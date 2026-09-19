-- DISPOSABLE PostgreSQL only. Entire synthetic scenario must ROLLBACK.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
   RAISE EXCEPTION 'STABLE PLAN FIXTURE REFUSED: isolated database required';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
  v_user uuid:=gen_random_uuid(); v_other uuid:=gen_random_uuid();
  v_program bigint; v_old_plan uuid; v_new_plan uuid; v_goal uuid;
  v_assessment bigint; v_auth_id uuid; v_new_auth_id uuid; v_session_id uuid;
  v_result jsonb; v_plan jsonb; v_row record;
  v_denied boolean:=false;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_user,'authenticated','authenticated','stable-plan-one@invalid.example',now(),now(),false,false),
        (v_other,'authenticated','authenticated','stable-plan-two@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(v_user,'StablePlanOnceFixture',now(),false),(v_other,'StablePlanOnceFixture',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(v_user,'active',true),(v_other,'active',true);
  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
      mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
  SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles
    (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(v_user,v_program,'May/June 2027','A',12,6,1),
        (v_other,v_program,'May/June 2027','A',12,6,1);
  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,1,'active','Synthetic stable commitment') RETURNING id INTO v_old_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_old_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
  IF (v_result->>'created')::integer<>1 THEN RAISE EXCEPTION 'Frozen goal not created: %',v_result; END IF;
  SELECT id INTO STRICT v_goal FROM private.exam_prep_weekly_goal_snapshots
  WHERE user_id=v_user AND component_code='P1' AND active_week_no=1 AND priority_order=1;
  v_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF v_plan->>'status'<>'existing' OR v_plan->>'plan_id'<>v_old_plan::text THEN
    RAISE EXCEPTION 'Initial stable plan changed: %',v_plan;
  END IF;
  v_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF v_plan->>'plan_id'<>v_old_plan::text OR
     (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_user AND component_code='P1')<>1 THEN
    RAISE EXCEPTION 'Repeated open silently replanned: %',v_plan;
  END IF;

  v_result:=public.authorize_exam_prep_goal_once_safe_v1('P1',v_goal,v_old_plan);
  IF v_result->>'status'<>'authorized' OR v_result->>'authorization_id' IS NULL THEN
    RAISE EXCEPTION 'Goal was not authorized: %',v_result;
  END IF;
  v_auth_id:=(v_result->>'authorization_id')::uuid;
  SELECT assessment_id INTO STRICT v_assessment FROM private.exam_prep_session_authorizations WHERE id=v_auth_id;
  v_result:=public.authorize_exam_prep_goal_once_safe_v1('P1',v_goal,v_old_plan);
  IF v_result->>'status'<>'authorized' OR (v_result->>'authorization_id')::uuid<>v_auth_id THEN
    RAISE EXCEPTION 'Repeated authorization changed identity: %',v_result;
  END IF;
  v_result:=public.start_exam_prep_plan_session_once_safe_v1(v_auth_id,'stable-once-idem-key-001');
  IF v_result->>'status'<>'started' OR v_result->>'session_id' IS NULL THEN
    RAISE EXCEPTION 'First start failed: %',v_result;
  END IF;
  v_session_id:=(v_result->>'session_id')::uuid;
  v_result:=public.start_exam_prep_plan_session_once_safe_v1(v_auth_id,'stable-once-idem-key-002');
  IF v_result->>'status'<>'resume' OR (v_result->>'session_id')::uuid<>v_session_id THEN
    RAISE EXCEPTION 'Double-click did not resume same session: %',v_result;
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_user)<>1 THEN
    RAISE EXCEPTION 'Double-start created duplicate session'; END IF;

  -- Simulate an explicit governed replan, with the original active attempt preserved.
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_old_plan;
  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,2,'active','Synthetic explicit revision') RETURNING id INTO v_new_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_new_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
     academic_credit,plan_id,plan_priority_order)
  VALUES(v_user,v_assessment,'P1','learning','issued',now()+interval '1 hour',
         'Synthetic plan transition',true,v_new_plan,1) RETURNING id INTO v_new_auth_id;
  v_result:=public.start_exam_prep_plan_session_once_safe_v1(v_new_auth_id,'stable-once-idem-key-003');
  IF v_result->>'status'<>'resume_existing_session_first' OR
     (v_result->>'session_id')::uuid<>v_session_id THEN
    RAISE EXCEPTION 'Replan replaced unfinished attempt: %',v_result;
  END IF;
  v_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF v_plan->>'plan_id'<>v_new_plan::text OR v_plan->>'status'<>'existing' THEN
    RAISE EXCEPTION 'Explicitly revised plan not retained: %',v_plan;
  END IF;
  v_result:=public.authorize_exam_prep_goal_once_safe_v1('P1',v_goal,v_old_plan);
  IF v_result->>'status'<>'stale' THEN RAISE EXCEPTION 'Old plan still authorized: %',v_result; END IF;

  -- Store every response in synthetic DB, then finalize for a replay-only contract test.
  FOR v_row IN SELECT si.item_order,si.item_kind FROM private.exam_prep_session_items si
               WHERE si.session_id=v_session_id ORDER BY si.item_order LOOP
    IF v_row.item_kind='written' THEN
      INSERT INTO private.exam_prep_responses
        (session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,evaluator_version,elapsed_ms)
      VALUES(v_session_id,v_row.item_order,v_user,'stable-once-written-'||v_row.item_order::text,
             'written',jsonb_build_object('text','synthetic unverified answer'),'stable-plan-fixture',1000);
    ELSE
      INSERT INTO private.exam_prep_responses
        (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,is_correct,evaluator_version,elapsed_ms)
      VALUES(v_session_id,v_row.item_order,v_user,'stable-once-machine-'||v_row.item_order::text,
             'machine','fixture',false,'stable-plan-fixture',1000);
    END IF;
  END LOOP;
  UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
      finalize_idempotency_key='stable-once-final-001' WHERE id=v_session_id;
  v_result:=public.start_exam_prep_plan_session_once_safe_v1(v_auth_id,'stable-once-idem-key-004');
  IF v_result->>'status'<>'attempt_already_saved' OR v_result?'session_id' THEN
    RAISE EXCEPTION 'Finalized authorization replay leaked session: %',v_result;
  END IF;
  v_result:=public.start_exam_prep_plan_session_once_safe_v1(v_auth_id,'stable-once-idem-key-001');
  IF v_result->>'status'<>'attempt_already_saved' OR v_result?'session_id' THEN
    RAISE EXCEPTION 'Original key reopened finalized attempt: %',v_result;
  END IF;
  v_result:=public.start_exam_prep_plan_session_once_safe_v1(v_new_auth_id,'stable-once-idem-key-003');
  IF v_result->>'status'<>'content_exhausted' THEN
    RAISE EXCEPTION 'Exposed learning pack reused as fresh: %',v_result;
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_user)<>1 THEN
    RAISE EXCEPTION 'Finalized replay created duplicate attempt'; END IF;
  v_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF v_plan->>'plan_id'<>v_new_plan::text OR v_plan->>'status'<>'existing' OR
      (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_user AND component_code='P1')<>2 THEN
    RAISE EXCEPTION 'Completed attempt regenerated plan: %',v_plan;
  END IF;
  PERFORM set_config('request.jwt.claim.sub',v_other::text,true);
  BEGIN
    PERFORM public.start_exam_prep_plan_session_once_safe_v1(v_auth_id,'stable-foreign-key-001');
  EXCEPTION WHEN OTHERS THEN v_denied:=true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'Foreign user accessed session'; END IF;
  RAISE NOTICE 'STABLE PLAN CONTRACT GREEN: same-week identity, authorize, double-click, replan, resume, finalized block, exhausted pack, owner';
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='StablePlanOnceFixture') THEN
   RAISE EXCEPTION 'Stable-plan synthetic residue';
 END IF;
 RAISE NOTICE 'STABLE PLAN ROLLBACK GREEN';
END $$;
