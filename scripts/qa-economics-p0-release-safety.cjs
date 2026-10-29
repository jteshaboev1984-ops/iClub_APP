#!/usr/bin/env node
'use strict';
// Non-destructive P0 release-safety review. No external services or credentials.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const forward=read('supabase/migrations/20261028194500_iclub_economics_native_mcq_active_access_parity_v1.sql');
const rollback=read('supabase/rollback/20261028194500_iclub_economics_native_mcq_active_access_parity_v1_rollback.sql');
const html=read('index.html');
const intended=[
  'iclub_exam_native_mcq_answer_v1',
  'iclub_exam_native_mcq_finish_v1',
  'iclub_exam_native_mcq_get_v1',
  'iclub_exam_native_mcq_mark_studied_v1',
  'iclub_exam_native_mcq_study_plan_v1'
].sort();
function extract(sql){
  return [...sql.matchAll(/CREATE OR REPLACE FUNCTION public\.(iclub_exam_native_mcq_[a-z_]+_v1)\s*\(([^)]*)\)/g)]
    .map(m=>({name:m[1],signature:m[2].replace(/\s+/g,' ').trim()}))
    .sort((a,b)=>a.name.localeCompare(b.name));
}
const a=extract(forward),b=extract(rollback);
assert.deepEqual(a.map(x=>x.name),intended,'Forward migration must alter exactly five Economics RPCs');
assert.deepEqual(b.map(x=>x.name),intended,'Rollback must restore exactly those same five RPCs');
assert.deepEqual(a,b,'Rollback identities/argument types must match forward SQL');

function blocks(sql){
  return Object.fromEntries(
    [...sql.matchAll(/CREATE OR REPLACE FUNCTION public\.(iclub_exam_native_mcq_[a-z_]+_v1)\s*\(([^)]*)\)([\s\S]*?)(?=\nCREATE OR REPLACE FUNCTION|\nCOMMIT;|$)/g)]
      .map(m=>[m[1],m[0]])
  );
}
const before=blocks(rollback),after=blocks(forward);
const betaGuard=/IF\s+NOT\s+private\.iclub_exam_native_economics_beta_allowed_v1\(v_user\)\s+THEN\s+RETURN\s+jsonb_build_object\('ok',false,'code','not_authorized'\);\s+END\s+IF;/g;
function normalize(sql){
  return sql.replace(/--[^\n]*/g,'').replace(/\s+/g,'').toLowerCase().replace(/;+$/,'');
}
function removeGuard(sql,name){
  let stripped=sql.replace(/--[^\n]*/g,'').replace(betaGuard,'');
  if(name==='iclub_exam_native_mcq_get_v1')
    stripped=stripped.replace(/IF\s+v\.status='active'\s+THEN\s*END\s+IF;/g,'');
  if(name==='iclub_exam_native_mcq_finish_v1')
    stripped=stripped.replace(/IF\s+v\.status<>'finalized'\s+THEN\s*END\s+IF;/g,'');
  return normalize(stripped);
}
for(const name of intended){
  assert.equal((after[name].match(betaGuard)||[]).length,1,'Exactly one access guard in '+name);
  assert.equal(removeGuard(after[name],name),normalize(before[name]),
    'Unexpected function body changes beyond Economics beta authorization in '+name);
}

assert.equal((forward.match(/private\.iclub_exam_native_economics_beta_allowed_v1\(/g)||[]).length,5,
  'Every altered Economics RPC must check current access');
assert(!rollback.includes('iclub_exam_native_economics_beta_allowed_v1'),
  'Rollback must preserve the old production functions, not copy new code');
assert(/^\s*--[\s\S]*?BEGIN;/.test(rollback)&&/COMMIT;\s*$/.test(rollback),
  'Rollback is a single controlled transaction');
for(const sql of [forward,rollback]){
  assert(!/\b(?:DROP|TRUNCATE)\s+(?:TABLE|SCHEMA)\b|\bALTER\s+TABLE\b|\bDELETE\s+FROM\b/i.test(sql),
    'No destructive learner-data DDL/DML permitted');
  assert(!/\blocalStorage\.clear\s*\(/.test(sql),'No local-data erasure');
  assert.equal((sql.match(/SECURITY DEFINER/g)||[]).length,5,'RPC security mode must be preserved');
}
assert(html.includes('exam-prep-economics-native.js?v=econ-p0-answer-parity-no-consent-20261029'),
  'Deployed page must use the reviewed native answer-parity asset pin');
assert(!forward.includes('math_as_p1_p5_sessions'),'Mathematics attempts must not be modified');
console.log('ECONOMICS P0 ROLLBACK + ACCESS GUARD SAFETY PASS — five exact RPCs, no learner-data removal');
