"use strict";
// §108 local synthetic one-shot action handoff; NO navigation/progress writes.
// A bearer token never contains academic record IDs, owner or signed plan.
// The only state mutation is consuming one synthetic scratch PostgreSQL token.
const {randomBytes,createHash}=require("node:crypto");
const {readFileSync}=require("node:fs");
const {join}=require("node:path");
const {verifySignedPlan}=require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const WORD=/^[a-z][a-z0-9_]{1,79}$/;
const ACTIONS=["review_finalized_practice","review_open_tour_archive",
 "continue_enrolled_subject"];
const LOCALES=["ru","uz","en"];
const TOKEN=/^[A-Za-z0-9_-]{32}$/;
const SHA=/^[a-f0-9]{64}$/;
const denial=()=>Object.freeze({ok:false,reason:"in_development",releaseAllowed:false});
const literal=s=>"'"+String(s).replace(/'/g,"''")+"'";
const sha256=s=>createHash("sha256").update(s).digest("hex");
const validAction=x=>x&&typeof x==="object"&&
 ACTIONS.includes(x.actionCode)&&WORD.test(x.subjectKey);
function possibleChoices(delivered){
 if(!delivered||delivered.ready!==true||delivered.reviewOnly!==true||
  delivered.releaseAllowed!==false)return null;
 let choices;
 if(delivered.status==="candidate_only"&&validAction(delivered))
  choices=[{actionCode:delivered.actionCode,subjectKey:delivered.subjectKey}];
 else if(delivered.status==="selection_required"&&
  Array.isArray(delivered.choices)&&delivered.choices.length>=2&&
  delivered.choices.length<=3&&delivered.choices.every(validAction))
  choices=delivered.choices.map(x=>({actionCode:x.actionCode,subjectKey:x.subjectKey}));
 else return null;
 if(new Set(choices.map(x=>x.actionCode+":"+x.subjectKey)).size!==choices.length)
  return null;
 return choices;
}
function issueSyntheticHandoff({sql,signingKey,userId,contextHandle,locale,plan,delivered}){
 if(typeof sql!=="function"||!Buffer.isBuffer(signingKey)||
  !UUID.test(userId)||!UUID.test(contextHandle)||!LOCALES.includes(locale)||
  !verifySignedPlan(plan,signingKey)||plan.ownerId!==userId||
  !Number.isSafeInteger(plan.screenRevision)||plan.screenRevision<1||
  !Number.isSafeInteger(plan.expiresAtMs)||plan.expiresAtMs<=Date.now()||
  plan.expiresAtMs-Date.now()>30000||
  delivered?.expiresAtMs!==plan.expiresAtMs)return denial();
 const choices=possibleChoices({...delivered,ready:true});
 if(!choices)return denial();
 const selected=new Set(plan.actions.map(x=>x.actionCode+":"+x.subjectKey));
 if(choices.length!==selected.size||
  choices.some(x=>!selected.has(x.actionCode+":"+x.subjectKey)))return denial();
 const token=randomBytes(24).toString("base64url");
 if(!TOKEN.test(token))return denial();
 const row=[
  literal(sha256(token)),literal(userId)+"::uuid",
  literal(contextHandle)+"::uuid",literal(locale),
  String(plan.screenRevision),
  "to_timestamp("+plan.expiresAtMs+"::double precision/1000.0)",
  literal(JSON.stringify(plan)),
  literal(JSON.stringify(choices))+"::jsonb"
 ].join(",");
 try{
  const inserted=sql("WITH created AS (INSERT INTO "+
   "private.iclub_ai_v21_home_action_handoffs_scratch "+
   "(token_sha256,owner_id,context_handle,locale,screen_revision,"+
   "expires_at,signed_plan,allowed_choices) VALUES ("+row+") "+
   "RETURNING token_sha256) SELECT token_sha256 FROM created");
  if(inserted!==sha256(token))return denial();
  return Object.freeze({ok:true,handoffToken:token,expiresAtMs:plan.expiresAtMs,
   reviewOnly:true,releaseAllowed:false,navigationExecuted:false});
 }catch{return denial();}
}
const safePlan=p=>p&&typeof p==="object"&&
 Array.isArray(p.actions)&&p.actions.length>=1&&p.actions.length<=3&&
 Number.isSafeInteger(p.screenRevision)&&p.screenRevision>0&&
 Number.isSafeInteger(p.expiresAtMs)&&p.expiresAtMs>0&&
 p.actions.every(a=>validAction(a)&&
  typeof a.actionId==="string"&&/^[a-z][a-z0-9_]{2,110}$/.test(a.actionId)&&
  Number.isSafeInteger(a.evidenceRevision)&&a.evidenceRevision>0&&
  typeof a.sourceVersion==="string"&&/^[a-z0-9_.-]{1,80}$/.test(a.sourceVersion)&&
  typeof a.evidenceHash==="string"&&SHA.test(a.evidenceHash)&&
  typeof a.sourceHash==="string"&&SHA.test(a.sourceHash));
function authoritySql(plan,userId,contextHandle,locale){
 if(!safePlan(plan)||!UUID.test(userId)||!UUID.test(contextHandle)||
  !LOCALES.includes(locale))throw Error("untrusted handoff payload");
 let template=readFileSync(join(__dirname,"sql_drafts",
  "iclub_ai_v21_home_atomic_delivery_READ_ONLY.sql"),"utf8");
 const substitutions={
  "{{USER}}":userId,"{{HANDLE}}":contextHandle,"{{LOCALE}}":locale,
  "{{REVISION}}":String(plan.screenRevision),
  "{{EXPIRES_MS}}":String(plan.expiresAtMs),
  "{{ACTIONS_JSON}}":JSON.stringify(plan.actions).replace(/'/g,"''")
 };
 for(const [k,v] of Object.entries(substitutions))template=template.replaceAll(k,v);
 if(template.includes("{{"))throw Error("unresolved SQL handoff authority");
 return template.trim().replace(/;\s*$/,"");
}
function claimSyntheticHandoff({sql,signingKey,userId,contextHandle,locale,
 handoffToken,actionCode,subjectKey}){
 if(typeof sql!=="function"||!Buffer.isBuffer(signingKey)||
  !UUID.test(userId)||!UUID.test(contextHandle)||!LOCALES.includes(locale)||
  !TOKEN.test(handoffToken||"")||!ACTIONS.includes(actionCode)||
  !WORD.test(subjectKey||""))return denial();
 const digest=sha256(handoffToken);
 let saved;
 try{
  const row=sql("SELECT coalesce((SELECT json_build_object("+
   "'signedPlan',h.signed_plan,'choices',h.allowed_choices,"+
   "'ownerId',h.owner_id,'contextHandle',h.context_handle,"+
   "'locale',h.locale,'screenRevision',h.screen_revision,"+
   "'expiresAtMs',floor(extract(epoch from h.expires_at)*1000)::bigint)"+
   " FROM private.iclub_ai_v21_home_action_handoffs_scratch h"+
   " WHERE h.token_sha256="+literal(digest)+"),'null'::json)::text");
  saved=JSON.parse(row);
 }catch{return denial();}
 if(!saved||saved.ownerId!==userId||
  saved.contextHandle!==contextHandle||saved.locale!==locale||
  !Number.isSafeInteger(saved.screenRevision)||
  !Number.isSafeInteger(saved.expiresAtMs)||
  !Array.isArray(saved.choices)||!saved.choices.some(x=>
   x.actionCode===actionCode&&x.subjectKey===subjectKey))return denial();
 let plan;
 try{plan=JSON.parse(saved.signedPlan);}
 catch{return denial();}
 if(!safePlan(plan)||!verifySignedPlan(plan,signingKey)||
  plan.ownerId!==userId||plan.screenRevision!==saved.screenRevision||
  plan.expiresAtMs!==saved.expiresAtMs||Date.now()>=plan.expiresAtMs)
  return denial();
 let query;
 try{
  const verified=authoritySql(plan,userId,contextHandle,locale);
  query="WITH permitted AS MATERIALIZED ("+verified+"), consumed AS ("+
   " UPDATE private.iclub_ai_v21_home_action_handoffs_scratch h"+
   " SET consumed_at=clock_timestamp(),"+
   " selected_action="+literal(actionCode)+","+
   " selected_subject="+literal(subjectKey)+
   " WHERE h.token_sha256="+literal(digest)+
   " AND h.owner_id="+literal(userId)+"::uuid"+
   " AND h.context_handle="+literal(contextHandle)+"::uuid"+
   " AND h.locale="+literal(locale)+
   " AND h.screen_revision="+plan.screenRevision+
   " AND h.signed_plan="+literal(saved.signedPlan)+
   " AND h.consumed_at IS NULL"+
   " AND h.expires_at>clock_timestamp()"+
   " AND h.allowed_choices @> "+literal(JSON.stringify(
    [{actionCode,subjectKey}]))+"::jsonb"+
   " AND (SELECT still_authorized='true' FROM permitted)"+
   " RETURNING h.token_sha256)"+
   " SELECT EXISTS(SELECT 1 FROM consumed)::text";
  if(sql(query)!=="true")return denial();
 }catch{return denial();}
 return Object.freeze({ok:true,status:"qa_handoff_confirmed",
  reviewOnly:true,releaseAllowed:false,navigationExecuted:false,
  progressChanged:false});
}
module.exports={issueSyntheticHandoff,claimSyntheticHandoff,possibleChoices,authoritySql};
