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
 "question_snapshot_md5","OR EXISTS","qa_math_status"
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

const all15=fs.readFileSync(path.join(__dirname,"fixtures/math-second-pass-p1-cir03-15-readonly.sql"),"utf8");
const pi=Math.PI;
const allOracles=[
 ["P1CIR03-A01-QA20261030",()=>.5*100*(.8-Math.sin(.8)),"4.13 cm²",4.13,.005],
 ["P1CIR03-A02",()=>36/(.5*(64-16)),"1.5",1.5,1e-10],
 ["P1CIR03-A03-QA20261030",()=>.5*36*(2.2-Math.sin(2.2)),"25.05",25.05,.005],
 ["P1CIR03-D01",()=>.5*36*pi/3,"6π",6*pi,1e-10],
 ["P1CIR03-D02",()=>.5*100*(1.1-.4),"35 cm²",35,1e-10],
 ["P1CIR03-D03",()=>.5*36*(pi/3-Math.sin(pi/3)),"6π−9√3 cm²",6*pi-9*Math.sqrt(3),1e-10],
 ["P1CIR03-L01",()=>.5*25*1.2,"15",15,1e-10],
 ["P1CIR03-L02",()=>24/(.5*16),"3",3,1e-10],
 ["P1CIR03-L03",()=>.5*16*(pi/2-Math.sin(pi/2)),"4π−8",4*pi-8,1e-10],
 ["P1CIR03-M01",()=>.5*(36-9)*pi/3,"9π/2",9*pi/2,1e-10],
 ["P1CIR03-M02",()=>((.5+.25)*pi*16)/pi,"12",12,1e-10],
 ["P1CIR03-R01",()=>.5*9*2,"9",9,1e-10],
 ["P1CIR03-R02",()=>Math.sqrt(2*10/.8),"5",5,1e-10],
 ["P1CIR03-R03",()=>.5*(100-36)*.5,"16",16,1e-10],
 ["P1CIR03-R04",()=>27/(.5*36),"1.5",1.5,1e-10]
];
assert.equal(allOracles.length,15);
for(const [key,fn,selected,expected,tolerance] of allOracles){
 assert.ok(all15.includes("('"+key+"','"+selected+"')"),"P1-CIR-03 source/key fixture missing "+key);
 assert.ok(Math.abs(fn()-expected)<=tolerance,"Independent P1-CIR-03 formula mismatch "+key);
}
assert.doesNotMatch(all15,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|ALTER|DROP)\s+(?:private\.|public\.)/i);
console.log("Math second-pass P1 circular segments: independent sine oracles and safe versioned release PASS");
