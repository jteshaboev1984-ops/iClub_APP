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
 // Wait until the synthetic /context POST actually exists: navigation
 // BEFORE dispatch is now cancelled by §72's stronger JWT race guard.
 for(let k=0;k<8&&f.calls.length===0;k++)await Promise.resolve();
 assert.equal(f.calls[0]?.body.action,"mintLesson",
  "This case must cover a dispatched but still-pending mint response");
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

test("§62 server-defined context TTL expires locally before any new answer or status",async()=>{
 let clock=100000;
 const f=fixture({postOverride:r=>r.path==="/context"?
  r.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:HANDLE,expiresInSeconds:2}:
  {ok:true,reply:"MUST_NOT_DELIVER"}});
 f.client.nowMs=()=>clock;
 assert.equal((await f.client.openAppView("about")).ok,true);
 assert.equal(f.client.isCurrent(),true);
 clock=102000;
 assert.equal(f.client.isCurrent(),false);
 assert.equal((await f.client.status("ru")).reason,"context_expired");
 assert.equal((await f.client.askPrepared("nav_about","ru")).reason,"context_expired");
 assert.deepEqual(f.calls.map(x=>x.path),["/context"],"No billed answer after TTL");
 await f.client.leave();
 assert.equal(f.client.expiresAtMs,0);
});
test("§62 malformed or missing lease from /context cannot establish any client authority",async()=>{
 for(const lease of [undefined,0,-1,91,1.2,"90",null,NaN,Infinity]){
  const f=fixture({postOverride:r=>r.body.action==="revoke"?{ok:true}:{
   ok:true,contextHandle:HANDLE,expiresInSeconds:lease
  }});
  assert.equal((await f.client.openAppView("profile")).reason,
   "invalid_context_expiry",String(lease));
  assert.equal(f.client.handle,null);
  assert.equal(f.client.expiresAtMs,0);
  assert.deepEqual(f.calls.at(-1).body,{action:"revoke",contextHandle:HANDLE});
 }
});
test("§62 replies crossing the context expiry deadline are discarded even on same view",async()=>{
 let clock=300000;
 const pending=deferred();
 const f=fixture({postOverride:r=>r.path==="/answer"?pending.promise:
  r.body.action==="revoke"?{ok:true}:{
   ok:true,contextHandle:HANDLE,expiresInSeconds:1
  }});
 f.client.nowMs=()=>clock;
 assert.equal((await f.client.openAppView("support")).ok,true);
 const reply=f.client.askPrepared("nav_support","uz");
 await Promise.resolve();
 clock=301000;
 pending.resolve({ok:true,reply:"STALE_MUST_NOT_DISPLAY"});
 assert.equal((await reply).reason,"context_expired");
 assert.equal(f.calls.filter(x=>x.path==="/answer").length,1,
  "No second provider billing attempt");
});
test("§63 delayed /context responses do not extend the original server TTL",async()=>{
 const pending=deferred();let clock=100000;
 const f=fixture({postOverride:r=>r.body.action==="revoke"?{ok:true}:pending.promise});
 f.client.nowMs=()=>clock;
 const opening=f.client.openAppView("about");
 for(let k=0;k<8;k++)await Promise.resolve();
 clock=190001;
 pending.resolve({ok:true,contextHandle:HANDLE,expiresInSeconds:90});
 assert.equal((await opening).reason,"context_expired");
 assert.equal(f.client.handle,null);
 assert.deepEqual(f.calls.at(-1).body,{action:"revoke",contextHandle:HANDLE});
 assert.equal(f.calls.some(x=>x.path==="/answer"),false);
});
test("§63 clock regressions fail closed before adopting any returned handle",async()=>{
 for(const invalid of [-1,NaN,Infinity,1.2]){
  const f=fixture();f.client.nowMs=()=>invalid;
  assert.equal((await f.client.openAppView("about")).reason,"invalid_context_clock");
  assert.equal(f.client.handle,null);
  assert.equal(f.calls.length,0);
 }
 const f=fixture();let clock=400000;
 f.client.nowMs=()=>clock;
 const pending=deferred();
 f.client.post=r=>r.body.action==="revoke"?{ok:true}:pending.promise;
 const opening=f.client.openAppView("profile");
 for(let k=0;k<8;k++)await Promise.resolve();
 clock=399999;
 pending.resolve({ok:true,contextHandle:HANDLE,expiresInSeconds:90});
 assert.equal((await opening).reason,"context_expired");
 assert.equal(f.client.handle,null);
});

test("§67 wall-clock rollback AFTER mint cannot extend context or deliver answers",async()=>{
 let clock=100000;
 const f=fixture();f.client.nowMs=()=>clock;
 assert.equal((await f.client.openAppView("support")).ok,true);
 assert.equal(f.client.isCurrent(),true);
 clock=109000;assert.equal(f.client.isCurrent(),true);
 clock=108999;
 assert.equal(f.client.isCurrent(),false,"clock rollback must invalidate the lease");
 clock=110000;
 assert.equal(f.client.isCurrent(),false,"clock cannot revive a poisoned lease");
 assert.equal((await f.client.status("ru")).reason,"context_expired");
 assert.equal((await f.client.askPrepared("nav_support","ru")).reason,"context_expired");
 assert.equal(f.calls.filter(x=>x.path==="/answer").length,0);
 await f.client.leave();
 assert.equal((await f.client.openAppView("support")).reason,"invalid_context_clock");
 assert.equal(f.calls.filter(x=>x.body.action==="mintAppView").length,1);
});
test("§67 clock provider throws safely without leaking or sending a network request",async()=>{
 const f=fixture();
 f.client.nowMs=()=>{throw Error("SYNTHETIC_CLOCK_PRIVATE")};
 assert.equal((await f.client.openAppView("home")).reason,"invalid_context_clock");
 assert.equal(f.client.isCurrent(),false);
 assert.equal(f.calls.length,0);
});
test("§68 rejected JWT reader never throws or forwards a stale credential",async()=>{
 let reads=0;
 const f=fixture({readJwt:async()=>{
  reads++;throw Error("SYNTHETIC_JWT_PRIVATE");
 }});
 assert.equal((await f.client.openAppView("profile")).reason,
  "authentication_required");
 assert.equal(f.client.handle,null);
 assert.equal(f.calls.length,0);
 assert.equal(reads,1);
 assert.equal((await f.client.revoke(HANDLE)).reason,"authentication_required");
 assert.equal(f.calls.length,0);
});
test("§68 rejection during answer is contained, and no data/credential is emitted",async()=>{
 let tokenReads=0;
 const f=fixture({readJwt:async()=>{
  if(++tokenReads===1)return "synthetic-jwt-token";
  throw Error("SYNTHETIC_JWT_PRIVATE");
 }});
 assert.equal((await f.client.openAppView("about")).ok,true);
 const reply=await f.client.askPrepared("nav_about","uz");
 assert.equal(reply.reason,"authentication_required");
 assert.equal(f.calls.length,1,"invalid JWT must prevent any answer post");
 assert.equal(JSON.stringify(reply).includes("SYNTHETIC_JWT_PRIVATE"),false);
});


test("§72 late JWT on context mint cannot send to Edge after sign-out",async()=>{
 const jwt=deferred();let reads=0;
 const f=fixture({readJwt:async()=>++reads===1?jwt.promise:"synthetic-jwt-token"});
 const mint=f.client.openAppView("home");
 await Promise.resolve();
 await f.client.leave();
 jwt.resolve("synthetic-jwt-token");
 assert.equal((await mint).reason,"context_changed");
 assert.equal(f.calls.length,0,"Abandoned mint must never post or reserve capacity");
 assert.equal(f.client.handle,null);
});
test("§72 delayed JWT on prepared answer or status cannot post after logout or screen switch",async()=>{
 for(const intent of ["answer","status"]){
  for(const mode of ["logout","screen_switch"]){
   const jwt=deferred();let reads=0;
   const f=fixture({readJwt:async()=>++reads===2?jwt.promise:"synthetic-jwt-token"});
   assert.equal((await f.client.openAppView("support")).ok,true);
   const pending=intent==="answer"?f.client.askPrepared("nav_home","ru"):
    f.client.status("ru");
   await Promise.resolve();
   if(mode==="logout")await f.client.leave();
   else assert.equal((await f.client.openAppView("ratings")).ok,true);
   jwt.resolve("synthetic-jwt-token");
   assert.equal((await pending).reason,"context_changed",intent+":"+mode);
   assert.equal(f.calls.filter(c=>c.path==="/answer").length,0,
    "Late JWT must not dispatch a stale paid or prepared request");
  }
 }
});
test("§72 context expiration during JWT lookup prevents even status/answer dispatch",async()=>{
 for(const intent of ["answer","status"]){
  let clock=100000,reads=0;
  const jwt=deferred();
  const f=fixture({readJwt:async()=>++reads===2?jwt.promise:"synthetic-jwt-token"});
  f.client.nowMs=()=>clock;
  assert.equal((await f.client.openAppView("support")).ok,true);
  const pending=intent==="answer"?f.client.askPrepared("nav_support","uz"):
   f.client.status("uz");
  await Promise.resolve();
  clock=190000;
  jwt.resolve("synthetic-jwt-token");
  assert.equal((await pending).reason,"context_expired",intent);
  assert.equal(f.calls.filter(c=>c.path==="/answer").length,0);
 }
});

test("§72 delayed JWT beyond maximum context lease rejects mint without Edge request",async()=>{
 const jwt=deferred();let clock=100000;
 const f=fixture({readJwt:async()=>jwt.promise});
 f.client.nowMs=()=>clock;
 const pending=f.client.openAppView("about");
 await Promise.resolve();
 clock=190001;
 jwt.resolve("synthetic-jwt-token");
 assert.equal((await pending).reason,"context_changed");
 assert.equal(f.calls.length,0);
 assert.equal(f.client.handle,null);
});
