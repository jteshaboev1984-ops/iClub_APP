'use strict';
// Real enrolled-user diagnostic continuity, separate from protected weekly plan.
// DISPOSABLE GitHub Actions PostgreSQL service and synthetic students ONLY.
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
   !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
  console.error('REFUSED: disposable PostgreSQL required');process.exit(1);
}
function query(source){
  const ret=spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
    env,encoding:'utf8',input:source,timeout:30000
  });
  assert.equal(ret.status,0,`Isolated SQL error: ${(ret.stderr||'').slice(-1100)}`);
  return ret.stdout;
}
function read(stdout,label){
  const matches=stdout.split(/\r?\n/).filter(x=>x.startsWith(label+'='));
  assert.equal(matches.length,1,`Missing ${label}`);
  return matches[0].slice(label.length+1);
}
const sql=`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.dispatch_fixture),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
DO $setup$
DECLARE v_assessment bigint; v_uid uuid;
BEGIN
  SELECT user_id INTO STRICT v_uid FROM weekly_goal_ci.dispatch_fixture;
  SELECT id INTO v_assessment FROM private.exam_prep_assessments
  WHERE component_code='P1' AND assessment_type='diagnostic' AND status='published'
  ORDER BY id LIMIT 1;
  IF v_assessment IS NULL THEN RAISE EXCEPTION 'Isolated P1 diagnostic fixture missing'; END IF;
  INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit)
  VALUES(v_uid,v_assessment,'P1','diagnostic','issued',clock_timestamp()+interval '1 hour',
    'Synthetic non-plan diagnostic continuity',true);
END $setup$;
SELECT 'BEFORE='||
 (SELECT count(*)::text FROM private.exam_prep_sessions s
  WHERE s.user_id=(SELECT user_id FROM weekly_goal_ci.dispatch_fixture));
SELECT 'FIRST='||public.start_exam_prep_session_safe_v1(
 (SELECT id FROM private.exam_prep_session_authorizations WHERE user_id=
  (SELECT user_id FROM weekly_goal_ci.dispatch_fixture) AND plan_id IS NULL ORDER BY issued_at DESC LIMIT 1),
 'synthetic-diagnostic-idem-01')::text;
SELECT 'REPLAY='||public.start_exam_prep_session_safe_v1(
 (SELECT id FROM private.exam_prep_session_authorizations WHERE user_id=
  (SELECT user_id FROM weekly_goal_ci.dispatch_fixture) AND plan_id IS NULL ORDER BY issued_at DESC LIMIT 1),
 'synthetic-diagnostic-idem-01')::text;
SELECT 'AFTER='||
 (SELECT count(*)::text FROM private.exam_prep_sessions s
  WHERE s.user_id=(SELECT user_id FROM weekly_goal_ci.dispatch_fixture));
ROLLBACK;`;
const output=query(sql);
const first=JSON.parse(read(output,'FIRST'));
const repeat=JSON.parse(read(output,'REPLAY'));
assert.equal(read(output,'BEFORE'),'1');
assert.equal(read(output,'AFTER'),'2');
assert.equal(first.session_type,'diagnostic');
assert.equal(first.status,'active');
assert.equal(repeat.session_id,first.session_id);
assert.equal(repeat.status,'active');
console.log('PASS enrolled learner diagnostic: original non-plan Core start + same-key replay preserved; test rolled back.');
const privileges=query(`SELECT 'PRIVATE_DENIAL='||bool_and(
 NOT has_function_privilege('anon',r.oid,'EXECUTE') AND
 NOT has_function_privilege('authenticated',r.oid,'EXECUTE') AND
 NOT has_function_privilege('service_role',r.oid,'EXECUTE'))::text
FROM (SELECT to_regprocedure(x.signature) AS oid FROM (VALUES
 ('private.exam_prep_legacy_generate_v2_internal_v1(text)'),
 ('private.exam_prep_legacy_generate_v3_internal_v1(text)'),
 ('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'),
 ('private.exam_prep_legacy_start_session_internal_v1(uuid,text)')
) AS x(signature)) r;`);
assert.equal(read(privileges,'PRIVATE_DENIAL'),'true');
console.log('PASS private original implementations unavailable to anon, authenticated and service_role.');
console.log('NON-PLAN CONTINUITY GREEN: temporary database only; live database never accessed.');
