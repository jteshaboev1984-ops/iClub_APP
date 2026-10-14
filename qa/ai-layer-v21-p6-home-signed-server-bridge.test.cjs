"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {buildHomePlan,verifySignedPlan}=
 require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const {QAHomeApprovedPriority}=
 require("./ai-layer-v21-p6-home-approved-priority.cjs");
const U="11111111-1111-4111-8111-111111111111";
const H="33333333-3333-4333-8333-333333333333";
const evHash="a".repeat(64),sourceHash="b".repeat(64);
const clone=x=>structuredClone(x);
const action=(code,subject,evidenceId)=>({
 actionCode:code,subjectKey:subject,evidenceId,evidenceRevision:12
});
const P=action("review_finalized_practice","economics",901);
const T=action("review_open_tour_archive","mathematics",100);
const C=action("continue_enrolled_subject","biology",10);
function fixture(candidates=[P]){
 const t={
  now:100000,authorized:true,academic:true,editorial:true,releaseRights:true,
  readCounts:0,changeScan:false,
  screen:{ownerId:U,contextHandle:H,surface:"home",currentView:"home",
   revision:12,expiresAtMs:150000},
  scan:{allowed:true,review_only:true,source_publication:false,rights_approved:false,
   owner_id:U,context_handle:H,screen_revision:12,
   policy_version:"home_next_actions_20261014_v1",complete_scan:true,
   candidates:clone(candidates)}
 };
 const s={
  signingKey:Buffer.alloc(32,7),nowMs:()=>t.now,
  readCurrentScreen:async()=>clone(t.screen),
  readServerScan:async()=>{
   const scan=clone(t.scan);
   if(t.changeScan&&++t.readCounts===2)scan.candidates=[];
   return scan;
  },
  verifySubjectAccess:async()=>t.authorized,
  verifyAcademicEvidence:async(_,candidate)=>({
   allowed:t.academic,evidenceId:candidate.evidenceId,
   evidenceRevision:candidate.evidenceRevision,
   subjectKey:candidate.subjectKey,actionCode:candidate.actionCode,
   evidenceHash:evHash
  }),
  readEditorialRelease:async()=>({
   ready:t.editorial,rightsApproved:t.releaseRights,
   contentApproved:true,sourceConflict:false,
   sourceHash,sourceVersion:"synthetic-reviewed-v1"
  })
 };
 return{t,s,run:()=>buildHomePlan(s,{userId:U,contextHandle:H,locale:"ru"})};
}
test("§88 private-key-signed Home plan comes only from owner scan with all independent gates",async()=>{
 const x=fixture([P]),r=await x.run();
 a.equal(r.ready,true);a.equal(r.reviewOnly,true);
 a.equal(r.providerAllowed,false);a.equal(r.productionAllowed,false);
 a.equal(verifySignedPlan(r.plan,x.s.signingKey),true);
 a.equal(r.plan.policyVersion,"home_next_actions_20261014_v1");
 a.deepEqual(r.plan.actions.map(a=>a.actionCode),["review_finalized_practice"]);
 a.equal(Object.values(r.plan.priorityCoverage).every(x=>x===true),true);
 a.equal(JSON.stringify(r).includes("signingKey"),false);
 a.equal(JSON.stringify(r).includes("correctAnswer"),false);
 const altered=clone(r.plan);altered.actions[0].subjectKey="biology";
 a.equal(verifySignedPlan(altered,x.s.signingKey),false);
});
test("§88 exactly verified commercial study/competitive intents are required",async()=>{
 const intents=[];
 const x=fixture([T,C]);
 x.s.verifySubjectAccess=async(_,subject,intent)=>{
  intents.push([subject,intent]);return true;
 };
 const r=await x.run();
 a.equal(r.ready,true);
 a.deepEqual(intents.slice(0,2),[["mathematics","competitive"],["biology","study"]]);
 a.equal(intents.length,4,"Repeat entitlement checks immediately before signing");
});
test("§88 deny if any authorization, academic, publication or integrity check is absent",async()=>{
 const flips=[
  t=>{t.authorized=false},
  t=>{t.academic=false},
  t=>{t.editorial=false},
  t=>{t.releaseRights=false},
  t=>{t.screen.currentView="profile"},
  t=>{t.screen.ownerId="22222222-2222-4222-8222-222222222222"},
  t=>{t.scan.owner_id="22222222-2222-4222-8222-222222222222"},
  t=>{t.scan.source_publication=true},
  t=>{t.scan.complete_scan=false},
  t=>{t.scan.policy_version="wrong_version"},
  t=>{t.scan.candidates[0].evidenceRevision=0},
  t=>{t.scan.candidates[0].actionCode="mark_correct"},
  t=>{t.now=151000}
 ];
 for(const mutate of flips){
  const x=fixture();mutate(x.t);
  a.equal((await x.run()).ready,false,mutate.toString().slice(0,60));
 }
 for(const actions of [[],[P,T,C,P]]){
  a.equal((await fixture(actions).run()).ready,false);
 }
 const x=fixture();x.s.signingKey=Buffer.alloc(8);
 a.equal((await x.run()).ready,false);
});
test("§88 a changing server scan across awaits cannot be signed",async()=>{
 const x=fixture();x.t.changeScan=true;
 a.equal((await x.run()).ready,false);
});
test("§88 the signed plan integrates with existing owner-screen, evidence and Home priority checks",async()=>{
 const x=fixture([P]);
 const signed=await x.run();a.equal(signed.ready,true);
 const services={
  nowMs:()=>x.t.now,
  readCurrentScreen:x.s.readCurrentScreen,
  readServerPlan:async()=>clone(signed.plan),
  verifyPlanAuthority:async(user,screen,plan)=>
   user===U&&screen.contextHandle===H&&verifySignedPlan(plan,x.s.signingKey),
  verifyAcademicEvidence:async(_,a)=>({allowed:true,
   evidenceRevision:a.evidenceRevision,evidenceHash:a.evidenceHash}),
  verifyEditorialRelease:async(_,a)=>({ready:true,
   sourceHash:a.sourceHash,sourceVersion:a.sourceVersion})
 };
 const chosen=await new QAHomeApprovedPriority(services).choose({
  userId:U,contextHandle:H,locale:"ru"
 });
 a.equal(chosen.ready,true);
 a.equal(chosen.status,"candidate_only");
 a.equal(chosen.actionCode,"review_finalized_practice");
 a.equal(chosen.releaseAllowed,false);
 const stale=clone(signed.plan);stale.actions[0].evidenceHash="c".repeat(64);
 services.readServerPlan=async()=>stale;
 a.equal((await new QAHomeApprovedPriority(services).choose({
  userId:U,contextHandle:H,locale:"ru"})).ready,false);
});
