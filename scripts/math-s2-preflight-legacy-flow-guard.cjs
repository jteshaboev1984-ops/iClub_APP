#!/usr/bin/env node
"use strict";
// Source-only regression: mirrors the production old-client order; not an E2E claim.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const app = fs.readFileSync("app.js","utf8");
const sql = fs.readFileSync("supabase/candidates/math_s2_preflight_redacted_legacy_compatible_v1_hold.sql","utf8");
const start = app.indexOf("const questions = await loadTourQuestionsDB(tour.id);");
assert(start>=0,"client no longer calls preflight loader");
const preload = app.indexOf("await preloadTourQuestionImages(questions)",start);
const guard = app.indexOf("if (!imagePreloadResult?.ok)",start);
const beginAttempt = app.indexOf("tourApi.start({",start);
const issued = app.indexOf("tourApi.questions(Number(startResult?.attempt_id))",start);
assert(start<preload && preload<guard && guard<beginAttempt && beginAttempt<issued,
 "old-client image readiness / attempt / issued-questions order changed");
assert(app.slice(guard,beginAttempt).includes("return;"),"image failure may consume attempt");
assert(sql.includes("91fc6b12dcb059426668bdff040223b1"),"un-pinned server patch");
assert(sql.includes("v_redact := v_tour.subject_id=5"),"not subject-scoped");
assert(sql.includes("s.season_no=2"),"not season-scoped");
assert(!sql.includes("math_s2_questions_require_started_attempt"),"breaks cached clients");
for(const field of ["question_text","question_text_en","question_text_ru","question_text_uz",
 "options_text","options_text_en","options_text_ru","options_text_uz",
 "time_limit_sec","topic","subtopic","difficulty","book_ref"]) {
 assert(sql.includes("CASE WHEN v_redact THEN NULL ELSE q."+field+" END"),
  "unredacted S2 preflight field "+field);
}
assert(sql.includes("q.image_url"),"old-client image readiness cannot run");
assert(sql.includes("q.id"),"old client needs 20 positive question IDs");
console.log("S2 prestart source compatibility guard PASS (static, no hosted I/O)");
