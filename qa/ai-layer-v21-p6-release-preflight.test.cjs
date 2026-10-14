"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {p6ReleasePreflight}=require("./ai-layer-v21-p6-release-preflight.cjs");
test("§56 review does not promote editor candidates into deployed Global AI",()=>{
 const q=p6ReleasePreflight();
 a.equal(q.status,"NO_GO");a.equal(q.reviewOnly,true);
 a.equal(q.candidateLanguages,3);a.equal(q.candidateDraftReplies,18);
 a.equal(q.navigation,"NOT_EDITORIALLY_PUBLISHED");
 a.equal(q.copySourceAudit,"18_DRAFT_REPLIES_VERIFIED_NOT_APPROVED");
 a.equal(q.currentAccessibleNameMismatches,9);
 a.equal(q.candidateAccessibleNameMismatches,0);
 a.equal(q.navigationLandmark,"UNTRANSLATED_REVIEW_REQUIRED");
 a.equal(q.chromeAssistiveTechSignoff,"NOT_GIVEN");
 a.equal(q.home,"NO_AUTHORITATIVE_CROSS_SUBJECT_PLANNER");
 a.equal(q.uiBinding,"NOT_APPROVED");
 a.equal(q.ownerCohortApproval,"NOT_GIVEN");
 a.equal(q.liveRpc,"NOT_INSTALLED_BY_QA");
 a.equal(q.payment,"NOT_ENABLED");
});
test("QA release report is immutable and has no production action",()=>{
 const q=p6ReleasePreflight();
 a.equal(Object.isFrozen(q),true);
 a.equal(q.productionChanged,false);
 for(const name of ["deploy","applyMigration","publish","createPreview","enableGlobalAi"])
  a.equal(Object.prototype.hasOwnProperty.call(q,name),false,name);
});
