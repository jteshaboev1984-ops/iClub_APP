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
const targets=[...full.matchAll(/DELETE FROM private\.(exam_prep_\w+)/g)].map(x=>x[1]);
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
