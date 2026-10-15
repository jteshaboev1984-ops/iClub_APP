"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {buildHomePlan,verifySignedPlan}=
 require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const {QAHomeApprovedPriority}=
 require("./ai-layer-v21-p6-home-approved-priority.cjs");
const {validateBeforeHomeDelivery}=
 require("./ai-layer-v21-p6-home-delivery-gate.cjs");
const USER="11111111-1111-4111-8111-111111111111";
const HANDLE="33333333-3333-4333-8333-333333333333";
const E="a".repeat(64),S="b".repeat(64);
const clone=x=>structuredClone(x);
function setup(withTie=false){
 const state={
  clock:100000,entitled:true,rights:true,academic:true,screenRev:12,
  scanRev:12,source:S,hash:E,complete:true,
  subject:"economics",locale:"ru",candidates:[
   {actionCode:"review_finalized_practice",subjectKey:"economics",
    evidenceId:901,evidenceRevision:12},
   ...(withTie?[{actionCode:"review_finalized_practice",subjectKey:"biology",
    evidenceId:902,evidenceRevision:12}]:[])
  ]
 };
 const s={
  signingKey:Buffer.alloc(32,42),nowMs:()=>state.clock,
  readCurrentScreen:async()=>({ownerId:USER,contextHandle:HANDLE,
   surface:"home",currentView:"home",revision:state.screenRev,expiresAtMs:150000}),
  readServerScan:async()=>({allowed:true,review_only:true,
   source_publication:false,rights_approved:false,owner_id:USER,
   context_handle:HANDLE,screen_revision:state.scanRev,
   policy_version:"home_next_actions_20261014_v1",complete_scan:state.complete,
   candidates:clone(state.candidates).map(v=>v.evidenceId===901?
    {...v,subjectKey:state.subject}:v)}),
  verifySubjectAccess:async(user,subject,intent)=>({
   allowed:state.entitled,verified:state.entitled,userId:user,subjectKey:subject,intent,
   revision:4,source:"server_enforced_subject_access_v1",mode:"commercial",
   competitiveSelectionVerified:false}),
  verifyAcademicEvidence:async(user,v)=>({
   allowed:state.academic,evidenceId:v.evidenceId,evidenceRevision:v.evidenceRevision,
   subjectKey:v.subjectKey,actionCode:v.actionCode,evidenceHash:state.hash}),
  readEditorialRelease:async(locale,code,subject)=>({
   ready:state.rights&&locale===state.locale,rightsApproved:state.rights,
   contentApproved:true,sourceConflict:false,sourceHash:state.source,
   sourceVersion:"synthetic-v1"})
 };
 return{state,s};
}
async function signedFixture(withTie=false){
 const f=setup(withTie),{s}=f;
 const built=await buildHomePlan(s,{userId:USER,contextHandle:HANDLE,locale:"ru"});
 assert.equal(built.ready,true);
 const checkServices={
  nowMs:s.nowMs,readCurrentScreen:s.readCurrentScreen,
  readServerPlan:async()=>built.plan,
  verifyPlanAuthority:async(owner,screen,plan)=>owner===USER&&
   screen.contextHandle===HANDLE&&verifySignedPlan(plan,s.signingKey),
  verifyAcademicEvidence:async(_,a)=>({allowed:f.state.academic,
   evidenceRevision:a.evidenceRevision,evidenceHash:f.state.hash}),
  verifyEditorialRelease:async(locale,a)=>({ready:f.state.rights,
   sourceHash:f.state.source,sourceVersion:a.sourceVersion})
 };
 const choice=await new QAHomeApprovedPriority(checkServices).choose({
  userId:USER,contextHandle:HANDLE,locale:"ru"});
 assert.equal(choice.ready,true);
 return{...f,plan:built.plan,choice};
}
const params=(f,more={})=>({
 userId:USER,contextHandle:HANDLE,locale:"ru",plan:f.plan,choice:f.choice,...more});
test("§104 delivery checks fresh complete scan + current commercial and rights state",async()=>{
 const f=await signedFixture();
 const d=await validateBeforeHomeDelivery(f.s,params(f));
 assert.equal(d.ready,true);assert.equal(d.releaseAllowed,false);
 assert.equal(d.actionCode,"review_finalized_practice");
 assert.equal(d.subjectKey,"economics");
 assert.equal(d.expiresAtMs,f.plan.expiresAtMs);
 assert.equal(JSON.stringify(d).includes("authorityHash"),false);
 assert.equal(JSON.stringify(d).includes("evidenceHash"),false);
});
test("§105 same-priority tie must not expose database evidence or action IDs",async()=>{
 const f=await signedFixture(true);
 assert.equal(f.choice.status,"selection_required");
 const r=await validateBeforeHomeDelivery(f.s,params(f));
 assert.equal(r.ready,true);
 assert.equal(r.status,"selection_required");
 assert.deepEqual(r.choices,[
  {actionCode:"review_finalized_practice",subjectKey:"biology"},
  {actionCode:"review_finalized_practice",subjectKey:"economics"}
 ]);
 assert.equal(Object.hasOwn(r,"candidateActionIds"),false);
 assert.equal(JSON.stringify(r).includes("901"),false);
 assert.equal(JSON.stringify(r).includes("902"),false);
 const poisoned=clone(f.choice);
 poisoned.candidateActionIds=[poisoned.candidateActionIds[0]];
 assert.equal((await validateBeforeHomeDelivery(f.s,params(f,{choice:poisoned}))).ready,false);
});
test("§104 a revoked commercial, source, academic, screen or candidate never leaves server",async()=>{
 const changes=[
  s=>{s.entitled=false},s=>{s.rights=false},s=>{s.academic=false},
  s=>{s.screenRev=13},s=>{s.scanRev=13},s=>{s.complete=false},
  s=>{s.subject="biology"},s=>{s.source="c".repeat(64)},
  s=>{s.hash="d".repeat(64)},s=>{s.clock=131000}
 ];
 for(const change of changes){
  const f=await signedFixture();change(f.state);
  const r=await validateBeforeHomeDelivery(f.s,params(f));
  assert.equal(r.ready,false,change.toString());
 }
});
test("§104 exact chosen action cannot be replaced or cross-replayed",async()=>{
 const f=await signedFixture();
 for(const change of [
  p=>{p.status="selection_required"},
  p=>{p.actionCode="review_open_tour_archive"},
  p=>{p.subjectKey="biology"},
  p=>{p.actionId="next_other"},
  p=>{p.expiresAtMs+=10},
  p=>{p.ready=false}
 ]){
  const choice=clone(f.choice);change(choice);
  assert.equal((await validateBeforeHomeDelivery(f.s,params(f,{choice}))).ready,false);
 }
 const corrupt=clone(f.plan);corrupt.actions[0].subjectKey="biology";
 assert.equal((await validateBeforeHomeDelivery(f.s,params(f,{plan:corrupt}))).ready,false);
 assert.equal((await validateBeforeHomeDelivery(f.s,params(f,{locale:"en"}))).ready,false);
 assert.equal((await validateBeforeHomeDelivery(f.s,params(f,{userId:
  "22222222-2222-4222-8222-222222222222"}))).ready,false);
});
test("§104 reject auth/source/screen revocations specifically during final async delivery read",async()=>{
 for(const target of ["rights","entitlement","screen","scan"]){
  const f=await signedFixture();
  if(target==="rights"){
   const read=f.s.readEditorialRelease;let n=0;
   f.s.readEditorialRelease=async(...args)=>{
    const result=await read(...args);if(++n===1)f.state.rights=false;return result;
   };
  }else if(target==="entitlement"){
   const read=f.s.verifySubjectAccess;let n=0;
   f.s.verifySubjectAccess=async(...args)=>{
    const result=await read(...args);
    if(++n===1){f.state.entitled=false;f.state.screenRev=13;}
    return result;
   };
  }else if(target==="screen"){
   const read=f.s.readCurrentScreen;let n=0;
   f.s.readCurrentScreen=async(...args)=>{
    const result=await read(...args);if(++n===1)f.state.screenRev=13;
    return result;
   };
  }else{
   const read=f.s.readServerScan;let n=0;
   f.s.readServerScan=async(...args)=>{
    const result=await read(...args);if(++n===1)f.state.scanRev=13;
    return result;
   };
  }
  assert.equal((await validateBeforeHomeDelivery(f.s,params(f))).ready,false,target);
 }
});
