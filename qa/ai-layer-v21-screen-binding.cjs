// §41 iClub AI V2 screen admission — QA-only, NOT loaded by index.html.
// Browser element attributes are SELECTORS, never proof of authorization.
// The Edge mint RPC MUST independently verify owner, finalized Practice,
// answered question, enrollment, protected exam, source and active release.
"use strict";
(function(factory){
 const api=factory();
 if(typeof module==="object"&&module.exports)module.exports=api;
 // Only the synthetic file:// harness enables this explicit export.
 if(typeof window==="object"&&window.__ICLUB_AI_V21_SYNTHETIC_ONLY__===true)
  window.iClubQaV21ScreenBinder=api.QaV21ScreenBinder;
})(function(){
 const fail=reason=>({ok:false,reason});
 const integer=x=>{
  if(typeof x!=="string"||! /^[1-9][0-9]*$/.test(x))return null;
  const n=Number(x);
  return Number.isSafeInteger(n)&&n>0?n:null;
 };
 class QaV21ScreenBinder{
  constructor({client,document}={}){
   if(!client||typeof client.leave!=="function"||
     typeof client.openLesson!=="function"||typeof client.openPractice!=="function"||
     typeof client.status!=="function"||typeof client.askPrepared!=="function")
     throw Error("qa_screen_client_not_configured");
   if(!document||typeof document.getElementById!=="function")
     throw Error("qa_document_not_configured");
   this.client=client;
   this.doc=document;
   this.epoch=0;
   this.screenKey="";
   this.ready=false;
   this.userId=null;
   this.observer=null;
  }
  read(){
   const el=id=>this.doc.getElementById(id);
   const courses=el("view-courses");
   if(!courses?.classList?.contains("is-active"))return null;
   const exam=el("exam-prep-host-root");
   if(exam&&!exam.hidden&&exam.getAttribute("aria-hidden")!=="true")return null;
   for(const id of ["courses-practice-quiz","courses-tour-quiz"]){
    if(el(id)?.classList?.contains("is-active"))return null;
   }
   const lesson=el("courses-video");
   const review=el("courses-practice-review");
   const onLesson=Boolean(lesson?.classList?.contains("is-active"));
   const onReview=Boolean(review?.classList?.contains("is-active"));
   if(onLesson===onReview)return null;
   if(onLesson){
    const lessonId=integer(lesson.getAttribute("data-iclub-ai-v21-lesson-id"));
    return lessonId?{kind:"lesson",lessonId,key:"lesson:"+lessonId}:null;
   }
   const sessionId=integer(review.getAttribute("data-iclub-ai-v21-session-id"));
   // No legacy data-practice-ai-attempt-id, title, score, localStorage or
   // generic result ID may substitute for a V4 finalized-session selector.
   const selected=review.querySelectorAll(
    '[data-iclub-ai-v21-question-id][data-iclub-ai-v21-selected="true"]');
   if(!sessionId||selected.length!==1)return null;
   const questionId=integer(selected[0].getAttribute("data-iclub-ai-v21-question-id"));
   return questionId?{kind:"practice",sessionId,questionId,
    key:"practice:"+sessionId+":"+questionId}:null;
  }
  async sync(){
   const next=this.read(),key=next?.key||"";
   if(key===this.screenKey)return this.ready?{ok:true}:fail("screen_not_verified");
   const seq=++this.epoch;
   this.screenKey=key;
   this.ready=false;
   // Cancel local authority BEFORE awaiting remote revocation. The server
   // keeps its independent 90s expiry/revalidation on lost revoke ACK.
   await this.client.leave();
   if(seq!==this.epoch)return fail("context_changed");
   if(!next)return fail("screen_not_verified");
   let result;
   try{
    result=next.kind==="lesson"?
     await this.client.openLesson(next.lessonId):
     await this.client.openPractice(next.sessionId,next.questionId);
   }catch{result=fail("unavailable");}
   if(seq!==this.epoch)return fail("context_changed");
   if(!result||result.ok!==true)return fail(result?.reason||"context_unavailable");
   if(this.read()?.key!==key){
    // Screen DOM changed during mint without observer: do not trust the handle.
    ++this.epoch;this.screenKey="";await this.client.leave();
    return fail("context_changed");
   }
   this.ready=true;
   return{ok:true};
  }
  async status(locale){
   const key=this.screenKey,seq=this.epoch;
   if(!this.ready||!key||this.read()?.key!==key)return fail("screen_not_verified");
   const out=await this.client.status(locale);
   return seq===this.epoch&&this.read()?.key===key?out:fail("context_changed");
  }
  async askPrepared(promptKey,locale){
   const key=this.screenKey,seq=this.epoch;
   if(!this.ready||!key||this.read()?.key!==key)return fail("screen_not_verified");
   const out=await this.client.askPrepared(promptKey,locale);
   return seq===this.epoch&&this.read()?.key===key?out:fail("context_changed");
  }
  async leave(){
   ++this.epoch;this.screenKey="";this.ready=false;
   return this.client.leave();
  }
  async authChanged(event,session){
   const id=typeof session?.user?.id==="string"?session.user.id:null;
   const logout=event==="SIGNED_OUT"||event==="USER_DELETED"||
    (event==="INITIAL_SESSION"&&!id);
   if(logout||(id&&this.userId&&this.userId!==id)){
    this.userId=logout?null:id;
    return this.leave();
   }
   if(id)this.userId=id;
   return{ok:true};
  }
  attach(){
   if(this.observer)return this;
   if(typeof MutationObserver!=="function")return this;
   const root=this.doc.getElementById("view-courses");
   if(!root)return this;
   this.observer=new MutationObserver(()=>{void this.sync();});
   this.observer.observe(root,{subtree:true,attributes:true,
    attributeFilter:["class","hidden","aria-hidden",
     "data-iclub-ai-v21-lesson-id","data-iclub-ai-v21-session-id",
     "data-iclub-ai-v21-question-id","data-iclub-ai-v21-selected"]});
   void this.sync();
   return this;
  }
  async disconnect(){
   this.observer?.disconnect();
   this.observer=null;
   return this.leave();
  }
 }
 return{QaV21ScreenBinder};
});
