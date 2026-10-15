"use strict";
/**
 * iClub AI v2.1 — QA-only REAL APP academic context bridge.
 *
 * Reads selectors from unchanged index.html/app.js, but no browser DOM data
 * is ever treated as ownership, completion or source proof.
 * This module NEVER imports into production, sends requests, reads storage,
 * changes academic state, adds marks or calls a provider.
 *
 * The live app's practiceAiAttemptId is intentionally named "attemptReference".
 * It is NOT safe to pass it as practice_sessions_v4.id to mint without a
 * JWT-bound server resolver. The resolver and /context mint each independently
 * enforce ownership, finalization and exact answer identity.
 *
 * Lessons currently render a list of records, while the video screen can
 * resolve to the subject-level Telegram group. Neither is a specific
 * editor-approved lesson transcript, so both academic routes remain closed.
 */
const fail=(reason)=>Object.freeze({ok:false,reason});
const positive=(v)=>typeof v==="string"&&/^[1-9][0-9]{0,14}$/.test(v)&&
 Number.isSafeInteger(Number(v))&&Number(v)>0;
class QaV21RealAcademicScreenBridge {
 constructor({document,client,serverResolver}={}){
  if(!document||typeof document.getElementById!=="function"||
     typeof document.querySelectorAll!=="function"||
     !client||typeof client.leave!=="function"||
     typeof client.openPractice!=="function"||
     typeof client.status!=="function"||
     typeof client.askPrepared!=="function"||
     typeof serverResolver?.resolvePracticeV4!=="function")
   throw Error("missing_qa_academic_server_binding");
  this.document=document;
  this.client=client;
  this.resolver=serverResolver;
  this.epoch=0;
  this.active=null;
  this.suspended=false;
  this.subjects=Object.freeze(["biology","chemistry","economics","informatics","mathematics"]);
  this.observer=null;
 }
 protected(){
  const e=id=>this.document.getElementById(id);
  const exam=e("exam-prep-host-root");
  if(exam&&!exam.hidden&&exam.getAttribute?.("aria-hidden")!=="true")return true;
  return ["courses-practice-quiz","courses-tour-quiz"].some(id=>
   e(id)?.classList?.contains("is-active"));
 }
 readReviewCandidate(row){
  if(this.suspended||this.document.visibilityState==="hidden"||this.protected())
   return null;
  const views=Array.from(this.document.querySelectorAll(".view.is-active"));
  if(views.length!==1||views[0]?.id!=="view-courses")return null;
  const inner=Array.from(this.document.querySelectorAll(
   "#view-courses .stack-screen.is-active"));
  if(inner.length!==1||inner[0]?.id!=="courses-practice-review")return null;
  const panel=this.document.getElementById("courses-practice-review");
  const list=this.document.getElementById("practice-review-list");
  if(!panel||!list||!row||typeof list.contains!=="function"||
     !list.contains(row))return null;
  if(!positive(panel.dataset?.practiceAiAttemptId)||
     !positive(row.dataset?.practiceAiQuestionId))return null;
  const subject=String(panel.dataset?.practiceAiSubjectKey||"");
  if(!this.subjects.includes(subject))return null;
  return Object.freeze({
   surface:"practice_review",subjectHint:subject,
   attemptReference:Number(panel.dataset.practiceAiAttemptId),
   questionId:Number(row.dataset.practiceAiQuestionId),
   row
  });
 }
 same(candidate,row){
  const newer=this.readReviewCandidate(row);
  return !!newer&&
   newer.attemptReference===candidate.attemptReference&&
   newer.questionId===candidate.questionId&&
   newer.subjectHint===candidate.subjectHint;
 }
 async leave(){
  ++this.epoch;
  this.active=null;
  try{await this.client.leave();}catch{}
  return{ok:true};
 }
 async chooseReviewQuestion(row){
  const candidate=this.readReviewCandidate(row);
  const epoch=this.epoch+1;
  await this.leave();
  if(this.epoch!==epoch)return fail("screen_changed");
  if(!candidate)return fail("verified_review_required");
  if(!this.same(candidate,row))return fail("screen_changed");
  // The browser supplies ONLY exact integer selectors, not scores, progress,
  // correct answers, user ID, topic, readiness or proof flags.
  let resolved;
  try{
   resolved=await this.resolver.resolvePracticeV4(Object.freeze({
    attemptReference:candidate.attemptReference,
    questionId:candidate.questionId
   }));
  }catch{return fail("server_context_unavailable");}
  if(epoch!==this.epoch||!this.same(candidate,row))return fail("screen_changed");
  if(resolved?.ok!==true||
     resolved?.kind!=="server_resolved_practice_v4"||
     resolved?.attemptReference!==candidate.attemptReference||
     resolved?.questionId!==candidate.questionId||
     !Number.isSafeInteger(resolved.sessionId)||resolved.sessionId<=0)
   return fail("server_verification_required");
  // Even the resolver return is merely a canonical selector. /context
  // revalidates the current owner, completed session, answer and assessment.
  let mint;
  try{mint=await this.client.openPractice(resolved.sessionId,candidate.questionId);}
  catch{return fail("server_context_unavailable");}
  if(epoch!==this.epoch||!this.same(candidate,row)){
   try{await this.client.leave();}catch{}
   return fail("screen_changed");
  }
  if(mint?.ok!==true)return fail(mint?.reason||"server_context_unavailable");
  let status;
  try{status=await this.client.status("ru");}
  catch{status=null;}
  if(epoch!==this.epoch||!this.same(candidate,row)){
   try{await this.client.leave();}catch{}
   return fail("screen_changed");
  }
  if(status?.ok!==true||status?.state!=="available"||status?.route!=="practice_result"){
   await this.leave();
   return fail("source_in_development");
  }
  this.active=Object.freeze({
   row,attemptReference:candidate.attemptReference,
   questionId:candidate.questionId,subjectHint:candidate.subjectHint,
   sessionId:resolved.sessionId,epoch:this.epoch
  });
  return Object.freeze({ok:true,state:"available"});
 }
 async explainSelectedError(locale){
  const a=this.active;
  if(!a||a.epoch!==this.epoch||!this.same(a,a.row)||
     !["ru","uz","en"].includes(locale))return fail("screen_not_verified");
  if(this.client.isCurrent && !this.client.isCurrent())return fail("context_expired");
  let result;
  try{result=await this.client.askPrepared("practice_error",locale);}
  catch{return fail("server_context_unavailable");}
  if(a.epoch!==this.epoch||!this.same(a,a.row))return fail("screen_changed");
  return result?.ok===true?result:fail(result?.reason||"source_in_development");
 }
 async authChanged(){
  this.suspended=true;
  return this.leave();
 }
 async authenticated(){
  this.suspended=false;
  return{ok:true};
 }
 async onNavigation(){
  return this.leave();
 }
 attach(){
  if(this.observer)return this;
  const root=this.document.getElementById("main");
  if(typeof MutationObserver!=="function"||!root)return this;
  this.observer=new MutationObserver(()=>{
   if(this.active&&!this.same(this.active,this.active.row)){
    void this.leave();
   }
  });
  this.observer.observe(root,{subtree:true,attributes:true,
   attributeFilter:["class","hidden","aria-hidden","data-practice-ai-attempt-id",
    "data-practice-ai-question-id","data-practice-ai-subject-key"]});
  return this;
 }
 async disconnect(){
  this.observer?.disconnect();
  this.observer=null;
  return this.leave();
 }
}
module.exports={QaV21RealAcademicScreenBridge};
