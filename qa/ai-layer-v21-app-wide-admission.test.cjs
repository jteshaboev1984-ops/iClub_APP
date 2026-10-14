"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const {QAAppWideFeatureAdmission,routeFor,APP_VIEWS}=require("./ai-layer-v21-app-wide-admission.cjs");
const U="synthetic-learner-001",OTHER="other-account";
const SOURCES=["mathematics","biology","chemistry","economics","informatics",
 "english_a1","english_a2","english_b1","sat","ielts"];
const base={ownerId:U,routeAuthority:"unified_ai",active:true,
 protectedAssessment:false,expiresAtMs:120000,contextRevision:"r1",
 surface:"global",subject:"general",feature:"app_help",topic:"navigation",
 currentView:"home"};
const examples={
 general_help:{ctx:{},proof:{kind:"app_navigation",verified:true}},
 subject_overview:{ctx:{surface:"global",subject:"chemistry",feature:"subject_overview",
  topic:"overview",currentView:"courses"},
  proof:{kind:"governed_subject_overview",verified:true}},
 home_next:{ctx:{surface:"home",feature:"next_step",topic:"next_actions"},
  proof:{kind:"signed_next_actions",verified:true,aggregateRevision:1}},
 profile_progress:{ctx:{surface:"profile",currentView:"profile",
  feature:"progress_explanation",topic:"progress"},
  proof:{kind:"signed_progress_aggregate",verified:true,aggregateRevision:1}},
 lesson:{ctx:{surface:"lesson",subject:"biology",feature:"topic_explanation",
  topic:"cells",currentView:"courses",lessonId:72},
  proof:{kind:"approved_lesson_source",lessonSpecific:true,isVideo:false,lessonId:72}},
 practice_result:{ctx:{surface:"practice",subject:"economics",feature:"answer_explanation",
  topic:"demand",currentView:"courses",practiceSessionId:101,questionId:202},
  proof:{kind:"finalized_practice_answer",finalized:true,answerVerified:true,
   practiceSessionId:101,questionId:202}},
 tour_archive:{ctx:{surface:"tour_archive",subject:"informatics",feature:"archive_explanation",
  topic:"algorithm",currentView:"courses",tourAttemptId:55},
  proof:{kind:"opened_tour_archive",finalized:true,archiveUnlocked:true,
   tourAttemptId:55,archiveUnlockRevision:2}}
};
const match=k=>{const v=examples[k];const ctx={...base,...v.ctx};
 return {ctx,proof:{ownerId:ctx.ownerId,contextRevision:ctx.contextRevision,
  surface:ctx.surface,subject:ctx.subject,feature:ctx.feature,topic:ctx.topic,
  currentView:ctx.currentView,proofId:"server-proof-001",proofRevision:1,
  proofHash:"a".repeat(64),...v.proof}}};
const key=v=>[v.surface,v.subject,v.feature,v.topic,"ru"].join("|");
function fixture(k,{sourceReady=true,rights=true,protection=false,active=true}={}){
 const data=match(k);
 const state={...data,protected:protection,global:true,subject:true,
  rollout:true,now:1000,sourceReady,rights,calls:0,mutate:null};
 const release=()=>({ready:true,surface:state.ctx.surface,subject:state.ctx.subject,
  feature:state.ctx.feature,topic:state.ctx.topic,locale:"ru",
  source_id:"real-release-mock",source_version:"v1",
  source_hash:"b".repeat(64),revision:1});
 const S={
  getServerTimeMs:async()=>state.now,
  isProtected:async()=>state.protected,
  getGlobalState:async()=>({uiEnabled:state.global,gatewayEnabled:state.global,
    killSwitch:!state.global,releaseApproved:true}),
  getScopedContext:async()=>state.ctx,
  getVerifiedScreenEvidence:async()=>{
   state.calls++;
   if(state.mutate)state.mutate(state);
   return state.proof;
  },
  getSubjectActive:async()=>state.subject,
  isRolloutAuthorized:async()=>state.rollout,
  getPublishedRelease:async r=>state.sourceReady&&
   key(r)===key(state.ctx)?release():null,
  getLiveSourceProof:async r=>({
   approved:state.rights,rightsApproved:state.rights,
   runtimeAllowed:true,sourceConflict:false,
   ...r,source_id:"real-release-mock",source_version:"v1",
   source_hash:"b".repeat(64)
  })
 };
 return{check:(opts={})=>new QAAppWideFeatureAdmission(S).check({
   principal:{authenticated:true,userId:U},contextHandle:"opaque-handle-001",
   locale:"ru",...opts}),S,state};
}
test("Exact server-proved single router covers global, Home, Profile, Lessons, Practice, Tours",async()=>{
 for(const k of Object.keys(examples)){
  const f=fixture(k);
  const r=await f.check();
  assert.equal(r.state,"available",k+":"+JSON.stringify(r));
  assert.equal(r.route,k);
  assert.equal(r.canAsk,true);
  assert.equal(r.charge,0);assert.equal(r.providerCallRequired,false);
 }
});
test("All core and future app subjects use one router, not Math-only code",async()=>{
 for(const subject of SOURCES){
  const f=fixture("subject_overview");
  f.state.ctx.subject=subject;f.state.proof.subject=subject;
  // Mock approved sources are not activation authority for production.
  const r=await f.check();
  assert.equal(r.state,"available",subject);
  assert.equal(r.subject,subject);
 }
 for(const subject of ["", "foreign_subject","general"]){
  const f=fixture("subject_overview");
  f.state.ctx.subject=subject;f.state.proof.subject=subject;
  assert.equal((await f.check()).state,"in_development",subject);
 }
});
test("Every registered app View can use General Help only with server screen proof",async()=>{
 for(const view of APP_VIEWS){
  const f=fixture("general_help");
  f.state.ctx.currentView=view;f.state.proof.currentView=view;
  assert.equal((await f.check()).route,"global_help",view);
 }
 for(const view of ["splash","registration","practice-quiz","tour-quiz","video","exam-prep"]){
  const f=fixture("general_help");
  f.state.ctx.currentView=view;f.state.proof.currentView=view;
  assert.equal((await f.check()).state,"in_development",view);
 }
});
test("No releases or rights/locale/entitlement blocks all surfaces without a bill",async()=>{
 for(const k of Object.keys(examples)){
  for(const off of [{sourceReady:false},{rights:false},{active:false}]){
   const f=fixture(k,off);
   if(off.active===false){f.state.rollout=false;}
   const result=await f.check();
   assert.notEqual(result.state,"available",JSON.stringify({k,off}));
   assert.equal(result.charge,0,k);
   assert.equal(result.providerCallRequired,false,k);
  }
 }
});
test("Exact resource and authorization checks fail closed across all surfaces",()=>{
 for(const k of Object.keys(examples)){
  const {ctx,proof}=match(k);
  assert.equal(routeFor(ctx,proof),k);
  for(const patch of [{ownerId:OTHER},{proofHash:"not-a-hash"},
   {proofRevision:0},{contextRevision:"old"},{surface:"practice"},
   {subject:"mathematics"}]){
   const forged={...proof,...patch};
   assert.equal(routeFor(ctx,forged),null,k+":"+JSON.stringify(patch));
  }
 }
});
test("Completed Practice and opened Tour archive cannot be inferred from title/score/client flags",()=>{
 for(const patch of [
  {finalized:false},{answerVerified:false},{practiceSessionId:567},
  {questionId:999},{kind:"generic_topic_card"},{isVideo:true,questionId:999}
 ]){
  const {ctx,proof}=match("practice_result");
  assert.equal(routeFor(ctx,{...proof,...patch}),null,JSON.stringify(patch));
 }
 for(const patch of [{archiveUnlocked:false},{finalized:false},
  {archiveUnlockRevision:0},{tourAttemptId:777}]){
  const {ctx,proof}=match("tour_archive");
  assert.equal(routeFor(ctx,{...proof,...patch}),null,JSON.stringify(patch));
 }
});
test("Lesson AI NEVER guesses subject-wide video, requires exact approved lesson",()=>{
 const {ctx,proof}=match("lesson");
 for(const patch of [{lessonId:1},{lessonSpecific:false},{isVideo:true},
  {kind:"video_subtitles"},{currentView:"video"}])
  assert.equal(routeFor(ctx,{...proof,...patch}),null,JSON.stringify(patch));
 assert.equal(routeFor({...ctx,surface:"video"},{...proof,surface:"video"}),null);
});
test("Existing Mathematics Exam Prep Tutor remains unchanged and isolated",async()=>{
 const f=fixture("practice_result");
 f.state.ctx.surface="exam_prep";f.state.ctx.subject="mathematics";
 f.state.proof.surface="exam_prep";f.state.proof.subject="mathematics";
 assert.equal((await f.check()).state,"in_development");
 assert.equal(routeFor({...f.state.ctx,feature:"legacy_tutor"},
  {...f.state.proof,feature:"legacy_tutor"}),null);
});
test("Signed Home/Profile aggregates are required, not raw browser progress",()=>{
 for(const kind of ["home_next","profile_progress"]){
  const {ctx,proof}=match(kind);
  for(const change of [{aggregateRevision:0},{verified:false},{kind:"client_progress"}]){
   assert.equal(routeFor(ctx,{...proof,...change}),null,kind);
  }
 }
});
test("Protected exam ALWAYS hides AI, even with otherwise verified source",async()=>{
 for(const k of Object.keys(examples)){
  const f=fixture(k,{protection:true});
  assert.equal((await f.check()).visible,false,k);
  assert.equal((await f.check()).state,"hidden",k);
 }
});
test("No stale source/evidence after async read can authorize the prior screen",async()=>{
 for(const kind of ["practice_result","tour_archive","home_next","lesson"]){
  const f=fixture(kind);
  f.state.mutate=state=>{
   if(state.calls===2){state.proof={...state.proof,proofRevision:2};}
  };
  assert.equal((await f.check()).state,"unavailable",kind);
 }
});
test("Wrong user, expired handle, account switch and invalid locale fail closed",async()=>{
 const f=fixture("profile_progress");
 assert.equal((await f.check({principal:{authenticated:true,userId:OTHER}})).state,"unavailable");
 f.state.now=200000;
 assert.equal((await f.check()).state,"unavailable");
 assert.equal((await f.check({locale:"fr"})).state,"in_development");
});
test("Real app DOM keeps all screens; QA router does not alter production files",()=>{
 const app=fs.readFileSync("index.html","utf8");
 for(const id of ["view-home","view-courses","view-profile","courses-lessons",
  "courses-video","courses-practice-quiz","courses-practice-result",
  "courses-practice-review","courses-tour-quiz","courses-tour-result",
  "courses-tour-review","exam-prep-host-root","view-community",
  "view-notifications","view-archive","view-certificates"])
  assert.ok(app.includes('id="'+id+'"'),id);
 const source=fs.readFileSync("qa/ai-layer-v21-app-wide-admission.cjs","utf8");
 assert.doesNotMatch(source,/supabase-js|createClient|service_role|localStorage|sessionStorage/);
});
