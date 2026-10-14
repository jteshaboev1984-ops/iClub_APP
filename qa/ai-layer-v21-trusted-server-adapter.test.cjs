"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {TrustedAppWideServerAdapter}=require("./ai-layer-v21-trusted-server-adapter.cjs");
const U="11111111-1111-4111-8111-111111111111";
const OTHER="22222222-2222-4222-8222-222222222222";
const handle="33333333-3333-4333-8333-333333333333";
const cases={
 general:{surface:"global",subject:"general",feature:"app_help",topic:"navigation",currentView:"home",route:"global_help"},
 overview:{surface:"global",subject:"biology",feature:"subject_overview",topic:"overview",currentView:"courses",route:"subject_overview"},
 home:{surface:"home",subject:"general",feature:"next_step",topic:"next_actions",currentView:"home",route:"home_next"},
 profile:{surface:"profile",subject:"general",feature:"progress_explanation",topic:"progress",currentView:"profile",route:"profile_progress"},
 lesson:{surface:"lesson",subject:"biology",feature:"topic_explanation",topic:"cells",currentView:"courses",lessonId:72,route:"lesson"},
 practice:{surface:"practice",subject:"economics",feature:"answer_explanation",topic:"demand",currentView:"courses",practiceSessionId:101,questionId:202,route:"practice_result"},
 tour:{surface:"tour_archive",subject:"chemistry",feature:"archive_explanation",topic:"atomic",currentView:"courses",tourAttemptId:55,route:"tour_archive"}
};
function setup(name){
 const {route,...data}=cases[name];
 const c={ownerId:U,routeAuthority:"unified_ai",active:true,
  protectedAssessment:false,expiresAtMs:120000,contextRevision:"screen_1",...data};
 const s={user_id:U,active:true,context_handle:handle,
  context_revision:"screen_1",revision:1,current_view:c.currentView};
 const records={
  nav:{approved:true,current:true,view:c.currentView,version:"v1"},
  overview:{approved:true,current:true,subject_key:c.subject,version:"v1"},
  home:{user_id:U,verified:true,aggregate_revision:1,next_actions:["server-next"]},
  profile:{user_id:U,verified:true,aggregate_revision:1,metrics:[{type:"verified",count:1}]},
  lesson:{id:72,subject_key:"biology",topic_key:"cells",is_active:true,
   lesson_specific:true,is_video:false,access_authorized:true,source_revision:1},
  practice:{id:101,user_id:U,subject_key:"economics",status:"finalized",
   finalized_at:"2026-10-14T05:00:00Z",question_ids:[202]},
  answer:{user_id:U,session_id:101,question_id:202,server_checked:true,
   is_final:true,topic_key:"demand",revision:1},
  tour:{id:55,user_id:U,subject_key:"chemistry",tour_id:12,status:"submitted"},
  runtime:{user_id:U,attempt_id:55,tour_id:12,finalized_at:"2026-10-14T05:00:00Z"},
  archive:{user_id:U,attempt_id:55,tour_id:12,owner_verified:true,
   unlocked:true,unlock_revision:1,topic_key:"atomic"}
 };
 const flags={protected:false,global:true,active:true,rollout:true,source:true,conflict:false,now:1000};
 const S={
  getServerTimeMs:async()=>flags.now,
  isProtected:async()=>flags.protected,
  getGlobalState:async()=>({uiEnabled:flags.global,gatewayEnabled:flags.global,
   killSwitch:!flags.global,releaseApproved:true}),
  getSubjectActive:async()=>flags.active,
  isRolloutAuthorized:async()=>flags.rollout,
  getScopedContext:async()=>c,
  getCurrentScreen:async()=>s,
  readNavigationSource:async()=>records.nav,
  readSubjectOverview:async()=>records.overview,
  readHomeNextActions:async()=>records.home,
  readProfileAggregate:async()=>records.profile,
  readLesson:async()=>records.lesson,
  readPracticeSessionV4:async()=>records.practice,
  readPracticeAnswerV4:async()=>records.answer,
  readTourAttempt:async()=>records.tour,
  readTourRuntime:async()=>records.runtime,
  readTourArchiveAccess:async()=>records.archive,
  getPublishedRelease:async ref=>flags.source?{
   ...ref,ready:true,source_id:"synthetic-source",source_version:"v1",
   source_hash:"a".repeat(64),revision:1}:null,
  getLiveSourceProof:async ref=>({...ref,approved:true,
   rightsApproved:true,runtimeAllowed:true,sourceConflict:flags.conflict,
   source_id:"synthetic-source",source_version:"v1",source_hash:"a".repeat(64)})
 };
 const adapter=new TrustedAppWideServerAdapter(S);
 const principal={authenticated:true,userId:U};
 return {adapter,S,c,s,records,flags,principal,route,
  check:()=>adapter.check({principal,contextHandle:handle,locale:"ru"})};
}
test("One adapter routes every approved surface with exact server-owned evidence",async()=>{
 for(const k of Object.keys(cases)){
  const t=setup(k),res=await t.check();
  assert.equal(res.state,"available",k+":"+JSON.stringify(res));
  assert.equal(res.route,t.route,k);
  assert.equal(res.charge,0,k);
  assert.equal(res.providerCallRequired,false,k);
 }
});
test("No reader contract, no service proof",()=>{
 const t=setup("practice");
 delete t.S.readTourArchiveAccess;
 assert.throws(()=>new TrustedAppWideServerAdapter(t.S),/missing authenticated/);
});
test("Cross-account context, screen and each academic record are rejected",async()=>{
 for(const k of Object.keys(cases)){
  const t=setup(k);t.s.user_id=OTHER;
  assert.notEqual((await t.check()).state,"available",k+" screen");
  t.s.user_id=U;t.c.ownerId=OTHER;
  assert.notEqual((await t.check()).state,"available",k+" context");
 }
 for(const [k,row] of [["home","home"],["profile","profile"],["practice","practice"],
  ["practice","answer"],["tour","tour"],["tour","runtime"],["tour","archive"]]){
  const t=setup(k);t.records[row].user_id=OTHER;
  assert.notEqual((await t.check()).state,"available",k+"/"+row);
 }
});
test("Practice V4: active, foreign answer, missing question or legacy ID cannot pass",async()=>{
 const changes=[
  t=>t.records.practice.status="active",
  t=>t.records.practice.finalized_at=null,
  t=>t.records.practice.question_ids=[],
  t=>t.records.answer.server_checked=false,
  t=>t.records.answer.is_final=false,
  t=>t.records.answer.session_id=999,
  t=>t.records.answer.question_id=999,
  t=>t.c.practiceSessionId=999,
  t=>{delete t.c.practiceSessionId;t.c.attemptId=101;},
  t=>t.records.answer.topic_key="unapproved",
  t=>t.records.answer.revision=0
 ];
 for(const f of changes){
  const t=setup("practice");f(t);
  assert.notEqual((await t.check()).state,"available",String(f));
 }
});
test("Tour never opens on mere submission: runtime, owner, archive and revision required",async()=>{
 const changes=[
  t=>t.records.tour.status="active",
  t=>t.records.runtime.finalized_at=null,
  t=>t.records.runtime.tour_id=33,
  t=>t.records.archive.unlocked=false,
  t=>t.records.archive.owner_verified=false,
  t=>t.records.archive.unlock_revision=0,
  t=>t.records.archive.topic_key="different",
  t=>t.c.tourAttemptId=99
 ];
 for(const f of changes){
  const t=setup("tour");f(t);
  assert.notEqual((await t.check()).state,"available",String(f));
 }
});
test("Lesson must be exact non-video, active, entitled, and source bound",async()=>{
 for(const f of [
  t=>t.records.lesson.is_video=true,
  t=>t.records.lesson.lesson_specific=false,
  t=>t.records.lesson.id=73,
  t=>t.records.lesson.topic_key="video_subject",
  t=>t.records.lesson.is_active=false,
  t=>t.records.lesson.access_authorized=false,
  t=>t.records.lesson.source_revision=0
 ]){
  const t=setup("lesson");f(t);
  assert.notEqual((await t.check()).state,"available");
 }
});
test("Home/Profile never accept unsigned or foreign progress nor inflated revision",async()=>{
 for(const k of ["home","profile"])for(const f of [
  t=>t.records[k].verified=false,
  t=>t.records[k].aggregate_revision=0,
  t=>t.records[k][k==="home"?"next_actions":"metrics"]=null
 ]){
  const t=setup(k);f(t);
  assert.notEqual((await t.check()).state,"available",k);
 }
});
test("Feature readiness is independent across topic, locale, subject and source",async()=>{
 for(const k of Object.keys(cases)){
  for(const change of [
   t=>t.flags.source=false,
   t=>t.flags.conflict=true,
   t=>t.flags.active=false,
   t=>t.flags.rollout=false
  ]){
   const t=setup(k);change(t);
   assert.notEqual((await t.check()).state,"available",k);
  }
 }
});
test("Global AI disabled or protected assessment blocks even general navigation",async()=>{
 for(const k of Object.keys(cases)){
  for(const f of [t=>t.flags.global=false,t=>t.flags.protected=true,
   t=>t.c.protectedAssessment=true]){
   const t=setup(k);f(t);
   const r=await t.check();
   assert.notEqual(r.state,"available");
   assert.equal(r.charge,0);
  }
 }
});
test("Account change, navigation and expiry revoke all surface proofs",async()=>{
 for(const k of Object.keys(cases)){
  for(const f of [
   t=>t.s.context_handle="other-handle",
   t=>t.s.revision=0,
   t=>t.s.context_revision="screen_2",
   t=>t.s.active=false,
   t=>t.s.current_view="changed",
   t=>t.c.active=false,
   t=>t.flags.now=130000
  ]){
   const t=setup(k);f(t);
   assert.notEqual((await t.check()).state,"available",k+":"+String(f));
  }
 }
});
test("Async cross-screen change and mutable source evidence invalidates proof",async()=>{
 for(const k of ["home","practice","tour"]){
  const t=setup(k);let n=0;
  const old=t.S.getCurrentScreen;
  t.S.getCurrentScreen=async(...args)=>{
   const r=await old(...args);n++;
   if(n===3){t.s.revision++;return {...r};}
   return {...r};
  };
  const a=new TrustedAppWideServerAdapter(t.S);
  const res=await a.check({principal:t.principal,contextHandle:handle,locale:"ru"});
  assert.notEqual(res.state,"available",k);
 }
});
test("Only minimal server-derived metadata escapes, no answer keys, progress or private text",async()=>{
 for(const k of Object.keys(cases)){
  const t=setup(k);
  const p=await t.adapter.getVerifiedScreenEvidence(U,handle);
  assert.ok(p&&/^[0-9a-f]{64}$/.test(p.proofHash),k);
  const output=JSON.stringify(p);
  for(const secret of ["correct_answer","sourceText","next_actions","metrics","finalized_at","apikey"])
   assert.equal(output.includes(secret),false,secret+" / "+k);
  assert.equal(await t.adapter.getVerifiedScreenEvidence(OTHER,handle),null);
 }
});
