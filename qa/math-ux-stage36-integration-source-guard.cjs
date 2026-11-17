#!/usr/bin/env node
"use strict";
/* Strict code-only gate for reviewed Math #450 + UX #531 combined Draft.
 * This is NOT the UX-only guard and does not relax it.
 * No DB, auth, learner requests, network, deploy or release writes.
 */
const fs=require("node:fs"),cp=require("node:child_process"),assert=require("node:assert/strict");
const MAIN="f945228fefe0ec3a013f34b7d0ab9ac6c40cc2e4";
const UX="5d87b866abb0bed45936f048eab3d0b97dc509de";
const ACADEMIC="85a619752695a5f3217543391ee0eea47beb1aa9";
const base=String(process.env.MATH_UX_BASE_SHA||"");
const head=String(process.env.MATH_UX_HEAD_SHA||"");
assert.equal(base,MAIN,"Integration base must be the exact published main release");
assert(/^[a-f0-9]{40}$/.test(head),"Expected full integration HEAD SHA");
const git=(...args)=>cp.execFileSync("git",args,{encoding:"utf8",maxBuffer:32*1024*1024}).trimEnd();
assert.equal(git("rev-parse","HEAD"),head,"Checkout must be exact PR source, not merge ref");
assert.equal(git("merge-base",MAIN,head),MAIN,"Published baseline must be ancestor");
const read=p=>fs.readFileSync(p,"utf8");
const expected=[
 ".github/scripts/p0_14_legacy_off_regression.js",
 ".github/workflows/p0-14-host-regression.yml",
 ".github/workflows/p2-03-past-paper-companion.yml",
 ".github/workflows/p2-08-progress-preservation.yml",
 ".github/workflows/p2-43-protected-integrity-regression.yml",
 ".github/workflows/written-understanding-checks-v1.yml",
 ".github/scripts/p0_19_live_timed_readiness_regression.js",
 ".github/scripts/p2_55_full_learner_journey_regression.js",
 ".github/scripts/visual_v3_home_study_regression.js",
 ".github/workflows/exam-prep-weekly-answer-recovery.yml",
 ".github/workflows/exam-prep-weekly-profile-recovery.yml",
 ".github/workflows/math-p1p5-s4-hybrid-psql-jwt.yml",
 ".github/workflows/math-ux-stage36-integration-source-gate.yml",
 ".github/workflows/ux531-previewless-release-firewall.yml",
 "docs/ui-redesign/28-ux531-math-history-plan-and-retention-20261117.md",
 "exam-prep/exam-prep-api.js",
 "exam-prep/exam-prep-live.js",
 "index.html",
 "qa/math-ux-stage36-integration-source-guard.cjs",
 "qa/ux531-academy-all-screens.cjs",
 "qa/ux531-academy-browser.cjs",
 "qa/ux531-academy-ui-parity.cjs",
 "qa/ux531-math-history-plan-source-guard.cjs",
 "qa/ux531-math-p1p5-plan-runtime.cjs",
 "qa/ux531-registered-navigation-e2e.cjs",
 "scripts/p1p5-s3-chromium-mobile-three-language.cjs",
 "scripts/p1p5-s4-positive-objective-stage-signed.cjs",
 "scripts/p1p5-s4-readiness-fail-closed-source.cjs",
 "scripts/p1p5-s4-stage-on-finalized-browser.cjs",
 "scripts/p1p5-s4-stage-on-finalized-e2e.cjs",
 "scripts/p1p5-s4-stage-on-finalized-evidence-fixture.sql",
 "scripts/p1p5-s4-stage-on-real-evidence-seed.cjs",
 "supabase/migrations/20261116164000_exam_prep_math_s4_stage6_operational_readout_v1.sql",
 "visual/iclub-academy-ux531-b02b03.css",
 "visual/iclub-academy-ux531-b04b08.css",
 "visual/iclub-academy-ux531-interactions.js"
];
assert.equal(git("hash-object",".github/scripts/p0_14_legacy_off_regression.js"),"8f844e38efa69fb8fb45819b779deb079cca1ef1","Reviewed CI fix file drift: .github/scripts/p0_14_legacy_off_regression.js");
assert.equal(git("hash-object",".github/workflows/p0-14-host-regression.yml"),"3e623fbd9c8d28ca6b2040a6cbc840f8e2b16927","Reviewed CI fix file drift: .github/workflows/p0-14-host-regression.yml");
assert.equal(git("hash-object",".github/workflows/p2-03-past-paper-companion.yml"),"b6f92bcae4dd9061d18452bce0876c2072319df6","Reviewed CI fix file drift: .github/workflows/p2-03-past-paper-companion.yml");
assert.equal(git("hash-object",".github/workflows/p2-08-progress-preservation.yml"),"95e6a3f61a31a28f2cc4d20df076d47fccdd0bc5","Reviewed CI fix file drift: .github/workflows/p2-08-progress-preservation.yml");
assert.equal(git("hash-object",".github/workflows/p2-43-protected-integrity-regression.yml"),"8a778c8aa821f99db58e520d3bb2844b86fa9af6","Reviewed CI fix file drift: .github/workflows/p2-43-protected-integrity-regression.yml");
assert.equal(git("hash-object",".github/workflows/written-understanding-checks-v1.yml"),"fae72b32cf7f0c4947a84e19956622ee333b11f1","Reviewed CI fix file drift: .github/workflows/written-understanding-checks-v1.yml");
const changes=git("diff","--name-only",MAIN,head).split("\n").filter(Boolean).sort();
assert.deepEqual(changes,expected.sort(),"Only pre-reviewed UX+Math+CI baseline repair union files allowed");
const live=read("exam-prep/exam-prep-live.js");
const css=read("visual/iclub-academy-ux531-b02b03.css");
const swatch=(p,what)=>assert(css.includes(p),what+" owner-accepted solid swatch missing");
swatch("background:#174aab;","Competitive #174AAB");
swatch("background:#3071e1;","Pinned Study #3071E1");
assert(css.includes("#home-study-list .home-pinned-tile *")&&
  css.includes("color:#fff!important;"),"Nested pinned Study text must remain white");
for(const token of [
 "function renderMyPlan(expand=",
 "async function openRecentResults(component)",
 "rows.slice(0,3)",
 "rows.slice(3+shown,3+shown+5)",
 "data-ep-history-paper-session",
 "async function reconcilePendingAnswer(pending)",
 "pending.idempotencyKey",
 "typeof hybrid.data?.enabled !== \"boolean\"",
 "function renderOperationalReadiness(component, status, calibration)",
 "hybridS4StageStatus(component)",
 "calibration?.stage6_operational_access===true",
 "calibration?.available===true",
 "Number(calibration.operational_stage)>=6"
]) assert(live.includes(token),"Required UX or academic fail-closed invariant missing: "+token);
assert(!live.includes("data-ep-history-delete"),"Academic history deletion NOT approved");
const fixedP014=read(".github/workflows/p0-14-host-regression.yml");
const fixedLegacyOff=read(".github/scripts/p0_14_legacy_off_regression.js");
assert(fixedP014.includes("ubuntu-24.04")&&fixedP014.includes("ux531-math-single-back-loader-v5")&&
  fixedP014.includes("ux531-mobile-polish-20261116-loader-v2"),"Repaired P0-14 must retain exact released tags");
assert(fixedP014.includes("const all=[...s.matchAll(/")&&fixedP014.includes("const array=[...s.matchAll(/")&&
  fixedLegacyOff.includes("Exam Prep must remain hidden with real OFF capability"),
  "No bypass of P0-14 direct DB check or legacy OFF gate");

assert.equal(git("hash-object","exam-prep/exam-prep-live.js"),
  "665a71e3624059fb5da89caac9ea772adc1d25b2",
  "Whole merged answer-ACK/Stage source no longer reviewed");
assert.equal(git("hash-object","exam-prep/exam-prep-api.js"),
  "ff59bd51a72dda2f194ff86c8aaaebd336e38f4e",
  "Whole reviewed profile owner RPC API changed");
assert.equal(git("hash-object","supabase/migrations/20261116164000_exam_prep_math_s4_stage6_operational_readout_v1.sql"),
  "f5c59aaa166d026455c76769dddcc4dd7e1e5fef",
  "Academic Stage6 access bridge may not drift");
const answer=read(".github/workflows/exam-prep-weekly-answer-recovery.yml");
const profile=read(".github/workflows/exam-prep-weekly-profile-recovery.yml");
assert(answer.includes("665a71e3624059fb5da89caac9ea772adc1d25b2"),
 "Exact whole-file answer ACK pin must match integrated source");
assert(profile.includes("ff59bd51a72dda2f194ff86c8aaaebd336e38f4e"),
 "Exact whole-file profile API pin must match approved source");
const migration=read("supabase/migrations/20261116164000_exam_prep_math_s4_stage6_operational_readout_v1.sql");
for(const t of ["exam_prep_require_core_access_v1","v_stage>=6",
 "private.exam_prep_stage5_hybrid_operational_v1",
 "verified_written_method_marks',null","paper_marks_awarded",
 "mentor_required_for_core',false","stage_gates_enabled"])
 assert(migration.includes(t),"Stage6 source-backed access/mark boundary missing: "+t);
assert(!/update\s+private\.exam_prep_hybrid_s4_config_v1/i.test(migration),
 "Migration must not activate Stage flag");
const finalFixture=read("scripts/p1p5-s4-stage-on-finalized-evidence-fixture.sql");
const seed=read("scripts/p1p5-s4-stage-on-real-evidence-seed.cjs");
const runner=read("scripts/p1p5-s4-stage-on-finalized-e2e.cjs");
const browser=read("scripts/p1p5-s4-stage-on-finalized-browser.cjs");
assert(finalFixture.includes("pg_temp.p269_complete_retests_all_skills_v1")&&
 finalFixture.includes("private.rebuild_exam_prep_state_v1(v_uid,null)"),
 "Stage-ON test must derive mastery from finalized Core events");
assert(!/(insert into|update)\s+private\.exam_prep_(?:stage_states|skill_states)/i.test(finalFixture),
 "No fabricated stage projection");
assert(seed.includes("fixture.replace(marker,()=>helpers)")&&
 seed.includes("P1P5_E2E_ISOLATED"),
 "Only vetted SQL dollar-safe import in disposable PG17 allowed");
assert(runner.includes("get_exam_prep_state_safe_v1")&&
 runner.includes("get_exam_prep_final_calibration_safe_v1")&&
 runner.includes("stage_gates_enabled=false"),
 "Signed owner state projection/readout plus isolated reset required");
assert(browser.includes('["ru",390],["uz",375],["en",1280]')&&
 browser.includes("SIMULATED_READ_FAILURE")&&
 browser.includes("Stage6")&&browser.includes("window.sb.rpc"),
 "RU/UZ/EN signed browser and fail-closed error contract missing");
assert(UX!==ACADEMIC&&head!==MAIN,"Integration identities must stay distinct");
console.log("Math #450 + UX #531 strict union SOURCE guard PASS");
console.log("published_base="+MAIN+" combined_HEAD="+head+" reviewed_files="+changes.length+
 " authored learner writes=0 deployment=0");
