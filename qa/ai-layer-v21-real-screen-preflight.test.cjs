"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const fs=require("node:fs");
const {inspectActualAppPreviewAdmission}=require("./ai-layer-v21-real-screen-preflight.cjs");
test("Actual app and Preview release gate remain NO-GO until independently approved",()=>{
 const check=inspectActualAppPreviewAdmission();
 assert.equal(check.status,"NO_GO");
 assert.equal(check.existingQaBranchOnly,true);
 for(const code of ["legacy_global_ai_route_not_replaced",
  "lesson_id_not_safely_bound_to_v2_context",
  "legacy_practice_attempt_id_not_verified_as_v4_session_id",
  "isolated_qa_db_and_auth_not_verified",
  "preview_has_no_separate_owner_authorization"])
  assert.ok(check.blockers.includes(code),code);
});
test("Lesson browser selector is missing despite real internal lessonId",()=>{
 const o=inspectActualAppPreviewAdmission().observations;
 assert.equal(o.lessonInternal,true);assert.equal(o.lessonCardsDynamic,true);
 assert.equal(o.lessonScreen,true);assert.equal(o.hasV2LessonScreenBinding,false);
});
test("Legacy Practice attempt is not trusted V4 session selector",()=>{
 const o=inspectActualAppPreviewAdmission().observations;
 assert.equal(o.legacyAttempt,true);assert.equal(o.attemptAttribute,true);
 assert.equal(o.canonicalPractice,true);assert.equal(o.explicitV2PracticeBinding,false);
});
test("Original app shell remains on V1; isolated V2 is not imported",()=>{
 const o=inspectActualAppPreviewAdmission().observations;
 assert.equal(o.routeV1,true);assert.equal(o.indexImportsV2,false);
 assert.equal(o.v2Separate,true);
 for(const p of ["index.html","app.js","supabase/functions/global-ai/index.ts"])
  assert.doesNotMatch(fs.readFileSync(p,"utf8"),/ai-layer-v21-ui-transport/);
});
