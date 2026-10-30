#!/usr/bin/env node
"use strict";
const fs=require("node:fs");
const path=require("node:path");
const assert=require("node:assert/strict");
const stage=fs.readFileSync(path.join(__dirname,"ops/20261030_math_second_pass_cir03_two_question_stage.sql"),"utf8");
const release=fs.readFileSync(path.join(__dirname,"ops/20261030_math_second_pass_cir03_two_question_release.sql"),"utf8");
const post=fs.readFileSync(path.join(__dirname,"fixtures/math-second-pass-cir03-postrelease.sql"),"utf8");
const round2=n=>Math.round((n+Number.EPSILON)*100)/100;
const cases=[
 {r:10,theta:0.8,expected:4.13,old:16,source:7154,newid:10100},
 {r:6,theta:2.2,expected:25.05,old:25.2,source:7140,newid:10099}
];
for(const c of cases){
 const sector=.5*c.r*c.r*c.theta;
 const centralTriangle=.5*c.r*c.r*Math.sin(c.theta);
 const segment=sector-centralTriangle;
 assert.equal(round2(segment),c.expected,
   "Independent central-triangle calculation for source "+c.source);
 assert.notEqual(round2(segment),c.old,"Legacy mathematically wrong answer must be rejected");
 assert.ok(stage.includes(String(c.source)));
 assert.ok(stage.includes(String(c.newid)) || stage.includes(String(c.expected)));
 assert.ok(release.includes(String(c.newid)));
 assert.ok(post.includes(String(c.newid)));
}
for(const required of [
 "BEGIN;","COMMIT;","pg_advisory_xact_lock(611031528041)",
 "MATH_SECOND_PASS_SOURCE_OR_EXPOSURE_DRIFT","MATH_SECOND_PASS_CLONE_FAILED",
 "P1CIR03-A01-QA20261030","P1CIR03-A03-QA20261030",
 "question_snapshot_md5","NOT EXISTS","qa_math_status"
])assert.ok(stage.includes(required), "Staging release guard missing "+required);
for(const required of [
 "BEGIN;","COMMIT;","CIR03_SECOND_PASS_RELEASE_GUARD_DRIFT",
 "CIR03_SECOND_PASS_MATHEMATICS_OR_KEY_MISMATCH",
 "CIR03_SECOND_PASS_SOURCE_SNAPSHOT_CHANGED",
 "CIR03_SECOND_PASS_PUBLISH_INCOMPLETE",
 "round((40-50*sin(0.8))::numeric,2)<>4.13",
 "round((39.6-18*sin(2.2))::numeric,2)<>25.05",
 "exam_prep_learning_review_starts_v1", "exam_prep_weekly_goal_snapshots",
 "status='retired'","lifecycle_state='retired'"
])assert.ok(release.includes(required),"Publication guard missing "+required);
for(const sql of [stage,release]){
 assert.doesNotMatch(sql,/\b(?:DELETE\s+FROM|DROP\s+TABLE|TRUNCATE|ALTER\s+TABLE)\b/i);
 assert.doesNotMatch(sql,/\b(?:UPDATE|DELETE\s+FROM)\s+(?:private\.exam_prep_(?:sessions|responses|session_items|skill_states|weekly_plans)|public\.questions)\b/i);
}
assert.match(stage,/INSERT\s+INTO\s+public\.questions/i);
assert.match(stage,/INSERT\s+INTO\s+private\.exam_prep_question_content_meta/i);
assert.match(stage,/INSERT\s+INTO\s+private\.exam_prep_assessment_items/i);
assert.doesNotMatch(post,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|ALTER|DROP)\s/i);
console.log("Math second-pass P1 circular segments: independent sine oracles and safe versioned release PASS");
