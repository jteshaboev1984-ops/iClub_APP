"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const HANDLE="11111111-1111-4111-8111-111111111111";
const HANDLE2="22222222-2222-4222-8222-222222222222";
const REQUEST="33333333-3333-4333-8333-333333333333";
function deferred(){let resolve;const promise=new Promise(r=>{resolve=r;});return{promise,resolve};}
function fixture({postOverride,readJwt=async()=> "synthetic-jwt-token"}={}){
 const calls=[];
 const post=async request=>{
  calls.push(request);
  if(postOverride)return postOverride(request);
  if(request.path==="/context")
   return request.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:HANDLE,expiresInSeconds:90};
  return request.body.intent==="status"?{ok:true,state:"available"}:
   {ok:true,reply:"Synthetic QA reply only"};
 };
 const client=new QaV21ScreenClient({post,readJwt,newRequestId:()=>REQUEST});
 return {client,calls};
}
test("Lessons mint server-owned handle and prepared answer omits user, progress, topic, plan",async()=>{
 const f=fixture();
 assert.equal((await f.client.openLesson(101)).ok,true);
 assert.equal((await f.client.askPrepared("topic_main","ru")).reply,"Synthetic QA reply only");
 assert.deepEqual(f.calls.map(x=>x.path),["/context","/answer"]);
 assert.deepEqual(f.calls[0].body,{action:"mintLesson",lessonId:101});
 assert.deepEqual(f.calls[1].body,{intent:"answer",requestId:REQUEST,
  contextHandle:HANDLE,appLocale:"ru",promptKey:"topic_main"});
 for(const call of f.calls){
  assert.equal(call.authorization,"Bearer synthetic-jwt-token");
  for(const forbidden of ["subject","plan","userId","progress","sourceHash","answerKey"])
   assert.equal(Object.hasOwn(call.body,forbidden),false);
 }
});
test("Completed Practice only submits server selectors, no invented scope",async()=>{
 const f=fixture();
 assert.equal((await f.client.openPractice(11,202)).ok,true);
 assert.deepEqual(f.calls[0].body,{action:"mint",sessionId:11,questionId:202});
 assert.equal((await f.client.askQuestion("Почему это происходит?","ru")).ok,true);
 assert.equal(f.calls[1].body.question,"Почему это происходит?");
 assert.equal(f.calls[1].body.appLocale,"ru");
});
test("RU/UZ/EN status is answer-free, no client quota/subject flag",async()=>{
 for(const locale of ["ru","uz","en"]){
  const f=fixture();await f.client.openLesson(101);
  const r=await f.client.status(locale);
  assert.equal(r.state,"available");
  assert.deepEqual(f.calls[1].body,{intent:"status",contextHandle:HANDLE,appLocale:locale});
 }
});
test("Leaving exam/navigation revokes handle and discards late answer",async()=>{
 const pending=deferred();
 const f=fixture({postOverride:r=>r.path==="/context"?
  r.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:HANDLE,expiresInSeconds:90}:
  pending.promise});
 await f.client.openLesson(101);
 const ask=f.client.askPrepared("topic_main","ru");
 await Promise.resolve();
 await f.client.leave();
 pending.resolve({ok:true,reply:"SHOULD_NEVER_RENDER"});
 assert.equal((await ask).reason,"context_changed");
 assert.deepEqual(f.calls.at(-1).body,{action:"revoke",contextHandle:HANDLE});
 assert.equal((await f.client.status("ru")).reason,"context_unavailable");
});
test("Mint returning after navigation is revoked rather than adopted",async()=>{
 const pending=deferred();
 const f=fixture({postOverride:r=>r.body.action==="mintLesson"?
  pending.promise:{ok:true}});
 const open=f.client.openLesson(101);
 await f.client.leave();
 pending.resolve({ok:true,contextHandle:HANDLE2,expiresInSeconds:90});
 assert.equal((await open).reason,"context_changed");
 assert.deepEqual(f.calls.at(-1).body,{action:"revoke",contextHandle:HANDLE2});
 assert.equal((await f.client.askPrepared("topic_main","ru")).reason,"context_unavailable");
});
test("No session / invalid JWT / transport exception fail CLOSED",async()=>{
 const f=fixture({readJwt:async()=>null});
 assert.equal((await f.client.openLesson(101)).reason,"authentication_required");
 assert.equal(f.calls.length,0);
 const x=fixture({postOverride:async()=>{throw Error("private-server-key");}});
 assert.equal((await x.client.openLesson(101)).reason,"unavailable");
 assert.equal(JSON.stringify(await x.client.status("ru")).includes("private-server-key"),false);
});
test("Two clicks cannot make parallel paid requests, no automated retry on timeout",async()=>{
 const pending=deferred();const f=fixture({
  postOverride:r=>r.body.intent==="answer"?pending.promise:
   {ok:true,contextHandle:HANDLE,expiresInSeconds:90}
 });
 await f.client.openLesson(101);
 const ask=f.client.askQuestion("Почему это происходит?","ru");
 await Promise.resolve();
 assert.equal((await f.client.askQuestion("Почему это происходит?","ru")).reason,
  "request_in_progress");
 pending.resolve({ok:false,reason:"delivery_confirmation_unknown"});
 assert.equal((await ask).reason,"delivery_confirmation_unknown");
 assert.equal(f.calls.filter(c=>c.path==="/answer").length,1);
});
test("Bad selectors/locale/ID and duplicate input fail before any request",async()=>{
 const f=fixture();
 assert.equal((await f.client.openPractice(0,202)).reason,"invalid_screen");
 assert.equal((await f.client.openLesson(-1)).reason,"invalid_screen");
 assert.equal(f.calls.length,0);
 await f.client.openLesson(101);
 for(const bad of [""," bad key","!!!"])
  assert.equal((await f.client.askPrepared(bad,"ru")).ok,false);
 assert.equal((await f.client.askQuestion("Hello","fr")).reason,"context_unavailable");
 assert.equal((await f.client.askQuestion("x".repeat(2001),"ru")).reason,"invalid_question");
 assert.equal(f.calls.length,1);
});
test("QA adapter does not persist sessions, transcripts or signing keys",async()=>{
 const f=fixture();await f.client.openLesson(101);
 const keys=Object.keys(f.client);
 for(const forbidden of ["localStorage","sessionStorage","transcript",
  "apiKey","secret","history","provider","progress"])assert.ok(!keys.includes(forbidden));
 assert.ok(!JSON.stringify(f.client).includes("Synthetic QA reply only"));
});

test("§57 reuses one authenticated UI transport for app-view and Tour archive selection",async()=>{
 const f=fixture();
 assert.equal((await f.client.openAppView("home")).ok,true);
 assert.deepEqual(f.calls[0].body,{action:"mintAppView",view:"home"});
 assert.equal((await f.client.openAppView("profile")).ok,true);
 assert.deepEqual(f.calls[1].body,{action:"revoke",contextHandle:HANDLE});
 assert.deepEqual(f.calls[2].body,{action:"mintAppView",view:"profile"});
 assert.equal((await f.client.openTourArchive(401)).ok,true);
 assert.deepEqual(f.calls[4].body,{action:"mintTourArchive",tourAttemptId:401});
 for(const c of f.calls)assert.equal(c.body.userId,undefined);
});
test("§57 unknown app view and invalid Tour selector never reach the Edge",async()=>{
 const f=fixture();
 for(const bad of ["",null,"notifications","support-topic","practice",13]){
  assert.equal((await f.client.openAppView(bad)).reason,"invalid_screen");
 }
 for(const bad of [0,-1,"401",1.7,Number.MAX_SAFE_INTEGER+1])
  assert.equal((await f.client.openTourArchive(bad)).reason,"invalid_screen");
 assert.equal(f.calls.length,0);
});
