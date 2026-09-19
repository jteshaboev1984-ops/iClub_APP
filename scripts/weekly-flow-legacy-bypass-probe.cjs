'use strict';
// EXPECTED-FAILURE SAFETY PROBE followed by isolated atomic-candidate tests.
// Requires committed SYNTHETIC fixture from weekly-flow-two-connection.cjs.
// Candidate SQL runs only in disposable PG17; NEVER on production.
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const env = process.env;
if (env.GITHUB_ACTIONS !== 'true' || env.PGHOST !== '127.0.0.1' ||
    env.PGDATABASE !== 'postgres' || !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
  console.error('REFUSED: legacy bypass probe runs only in disposable GitHub Actions PostgreSQL.');
  process.exit(1);
}
function sql(statement) {
  const result=spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
    env,encoding:'utf8',input:statement,timeout:30000
  });
  assert.equal(result.status,0,`Disposable SQL failed: ${(result.stderr||'').slice(-800)}`);
  return result.stdout;
}
function named(output,marker) {
  const matches=output.split(/\r?\n/).filter(line=>line.startsWith(marker+'='));
  assert.equal(matches.length,1,`Expected exactly one ${marker} marker`);
  return matches[0].slice(marker.length+1);
}
const before=named(sql(`
SELECT 'COUNTS=' ||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
FROM weekly_goal_ci.fixture f;`),'COUNTS');
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
const after=named(sql(`
SELECT 'COUNTS=' ||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
FROM weekly_goal_ci.fixture f;`),'COUNTS');
assert.equal(after,before,'Baseline observation unexpectedly changed synthetic fixture');
console.log('BLOCKER REPRODUCED: old starter returns a finalized ID; old generator can supersede plans.');
console.log('Applying review-only atomic candidate to DISPOSABLE PG17.');
const candidate=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-f',
  'docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql'],{
    env,encoding:'utf8',timeout:30000
  });
assert.equal(candidate.status,0,`Atomic candidate SQL refused: ${(candidate.stderr||'').slice(-2500)} ${(candidate.stdout||'').slice(-700)}`);
console.log('Atomic SQL transaction compiled in disposable PG17; no enrollments.');
for(const script of ['scripts/weekly-flow-atomic-dispatch-smoke.cjs',
                     'scripts/weekly-flow-atomic-dispatch-race.cjs']) {
  const check=spawnSync(process.execPath,['--check',script],{env,encoding:'utf8',timeout:10000});
  assert.equal(check.status,0,`Syntax invalid ${script}: ${(check.stderr||'').slice(-600)}`);
  const test=spawnSync(process.execPath,[script],{env,encoding:'utf8',timeout:90000});
  if(test.stdout) process.stdout.write(test.stdout);
  assert.equal(test.status,0,`Isolated candidate test ${script} failed: ${(test.stderr||'').slice(-2500)}`);
}
console.log('ATOMIC CANDIDATE ISOLATED GREEN only. Live old RPC bypass remains a deployment blocker.');
