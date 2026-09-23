'use strict';
// NEVER run against production. This seeds committed synthetic rows only in a
// GitHub Actions disposable postgres:17 service and exercises TWO real backends.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const env = process.env;
if (!env.PGOPTIONS?.includes('weekly_goal.isolated_db=true') || env.GITHUB_ACTIONS !== 'true' ||
    env.PGHOST !== '127.0.0.1' || env.PGDATABASE !== 'postgres') {
  console.error('REFUSED: real two-backend test requires GitHub Actions isolated DB guard.');
  process.exit(1);
}
const ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function psql(sql, file = false) {
  return new Promise((resolve, reject) => {
    const args = ['-X', '-q', '-A', '-t', '-v', 'ON_ERROR_STOP=1'];
    if (file) args.push('-f', sql);
    const child = spawn('psql', args, { env, stdio: [file ? 'ignore' : 'pipe', 'pipe', 'pipe'] });
    let out = '', err = '';
    child.stdout.on('data', chunk => { out += chunk; });
    child.stderr.on('data', chunk => { err += chunk; });
    child.on('error', reject);
    child.on('close', code => code === 0 ? resolve(out) : reject(new Error(`psql exit ${code}: ${err.slice(-2500)}`)));
    if (!file) child.stdin.end(sql);
  });
}
const authPrefix = `BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'BACKEND='||pg_backend_pid();
`;
const authenticated = (label, expr, pause = true) => `${authPrefix}
SELECT '${label}='||(${expr});
${pause ? 'SELECT pg_sleep(0.30);' : ''}
COMMIT;
`;
function field(output, name) {
  const values = output.split(/\r?\n/).filter(line => line.startsWith(name + '=')).map(line => line.slice(name.length + 1));
  assert.equal(values.length, 1, `Expected one ${name}: ${output.slice(-250)}`);
  return values[0];
}
async function pair(label, expr, pause = true) {
  const sql = authenticated(label, expr, pause);
  const [a, b] = await Promise.all([psql(sql), psql(sql)]);
  const backends = [field(a,'BACKEND'),field(b,'BACKEND')];
  assert.notEqual(backends[0], backends[1], 'Test did not use independent PostgreSQL backends');
  return [field(a,label),field(b,label)];
}
(async () => {
  await psql('SELECT 1;', false);
  await psql('supabase/tests/exam_prep_weekly_flow_concurrent_seed.sql', true);
  const planExpr = `(public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1')->>'plan_id')`;
  const [planA,planB] = await pair('PLAN',planExpr);
  assert.match(planA,ID); assert.equal(planA,planB);
  const initial = field(await psql("SELECT 'INITIAL='||plan_id::text FROM weekly_goal_ci.fixture;"),'INITIAL');
  assert.equal(planA,initial,'Two readers must retain the initial weekly plan');
  console.log('GREEN real two-backend plan: one stable plan ID');

  const goalExpr = `(public.authorize_exam_prep_goal_once_safe_v1('P1',
    (SELECT goal_id FROM weekly_goal_ci.fixture),
    (SELECT plan_id FROM weekly_goal_ci.fixture))::text)`;
  const [authTextA,authTextB] = await pair('AUTH',goalExpr);
  const [authA,authB] = [JSON.parse(authTextA),JSON.parse(authTextB)];
  assert.equal(authA.status,'authorized'); assert.equal(authB.status,'authorized');
  assert.match(authA.authorization_id,ID);
  assert.equal(authA.authorization_id,authB.authorization_id,'Double click issued different authorizations');
  console.log('GREEN real two-backend authorization: one server authorization');

  const startExpr = key => `(public.start_exam_prep_plan_session_once_safe_v1(
    '${authA.authorization_id}'::uuid,'${key}')::text)`;
  const [startA,startB] = await Promise.all([
    psql(authenticated('START',startExpr('concurrent-session-idem-01'))),
    psql(authenticated('START',startExpr('concurrent-session-idem-02')))
  ]);
  assert.notEqual(field(startA,'BACKEND'),field(startB,'BACKEND'));
  const first = JSON.parse(field(startA,'START')), second = JSON.parse(field(startB,'START'));
  assert.deepEqual([first.status,second.status].sort(), ['resume','started']);
  assert.match(first.session_id,ID); assert.equal(first.session_id,second.session_id);
  const count = field(await psql(`SELECT 'COUNTS='||
    (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text||':'||
    (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text||':'||
    (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text;`),'COUNTS');
  assert.equal(count,'1:1:1','Concurrent calls must leave exactly one plan, authorization and session');
  console.log('GREEN real two-backend start: same live session, no duplication');

  // All synthetic responses are saved before marking the attempt finalized.
  await psql(`DO $responses$
DECLARE v_user uuid; v_session uuid; r record;
BEGIN
  SELECT user_id INTO STRICT v_user FROM weekly_goal_ci.fixture;
  SELECT id INTO STRICT v_session FROM private.exam_prep_sessions WHERE user_id=v_user;
  FOR r IN SELECT item_order,item_kind FROM private.exam_prep_session_items WHERE session_id=v_session ORDER BY item_order LOOP
    IF r.item_kind='written' THEN
      INSERT INTO private.exam_prep_responses
       (session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,evaluator_version,elapsed_ms)
      VALUES(v_session,r.item_order,v_user,'concurrent-written-'||r.item_order::text,'written',
        jsonb_build_object('text','synthetic only'),'concurrent-fixture',1000);
    ELSE
      INSERT INTO private.exam_prep_responses
       (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,is_correct,evaluator_version,elapsed_ms)
      VALUES(v_session,r.item_order,v_user,'concurrent-machine-'||r.item_order::text,'machine',
        'synthetic',false,'concurrent-fixture',1000);
    END IF;
  END LOOP;
  UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
    finalize_idempotency_key='concurrent-final-001' WHERE id=v_session;
END;
$responses$;`);
  const [replayA,replayB] = await Promise.all([
    psql(authenticated('REPLAY',startExpr('concurrent-session-idem-01'),false)),
    psql(authenticated('REPLAY',startExpr('concurrent-session-idem-03'),false))
  ]);
  for (const value of [replayA,replayB]) {
    const response = JSON.parse(field(value,'REPLAY'));
    assert.equal(response.status,'attempt_already_saved');
    assert.equal(Object.hasOwn(response,'session_id'),false);
  }
  const [afterA,afterB] = await pair('AFTER',planExpr,false);
  assert.equal(afterA,initial); assert.equal(afterB,initial);
  console.log('GREEN real two-backend finalized replay rejected and plan remains stable');
  console.log('TWO-BACKEND CONCURRENCY GREEN: disposable PostgreSQL only; service container destroys synthetic records.');
})().catch(error => { console.error(error); process.exitCode = 1; });
