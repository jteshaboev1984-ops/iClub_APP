// node --test qa/ai-layer-v21-content-handoff-sql.test.cjs
// Static contract only; PostgreSQL fixture is prepared but NOT executed.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs');
const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_topic_release_gate_v21_UNAPPLIED.sql','utf8');
const scratch=fs.readFileSync('qa/sql_drafts/iclub_ai_topic_release_local_pg.psql','utf8');
const runner=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
const fn=sql.slice(sql.toLowerCase().indexOf('create or replace function public.get_iclub_ai_topic_release_service_v21('));
test('SQL draft intrinsically prevents remote or production database execution',()=>{
 assert.match(sql,/DO \$iclub_ai_v21_release_scratch_only\$/);
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/inet_server_addr\(\)/);
 assert.match(sql,/BLOCKED: topic readiness draft is scratch only/);
});
test('Table identity is subject×surface×feature×topic×locale',()=>{
 for(const key of ['surface_code','subject_key','feature_code','topic_key','locale'])
  assert.ok(sql.includes(key+' text not null'),key);
 assert.ok(sql.includes('primary key(surface_code,subject_key,feature_code,topic_key,locale)'));
});
test('There is never a source/feature publication without all eight approval gates',()=>{
 for(const key of ['content_approved','rights_approved','source_version_verified',
 'correctness_passed','negative_tests_passed','exam_security_passed',
 'locale_verified','accessibility_passed']){
  assert.ok(sql.includes(key+' boolean not null default false'),key);
  assert.ok(sql.includes('v.'+key),key);
 }
});
test('No initial readiness, publication or feature flags default to ready',()=>{
 assert.match(sql,/publication_state text not null default 'draft'/);
 assert.match(sql,/feature_enabled boolean not null default false/);
 assert.match(sql,/source_conflict boolean not null default false/);
});
test('An approved publication requires named reviewer and approval time',()=>{
 assert.match(sql,/publication_state<>'approved' OR/);
 assert.match(sql,/approved_at is not null/);
 assert.match(sql,/approved_by is not null/);
});
test('Revoked or conflicted content cannot silently remain published',()=>{
 assert.match(fn,/v.publication_state<>'approved'/);
 assert.match(fn,/v.feature_enabled<>true/);
 assert.match(fn,/v.source_conflict=true/);
 assert.match(fn,/return jsonb_build_object\('ready',false,'reason','in_development'\)/i);
});
test('Existing global kill switch, UI and gateway are independent blockers',()=>{
 assert.match(fn,/cfg.kill_switch=false/);
 assert.match(fn,/cfg.ui_enabled=true/);
 assert.match(fn,/cfg.gateway_enabled=true/);
 assert.match(fn,/global_ai_disabled/);
});
test('Published version/hash/revision remains bound to the exact topic',()=>{
 for(const k of ["'source_id',v.source_id","'source_version',v.source_version",
 "'source_hash',v.source_hash","'revision',v.publication_revision",
 "surface_code=p_surface","subject_key=p_subject","feature_code=p_feature",
 "topic_key=p_topic","locale=p_locale"]){
  assert.ok(fn.includes(k),k);
 }
});
test('The registry can be read only by service_role, never public or browser',()=>{
 assert.match(sql,/REVOKE ALL ON TABLE private\.iclub_ai_topic_release_v21\s+FROM public,anon,authenticated/);
 assert.match(sql,/GRANT SELECT ON TABLE private\.iclub_ai_topic_release_v21 TO service_role/);
 assert.match(sql,/REVOKE ALL ON FUNCTION public\.get_iclub_ai_topic_release_service_v21\(\s*text,text,text,text,text\) FROM public,anon,authenticated/);
 assert.match(sql,/GRANT EXECUTE ON FUNCTION public\.get_iclub_ai_topic_release_service_v21\(\s*text,text,text,text,text\) TO service_role/);
});
test('No content, answers, student data, payment or write publication API is created',()=>{
 for(const illegal of [/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.publish_/i,
   /insert\s+into\s+private\.exam_prep_/i,/update\s+public\.practice_/i,
   /delete\s+from\s+public\.tour_/i]){
  assert.equal(illegal.test(sql),false,String(illegal));
 }
 for(const field of ["lesson_text text","question_text text","correct_answer text",
   "user_answer text","prompt_text text","price numeric"]){
   assert.equal(sql.includes(field),false,field);
 }
});
test('Releasable source is not itself a permission to call a model or charge',()=>{
 assert.match(sql,/authenticated owner/i);
 assert.match(sql,/per-user cohort/i);
 assert.match(sql,/exact live/i);
 assert.equal(/reserve_iclub_ai_usage_service_v[12]\(/.test(sql),false);
});
test('All local publication tests are rollbacked, scratch and synthetic only',()=>{
 assert.match(scratch,/^BEGIN;/m);assert.match(scratch,/^ROLLBACK;/m);
 assert.match(scratch,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 for(const phrase of ['Missing source accidentally ready','Draft opened without approval',
  'Approved RU source unavailable','Unapproved UZ locale','Suspended publication',
  'Global stop bypassed'])assert.ok(scratch.includes(phrase),phrase);
});
test('Local runner allowlists release suite on empty localhost scratch DB only',()=>{
 assert.match(runner,/release\) TEST_FILE="qa\/sql_drafts\/iclub_ai_topic_release_local_pg\.psql"/);
 assert.ok(runner.includes('NOT_EMPTY_OR_UNSAFE'));
 assert.ok(runner.includes('ICLUB_PGTEST_DB'));
 assert.ok(runner.includes('127.0.0.1'));
});
