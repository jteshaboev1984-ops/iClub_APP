"use strict";
// §57 detached QA-only binding; not referenced by the live app or Edge.
// Browser DOM is only a selector. The server alone grants any context.
const VIEWS=["home","courses","ratings","profile","about","support"];
const fail=reason=>({ok:false,reason});
class QaV21AppScreenBinder{
 constructor({client,document}={}){
  if(!client||typeof client.leave!=="function"||
    typeof client.openAppView!=="function"||
    typeof client.status!=="function"||
    typeof client.askPrepared!=="function")throw Error("missing_qa_view_client");
  if(!document||typeof document.getElementById!=="function")
   throw Error("missing_qa_document");
  this.client=client;this.document=document;this.epoch=0;
  this.key="";this.ready=false;this.userId=null;this.observer=null;
 }
 read(){
  if(this.document.visibilityState==="hidden")return null;
  const el=x=>this.document.getElementById(x);
  const exam=el("exam-prep-host-root");
  if(exam&&!exam.hidden&&exam.getAttribute?.("aria-hidden")!=="true")return null;
  for(const id of ["courses-practice-quiz","courses-tour-quiz"]){
   if(el(id)?.classList?.contains("is-active"))return null;
  }
  const active=VIEWS.filter(v=>el("view-"+v)?.classList?.contains("is-active"));
  // Unknown global view, quiz/registration and overlapping view transitions
  // must never fall back to an old Home or General AI context.
  const unknown=this.document.querySelector?.(".view.is-active");
  if(active.length!==1||unknown?.dataset?.view!==active[0])return null;
  return active[0];
 }
 async sync(){
  const next=this.read(),key=next||"";
  if(key===this.key)return this.ready?{ok:true}:fail("screen_not_verified");
  const seq=++this.epoch;this.key=key;this.ready=false;
  await this.client.leave();
  if(seq!==this.epoch)return fail("context_changed");
  if(!next)return fail("screen_not_verified");
  let res;
  try{res=await this.client.openAppView(next);}
  catch{res=fail("unavailable");}
  if(seq!==this.epoch)return fail("context_changed");
  if(res?.ok!==true)return fail(res?.reason||"context_unavailable");
  if(this.read()!==next){
   ++this.epoch;this.key="";await this.client.leave();
   return fail("context_changed");
  }
  this.ready=true;return{ok:true};
 }
 async status(locale){
  const key=this.key,seq=this.epoch;
  if(!this.ready||!key||this.read()!==key)return fail("screen_not_verified");
  const value=await this.client.status(locale);
  return seq===this.epoch&&this.read()===key?value:fail("context_changed");
 }
 async askPrepared(intent,locale){
  const key=this.key,seq=this.epoch;
  if(!this.ready||!key||this.read()!==key)return fail("screen_not_verified");
  if(!["nav_home","nav_courses","nav_ratings","nav_profile","nav_about","nav_support"].includes(intent))
   return fail("invalid_prompt");
  const value=await this.client.askPrepared(intent,locale);
  return seq===this.epoch&&this.read()===key?value:fail("context_changed");
 }
 async leave(){
  ++this.epoch;this.key="";this.ready=false;
  return this.client.leave();
 }
 async authChanged(event,session){
  const id=typeof session?.user?.id==="string"?session.user.id:null;
  const logout=event==="SIGNED_OUT"||event==="USER_DELETED"||
    (event==="INITIAL_SESSION"&&!id);
  if(logout||(id&&this.userId&&id!==this.userId)){
   this.userId=logout?null:id;
   return this.leave();
  }
  if(id)this.userId=id;
  return{ok:true};
 }
 attach(){
  if(this.observer)return this;
  if(typeof MutationObserver!=="function")return this;
  const root=this.document.getElementById("main");
  if(!root)return this;
  this.observer=new MutationObserver(()=>{void this.sync();});
  this.observer.observe(root,{subtree:true,attributes:true,
   attributeFilter:["class","hidden","aria-hidden"]});
  this.document.addEventListener?.("visibilitychange",this.onVisibilityChange=()=>{
   void this.sync();
  });
  void this.sync();
  return this;
 }
 async disconnect(){
  this.observer?.disconnect();this.observer=null;
  if(this.onVisibilityChange)this.document.removeEventListener?.(
   "visibilitychange",this.onVisibilityChange);
  this.onVisibilityChange=null;
  return this.leave();
 }
}
module.exports={QaV21AppScreenBinder};
