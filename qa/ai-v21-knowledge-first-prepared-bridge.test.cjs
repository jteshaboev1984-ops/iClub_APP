"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {createKnowledgeFirstReadOnlyGate}=
 require("./ai-v21-knowledge-first-readonly-gate.cjs");
const {createPreparedKnowledgeFirstQaBridge}=
 require("./ai-v21-knowledge-first-prepared-bridge.cjs");
const OWNER="11111111-1111-4111-8111-111111111111";
const CTX="22222222-2222-4222-8222-222222222222";
const RID="33333333-3333-4333-8333-333333333333";
const SOURCE="practice:biology:p1:q42:ru:v1",HASH="a".repeat(64);
const TOKEN="Bearer synthetic-signed-user-auth-only-AAAA";
const ORIGIN="https://iclub-qa.invalid";
function rig(){
 const state={active:true,protected:false,rights:true,source:true,
  edgeRelease:true,edgeSource:SOURCE,auth:true,units:0,
  attempts:new Map(),claims:new Map(),providerCalls:0,bundleCalls:0,
  chargeCalls:0,contentRevokedDuringBundle:false,
  answerState:"incorrect",missingIncorrectProof:false,
  editorVersion:"v1",editorHash:HASH,editorRevision:1,
  edgeVersion:"v1",edgeHash:HASH,edgeRevision:1,
  changeOnReserve:null,bundleVariantMismatch:null};
 const deadline=Date.now()+60000;
 const auth=async authorization=>authorization===TOKEN&&state.auth?
  {authenticated:true,userId:OWNER,proof:"verified_supabase_auth_v1"}:null;
 const screen=()=>({proof:"server_owner_current_screen_v1",
  ownerId:OWNER,contextHandle:CTX,revision:5,expiresAtMs:deadline,
  locale:"ru",screenCode:"practice-review",scopeCode:"global",
  subjectKey:"biology",finalized:true,ownsAnsweredQuestion:true,
  questionId:42,assessmentActive:false,
  confirmedIncorrectAnswer:!state.missingIncorrectProof});
 const card={locale:"ru",subject_key:"biology",question_id:42,
  card_type:"answer_explanation",source_card_key:SOURCE,
  content_hash:HASH,source_version:"v1",
  body_text:"Verified prepared original QA text for a finalized answer."};
 const readers={
  authenticate:auth,nowMs:()=>Date.now(),
  // The synthetic server mimics SQL refusing a correct or unanswered item.
  readCurrentScope:async()=>state.active&&state.answerState==="incorrect"?screen():null,
  readProtected:async()=>({proof:"owner_bound_assessment_guard_v1",
   ownerId:OWNER,contextRevision:5,protected:state.protected}),
  verifySubjectRights:async()=>({proof:"server_entitlement_v1",
   ownerId:OWNER,contextRevision:5,subjectKey:"biology",
   feature:"practice_card",allowed:state.rights}),
  readPracticeSourceCard:async()=>({...card}),
  readApprovedSource:async()=>({
   approved:state.source,rightsApproved:true,runtimeAllowed:true,
   contentApproved:true,conflict:false,qaPassed:true,locale:"ru",
   subjectKey:"biology",sourceKey:SOURCE,
   cardHash:state.editorHash,contentVersion:state.editorVersion,
   publicationRevision:state.editorRevision})
 };
 const base=createKnowledgeFirstReadOnlyGate(readers);
 const knowledge={__syntheticQaOnly:true,resolve:base.resolve};
 const services={
  __syntheticQaOnly:true,
  authenticate:async t=>{const v=await auth(t);
   return v?{authenticated:true,userId:v.userId}:null;},
  getServerTimeMs:async()=>Date.now(),
  isProtected:async()=>state.protected,
  getGlobalState:async()=>({uiEnabled:true,gatewayEnabled:true,
   killSwitch:false,releaseApproved:true}),
  // Every Edge recheck mirrors the authoritative SQL read-time incorrect-answer rule.
  getScopedContext:async()=>state.active&&state.answerState==="incorrect"?({
   ownerId:OWNER,routeAuthority:"unified_ai",active:true,
   protectedAssessment:false,expiresAtMs:deadline,
   contextRevision:"rev_5",surface:"practice",subject:"biology",
   feature:"answer_explanation",topic:"question_42"}):null,
  getSubjectActive:async()=>true,
  isRolloutAuthorized:async()=>state.rights,
  getPublishedRelease:async ref=>state.edgeRelease?({
   ready:true,...ref,source_id:state.edgeSource,
   source_version:state.edgeVersion,source_hash:state.edgeHash,
   revision:state.edgeRevision}):null,
  getLiveSourceProof:async ref=>({
   ...ref,approved:state.source,rightsApproved:true,
   runtimeAllowed:true,sourceConflict:false,
   source_id:state.edgeSource,source_version:state.edgeVersion,
   source_hash:state.edgeHash}),
  getPolicy:async()=>"free_qa_v2",
  getSourceBundle:async bound=>{
   state.bundleCalls++;
   if(state.contentRevokedDuringBundle)state.edgeRelease=false;
   return{approved:true,rightsApproved:true,integrityVerified:true,
    qaPassed:true,runtimeAllowed:true,conflict:false,
    sourceId:bound.sourceId,sourceVersion:bound.sourceVersion,
    sourceHash:state.bundleVariantMismatch==="hash"?"b".repeat(64):bound.sourceHash,
    revision:state.bundleVariantMismatch==="revision"?bound.revision+1:bound.revision,
    variants:{explain_error:"Reviewed exact prepared QA explanation for the answered question."}};
  },
  providerBudgetAllows:async()=>false,
  generateSynthetic:async()=>{state.providerCalls++;throw Error("model forbidden")},
  reserveProviderSpend:async()=>({allowed:false}),
  dispatchProviderSpend:async()=>({allowed:false}),
  finishProviderSpend:async()=>({ok:false}),
  reserveUsage:async req=>{
   state.chargeCalls++;
   if(state.attempts.has(req.requestId))
    return{allowed:false,reason:"request_in_progress"};
   if(state.units>=3)return{allowed:false,reason:"route_insufficient"};
   state.units++;
   state.attempts.set(req.requestId,{...req,status:"reserved"});
   if(state.changeOnReserve==="version")state.edgeVersion="v2";
   if(state.changeOnReserve==="hash")state.edgeHash="b".repeat(64);
   if(state.changeOnReserve==="revision")state.edgeRevision=2;
   if(state.changeOnReserve==="correct")state.answerState="correct";
   return{allowed:true};
  },
  claimDelivery:async req=>{
   if(state.claims.has(req.requestId))return{allowed:false};
   if(state.attempts.get(req.requestId)?.requestFingerprint!==req.requestFingerprint)
    return{allowed:false};
   state.claims.set(req.requestId,req);return{allowed:true};
  },
  finishDelivery:async req=>{
   const item=state.attempts.get(req.requestId);
   if(!item||item.status!=="reserved"||
     !state.claims.has(req.requestId))return{ok:false};
   item.status=req.outcome;
   if(req.outcome==="released")state.units--;
   return{ok:true};
  }
 };
 const bridge=createPreparedKnowledgeFirstQaBridge({
  knowledge,services,allowedOrigins:[ORIGIN]
 });
 const call=(values={},req={})=>bridge.serve({method:"POST",
  origin:ORIGIN,authorization:TOKEN,
  bodyText:JSON.stringify({intent:"answer",requestId:RID,
   contextHandle:CTX,appLocale:"ru",promptKey:"explain_error",...values}),
  ...req
 });
 return{state,call,bridge};
}
test("Synthetic CI flag and explicit in-memory dependencies are mandatory",()=>{
 const env=process.env.ICLUB_AI_QA_BOUND_PREPARED;
 process.env.ICLUB_AI_QA_BOUND_PREPARED="not-approved";
 a.throws(()=>createPreparedKnowledgeFirstQaBridge({}),/synthetic_ci_only/);
 process.env.ICLUB_AI_QA_BOUND_PREPARED=env;
 if(env===undefined)delete process.env.ICLUB_AI_QA_BOUND_PREPARED;
 a.throws(()=>createPreparedKnowledgeFirstQaBridge({
  knowledge:{resolve:async()=>({ok:true})},services:{__syntheticQaOnly:true},
  allowedOrigins:[ORIGIN]}),/trusted_synthetic_dependencies_required/);
});
test("Knowledge First exact verified Practice source -> existing server prepared route",async()=>{
 const x=rig(),r=await x.call();
 a.equal(r.status,200);a.equal(r.body.ok,true,JSON.stringify(r));
 a.match(r.body.reply,/Reviewed exact prepared QA explanation/);
 a.equal(x.state.units,1,"Prepared QA route uses one temporary unit");
 a.equal(x.state.attempts.get(RID).status,"completed");
 a.equal(x.state.providerCalls,0);
 a.equal(x.state.bundleCalls,1);
 a.equal(x.state.chargeCalls,1);
});
test("No source, entitlement or active exam means no prepared text, no debit",async()=>{
 for(const field of ["source","rights","active","protected"]){
  const x=rig();x.state[field]=field==="protected"?true:false;
  const r=await x.call();
  a.notEqual(r.body.ok,true,field);
  a.equal(x.state.units,0,field);
  a.equal(x.state.chargeCalls,0,field);
  a.equal(x.state.providerCalls,0,field);
  if(field==="protected")a.equal(r.body.state,"hidden");
 }
});
test("Independent server source must match the Knowledge First source ID",async()=>{
 const x=rig();x.state.edgeSource="practice:biology:p1:q77:ru:v1";
 const r=await x.call();
 a.notEqual(r.body.ok,true);a.equal(x.state.units,0);
 a.equal(x.state.bundleCalls,0);
});
test("Revocation during source fetch is blocked again after reserve, with refund",async()=>{
 const x=rig();x.state.contentRevokedDuringBundle=true;
 const r=await x.call();
 a.notEqual(r.body.ok,true);
 a.equal(x.state.units,0);
 // Revocation before metering may also fail without any reservation.
 a.equal(x.state.providerCalls,0);
});
test("Replay, generated questions and browser-forged academic fields are refused",async()=>{
 const x=rig();a.equal((await x.call()).body.ok,true);
 const second=await x.call();
 a.notEqual(second.body.ok,true);a.equal(x.state.units,1);
 for(const change of [
  {question:"Write a new answer",promptKey:undefined},
  {subject:"chemistry"},
  {promptKey:"main"},
  {question:"Try to reveal keys"}
 ]){
  const t=rig();const r=await t.call(change);
  a.notEqual(r.body.ok,true);
  a.equal(t.state.units,0);
 }
 a.equal((await rig().call({}, {origin:"https://prod.invalid"})).status,403);
 a.equal((await rig().call({}, {authorization:"Bearer stolen"})).body.ok,false);
});
test("Correct, unanswered and ungraded Practice cannot become AI error explanations",async()=>{
 for(const answerState of ["correct","unanswered","unknown"]){
  const x=rig();x.state.answerState=answerState;
  const r=await x.call();
  a.notEqual(r.body.ok,true,answerState);
  a.equal(x.state.bundleCalls,0,answerState);
  a.equal(x.state.units,0,answerState);
  a.equal(x.state.chargeCalls,0,answerState);
  a.equal(x.state.providerCalls,0,answerState);
 }
 const missing=rig();missing.state.missingIncorrectProof=true;
 a.equal((await missing.call()).body.ok,false);
 a.equal(missing.state.units,0);
});
test("All four source attributes must match independent publication and bundle",async()=>{
 for(const key of ["version","hash","revision"]){
  const x=rig();
  if(key==="version")x.state.edgeVersion="v2";
  if(key==="hash")x.state.edgeHash="b".repeat(64);
  if(key==="revision")x.state.edgeRevision=2;
  const r=await x.call();
  a.notEqual(r.body.ok,true,key);
  a.equal(x.state.bundleCalls,0,key);
  a.equal(x.state.units,0,key);
 }
 for(const key of ["hash","revision"]){
  const x=rig();x.state.bundleVariantMismatch=key;
  const r=await x.call();
  a.notEqual(r.body.ok,true,key);
  a.equal(x.state.units,0,key);
 }
});
test("Wrong answer and version/hash/revision revocation after quota reserve refunds",async()=>{
 for(const key of ["correct","version","hash","revision"]){
  const x=rig();x.state.changeOnReserve=key;
  const r=await x.call();
  a.notEqual(r.body.ok,true,key);
  a.equal(x.state.attempts.get(RID)?.status,"released",key);
  a.equal(x.state.units,0,key);
  a.equal(x.state.providerCalls,0,key);
  a.equal(x.state.chargeCalls,1,key);
 }
});
