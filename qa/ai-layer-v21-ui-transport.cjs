// iClub AI v2.1: §37 QA-only browser transport candidate.
// NOT imported by index.html, app.js, global-ai-ui.js or any deployed Edge.
// No storage/cookie/progress writes and no credentials baked into source.
"use strict";
const UUID=/^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const TOKEN=/^[A-Za-z0-9._-]{8,2048}$/;
const LOCALES=new Set(["ru","uz","en"]);
const fail=reason=>({ok:false,reason});
const validIndex=x=>Number.isSafeInteger(x)&&x>0;
class QaV21ScreenClient{
 constructor({post,readJwt,newRequestId,nowMs=Date.now}={}){
  if(typeof post!=="function"||typeof readJwt!=="function"||
   typeof newRequestId!=="function"||typeof nowMs!=="function")throw Error("unconfigured_qa_transport");
  this.post=post;
  this.readJwt=readJwt;
  this.newRequestId=newRequestId;
  this.nowMs=nowMs;
  this.lastClockMs=-1;
  this.clockUnsafe=false;
  this.expiresAtMs=0;
  this.epoch=0;
  this.handle=null;
  this.inFlight=false;
 }
 // Authentication acquisition is part of the trusted operation. A
 // rejected token reader must never escape as an unhandled promise.
 async authenticatedPost(path,body){
  let token;
  try{token=await this.readJwt();}
  catch{return fail("authentication_required");}
  if(typeof token!=="string"||!TOKEN.test(token))
   return fail("authentication_required");
  try{
   const res=await this.post({path,authorization:"Bearer "+token,body});
   return res&&typeof res==="object"&&!Array.isArray(res)?
    res:fail("unavailable");
  }catch{return fail("unavailable");}
 }
 safeNow(){
  let now;
  try{now=this.nowMs();}catch{this.clockUnsafe=true;return null;}
  // Wall-clock rollback after authorization must not extend a granted TTL.
  // Once unsafe, remain closed until a new client/verified session is built.
  if(this.clockUnsafe||!Number.isSafeInteger(now)||now<0||
     now<this.lastClockMs){
   this.clockUnsafe=true;return null;
  }
  this.lastClockMs=now;
  return now;
 }
 async revoke(handle){
  if(!UUID.test(handle||""))return fail("invalid_context");
  return await this.authenticatedPost("/context",{
   action:"revoke",contextHandle:handle
  });
 }
 async leave(){
  // Drop local authority BEFORE awaiting the remote revocation RPC.
  ++this.epoch;
  const old=this.handle;
  this.handle=null;
  this.expiresAtMs=0;
  this.inFlight=false;
  if(old)await this.revoke(old);
  return {ok:true};
 }
 async openLesson(lessonId){
  if(!validIndex(lessonId))return fail("invalid_screen");
  return this.open({action:"mintLesson",lessonId});
 }
 async openPractice(sessionId,questionId){
  if(!validIndex(sessionId)||!validIndex(questionId))
   return fail("invalid_screen");
  return this.open({action:"mint",sessionId,questionId});
 }
 async openTourArchive(tourAttemptId){
  if(!validIndex(tourAttemptId))return fail("invalid_screen");
  return this.open({action:"mintTourArchive",tourAttemptId});
 }
 async openAppView(view){
  if(!["home","profile","courses","ratings","about","support"].includes(view))
   return fail("invalid_screen");
  return this.open({action:"mintAppView",view});
 }
 async open(body){
  ++this.epoch;
  const seq=this.epoch;
  const prev=this.handle;
  this.handle=null;
  this.expiresAtMs=0;
  this.inFlight=false;
  if(prev)await this.revoke(prev);
  if(seq!==this.epoch)return fail("context_changed");
  // Conservative lease bound starts BEFORE JWT/network awaits.
  const begunAt=this.safeNow();
  if(begunAt===null)
   return fail("invalid_context_clock");
  const r=await this.authenticatedPost("/context",body);
  if(r?.ok!==true||!UUID.test(r.contextHandle||""))
   return fail(r?.reason||"context_unavailable");
  // An arbitrary boolean from /context does not grant an unlimited lease.
  // The QA Edge contract returns 1..90 seconds for every successful mint.
  if(!Number.isInteger(r.expiresInSeconds)||r.expiresInSeconds<1||
     r.expiresInSeconds>90){
   await this.revoke(r.contextHandle);
   return fail("invalid_context_expiry");
  }
  if(seq!==this.epoch){
   // Mint finished AFTER navigation; revoke that handle, never display it.
   await this.revoke(r.contextHandle);
   return fail("context_changed");
  }
  const now=this.safeNow();
  const deadline=begunAt+r.expiresInSeconds*1000;
  if(now===null||!Number.isSafeInteger(deadline)||now>=deadline){
   await this.revoke(r.contextHandle);return fail("context_expired");
  }
  this.handle=r.contextHandle;
  this.expiresAtMs=deadline;
  return {ok:true};
 }
 isCurrent(){
  const now=this.safeNow();
  return Boolean(this.handle)&&now!==null&&now<this.expiresAtMs;
 }
 async status(locale){
  if(!LOCALES.has(locale)||!this.handle)return fail("context_unavailable");
  if(!this.isCurrent())return fail("context_expired");
  const seq=this.epoch;
  const handle=this.handle;
  const r=await this.authenticatedPost("/answer",{
   intent:"status",contextHandle:handle,appLocale:locale
  });
  return seq===this.epoch&&this.handle===handle?
   this.isCurrent()?r:fail("context_expired"):fail("context_changed");
 }
 async askPrepared(promptKey,locale){
  if(typeof promptKey!=="string"||!/^[a-z0-9_]{3,60}$/.test(promptKey))
   return fail("invalid_prompt");
  return this.ask({promptKey},locale);
 }
 async askQuestion(question,locale){
  if(typeof question!=="string"||!question.trim()||
    question.length>2000)return fail("invalid_question");
  return this.ask({question:question.trim()},locale);
 }
 async ask(input,locale){
  if(!LOCALES.has(locale)||!this.handle)return fail("context_unavailable");
  if(!this.isCurrent())return fail("context_expired");
  if(this.inFlight)return fail("request_in_progress");
  const requestId=this.newRequestId();
  if(!UUID.test(requestId||""))return fail("invalid_request_id");
  const seq=this.epoch;
  const contextHandle=this.handle;
  this.inFlight=true;
  try{
   const r=await this.authenticatedPost("/answer",{
    intent:"answer",requestId,contextHandle,appLocale:locale,...input
   });
   // Do not display a reply after route, learner, account or screen switch.
   // Do not issue any automatic retries (the server might already have billed).
   if(seq!==this.epoch||this.handle!==contextHandle)
    return fail("context_changed");
   if(!this.isCurrent())return fail("context_expired");
   return r;
  }finally{
   if(seq===this.epoch)this.inFlight=false;
  }
 }
}
module.exports={QaV21ScreenClient};
