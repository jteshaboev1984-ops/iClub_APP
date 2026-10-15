"use strict";
// §96: QA-only local HTTP + REAL scratch PostgreSQL + signed Home policy.
// No real auth, source publication, Supabase client or model provider.
// NEVER deploy this synthetic fixture to Vercel or a production Edge.
const {execFileSync}=require("node:child_process");
const {createServer}=require("node:http");
const {readFileSync}=require("node:fs");
const {join}=require("node:path");
const {createHash}=require("node:crypto");
const {buildHomePlan,verifySignedPlan}=require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const {QAHomeApprovedPriority}=require("./ai-layer-v21-p6-home-approved-priority.cjs");
const {makeCommercialProofAdapter}=require("./ai-layer-v21-p6-commercial-contract-adapter.cjs");
const {validateBeforeHomeDelivery}=require("./ai-layer-v21-p6-home-delivery-gate.cjs");
const {issueSyntheticHandoff,claimSyntheticHandoff}=require("./ai-layer-v21-p6-home-action-handoff.cjs");
const OWNER="11111111-1111-4111-8111-111111111111";
const FOREIGN="22222222-2222-4222-8222-222222222222";
const HANDLE="33333333-3333-4333-8333-333333333333";
const OWNER_TOKEN="synthetic-owner-no-real-jwt-AAAAAAAA";
const OTHER_TOKEN="synthetic-other-no-real-jwt-BBBBBBBB";
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const WORD=/^[a-z][a-z0-9_]{1,79}$/;
const CODE_INTENT=Object.freeze({
 review_finalized_practice:"study",
 review_open_tour_archive:"competitive",
 continue_enrolled_subject:"study"
});
function pg(){
 const name=process.env.ICLUB_PGTEST_DB,host=process.env.ICLUB_PGTEST_HOST;
 const port=process.env.ICLUB_PGTEST_PORT||"5432";
 if(!/^iclub_ai_v21_scratch_[a-z0-9_]+$/.test(name||"")||
  host!=="127.0.0.1"||!/^\d{1,5}$/.test(port)||
  +port<1||+port>65535||process.env.PGPASSWORD!=="synthetic-only")
  throw Error("STOP: local disposable scratch PostgreSQL is mandatory");
 return{name,host,port};
}
function sql(query){
 const c=pg();
 return execFileSync("psql",["-X","-w","-v","ON_ERROR_STOP=1","-At",
  "-h",c.host,"-p",c.port,"-d",c.name,"-c",query],
  {encoding:"utf8",timeout:5000,maxBuffer:65536,
   env:{PATH:process.env.PATH,HOME:process.env.HOME,PGUSER:"postgres",
    PGPASSWORD:"synthetic-only",PGAPPNAME:"iclub_ai_v21_local_scratch",
    PGCONNECT_TIMEOUT:"3"}}).trim();
}
function makeServices(){
 const signingKey=Buffer.alloc(32,0x4f); // only ephemeral QA fixture
 const services={
  signingKey,nowMs:()=>Date.now(),
  async readCurrentScreen(user,handle){
   if(!UUID.test(user)||!UUID.test(handle))return null;
   const q="SELECT coalesce((SELECT json_build_object("+
    "'ownerId',n.user_id,'contextHandle',c.context_handle,"+
    "'surface',c.surface_code,'currentView',c.app_view_code,"+
    "'revision',n.revision,"+
    "'expiresAtMs',floor(extract(epoch from c.expires_at)*1000)::bigint)"+
    " FROM private.iclub_ai_v21_current_screen n JOIN"+
    " private.iclub_ai_v21_scoped_contexts c"+
    " ON c.context_handle=n.current_handle AND c.user_id=n.user_id"+
    " AND c.context_revision=n.revision"+
    " WHERE n.user_id='"+user+"' AND c.context_handle='"+handle+"'"+
    " AND c.revoked_at IS NULL AND c.expires_at>now()),'null'::json)::text";
   return JSON.parse(sql(q));
  },
  async readServerScan(user,handle){
   if(!UUID.test(user)||!UUID.test(handle))return null;
   return JSON.parse(sql("SELECT public.get_iclub_ai_v21_home_scan_scratch_service("+
    "'"+user+"'::uuid,'"+handle+"'::uuid)::text"));
  },
  async readCommercialSnapshot(user,subject,intent){
   // The code and intent arrive from a trusted server step and are syntactically
   // allowlisted. This query calls the real-shaped scratch guard with intent
   // "open" and separately reads selected mode and entitlement facts.
   if(!UUID.test(user)||!WORD.test(subject||"")||
    !["study","competitive"].includes(intent))return null;
   const value=sql(
    "SELECT public.get_iclub_ai_v21_commercial_snapshot_scratch_service("+
    "'"+user+"'::uuid,'"+subject+"','"+intent+"')::text");
   return value?JSON.parse(value):null;
  },
  async verifyAcademicEvidence(user,v){
   if(!UUID.test(user)||!v||!CODE_INTENT[v.actionCode]||
    !WORD.test(v.subjectKey||"")||!Number.isSafeInteger(v.evidenceId)||
    v.evidenceId<=0||!Number.isSafeInteger(v.evidenceRevision)||
    v.evidenceRevision<=0)return{allowed:false};
   const id=v.evidenceId,rev=v.evidenceRevision,subject=v.subjectKey;
   const begin="SELECT EXISTS(SELECT 1 FROM ";
   let q;
   if(v.actionCode==="review_finalized_practice")
    q=begin+"public.practice_sessions_v4 s JOIN public.subjects j"+
     " ON j.id=s.subject_id JOIN public.practice_session_answers_v4 a"+
     " ON a.session_id=s.id WHERE s.id="+id+" AND s.user_id='"+user+"'"+
     " AND j.subject_key='"+subject+"' AND s.status='finalized'"+
     " AND s.finalized_at IS NOT NULL"+
     " AND extract(epoch from s.finalized_at)::bigint="+rev+
     " AND a.question_id=ANY(s.question_ids) AND a.is_correct=false"+
     " AND a.answered_at IS NOT NULL)::text";
   else if(v.actionCode==="review_open_tour_archive")
    q=begin+"public.tour_attempts ta JOIN public.tours t"+
     " ON t.id=ta.tour_id JOIN public.subjects j ON j.id=t.subject_id"+
     " JOIN public.tour_session_runtime_v4 rt ON rt.attempt_id=ta.id"+
     " WHERE ta.id="+id+" AND ta.user_id='"+user+"'"+
     " AND j.subject_key='"+subject+"'"+
     " AND ta.status IN ('submitted','time_expired')"+
     " AND t.end_date < (now() AT TIME ZONE 'Asia/Tashkent')::date"+
     " AND rt.user_id=ta.user_id AND rt.tour_id=ta.tour_id"+
     " AND rt.finalized_at IS NOT NULL"+
     " AND extract(epoch from rt.finalized_at)::bigint="+rev+")::text";
   else
    q=begin+"public.subjects j JOIN public.user_subjects us"+
     " ON us.subject_id=j.id WHERE j.id="+id+" AND j.is_active"+
     " AND j.subject_key='"+subject+"' AND us.user_id='"+user+"'"+
     " AND us.mode='study' AND "+rev+">0)::text";
   const allowed=sql(q)==="true";
   const evidenceHash=createHash("sha256").update(
    ["SYNTHETIC-EVIDENCE",user,v.actionCode,subject,id,rev].join(":")
   ).digest("hex");
   return{allowed,evidenceId:id,evidenceRevision:rev,evidenceHash,
    subjectKey:subject,actionCode:v.actionCode};
  },
  async verifyAtomicDeliverySnapshot({userId,contextHandle,locale,plan}={}){
   // Only private disposable PG; never query live Supabase. Exact signed
   // action values become a JSONB literal after strict type/character check.
   if(!UUID.test(userId||"")||!UUID.test(contextHandle||"")||
    !["ru","uz","en"].includes(locale)||
    !Number.isSafeInteger(plan?.screenRevision)||plan.screenRevision<1||
    !Number.isSafeInteger(plan?.expiresAtMs)||plan.expiresAtMs<1||
    !Array.isArray(plan.actions)||plan.actions.length<1||plan.actions.length>3)
    return false;
   for(const a of plan.actions){
    if(!a||!["continue_enrolled_subject","review_finalized_practice",
       "review_open_tour_archive"].includes(a.actionCode)||
      !WORD.test(a.subjectKey)||!/^[a-z][a-z0-9_]{2,110}$/.test(a.actionId)||
      !Number.isSafeInteger(a.evidenceRevision)||a.evidenceRevision<1||
      !/^[0-9a-f]{64}$/.test(a.sourceHash)||
      !/^[0-9a-f]{64}$/.test(a.evidenceHash)||
      !/^[a-z0-9_.-]{1,80}$/.test(a.sourceVersion))return false;
   }
   const path=join(__dirname,"sql_drafts",
    "iclub_ai_v21_home_atomic_delivery_READ_ONLY.sql");
   const template=readFileSync(path,"utf8");
   const values={
    "{{USER}}":userId,"{{HANDLE}}":contextHandle,"{{LOCALE}}":locale,
    "{{REVISION}}":String(plan.screenRevision),
    "{{EXPIRES_MS}}":String(plan.expiresAtMs),
    "{{ACTIONS_JSON}}":JSON.stringify(plan.actions).replace(/'/g,"''")
   };
   let query=template;
   for(const [tag,value] of Object.entries(values))query=query.replaceAll(tag,value);
   if(query.includes("{{")||!/^\s*--/.test(query))return false;
   return sql(query)==="true";
  },
  async readEditorialRelease(locale,code,subject){
   if(!["ru","uz","en"].includes(locale)||!CODE_INTENT[code]||
    !WORD.test(subject||""))return{ready:false};
   // Read a REAL PostgreSQL row, but ONLY the synthetic scratch release
   // table. A revoked locale / source fails before any signed recommendation.
   // This is NOT real editorial approval or production source publication.
   const q="SELECT (SELECT json_build_object("+
    "'ready',r.rights_approved AND r.content_approved AND r.revoked_at IS NULL,"+
    "'rightsApproved',r.rights_approved AND r.revoked_at IS NULL,"+
    "'contentApproved',r.content_approved AND r.revoked_at IS NULL,"+
    "'sourceConflict',false,'sourceHash',r.source_hash,"+
    "'sourceVersion',r.source_version)"+
    " FROM private.iclub_ai_v21_home_source_test_releases r"+
    " WHERE r.locale='"+locale+"' AND r.action_code='"+code+"'"+
    " AND r.subject_key='"+subject+"')::text";
   const raw=sql(q);
   return raw?JSON.parse(raw):{ready:false};
  }
 };
 const access=makeCommercialProofAdapter({
  readCommercialSnapshot:services.readCommercialSnapshot
 });
 services.verifySubjectAccess=access.verifySubjectAccess;
 return services;
}
async function evaluateOwnerAction(services,user,handle,locale,beforeDelivery){
 const proposed=await buildHomePlan(services,{userId:user,contextHandle:handle,locale});
 if(proposed.ready!==true)return null;
 const validated={
  nowMs:services.nowMs,
  readCurrentScreen:services.readCurrentScreen,
  readServerPlan:async()=>proposed.plan,
  verifyPlanAuthority:async(owner,screen,plan)=>
   owner===user&&screen.contextHandle===handle&&
   verifySignedPlan(plan,services.signingKey),
  verifyAcademicEvidence:async(_,a)=>{
   const current=await services.readServerScan(user,handle);
   const v=current.candidates?.find(x=>x.actionCode===a.actionCode&&
    x.subjectKey===a.subjectKey);
   const e=v?await services.verifyAcademicEvidence(user,v):{allowed:false};
   return{allowed:e.allowed&&e.evidenceHash===a.evidenceHash,
    evidenceHash:e.evidenceHash,evidenceRevision:e.evidenceRevision};
  },
  verifyEditorialRelease:async(l,a)=>{
   const r=await services.readEditorialRelease(l,a.actionCode,a.subjectKey);
   return{ready:r.ready&&r.rightsApproved&&r.contentApproved,
    sourceHash:r.sourceHash,sourceVersion:r.sourceVersion};
  }
 };
 const choice=await new QAHomeApprovedPriority(validated).choose({
  userId:user,contextHandle:handle,locale});
 if(choice.ready!==true)return null;
 // QA instrumentation runs only on isolated loopback and may revoke
 // synthetic rights *after* priority selection but *before* delivery.
 if(typeof beforeDelivery==="function")await beforeDelivery({user,handle,locale});
 const delivered=await validateBeforeHomeDelivery(services,{
  userId:user,contextHandle:handle,locale,plan:proposed.plan,choice
 });
 if(delivered.ready!==true)return null;
 const handoff=issueSyntheticHandoff({sql,signingKey:services.signingKey,
  userId:user,contextHandle:handle,locale,plan:proposed.plan,delivered});
 if(handoff.ok!==true)return null;
 const out={ok:true,status:delivered.status,handoffToken:handoff.handoffToken,
  reviewOnly:true,releaseAllowed:false,expiresAtMs:delivered.expiresAtMs};
 if(delivered.status==="candidate_only"){
  out.actionCode=delivered.actionCode;out.subjectKey=delivered.subjectKey;
 }else if(delivered.status==="selection_required"){
  out.choices=delivered.choices;
 }else return null;
 return out;
}
function makeGateway({beforeDelivery,beforeAtomicRead}={}){
 if([beforeDelivery,beforeAtomicRead].some(h=>h!==undefined&&typeof h!=="function"))
  throw Error("invalid scratch-only injection hook");
 pg();
 const services=makeServices(),state={requests:0,denied:0};
 if(typeof beforeAtomicRead==="function"){
  const actual=services.verifyAtomicDeliverySnapshot;
  services.verifyAtomicDeliverySnapshot=async input=>{
   // Test-only deterministic revocation immediately before the single SQL
   // statement. No product code, no credentials and no production DB.
   await beforeAtomicRead({userId:input.userId,locale:input.locale});
   return actual(input);
  };
 }
 const server=createServer(async(req,res)=>{
  state.requests++;
  // This page is ONLY available on the locally bound QA fixture server.
  // Never served by Vercel or the real app. It invokes the SAME HTTP route
  // that authenticates synthetic user and reads the disposable PostgreSQL.
  if(req.method==="GET"&&req.url==="/qa/home/demo"){
   const file=join(__dirname,"preview_v21","home-pg-local.html");
   const html=readFileSync(file,"utf8");
   res.writeHead(200,{"Content-Type":"text/html; charset=utf-8",
    "Cache-Control":"no-store","X-Content-Type-Options":"nosniff",
    "Content-Security-Policy":"default-src 'none'; script-src 'unsafe-inline'; "+
    "style-src 'unsafe-inline'; connect-src 'self'; img-src 'none'; "+
    "base-uri 'none'; form-action 'none'; frame-ancestors 'none'"});
   return res.end(html);
  }
  const reject=(status,reason)=>{
   state.denied++;
   res.writeHead(status,{"Content-Type":"application/json","Cache-Control":"no-store"});
   res.end(JSON.stringify({ok:false,reason}));
  };
  const isNext=req.url==="/qa/home/next";
  const isConfirm=req.url==="/qa/home/confirm";
  if((!isNext&&!isConfirm)||req.method!=="POST")
   return reject(404,"not_found");
  const origin="http://127.0.0.1:"+server.address().port;
  if(req.headers.origin!==origin)return reject(403,"origin_not_authorized");
  const header=req.headers.authorization||"";
  const token=/^Bearer [A-Za-z0-9._-]{8,128}$/.test(header)?
   header.slice(7):null;
  const user=token===OWNER_TOKEN?OWNER:token===OTHER_TOKEN?FOREIGN:null;
  if(!user)return reject(401,"authentication_required");
  if(req.headers["content-type"]!=="application/json")
   return reject(415,"invalid_content_type");
  try{
   let raw="";
   for await(const chunk of req){
    raw+=chunk;
    if(Buffer.byteLength(raw)>256)return reject(413,"body_too_large");
   }
   const body=JSON.parse(raw),keys=Object.keys(body||{}).sort().join(",");
   if(isConfirm){
    if(keys!=="actionCode,contextHandle,handoffToken,locale,subjectKey"||
     !UUID.test(body.contextHandle||"")||
     !["ru","uz","en"].includes(body.locale))
     return reject(400,"invalid_request");
    const claimed=claimSyntheticHandoff({sql,signingKey:services.signingKey,
     userId:user,contextHandle:body.contextHandle,locale:body.locale,
     handoffToken:body.handoffToken,actionCode:body.actionCode,
     subjectKey:body.subjectKey});
    if(claimed.ok!==true)return reject(403,"in_development");
    res.writeHead(200,{"Content-Type":"application/json",
     "Cache-Control":"no-store","Access-Control-Allow-Origin":origin,
     "X-Content-Type-Options":"nosniff"});
    return res.end(JSON.stringify(claimed));
   }
   if(keys!=="contextHandle,locale"||!UUID.test(body.contextHandle||"")||
    !["ru","uz","en"].includes(body.locale))return reject(400,"invalid_request");
   const out=await evaluateOwnerAction(services,user,body.contextHandle,body.locale,beforeDelivery);
   if(!out)return reject(403,"in_development");
   res.writeHead(200,{"Content-Type":"application/json",
    "Cache-Control":"no-store","Access-Control-Allow-Origin":origin,
    "X-Content-Type-Options":"nosniff"});
   res.end(JSON.stringify(out));
  }catch{return reject(503,"unavailable");}
 });
 return{server,state,ownerToken:OWNER_TOKEN,otherToken:OTHER_TOKEN,
  handle:HANDLE,ownerId:OWNER};
}
module.exports={makeGateway,scratchSql:sql,OWNER,FOREIGN,HANDLE};
