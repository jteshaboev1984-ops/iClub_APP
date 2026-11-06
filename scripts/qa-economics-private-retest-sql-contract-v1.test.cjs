#!/usr/bin/env node
'use strict';
// STATIC CONTRACT AND CORRUPTION CHECKS ONLY.
// These do not compile SQL or replace isolated authenticated Postgres E2E.
const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const sql=fs.readFileSync(path.resolve(__dirname,'../docs/release-candidates/economics-private-retest-gated-v1.sql'),'utf8');

function assertSqlStructure(text){
  const creates=[...text.matchAll(/^create function (?:public|private)\.iclub_econ_retest_[a-z0-9_]+\(/gm)];
  const opened=[...text.matchAll(/\bset search_path=''\s+as \$\$\s*$/gm)];
  const closed=[...text.matchAll(/^end; \$\$;$/gm)];
  assert.equal(creates.length,6,'unexpected function count');
  assert.equal(opened.length,creates.length,'broken dollar-quoted function opener');
  assert.equal(closed.length,creates.length,'broken dollar-quoted function terminator');
  assert.equal((text.match(/\$\$/g)||[]).length,2*creates.length,'unbalanced dollar delimiters');
  assert.doesNotMatch(text,/\bas \$\s*\n|^end; \$;$/m,'corrupt single-dollar function delimiter');

  const commits=[...text.matchAll(/^commit;$/gm)];
  assert.equal(commits.length,1,'exactly one transaction commit expected');
  const afterCommit=text.slice(commits[0].index+commits[0][0].length)
    .split('\n').map(x=>x.trim()).filter(x=>x!==''&&!x.startsWith('--'));
  assert.deepEqual(afterCommit,[],'SQL statements outside the committed transaction');

  const originalErrorGuard=text.slice(
    text.indexOf("  v_old_item:=v_exam.items->"),
    text.indexOf("  -- Stable idempotency key:")
  );
  assert.match(originalErrorGuard,/if coalesce\(v_old_item->>'key',''\) !~ '\^\[A-D\]\$'/,'damaged original-answer guard');
  assert.match(originalErrorGuard,/jsonb_typeof\(v_old_item->'display_order'\)/,'missing original order validation');
  assert.match(originalErrorGuard,/no_recorded_wrong_answer/,'incorrectly accepting unanswered originals');
  assert.match(originalErrorGuard,/not_an_error/,'incorrectly accepting previously correct answers');
  assert.doesNotMatch(originalErrorGuard,/^\s*-- Stable/m,'broken guard boundary');
}

test('reject a damaged function body, dollar quote or duplicate SQL tail',()=>{
  assert.doesNotThrow(()=>assertSqlStructure(sql));
  assert.throws(()=>assertSqlStructure(sql.replace(
    "if coalesce(v_old_item->>'key','') !~ '^[A-D]$'",
    "if coalesce(v_old_item->>'key','') !~ '^[A-D]"
  )),/damaged original-answer guard/);
  assert.throws(()=>assertSqlStructure(sql.replace(
    "returns jsonb language plpgsql stable security definer set search_path='' as $$",
    "returns jsonb language plpgsql stable security definer set search_path='' as $"
  )),/dollar|function/i);
  assert.throws(()=>assertSqlStructure(sql+'\n    or jsonb_typeof(v_old_item->\'display_order\')=\'array\';\n'),
    /outside the committed transaction/);
});

test('new tables private, RLS on, and issuance OFF',()=>{
  assert.match(sql,/^begin;$/m);
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

test('different unseen item for each owned incorrect source answer',()=>{
  assert.match(sql,/unique\(user_id,item_key\)/);
  assert.match(sql,/unique\(user_id,source_session_id,source_item_order\)/);
  assert.match(sql,/status='finalized' and finalized_at is not null/);
  assert.match(sql,/no_recorded_wrong_answer/);
  assert.match(sql,/not_an_error/);
  assert.match(sql,/not exists \([\s\S]*?seen\.item_key=r\.item_key/i);
  assert.doesNotMatch(sql,/update\s+private\.iclub_exam_native_mcq_attempts_v1/i);
  assert.doesNotMatch(sql,/delete\s+from\s+private\.iclub_exam_native_mcq_attempts_v1/i);
  assert.doesNotMatch(sql,/drop\s+(table|function)/i);
});


test('exclude prior native source_id / snapshot_md5 exposures, not only future item_key',()=>{
  const idGuard="shown->>'source_id'=r.known_legacy_source_id::text";
  const hashGuard="shown->>'snapshot_md5'=r.known_legacy_snapshot_md5";
  const oldGuard="shown->>'item_key'=r.item_key";
  for(const guard of [idGuard,hashGuard,oldGuard]) assert(sql.includes(guard),'missing shown-source guard');
  assert.match(sql,/known_legacy_source_id bigint/);
  assert.match(sql,/known_legacy_snapshot_md5 text/);
  const issuedSourceTrigger=sql.slice(sql.indexOf('create function private.iclub_econ_retest_protect_issued_source_v1()'),
      sql.indexOf('create trigger iclub_econ_retest_protect_issued_source_v1'));
  assert(issuedSourceTrigger.includes('new.known_legacy_source_id'),'mutable shown-source link');
  assert(issuedSourceTrigger.includes('new.known_legacy_snapshot_md5'),'mutable shown-hash link');
  function requireActualHistoricalGuards(candidate){
    for(const guard of [idGuard,hashGuard,oldGuard]){
      assert(candidate.includes(guard),'missing actual native exposure comparison');
    }
  }
  assert.doesNotThrow(()=>requireActualHistoricalGuards(sql));
  for(const guard of [idGuard,hashGuard]){
    const mutation=sql.replace(guard,'false /* removed historical guard */');
    assert.throws(()=>requireActualHistoricalGuards(mutation),
      /missing actual native exposure comparison/);
  }
});

test('owner auth, server scoring and keys only after finalization',()=>{
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

test('client public RPCs have explicit EXECUTE revoke + narrow grant',()=>{
  for(const f of ['start_v1(uuid,integer,text)','get_v1(uuid,text)','resume_v1(uuid)','submit_v1(uuid,integer,text)']){
    const name='public.iclub_econ_retest_'+f.replaceAll('(', '\\(').replaceAll(')', '\\)');
    assert.match(sql,new RegExp('revoke all on function '+name+' from public,anon,authenticated','i'));
    assert.match(sql,new RegExp('grant execute on function '+name+' to authenticated','i'));
  }
});
