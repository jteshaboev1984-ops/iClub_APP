"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {QaV21AppScreenBinder}=require("./ai-layer-v21-p6-app-screen-binding.cjs");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const handle="11111111-1111-4111-8111-111111111111",req="33333333-3333-4333-8333-333333333333";
const views=["home","courses","ratings","profile","about","support","certificates"];
const defer=()=>{let resolve;const promise=new Promise(r=>resolve=r);return{promise,resolve};};
function fixture(postOverride){
 const calls=[],els={};
 for(const v of views)els["view-"+v]={active:false};
 for(const x of ["courses-practice-quiz","courses-tour-quiz"])
  els[x]={active:false};
 els["exam-prep-host-root"]={active:false,hidden:true,attrs:{}};
 els.main={active:false};
 const mk=id=>({
  classList:{contains:k=>k==="is-active"&&els[id]?.active===true},
  hidden:els[id]?.hidden,
  getAttribute:k=>els[id]?.attrs?.[k]??null
 });
 const doc={
  visibilityState:"visible",getElementById:k=>els[k]?mk(k):null,
  querySelector(selector){
   if(selector!==".view.is-active")return null;
   const v=views.find(v=>els["view-"+v].active);
   return v?{dataset:{view:v}}:null;
  }
 };
 const post=async request=>{
  calls.push(request);
  if(postOverride)return postOverride(request);
  if(request.path==="/context")return request.body.action==="revoke"?
   {ok:true}:{ok:true,contextHandle:handle};
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
  if(event==="practice")f.els["courses-practice-quiz"].active=true;
  if(event==="tour")f.els["courses-tour-quiz"].active=true;
  if(event==="exam")f.els["exam-prep-host-root"].hidden=false;
  a.equal((await f.binder.sync()).reason,"screen_not_verified",event);
  a.equal(f.calls.length,0,event);
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
   r.body.view==="home"?wait.promise:{ok:true,contextHandle:newHandle}:{ok:true});
 f.set("home");
 const p=f.binder.sync();
 for(let i=0;i<6;i++)await Promise.resolve();
 a.equal(f.calls[0].body.view,"home");
 f.set("profile");const changed=f.binder.sync();
 for(let i=0;i<6;i++)await Promise.resolve();
 wait.resolve({ok:true,contextHandle:handle});
 a.equal((await p).reason,"context_changed");
 a.equal((await changed).ok,true);
 a.equal(f.binder.ready,true);
 a.equal(f.client.handle,newHandle);
 a.ok(f.calls.some(x=>x.body.action==="revoke"&&x.body.contextHandle===handle));
 const g=fixture(r=>r.path==="/answer"?wait2.promise:
   r.body.action==="revoke"?{ok:true}:{ok:true,contextHandle:handle});
 const wait2=defer();g.set("profile");await g.binder.sync();
 const ans=g.binder.askPrepared("nav_profile","ru");await Promise.resolve();
 g.set("about");await g.binder.sync();
 wait2.resolve({ok:true,reply:"OLD_USER_SCREEN"});
 a.equal((await ans).reason,"context_changed");
});
test("Logout/account switch invalidates QA scope, unrecognized prepared key denied",async()=>{
 const f=fixture();f.set("home");
 await f.binder.authChanged("SIGNED_IN",{user:{id:"synthetic-a"}});
 await f.binder.sync();
 a.equal((await f.binder.askPrepared("profile_password","ru")).reason,"invalid_prompt");
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
