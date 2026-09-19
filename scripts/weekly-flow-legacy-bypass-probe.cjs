'use strict';
// EXPECTED-FAILURE SAFETY PROBE followed by an isolated candidate fix test.
// Requires committed SYNTHETIC fixture from weekly-flow-two-connection.cjs.
// Candidate SQL runs only in the disposable service; NEVER on production.
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const env = process.env;
if (env.GITHUB_ACTIONS !== 'true' || env.PGHOST !== '127.0.0.1' ||
    env.PGDATABASE !== 'postgres' || !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
  console.error('REFUSED: legacy bypass probe runs only in the disposable GitHub Actions PostgreSQL service.');
  process.exit(1);
}
function sql(statement) {
  const result = spawnSync('psql', ['-X', '-q', '-A', '-t', '-v', 'ON_ERROR_STOP=1'], {
    env, encoding: 'utf8', input: statement, timeout: 30000
  });
  assert.equal(result.status, 0, `Disposable SQL failed: ${(result.stderr || '').slice(-800)}`);
  return result.stdout;
}
function named(output, marker) {
  const matches = output.split(/\r?\n/).filter(line => line.startsWith(marker + '='));
  assert.equal(matches.length, 1, `Expected exactly one ${marker} marker`);
  return matches[0].slice(marker.length + 1);
}
const before = named(sql(`
SELECT 'COUNTS=' ||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
FROM weekly_goal_ci.fixture f;`), 'COUNTS');
assert.equal(before, '1:1:1', 'Expected the completed two-backend synthetic test fixture');
const output = sql(`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'LEGACY=' || public.start_exam_prep_session_safe_v1(
  (SELECT a.id FROM private.exam_prep_session_authorizations a
   JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),
  'isolated-legacy-finalized-replay')::text;
SELECT 'GUARDED=' || public.start_exam_prep_plan_session_once_safe_v1(
  (SELECT a.id FROM private.exam_prep_session_authorizations a
   JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),
  'isolated-guarded-finalized-replay')::text;
ROLLBACK;`);
const legacy = JSON.parse(named(output,'LEGACY'));
const guarded = JSON.parse(named(output,'GUARDED'));
assert.equal(legacy.status,'finalized','The legacy endpoint behavior changed: re-audit first');
assert.match(legacy.session_id || '', /^[0-9a-f]{8}-[0-9a-f-]{27,}$/i,
  'Legacy must expose the finalized ID to prove the known bypass');
assert.equal(guarded.status,'attempt_already_saved');
assert.equal(Object.hasOwn(guarded,'session_id'),false);
const def = sql(`SELECT 'DIRECT=' ||
 (position('public.generate_exam_prep_weekly_plan_safe_v2' in pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v3(text)'::regprocedure))>0)::text || ':' ||
 (position('set status=''superseded''' in pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v2(text)'::regprocedure))>0)::text;`);
assert.equal(named(def,'DIRECT'),'true:true',
  'Legacy v3/v2 generator bypass is no longer in this shape: re-audit its exact contract');
const after = named(sql(`
SELECT 'COUNTS=' ||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
FROM weekly_goal_ci.fixture f;`), 'COUNTS');
assert.equal(after,before,'Bypass observation unexpectedly changed the synthetic fixture');
console.log('BLOCKER REPRODUCED: old session start returns a finalized ID; the old generator can supersede plans.');
console.log('Applying the review-only atomic compatibility candidate to DISPOSABLE PG17 only.');
const candidate = spawnSync('psql', ['-X','-v','ON_ERROR_STOP=1','-f',
  'docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql'], {
  env,encoding:'utf8',timeout:30000
});
assert.equal(candidate.status,0,`Atomic candidate rejected by disposable SQL: ${(candidate.stderr||'').slice(-2500)} ${(candidate.stdout||'').slice(-700)}`);
console.log('Candidate transaction compiled and committed in disposable PG17; zero enrollments.');
const smoke = spawnSync(process.execPath,['scripts/weekly-flow-atomic-dispatch-smoke.cjs'],{
  env,encoding:'utf8',timeout:90000
});
if(smoke.stdout) process.stdout.write(smoke.stdout);
assert.equal(smoke.status,0,`Candidate smoke failed: ${(smoke.stderr||'').slice(-2500)}`);
console.log('CANDIDATE ISOLATED GREEN only. Live legacy bypass is STILL a deployment blocker.');
