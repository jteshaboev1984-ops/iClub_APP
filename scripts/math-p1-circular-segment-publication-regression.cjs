#!/usr/bin/env node
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const sql = fs.readFileSync(path.join(__dirname,"ops/20261030_p1_cir03_segment_math_repair_publish.sql"),"utf8");
for(const x of [
  "BEGIN;", "COMMIT;", "pg_advisory_xact_lock(611031528040)",
  "38,285,98,463,10,8,0", "15638,286,35421,464,6,10,1",
  "P1_CIR03_publication_preflight", "P1_CIR03_locale_checksum",
  "P1_CIR03_math_content_or_version_drift", "P1_CIR03_assessment_drift",
  "P1_CIR03_publication_failed", "P1_CIR03_mark_total",
  "OWNER_REQUESTED_AI_ASSISTED_ACADEMIC_REPAIR_2026_10_30_NOT_HUMAN",
  "review_state='approved'", "new_task", "new_assessment"
])assert.ok(sql.includes(x), "Missing guarded publication constraint: "+x);
assert.doesNotMatch(sql, /\b(?:DELETE\s+FROM|TRUNCATE|DROP\s+TABLE|ALTER\s+TABLE)\b/i);
assert.doesNotMatch(sql, /UPDATE\s+private\.exam_prep_(?:responses|sessions|skill_states|weekly_plans)\b/i);
const mutations=[...sql.matchAll(/UPDATE\s+private\.(exam_prep_[a-z_0-9]+)\s+\w+\s+SET[\s\S]*?;/gi)].map(x=>x[1]);
assert.deepEqual(mutations.sort(),[
  "exam_prep_written_criteria_locale_v1",
  "exam_prep_written_understanding_checks",
  "exam_prep_written_tasks",
  "exam_prep_assessments"
].sort());
for(const [radius,theta,value] of [[8,1.1,6.68],[9,1.2,10.85]]){
 const segment=radius*radius*(theta-Math.sin(theta))/2;
 assert.ok(Math.abs(segment-value)<0.005);
}
console.log("P1 circular-segment guarded publication: math, locales, learners unchanged PASS");
