"use strict";
// Disposable source-governed Practice error E2E; no real learner/provider/database.
const {test}=require("node:test"),assert=require("node:assert/strict");
const {CandidateEdgeRequest}=require("./ai-layer-v21-edge-request.cjs");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const {QaV21RealAcademicScreenBridge}=require("./ai-v21-real-academic-screen-bridge.cjs");
const U="11111111-1111-4111-8111-111111111111";
const H="33333333-3333-4333-8333-333333333333";
const ORIGIN="https://qa.synthetic.invalid";
const SHA="a".repeat(64);
const texts={ru:"SYNTHETIC QA ONLY: approved error reference, no actual answer.",
 uz:"SUN'IY QA: tasdiqlangan xato manbasi, haqiqiy javob yo'q.",
 en:"SYNTHETIC QA ONLY: approved error source, no actual answer."};
function make(){
 const state={release:new Set(["ru"]),rights:true,owner:true,finished:true,
  exam:false,loggedIn:true,kill:false,subject:true,now:1000,handle:false,
  provider:0,academicWrites:0,usage:0,events:[],seq:0,screen:"practice-review"};
 const row={dataset:{practiceAiQuestionId:"202"}};
 const elements={
  "courses-practice-review":{dataset:{practiceAiAttemptId:"701",practiceAiSubjectKey:"biology"}},
  "practice-review-list":{contains:r=>r===row},
  "courses-practice-quiz":{classList:{contains:()=>state.exam}},
  "courses-tour-quiz":{classList:{contains:()=>false}},
  "exam-prep-host-root":{hidden:true}
 };
 const doc={visibilityState:"visible",
  getElementById:id=>elements[id]||null,
  querySelectorAll:q=>q===".view.is-active"?[{id:"view-courses"}]:
   q==="#view-courses .stack-screen.is-active"?
    [{id:"courses-"+state.screen}]:[]};
 const svc={
  authenticate:async token=>state.loggedIn&&token==="Bearer synthetic-test-token"?
   {authenticated:true,userId:U}:null,
  getServerTimeMs:async()=>state.now,
  isProtected:async()=>state.exam,
  getGlobalState:async()=>({uiEnabled:!state.kill,gatewayEnabled:!state.kill,
   killSwitch:state.kill,releaseApproved:!state.kill}),
  getScopedContext:async(u,h)=>state.handle&&u===U&&h===H?{
   ownerId:U,active:true,routeAuthority:"unified_ai",
   protectedAssessment:false,expiresAtMs:90000,contextRevision:"practice-proof-900-202",
   surface:"practice",subject:"biology",feature:"answer_explanation",topic:"question_202"
  }:null,
  getSubjectActive:async()=>state.subject,
  isRolloutAuthorized:async()=>state.subject,
  getPublishedRelease:async ref=>state.release.has(ref.locale)&&ref.surface==="practice"&&ref.feature==="answer_explanation"&&ref.topic==="question_202"?
   {ready:true,...ref,source_id:"qa-source-202",
    source_version:"qa-only-v1",source_hash:SHA,revision:1}:null,
  getLiveSourceProof:async ref=>({...ref,approved:state.rights,
   rightsApproved:state.rights,runtimeAllowed:true,sourceConflict:false,
   source_id:"qa-source-202",source_version:"qa-only-v1",source_hash:SHA}),
  getPolicy:async()=>"free_qa_v2",
  getSourceBundle:async q=>({approved:state.rights,rightsApproved:state.rights,
   integrityVerified:true,qaPassed:true,runtimeAllowed:true,conflict:false,
   sourceId:q.sourceId,sourceVersion:q.sourceVersion,
   sourceHash:q.sourceHash,revision:q.revision,generationAllowed:false,sourceText:"",
   variants:{practice_error:texts[q.locale]}}),
  providerBudgetAllows:async()=>false,
  generateSynthetic:async()=>{state.provider++;throw Error("NO PROVIDER");},
  reserveUsage:async()=>{state.usage++;return{allowed:true};},
  claimDelivery:async()=>({allowed:true}),
  finishDelivery:async()=>({ok:true}),
  reserveProviderSpend:async()=>{state.provider++;return{allowed:false};},
  dispatchProviderSpend:async()=>{state.provider++;return{allowed:false};},
  finishProviderSpend:async()=>{state.provider++;return{ok:false};}
 };
 const edge=new CandidateEdgeRequest({services:svc,allowedOrigins:[ORIGIN]});
 const post=async r=>{
  state.events.push([r.path,r.body.action||r.body.intent]);
  if(r.path==="/context"){
   if(r.body.action==="resolvePracticeV4")return state.owner&&state.finished&&!state.exam&&
    r.body.attemptReference===701&&r.body.questionId===202?
    {ok:true,kind:"server_resolved_practice_v4",attemptReference:701,questionId:202,
     sessionId:900}:{ok:false};
   if(r.body.action==="mint"){
    if(!state.owner||!state.finished||state.exam||r.body.sessionId!==900||
       r.body.questionId!==202)return{ok:false};
    state.handle=true;
    return{ok:true,contextHandle:H,expiresInSeconds:90};
   }
   if(r.body.action==="revoke"){state.handle=false;return{ok:true};}
   return{ok:false};
  }
  if(r.path==="/answer")return(await edge.serve({method:"POST",origin:ORIGIN,
   authorization:r.authorization,bodyText:JSON.stringify(r.body)})).body;
  throw Error("unapproved request");
 };
 const client=new QaV21ScreenClient({post,
  readJwt:async()=>state.loggedIn?"synthetic-test-token":null,
  newRequestId:()=>("55555555-5555-4555-8555-"+String(++state.seq).padStart(12,"0")),
  nowMs:()=>state.now});
 const bridge=new QaV21RealAcademicScreenBridge({document:doc,client,serverResolver:client});
 return{state,bridge,row};
}
test("approved RU exact question flows resolver => mint => source => prepared answer",async()=>{
 const x=make();
 const open=await x.bridge.chooseReviewQuestion(x.row,"ru");
 assert.equal(open.ok,true,JSON.stringify(open));
 const out=await x.bridge.explainSelectedError("ru");
 assert.equal(out.ok,true,JSON.stringify(out));
 assert.equal(out.reply,texts.ru);
 assert.deepEqual(x.state.events.slice(0,4),[
  ["/context","resolvePracticeV4"],["/context","mint"],
  ["/answer","status"],["/answer","answer"]]);
 assert.equal(x.state.usage,1);
 assert.equal(x.state.provider,0);
 assert.equal(x.state.academicWrites,0);
});
test("RU approval never opens UZ or EN; independent releases provide respective text",async()=>{
 for(const lang of ["uz","en"]){
  const x=make();
  assert.equal((await x.bridge.chooseReviewQuestion(x.row,lang)).ok,false);
  assert.equal(x.state.usage,0);
  x.state.release.add(lang);
  assert.equal((await x.bridge.chooseReviewQuestion(x.row,lang)).ok,true);
  const r=await x.bridge.explainSelectedError(lang);
  assert.equal(r.ok,true,JSON.stringify(r));
  assert.equal(r.reply,texts[lang]);
  assert.equal(x.state.provider,0);
 }
});
test("missing publication, rights, entitlement or global release blocks before billing",async()=>{
 for(const alter of [
  s=>s.release.clear(),s=>{s.rights=false;},
  s=>{s.subject=false;},s=>{s.kill=true;}
 ]){
  const x=make();alter(x.state);
  assert.equal((await x.bridge.chooseReviewQuestion(x.row,"ru")).ok,false);
  assert.equal(x.state.usage,0);assert.equal(x.state.provider,0);
 }
});
test("active exam, foreign or unfinished attempt never gets canonical mint",async()=>{
 for(const alter of [
  s=>{s.exam=true;},s=>{s.owner=false;},s=>{s.finished=false;}
 ]){
  const x=make();alter(x.state);
  assert.equal((await x.bridge.chooseReviewQuestion(x.row,"ru")).ok,false);
  assert.equal(x.state.events.some(e=>e[1]==="mint"),false);
 }
});
test("navigation or logout removes permission without reusing previous answers",async()=>{
 const x=make();
 assert.equal((await x.bridge.chooseReviewQuestion(x.row,"ru")).ok,true);
 await x.bridge.onNavigation();x.state.screen="home";
 assert.equal((await x.bridge.explainSelectedError("ru")).ok,false);
 assert.equal(x.state.handle,false);
 const y=make();
 assert.equal((await y.bridge.chooseReviewQuestion(y.row,"ru")).ok,true);
 y.state.loggedIn=false;
 assert.equal((await y.bridge.explainSelectedError("ru")).ok,false);
 assert.equal(y.state.provider,0);
});
test("revoking editorial release between status and answer blocks content",async()=>{
 const x=make();
 assert.equal((await x.bridge.chooseReviewQuestion(x.row,"ru")).ok,true);
 x.state.release.delete("ru");
 const result=await x.bridge.explainSelectedError("ru");
 assert.equal(result.ok,false);
 assert.notEqual(result.reply,texts.ru);
 assert.equal(x.state.usage,0);
});
