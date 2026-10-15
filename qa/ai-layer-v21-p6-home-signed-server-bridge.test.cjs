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
const access=(user,subject,intent,allowed=true)=>({
 allowed,verified:true,userId:user,subjectKey:subject,intent,
 revision:4,source:"server_enforced_subject_access_v1",
 mode:"commercial",competitiveSelectionVerified:intent==="competitive"
});
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
  verifySubjectAccess:async(user,subject,intent)=>access(user,subject,intent,t.authorized),
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
  intents.push([subject,intent]);return access(U,subject,intent);
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
test("§89 shadow, legacy passthrough, wrong subject/owner and unverified competitive access deny",async()=>{
 for(const mutate of [
  p=>{p.mode="shadow"},
  p=>{p.mode="legacy_passthrough"},
  p=>{p.mode="grandfathered"},
  p=>{p.verified=false},
  p=>{p.userId="22222222-2222-4222-8222-222222222222"},
  p=>{p.subjectKey="mathematics"},
  p=>{p.revision=0},
  p=>{p.source="browser_cache"},
  p=>{p.intent="competitive"},
  p=>{p.allowed=false}
 ]){
  const x=fixture();
  x.s.verifySubjectAccess=async(u,subject,intent)=>{
   const p=access(u,subject,intent);mutate(p);return p;
  };
  a.equal((await x.run()).ready,false,mutate.toString().slice(0,70));
 }
 const x=fixture([T]);
 x.s.verifySubjectAccess=async(u,subject,intent)=>({
  ...access(u,subject,intent),competitiveSelectionVerified:false
 });
 a.equal((await x.run()).ready,false,
  "Competitive Tour requires independent current subject selection proof");
});
test("§88 a changing server scan across awaits cannot be signed",async()=>{
 const x=fixture();x.t.changeScan=true;
 a.equal((await x.run()).ready,false);
});

test("§92 academic evidence revoked or changed during commercial waits is never signed",async()=>{
 for(const kind of ["revoked","hash","revision"]){
  const x=fixture();let calls=0;
  x.s.verifyAcademicEvidence=async(_,v)=>{
   const isLate=++calls>1;
   return {allowed:!(isLate&&kind==="revoked"),
    evidenceId:v.evidenceId,
    evidenceRevision:isLate&&kind==="revision"?v.evidenceRevision+1:v.evidenceRevision,
    subjectKey:v.subjectKey,actionCode:v.actionCode,
    evidenceHash:isLate&&kind==="hash"?"c".repeat(64):evHash};
  };
  a.equal((await x.run()).ready,false,kind);
  a.equal(calls,2,"Fresh academic evidence required");
 }
});
test("§92 source rights, publication or hash revoked while awaiting other services denies",async()=>{
 for(const kind of ["rights","ready","sourceHash","sourceVersion"]){
  const x=fixture();let calls=0;
  x.s.readEditorialRelease=async()=>{
   const late=++calls>1;
   return {ready:!(late&&kind==="ready"),
    rightsApproved:!(late&&kind==="rights"),contentApproved:true,
    sourceConflict:false,
    sourceHash:late&&kind==="sourceHash"?"c".repeat(64):sourceHash,
    sourceVersion:late&&kind==="sourceVersion"?"new-version":"synthetic-reviewed-v1"};
  };
  a.equal((await x.run()).ready,false,kind);
  a.equal(calls,2,"Fresh published source validation required");
 }
});
test("§92 final screen or scan change AFTER evidence recheck cannot be signed",async()=>{
 for(const which of ["screen","scan"]){
  const x=fixture();let count=0;
  if(which==="screen"){
   x.s.readCurrentScreen=async()=>{
    const next=clone(x.t.screen);
    if(++count>=3)next.revision=13;
    return next;
   };
  }else{
   x.s.readServerScan=async()=>{
    const next=clone(x.t.scan);
    if(++count>=3)next.candidates[0].evidenceRevision+=1;
    return next;
   };
  }
  a.equal((await x.run()).ready,false,which);
  a.equal(count,3,"Final owner-bound read must be performed");
 }
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
