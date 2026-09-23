'use strict';
// Fail closed: only disposable CI PostgreSQL; no production connections.
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
 !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')){
 console.error('REFUSED: disposable CI PostgreSQL ONLY');process.exit(1);
}
function query(source){const result=spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
 env,encoding:'utf8',input:source,timeout:30000});
 assert.equal(result.status,0,`Isolated SQL error: ${(result.stderr||'').slice(-2200)}`);
 return result.stdout;}
function read(output,key){const hits=output.split(/\r?\n/).filter(x=>x.startsWith(key+'='));
 assert.equal(hits.length,1,`Expected ${key}`);return hits[0].slice(key.length+1);}
const run=`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'BEFORE='||(SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text;
DO $denied$
DECLARE v_uid uuid; v_learning bigint; v_auth uuid; v_count integer:=0;
BEGIN
 SELECT user_id INTO STRICT v_uid FROM weekly_goal_ci.fixture;
 IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'Missing enrolled fixture';
 END IF;
 -- Every direct legacy route must reject enrollment before touching plan, cases or content.
 BEGIN PERFORM public.generate_exam_prep_weekly_plan_safe_v1('P1','normal');
  RAISE EXCEPTION 'UNGUARDED_DIRECT_V1_PLAN';
 EXCEPTION WHEN sqlstate '42501' THEN v_count:=v_count+1; END;
 BEGIN PERFORM public.authorize_exam_prep_correction_safe_v1('00000000-0000-4000-8000-000000000001'::uuid);
  RAISE EXCEPTION 'UNGUARDED_DIRECT_CORRECTION';
 EXCEPTION WHEN sqlstate '42501' THEN v_count:=v_count+1; END;
 BEGIN PERFORM public.authorize_exam_prep_mixed_safe_v1('P1');
  RAISE EXCEPTION 'UNGUARDED_DIRECT_MIXED';
 EXCEPTION WHEN sqlstate '42501' THEN v_count:=v_count+1; END;
 BEGIN PERFORM public.authorize_exam_prep_retest_safe_v1('00000000-0000-4000-8000-000000000001'::uuid);
  RAISE EXCEPTION 'UNGUARDED_DIRECT_RETEST';
 EXCEPTION WHEN sqlstate '42501' THEN v_count:=v_count+1; END;
 SELECT id INTO v_learning FROM private.exam_prep_assessments
  WHERE component_code='P1' AND assessment_type='learning' AND status='published'
  ORDER BY id LIMIT 1;
 IF v_learning IS NULL THEN RAISE EXCEPTION 'Missing synthetic learning content'; END IF;
 -- Simulate unbound, previously issued authorization created by an older client.
 INSERT INTO private.exam_prep_session_authorizations
 (user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit)
 VALUES(v_uid,v_learning,'P1','learning','issued',clock_timestamp()+interval '1 hour',
 'Disposable legacy unbound authorization',true) RETURNING id INTO v_auth;
 BEGIN PERFORM public.start_exam_prep_session_safe_v1(v_auth,'synthetic-unbound-bypass');
  RAISE EXCEPTION 'UNGUARDED_NONPLAN_LEARNING_START';
 EXCEPTION WHEN sqlstate '42501' THEN v_count:=v_count+1; END;
 IF v_count<>5 THEN RAISE EXCEPTION 'Expected five independent denials, got %',v_count; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE authorization_id=v_auth) THEN
  RAISE EXCEPTION 'Denied start created session';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE id=v_auth AND status<>'issued') THEN
  RAISE EXCEPTION 'Denied start consumed authorization';
 END IF;
END $denied$;
SELECT 'AFTER='||(SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text||':'||
 (SELECT count(*)-1 FROM private.exam_prep_session_authorizations WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=(SELECT user_id FROM weekly_goal_ci.fixture))::text;
ROLLBACK;`;
const result=query(run);
assert.equal(read(result,'BEFORE'),'1:1:1');
assert.equal(read(result,'AFTER'),'1:1:1');
console.log('FULL-SURFACE NEGATIVE PASS: direct v1 replan, correction, mixed, retest and unbound learning starter denied for enrolled synthetic user.');
const originals=query(`SELECT 'PRIVILEGES='||bool_and(
 NOT has_function_privilege('authenticated',sig,'EXECUTE') AND
 NOT has_function_privilege('anon',sig,'EXECUTE') AND
 NOT has_function_privilege('service_role',sig,'EXECUTE'))::text
 FROM (VALUES
 ('private.exam_prep_legacy_generate_v1_internal_v1(text,text)'),
 ('private.exam_prep_legacy_generate_v2_internal_v1(text)'),
 ('private.exam_prep_legacy_generate_v3_internal_v1(text)'),
 ('private.exam_prep_legacy_correction_internal_v1(uuid)'),
 ('private.exam_prep_legacy_mixed_internal_v1(text)'),
 ('private.exam_prep_legacy_retest_internal_v1(uuid)'),
 ('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'),
 ('private.exam_prep_legacy_start_session_internal_v1(uuid,text)')) v(sig);`);
assert.equal(read(originals,'PRIVILEGES'),'true');
console.log('PRIVATE ORIGINALS PASS: all eight Core implementations unavailable to browser, anon and service roles.');
