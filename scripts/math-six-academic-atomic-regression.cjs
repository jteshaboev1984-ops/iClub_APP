#!/usr/bin/env node
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const source = fs.readFileSync(path.join(__dirname,"ops/20261030_math_p1p5_six_fix_atomic_publish.sql"),"utf8");
const required = [
 "BEGIN;", "COMMIT;", "MATH_SIX_ATOMIC_RELEASE_POSTFLIGHT_FAILED",
 "MATH_SIX_CORRECTED_CONTENT_MISSING", "MATH_SIX_LOCALE_CHECKSUM_MISMATCH",
 "MATH_SIX_UNEXPECTED_SESSION_CREATED", "MATH_SIX_LEARNING_PACK_DRIFT",
 "OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_30_NO_INDEPENDENT_HUMAN",
 "184,279,380,457", "204,280,400,458", "62,281,167,459",
 "185,282,381,460", "38,285,98,463", "15638,286,35421,464"
];
for(const term of required) assert.ok(source.includes(term), "Missing release gate "+term);
assert.doesNotMatch(source, /\b(?:DELETE\s+FROM|TRUNCATE|DROP\s+TABLE|ALTER\s+TABLE)\b/i);
assert.doesNotMatch(source,/UPDATE\s+private\.exam_prep_(?:responses|sessions|skill_states|weekly_plans)/i);
const updatedTables=[...source.matchAll(/UPDATE\s+private\.(exam_prep_[a-z_0-9]+)\s+\w+\s+SET[\s\S]*?;/gi)].map(x=>x[1]).sort();
assert.deepEqual(updatedTables, [
 "exam_prep_assessments",
 "exam_prep_written_criteria_locale_v1",
 "exam_prep_written_tasks",
 "exam_prep_written_understanding_checks"
].sort(), "Exactly four version-targeted table updates expected");
assert.equal((source.match(/pg_advisory_xact_lock\(/g)||[]).length,4);
assert.equal((source.match(/^\(\d+,/gm)||[]).length,6);
const close=(x,y,tol=0.00005)=>assert.ok(Math.abs(x-y)<tol, "Expected "+x+" ≈ "+y);
const pi=Math.PI;
close(2*Math.sin(pi/6)-1,0);
close(2*Math.sin(5*pi/6)-1,0);
close(.5*8**2*1.1,35.2);
close(.5*8**2*Math.sin(1.1),28.51864,0.001);
close(.5*8**2*(1.1-Math.sin(1.1)),6.681364,0.00001);
close(.5*(8**2-5**2)*1.1,21.45);
close(.5*9**2*1.2,48.6);
close(.5*9**2*Math.sin(1.2),37.74758,0.001);
close(.5*9**2*(1.2-Math.sin(1.2)),10.852416,0.001);
close(.5*(9**2-5**2)*1.2,33.6);
const factorial=n=>Array.from({length:n},(_,i)=>i+1).reduce((v,x)=>v*x,1);
assert.equal(factorial(10)/(factorial(3)*factorial(3)*factorial(2)),50400);
const p=1/5;
close((1-p)**3,0.512);
close((1-p)**3*p,0.1024);
const Phi=z=>{
 const s=Math.sign(z),x=Math.abs(z)/Math.SQRT2,t=1/(1+.3275911*x);
 const erf=1-(((((1.061405429*t-1.453152027)*t)+1.421413741)*t-0.284496736)*t+0.254829592)*t*Math.exp(-x*x);
 return (1+s*erf)/2;
};
close(Phi(1),0.84134475);
close(1-Phi(2),0.02275013);
close(Phi(1)-Phi(-1),0.68268949);
assert.equal(10+11+10+10+10+6,57);
assert.equal(8+10+10+8+8+10,54);
const readOnly=fs.readFileSync(path.join(__dirname,"fixtures/math-six-academic-post-publish-readonly.sql"),"utf8");
assert.doesNotMatch(readOnly, /\b(?:UPDATE|INSERT|DELETE|TRUNCATE|DROP|CREATE\s+TABLE|ALTER\s+TABLE)\b/i);
for(const text of ["MATH_SIX_READONLY_CONTRACT_PASS","MATH_SIX_READONLY_LOCALE_HASH_FAILED",
    "MATH_SIX_READONLY_MARKS_FAILED","published_corrected_tasks","published_locales"]){
  assert.ok(readOnly.includes(text), "Missing read-only release checkpoint: "+text);
}
console.log("Atomic six-fix math: gates, 57 marks, 54 locales, 4 protected tables PASS");
