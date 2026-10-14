"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {createHash}=require("node:crypto");
const {readFileSync}=require("node:fs");
const {QAHomeApprovedPriority,productPolicyValid}=require("./ai-layer-v21-p6-home-approved-priority.cjs");
const decision=require("./ai-layer-v21-owner-product-decisions-20261014.json");
const U="11111111-1111-4111-8111-111111111111",H="22222222-2222-4222-8222-222222222222";
const hash="a".repeat(64),src="b".repeat(64);
const action=(code,id,subject="mathematics")=>({
 actionId:id,actionCode:code,subjectKey:subject,
 evidenceRevision:5,evidenceHash:hash,sourceVersion:"synthetic-v1",sourceHash:src
});
const P=action("review_finalized_practice","practice_101");
const T=action("review_open_tour_archive","archive_102");
const C=action("continue_enrolled_subject","continue_103");
function setup(actions=[P,T,C]){
 const state={now:100000,approved:true,academic:true,editorial:true,reads:0,
  screen:{ownerId:U,contextHandle:H,surface:"home",currentView:"home",
   revision:12,expiresAtMs:150000},
  plan:{ownerId:U,screenRevision:12,planRevision:9,authorityHash:hash,
   issuedAtMs:95000,expiresAtMs:150000,policyVersion:decision.homeNextActions.policyVersion,
   priorityCoverage:{activeEnrollments:true,finalizedPractice:true,
    openTourArchives:true,ownerScope:true},actions:structuredClone(actions)}};
 const services={
  nowMs:()=>state.now,
  readCurrentScreen:async()=>{state.reads++;return structuredClone(state.screen);},
  readServerPlan:async()=>structuredClone(state.plan),
  verifyPlanAuthority:async()=>state.approved,
  verifyAcademicEvidence:async(_,action)=>({allowed:state.academic,
   evidenceHash:action.evidenceHash,evidenceRevision:action.evidenceRevision}),
  verifyEditorialRelease:async(_,action)=>({ready:state.editorial,
   sourceHash:action.sourceHash,sourceVersion:action.sourceVersion})
 };
 const run=(userId=U)=>new QAHomeApprovedPriority(services).choose({
  userId,contextHandle:H,locale:"ru"
 });
 return{state,services,run};
}
test("§77 exact 18-copy approval is pinned to unchanged Git blob; no rights/release approval",()=>{
 const raw=readFileSync("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json");
 const prefix=Buffer.from("blob "+raw.length+"\0");
 const blob=createHash("sha1").update(prefix).update(raw).digest("hex");
 a.equal(blob,decision.navigationCopy.exactDraftGitBlobSha);
 a.equal(decision.navigationCopy.productApproved,true);
 a.equal(decision.accessibility.productApproved,true);
 a.equal(productPolicyValid(decision),true);
 for(const field of Object.keys(decision.release))a.equal(decision.release[field],false,field);
});
test("§78 signed exhaustive planner evidence chooses Practice before Tour and continuation",async()=>{
 for(const actions of [[P,T,C],[T,P],[C,T,P],[P],[P,C]]){
  const v=await setup(actions).run();
  a.equal(v.ready,true);a.equal(v.status,"candidate_only");
  a.equal(v.actionCode,"review_finalized_practice");
  a.equal(v.actionId,"practice_101");a.equal(v.releaseAllowed,false);
  a.equal(v.ownerId,undefined);
  a.equal(v.questionId,undefined);
 }
});
test("§78 Tour beats continuation; continuation is permitted only with verified complete scan",async()=>{
 for(const actions of [[T,C],[C,T],[T]]){
  const v=await setup(actions).run();a.equal(v.actionCode,"review_open_tour_archive");
 }
 const only=await setup([C]).run();
 a.equal(only.status,"candidate_only");
 a.equal(only.actionCode,"continue_enrolled_subject");
});
test("§78 same category across two subjects returns choices, NEVER invisible cross-subject ranking",async()=>{
 const x=setup([P,action("review_finalized_practice","practice_202","economics"),T]);
 const z=await x.run();
 a.equal(z.status,"selection_required");
 a.deepEqual(z.candidateActionIds,["practice_101","practice_202"]);
 a.equal(z.actionId,undefined);a.equal(z.subjectKey,undefined);
 a.equal(z.releaseAllowed,false);
});
test("§78 incomplete enumeration, expired/stale screen, unauthenticated and unknown policy deny",async()=>{
 const modifications=[
  state=>{delete state.plan.priorityCoverage;},
  state=>{state.plan.priorityCoverage.finalizedPractice=false;},
  state=>{state.plan.priorityCoverage.openTourArchives="true";},
  state=>{state.plan.priorityCoverage.otherCategory=true;},
  state=>{state.plan.policyVersion="unapproved_policy";},
  state=>{state.plan.ownerId="33333333-3333-4333-8333-333333333333";},
  state=>{state.plan.screenRevision=11;},
  state=>{state.screen.currentView="profile";},
  state=>{state.now=150000;},
  state=>{state.approved=false;},
  state=>{state.academic=false;},
  state=>{state.editorial=false;},
  state=>{state.plan.actions=[];},
  state=>{state.plan.actions[0].actionCode="grade_changer";},
  state=>{state.plan.actions[0].subjectKey="something;select *";}
 ];
 for(const mutate of modifications){
  const x=setup();mutate(x.state);
  const z=await x.run();
  a.equal(z.ready,false,mutate.toString().slice(0,70));
  a.equal(z.reason,"in_development");
 }
 const other=await setup().run("44444444-4444-4444-8444-444444444444");
 a.equal(other.ready,false);
});
test("§78 revoking the source during async verification denies the entire recommendation",async()=>{
 const x=setup();let checks=0;
 x.services.verifyEditorialRelease=async(_,entry)=>({
  ready:++checks<=3,sourceHash:entry.sourceHash,sourceVersion:entry.sourceVersion
 });
 const z=await x.run();a.equal(z.ready,false);
});
test("§78 changing the signed plan midway fails closed",async()=>{
 const x=setup();let count=0;
 x.services.readServerPlan=async()=>{
  if(++count===2)x.state.plan.actions.reverse();
  return structuredClone(x.state.plan);
 };
 a.equal((await x.run()).ready,false);
});
test("§78 changing approved policy or enabling live flags cannot pass",()=>{
 const bad=structuredClone(decision);
 bad.homeNextActions.order=["continue_enrolled_subject","review_finalized_practice",
  "review_open_tour_archive"];
 a.equal(productPolicyValid(bad),false);
 const other=structuredClone(decision);other.release.productionDeployApproved=true;
 a.equal(productPolicyValid(other),false);
 a.throws(()=>new QAHomeApprovedPriority(setup().services,bad),/unapproved_home_policy/);
});
