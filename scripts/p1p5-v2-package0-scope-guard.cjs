// Issue #450, Mathematics P1/P5 v2.0 Package 0.
 // Static guard for repeatable SELECT-only live audit and isolated synthetic FK test.
 // No network, production credentials, database writes, external dependencies.
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const baseline=read('supabase/tests/p1p5_v2_package0_baseline_readonly.sql');
const dry=read('supabase/tests/p1p5_v2_package0_cleanup_dry_run_readonly.sql');
const report=read('supabase/tests/p1p5_v2_package0_cleanup_scope_report_readonly.sql');
const isolated=read('supabase/tests/p1p5_v2_package0_cleanup_isolated_fk_rehearsal.sql');
const strip=s=>s.replace(/--[^\n]*/g,'').replace(/'(?:''|[^'])*'/g,"''");
for(const [label,s] of [['baseline',baseline],['dry-run',dry],['scope report',report]]){
  assert(/--.*READ.?ONLY|--.*read.?only|--.*READ ONLY/i.test(s),label+' lacks readonly guard header');
  assert(!/\b(?:delete|update|insert|truncate|drop|alter|create|grant|revoke|call|do|execute|copy|vacuum)\b/i.test(strip(s)),label+' contains nonread-only SQL keyword');
  assert(/SELECT/i.test(s),label+' contains no read-only query');
}
const reset=[
'component_access_gates','component_placements','correction_actions','correction_cases',
'evidence_events','exam_appointments','exam_map_revisions','exam_ops_confirmations','exam_profiles',
'human_review_recommendations','integrity_events','learning_review_starts_v1','legacy_evidence_references',
'prerequisite_states','progress_revalidation_cases','progress_revalidation_items','recovery_cases',
'responses','retest_events','session_authorizations','session_items','sessions','skill_states',
'stage_states','timed_attempt_results','timed_written_self_marks','weekly_flow_enrollment_v1',
'weekly_goal_snapshots','weekly_plan_items','weekly_plans',
'written_session_check_snapshots','written_step_advances_v1'].map(x=>'exam_prep_'+x);
assert.equal(reset.length,32,'expected exact provisional scope');
for(const name of reset){
  assert(report.includes('FROM private.'+name),name+' missing from report');
  assert(dry.includes('FROM private.'+name),name+' missing from dry-run');
}
for(const forbidden of [
'public.users','public.tour_attempts','public.tour_answers','public.certificates',
'public.practice_attempts','public.practice_sessions_v4','public.practice_drill_sessions_v4',
'private.exam_prep_feature_entitlements','private.exam_prep_beta_consents',
'private.exam_prep_audit_events','private.exam_prep_written_tasks'
]){
  assert(report.includes(forbidden),forbidden+' missing from protected-data observation');
  assert(!reset.includes(forbidden.replace('private.','').replace('public.','')),
    forbidden+' must not be in candidate reset list');
}
for(const x of ['auth_consumed_session_links','retained_mentor_links_blocking_reset']){
  assert(dry.includes(x),'missing FK blocker observation: '+x);
}
assert(isolated.includes('ISOLATED PostgreSQL 17 ONLY'),'isolated-only header');
for(const x of [
'BEGIN;','ROLLBACK;','SAVEPOINT before_cleanup','ROLLBACK TO SAVEPOINT before_cleanup',
'ON DELETE RESTRICT','EXCEPTION WHEN foreign_key_violation','DELETE FROM sessions',
'DELETE FROM recommendations','retained_mentor_queue','practice_attempts','tour_attempts','certificates'
]) assert(isolated.includes(x),'isolated rehearsal contract missing: '+x);
// Gate added at Package 0 independent-PG17-backup checkpoint.
const dag=read('supabase/tests/p1p5_v2_package0_fk_graph_readonly.sql');
const full=read('supabase/tests/p1p5_v2_package0_32table_disposable_rollback_only.sql');
const backup=read('scripts/p1p5-v2-package0-synthetic-backup-restore.sh');
const e2e=read('.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml');
const authorization=read('docs/math-p1p5-v2-package0-release-authorization-contract.md');
assert(!/\b(?:insert|update|delete|truncate|drop|alter|create|grant|revoke|call|do|execute|copy|vacuum)\b/i.test(strip(dag)),
  'full live FK graph must remain SELECT-only');
assert(dag.includes('GRAPH_PRECHECK_PASS_NO_DELETE_AUTHORIZED'),'live graph must not claim release permission');
assert(dag.includes('consumed_session_id')&&dag.includes('correction_case_id'),
  'both FK cut points are essential');
// Exclude the deliberate pre-authorization negative DELETE probe; validate only
// the two complete 32-table scoped cleanup/replay sequences.
const delMarker='-- Two real nullable links must be removed before cascading through DAG.';
assert(full.includes(delMarker),'missing full-scope cleanup start marker');
const guardedCleanup=full.slice(full.indexOf(delMarker));
const targets=[...guardedCleanup.matchAll(/DELETE FROM private\.(exam_prep_\w+)/g)].map(x=>x[1]);
assert.equal(targets.length,64,'isolated cleanup needs exactly 32 scoped deletes and 32 replay checks');
for(const name of reset)assert.equal(targets.filter(t=>t===name).length,2,
  'each candidate must appear exactly twice: '+name);
for(const statement of [
  "current_database()<>'postgres'",
  "current_setting('iclub.e2e_isolated',true)",
  'SAVEPOINT p0_before_actual_full_cleanup',
  'ROLLBACK TO SAVEPOINT p0_before_actual_full_cleanup',
  'ROLLBACK;',
  "'iclub.exam_prep_synthetic_cleanup','on',true",
  'PASS: authentic immutable evidence trigger denies unguarded delete'
])assert(full.includes(statement),'isolated-only rollback guard missing: '+statement);
assert(!/DISABLE\s+TRIGGER|SET\s+session_replication_role|localStorage\.clear\s*\(/i.test(full),
  'isolated test must not disable protections');
for(const token of ['P1P5_E2E_ISOLATED','PGHOST','PGDATABASE','pg_dump','pg_restore',
                     'createdb','dropdb','fingerprint_query','mktemp']){
  assert(backup.includes(token),'backup/restore guard missing: '+token);
}
assert(backup.includes("SELECT count(*) FROM public.users")&&backup.includes("SELECT count(*) FROM auth.users"),
  'backup must reject unexpected real learners');
assert(e2e.includes('docker run --rm --network host --entrypoint bash')&&
       e2e.includes('postgres:17 /p0-restore-test.sh'),
  'backup client must match isolated PG17 server (runner defaults to PG16)');
assert(e2e.includes('p1p5_v2_package0_32table_disposable_rollback_only.sql'),
  'full scoped cleanup test must be in real HTTP E2E');
for(const phrase of ['NOT release GO','synthetic-only','ONE','Practice','Tour','AI','audit',
                     'one-shot','NO_GO']){
  assert(authorization.toLowerCase().includes(phrase.toLowerCase()),
    'release-time authorization must keep protected data and fail closed: '+phrase);
}
console.log('PASS P0 full 32-table exact scoped rollback and independent PG17-only backup/restore safety contracts');

console.log('PASS v2 Package 0 SELECT-only live queries, 32 provisional candidates, protected invariants, synthetic PG rollback contracts');


// P0-08 draft-branch schema drift: the old 32-table reset scope is NOT final.
const future=read('supabase/tests/p1p5_v2_package0_future_tables_readonly.sql');
const driftDecision=read('docs/math-p1p5-v2-package0-draft-schema-drift-20261104.md');
assert(/READ ONLY/i.test(future),'cross-PR scope inspection must be READ ONLY');
assert(!/\b(?:delete|update|insert|truncate|drop|alter|create|grant|revoke|call|do|execute|copy|vacuum)\b/i.test(strip(future)),
  'draft-schema scope inspection contains a write command');
for(const [name,pr] of [
  ['exam_prep_periodic_study_report_receipts_v1','469'],
  ['exam_prep_learner_exam_dates_v1','470']
]){
  assert(future.includes(name),'P0-08 SQL must detect new draft user state '+name);
  assert(driftDecision.includes(name),'P0-08 release hold must classify '+name);
  assert(driftDecision.includes('PR #'+pr),'P0-08 must link original PR #'+pr);
  assert(!reset.includes(name),'original 32-table rehearsal must not silently assume future table '+name);
}
assert(driftDecision.includes('No')||driftDecision.includes('NO_GO'),'scope drift must not grant release');
assert(driftDecision.includes('program_version_id')&&driftDecision.includes('one-shot'),
  'missing receipt ownership or release epoch review');
console.log('PASS P0-08 draft-schema drift: two newly proposed per-user tables identified, both outside original 32-table scope, release NO_GO');

// P0-09 disposable epoch model is a negative security test, NEVER a release API.
const epochFixture=read('supabase/tests/p1p5_v2_package0_epoch_one_shot_disposable_only.sql');
const p0Workflow=read('.github/workflows/p1p5-v2-package0-cleanup-rehearsal.yml');
assert(epochFixture.includes('ISOLATED PostgreSQL 17 ONLY'), 'missing disposable fixture warning');
assert(epochFixture.includes("current_database() <> 'iclub_p1p5_package0_test'"),
  'P0-09 must refuse every non-disposable database name');
for(const token of [
  'BEGIN;', 'ROLLBACK;', 'SAVEPOINT before_simulated_release',
  'ROLLBACK TO SAVEPOINT before_simulated_release',
  'REVOKE ALL ON ALL FUNCTIONS IN SCHEMA p0_09_fixture FROM PUBLIC',
  'SET SESSION AUTHORIZATION p0_mock_release_executor',
  'SET SESSION AUTHORIZATION p0_mock_learner',
  'production_backup_restored','explicit_approval','retention_scope_reviewed',
  'unknown_fk_or_schema_drift','active_attempts','protected_fingerprint',
  'approved_sha','consumed','stale_or_paused_epoch','p0_09_fixture.test_progress',
  'p0_09_fixture.protected_data'
]) assert(epochFixture.includes(token),'P0-09 missing fail-closed gate: '+token);
assert(!/private\.exam_prep_(sessions|responses|skill_states)\b/.test(epochFixture),
  'P0-09 must not mutate existing real Math Exam Prep tables');
assert(p0Workflow.includes('p1p5_v2_package0_epoch_one_shot_disposable_only.sql'),
  'P0-09 cannot pass without isolated postgres workflow invocation');
console.log('PASS P0-09 source authorization model isolated from production, role/epoch/replay gates present');


// P0-10 prospective state overlay uses the UNCHANGED 32-table disposal test.
const p010Overlay=read('supabase/tests/p1p5_v2_package0_future_state_overlay_disposable.sql');
const p010Assembler=read('scripts/p1p5-v2-package0-build-combined-probe.cjs');
const p010Workflow=read('.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml');
for(const section of ['SETUP','FIRST_DELETE','SECOND_DELETE','POST_ROLLBACK']) {
  assert(p010Overlay.includes('-- P0-10 SECTION '+section),
    'P0-10 overlay missing mandatory combined test section '+section);
}
for(const token of [
  'private.exam_prep_learner_exam_dates_v1',
  'private.exam_prep_periodic_study_report_receipts_v1',
  'ROLLBACK TO SAVEPOINT p0_unknown_future_fk_probe',
  'on delete restrict',
  'p0_future_before',
  'p0_future_selected_program',
  'receipts_fingerprint',
  'receipt retention remains NO_GO'
]) assert(p010Overlay.includes(token),'P0-10 prospective scope not tested: '+token);
assert(p010Assembler.includes('P1P5_E2E_ISOLATED') &&
       p010Assembler.includes("PGDATABASE === 'postgres'") &&
       p010Assembler.includes("assert.equal(found.length,65") &&
       p010Assembler.includes('wx'),
       'P0-10 test assembly must be limited to original isolated full-schema rollback');
assert(p010Workflow.includes('node scripts/p1p5-v2-package0-build-combined-probe.cjs') &&
       p010Workflow.includes('P0-10 real-schema 32-table plus future dates scoped reset') &&
       p010Workflow.includes('PGOPTIONS: -c iclub.e2e_isolated=true'),
       'P0-10 actual migrated PostgreSQL E2E is absent');
console.log('PASS P0-10 prospective state overlay and combined real-schema test authorization guard');


// P0-12 read-only RPC entrypoint inventory: NEVER use catalog metadata to
// authorize production cleanup or claim that nested write calls are all found.
const p012=read('supabase/tests/p1p5_v2_package0_write_entrypoints_readonly.sql');
assert(/--.*READ ONLY/i.test(p012),'P0-12 RPC audit must state READ ONLY');
assert(!/\b(?:insert|update|delete|truncate|drop|alter|create|grant|revoke|call|do|execute|copy|vacuum)\b/i.test(strip(p012)),
  'P0-12 production catalog inspection contains a non-SELECT statement');
for(const marker of [
  'pg_proc',
  'pg_get_functiondef',
  'has_function_privilege',
  'exam_prep_require_core_access_v1',
  'start_exam_prep_next_diagnostic_safe_v1',
  'submit_exam_prep_response_safe_v1',
  'finalize_exam_prep_session_safe_v1',
  'auth_contains_release_epoch_token',
  'public wrappers',
  'checks_epoch'
]) assert(p012.includes(marker),'P0-12 lacks safety audit coverage: '+marker);
console.log('PASS P0-12 read-only write-API/epoch coverage inventory, no live mutations');


// P0-13 real signed-JWT disposable epoch gate: never deploy as live RPC.
const p013=read('supabase/tests/p1p5_v2_package0_signed_epoch_http_disposable.sql');
const p013Http=read('scripts/p1p5-v2-package0-signed-old-epoch-http.cjs');
const p013E2e=read('.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml');
for(const token of [
  'DISPOSABLE PG17 ONLY','current_database()', 'iclub.e2e_isolated',
  '(SELECT count(*) FROM public.users)<>2','(SELECT count(*) FROM auth.users)<>2',
  'private.p0_13_epoch_gate','private.p0_13_fake_write_events',
  'private.p0_13_fake_authorizations','issued_attempt_epoch_mismatch',
  'FOR SHARE','stale_or_paused_academic_epoch','PT409',
  'REVOKE ALL ON FUNCTION public.p0_13_submit_signed_epoch_test_v1',
  'GRANT EXECUTE ON FUNCTION public.p0_13_submit_signed_epoch_test_v1'
]) assert(p013.includes(token),'P0-13 SQL fixture safety boundary missing: '+token);
assert(!/DELETE\s+FROM\s+(?:private\.exam_prep_|public\.)/i.test(p013),
  'P0-13 cannot delete any real assessment or public table');
assert(!/TRUNCATE|DISABLE\s+TRIGGER|session_replication_role|service_role/i.test(p013),
  'P0-13 must not bypass database protections');
for(const phrase of [
  "HOST='http://127.0.0.1:3000'","P1P5_E2E_ISOLATED",
  "PGDATABASE==='postgres'","phase==='before'","phase==='during'",
  'post-cutover stale tab','same key changed payload','foreign learner',
  'anonymous','bad JWT','PT409'
]) assert(p013Http.includes(phrase),'P0-13 signed HTTP coverage missing: '+phrase);
assert(p013Http.includes('tampered new epoch with old issued session') &&
       p013E2e.includes('epoch-two-request'),
  'P0-13 must reject spoofed epoch on an old issued authorization');
assert(p013Http.includes('P0_13_FIXED_IAT') && p013E2e.includes('export P0_13_FIXED_IAT'),
  'P0-13 must reuse exact still-valid pre-cutover learner JWT');
assert(p013E2e.includes('P0-13 signed old-device HTTP epoch') &&
       p013E2e.includes('p1p5_v2_package0_signed_epoch_http_disposable.sql'),
       'P0-13 real PostgREST/PG17 E2E workflow step absent');
console.log('PASS P0-13 real signed-JWT disposable epoch-only source/privilege guards');


// P0-14 two-connection release maintenance lock: no fake "sequential" proof.
const p014=read('scripts/p1p5-v2-package0-concurrent-epoch-lock.cjs');
const p014Flow=read('.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml');
for(const x of [
 'P1P5_E2E_ISOLATED','PGDATABASE','127.0.0.1','spawnSync',
 'P0_14_SHARE_LOCK_HELD','FOR SHARE','lock timeout',
 'UPDATE private.p0_13_epoch_gate SET paused=true',
 'P0_14_CLEAN','holder.stdin.end'
])assert(p014.includes(x),'P0-14 real-lock regression missing '+x);
assert(p014Flow.includes('P0-14 real two-session PG17 epoch maintenance lock race'),
       'P0-14 real-lock step absent from full JWT/PG17 workflow');
console.log('PASS P0-14 genuine two-connection lock gate is isolated and in full E2E');


// P0-15 read-only reachable call graph: RPC textual candidates, not authority.
const p015=read('supabase/tests/p1p5_v2_package0_rpc_write_graph_readonly.sql');
assert(/--.*READ ONLY/i.test(p015),'P0-15 must state READ ONLY');
assert(!/\b(?:insert|update|delete|truncate|drop|alter|create|grant|revoke|call|do|execute|copy|vacuum)\b/i.test(strip(p015)),
  'P0-15 catalog source has DML/DDL outside quoted patterns');
for(const token of [
 'WITH RECURSIVE','pg_proc','pg_get_functiondef','regexp_matches',
 'has_function_privilege','NOT e.target_oid=ANY(w.visited)',
 'authenticated_root_rpcs','indirect_only_dml_candidates',
 'write_candidates_without_named_core_guard',
 'write_candidates_with_named_epoch_marker','scope_warning',
 'regex excludes dynamic/unqualified calls'
])assert(p015.includes(token),'P0-15 missing tested read-only audit contract: '+token);
console.log('PASS P0-15 read-only authenticated direct/indirect RPC epoch coverage catalog guard');


// P0-16 six real Math RPCs guarded IN DISPOSABLE CI ONLY. Explicitly does not
// authorize release, claims no full 37-path closure and cannot target Supabase.
const p016sql=read('supabase/tests/p1p5_v2_package0_actual_rpc_epoch_shadow_disposable.sql');
const p016js=read('scripts/p1p5-v2-package0-real-rpc-epoch-http.cjs');
const p016flow=read('.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml');
for(const token of [
 'ABSOLUTELY DISPOSABLE PG17 ONLY', 'current_database()', 'iclub.e2e_isolated',
 "(SELECT count(*) FROM public.users)<>2", "(SELECT count(*) FROM auth.users)<>2",
 'private.p0_16_academic_epoch_gate', 'private.p0_16_require_current_epoch_v1',
 "current_setting('request.jwt.claims',true)", 'FOR SHARE',
 'p0_16_old_signed_jwt', 'p0_16_stale_session_epoch',
 'p0_16_stamp_new_session_fixture', 'p0_16_issued_epoch',
 'v_count<>6', 'refusing RPC source drift', 'anon,authenticated'
]) assert(p016sql.includes(token),'P0-16 real RPC shadow risk guard missing: '+token);
for(const route of [
 'public.save_exam_prep_exam_profile_v2',
 'public.start_exam_prep_next_diagnostic_safe_v1',
 'public.authorize_exam_prep_timed_safe_v1',
 'public.start_exam_prep_session_safe_v1',
 'public.submit_exam_prep_response_safe_v1',
 'public.finalize_exam_prep_session_safe_v1'
]) assert(p016sql.includes(route),'P0-16 real RPC test omission: '+route);
assert(!/DELETE\s+FROM\s+(?:private\.exam_prep_|public\.)|TRUNCATE|DISABLE\s+TRIGGER|session_replication_role/i.test(p016sql),
  'P0-16 must not delete any real academic facts or bypass protections');
for(const marker of [
  "HOST='http://127.0.0.1:3000'", "P1P5_E2E_ISOLATED",
  "PGDATABASE==='postgres'", 'OLD_IAT', 'phase===',
  'fresh JWT trying stale server-issued session','same', // source-wide literal
  'six=[profile,next,timed,start,answer,finalize]'
]) assert(p016js.includes(marker),'P0-16 real-signed-HTTP test coverage missing: '+marker);
assert(p016flow.includes('P0-16 REAL six Math public RPCs') &&
       p016flow.includes('p1p5_v2_package0_actual_rpc_epoch_shadow_disposable.sql') &&
       p016flow.includes('P0_16_OLD_IAT') &&
       p016flow.includes('P0_16_STALE_SESSION_ID'),
       'P0-16 actual full-stack E2E test is not wired');
console.log('PASS P0-16 isolated six-actual-RPC JWT/session epoch test source bounds; 37+ others still NO_GO');
