// QA-only real Practice lifecycle glue. Not imported by original index.
"use strict";
(function(make){
 const x=make();
 if(typeof module==="object"&&module.exports)module.exports=x;
 if(typeof window==="object"&&window.__ICLUB_AI_V21_SYNTHETIC_ONLY__===true
  &&typeof window.iClubQaV21EvidencePublisher==="function")
  window.__iclubQaV21Bridge=new x.PreviewGlue(new window.iClubQaV21EvidencePublisher());
})(function(){
 const id=x=>Number.isSafeInteger(Number(x))&&Number(x)>0?Number(x):0;
 const keys=rows=>Array.isArray(rows)?
  rows.map(r=>id(r?.question_id)).sort((a,b)=>a-b):[];
 class PreviewGlue{
  constructor(publisher){
   if(!publisher||typeof publisher.mountReview!=="function")
    throw Error("qa_publisher_required");
   this.pub=publisher;this.proof=null;
  }
  clear(){this.proof=null;this.pub.clear();return{ok:true};}
  screenChanged(name){
   if(name!=="practice-result"&&name!=="practice-review")return this.clear();
   return{ok:true};
  }
  finalized({quiz,finalResult,reviewRows}={}){
   this.clear();
   if(!Array.isArray(reviewRows)||!reviewRows.length)
    return{ok:false,reason:"review_unverified"};
   const proof=this.pub.acceptFinalization({quiz,finalResult});
   if(proof?.ok!==true)return{ok:false,reason:"finalization_unverified"};
   const expected=(quiz.questions||[]).map(q=>id(q?.id)).sort((a,b)=>a-b);
   const received=keys(reviewRows);
   if(!received.length||received.length!==expected.length||
     received.some((x,i)=>!x||x!==expected[i])){
    this.clear();return{ok:false,reason:"review_mismatch"};
   }
   this.proof={token:proof.token,attemptId:id(finalResult.attempt_id),received};
   return{ok:true};
  }
  reviewRendered({attemptId,reviewRows,screen}={}){
   const p=this.proof;
   if(!p||id(attemptId)!==p.attemptId)
    return{ok:false,reason:"context_changed"};
   const got=keys(reviewRows);
   if(got.length!==p.received.length||got.some((x,i)=>x!==p.received[i]))
    return{ok:false,reason:"review_changed"};
   return this.pub.mountReview({token:p.token,reviewRows,screen});
  }
  selectQuestion(questionId){
   return this.proof?this.pub.selectQuestion({
    token:this.proof.token,questionId
   }):{ok:false,reason:"context_changed"};
  }
 }
 return{PreviewGlue};
});
