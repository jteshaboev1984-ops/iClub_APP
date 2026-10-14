"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {QaV21AppScreenBinder}=require("./ai-layer-v21-p6-app-screen-binding.cjs");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const handle="11111111-1111-4111-8111-111111111111",req="33333333-3333-4333-8333-333333333333";
const views=["home","courses","ratings","profile","about","support","certificates"];
const courseScreensForTest=[
 "courses-subject-hub","courses-lessons","courses-video",
 "courses-practice-start","courses-practice-quiz","courses-practice-result",
 "courses-practice-review","courses-practice-recs","courses-tours",
 "courses-tour-rules","courses-tour-quiz","courses-tour-result",
 "courses-tour-review","courses-books","courses-my-recs","courses-my-rec-detail"
];
const defer=()=>{let resolve;const promise=new Promise(r=>resolve=r);return{promise,resolve};};
function fixture(postOverride){
 const calls=[],els={};
 for(const v of views)els["view-"+v]={active:false};
 const courseScreens=["all-subjects","subject-hub","lessons","video",
  "practice-start","practice-quiz","practice-result","practice-review",
  "practice-recs","tours","tour-rules","tour-quiz","tour-result",
  "tour-review","books","my-recs","my-rec-detail"];
 for(const x of courseScreens)
  els["courses-"+x]={active:x==="all-subjects"};
 els["exam-prep-host-root"]={active:false,hidden:true,attrs:{}};
 els.main={active:false};
 const mk=id=>({
  classList:{contains:k=>k==="is-active"&&els[id]?.active===true},
  hidden:els[id]?.hidden,
  getAttribute:k=>els[id]?.attrs?.[k]??null
 });
 const doc={
  visibilityState:"visible",getElementById:k=>els[k]?mk(k):null,
  querySelectorAll(selector){
   if(selector===".view.is-active")
    return views.filter(v=>els["view-"+v].active).map(v=>({dataset:{view:v}}));
   if(selector==="#view-courses .stack-screen.is-active")
    return courseScreens.filter(v=>els["courses-"+v].active)
      .map(v=>({id:"courses-"+v}));
   return [];
  }
 };
 const post=async request=>{
  calls.push(request);
  if(postOverride)return postOverride(request);
  if(request.path==="/context")return request.body.action==="revoke"?
   {ok:true}:{ok:true,contextHandle:handle,expiresInSeconds:90};
  return request.body.intent==="status"?{ok:true,state:"in_development"}:
   {ok:false,state:"in_development"};
 };
 const client=new QaV21ScreenClient({post,readJwt:async()=>"synthetic-public-jwt-001",
  newRequestId:()=>req});
 const binder=new QaV21AppScreenBinder({client,document:doc});
 const set=v=>{for(const key of views)els["view-"+key].active=key===v;};
 return{calls,els,doc,client,binder,set};
}
test("§57 Home Profile About Support use ONE exact server-owned context with no user fields",async()=>{
 const f=fixture();f.set("home");
 a.equal((await f.binder.sync()).ok,true);
 a.deepEqual(f.calls[0].body,{action:"mintAppView",view:"home"});
 for(const view of ["profile","about","support","ratings","courses"]){
  f.set(view);a.equal((await f.binder.sync()).ok,true);
  a.deepEqual(f.calls.at(-1).body,{action:"mintAppView",view});
 }
 a.equal(f.calls.filter(x=>x.body.action==="mintAppView").length,6);
 a.equal(f.calls.filter(x=>x.body.action==="revoke").length,5);
 for(const call of f.calls){
  a.equal(call.body.userId,undefined);a.equal(call.body.progress,undefined);
  a.equal(call.body.plan,undefined);a.equal(call.body.subject,undefined);
 }
 a.equal((await f.binder.status("ru")).state,"in_development");
 a.equal((await f.binder.askPrepared("nav_about","en")).state,"in_development");
});
test("Unlisted pages, overlapping views, hidden browser and all protected quiz states deny mint",async()=>{
 for(const event of ["none","unknown","overlap","hidden","practice","tour","exam"]){
  const f=fixture();f.set("home");
  if(event==="none")f.set("");
  if(event==="unknown")f.set("certificates");
  if(event==="overlap")f.els["view-profile"].active=true;
  if(event==="hidden")f.doc.visibilityState="hidden";
  if(event==="practice"){
   f.els["courses-all-subjects"].active=false;
   f.els["courses-practice-quiz"].active=true;
  }
  if(event==="tour"){
   f.els["courses-all-subjects"].active=false;
   f.els["courses-tour-quiz"].active=true;
  }
  if(event==="exam")f.els["exam-prep-host-root"].hidden=false;
  a.equal((await f.binder.sync()).reason,"screen_not_verified",event);
  a.equal(f.calls.length,0,event);
 }
});
test("§58 active nested lessons/reviews or unknown overlay cannot steal independent AI scope",async()=>{
 for(const id of courseScreensForTest){
  const f=fixture();f.set("courses");
  f.els["courses-all-subjects"].active=false;f.els[id].active=true;
  a.equal((await f.binder.sync()).reason,"screen_not_verified",id);
  a.equal(f.calls.length,0,id);
 }
 const overlay=fixture();overlay.set("home");overlay.els["view-certificates"].active=true;
 a.equal((await overlay.binder.sync()).reason,"screen_not_verified");
 a.equal(overlay.calls.length,0);
});
test("§58 Home/Profile never dispatch unapproved General Help prompt",async()=>{
 for(const view of ["home","profile"]){
  const f=fixture();f.set(view);a.equal((await f.binder.sync()).ok,true);
  const length=f.calls.length;
  a.equal((await f.binder.askPrepared("nav_about","ru")).reason,"source_in_development");
  a.equal(f.calls.length,length);
 }
});
test("§60 leaving an already minted Home or Courses for unsupported overlay revokes authority",async()=>{
 for(const transition of ["certificates","course-review","dual-view"]){
  const f=fixture();f.set(transition==="course-review"?"courses":"home");
  a.equal((await f.binder.sync()).ok,true,transition);
  if(transition==="certificates")f.set("certificates");
  if(transition==="course-review")f.els["courses-practice-review"].active=true;
  if(transition==="dual-view")f.els["view-profile"].active=true;
  a.equal((await f.binder.sync()).reason,"screen_not_verified",transition);
  a.equal(f.binder.ready,false,transition);
  a.deepEqual(f.calls.map(x=>x.body.action),["mintAppView","revoke"],transition);
  a.equal((await f.binder.status("ru")).reason,"screen_not_verified");
  a.equal(f.calls.length,2,"Old context must not be reused for "+transition);
 }
});
test("Changing tabs or document visibility drops local authority and remote handle",async()=>{
 const f=fixture();f.set("home");await f.binder.sync();
 f.doc.visibilityState="hidden";
 a.equal((await f.binder.sync()).reason,"screen_not_verified");
 a.deepEqual(f.calls.map(x=>x.body.action),["mintAppView","revoke"]);
 a.equal((await f.binder.status("ru")).reason,"screen_not_verified");
 f.doc.visibilityState="visible";a.equal((await f.binder.sync()).ok,true);
 a.equal(f.calls.at(-1).body.view,"home");
 await f.binder.disconnect();
 a.equal(f.calls.at(-1).body.action,"revoke");
});
test("Race: late mint does not grant abandoned view and revoked answer does not display",async()=>{
 const wait=defer(),newHandle="22222222-2222-4222-8222-222222222222";
 const f=fixture(r=>r.body.action==="mintAppView"?
   r.body.view==="home"?wait.promise:{ok:true,contextHandle:newHandle,expiresInSeconds:90}:{ok:true});
 f.set("home");
 const p=f.binder.sync();
 for(let i=0;i<6;i++)await Promise.resolve();
 a.equal(f.calls[0].body.view,"home");
 f.set("profile");const changed=f.binder.sync();
 for(let i=0;i<6;i++)await Promise.resolve();
 wait.resolve({ok:true,contextHandle:handle,expiresInSeconds:90});
 a.equal((await p).reason,"context_changed");
 a.equal((await changed).ok,true);
 a.equal(f.binder.ready,true);
 a.equal(f.client.handle,newHandle);
 a.ok(f.calls.some(x=>x.body.action==="revoke"&&x.body.contextHandle===handle));
 const g=fixture(r=>r.path==="/answer"?wait2.promise:
   r.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:handle,expiresInSeconds:90});
 const wait2=defer();g.set("support");await g.binder.sync();
 const ans=g.binder.askPrepared("nav_profile","ru");await Promise.resolve();
 g.set("about");await g.binder.sync();
 wait2.resolve({ok:true,reply:"OLD_USER_SCREEN"});
 a.equal((await ans).reason,"context_changed");
});
test("§62 expired server lease invalidates UI readiness and does not silently remint",async()=>{
 const f=fixture();let clock=100000;
 f.client.nowMs=()=>clock;
 f.set("support");a.equal((await f.binder.sync()).ok,true);
 const issued=f.calls.length;
 clock=190000;
 a.equal((await f.binder.askPrepared("nav_support","ru")).reason,"context_expired");
 a.equal((await f.binder.status("ru")).reason,"context_expired");
 a.equal(f.calls.length,issued,"No answer is sent after expiry");
 a.equal((await f.binder.sync()).reason,"context_expired");
 a.equal(f.binder.ready,false);
 a.deepEqual(f.calls.at(-1).body,{action:"revoke",contextHandle:handle});
 a.equal((await f.binder.sync()).reason,"screen_not_verified");
 a.equal(f.calls.filter(x=>x.body.action==="mintAppView").length,1);
});
test("Logout/account switch invalidates QA scope, unrecognized prepared key denied",async()=>{
 const f=fixture();f.set("home");
 await f.binder.authChanged("SIGNED_IN",{user:{id:"synthetic-a"}});
 await f.binder.sync();
 a.equal((await f.binder.askPrepared("profile_password","ru")).reason,"source_in_development");
 a.equal((await f.binder.authChanged("SIGNED_OUT",null)).ok,true);
 a.equal(f.binder.ready,false);
 a.equal(f.calls.at(-1).body.action,"revoke");
 f.set("profile");
 const oldCount=f.calls.length;
 a.equal((await f.binder.sync()).reason,"screen_not_verified");
 a.equal(f.calls.length,oldCount,"logged-out user re-minted a context");
 await f.binder.authChanged("SIGNED_IN",{user:{id:"synthetic-a"}});
 a.equal((await f.binder.sync()).ok,true);
 a.equal(f.calls.at(-1).body.view,"profile");
 a.equal((await f.binder.authChanged("SIGNED_IN",{user:{id:"synthetic-b"}})).ok,true);
 a.equal(f.calls.at(-1).body.action,"revoke");
 a.equal(f.binder.ready,false);
});
