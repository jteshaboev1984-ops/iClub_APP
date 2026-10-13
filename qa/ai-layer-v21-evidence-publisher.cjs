// §42 QA-only, read-only V4 finalize->review handoff candidate.
// NOT imported by app.js or index.html; never persisted to localStorage/DB.
"use strict";
(function(factory){
 const api=factory();
 if(typeof module==="object"&&module.exports)module.exports=api;
 if(typeof window==="object"&&window.__ICLUB_AI_V21_SYNTHETIC_ONLY__===true)
  window.iClubQaV21EvidencePublisher=api.QaV21EvidencePublisher;
})(function(){
 const int=n=>Number.isSafeInteger(n)&&n>0?n:null;
 const from=x=>typeof x==="number"?int(x):
  (typeof x==="string"&&/^[1-9][0-9]*$/.test(x)?int(Number(x)):null);
 const denied=reason=>({ok:false,reason});
 class QaV21EvidencePublisher{
  constructor(){this.epoch=0;this.session=null;this.screen=null;}
  clear(){
   ++this.epoch;
   if(this.screen){
    this.screen.removeAttribute("data-iclub-ai-v21-session-id");
    for(const item of this.screen.querySelectorAll(
     '[data-iclub-ai-v21-question-id]')){
      item.removeAttribute("data-iclub-ai-v21-question-id");
      item.removeAttribute("data-iclub-ai-v21-selected");
    }
   }
   this.session=null;this.screen=null;
   return{ok:true};
  }
  acceptFinalization({quiz,finalResult}={}){
   this.clear();
   // Use ONLY the real V4 session ID from quiz.safeSessionId; NOT the
   // attempt_id returned for old Practice UI and recommendations.
   if(!quiz||quiz.mode!=="practice"||quiz.drillType||
     quiz._safeFinalizeComplete!==true||!quiz.safeSessionId)
     return denied("finalization_unverified");
   const sessionId=from(quiz.safeSessionId);
   const attemptId=from(finalResult?.attempt_id);
   const questions=Array.isArray(quiz.questions)?quiz.questions:[];
   const ids=questions.map(q=>from(q?.id));
   if(!sessionId||!attemptId||!ids.length||ids.some(x=>!x)||
      new Set(ids).size!==ids.length)return denied("finalization_unverified");
   this.session={sessionId,attemptId,questions:new Set(ids)};
   return{ok:true,token:this.epoch};
  }
  mountReview({token,reviewRows,screen}={}){
   if(token!==this.epoch||!this.session)return denied("context_changed");
   if(!screen||!screen.classList?.contains("is-active"))
    return denied("screen_not_verified");
   if(!Array.isArray(reviewRows)||!reviewRows.length)
    return denied("review_not_verified");
   const rows=new Map();
   for(const item of reviewRows){
    const id=from(item?.question_id);
    if(!id||rows.has(id)||!this.session.questions.has(id))
     return denied("review_not_verified");
    rows.set(id,item);
   }
   const rendered=Array.from(screen.querySelectorAll("[data-practice-ai-question-id]"));
   const mapped=new Map();
   for(const element of rendered){
    const id=from(element.getAttribute("data-practice-ai-question-id"));
    if(!id||mapped.has(id)||!rows.has(id))return denied("review_dom_mismatch");
    mapped.set(id,element);
   }
   if(mapped.size!==rows.size)return denied("review_dom_mismatch");
   this.screen=screen;
   screen.setAttribute("data-iclub-ai-v21-session-id",String(this.session.sessionId));
   for(const [id,element] of mapped){
    element.setAttribute("data-iclub-ai-v21-question-id",String(id));
    element.removeAttribute("data-iclub-ai-v21-selected");
   }
   return{ok:true,questions:mapped.size};
  }
  selectQuestion({token,questionId}={}){
   if(token!==this.epoch||!this.session||!this.screen||
      !this.screen.classList?.contains("is-active"))
     return denied("context_changed");
   const id=from(questionId);
   const row=id?Array.from(this.screen.querySelectorAll(
    "[data-iclub-ai-v21-question-id]")).find(x=>
     x.getAttribute("data-iclub-ai-v21-question-id")===String(id)):null;
   if(!row)return denied("question_not_verified");
   for(const node of this.screen.querySelectorAll("[data-iclub-ai-v21-question-id]"))
    node.removeAttribute("data-iclub-ai-v21-selected");
   row.setAttribute("data-iclub-ai-v21-selected","true");
   return{ok:true};
  }
 }
 return{QaV21EvidencePublisher};
});
