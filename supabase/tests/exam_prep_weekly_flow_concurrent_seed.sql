-- DISPOSABLE PostgreSQL ONLY. This intentionally commits synthetic fixture data
-- so TWO different database connections can race on the SAME owner and plan.
-- The CI service container is deleted after the job; NEVER run on production.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
   RAISE EXCEPTION 'CONCURRENCY SEED REFUSED: isolated database only';
 END IF;
END $$;
CREATE SCHEMA weekly_goal_ci;
CREATE TABLE weekly_goal_ci.fixture (
 user_id uuid primary key, plan_id uuid not null, goal_id uuid not null
);
DO $seed$
DECLARE
 v_uid uuid:=gen_random_uuid(); v_program bigint; v_plan uuid; v_goal uuid;
 v_goals jsonb;
BEGIN
 INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
 VALUES(v_uid,'authenticated','authenticated','weekly-concurrent@invalid.example',now(),now(),false,false);
 INSERT INTO public.users(id,first_name,created_at,must_change_password)
 VALUES(v_uid,'WeeklyConcurrencyFixture',now(),false);
 INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
 VALUES(v_uid,'active',true);
 UPDATE private.exam_prep_feature_config
 SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
     mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
 SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
 INSERT INTO private.exam_prep_exam_profiles
 (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
 VALUES(v_uid,v_program,'May/June 2027','A',12,6,1);
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(v_uid,v_program,'P1',1,1,'active','Synthetic two-backend commitment') RETURNING id INTO v_plan;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,action_code)
 VALUES(v_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
 PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 v_goals:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
 IF (v_goals->>'created')::int<>1 THEN RAISE EXCEPTION 'Synthetic frozen goal missing'; END IF;
 SELECT id INTO STRICT v_goal FROM private.exam_prep_weekly_goal_snapshots
 WHERE user_id=v_uid AND component_code='P1' AND active_week_no=1 AND priority_order=1;
 INSERT INTO weekly_goal_ci.fixture(user_id,plan_id,goal_id) VALUES(v_uid,v_plan,v_goal);
 RAISE NOTICE 'SYNTHETIC CONCURRENCY SEED READY: identifiers intentionally not logged';
END;
$seed$;
