"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {QAHomeNextActionProof}=require("./ai-layer-v21-p6-home-next-action-proof.cjs");
const uid="11111111-1111-4111-8111-111111111111";
const handle="33333333-3333-4333-8333-333333333333",hash="a".repeat(64),source="b".repeat(64);
function setup(){
 const t={now:100000,reads:0,planApproved:true,evidenceApproved:true,editorialApproved:true,
  screen:{ownerId:uid,contextHandle:handle,surface:"home",currentView:"home",revision:12,expiresAtMs:150000},
  plan:{ownerId:uid,screenRevision:12,issuedAtMs:90000,expiresAtMs:150000,
   planRevision:8,authorityHash:hash,actions:[{
    actionId:"review_practice_101",actionCode:"review_finalized_practice",
    subjectKey:"economics",evidenceRevision:4,evidenceHash:hash,
    sourceVersion:"v1",sourceHash:source
   }]}};
 const svc={
  nowMs:()=>t.now,
  readCurrentScreen:async()=>{t.reads++;return {...t.screen}},
  readServerPlan:async()=>t.plan,
  verifyPlanAuthority:async()=>t.planApproved,
  verifyAcademicEvidence:async()=>({allowed:t.evidenceApproved,
   evidenceRevision:4,evidenceHash:hash}),
  verifyEditorialRelease:async()=>({ready:t.editorialApproved,
   sourceHash:source,sourceVersion:"v1"})
 };
 return{t,svc,run:()=>new QAHomeNextActionProof(svc).check({userId:uid,contextHandle:handle,locale:"ru"})};
}
test("Signed, independently verified Home snapshot yields only a handoff, not learner instructions",async()=>{
 const x=setup(),z=await x.run();
 a.equal(z.ready,true);a.equal(z.ownerId,uid);
 a.deepEqual(z.actionIds,["review_practice_101"]);
 a.equal(z.screenRevision,12);a.equal(z.planRevision,8);a.equal(x.t.reads,2);
 a.equal(JSON.stringify(z).includes("answer"),false);
});
test("Absent server planner, missing independent authority or academic proof denies",async()=>{
 for(const k of ["readCurrentScreen","readServerPlan","verifyPlanAuthority",
  "verifyAcademicEvidence","verifyEditorialRelease","nowMs"]){
  const x=setup();delete x.svc[k];
  a.throws(()=>new QAHomeNextActionProof(x.svc),/missing trusted service/);
 }
 const x=setup();x.svc.readServerPlan=async()=>null;a.equal((await x.run()).ready,false);
 for(const prop of ["planApproved","evidenceApproved","editorialApproved"]){
  const x=setup();x.t[prop]=false;a.equal((await x.run()).ready,false,prop);
 }
});
test("Expired, borrowed, replayed, unfinalized and forged Home states never admit",async()=>{
 const edits=[
  t=>{t.screen.ownerId="22222222-2222-4222-8222-222222222222"},
  t=>{t.screen.currentView="profile"},
  t=>{t.screen.surface="practice"},
  t=>{t.screen.expiresAtMs=t.now},
  t=>{t.plan.ownerId="22222222-2222-4222-8222-222222222222"},
  t=>{t.plan.screenRevision=11},
  t=>{t.plan.expiresAtMs=t.now},
  t=>{t.plan.expiresAtMs=t.screen.expiresAtMs+1},
  t=>{t.plan.issuedAtMs=t.now+1},
  t=>{t.plan.authorityHash="unauthenticated"},
  t=>{t.plan.actions=[]},
  t=>{t.plan.actions=Array.from({length:4},(_,i)=>({...t.plan.actions[0],actionId:"next_"+i}))},
  t=>{t.plan.actions[0].actionCode="mark_practice_correct"},
  t=>{t.plan.actions[0].subjectKey="unknown;drop"},
  t=>{t.plan.actions[0].evidenceRevision=0},
  t=>{t.plan.actions[0].evidenceHash="z".repeat(64)},
  t=>{t.plan.actions[0].sourceHash="z".repeat(64)},
  t=>{t.plan.actions.push({...t.plan.actions[0]})}
 ];
 for(const mutate of edits){const x=setup();mutate(x.t);
  a.equal((await x.run()).ready,false,mutate.toString().slice(0,85));}
 const x=setup();x.svc.readCurrentScreen=async()=>{
  x.t.reads++;return{...x.t.screen,revision:x.t.reads===2?13:12}
 };
 a.equal((await x.run()).ready,false,"replayed earlier tab screen");
 const y=setup();y.svc.verifyAcademicEvidence=async()=>{
  y.t.now=150000;return{allowed:true,evidenceHash:hash,evidenceRevision:4}
 };
 a.equal((await y.run()).ready,false,"expired during async source work");
});
test("One unverified locale blocks Home; fallback cannot bypass it",async()=>{
 const x=setup();
 a.equal((await new QAHomeNextActionProof(x.svc).check({
  userId:uid,contextHandle:handle,locale:"de"})).ready,false);
 x.t.editorialApproved=false;
 for(const locale of ["ru","uz","en"])
  a.equal((await new QAHomeNextActionProof(x.svc).check({userId:uid,
   contextHandle:handle,locale})).ready,false);
});
