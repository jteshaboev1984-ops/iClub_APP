'use strict';
// DISPOSABLE PG17 ONLY. Invoked AFTER applying review-only atomic dispatch SQL.
// Uses synthetic fixture from weekly-flow-two-connection.cjs; never contacts live DB.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const env = process.env;
if (env.GITHUB_ACTIONS !== 'true' || env.PGHOST !== '127.0.0.1' ||
    env.PGDATABASE !== 'postgres' || !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
  console.error('REFUSED: only disposable GitHub Actions PostgreSQL can test dispatch.');
  process.exit(1);
}
function psql(input) {
  return new Promise((resolve,reject) => {
    const child = spawn('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
      env,stdio:['pipe','pipe','pipe']
    });
    let out='',error='';
    child.stdout.on('data',data=>out+=data);
    child.stderr.on('data',data=>error+=data);
    child.on('error',reject);
    child.on('close',code=>code===0?resolve(out):reject(new Error(`Isolated SQL exit ${code}: ${error.slice(-1000)}`)));
    child.stdin.end(input);
  });
}
function value(output,name) {
  const rows = output.split(/\r?\n/).filter(x=>x.startsWith(name+'='));
  assert.equal(rows.length,1,`Expected exactly one ${name} in isolated output`);
  return rows[0].slice(name.length+1);
}
const preface=`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'BACKEND='||pg_backend_pid();
`;
const authQuery = (name,expr,pause=false)=>`${preface}\nSELECT '${name}='||(${expr});\n${pause?'SELECT pg_sleep(0.25);':''}\nCOMMIT;`;
const counts=`(SELECT count(*)::text FROM private.exam_prep_weekly_plans WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))||':'||
(SELECT count(*)::text FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))||':'||
(SELECT count(*)::text FROM private.exam_prep_sessions WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))`;
(async()=>{
  const empty=await psql('SELECT \'ENROLLED=\'||count(*) FROM private.exam_prep_weekly_flow_enrollment_v1;');
  assert.equal(value(empty,'ENROLLED'),'0','Atomic proposal must not enroll a real or synthetic user by default');
  const off = await psql(`${preface}
SELECT 'LEGACY_OFF='||public.start_exam_prep_session_safe_v1(
  (SELECT id FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture)),
  'synthetic-off-legacy-replay')::text;
DO $check$ BEGIN
  BEGIN
    PERFORM public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
    RAISE EXCEPTION 'FAILED: new RPC worked without server enrollment';
  EXCEPTION WHEN sqlstate '42501' THEN NULL;
  END;
END $check$;
SELECT 'NO_ENROLLMENT='||(SELECT count(*) FROM private.exam_prep_weekly_flow_enrollment_v1)::text;
ROLLBACK;`);
  const oldOff=JSON.parse(value(off,'LEGACY_OFF'));
  assert.equal(oldOff.status,'finalized');
  assert.ok(oldOff.session_id,'Old interface must remain intact until explicitly enrolled');
  assert.equal(value(off,'NO_ENROLLMENT'),'0');
  console.log('PASS default OFF: legacy endpoint unchanged; new RPC denied without server approval.');

  await psql(`BEGIN;
INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
SELECT user_id,true,'00000000-0000-4000-8000-000000000001'::uuid,clock_timestamp()
FROM weekly_goal_ci.fixture;
COMMIT;`);
  const first=authQuery('OLD_PLAN',`public.generate_exam_prep_weekly_plan_safe_v3('P1')::text`,true);
  const second=authQuery('NEW_PLAN',`public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1')::text`,true);
  const [oldOutput,newOutput]=await Promise.all([psql(first),psql(second)]);
  assert.notEqual(value(oldOutput,'BACKEND'),value(newOutput,'BACKEND'));
  const oldPlan=JSON.parse(value(oldOutput,'OLD_PLAN'));
  const newPlan=JSON.parse(value(newOutput,'NEW_PLAN'));
  assert.equal(oldPlan.plan_id,newPlan.plan_id);
  assert.equal(oldPlan.status,'existing'); assert.equal(newPlan.status,'existing');
  const firstId=value(await psql("SELECT 'PLAN='||plan_id::text FROM weekly_goal_ci.fixture;"),'PLAN');
  assert.equal(oldPlan.plan_id,firstId,'Legacy/new race must not replace the student plan');
  console.log('PASS real two-backend legacy-v3 vs new-stable race: single original plan.');

  const result=await psql(`${preface}
SELECT 'OLD_V2='||public.generate_exam_prep_weekly_plan_safe_v2('P1')::text;
SELECT 'OLD_AUTH='||public.authorize_exam_prep_plan_item_safe_v1(
  (SELECT plan_id FROM weekly_goal_ci.fixture),1)::text;
SELECT 'OLD_START='||public.start_exam_prep_session_safe_v1(
  (SELECT id FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture)),
  'synthetic-on-legacy-finalized-replay')::text;
SELECT 'NEW_START='||public.start_exam_prep_plan_session_once_safe_v1(
  (SELECT id FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture)),
  'synthetic-on-new-finalized-replay')::text;
SELECT 'COUNTS='||${counts};
ROLLBACK;`);
  assert.equal(JSON.parse(value(result,'OLD_V2')).plan_id,firstId);
  const denied=JSON.parse(value(result,'OLD_AUTH'));
  assert.equal(denied.status,'goal_identity_required');
  assert.equal(Object.hasOwn(denied,'authorization_id'),false);
  for(const marker of ['OLD_START','NEW_START']) {
    const attempt=JSON.parse(value(result,marker));
    assert.equal(attempt.status,'attempt_already_saved',`${marker} reopened a finalized attempt`);
    assert.equal(Object.hasOwn(attempt,'session_id'),false,`${marker} leaked a finalized session ID`);
  }
  assert.equal(value(result,'COUNTS'),'1:1:1','Dispatch created new plans, authorizations or attempts');
  console.log('PASS enrolled user: old numeric authorization denied; old and new finalized replay expose no ID.');
  console.log('ATOMIC DISPATCH ISOLATED GREEN: server enrollment defaults OFF and both public generators serialize; production untouched.');
})().catch(error=>{console.error(error);process.exitCode=1;});
