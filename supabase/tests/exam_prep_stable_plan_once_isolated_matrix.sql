-- DISPOSABLE PostgreSQL only. The entire synthetic learner scenario is rolled back.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
   RAISE EXCEPTION 'STABLE PLAN FIXTURE REFUSED: isolated database required';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
  u uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid();
  prog bigint; old_plan uuid; new_plan uuid; frozen_goal uuid;
  assessment bigint; authorization uuid; new_auth uuid; session_id uuid;
  result jsonb; first_plan jsonb; current_plan jsonb; r record;
  n integer; denied boolean:=false;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(u,'authenticated','authenticated','stable-plan-one@invalid.example',now(),now(),false,false),
        (outsider,'authenticated','authenticated','stable-plan-two@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(u,'StablePlanOnceFixture',now(),false),(outsider,'StablePlanOnceFixture',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(u,'active',true),(outsider,'active',true);
  UPDATE private.exam_prep_feature_config
    SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
        mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
  SELECT id INTO STRICT prog FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles
    (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(u,prog,'May/June 2027','A',12,6,1),
        (outsider,prog,'May/June 2027','A',12,6,1);
  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,1,'active','Synthetic stable commitment') RETURNING id INTO old_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(old_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
  IF (result->>'created')::integer<>1 THEN RAISE EXCEPTION 'Frozen goal not created: %',result; END IF;
  SELECT id INTO STRICT frozen_goal FROM private.exam_prep_weekly_goal_snapshots
   WHERE user_id=u AND component_code='P1' AND active_week_no=1 AND priority_order=1;
  first_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF first_plan->>'status'<>'existing' OR first_plan->>'plan_id'<>old_plan::text THEN
    RAISE EXCEPTION 'Stable plan did not retain existing ID: %',first_plan;
  END IF;
  current_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF current_plan->>'plan_id'<>old_plan::text OR
     (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=u AND component_code='P1')<>1 THEN
    RAISE EXCEPTION 'Repeated open silently replanned: %',current_plan;
  END IF;

  result:=public.authorize_exam_prep_goal_once_safe_v1('P1',frozen_goal,old_plan);
  IF result->>'status'<>'authorized' OR result->>'authorization_id' IS NULL THEN
    RAISE EXCEPTION 'Goal was not authorized: %',result;
  END IF;
  authorization:=(result->>'authorization_id')::uuid;
  SELECT assessment_id INTO STRICT assessment FROM private.exam_prep_session_authorizations WHERE id=authorization;
  result:=public.authorize_exam_prep_goal_once_safe_v1('P1',frozen_goal,old_plan);
  IF result->>'status'<>'authorized' OR (result->>'authorization_id')::uuid<>authorization THEN
    RAISE EXCEPTION 'Repeated authorize must reuse issued auth: %',result;
  END IF;
  result:=public.start_exam_prep_plan_session_once_safe_v1(authorization,'stable-once-idem-key-001');
  IF result->>'status'<>'started' OR result->>'session_id' IS NULL THEN
    RAISE EXCEPTION 'First session did not start: %',result;
  END IF;
  session_id:=(result->>'session_id')::uuid;
  result:=public.start_exam_prep_plan_session_once_safe_v1(authorization,'stable-once-idem-key-002');
  IF result->>'status'<>'resume' OR (result->>'session_id')::uuid<>session_id THEN
    RAISE EXCEPTION 'Double click created another session: %',result;
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=u)<>1 THEN
    RAISE EXCEPTION 'Double-start produced duplicate sessions'; END IF;

  -- Explicit replan simulated in isolated fixture: original session remains resumable.
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=old_plan;
  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,2,'active','Synthetic explicit revision') RETURNING id INTO new_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(new_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
     academic_credit,plan_id,plan_priority_order)
  VALUES(u,assessment,'P1','learning','issued',now()+interval '1 hour',
         'Synthetic plan transition',true,new_plan,1) RETURNING id INTO new_auth;
  result:=public.start_exam_prep_plan_session_once_safe_v1(new_auth,'stable-once-idem-key-003');
  IF result->>'status'<>'resume_existing_session_first' OR
     (result->>'session_id')::uuid<>session_id THEN
    RAISE EXCEPTION 'Replan replaced unfinished prior session: %',result;
  END IF;
  current_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF current_plan->>'plan_id'<>new_plan::text OR current_plan->>'status'<>'existing' THEN
    RAISE EXCEPTION 'Replan should keep current commitment: %',current_plan;
  END IF;
  result:=public.authorize_exam_prep_goal_once_safe_v1('P1',frozen_goal,old_plan);
  IF result->>'status'<>'stale' THEN RAISE EXCEPTION 'Old plan still authorized: %',result; END IF;

  -- Complete four saved responses in synthetic DB, then ensure no replay or replanning.
  FOR r IN SELECT item_order,item_kind FROM private.exam_prep_session_items
           WHERE session_id=session_id ORDER BY item_order LOOP
    IF r.item_kind='written' THEN
      INSERT INTO private.exam_prep_responses
       (session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,evaluator_version,elapsed_ms)
      VALUES(session_id,r.item_order,u,'stable-once-written-'||r.item_order::text,
             'written',jsonb_build_object('text','synthetic unverified answer'),
             'stable-plan-fixture',1000);
    ELSE
      INSERT INTO private.exam_prep_responses
       (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
        is_correct,evaluator_version,elapsed_ms)
      VALUES(session_id,r.item_order,u,'stable-once-machine-'||r.item_order::text,
             'machine','fixture',false,'stable-plan-fixture',1000);
    END IF;
  END LOOP;
  UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
      finalize_idempotency_key='stable-once-final-001' WHERE id=session_id;
  result:=public.start_exam_prep_plan_session_once_safe_v1(authorization,'stable-once-idem-key-004');
  IF result->>'status'<>'attempt_already_saved' OR result?'session_id' THEN
    RAISE EXCEPTION 'Finalized authorization replay leaked session: %',result;
  END IF;
  result:=public.start_exam_prep_plan_session_once_safe_v1(authorization,'stable-once-idem-key-001');
  IF result->>'status'<>'attempt_already_saved' OR result?'session_id' THEN
    RAISE EXCEPTION 'Original idempotency key reopened finalized: %',result;
  END IF;
  result:=public.start_exam_prep_plan_session_once_safe_v1(new_auth,'stable-once-idem-key-003');
  IF result->>'status'<>'content_exhausted' THEN
    RAISE EXCEPTION 'Previously exposed learning pack recycled as fresh: %',result;
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=u)<>1 THEN
    RAISE EXCEPTION 'Finalized replay created another session'; END IF;
  current_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
  IF current_plan->>'plan_id'<>new_plan::text OR current_plan->>'status'<>'existing' OR
      (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=u AND component_code='P1')<>2 THEN
    RAISE EXCEPTION 'Completed attempt regenerated current plan: %',current_plan;
  END IF;
  PERFORM set_config('request.jwt.claim.sub',outsider::text,true);
  BEGIN
    PERFORM public.start_exam_prep_plan_session_once_safe_v1(authorization,'stable-foreign-key-001');
  EXCEPTION WHEN OTHERS THEN denied:=true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Foreign user could start another learner session'; END IF;
  RAISE NOTICE 'STABLE-PLAN ISOLATED GREEN: repeated read, issued auth, double click, replan, resume, finalized replay, seen-pack gate, owner isolation';
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='StablePlanOnceFixture') THEN
   RAISE EXCEPTION 'Stable-plan fixture left synthetic users';
 END IF;
 RAISE NOTICE 'STABLE-PLAN SYNTHETIC ROLLBACK GREEN';
END $$;
