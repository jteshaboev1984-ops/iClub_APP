'use strict';
// Follow-up to atomic-dispatch-smoke. Real independent PG backends, SYNTHETIC
// second learner only; database/service container is deleted by GitHub Actions.
const assert=require('node:assert/strict');
const {spawn}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
   !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
  console.error('REFUSED: isolated service-only test.'); process.exit(1);
}
function psql(sql) {
  return new Promise((resolve,reject)=>{
    const child=spawn('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{env,stdio:['pipe','pipe','pipe']});
    let output='',error='';
    child.stdout.on('data',x=>output+=x);
    child.stderr.on('data',x=>error+=x);
    child.on('error',reject);
    child.on('close',code=>code===0?resolve(output):reject(new Error(`Isolated SQL ${code}: ${error.slice(-900)}`)));
    child.stdin.end(sql);
  });
}
function field(out,label) {
  const rows=out.split(/\r?\n/).filter(x=>x.startsWith(label+'='));
  assert.equal(rows.length,1,`Missing exact ${label}`);
  return rows[0].slice(label.length+1);
}
const fixture=`weekly_goal_ci.dispatch_fixture`;
const preface=`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM ${fixture}),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'BACKEND='||pg_backend_pid();\n`;
const request=(label,expression)=>`${preface}SELECT '${label}='||(${expression});
SELECT pg_sleep(0.25);
COMMIT;`;
const ID=/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i;
(async()=>{
  await psql(`CREATE TABLE weekly_goal_ci.dispatch_fixture(user_id uuid primary key,plan_id uuid not null,goal_id uuid not null);
DO $seed$
DECLARE v_uid uuid:=gen_random_uuid();v_program bigint;v_plan uuid;v_goal uuid;v_goals jsonb;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','dispatch-race@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(v_uid,'DispatchRaceFixture',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(v_uid,'active',true);
  SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles(user_id,program_version_id,exam_series,target_grade,
    total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(v_uid,v_program,'May/June 2027','A',12,6,1);
  INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,
    active_week_no,plan_version,status,policy_note)
  VALUES(v_uid,v_program,'P1',1,1,'active','Synthetic dispatch fresh race')
  RETURNING id INTO v_plan;
  INSERT INTO private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_goals:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
  IF (v_goals->>'created')::int<>1 THEN RAISE EXCEPTION 'Synthetic goal not frozen'; END IF;
  SELECT id INTO STRICT v_goal FROM private.exam_prep_weekly_goal_snapshots
  WHERE user_id=v_uid AND component_code='P1' AND active_week_no=1 AND priority_order=1;
  INSERT INTO ${fixture}(user_id,plan_id,goal_id) VALUES(v_uid,v_plan,v_goal);
  INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
  VALUES(v_uid,true,'00000000-0000-4000-8000-000000000001',clock_timestamp());
END $seed$;`);
  const plan=field(await psql(`SELECT 'PLAN='||plan_id::text FROM ${fixture};`),'PLAN');
  assert.match(plan,ID);

  const authExpr=`public.authorize_exam_prep_goal_once_safe_v1('P1',
    (SELECT goal_id FROM ${fixture}),(SELECT plan_id FROM ${fixture}))::text`;
  const oldExpr=`public.authorize_exam_prep_plan_item_safe_v1((SELECT plan_id FROM ${fixture}),1)::text`;
  const [a,b]=await Promise.all([psql(request('OLD_AUTH',oldExpr)),psql(request('NEW_AUTH',authExpr))]);
  assert.notEqual(field(a,'BACKEND'),field(b,'BACKEND'));
  const blocked=JSON.parse(field(a,'OLD_AUTH'));
  const authorized=JSON.parse(field(b,'NEW_AUTH'));
  assert.equal(blocked.status,'goal_identity_required');
  assert.equal(Object.hasOwn(blocked,'authorization_id'),false);
  assert.equal(authorized.status,'authorized');
  assert.match(authorized.authorization_id,ID);
  console.log('PASS two-backend old numeric authorizer denied while governed exact goal issues one auth.');

  const startOld=`public.start_exam_prep_session_safe_v1('${authorized.authorization_id}'::uuid,'dispatch-old-client-key-01')::text`;
  const startNew=`public.start_exam_prep_plan_session_once_safe_v1('${authorized.authorization_id}'::uuid,'dispatch-new-client-key-02')::text`;
  const [sOld,sNew]=await Promise.all([psql(request('OLD_START',startOld)),psql(request('NEW_START',startNew))]);
  assert.notEqual(field(sOld,'BACKEND'),field(sNew,'BACKEND'));
  const started=JSON.parse(field(sOld,'OLD_START'));
  const resumed=JSON.parse(field(sNew,'NEW_START'));
  assert.deepEqual([started.status,resumed.status].sort(),['resume','started']);
  assert.match(started.session_id,ID);
  assert.equal(started.session_id,resumed.session_id);
  const counters=await psql(`SELECT 'COUNTS='||
    (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
    (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
    (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
    FROM ${fixture} f;`);
  assert.equal(field(counters,'COUNTS'),'1:1:1');
  console.log('PASS two-backend legacy/new session race: exactly one live session and no duplicate evidence.');

  // Cross-owner replay with an authorization from the FIRST fixture must not
  // return another student session; the regular Core owner guard is preserved.
  const foreign=await psql(`${preface}
DO $deny$ BEGIN
  BEGIN
    PERFORM public.start_exam_prep_session_safe_v1(
      (SELECT a.id FROM private.exam_prep_session_authorizations a
       JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),'dispatch-foreign-replay-01');
    RAISE EXCEPTION 'foreign authorization was accepted';
  EXCEPTION WHEN sqlstate 'P0002' THEN NULL;
  END;
END $deny$;
SELECT 'OWNER=denied';
ROLLBACK;`);
  assert.equal(field(foreign,'OWNER'),'denied');
  console.log('PASS cross-learner direct legacy replay denied; P1 session remains owner-scoped.');
  console.log('ATOMIC DISPATCH FRESH RACE GREEN: disposable fixtures and independent connections only.');
})().catch(e=>{console.error(e);process.exitCode=1;});
