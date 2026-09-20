-- SYNTHETIC ISOLATED POSTGRES ONLY. Structural adherence, not real marking.
-- This fixture refuses production and rolls back the entire artificial learner.
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
     OR to_regclass('weekly_goal_ci.fixture') IS NULL
     OR to_regprocedure('public.get_exam_prep_previous_week_adherence_safe_v1(text)') IS NULL THEN
    RAISE EXCEPTION 'ADHERENCE FIXTURE REFUSED: isolated database and reviewed proposal required';
  END IF;
END $$;
BEGIN;
DO $test$
DECLARE
  v_uid uuid:=gen_random_uuid(); v_program bigint; v_assessment bigint;
  v_cv bigint; v_version text; v_plan uuid; v_plan2 uuid;
  v_auth uuid; v_session uuid; v_result jsonb; v_start timestamptz:=now()-interval '8 days';
BEGIN
  UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',
    core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
    WHERE id=1;
  SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
    WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  SELECT id,content_version_id,assessment_version INTO STRICT v_assessment,v_cv,v_version
    FROM private.exam_prep_assessments WHERE status='published'
      AND assessment_type='learning' AND component_code='P1' ORDER BY id LIMIT 1;
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(v_uid,'authenticated','authenticated','previous-week-synthetic@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
    VALUES(v_uid,'AdherenceSyntheticFixture',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
    VALUES(v_uid,'active',true);
  INSERT INTO private.exam_prep_exam_profiles(user_id,program_version_id,exam_series,target_grade,
    total_student_hours_available,mathematics_hours_budget,active_week_no,created_at)
    VALUES(v_uid,v_program,'May/June 2027','A',12,6,1,v_start);
  INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
    VALUES(v_uid,true,'00000000-0000-4000-8000-000000000001',now());
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  IF private.exam_prep_effective_active_week_v1(v_uid)<>2 THEN
    RAISE EXCEPTION 'Profile anchor did not resolve to closed week 1'; END IF;
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
  IF v_result->>'status'<>'no_verified_plan' OR (v_result->>'can_alert')::boolean THEN
    RAISE EXCEPTION 'Missing plan must not blame learner: %',v_result; END IF;
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P5');
  IF v_result->>'status'<>'no_verified_plan' THEN
    RAISE EXCEPTION 'P5 must stay independent: %',v_result; END IF;

  INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,
    active_week_no,plan_version,status,policy_note,generated_at)
    VALUES(v_uid,v_program,'P1',1,1,'active','synthetic previous-week contract only',v_start+interval '1 day')
    RETURNING id INTO v_plan;
  INSERT INTO private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,
    action_code,action_payload,status,created_at)
    VALUES(v_plan,1,'learning','P1-CIR-01','start_learning',
      jsonb_build_object('assessment_id',v_assessment),'pending',v_start+interval '1 day');
  INSERT INTO private.exam_prep_weekly_goal_snapshots(user_id,program_version_id,component_code,
    active_week_no,priority_order,source_plan_id,item_type,skill_code,action_code,assessment_id,created_at)
    VALUES(v_uid,v_program,'P1',1,1,v_plan,'learning','P1-CIR-01',
      'start_learning',v_assessment,v_start+interval '1 day');
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
  IF v_result->>'status'<>'missed' OR (v_result->>'can_alert')::boolean IS DISTINCT FROM true
     OR (v_result->>'scheduled_goals')::int<>1 OR (v_result->>'completed_by_deadline')::int<>0 THEN
    RAISE EXCEPTION 'Verified unfinished previous-week goal was not detected: %',v_result;
  END IF;
  RAISE NOTICE 'PASS frozen overdue P1 goal, P5 remains untouched';

  INSERT INTO private.exam_prep_session_authorizations(user_id,assessment_id,component_code,
    purpose,status,valid_until,reason,plan_id,plan_priority_order,academic_credit)
    VALUES(v_uid,v_assessment,'P1','learning','consumed',now()+interval '1 hour',
      'Synthetic adherence noncredit contract',v_plan,1,false) RETURNING id INTO v_auth;
  INSERT INTO private.exam_prep_sessions(authorization_id,user_id,program_version_id,
    content_version_id,assessment_id,assessment_version,component_code,session_type,
    status,client_idempotency_key,total_items,finalized_at)
    VALUES(v_auth,v_uid,v_program,v_cv,v_assessment,v_version,'P1','learning',
      'finalized','synthetic-late-adherence-session',1,now()-interval '12 hours')
    RETURNING id INTO v_session;
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
  IF v_result->>'status'<>'missed' THEN
    RAISE EXCEPTION 'Noncredit finalized attempt incorrectly satisfied goal: %',v_result; END IF;
  UPDATE private.exam_prep_session_authorizations SET academic_credit=true WHERE id=v_auth;
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
  IF v_result->>'status'<>'caught_up' OR (v_result->>'can_alert')::boolean
    OR (v_result->>'completed_by_deadline')::int<>0 OR (v_result->>'completed_now')::int<>1 THEN
    RAISE EXCEPTION 'Late completion did not clear active warning: %',v_result; END IF;
  RAISE NOTICE 'PASS noncredit ignored and eventual completion suppresses stale warning';

  -- Old automatic plan replacement makes adherence attribution unreliable.
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_plan;
  INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,
    active_week_no,plan_version,status,policy_note,generated_at)
    VALUES(v_uid,v_program,'P1',1,2,'active','synthetic legacy replacement',v_start+interval '2 days')
    RETURNING id INTO v_plan2;
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
  IF v_result->>'status'<>'ambiguous_plan' OR (v_result->>'can_alert')::boolean THEN
    RAISE EXCEPTION 'Superseded multi-plan week must fail closed: %',v_result; END IF;
  RAISE NOTICE 'PASS legacy multi-plan ambiguity fails closed';

  UPDATE private.exam_prep_exam_profiles SET created_at=now(),active_week_no=1 WHERE user_id=v_uid;
  v_result:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
  IF v_result->>'status'<>'not_due' OR (v_result->>'can_alert')::boolean THEN
    RAISE EXCEPTION 'Open first week was judged overdue: %',v_result; END IF;
  RAISE NOTICE 'PASS first week cannot trigger premature overdue alert';
END;
$test$;
ROLLBACK;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.users WHERE first_name='AdherenceSyntheticFixture') OR
     EXISTS(SELECT 1 FROM auth.users WHERE email='previous-week-synthetic@invalid.example') THEN
    RAISE EXCEPTION 'Synthetic adherence learner survived rollback'; END IF;
  RAISE NOTICE 'PREVIOUS-WEEK ADHERENCE: ZERO SYNTHETIC RESIDUE';
END $$;
