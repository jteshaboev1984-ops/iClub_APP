// node --test qa/ai-layer-v21-cross-subject-sql.test.cjs
// STATIC source contract checks. Scratch SQL has NOT been executed in Postgres.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs');
const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_practice_exact_source_v21_UNAPPLIED.sql','utf8');
const suite=fs.readFileSync('qa/sql_drafts/iclub_ai_practice_exact_source_local_pg.psql','utf8');
const runner=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
const info=require('./ai-layer-v21-subject-readiness-inventory.snapshot.json');
const body=sql.slice(sql.indexOf('create or replace function public.get_iclub_ai_practice_question_source_service_v2('));
test('Raw Practice SQL is an UNAPPLIED QA draft with intrinsic scratch-only guard',()=>{
 assert.match(sql,/DO \$iclub_ai_v21_practice_scratch_only\$/);
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/inet_server_addr\(\)/);
 assert.equal((sql.match(/create or replace function public\.get_iclub_ai_practice_question_source_service_v2\(/g)||[]).length,1);
});
test('Practice answer authority is service-only and never browser-executable',()=>{
 assert.match(body,/language plpgsql stable security definer set search_path=''/);
 assert.match(sql,/revoke all on function public\.get_iclub_ai_practice_question_source_service_v2\(uuid,bigint,bigint,text\)\s*from public,anon,authenticated/);
 assert.match(sql,/grant execute on function public\.get_iclub_ai_practice_question_source_service_v2\(uuid,bigint,bigint,text\)\s*to service_role/);
});
test('Requires completed full Practice attempt owned by the current JWT learner',()=>{
 for(const x of ['s.id=p_session_id','s.user_id=p_user_id',
  "s.status='finalized'","s.finalized_at is not null"])
  assert.ok(body.includes(x),x);
});
test('Question must be in session question_ids AND actually answered',()=>{
 assert.ok(body.includes('p_question_id=any(s.question_ids)'));
 assert.ok(body.includes('from public.practice_session_answers_v4 a'));
 assert.ok(body.includes('a.session_id=s.id and a.question_id=p_question_id'));
});
test('Subject derived by verified relational join and restricted to Econ/Chemistry',()=>{
 assert.ok(body.includes('join public.subjects subj on subj.id=s.subject_id'));
 assert.ok(body.includes("subj.subject_key in ('economics','chemistry')"));
 assert.ok(body.includes('subj.is_active=true'));
 assert.equal(body.includes('p_subject_key'),false);
});
test('A generic topic card or result_context cannot impersonate an exact answer',()=>{
 assert.ok(body.includes('c.question_id=p_question_id'));
 assert.ok(body.includes("c.card_type='answer_explanation'"));
 assert.equal(body.includes('c.question_id is null'),false);
});
test('Source must be rights-cleared, approved and locale-specific',()=>{
 for(const x of ["c.locale=p_locale","c.approval_status='approved'",
  "c.rights_status='original_iclub'","c.is_runtime_allowed=true",
  'length(c.content_hash)=64'])assert.ok(body.includes(x),x);
});
test('Fail closed when any protected assessment or new AI global stop is on',()=>{
 assert.ok(body.includes('private.iclub_ai_has_active_protected_assessment_v1(p_user_id)'));
 assert.ok(body.includes('cfg.kill_switch=false'));
 assert.ok(body.includes('cfg.gateway_enabled=true'));
});
test('Metadata never includes progress/answer text or performs academic mutation',()=>{
 for(const x of ['user_answer','correct_answer','body_text','answer_key','score'])
  assert.equal(body.includes(x),false,x);
 for(const re of [/insert\s+into\s+public\./i,/update\s+public\./i,/delete\s+from\s+public\./i])
  assert.equal(re.test(body),false,String(re));
 assert.ok(body.includes("'academic_state_changed',false"));
});
test('Local SQL testcase is one transaction, scratch guarded and rollback only',()=>{
 assert.match(suite,/^BEGIN;/m);assert.match(suite,/^ROLLBACK;/m);
 assert.ok(suite.includes('current_database() !~'));
 assert.ok(suite.includes('inet_server_addr()'));
 for(const reason of ['active_assessment','gateway_disabled','practice_context_not_authorized',
    'exact_source_not_ready'])assert.ok(suite.includes(reason),reason);
});
test('Local SQL runner explicitly allows Practice only on an empty localhost scratch DB',()=>{
 assert.match(runner,/practice\) TEST_FILE="qa\/sql_drafts\/iclub_ai_practice_exact_source_local_pg\.psql"/);
 assert.ok(runner.includes('NOT_EMPTY_OR_UNSAFE'));
 assert.ok(runner.includes('ICLUB_PGTEST_DB'));
 assert.ok(runner.includes('127.0.0.1'));
});
test('Historical inventory makes no automatic release based on number of cards',()=>{
 assert.equal(info.practiceApprovedCards.totalCards,357);
 assert.equal(info.practiceApprovedCards.exactQuestionCardRowsAcrossLocales,111);
 assert.equal(info.practiceApprovedCards.genericOrResultContextCardRowsAcrossLocales,246);
 assert.equal(info.practiceApprovedCards.exactQuestionProofReadyForProduction,false);
 assert.equal(info.globalAIRuntime.killSwitch,true);
});
test('Subjects without governed source readiness remain inactive for new AI',()=>{
 for(const name of ['biology','informatics','english_a1','english_a2','english_b1','sat','ielts']){
  const r=info.subjects.find(s=>s.subject===name);
  assert.ok(r,name);assert.equal(r.lessonAIReady,false,name);
 }
});
