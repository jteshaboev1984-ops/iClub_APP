"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {QaV21ScreenBinder}=require("./ai-layer-v21-screen-binding.cjs");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const H="11111111-1111-4111-8111-111111111111";
const REQ="33333333-3333-4333-8333-333333333333";
const defer=()=>{let resolve;const promise=new Promise(r=>resolve=r);return{promise,resolve};};
class Element{
 constructor(attrs={},active=false){this.attrs={...attrs};this.classList={
  active,contains:x=>x==="is-active"&&this.classList.active};
  this.hidden=false;this.selected=[];}
 getAttribute(k){return this.attrs[k]??null;}
 querySelectorAll(){return this.selected;}
}
function fixture({server}={}){
 const calls=[];
 const elements={
  "view-courses":new Element({},true),
  "courses-video":new Element(),
  "courses-practice-review":new Element(),
  "courses-practice-quiz":new Element(),
  "courses-tour-quiz":new Element(),
  "exam-prep-host-root":new Element()
 };
 elements["exam-prep-host-root"].hidden=true;
 const doc={getElementById:k=>elements[k]||null};
 const post=async req=>{
  calls.push(req);
  if(server)return server(req);
  if(req.path==="/context")
   return req.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:H};
  return req.body.intent==="status"?{ok:true,state:"in_development"}:
   {ok:false,state:"in_development"};
 };
 const client=new QaV21ScreenClient({post,readJwt:async()=> "synthetic-public-jwt-001",
  newRequestId:()=>REQ});
 const binder=new QaV21ScreenBinder({client,document:doc});
 return {binder,client,calls,elements};
}
function lesson(f,id="101"){
 f.elements["courses-video"].classList.active=true;
 if(id!==null)f.elements["courses-video"].attrs["data-iclub-ai-v21-lesson-id"]=id;
}
function review(f,session="11",question="202"){
 const el=f.elements["courses-practice-review"];
 el.classList.active=true;el.attrs["data-iclub-ai-v21-session-id"]=session;
 el.selected=[new Element({"data-iclub-ai-v21-question-id":question})];
}
test("Real app-compatible DOM WITHOUT new selectors produces zero V2 requests",async()=>{
 const f=fixture();
 f.elements["courses-video"].classList.active=true;
 assert.equal((await f.binder.sync()).reason,"screen_not_verified");
 assert.equal(f.calls.length,0);
});
test("Lesson sends ONLY its exact current canonical ID; source still not ready",async()=>{
 const f=fixture();lesson(f);
 assert.equal((await f.binder.sync()).ok,true);
 assert.deepEqual(f.calls[0].body,{action:"mintLesson",lessonId:101});
 assert.equal((await f.binder.status("ru")).state,"in_development");
 assert.equal(f.calls.length,2);
 assert.equal((await f.binder.sync()).ok,true);
 assert.equal(f.calls.length,2);
});
test("Practice review requires V4 session ID AND one exact answered question selector",async()=>{
 const f=fixture();review(f);
 assert.equal((await f.binder.sync()).ok,true);
 assert.deepEqual(f.calls[0].body,{action:"mint",sessionId:11,questionId:202});
 assert.equal((await f.binder.askPrepared("topic_main","en")).state,"in_development");
 assert.equal(f.calls.some(c=>c.body.userId||c.body.subjectId||c.body.plan),false);
});
test("Legacy attempt ID alone must never mint V2 Practice context",async()=>{
 const f=fixture();
 const r=f.elements["courses-practice-review"];r.classList.active=true;
 r.attrs["data-practice-ai-attempt-id"]="11";
 r.selected=[new Element({"data-iclub-ai-v21-question-id":"202"})];
 assert.equal((await f.binder.sync()).reason,"screen_not_verified");
 assert.equal(f.calls.length,0);
});
test("Invalid selectors or multiple selected Practice questions deny entirely",async()=>{
 for(const value of ["0","-1","001","1.3","Infinity","9007199254740992","abc"]){
  const f=fixture();lesson(f,value);
  assert.equal((await f.binder.sync()).reason,"screen_not_verified",value);
  assert.equal(f.calls.length,0);
 }
 const f=fixture();review(f);
 f.elements["courses-practice-review"].selected.push(
  new Element({"data-iclub-ai-v21-question-id":"203"}));
 assert.equal((await f.binder.sync()).reason,"screen_not_verified");
 assert.equal(f.calls.length,0);
});
test("Active Practice Quiz, tour, protected Exam Prep or other tab blocks mint",async()=>{
 for(const id of ["courses-practice-quiz","courses-tour-quiz"]){
  const f=fixture();lesson(f);f.elements[id].classList.active=true;
  assert.equal((await f.binder.sync()).reason,"screen_not_verified");
  assert.equal(f.calls.length,0);
 }
 const f=fixture();lesson(f);f.elements["exam-prep-host-root"].hidden=false;
 assert.equal((await f.binder.sync()).reason,"screen_not_verified");
 const g=fixture();lesson(g);g.elements["view-courses"].classList.active=false;
 assert.equal((await g.binder.sync()).reason,"screen_not_verified");
});
test("Leaving Lesson revokes handle before another Practice screen can mint",async()=>{
 const f=fixture();lesson(f);
 assert.equal((await f.binder.sync()).ok,true);
 f.elements["courses-video"].classList.active=false;review(f);
 assert.equal((await f.binder.sync()).ok,true);
 assert.deepEqual(f.calls.map(c=>c.body.action),["mintLesson","revoke","mint"]);
 assert.equal((await f.binder.disconnect()).ok,true);
 assert.equal(f.calls.at(-1).body.action,"revoke");
});
test("Stale answer from old screen is never returned by binder",async()=>{
 const wait=defer(),f=fixture({server:r=>
  r.path==="/answer"?wait.promise:
  r.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:H}});
 lesson(f);await f.binder.sync();
 const result=f.binder.askPrepared("topic_main","ru");
 await Promise.resolve();
 f.elements["courses-video"].classList.active=false;
 const leave=f.binder.sync();
 await leave;
 wait.resolve({ok:true,reply:"PRIVATE_OLD_SCREEN"});
 assert.equal((await result).reason,"context_changed");
});
test("Late mint must not open abandoned Lesson after navigation",async()=>{
 const wait=defer(),f=fixture({server:r=>
  r.body.action==="mintLesson"?wait.promise:{ok:true}});
 lesson(f);
 const pending=f.binder.sync();
 await Promise.resolve();
 f.elements["courses-video"].classList.active=false;
 await f.binder.sync();
 wait.resolve({ok:true,contextHandle:H});
 assert.equal((await pending).reason,"context_changed");
 assert.equal(f.binder.ready,false);
 assert.equal(f.binder.screenKey,"");
});
test("Changed account/signout revokes; same-user token refresh keeps context",async()=>{
 const f=fixture();lesson(f);
 await f.binder.authChanged("SIGNED_IN",{user:{id:"user-a"}});
 await f.binder.sync();
 await f.binder.authChanged("TOKEN_REFRESHED",{user:{id:"user-a"}});
 assert.equal(f.binder.ready,true);
 await f.binder.authChanged("SIGNED_IN",{user:{id:"user-b"}});
 assert.equal(f.binder.ready,false);
 assert.equal(f.calls.at(-1).body.action,"revoke");
 await f.binder.authChanged("SIGNED_OUT",null);
 assert.equal(f.binder.ready,false);
});
test("Unknown server/publication denies without inventing answer or quota",async()=>{
 const f=fixture({server:r=>r.body.action==="mintLesson"?
  {ok:false,reason:"global_ai_disabled"}:{ok:false}});
 lesson(f);
 assert.equal((await f.binder.sync()).reason,"global_ai_disabled");
 assert.equal((await f.binder.askPrepared("topic_main","ru")).reason,"screen_not_verified");
 assert.equal(f.calls.length,1);
});
