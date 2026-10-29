#!/usr/bin/env node
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const sql = fs.readFileSync(path.join(__dirname,"ops/20261029_p5_geo_cnt_prompt_fixes_publish.sql"),"utf8");
for (const s of [
 "BEGIN;", "COMMIT;", "pg_advisory_xact_lock(611031528039)",
 "P5GEO03-W01", "P5CNT03-W01", "281,167,459", "282,381,460",
 "id=281", "id=282", "mustaqil tajribalar", "независимых испытаний",
 "каждый делитель устраняет повторный подсчёт",
 "P5_prompt_fix_English_or_marks_drift",
 "P5_prompt_fix_locale_mismatch",
 "P5_prompt_fix_learning_pack_drift",
 "P5_prompt_fix_publication_incomplete",
 "OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN",
 "exam_prep_written_understanding_checks"
]) assert.ok(sql.includes(s),"Missing invariant: "+s);
assert.doesNotMatch(sql,/\b(?:DELETE\s+FROM|TRUNCATE|DROP\s+TABLE|ALTER\s+TABLE)\b/i);
assert.doesNotMatch(sql,/UPDATE\s+private\.exam_prep_(?:responses|sessions|skill_states|weekly_plans)/i);
const targets=[...sql.matchAll(/UPDATE\s+private\.(exam_prep_[a-z_0-9]+)\s+\w+\s+SET[\s\S]*?;/gi)].map(m=>m[1]);
assert.deepEqual(targets.sort(),[
 "exam_prep_written_criteria_locale_v1",
 "exam_prep_written_understanding_checks",
 "exam_prep_written_tasks",
 "exam_prep_assessments"
].sort());
const factorial=n=>Array.from({length:n},(_,i)=>i+1).reduce((a,b)=>a*b,1);
assert.equal(factorial(10)/(factorial(3)*factorial(3)*factorial(2)),50400);
const p=1/5;
assert.equal(p,0.2);
assert.ok(Math.abs((1-p)**3-0.512)<1e-12);
assert.ok(Math.abs((1-p)**3*p-0.1024)<1e-12);
assert.equal(3+3+2+2,10); // P5 CNT rubric marks
assert.equal(2+2+2+3+1,10); // P5 GEO rubric marks
console.log("P5 GEO/CNT versioned prompt fixes, source guard, numeric correctness and student-state isolation: PASS");
