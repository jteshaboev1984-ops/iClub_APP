"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const {QaV21RealAcademicScreenBridge}=require("./ai-v21-real-academic-screen-bridge.cjs");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const app=fs.readFileSync("app.js","utf8");
const shell=fs.readFileSync("qa/ai-v21-real-academic-screen-bridge.cjs","utf8");
function deferred(){
 let resolve;
 const promise=new Promise(r=>{resolve=r;});
 return {promise,resolve};
}
function fixture(){
 const flags={view:"courses",screen:"practice-review",quiz:false,tour:false,exam:false,hidden:false,
  attempt:"701",subject:"economics",question:"202",sameRow:true};
 const row={dataset:{practiceAiQuestionId:"202"}};
 const wrong={dataset:{practiceAiQuestionId:"203"}};
 const list={contains:r=>flags.sameRow && r===row};
 const root={dataset:{get practiceAiAttemptId(){return flags.attempt;},
   get practiceAiSubjectKey(){return flags.subject;}}};
 const cls=v=>({contains:key=>key==="is-active"&&v});
 const view={id:"view-courses"};
 const screen={id:"courses-practice-review"};
 const elements={
  "exam-prep-host-root":{hidden:true,getAttribute:()=>flags.exam?"false":"true"},
  "courses-practice-quiz":{classList:{contains:()=>flags.quiz}},
  "courses-tour-quiz":{classList:{contains:()=>flags.tour}},
  "courses-practice-review":root,
  "practice-review-list":list
 };
 elements["exam-prep-host-root"].getAttribute=()=>flags.exam?"false":"true";
 Object.defineProperty(elements["exam-prep-host-root"],"hidden",{get:()=>!flags.exam});
 const document={
  get visibilityState(){return flags.hidden?"hidden":"visible";},
  getElementById:id=>elements[id]||null,
  querySelectorAll:query=>{
   if(query===".view.is-active")return flags.view==="courses"?[view]:
     flags.view==="duplicate"?[view,{id:"view-home"}]:[];
   if(query==="#view-courses .stack-screen.is-active")
    return flags.screen==="practice-review"?[screen]:
      flags.screen==="duplicate"?[screen,{id:"courses-video"}]:[{id:"courses-"+flags.screen}];
   throw Error("unexpected selector "+query);
  }
 };
 const calls=[];
 const transport={
  leave:async()=>{calls.push(["leave"]);return{ok:true};},
  openPractice:async(sessionId,questionId)=>{
   calls.push(["mint",sessionId,questionId]);return{ok:true};
  },
  status:async(locale)=>{
   calls.push(["status",locale]);
   return{ok:true,state:"available",route:"practice_result"};
  },
  askPrepared:async(key,locale)=>{
   calls.push(["ask",key,locale]);return{ok:true,message:"synthetic approved QA only"};
  },
  isCurrent:()=>true
 };
 const resolver={
  resolvePracticeV4:async input=>{
   calls.push(["resolve",input]);
   return {ok:true,kind:"server_resolved_practice_v4",
    attemptReference:input.attemptReference,questionId:input.questionId,
    sessionId:101};
  }
 };
 const bridge=new QaV21RealAcademicScreenBridge({
  document,client:transport,serverResolver:resolver});
 return {flags,row,wrong,transport,resolver,bridge,calls,root,document};
}
test("actual APP exposes attempt marker and question marker but no canonical v4 session attribute",()=>{
 assert.match(app,/dataset\.practiceAiAttemptId/);
 assert.match(app,/dataset\.practiceAiQuestionId/);
 assert.match(app,/safePersistedResult.*?attemptId|safePersistedResult\.attemptId/s);
 assert.doesNotMatch(app,/dataset\.practiceAiSessionId/);
 assert.match(shell,/attemptReference/);
 assert.doesNotMatch(shell,/localStorage|fetch\(|window\.sb|correctAnswer|score:|userId:/);
});
test("actual completed review requires server resolution AND server mint before prepared answer",async()=>{
 const x=fixture();
 const r=await x.bridge.chooseReviewQuestion(x.row);
 assert.deepEqual(r,{ok:true,state:"available"});
 const resolve=x.calls.find(c=>c[0]==="resolve");
 assert.equal(Object.keys(resolve[1]).sort().join(","),"attemptReference,questionId");
 assert.equal(resolve[1].attemptReference,701);
 assert.equal(resolve[1].questionId,202);
 assert.deepEqual(x.calls.find(c=>c[0]==="mint"),["mint",101,202]);
 const answer=await x.bridge.explainSelectedError("ru");
 assert.equal(answer.ok,true);
 assert.deepEqual(x.calls.filter(c=>c[0]==="ask"),[["ask","practice_error","ru"]]);
});
test("Practice screenshot, result, lists and video have no permission to mint",async()=>{
 for(const screen of ["practice-start","practice-result","practice-recs",
  "practice-quiz","tour-quiz","tour-review","lessons","video",
  "subject-hub","all-subjects","duplicate"]){
  const x=fixture();x.flags.screen=screen;
  const r=await x.bridge.chooseReviewQuestion(x.row);
  assert.equal(r.ok,false,screen);
  assert.equal(x.calls.filter(z=>["resolve","mint","status","ask"].includes(z[0])).length,0,screen);
 }
});
test("must be exactly one active registered view and one active inner route",async()=>{
 for(const view of ["none","duplicate"]){
  const x=fixture();x.flags.view=view;
  assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,false);
  assert.equal(x.calls.filter(z=>z[0]==="resolve").length,0);
 }
});
test("active quizzes, Exam Prep, hidden browser or wrong row completely deny mint",async()=>{
 for(const flags of [{quiz:true},{tour:true},{exam:true},{hidden:true},
  {sameRow:false}]){
  const x=fixture();Object.assign(x.flags,flags);
  const r=await x.bridge.chooseReviewQuestion(x.row);
  assert.equal(r.ok,false,JSON.stringify(flags));
  assert.equal(x.calls.filter(z=>z[0]==="resolve").length,0);
 }
 const x=fixture();
 assert.equal((await x.bridge.chooseReviewQuestion(x.wrong)).ok,false);
});
test("invalid browser IDs, subject and injection strings are refused before server",async()=>{
 for(const val of ["", "0", "-1", "5.3", "0007", "7 OR 1=1",
  "999999999999999999999", "NaN"]){
  for(const which of ["attempt","question"]){
   const x=fixture();
   if(which==="attempt")x.flags.attempt=val;
   else x.row.dataset.practiceAiQuestionId=val;
   assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,false,val+" "+which);
   assert.equal(x.calls.filter(z=>z[0]==="resolve").length,0);
  }
 }
 for(const subject of ["", "unknown","general","../../math"]){
  const x=fixture();x.flags.subject=subject;
  assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,false);
 }
});
test("mismatched or unsourced resolver output never goes to mint",async()=>{
 for(const patch of [
   {ok:false},{kind:"browser_guess"},{attemptReference:702},{questionId:204},
   {sessionId:0},{sessionId:"101"},{sessionId:NaN}]){
  const x=fixture();
  x.resolver.resolvePracticeV4=async arg=>({
   ok:true,kind:"server_resolved_practice_v4",
   attemptReference:arg.attemptReference,questionId:arg.questionId,
   sessionId:101,...patch
  });
  const r=await x.bridge.chooseReviewQuestion(x.row);
  assert.equal(r.ok,false,JSON.stringify(patch));
  assert.equal(x.calls.filter(z=>z[0]==="mint").length,0);
 }
});
test("unfinished server proof, protected server or unpublished source never enable help",async()=>{
 for(const response of [
  {ok:false,reason:"active_assessment"},
  {ok:true,state:"in_development"},
  {ok:true,state:"available",route:"global_help"},
  {ok:false,state:"unavailable"}
 ]){
  const x=fixture();
  x.transport.status=async()=>response;
  const r=await x.bridge.chooseReviewQuestion(x.row);
  assert.equal(r.ok,false,JSON.stringify(response));
  assert.equal((await x.bridge.explainSelectedError("ru")).ok,false);
 }
});
test("navigation during server lookup invalidates selector before mint",async()=>{
 const x=fixture(),gate=deferred();
 x.resolver.resolvePracticeV4=async a=>gate.promise;
 const pending=x.bridge.chooseReviewQuestion(x.row);
 await new Promise(r=>setImmediate(r));
 x.flags.screen="home";
 gate.resolve({ok:true,kind:"server_resolved_practice_v4",
  attemptReference:701,questionId:202,sessionId:101});
 const result=await pending;
 assert.equal(result.ok,false);
 assert.equal(x.calls.filter(z=>z[0]==="mint").length,0);
});
test("navigation AFTER mint but before status must revoke and discard response",async()=>{
 const x=fixture(),gate=deferred();
 x.transport.openPractice=async()=>{
  x.calls.push(["mint",101,202]);return gate.promise;
 };
 const pending=x.bridge.chooseReviewQuestion(x.row);
 await new Promise(r=>setImmediate(r));
 await x.bridge.onNavigation();
 gate.resolve({ok:true});
 const result=await pending;
 assert.equal(result.ok,false);
 assert.equal(x.calls.filter(z=>z[0]==="ask").length,0);
 assert.ok(x.calls.filter(z=>z[0]==="leave").length>=2);
});
test("auth switch closes context, even for valid old review DOM",async()=>{
 const x=fixture();
 assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,true);
 await x.bridge.authChanged();
 assert.equal((await x.bridge.explainSelectedError("ru")).ok,false);
 assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,false);
 await x.bridge.authenticated();
 assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,true);
});
test("two overlapping selections cannot borrow each other's server authorization",async()=>{
 const x=fixture(),first=deferred();
 let n=0;
 x.resolver.resolvePracticeV4=async args=>{
  n++;if(n===1)return first.promise;
  return {ok:true,kind:"server_resolved_practice_v4",
    attemptReference:args.attemptReference,questionId:args.questionId,sessionId:101};
 };
 const a=x.bridge.chooseReviewQuestion(x.row);
 await new Promise(r=>setImmediate(r));
 const b=await x.bridge.chooseReviewQuestion(x.row);
 assert.equal(b.ok,true);
 first.resolve({ok:true,kind:"server_resolved_practice_v4",
  attemptReference:701,questionId:202,sessionId:101});
 assert.equal((await a).ok,false);
 assert.equal(x.calls.filter(z=>z[0]==="mint").length,1);
});
test("late prepared answer is not displayed after navigation",async()=>{
 const x=fixture(),gate=deferred();
 assert.equal((await x.bridge.chooseReviewQuestion(x.row)).ok,true);
 x.transport.askPrepared=async()=>gate.promise;
 const p=x.bridge.explainSelectedError("en");
 await x.bridge.onNavigation();
 gate.resolve({ok:true,message:"STALE ANSWER"});
 const res=await p;
 assert.equal(res.ok,false);
 assert.notEqual(res.message,"STALE ANSWER");
});

test("source readiness and explanation are bound to exact selected locale",async()=>{
 for(const locale of ["ru","uz","en"]){
  const x=fixture();
  const selected=await x.bridge.chooseReviewQuestion(x.row,locale);
  assert.equal(selected.ok,true,locale);
  assert.deepEqual(x.calls.find(y=>y[0]==="status"),["status",locale]);
  assert.equal((await x.bridge.explainSelectedError(locale)).ok,true);
  for(const different of ["ru","uz","en"].filter(v=>v!==locale)){
   const before=x.calls.filter(y=>y[0]==="ask").length;
   assert.equal((await x.bridge.explainSelectedError(different)).ok,false);
   assert.equal(x.calls.filter(y=>y[0]==="ask").length,before);
  }
 }
});
test("unsupported locale is denied before any server resolver or mint",async()=>{
 for(const locale of ["", "de", "RU", null, 1]){
  const x=fixture();
  const result=await x.bridge.chooseReviewQuestion(x.row,locale);
  assert.equal(result.ok,false,String(locale));
  assert.equal(x.calls.filter(y=>["resolve","mint","status"].includes(y[0])).length,0);
 }
});

test("real QA bridge composes authorized HTTP resolver, canonical mint, source gate and answer",async()=>{
 const x=fixture(),requests=[],U="11111111-1111-4111-8111-111111111111";
 const handle="33333333-3333-4333-8333-333333333333";
 const client=new QaV21ScreenClient({
  readJwt:async()=>"qa-signed-token-substitute",
  newRequestId:()=>"44444444-4444-4444-8444-444444444444",
  post:async request=>{
   requests.push(request);
   if(request.path==="/context"&&request.body.action==="resolvePracticeV4")
    return {ok:true,kind:"server_resolved_practice_v4",
     attemptReference:request.body.attemptReference,
     questionId:request.body.questionId,sessionId:900};
   if(request.path==="/context"&&request.body.action==="mint")
    return {ok:true,contextHandle:handle,expiresInSeconds:90};
   if(request.path==="/context"&&request.body.action==="revoke")
    return {ok:true};
   if(request.path==="/answer"&&request.body.intent==="status")
    return {ok:true,state:"available",route:"practice_result"};
   if(request.path==="/answer"&&request.body.intent==="answer")
    return {ok:true,reply:"Prepared, synthetic, verified for review"};
   return {ok:false,reason:"unavailable"};
  }
 });
 const bridge=new QaV21RealAcademicScreenBridge({
  document:x.document,client,serverResolver:client
 });
 assert.equal((await bridge.chooseReviewQuestion(x.row,"uz")).ok,true);
 const response=await bridge.explainSelectedError("uz");
 assert.equal(response.ok,true);
 assert.equal(requests.length,4);
 assert.deepEqual(requests.map(c=>[
  c.path,c.body.action||c.body.intent
 ]),[
  ["/context","resolvePracticeV4"],
  ["/context","mint"],
  ["/answer","status"],
  ["/answer","answer"]
 ]);
 assert.deepEqual(requests[0].body,{
  action:"resolvePracticeV4",attemptReference:701,questionId:202
 });
 assert.deepEqual(requests[1].body,{
  action:"mint",sessionId:900,questionId:202
 });
 assert.equal(requests[2].body.appLocale,"uz");
 assert.equal(requests[3].body.appLocale,"uz");
 assert.equal(requests[3].body.promptKey,"practice_error");
 for(const req of requests){
  assert.equal(req.authorization,"Bearer qa-signed-token-substitute");
  for(const forbidden of ["userId","ownerId","subject","score","correctAnswer","topic","sourceHash"])
   assert.equal(Object.hasOwn(req.body,forbidden),false,forbidden);
 }
 await bridge.onNavigation();
 assert.equal(requests.at(-1).body.action,"revoke");
 assert.equal((await bridge.explainSelectedError("uz")).ok,false);
});
