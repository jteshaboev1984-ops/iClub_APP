"use strict";
// §§110–113: destination-scoped, disposable QA journey, not a deployable API.
// Only local PostgreSQL scratch state changes (one route claim / close).
const {randomBytes,randomUUID,createHash}=require("node:crypto");
const {verifySignedPlan}=require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const {authoritySql}=require("./ai-layer-v21-p6-home-action-handoff.cjs");
const {resolveSyntheticDestination,destinationExistsSql}=
 require("./ai-layer-v21-p6-home-destination-proof.cjs");
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const TOKEN=/^[A-Za-z0-9_-]{32}$/;
const WORD=/^[a-z][a-z0-9_]{1,79}$/;
const TARGET=Object.freeze({
 review_finalized_practice:"practice-review",
 review_open_tour_archive:"tour-review",
 continue_enrolled_subject:"subject-hub"
});
const deny=()=>Object.freeze({ok:false,reason:"in_development",releaseAllowed:false});
const quote=v=>"'"+String(v).replace(/'/g,"''")+"'";
const digest=v=>createHash("sha256").update(v).digest("hex");
const isLocale=v=>["ru","uz","en"].includes(v);
function getClaim(sql,sha,userId,contextHandle,locale){
 return JSON.parse(sql("SELECT coalesce((SELECT json_build_object("+
  "'signedPlan',h.signed_plan,'revision',h.screen_revision,"+
  "'expiresAtMs',floor(extract(epoch from h.expires_at)*1000)::bigint)"+
  " FROM private.iclub_ai_v21_home_action_handoffs_scratch h"+
  " WHERE h.token_sha256="+quote(sha)+" AND h.owner_id="+quote(userId)+"::uuid"+
  " AND h.context_handle="+quote(contextHandle)+"::uuid"+
  " AND h.locale="+quote(locale)+
  " AND h.consumed_at IS NOT NULL), 'null'::json)::text"));
}
function openSyntheticStudy({sql,signingKey,userId,contextHandle,locale,
 handoffToken,actionCode,subjectKey}={}){
 if(typeof sql!=="function"||!Buffer.isBuffer(signingKey)||
  !UUID.test(userId||"")||!UUID.test(contextHandle||"")||
  !isLocale(locale)||!TOKEN.test(handoffToken||"")||
  !Object.hasOwn(TARGET,actionCode||"")||!WORD.test(subjectKey||""))
  return deny();
 // Earlier §109 proof is NOT the authority for the eventual move:
 // the INSERT and current-screen transition repeat all checks atomically.
 const proof=resolveSyntheticDestination({sql,signingKey,userId,contextHandle,
  locale,handoffToken,actionCode,subjectKey});
 if(proof.ok!==true)return deny();
 try{
  const handoffSha=digest(handoffToken);
  const saved=getClaim(sql,handoffSha,userId,contextHandle,locale);
  if(!saved||saved.expiresAtMs<=Date.now())return deny();
  const plan=JSON.parse(saved.signedPlan);
  if(!verifySignedPlan(plan,signingKey)||plan.ownerId!==userId||
   plan.screenRevision!==saved.revision||
   plan.expiresAtMs!==saved.expiresAtMs)return deny();
  const matching=plan.actions?.filter(a=>a.actionCode===actionCode&&
   a.subjectKey===subjectKey);
  if(matching?.length!==1)return deny();
  const action=matching[0],matched=/_([0-9]+)$/.exec(action.actionId);
  const id=matched?Number(matched[1]):NaN;
  if(!Number.isSafeInteger(id)||id<=0||!Number.isSafeInteger(action.evidenceRevision))
   return deny();
  const routeToken=randomBytes(24).toString("base64url");
  const routeContext=randomUUID(),revision=plan.screenRevision+1;
  const gate=authoritySql(plan,userId,contextHandle,locale);
  const q="WITH permitted AS MATERIALIZED ("+gate+"),"+
   "created AS (INSERT INTO private.iclub_ai_v21_study_routes_scratch "+
   "(ticket_sha256,home_handoff_sha256,owner_id,home_context,"+
   "route_context,route_revision,locale,action_code,subject_key,"+
   "target_screen,object_id,evidence_revision,source_hash,source_version,expires_at)"+
   " SELECT "+quote(digest(routeToken))+","+quote(handoffSha)+","+
   quote(userId)+"::uuid,"+quote(contextHandle)+"::uuid,"+
   quote(routeContext)+"::uuid,"+revision+","+quote(locale)+","+
   quote(actionCode)+","+quote(subjectKey)+","+quote(TARGET[actionCode])+","+
   id+","+action.evidenceRevision+","+quote(action.sourceHash)+","+
   quote(action.sourceVersion)+",clock_timestamp()+interval '60 seconds'"+
   " FROM public.subjects sj "+
   "WHERE sj.subject_key="+quote(subjectKey)+" AND sj.is_active=true"+
   " AND EXISTS(SELECT 1 FROM permitted WHERE still_authorized='true')"+
   " AND EXISTS(SELECT 1 FROM private.iclub_ai_v21_home_action_handoffs_scratch h"+
   " WHERE h.token_sha256="+quote(handoffSha)+
   " AND h.owner_id="+quote(userId)+"::uuid"+
   " AND h.context_handle="+quote(contextHandle)+"::uuid"+
   " AND h.locale="+quote(locale)+
   " AND h.screen_revision="+plan.screenRevision+
   " AND h.signed_plan="+quote(saved.signedPlan)+
   " AND h.consumed_at IS NOT NULL AND h.expires_at>clock_timestamp()"+
   " AND h.selected_action="+quote(actionCode)+
   " AND h.selected_subject="+quote(subjectKey)+")"+
   " AND "+destinationExistsSql(actionCode,id,userId,subjectKey)+
   " ON CONFLICT (home_handoff_sha256) DO NOTHING"+
   " RETURNING owner_id,home_context,route_context,route_revision),"+
   "moved AS (UPDATE private.iclub_ai_v21_current_screen n"+
   " SET current_handle=c.route_context,revision=c.route_revision"+
   " FROM created c WHERE n.user_id=c.owner_id"+
   " AND n.current_handle=c.home_context AND n.revision="+plan.screenRevision+
   " RETURNING n.current_handle)"+
   " SELECT EXISTS(SELECT 1 FROM moved)::text";
  if(sql(q)!=="true")return deny();
  return Object.freeze({ok:true,status:"qa_study_scope_open",
   routeToken,expiresInSec:60,targetScreen:TARGET[actionCode],
   subjectKey,reviewOnly:true,releaseAllowed:false,progressChanged:false});
 }catch{return deny();}
}
function freshEvidenceSql(){
 return "( (r.action_code='review_finalized_practice' AND EXISTS("+
  " SELECT 1 FROM public.practice_sessions_v4 ps"+
  " JOIN public.practice_session_answers_v4 pa ON pa.session_id=ps.id"+
  " WHERE ps.id=r.object_id AND ps.user_id=r.owner_id AND ps.subject_id=sj.id"+
  " AND ps.status='finalized' AND ps.finalized_at IS NOT NULL"+
  " AND extract(epoch from ps.finalized_at)::bigint=r.evidence_revision"+
  " AND pa.is_correct=false AND pa.answered_at IS NOT NULL"+
  " AND pa.question_id=ANY(ps.question_ids)))"+
  " OR (r.action_code='review_open_tour_archive' AND EXISTS("+
  " SELECT 1 FROM public.tour_attempts ta"+
  " JOIN public.tours t ON t.id=ta.tour_id"+
  " JOIN public.tour_session_runtime_v4 rt ON rt.attempt_id=ta.id"+
  " WHERE ta.id=r.object_id AND ta.user_id=r.owner_id"+
  " AND ta.tour_id=t.id AND t.subject_id=sj.id"+
  " AND ta.status IN ('submitted','time_expired')"+
  " AND t.end_date<(now() AT TIME ZONE 'Asia/Tashkent')::date"+
  " AND rt.user_id=r.owner_id AND rt.tour_id=t.id"+
  " AND rt.finalized_at IS NOT NULL"+
  " AND extract(epoch from rt.finalized_at)::bigint=r.evidence_revision))"+
  " OR (r.action_code='continue_enrolled_subject' AND r.object_id=sj.id"+
  " AND us.mode='study'))";
}
function studyReadSql(routeSha,userId,locale){
 // One PostgreSQL statement authorizes BOTH the object and the redacted payload.
 const c="SELECT coalesce((SELECT json_build_object("+
  "'targetScreen',r.target_screen,'subjectKey',r.subject_key,"+
  "'reviewCount',CASE WHEN r.action_code='review_finalized_practice'"+
  " THEN (SELECT count(DISTINCT pa.question_id) FROM public.practice_sessions_v4 ps"+
  " JOIN public.practice_session_answers_v4 pa ON pa.session_id=ps.id"+
  " WHERE ps.id=r.object_id AND ps.user_id=r.owner_id"+
  " AND pa.is_correct=false AND pa.answered_at IS NOT NULL"+
  " AND pa.question_id=ANY(ps.question_ids)) ELSE 0 END)"+
  " FROM private.iclub_ai_v21_study_routes_scratch r"+
  " JOIN private.iclub_ai_v21_current_screen n"+
  " ON n.user_id=r.owner_id AND n.current_handle=r.route_context"+
  " AND n.revision=r.route_revision"+
  " JOIN public.subjects sj ON sj.subject_key=r.subject_key AND sj.is_active=true"+
  " JOIN public.user_subjects us ON us.user_id=r.owner_id AND us.subject_id=sj.id"+
  " JOIN private.iclub_subject_slot_selections slot"+
  " ON slot.user_id=r.owner_id AND slot.subject_key=r.subject_key"+
  " JOIN private.iclub_ai_v21_home_synthetic_access grant_row"+
  " ON grant_row.user_id=r.owner_id AND grant_row.subject_key=r.subject_key"+
  " AND grant_row.intent=us.mode AND grant_row.allowed=true"+
  " JOIN private.iclub_ai_v21_home_source_test_releases src"+
  " ON src.locale=r.locale AND src.action_code=r.action_code"+
  " AND src.subject_key=r.subject_key"+
  " JOIN private.iclub_commercial_access_config cfg ON cfg.id=1"+
  " JOIN private.iclub_global_ai_runtime_config runtime ON runtime.id=1"+
  " JOIN private.iclub_ai_qa_capabilities_fixture caps ON caps.user_id=r.owner_id"+
  " JOIN private.iclub_ai_qa_home_feature_gate gate ON gate.user_id=r.owner_id"+
  " WHERE current_database() ~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'"+
  " AND r.ticket_sha256="+quote(routeSha)+" AND r.owner_id="+quote(userId)+"::uuid"+
  " AND r.locale="+quote(locale)+
  " AND r.revoked_at IS NULL AND r.expires_at>clock_timestamp()"+
  " AND cfg.subject_limits_mode='enforced'"+
  " AND cfg.grandfather_snapshot_completed_at IS NOT NULL"+
  " AND caps.resolved=true AND caps.ai_generation_entitled=true"+
  " AND gate.approved=true AND runtime.kill_switch=false"+
  " AND runtime.gateway_enabled=true"+
  " AND NOT private.iclub_ai_has_active_protected_assessment_v1(r.owner_id)"+
  " AND src.rights_approved=true AND src.content_approved=true"+
  " AND src.revoked_at IS NULL AND src.source_hash=r.source_hash"+
  " AND src.source_version=r.source_version"+
  " AND us.mode=CASE WHEN r.action_code='review_open_tour_archive'"+
  " THEN 'competitive' ELSE 'study' END"+
  " AND slot.study_selected=true"+
  " AND (us.mode='study' OR (sj.type='main' AND slot.competitive_selected=true))"+
  " AND (public.get_iclub_subject_access_guard_service_v1("+
  " r.owner_id,r.subject_key,'open')->>'mode')='commercial'"+
  " AND (public.get_iclub_subject_access_guard_service_v1("+
  " r.owner_id,r.subject_key,'open')->>'allowed')='true'"+
  " AND "+freshEvidenceSql()+
  "), 'null'::json)::text";
 return c;
}
function readSyntheticStudy({sql,userId,locale,routeToken}={}){
 if(typeof sql!=="function"||!UUID.test(userId||"")||
  !isLocale(locale)||!TOKEN.test(routeToken||""))return deny();
 try{
  const row=JSON.parse(sql(studyReadSql(digest(routeToken),userId,locale)));
  if(!row||!Object.values(TARGET).includes(row.targetScreen)||
   !WORD.test(row.subjectKey||"")||
   !Number.isSafeInteger(row.reviewCount)||row.reviewCount<0)return deny();
  return Object.freeze({ok:true,status:"qa_study_read",
   ...row,reviewOnly:true,releaseAllowed:false,progressChanged:false});
 }catch{return deny();}
}
function closeSyntheticStudy({sql,userId,locale,routeToken}={}){
 if(typeof sql!=="function"||!UUID.test(userId||"")||
  !isLocale(locale)||!TOKEN.test(routeToken||""))return deny();
 try{
  const q="WITH closed AS (UPDATE private.iclub_ai_v21_study_routes_scratch r"+
   " SET revoked_at=clock_timestamp() WHERE r.ticket_sha256="+quote(digest(routeToken))+
   " AND r.owner_id="+quote(userId)+"::uuid"+
   " AND r.locale="+quote(locale)+" AND r.revoked_at IS NULL"+
   " AND EXISTS(SELECT 1 FROM private.iclub_ai_v21_current_screen n"+
   " WHERE n.user_id=r.owner_id AND n.current_handle=r.route_context"+
   " AND n.revision=r.route_revision)"+
   " RETURNING r.owner_id,r.home_context,r.route_context,r.route_revision),"+
   "moved AS (UPDATE private.iclub_ai_v21_current_screen n"+
   " SET current_handle=c.home_context,revision=n.revision+1"+
   " FROM closed c WHERE n.user_id=c.owner_id"+
   " AND n.current_handle=c.route_context AND n.revision=c.route_revision"+
   " RETURNING n.user_id,n.current_handle,n.revision),"+
   "restored AS (UPDATE private.iclub_ai_v21_scoped_contexts ctx"+
   " SET context_revision=m.revision FROM moved m"+
   " WHERE ctx.context_handle=m.current_handle AND ctx.user_id=m.user_id"+
   " AND ctx.surface_code='home' AND ctx.revoked_at IS NULL"+
   " RETURNING ctx.context_handle)"+
   " SELECT EXISTS(SELECT 1 FROM restored)::text";
  if(sql(q)!=="true")return deny();
  return Object.freeze({ok:true,status:"qa_study_closed",reviewOnly:true,
   releaseAllowed:false,progressChanged:false});
 }catch{return deny();}
}
module.exports={openSyntheticStudy,readSyntheticStudy,closeSyntheticStudy,
 studyReadSql};
