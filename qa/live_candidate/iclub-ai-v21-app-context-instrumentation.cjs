"use strict";
/** One-time, narrow current-MAIN instrumentation; never merge stale QA app.js. */
function instrumentAcademicContext(source){
 if(typeof source!=="string"||!source.includes("function renderVideo()")||
  !source.includes("function renderTourReview()")||
  !source.includes("function syncPracticeAiDomContext()"))
  throw Error("main_app_screen_contract_changed");
 const inserts=[
  {
   start:"function renderTourReview() {",
   before:'  const localPayload = state?.courses?.lastTourReviewPayload || null;',
   code:[
    '  // Only a selector; the server enforces Tour embargo and editorial release.',
    '  const academicTourReview=document.getElementById("courses-tour-review");',
    '  if(academicTourReview){',
    '    if(Number.isSafeInteger(attemptId)&&attemptId>0)',
    '      academicTourReview.dataset.iclubAiTourAttemptId=String(attemptId);',
    '    else delete academicTourReview.dataset.iclubAiTourAttemptId;',
    '  }',''
   ].join("\n")
  }
 ];
 let result=source;
 for(const x of inserts){
  const first=result.indexOf(x.start);
  const next=result.indexOf(x.before,first);
  if(first<0||next<first||next-first>1400)
   throw Error("screen_anchor_changed:"+x.start);
  const middle=result.slice(first,next);
  if(middle.includes("academicTourReview")){
   if(!middle.includes(x.code.trim()))throw Error("partial_screen_instrumentation");
   continue;
  }
  result=result.slice(0,next)+x.code+result.slice(next);
 }
 return result;
}
module.exports={instrumentAcademicContext};
