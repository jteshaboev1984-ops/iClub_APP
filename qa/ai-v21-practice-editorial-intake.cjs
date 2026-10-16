"use strict";
// QA-only editorial *candidate* for one original iClub Practice error.
// Never publishes, calls Supabase, assigns real learner scores or grants AI.
const {createHash}=require("node:crypto");
const UUID=/^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[0-9a-f]{12}$/i;
const CODE=/^[a-z][a-z0-9_]{1,79}$/;
const SHA=/^[a-f0-9]{64}$/;
const LOCALES=Object.freeze(["ru","uz","en"]);
const SUBJECTS=new Set(["mathematics","biology","chemistry","economics","informatics"]);
const FIELDS=["protocol","status","surface","feature","promptKey","subject",
 "questionId","sourceId","sourceVersion","sourceHash","sourceOwner",
 "rightsEvidenceId","provenanceId","sourceKind","prepared",
 "review","releaseAllowed"];
const REVIEW_FIELDS=["authorVerified","rightsVerified","sourceVersionVerified",
 "academicReviewed","negativeTestsPassed","examSecurityPassed",
 "localeReviewed","accessibilityReviewed","editorialPublished"];
const deny=(reason)=>Object.freeze({ok:false,reason,ready:false,releaseAllowed:false});
const exact=(obj,fields)=>obj&&typeof obj==="object"&&!Array.isArray(obj)&&
 Object.keys(obj).length===fields.length&&fields.every(x=>Object.hasOwn(obj,x));
const id=n=>Number.isSafeInteger(n)&&n>0;
const isText=x=>typeof x==="string"&&x.length>=20&&x.length<=3000&&
 !/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(x)&&
 !/<\s*(script|iframe|img|video|svg|style)\b|javascript\s*:/i.test(x);
const digest=text=>createHash("sha256").update(text,"utf8").digest("hex");
function canonicalPracticeRef(evidence){
 // Only a separately authenticated server evidence reader may invoke this.
 // This helper does not validate a token or confer permission.
 if(!evidence||evidence.origin!=="trusted_server"||
    evidence.kind!=="finalized_practice_question_v4"||
    evidence.owned!==true||evidence.finalized!==true||
    evidence.serverChecked!==true||evidence.protectedAssessment!==false||
    !SUBJECTS.has(evidence.subject)||!id(evidence.questionId)||
    evidence.topic!==("question_"+evidence.questionId))
   return deny("trusted_question_proof_required");
 return Object.freeze({ok:true,surface:"practice",
  feature:"answer_explanation",topic:"question_"+evidence.questionId,
  subject:evidence.subject,questionId:evidence.questionId});
}
function inspectDraft(draft,serverEvidence){
 const canonical=canonicalPracticeRef(serverEvidence);
 if(canonical.ok!==true)return canonical;
 if(!exact(draft,FIELDS)||draft.protocol!=="iclub-ai-practice-editorial-v1"||
    draft.status!=="DRAFT_NOT_APPROVED"||
    draft.releaseAllowed!==false||
    draft.surface!=="practice"||draft.feature!=="answer_explanation"||
    draft.promptKey!=="practice_error"||
    draft.questionId!==canonical.questionId||draft.subject!==canonical.subject||
    !CODE.test(draft.sourceId)||!CODE.test(draft.sourceVersion)||
    !SHA.test(draft.sourceHash)||
    draft.sourceKind!=="iclub_original"||
    !UUID.test(draft.sourceOwner)||!CODE.test(draft.provenanceId)||
    !CODE.test(draft.rightsEvidenceId)||
    !exact(draft.review,REVIEW_FIELDS)||
    REVIEW_FIELDS.some(field=>draft.review[field]!==false))
   return deny("draft_not_governed");
 if(!exact(draft.prepared,LOCALES))return deny("locale_set_incomplete");
 const checksums=[];
 for(const locale of LOCALES){
  const value=draft.prepared[locale];
  if(!exact(value,["text","sha256","sourceHash","sourceVersion","reviewed"])||
     !isText(value.text)||!SHA.test(value.sha256)||
     value.sha256!==digest(value.text)||value.sourceHash!==draft.sourceHash||
     value.sourceVersion!==draft.sourceVersion||value.reviewed!==false)
   return deny("locale_content_not_reviewed");
  checksums.push(value.sha256);
 }
 if(new Set(checksums).size!==3)return deny("locale_not_independent");
 // Candidate is never a readiness/publishing signal. That requires
 // a separately authenticated signed editorial workflow + live SQL gates.
 return Object.freeze({ok:true,ready:false,releaseAllowed:false,
  next:"independent_academic_rights_locale_review",
  canonical:{surface:canonical.surface,feature:canonical.feature,
   topic:canonical.topic,subject:canonical.subject},
  sourceVersion:draft.sourceVersion,sourceHash:draft.sourceHash,
  contentDigests:Object.freeze(Object.fromEntries(LOCALES.map(locale=>
   [locale,draft.prepared[locale].sha256])))});
}
function buildSyntheticDraft({subject="biology",questionId=202}={}){
 // TEST-ONLY: fabricated content, never use with a learner.
 const h="a".repeat(64);
 const values={
  ru:"СИНТЕТИЧЕСКИЙ QA: пример ответа для проверки допуска, не учебный разбор.",
  uz:"SUN’IY QA: ruxsat tekshiruvi uchun javob, haqiqiy dars yoki yechim emas.",
  en:"SYNTHETIC QA ONLY: access test response; not a real lesson or solution."
 };
 return {
  protocol:"iclub-ai-practice-editorial-v1",status:"DRAFT_NOT_APPROVED",
  surface:"practice",feature:"answer_explanation",promptKey:"practice_error",
  subject,questionId,sourceId:"qa_only_original_source",
  sourceVersion:"qa_v1",sourceHash:h,
  sourceOwner:"11111111-1111-4111-8111-111111111111",
  rightsEvidenceId:"qa_synthetic_rights_only",provenanceId:"qa_synthetic_provenance_only",
  sourceKind:"iclub_original",
  prepared:Object.fromEntries(LOCALES.map(locale=>[locale,{
   text:values[locale],sha256:digest(values[locale]),
   sourceHash:h,sourceVersion:"qa_v1",reviewed:false}])),
  review:Object.fromEntries(REVIEW_FIELDS.map(x=>[x,false])),
  releaseAllowed:false
 };
}
module.exports={canonicalPracticeRef,inspectDraft,buildSyntheticDraft,LOCALES,REVIEW_FIELDS};
