#!/usr/bin/env node
"use strict";
const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");
const sql = fs.readFileSync(path.join(__dirname,"ops/20261030_p1_cir03_segment_math_repair_stage.sql"),"utf8");
function approx(a,b,eps=0.005){assert.ok(Math.abs(a-b)<eps, "Expected "+a+" approximately "+b);}
for(const [r,theta,sector,triangle,segment,annular] of [
  [8,1.1,35.2,28.52,6.68,21.45],
  [9,1.2,48.6,37.75,10.85,33.6]
]) {
  const actualSector=r*r*theta/2;
  const actualTriangle=r*r*Math.sin(theta)/2;
  const actualSegment=actualSector-actualTriangle;
  const actualAnnular=(r*r-25)*theta/2;
  approx(actualSector,sector);
  approx(actualTriangle,triangle);
  approx(actualSegment,segment);
  approx(actualAnnular,annular);
  assert.ok(Math.abs(actualSegment-(actualSector-(r===8?25.6:32)))>0.01,
    "Legacy triangle area must not pass as correct");
}
for(const required of [
  "BEGIN;", "COMMIT;", "P1_CIR03_SOURCE_DRIFT", "P1_CIR03_VERSION_EXISTS",
  "P1_CIR03_CLONE_INCOMPLETE", "P1_CIR03_MARKS_CHANGED", "P1_CIR03_LOCALE_MISMATCH",
  "P1_CIR03_LEARNER_SESSION_ADDED", "28.52", "6.68", "37.75", "10.85",
  "A=1/2 r² sin θ", "old_task", "new_task", "new_assessment", "review_state",
  "CROSS JOIN (VALUES('ru'::text),('uz'::text))"
])assert.ok(sql.includes(required), "Missing correction guard "+required);
assert.doesNotMatch(sql,/\b(?:DELETE\s+FROM|TRUNCATE|DROP\s+TABLE|ALTER\s+TABLE)\b/i);
assert.doesNotMatch(sql,/UPDATE\s+private\.exam_prep_(?:written_tasks|assessments|responses|sessions|skill_states|weekly_plans)\b/i);
assert.equal((sql.match(/WHEN loc\.criterion_id='segment' AND loc\.language=/g)||[]).length,4);
assert.equal((sql.match(/'draft','pending','pending','pending','pending'/g)||[]).length,1);
console.log("P1 circular segments: exact geometry, mark sums, RU/UZ and immutable drafts PASS");
