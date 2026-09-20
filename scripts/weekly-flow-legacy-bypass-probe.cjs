'use strict';
// Candidate install and rollback are rehearsed ONLY on disposable CI PostgreSQL.
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
   !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')){
  console.error('REFUSED: disposable CI database only.');process.exit(1);
}
function execute(text){return spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],
  {env,encoding:'utf8',input:text,timeout:30000});}
function sql(text){const r=execute(text);assert.equal(r.status,0,`Disposable SQL failed: ${(r.stderr||'').slice(-1300)}`);return r.stdout;}
function named(out,key){const a=out.split(/\r?\n/).filter(x=>x.startsWith(key+'='));
  assert.equal(a.length,1,`Expected one ${key}`);return a[0].slice(key.length+1);}
const counts=`SELECT 'COUNTS='||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
 FROM weekly_goal_ci.fixture f;`;
const before=named(sql(counts),'COUNTS');
assert.equal(before,'1:1:1','Expected completed synthetic two-connection fixture');
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
assert.equal(legacy.status,'finalized','Legacy replay behavior changed');
assert.match(legacy.session_id||'',/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i);
assert.equal(guarded.status,'attempt_already_saved');
assert.equal(Object.hasOwn(guarded,'session_id'),false);
const legacyDef=`SELECT 'DIRECT='||
 (position('public.generate_exam_prep_weekly_plan_safe_v2' in pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v3(text)'::regprocedure))>0)::text||':'||
 (position('set status=''superseded''' in pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v2(text)'::regprocedure))>0)::text;`;
assert.equal(named(sql(legacyDef),'DIRECT'),'true:true');
assert.equal(named(sql(counts),'COUNTS'),before);
console.log('BLOCKER REPRODUCED: legacy finalized ID and superseding generator.');

// Save exact originals, not rewritten private copies. Four deployed Core and
// three proposed guarded public functions must all be restored together.
const snapshot=sql(`CREATE TABLE weekly_goal_ci.rpc_restore_baseline AS
WITH required(ordinal,signature) AS (VALUES
 (1,'public.generate_exam_prep_weekly_plan_safe_v2(text)'),
 (2,'public.generate_exam_prep_weekly_plan_safe_v3(text)'),
 (3,'public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)'),
 (4,'public.start_exam_prep_session_safe_v1(uuid,text)'),
 (5,'public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'),
 (6,'public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)'),
 (7,'public.start_exam_prep_plan_session_once_safe_v1(uuid,text)'))
SELECT r.ordinal,r.signature,p.oid AS function_oid,
 pg_get_functiondef(p.oid) AS original_definition,
 md5(pg_get_functiondef(p.oid)) AS original_md5,
 p.proacl::text AS original_acl,p.proowner AS original_owner,
 p.prosecdef AS original_security,p.provolatile AS original_volatility
FROM required r JOIN pg_proc p ON p.oid=to_regprocedure(r.signature);
SELECT 'BASELINE='||count(*) FROM weekly_goal_ci.rpc_restore_baseline;`);
assert.equal(named(snapshot,'BASELINE'),'7','Incomplete original RPC snapshot');
const candidate=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-f',
 'docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql'],
 {env,encoding:'utf8',timeout:30000});
assert.equal(candidate.status,0,`Isolated candidate refused: ${(candidate.stderr||'').slice(-2500)}`);
for(const file of ['scripts/weekly-flow-atomic-dispatch-smoke.cjs',
 'scripts/weekly-flow-atomic-dispatch-race.cjs','scripts/weekly-flow-atomic-dispatch-nonplan.cjs']){
 const check=spawnSync(process.execPath,['--check',file],{env,encoding:'utf8',timeout:10000});
 assert.equal(check.status,0,`Bad syntax ${file}`);
 const test=spawnSync(process.execPath,[file],{env,encoding:'utf8',timeout:90000});
 if(test.stdout)process.stdout.write(test.stdout);
 assert.equal(test.status,0,`Isolated ${file} failed: ${(test.stderr||'').slice(-2500)}`);
}
console.log('ATOMIC CANDIDATE ISOLATED GREEN. Live bypass remains until separate approval.');
for(const file of ['docs/patch-proposals/20260920_exam_prep_previous_week_adherence_readonly_v1.sql',
 'supabase/tests/exam_prep_previous_week_adherence_isolated_matrix.sql']){
 const t=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-f',file],{env,encoding:'utf8',timeout:60000});
 if(t.stdout)process.stdout.write(t.stdout.slice(-1500));
 assert.equal(t.status,0,`Adherence test failed: ${(t.stderr||'').slice(-3000)}`);
}
assert.equal(named(sql(counts),'COUNTS'),before,'Academic fixture changed');

// Neither core-enabled nor enrolled-user rollback is permitted. The prior
// synthetic race/smoke creates enrolled rows: retain them for both denial tests.
const flagOff=`UPDATE private.exam_prep_feature_config SET rollout_state='off',
 core_enabled=false,ai_enabled=false,mentor_enabled=false,kill_switch=true
 WHERE program_key='math_as_p1_p5';`;
const guard=`DO $guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
  AND core_enabled IS FALSE AND kill_switch IS TRUE) THEN
  RAISE EXCEPTION 'rollback_requires_core_off'; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1
  WHERE enabled IS TRUE) THEN RAISE EXCEPTION 'rollback_requires_zero_enrolled_learners'; END IF;
 IF (SELECT count(*) FROM weekly_goal_ci.rpc_restore_baseline)<>7 THEN
  RAISE EXCEPTION 'rollback_requires_complete_original_snapshot'; END IF;
END;$guard$;`;
const refused=execute(`BEGIN;${guard}ROLLBACK;`);
assert.notEqual(refused.status,0);assert.match(refused.stderr||'',/rollback_requires_core_off/);
const enrolled=Number(named(sql(`SELECT 'ENROLLED='||count(*) FROM
 private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE;`),'ENROLLED'));
assert.ok(enrolled>0,'Synthetic approved enrollments required for refusal test');
const refusedEnrolled=execute(`BEGIN;${flagOff}${guard}ROLLBACK;`);
assert.notEqual(refusedEnrolled.status,0);
assert.match(refusedEnrolled.stderr||'',/rollback_requires_zero_enrolled_learners/);
console.log('Rollback correctly denied for active Core AND, separately, active enrolled learners.');

// In one reversible transaction simulate explicit synthetic unenrollment,
// restore original bodies, ownership and grants, verify, then ROLLBACK so the
// candidate stays available for the subsequent positive Stage 0->plan test.
const restored=sql(`BEGIN;
${flagOff}
UPDATE private.exam_prep_weekly_flow_enrollment_v1 SET enabled=false WHERE enabled IS TRUE;
${guard}
DO $restore$
DECLARE r record;
BEGIN
 FOR r IN SELECT * FROM weekly_goal_ci.rpc_restore_baseline ORDER BY ordinal LOOP
  EXECUTE r.original_definition;
 END LOOP;
END;$restore$;
DO $verify$
DECLARE invalid integer;
BEGIN
 SELECT count(*) INTO invalid FROM weekly_goal_ci.rpc_restore_baseline b
 LEFT JOIN pg_proc p ON p.oid=b.function_oid
 WHERE p.oid IS NULL OR md5(pg_get_functiondef(p.oid)) IS DISTINCT FROM b.original_md5
  OR p.proacl::text IS DISTINCT FROM b.original_acl
  OR p.proowner IS DISTINCT FROM b.original_owner
  OR p.prosecdef IS DISTINCT FROM b.original_security
  OR p.provolatile IS DISTINCT FROM b.original_volatility;
 IF invalid<>0 THEN RAISE EXCEPTION 'rollback_exact_public_functions_failed: %',invalid; END IF;
END;$verify$;
SELECT 'RESTORED='||count(*) FROM weekly_goal_ci.rpc_restore_baseline;
ROLLBACK;`);
assert.equal(named(restored,'RESTORED'),'7','Exact restoration not proven');
assert.equal(named(sql(counts),'COUNTS'),before,'Rollback rehearsal touched learner records');
assert.equal(Number(named(sql(`SELECT 'ENROLLED='||count(*) FROM
 private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE;`),'ENROLLED')),enrolled,
 'Rehearsal must retain approved synthetic enrollments');
// Evaluate ONLY the seven captured OIDs: scanning pg_proc with a pushed-down
// pg_get_functiondef predicate can hit aggregate OIDs and abort incorrectly.
const post=sql(`SELECT 'CANDIDATE='||count(*) FROM weekly_goal_ci.rpc_restore_baseline b
 WHERE md5(pg_get_functiondef(b.function_oid)) IS DISTINCT FROM b.original_md5;`);
assert.equal(named(post,'CANDIDATE'),'7','Rehearsal transaction must leave candidate in place');
console.log('ROLLBACK REHEARSAL GREEN: seven exact public definitions restored transactionally, then rehearsal rolled back.');
console.log('Live SQL, deployment and enrollments NOT approved or changed.');
