// node --test qa/ai-layer-v21-math-authority-sql.test.cjs
// STATIC SQL contract review, not PostgreSQL execution.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs');
const path='qa/sql_drafts/iclub_ai_math_skill_context_v21_UNAPPLIED.sql';
const sql=fs.readFileSync(path,'utf8');
const func=sql.slice(sql.indexOf('create or replace function public.get_iclub_ai_math_skill_context_service_v2('));
test('Math authority function lives ONLY under unapplied QA SQL drafts',()=>{
 assert.match(path,/^qa\/sql_drafts\/.*UNAPPLIED\.sql$/);
 assert.match(sql,/DO \$iclub_ai_v21_math_scratch_only\$/);
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/inet_server_addr\(\)/);
});
test('The new function is a read-only, service-only RPC, never a client permission',()=>{
 assert.match(func,/returns jsonb\s+language plpgsql\s+stable\s+security definer\s+set search_path=''/);
 assert.match(func,/revoke all on function public\.get_iclub_ai_math_skill_context_service_v2\(uuid,uuid,text,text\)\s*from public,anon,authenticated/);
 assert.match(func,/grant execute on function public\.get_iclub_ai_math_skill_context_service_v2\(uuid,uuid,text,text\)\s*to service_role/);
});
test('Exact learner owns a FINALIZED P1/P5 session',()=>{
 for(const term of ["s.id=p_session_id","s.user_id=p_user_id","s.status='finalized'",
 "s.finalized_at is not null","s.component_code in ('P1','P5')"]){
   assert.ok(func.includes(term),term);
 }
});
test('Subject component and runtime are server-verified',()=>{
 assert.match(func,/p_skill_code not like v_component\|\|'-%'/);
 assert.match(func,/r\.kill_switch=false/);
 assert.match(func,/r\.gateway_enabled=true/);
 assert.match(func,/private\.iclub_ai_has_active_protected_assessment_v1\(p_user_id\)/);
});
test('A provided skill must actually exist in the finalized assessment',()=>{
 assert.match(func,/from private\.exam_prep_session_items i/);
 assert.match(func,/i\.session_id=p_session_id/);
 assert.match(func,/i\.primary_skill_code=p_skill_code/);
});
test('Evidence must be verified and owned by same user, skill and session',()=>{
 assert.match(func,/from private\.exam_prep_evidence_events e/);
 for(const check of ["e.session_id=p_session_id","e.user_id=p_user_id",
 "e.component_code=v_component","e.skill_code=p_skill_code",
 "e.verification_status='app_verified'"])assert.ok(func.includes(check));
});
test('Retired/unapproved Tutor cards cannot be returned',()=>{
 assert.match(func,/from private\.exam_prep_ai_tutor_cards t/);
 for(const check of ["t.content_version='tutor_v3_learner_first'",
 "t.approval_status='approved'","t.is_runtime_allowed=true",
 "t.locale=p_locale","t.skill_code=p_skill_code"]){
  assert.ok(func.includes(check),check);
 }
});
test('Rights-cleared source and live hash independently verified',()=>{
 assert.match(func,/from private\.exam_prep_ai_source_cards c/);
 for(const check of ["c.source_card_key=v_source_key",
 "c.card_type='theory'","c.locale=p_locale","c.skill_code=p_skill_code",
 "c.approval_status='approved'","c.rights_status='original_iclub'",
 "c.is_runtime_allowed=true","length(c.content_hash)=64"]){
  assert.ok(func.includes(check),check);
 }
});
test('No academic answer text, answer keys or progress mutation are returned',()=>{
 for(const dangerous of [/insert\s+into\s+private\.exam_prep_/i,
   /update\s+private\.exam_prep_/i,/delete\s+from\s+private\.exam_prep_/i,
   /alter\s+table\s+private\.exam_prep_/i]){
    assert.equal(dangerous.test(sql),false,String(dangerous));
 }
 assert.equal(func.includes('body_text'),false);
 assert.equal(func.includes('main_explanation'),false);
 assert.equal(func.includes('user_answer'),false);
});
test('Math authority cannot route foreign languages and missing skill codes',()=>{
 assert.match(func,/p_locale not in \('ru','uz','en'\)/);
 assert.match(func,/p_skill_code !~ '\^P\[15\]-/);
 assert.match(func,/context_not_authorized/);
 assert.match(func,/skill_evidence_unverified/);
});
test('Approved result returns only source-binding metadata, never billing proof',()=>{
 assert.ok(func.includes("'academic_state_changed',false"));
 assert.ok(func.includes("'source_hash',v_source_hash"));
 assert.ok(func.includes("'tutor_content_hash',v_tutor_hash"));
 assert.equal(/reserve_iclub_ai_usage_service_v[12]\(/.test(func),false);
 assert.equal(/finalize_iclub_ai_usage_service_v[12]\(/.test(func),false);
});
test('RPC declaration is unique and no original legacy Tutor RPC is redefined',()=>{
 assert.equal((sql.match(/create or replace function public\.get_iclub_ai_math_skill_context_service_v2\(/g)||[]).length,1);
 assert.equal(/create or replace function (?:public|private)\.get_exam_prep_ai_tutor_card_service_v1\(/.test(sql),false);
});

test('Math SQL fixture is fully transactional and synthetic-only',()=>{
 const fixture=fs.readFileSync('qa/sql_drafts/iclub_ai_math_authority_local_pg.psql','utf8');
 assert.match(fixture,/^BEGIN;/m);
 assert.match(fixture,/^ROLLBACK;/m);
 assert.match(fixture,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(fixture,/inet_server_addr\(\)/);
 assert.ok(fixture.includes('\\ir iclub_ai_math_skill_context_v21_UNAPPLIED.sql'));
 for(const item of ['skill_evidence_unverified','active_assessment','source_not_approved',
 'tutor_source_not_ready','skill_component_mismatch','context_not_authorized','gateway_disabled']){
  assert.ok(fixture.includes(item),item);
 }
});
test('Local scratch shell selects an explicit allowlisted Math or tariff suite',()=>{
 const script=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
 assert.match(script,/ICLUB_PGTEST_SUITE/);
 assert.match(script,/meter\) TEST_FILE="qa\/sql_drafts\/iclub_ai_v21_local_pg_regression\.psql"/);
 assert.match(script,/math\) TEST_FILE="qa\/sql_drafts\/iclub_ai_math_authority_local_pg\.psql"/);
 assert.ok(script.includes('case "$SUITE" in'));
 assert.ok(script.includes('not exists (select 1 from pg_tables'));
});
