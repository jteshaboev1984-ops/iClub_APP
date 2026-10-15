"use strict";
// §109 QA-only: authorise an exact, server-owned academic destination AFTER
// §108 token consumption. No navigation, no user progress writes, no Supabase.
// Destination reads must recheck live authority in the same SQL statement.
const {createHash}=require("node:crypto");
const {verifySignedPlan}=require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const {authoritySql}=require("./ai-layer-v21-p6-home-action-handoff.cjs");
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const TOKEN=/^[A-Za-z0-9_-]{32}$/;
const WORD=/^[a-z][a-z0-9_]{1,79}$/;
const TARGET=Object.freeze({
 review_finalized_practice:"practice-review",
 review_open_tour_archive:"tour-review",
 continue_enrolled_subject:"subject-hub"
});
const quote=v=>"'"+String(v).replace(/'/g,"''")+"'";
const deny=()=>Object.freeze({ok:false,reason:"in_development",releaseAllowed:false});
function destinationExistsSql(actionCode,evidenceId,owner,subject){
 const id=String(evidenceId);
 if(actionCode==="review_finalized_practice")
  return "EXISTS(SELECT 1 FROM public.practice_sessions_v4 ps "+
   "JOIN public.practice_session_answers_v4 pa ON pa.session_id=ps.id "+
   "WHERE ps.id="+id+" AND ps.user_id="+quote(owner)+"::uuid "+
   "AND ps.subject_id=sj.id AND ps.status='finalized' "+
   "AND ps.finalized_at IS NOT NULL AND pa.is_correct=false "+
   "AND pa.answered_at IS NOT NULL AND pa.question_id=ANY(ps.question_ids))";
 if(actionCode==="review_open_tour_archive")
  return "EXISTS(SELECT 1 FROM public.tour_attempts ta "+
   "JOIN public.tours t ON t.id=ta.tour_id "+
   "JOIN public.tour_session_runtime_v4 rt ON rt.attempt_id=ta.id "+
   "WHERE ta.id="+id+" AND ta.user_id="+quote(owner)+"::uuid "+
   "AND t.subject_id=sj.id AND ta.status IN ('submitted','time_expired') "+
   "AND t.end_date < (now() AT TIME ZONE 'Asia/Tashkent')::date "+
   "AND rt.user_id=ta.user_id AND rt.tour_id=t.id AND rt.finalized_at IS NOT NULL)";
 if(actionCode==="continue_enrolled_subject")
  return "sj.id="+id+" AND EXISTS(SELECT 1 FROM public.user_subjects us "+
   "WHERE us.user_id="+quote(owner)+"::uuid AND us.subject_id=sj.id "+
   "AND us.mode='study')";
 throw Error("unsupported target");
}
function resolveSyntheticDestination({sql,signingKey,userId,contextHandle,
 locale,handoffToken,actionCode,subjectKey}={}){
 if(typeof sql!=="function"||!Buffer.isBuffer(signingKey)||
  !UUID.test(userId||"")||!UUID.test(contextHandle||"")||
  !["ru","uz","en"].includes(locale)||!TOKEN.test(handoffToken||"")||
  !Object.hasOwn(TARGET,actionCode||"")||!WORD.test(subjectKey||""))
  return deny();
 const digest=createHash("sha256").update(handoffToken).digest("hex");
 let saved;
 try{
  saved=JSON.parse(sql("SELECT coalesce((SELECT json_build_object("+
   "'signedPlan',h.signed_plan,'ownerId',h.owner_id,"+
   "'contextHandle',h.context_handle,'locale',h.locale,"+
   "'screenRevision',h.screen_revision,"+
   "'expiresAtMs',floor(extract(epoch from h.expires_at)*1000)::bigint,"+
   "'consumed',h.consumed_at IS NOT NULL,"+
   "'actionCode',h.selected_action,'subjectKey',h.selected_subject)"+
   " FROM private.iclub_ai_v21_home_action_handoffs_scratch h"+
   " WHERE h.token_sha256="+quote(digest)+
   " AND h.owner_id="+quote(userId)+"::uuid"+
   " AND h.context_handle="+quote(contextHandle)+"::uuid"+
   " AND h.locale="+quote(locale)+"),'null'::json)::text"));
 }catch{return deny();}
 if(!saved||saved.ownerId!==userId||saved.contextHandle!==contextHandle||
  saved.locale!==locale||saved.consumed!==true||
  saved.actionCode!==actionCode||saved.subjectKey!==subjectKey||
  !Number.isSafeInteger(saved.screenRevision)||
  !Number.isSafeInteger(saved.expiresAtMs)||
  saved.expiresAtMs<=Date.now())return deny();
 let plan;
 try{plan=JSON.parse(saved.signedPlan);}
 catch{return deny();}
 if(!verifySignedPlan(plan,signingKey)||plan.ownerId!==userId||
  plan.screenRevision!==saved.screenRevision||
  plan.expiresAtMs!==saved.expiresAtMs)return deny();
 const matching=plan.actions?.filter(a=>a.actionCode===actionCode&&
  a.subjectKey===subjectKey);
 if(matching?.length!==1)return deny();
 const match=/_([0-9]+)$/.exec(matching[0].actionId||"");
 const evidenceId=match?Number(match[1]):NaN;
 if(!Number.isSafeInteger(evidenceId)||evidenceId<1)return deny();
 try{
  const currentAuthority=authoritySql(plan,userId,contextHandle,locale);
  // The spent claim, source rights, subject slot, academic evidence, Home
  // revision and destination existence are read in ONE fresh MVCC snapshot.
  // Moving to a REAL Courses screen requires a new destination-scoped auth
  // service; the Home context must never be treated as lasting permission.
  const q="WITH permitted AS MATERIALIZED ("+currentAuthority+"), "+
   "spent AS (SELECT 1 FROM private.iclub_ai_v21_home_action_handoffs_scratch h"+
   " WHERE h.token_sha256="+quote(digest)+
   " AND h.owner_id="+quote(userId)+"::uuid"+
   " AND h.context_handle="+quote(contextHandle)+"::uuid"+
   " AND h.locale="+quote(locale)+
   " AND h.screen_revision="+plan.screenRevision+
   " AND h.signed_plan="+quote(saved.signedPlan)+
   " AND h.consumed_at IS NOT NULL"+
   " AND h.selected_action="+quote(actionCode)+
   " AND h.selected_subject="+quote(subjectKey)+
   " AND h.expires_at>clock_timestamp())"+
   " SELECT EXISTS(SELECT 1 FROM permitted p "+
   "JOIN public.subjects sj ON sj.subject_key="+quote(subjectKey)+
   " AND sj.is_active=true "+
   "WHERE p.still_authorized='true' AND EXISTS(SELECT 1 FROM spent) "+
   "AND "+destinationExistsSql(actionCode,evidenceId,userId,subjectKey)+")::text";
  if(sql(q)!=="true")return deny();
 }catch{return deny();}
 return Object.freeze({ok:true,status:"qa_destination_verified",
  targetScreen:TARGET[actionCode],subjectKey,reviewOnly:true,
  releaseAllowed:false,navigationExecuted:false,progressChanged:false});
}
module.exports={resolveSyntheticDestination,destinationExistsSql};
