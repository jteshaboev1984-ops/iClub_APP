// P2/P5/P6: ONE app-wide, server-owned surface contract for iClub AI v2.1.
// QA ONLY, never imported by the live app, Edge or legacy Mathematics Tutor.
// All injected services are authenticated server mocks; browser DOM is NOT proof.
// ContentHandoffGate remains the single authority for governed source readiness.
"use strict";
const {ContentHandoffGate,localized}=require("./ai-layer-v21-content-handoff-gate.cjs");
const inventory=require("./ai-layer-v21-subject-readiness-inventory.snapshot.json");
const SUBJECTS=new Set(inventory.subjects.map(s=>s.subject));
const LANGUAGES=new Set(["ru","uz","en"]);
const APP_VIEWS=new Set(["home","courses","profile","ratings","notifications",
 "community","about","support","support-topic","certificates",
 "certificate-verify","archive"]);
const PROOFS=Object.freeze({
 general_help:"app_navigation",
 subject_overview:"governed_subject_overview",
 home_next:"signed_next_actions",
 profile_progress:"signed_progress_aggregate",
 lesson_topic:"approved_lesson_source",
 practice_answer:"finalized_practice_answer",
 tour_archive:"opened_tour_archive"
});
const fail=(lang,state="in_development")=>localized(lang,state);
const int=n=>Number.isSafeInteger(n)&&n>0;
const digest=s=>typeof s==="string"&&/^[a-f0-9]{64}$/i.test(s);
const same=(a,b)=>a&&b&&[
 "ownerId","contextRevision","surface","subject","feature","topic",
 "kind","proofId","proofRevision","proofHash","currentView",
 "lessonId","practiceSessionId","questionId","tourAttemptId",
 "archiveUnlockRevision","aggregateRevision","sourceVersion",
 "verified","finalized","answerVerified","archiveUnlocked",
 "lessonSpecific","isVideo"
].every(x=>a[x]===b[x]);
function routeFor(ctx,proof){
 if(!ctx||ctx.routeAuthority!=="unified_ai"||
    !ctx.surface||!ctx.subject||!ctx.feature||!ctx.topic||
    !proof||proof.ownerId!==ctx.ownerId||
    proof.contextRevision!==ctx.contextRevision||
    proof.surface!==ctx.surface||proof.subject!==ctx.subject||
    proof.feature!==ctx.feature||proof.topic!==ctx.topic||
    !proof.proofId||!int(proof.proofRevision)||!digest(proof.proofHash))
  return null;
 if(ctx.subject!=="general"&&!SUBJECTS.has(ctx.subject))return null;
 if(ctx.surface==="global"){
  if(!APP_VIEWS.has(proof.currentView)||ctx.currentView!==proof.currentView)
   return null;
  if(ctx.subject==="general"){
   return ctx.feature==="app_help"&&ctx.topic==="navigation"&&
    proof.kind===PROOFS.general_help&&proof.verified===true?
     "global_help":null;
  }
  return ctx.feature==="subject_overview"&&ctx.topic==="overview"&&
   proof.kind===PROOFS.subject_overview&&proof.verified===true&&
   proof.currentView==="courses"?"subject_overview":null;
 }
 if(ctx.surface==="home")
  return ctx.subject==="general"&&ctx.feature==="next_step"&&
   ctx.topic==="next_actions"&&proof.kind===PROOFS.home_next&&
   proof.verified===true&&int(proof.aggregateRevision)&&
   proof.currentView==="home"?"home_next":null;
 if(ctx.surface==="profile")
  return ctx.subject==="general"&&ctx.feature==="progress_explanation"&&
   ctx.topic==="progress"&&proof.kind===PROOFS.profile_progress&&
   proof.verified===true&&int(proof.aggregateRevision)&&
   proof.currentView==="profile"?"profile_progress":null;
 if(ctx.surface==="lesson")
  return ctx.subject!=="general"&&ctx.feature==="topic_explanation"&&
   proof.kind===PROOFS.lesson_topic&&proof.lessonSpecific===true&&
   proof.isVideo===false&&int(proof.lessonId)&&
   ctx.lessonId===proof.lessonId&&proof.currentView==="courses"?
    "lesson":null;
 if(ctx.surface==="practice")
  return ctx.subject!=="general"&&ctx.feature==="answer_explanation"&&
   proof.kind===PROOFS.practice_answer&&proof.finalized===true&&
   proof.answerVerified===true&&int(proof.practiceSessionId)&&
   int(proof.questionId)&&ctx.practiceSessionId===proof.practiceSessionId&&
   ctx.questionId===proof.questionId&&proof.currentView==="courses"?
    "practice_result":null;
 if(ctx.surface==="tour_archive")
  return ctx.subject!=="general"&&ctx.feature==="archive_explanation"&&
   proof.kind===PROOFS.tour_archive&&proof.finalized===true&&
   proof.archiveUnlocked===true&&int(proof.tourAttemptId)&&
   int(proof.archiveUnlockRevision)&&
   ctx.tourAttemptId===proof.tourAttemptId&&
   proof.currentView==="courses"?"tour_archive":null;
 // Existing Exam Prep Tutor, active quiz, subject-wide videos, unsupported
 // screens, and anything without a backend proof are deliberately NEVER minted.
 return null;
}
class QAAppWideFeatureAdmission {
 constructor(services){
  if(typeof services?.getScopedContext!=="function"||
    typeof services?.getVerifiedScreenEvidence!=="function"||
    typeof services?.isProtected!=="function"||
    typeof services?.getServerTimeMs!=="function")
   throw Error("missing read-only server evidence contract");
  this.services=services;
  this.gate=new ContentHandoffGate(services);
 }
 async check({principal,contextHandle,locale}={}){
  const lang=LANGUAGES.has(locale)?locale:"en",S=this.services;
  if(!LANGUAGES.has(locale))return fail(lang);
  if(principal?.authenticated!==true||typeof principal.userId!=="string"||
     typeof contextHandle!=="string"||contextHandle.length<8)
   return fail(lang,"unavailable");
  const uid=principal.userId;
  let before,evidence;
  try{
   if(await S.isProtected(uid)!==false)return fail(lang,"hidden");
   before=await S.getScopedContext(uid,contextHandle);
   evidence=await S.getVerifiedScreenEvidence(uid,contextHandle);
  }catch{return fail(lang,"unavailable");}
  if(!before||before.ownerId!==uid||before.active!==true||
     before.protectedAssessment===true||!before.contextRevision||
     !Number.isSafeInteger(before.expiresAtMs))return fail(lang,"unavailable");
  let time;
  try{time=await S.getServerTimeMs();}catch{return fail(lang,"unavailable");}
  if(!Number.isSafeInteger(time)||time>=before.expiresAtMs)
   return fail(lang,"unavailable");
  const route=routeFor(before,evidence);
  if(!route)return fail(lang);
  const available=await this.gate.check({principal,contextHandle,locale:lang});
  if(available.state!=="available")return available;
  // A long-running source check can finish AFTER navigation, archive lock,
  // account switch, assessment start, content retirement or profile update.
  let after,again,lastTime;
  try{
   if(await S.isProtected(uid)!==false)return fail(lang,"hidden");
   [after,again,lastTime]=await Promise.all([
    S.getScopedContext(uid,contextHandle),
    S.getVerifiedScreenEvidence(uid,contextHandle),
    S.getServerTimeMs()
   ]);
  }catch{return fail(lang,"unavailable");}
  if(!after||after.ownerId!==uid||after.active!==true||
    after.protectedAssessment===true||!Number.isSafeInteger(lastTime)||
    after.expiresAtMs<=lastTime||
    after.contextRevision!==before.contextRevision||
    after.expiresAtMs!==before.expiresAtMs||
    !["surface","subject","feature","topic","currentView","lessonId",
      "practiceSessionId","questionId","tourAttemptId"].every(k=>after[k]===before[k])||
    !same(evidence,again)||routeFor(after,again)!==route)
   return fail(lang,"unavailable");
  // The verdict is read-only. The REAL Edge must rerun source/ownership
  // proof, reserve atomic quota and validate delivery before any answer.
  return {...available,route,surface:before.surface,subject:before.subject,
   locale:lang,proofRevision:evidence.proofRevision};
 }
}
module.exports={QAAppWideFeatureAdmission,routeFor,APP_VIEWS,PROOFS,SUBJECTS};
