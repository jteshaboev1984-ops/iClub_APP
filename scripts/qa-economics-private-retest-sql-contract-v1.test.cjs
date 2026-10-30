#!/usr/bin/env node
'use strict';
// STATIC CONTRACT CHECK ONLY. Does not prove Postgres compilation, authenticated
// integration behaviour, database recovery, or readiness for a learner beta.
const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const sql=fs.readFileSync(path.resolve(__dirname,'../docs/release-candidates/economics-private-retest-gated-v1.sql'),'utf8');
test('new tables private and new issuance defaults OFF',()=>{
  assert.match(sql,/begin;[\s\S]*commit;/i);
  for(const t of ['control','sources','sessions']){
    assert.match(sql,new RegExp('create table private\\.iclub_econ_retest_'+t+'_v1','i'));
    assert.match(sql,new RegExp('alter table private\\.iclub_econ_retest_'+t+'_v1 enable row level security','i'));
    assert.match(sql,new RegExp('revoke all on private\\.iclub_econ_retest_'+t+'_v1 from public,anon,authenticated','i'));
  }
  assert.match(sql,/issuance_enabled boolean not null default false/i);
  assert.match(sql,/values \(1,false\);/i);
  assert.match(sql,/and r\.semantic_distinct_status='pass'/i);
  assert.match(sql,/and ps\.link_role='direct'/i);
});
test('only one original per user and unchanged historic attempts',()=>{
  assert.match(sql,/unique\(user_id,item_key\)/);
  assert.match(sql,/unique\(user_id,source_session_id,source_item_order\)/);
  assert.match(sql,/v_exam\.status='finalized'|status='finalized' and finalized_at is not null/);
  assert.match(sql,/no_recorded_wrong_answer/);
  assert.match(sql,/not exists \([\s\S]*?seen\.item_key=r\.item_key/i);
  assert.doesNotMatch(sql,/update\s+private\.iclub_exam_native_mcq_attempts_v1/i);
  assert.doesNotMatch(sql,/delete\s+from\s+private\.iclub_exam_native_mcq_attempts_v1/i);
  assert.doesNotMatch(sql,/drop\s+(table|function)/i);
});
test('authenticated session and server scoring and completion-only reveal',()=>{
  assert.match(sql,/from auth\.sessions s/i);
  assert.match(sql,/coalesce\(v_claims->>'is_anonymous'/i);
  assert.match(sql,/pg_advisory_xact_lock/);
  assert.match(sql,/for update;/i);
  assert.match(sql,/selected_index=p_selected_index,/);
  assert.match(sql,/is_correct=v_correct/);
  assert.match(sql,/v_s\.status='finalized'.*?then ascii\(v_q\.answer_key\)/s);
  assert.match(sql,/v_s\.status='finalized'.*?then v_l->>'explanation'/s);
  assert.match(sql,/public\.iclub_econ_retest_resume_v1/);
});
test('all client public RPCs have explicit execute revoke and authenticated grant',()=>{
  for(const f of ['start_v1(uuid,integer,text)','get_v1(uuid,text)','resume_v1(uuid)','submit_v1(uuid,integer,text)']){
    const name='public.iclub_econ_retest_'+f.replaceAll('(', '\\(').replaceAll(')', '\\)');
    assert.match(sql,new RegExp('revoke all on function '+name+' from public,anon,authenticated','i'));
    assert.match(sql,new RegExp('grant execute on function '+name+' to authenticated','i'));
  }
});
