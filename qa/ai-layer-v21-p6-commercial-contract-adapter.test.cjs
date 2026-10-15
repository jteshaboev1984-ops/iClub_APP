"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {makeCommercialProofAdapter,checkContractProof}=
 require("./ai-layer-v21-p6-commercial-contract-adapter.cjs");
const U="11111111-1111-4111-8111-111111111111";
const V="22222222-2222-4222-8222-222222222222";
function snapshot(intent="study"){
 return{
  guard:{allowed:true,mode:"commercial",reason:"subject_selected"},
  capabilities:{resolved:true,ai_generation_entitled:true,
   plan_source:"explicit_entitlement",plan_code:"pro",
   all_available_subjects:false},
  config:{subjectLimitsMode:"enforced",grandfatherSnapshotCompleted:true,revision:12},
  enrollment:{userId:U,subjectKey:"economics",mode:intent,active:true,revision:13},
  slot:{userId:U,subjectKey:"economics",studySelected:true,
   competitiveSelected:intent==="competitive",revision:14},
  subjectRecord:{subjectKey:"economics",isActive:true,type:"main"},
  featureGate:{origin:"trusted_qa_server_only",scope:"isolated_qa_only",
   feature:"home_next_actions",approved:true,productionAllowed:false,revision:15}
 };
}
test("§100 enforced commercial, selected subject, independently entitled AI and QA gate",()=>{
 const p=checkContractProof(U,"economics","study",snapshot());
 assert.equal(p.allowed,true);
 assert.equal(p.verified,true);assert.equal(p.userId,U);
 assert.equal(p.subjectKey,"economics");assert.equal(p.intent,"study");
 assert.equal(p.source,"server_enforced_subject_access_v1");
 assert.equal(p.revision,15);
 assert.equal(p.providerAllowed,false);assert.equal(p.productionAllowed,false);
 assert.equal(p.qaOnly,true);
 const competitive=checkContractProof(U,"economics","competitive",snapshot("competitive"));
 assert.equal(competitive.allowed,true);
 assert.equal(competitive.competitiveSelectionVerified,true);
});
test("§100 all-subjects plan needs guard plan_all_subjects and actual enrolment",()=>{
 const p=snapshot();
 p.capabilities.all_available_subjects=true;
 p.guard.reason="plan_all_subjects";p.slot=null;
 assert.equal(checkContractProof(U,"economics","study",p).allowed,true);
 assert.equal(checkContractProof(U,"economics","competitive",{...p,
  enrollment:{...p.enrollment,mode:"competitive"}}).allowed,false,
  "No selected competitive slot cannot be inferred from plan");
});
test("§100 block shadow, pass-through, grandfather and capacity-only 'allowed' results",()=>{
 for(const mode of ["shadow","legacy_passthrough","grandfathered","unexpected"]){
  const p=snapshot();p.guard.mode=mode;
  assert.equal(checkContractProof(U,"economics","study",p).allowed,false,mode);
 }
 for(const reason of ["study_slot_available","competitive_slot_available",
  "subject_not_selected","legacy_access_preserved","subject_limits_off",
  "grandfather_snapshot_incomplete","unknown"]){
  const p=snapshot();p.guard.reason=reason;
  assert.equal(checkContractProof(U,"economics","study",p).allowed,false,reason);
 }
});
test("§100 reject all unverified commercial, owner and feature-grant states",()=>{
 const mutations=[
  p=>{p.guard.allowed=false},
  p=>{p.config.subjectLimitsMode="off"},
  p=>{p.config.subjectLimitsMode="shadow"},
  p=>{p.config.grandfatherSnapshotCompleted=false},
  p=>{p.config.revision=0},
  p=>{p.capabilities.resolved=false},
  p=>{p.capabilities.ai_generation_entitled=false},
  p=>{p.capabilities.plan_source="unknown"},
  p=>{p.capabilities.plan_code=""},
  p=>{p.enrollment.userId=V},
  p=>{p.enrollment.subjectKey="biology"},
  p=>{p.enrollment.mode="competitive"},
  p=>{p.enrollment.active=false},
  p=>{p.enrollment.revision=0},
  p=>{p.subjectRecord.isActive=false},
  p=>{p.subjectRecord.subjectKey="biology"},
  p=>{p.slot.userId=V},
  p=>{p.slot.subjectKey="biology"},
  p=>{p.slot.studySelected=false},
  p=>{p.slot.revision=0},
  p=>{p.featureGate.approved=false},
  p=>{p.featureGate.productionAllowed=true},
  p=>{p.featureGate.scope="production"},
  p=>{p.featureGate.origin="browser_cache"},
  p=>{p.featureGate.revision=0}
 ];
 for(const mutate of mutations){
  const p=snapshot();mutate(p);
  assert.equal(checkContractProof(U,"economics","study",p).allowed,false,
   mutate.toString().slice(0,80));
 }
 for(const v of [undefined,null,{},[],false]){
  assert.equal(checkContractProof(U,"economics","study",v).allowed,false);
 }
 assert.equal(checkContractProof(V,"economics","study",snapshot()).allowed,false);
});
test("§100 competitive grant requires actual selected mode, main subject and two selected flags",()=>{
 for(const mut of [
  p=>{p.subjectRecord.type="language"},
  p=>{p.slot.competitiveSelected=false},
  p=>{p.slot.studySelected=false},
  p=>{p.slot=null},
  p=>{p.enrollment.mode="study"},
  p=>{p.guard.reason="competitive_slot_available"}
 ]){
  const p=snapshot("competitive");mut(p);
  assert.equal(checkContractProof(U,"economics","competitive",p).allowed,false,
   mut.toString());
 }
});
test("§100 async trusted reader rechecked, revocation after initial success blocks",async()=>{
 const x=snapshot();
 let n=0;
 const adapter=makeCommercialProofAdapter({readCommercialSnapshot:async()=>{
  const s=structuredClone(x);
  if(++n===2)s.slot.studySelected=false;
  return s;
 }});
 assert.equal((await adapter.verifySubjectAccess(U,"economics","study")).allowed,true);
 assert.equal((await adapter.verifySubjectAccess(U,"economics","study")).allowed,false);
 assert.equal(n,2);
});
test("§100 read exceptions/invalid input never leak authorization",async()=>{
 const a=makeCommercialProofAdapter({readCommercialSnapshot:async()=>{throw Error("offline")}});
 assert.equal((await a.verifySubjectAccess(U,"economics","study")).allowed,false);
 assert.equal((await a.verifySubjectAccess(U,"economics","drop table")).allowed,false);
 assert.equal((await a.verifySubjectAccess(V,"invalid' OR true--","study")).allowed,false);
 assert.throws(()=>makeCommercialProofAdapter({}),/trusted server/);
});
