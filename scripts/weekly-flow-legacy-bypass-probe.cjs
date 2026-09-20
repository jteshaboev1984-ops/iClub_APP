'use strict';
// EXPECTED-FAILURE SAFETY PROBE, isolated atomic-candidate tests and rollback rehearsal.
// Requires committed SYNTHETIC fixture from weekly-flow-two-connection.cjs.
// Every SQL write here is REFUSED outside disposable GitHub Actions PostgreSQL.
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const env = process.env;
if (env.GITHUB_ACTIONS !== 'true' || env.PGHOST !== '127.0.0.1' ||
    env.PGDATABASE !== 'postgres' || !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
  console.error('REFUSED: legacy bypass and rollback probe run only in disposable GitHub Actions PostgreSQL.');
  process.exit(1);
}
function execute(statement) {
  return spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
    env,encoding:'utf8',input:statement,timeout:30000
  });
}
function sql(statement) {
  const result=execute(statement);
  assert.equal(result.status,0,`Disposable SQL failed: ${(result.stderr||'').slice(-1200)}`);
  return result.stdout;
}
function named(output,marker) {
  const matches=output.split(/\r?\n/).filter(line=>line.startsWith(marker+'='));
  assert.equal(matches.length,1,`Expected exactly one ${marker} marker`);
  return matches[0].slice(marker.length+1);
}
const counts=`SELECT 'COUNTS=' ||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
FROM weekly_goal_ci.fixture f;`;
const before=named(sql(counts),'COUNTS');
assert.equal(before,'1:1:1','Expected completed synthetic two-backend fixture');
const output=sql(`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'LEGACY='||public.start_exam_prep_session_safe_v1(
  (SELECT a.id FROM private.exam_prep_session_authorizations a
   JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),
  'isolated-legacy-finalized-replay')::text;
SELECT 'GUARDED='||public.start_exam_prep_plan_session_once_safe_v1(
  (SELECT a.id FROM private.exam_prep_session_authorizations a
   JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),
  'isolated-guarded-finalized-replay')::text;
ROLLBACK;`);
const legacy=JSON.parse(named(output,'LEGACY'));
const guarded=JSON.parse(named(output,'GUARDED'));
assert.equal(legacy.status,'finalized','Legacy contract changed: re-audit first');
assert.match(legacy.session_id||'',/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i);
assert.equal(guarded.status,'attempt_already_saved');
assert.equal(Object.hasOwn(guarded,'session_id'),false);
const def=sql(`SELECT 'DIRECT=' ||
 (position('public.generate_exam_prep_weekly_plan_safe_v2' in pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v3(text)'::regprocedure))>0)::text || ':' ||
 (position('set status=''superseded''' in pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v2(text)'::regprocedure))>0)::text;`);
assert.equal(named(def,'DIRECT'),'true:true','Legacy generator shape changed: re-audit first');
assert.equal(named(sql(counts),'COUNTS'),before,'Baseline observation unexpectedly changed synthetic fixture');
console.log('BLOCKER REPRODUCED: old starter returns a finalized ID; old generator can supersede plans.');

// Snapshot seven exact public definitions BEFORE candidate installation. Four
// are deployed Core entrypoints and three are draft RPCs modified by dispatch.
// A private v3 clone is NOT a valid rollback source: it delegates to private v2.
const baseline=sql(`
CREATE TABLE weekly_goal_ci.rpc_restore_baseline AS
WITH required(ordinal,signature) AS (VALUES
 (1,'public.generate_exam_prep_weekly_plan_safe_v2(text)'),
 (2,'public.generate_exam_prep_weekly_plan_safe_v3(text)'),
 (3,'public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)'),
 (4,'public.start_exam_prep_session_safe_v1(uuid,text)'),
 (5,'public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'),
 (6,'public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)'),
 (7,'public.start_exam_prep_plan_session_once_safe_v1(uuid,text)')
)
SELECT r.ordinal,r.signature,p.oid AS function_oid,
 pg_get_functiondef(p.oid) AS original_definition,
 md5(pg_get_functiondef(p.oid)) AS original_md5,
 p.proacl::text AS original_acl,p.proowner AS original_owner,
 p.prosecdef AS original_security,p.provolatile AS original_volatility
FROM required r JOIN pg_proc p ON p.oid=to_regprocedure(r.signature);
SELECT 'BASELINE='||count(*) FROM weekly_goal_ci.rpc_restore_baseline;`);
assert.equal(named(baseline,'BASELINE'),'7','All seven original public functions required');
console.log('Captured seven original public function definitions/permissions in disposable-only fixture.');
console.log('Applying review-only atomic candidate to DISPOSABLE PG17.');
const candidate=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-f',
  'docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql'],{
    env,encoding:'utf8',timeout:30000
  });
assert.equal(candidate.status,0,`Atomic candidate SQL refused: ${(candidate.stderr||'').slice(-2500)} ${(candidate.stdout||'').slice(-700)}`);
console.log('Atomic SQL compiled in disposable PG17; no enrollments.');
for(const script of ['scripts/weekly-flow-atomic-dispatch-smoke.cjs',
                     'scripts/weekly-flow-atomic-dispatch-race.cjs',
                     'scripts/weekly-flow-atomic-dispatch-nonplan.cjs']) {
  const check=spawnSync(process.execPath,['--check',script],{env,encoding:'utf8',timeout:10000});
  assert.equal(check.status,0,`Syntax invalid ${script}: ${(check.stderr||'').slice(-600)}`);
  const test=spawnSync(process.execPath,[script],{env,encoding:'utf8',timeout:90000});
  if(test.stdout) process.stdout.write(test.stdout);
  assert.equal(test.status,0,`Isolated candidate test ${script} failed: ${(test.stderr||'').slice(-2500)}`);
}
console.log('ATOMIC CANDIDATE ISOLATED GREEN only. Live old RPC bypass remains a deployment blocker.');
for(const file of [
  'docs/patch-proposals/20260920_exam_prep_previous_week_adherence_readonly_v1.sql',
  'supabase/tests/exam_prep_previous_week_adherence_isolated_matrix.sql'
]) {
  const check=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-f',file],{
    env,encoding:'utf8',timeout:60000
  });
  if(check.stdout) process.stdout.write(check.stdout.slice(-2500));
  assert.equal(check.status,0,`Isolated prior-week adherence failed in ${file}: ${(check.stderr||'').slice(-3000)}`);
}
console.log('PREVIOUS WEEK ADHERENCE isolated SQL GREEN: synthetic learner rolled back.');
assert.equal(named(sql(counts),'COUNTS'),before,'Candidate tests changed existing synthetic academic fixture');

// Verify a rollback refuses to run while Core is enabled or any learner is
// enrolled. Feature flag OFF and separate consent are mandatory release gates.
const rollbackGuard=`DO $guard$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM private.exam_prep_feature_config
     WHERE program_key='math_as_p1_p5' AND rollout_state='off'
       AND core_enabled IS FALSE AND kill_switch IS TRUE) THEN
   RAISE EXCEPTION 'rollback_requires_core_off';
 END IF;
 IF EXISTS (SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE) THEN
   RAISE EXCEPTION 'rollback_requires_zero_enrolled_learners';
 END IF;
 IF (SELECT count(*) FROM weekly_goal_ci.rpc_restore_baseline)<>7 THEN
   RAISE EXCEPTION 'rollback_requires_complete_original_snapshot';
 END IF;
END;
$guard$;`;
const refused=execute(`BEGIN;${rollbackGuard}ROLLBACK;`);
assert.notEqual(refused.status,0,'Rollback must refuse while Core is enabled');
assert.match(refused.stderr||'',/rollback_requires_core_off/);
console.log('Rollback refused while Core enabled, without modifying a public function.');

// Simulate flag OFF + restoration IN ONE TRANSACTION, then roll the rehearsal
// transaction BACK so the candidate remains installed for the next positive
// first-plan test. Restoring all seven public bodies by COMMIT is a separate,
// explicitly authorized production operation, NOT performed here.
const restored=sql(`BEGIN;
UPDATE private.exam_prep_feature_config SET rollout_state='off',
 core_enabled=false,ai_enabled=false,mentor_enabled=false,kill_switch=true
 WHERE program_key='math_as_p1_p5';
${rollbackGuard}
DO $restore$
DECLARE v_fn record;
BEGIN
 FOR v_fn IN SELECT * FROM weekly_goal_ci.rpc_restore_baseline ORDER BY ordinal LOOP
   EXECUTE v_fn.original_definition;
 END LOOP;
END;
$restore$;
DO $verify$
DECLARE v_bad integer;
BEGIN
 SELECT count(*) INTO v_bad FROM weekly_goal_ci.rpc_restore_baseline b
 LEFT JOIN pg_proc p ON p.oid=b.function_oid
 WHERE p.oid IS NULL OR md5(pg_get_functiondef(p.oid)) IS DISTINCT FROM b.original_md5
   OR p.proacl::text IS DISTINCT FROM b.original_acl
   OR p.proowner IS DISTINCT FROM b.original_owner
   OR p.prosecdef IS DISTINCT FROM b.original_security
   OR p.provolatile IS DISTINCT FROM b.original_volatility;
 IF v_bad<>0 THEN RAISE EXCEPTION 'rollback_did_not_restore_exact_public_functions: %',v_bad; END IF;
 IF EXISTS (SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE)
 THEN RAISE EXCEPTION 'rollback_left_enrolled_learners'; END IF;
END;
$verify$;
SELECT 'RESTORED='||count(*) FROM weekly_goal_ci.rpc_restore_baseline b
JOIN pg_proc p ON p.oid=b.function_oid
WHERE md5(pg_get_functiondef(p.oid))=b.original_md5
 AND p.proacl::text IS NOT DISTINCT FROM b.original_acl;
ROLLBACK;`);
assert.equal(named(restored,'RESTORED'),'7','Seven public RPC bodies/grants were not restored inside rehearsal');
assert.equal(named(sql(counts),'COUNTS'),before,'Rehearsal rollback altered synthetic student records');
const post=sql(`SELECT 'CANDIDATE='||count(*) FROM weekly_goal_ci.rpc_restore_baseline b
 JOIN pg_proc p ON p.oid=b.function_oid
 WHERE md5(pg_get_functiondef(p.oid)) IS DISTINCT FROM b.original_md5;`);
assert.equal(named(post,'CANDIDATE'),'7','Uncommitted restoration must not replace the seven candidate RPCs');
console.log('ROLLBACK REHEARSAL GREEN: exact seven originals restored within transaction, then rolled back; candidate remains for next test.');
console.log('Production compatibility SQL, rollback and rollout remain BLOCKED pending separate approval.');
