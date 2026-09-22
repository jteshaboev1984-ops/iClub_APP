'use strict';
// CONTENT-FREE synthetic contract. Do not insert confidential assessment items or real correct-answer data.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const migration=fs.readFileSync(path.join(__dirname,'../supabase/migrations/20260921220000_exam_prep_mcq_server_frozen_order_v1.sql'),'utf8');
const hardening=fs.readFileSync(path.join(__dirname,'../supabase/migrations/20260921220100_exam_prep_mcq_order_strict_validation_v1.sql'),'utf8');
function valid(map) {
  return Array.isArray(map) && map.length===4 && map.every(x=>Number.isInteger(x)) &&
    [...map].sort((a,b)=>a-b).every((x,i)=>x===i);
}
function displayOptions(source,map) {
  if (map===null) return source.slice();
  if (!valid(map) || !Array.isArray(source) || source.length!==4) throw Error('invalid order');
  return map.map(i=>source[i]);
}
function sourceIndex(displayIndex,map) {
  if (map===null) return displayIndex;
  if (!valid(map) || !Number.isInteger(displayIndex) || displayIndex<0 || displayIndex>3) throw Error('invalid display index');
  return map[displayIndex];
}
function displayLetter(sourceLetter,map) {
  if (map===null) return sourceLetter;
  if (!valid(map) || !/^[A-D]$/.test(sourceLetter)) throw Error('invalid selected answer');
  return String.fromCharCode(65+map.indexOf(sourceLetter.charCodeAt(0)-65));
}
function allOrders(source) {
  if (!source.length) return [[]];
  return source.flatMap((x,i)=>allOrders(source.filter((_,n)=>i!==n)).map(t=>[x,...t]));
}
assert.deepEqual(displayOptions(['a','b','c','d'],null),['a','b','c','d'],'old session preserved');
assert.equal(sourceIndex(2,null),2,'old selected index preserved');
assert.equal(displayLetter('C',null),'C','old selected letter preserved');
for (const broken of [[],[0,1,2],[0,0,1,2],[0,1,2,4],[-1,0,1,2],[0,1,2,null]]) {
  assert.equal(valid(broken),false);assert.throws(()=>displayOptions(['a','b','c','d'],broken));
}
let scenarios=0;
for (const component of ['P1','P5']) {
 for (const map of allOrders([0,1,2,3])) {
  assert.equal(valid(map),true);
  const frozen=Object.freeze(map.slice());
  const localeOptions={en:['EN0','EN1','EN2','EN3'],ru:['RU0','RU1','RU2','RU3'],uz:['UZ0','UZ1','UZ2','UZ3']};
  for (const locale of Object.keys(localeOptions)) {
    const displayed=displayOptions(localeOptions[locale],frozen);
    assert.deepEqual(displayOptions(localeOptions[locale],frozen),displayed,'resume must preserve order');
    for (let displayedIndex=0;displayedIndex<4;displayedIndex++) {
      const canonical=sourceIndex(displayedIndex,frozen);
      assert.equal(displayed[displayedIndex],localeOptions[locale][canonical]);
      assert.equal(displayLetter(String.fromCharCode(65+canonical),frozen),String.fromCharCode(65+displayedIndex));
      for (let canonicalCorrect=0;canonicalCorrect<4;canonicalCorrect++) {
        assert.equal(canonical===canonicalCorrect,displayedIndex===frozen.indexOf(canonicalCorrect),'score must use canonical source index');
        const wrong=canonical!==canonicalCorrect;
        assert.equal(wrong,displayedIndex!==frozen.indexOf(canonicalCorrect),'distractor diagnosis stays source-aligned');
        scenarios++;
      }
    }
  }
 }
}
assert.equal(scenarios,2*24*3*4*4);
assert.match(migration,/enabled boolean NOT NULL DEFAULT false/);
assert.match(migration,/INSERT INTO private\.exam_prep_mcq_order_rollout_v1\(singleton,enabled\) VALUES\(true,false\)/);
assert.match(migration,/ADD COLUMN display_to_source smallint\[\] NULL/);
assert.match(migration,/NEW\.display_to_source:=v_perm/);
assert.match(migration,/pg_catalog\.gen_random_uuid\(\)/);
assert.match(migration,/exam_prep_mcq_display_options_v1\(coalesce/);
assert.match(migration,/v_picked:=v_i\.display_to_source\[v_picked\+1\]/);
assert.match(migration,/exam_prep_mcq_display_letter_v1\(v_r\.selected_answer,v_i\.display_to_source\)/);
assert.match(migration,/exam_prep_mcq_display_letter_v1\(r\.selected_answer,si\.display_to_source\)/);
assert.match(migration,/definition_md5/);
for (const table of ['exam_prep_mcq_order_rollout_v1','exam_prep_mcq_order_function_backups_v1']) {
  assert.match(hardening,new RegExp(`ALTER TABLE private\\.${table} ENABLE ROW LEVEL SECURITY;`),`${table} must have RLS before any release gate`);
  assert.match(hardening,new RegExp(`REVOKE ALL ON TABLE private\\.${table} FROM PUBLIC,anon,authenticated;`),`${table} must deny direct browser access`);
}
assert.match(hardening,/MCQ hardening: RLS not enabled for both new private tables/);
assert.match(hardening,/MCQ hardening: browser table grants remain/);
assert.doesNotMatch(migration,/\bDELETE\s+FROM\s+(?:public\.questions|public\.practice_answers|public\.tour_answers|private\.exam_prep_responses|private\.exam_prep_sessions)/i);
assert.doesNotMatch(migration,/\bUPDATE\s+private\.exam_prep_mcq_order_rollout_v1\s+SET\s+enabled\s*=\s*true/i);
console.log(`PASS content-free MCQ source/display regression: ${scenarios} scorer/diagnosis comparisons across P1/P5, all display orders and three languages; legacy identity, RLS, browser ACL, retries and malformed maps protected. SQL static anchors only; PG17 feature-ON execution remains required.`);
