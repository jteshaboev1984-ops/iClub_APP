-- PROJECTION lifecycle test. DISPOSABLE DATABASE ONLY. All fixture writes roll back.
-- This tests the read model against finalized session provenance and correction facts;
-- it does not substitute for the existing academic-engine retest acceptance tests.
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF current_setting('progress_ux.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'PROGRESS UX LIFECYCLE REFUSED: isolated database required';
  END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
  v_user uuid:=gen_random_uuid(); v_other uuid:=gen_random_uuid();
  v_program bigint; v_case uuid; v_plan uuid; v_first uuid;
  v_assessment bigint; v_content bigint; v_version text;
  v_question bigint; v_skill text; v_reserve text; v_meta bigint; v_md5 text;
  v_auth uuid; v_session uuid; v_response uuid; v_last uuid;
  v_result jsonb; v_goal_id text; v_count integer; v_denied boolean:=false;
  v_no_change jsonb;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES (v_user,'authenticated','authenticated','px-lifecycle-1@invalid.example',now(),now(),false,false),
         (v_other,'authenticated','authenticated','px-lifecycle-2@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(v_user,'ProgressUXLifecycle',now(),false),(v_other,'ProgressUXLifecycle',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(v_user,'active',true),(v_other,'active',true);
  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
      mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
  SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles
  (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(v_user,v_program,'May/June 2027','A',12,6,1),(v_other,v_program,'May/June 2027','A',12,6,1);
  INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status)
  VALUES(v_user,'P1','P1-CIR-01','remediating') RETURNING id INTO v_case;
  SELECT a.id,a.content_version_id,a.assessment_version,
         ai.question_id,ai.primary_skill_code,ai.reserve_role,m.id,m.question_snapshot_md5
  INTO v_assessment,v_content,v_version,v_question,v_skill,v_reserve,v_meta,v_md5
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
  JOIN private.exam_prep_question_content_meta m
    ON m.content_version_id=a.content_version_id AND m.question_id=ai.question_id
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
    AND ai.primary_skill_code='P1-CIR-01' AND ai.question_id IS NOT NULL
  ORDER BY a.id,ai.item_order LIMIT 1;
  IF v_assessment IS NULL THEN RAISE EXCEPTION 'P1 CIR learning fixture missing'; END IF;

  -- Five historical versions, each with a distinct credited finalized session.
  -- The first version contains the immutable original three commitments.
  FOR v_count IN 1..5 LOOP
    INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
    VALUES(v_user,v_program,'P1',1,v_count,'superseded','Progress UX lifecycle fixture')
    RETURNING id INTO v_plan;
    IF v_count=1 THEN v_first:=v_plan; END IF;
    INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
    VALUES(v_plan,1,'correction','P1-CIR-01',v_case,'COMPLETE_CORRECTION_ANALOGUES');
    IF v_count=1 THEN
      INSERT INTO private.exam_prep_weekly_plan_items
      (plan_id,priority_order,item_type,skill_code,action_code)
      VALUES(v_plan,2,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE'),
            (v_plan,3,'learning','P1-QUA-02','BUILD_FIRST_COVERAGE');
    END IF;
    INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit,plan_id,plan_priority_order)
    VALUES(v_user,v_assessment,'P1','learning','issued',clock_timestamp()+interval '1 hour',
      'Isolated historical plan evidence',true,v_plan,1) RETURNING id INTO v_auth;
    v_session:=gen_random_uuid();
    INSERT INTO private.exam_prep_sessions
    (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
     assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
    VALUES(v_session,v_auth,v_user,v_program,v_content,v_assessment,v_version,
      'P1','learning','active','px-life-session-'||v_count::text,1);
    INSERT INTO private.exam_prep_session_items
    (session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
     is_holdout,content_meta_id,question_snapshot_md5,item_version)
    VALUES(v_session,1,'question',v_question,v_skill,v_reserve,false,v_meta,v_md5,
      v_version||'|px-life-'||v_count::text);
    INSERT INTO private.exam_prep_responses
    (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
     is_correct,evaluator_version,elapsed_ms)
    VALUES(v_session,1,v_user,'px-life-response-'||v_count::text,'machine',
      'isolated-fixture',true,'progress_ux_projection_fixture',1000)
    RETURNING id INTO v_response;
    INSERT INTO private.exam_prep_evidence_events
    (user_id,component_code,skill_code,session_id,response_id,evidence_type,
     verification_status,is_correct,evidence_payload,source_version)
    VALUES(v_user,'P1','P1-CIR-01',v_session,v_response,'learning','app_verified',true,
      jsonb_build_object('isolated_fixture','progress_ux_lifecycle'),v_version||'|px-life');
    UPDATE private.exam_prep_sessions
    SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='px-life-final-'||v_count::text WHERE id=v_session;
    v_last:=v_session;
  END LOOP;
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,6,'active','Current regenerated plan') RETURNING id INTO v_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
  VALUES(v_plan,1,'correction','P1-CIR-01',v_case,'COMPLETE_CORRECTION_ANALOGUES');

  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
  IF (v_result->>'created')::int<>3 THEN RAISE EXCEPTION 'Original three goals not snapshotted: %',v_result; END IF;
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF (v_result->>'finalized_study_sessions')::int<>5 OR (v_result->>'completed_goals')::int<>0
    OR (v_result->'goals'->0->>'finalized_sessions')::int<>5
    OR v_result->'goals'->0->>'status'<>'in_progress' THEN
    RAISE EXCEPTION 'Historical sessions must count once without invented completion: %',v_result;
  END IF;
  v_goal_id:=v_result->'goals'->0->>'goal_id';
  IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>0 THEN
    RAISE EXCEPTION 'Idempotence failed after five sessions'; END IF;

  -- Simulate engine-verified remediation action plus scheduled delayed check.
  -- This tests projection; it does NOT bypass the separate academic-engine tests.
  INSERT INTO private.exam_prep_correction_actions
  (correction_case_id,user_id,component_code,skill_code,action_type,session_id,payload)
  VALUES(v_case,v_user,'P1','P1-CIR-01','remediation_completed',v_last,
    jsonb_build_object('isolated_projection_fixture',true));
  UPDATE private.exam_prep_correction_cases SET status='retest_due' WHERE id=v_case;
  INSERT INTO private.exam_prep_retest_events
  (correction_case_id,user_id,component_code,skill_code,status,due_not_before)
  VALUES(v_case,v_user,'P1','P1-CIR-01','scheduled',now()+interval '2 days');
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_plan;
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,7,'active','Retest after remediation') RETURNING id INTO v_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code)
  VALUES(v_plan,1,'retest','P1-CIR-01',v_case,now()+interval '2 days','COMPLETE_DELAYED_RETEST');
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF (v_result->>'completed_goals')::int<>1
    OR v_result->'goals'->0->>'status'<>'waiting_retest'
    OR v_result->'goals'->0->>'correction_open'<>'true'
    OR v_result->'goals'->0->>'retest_due_at' IS NULL
    OR v_result->'goals'->0->>'goal_id'<>v_goal_id THEN
    RAISE EXCEPTION 'Remediation work must count while correction remains open: %',v_result;
  END IF;
  UPDATE private.exam_prep_correction_cases SET status='reopened' WHERE id=v_case;
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF v_result->'goals'->0->>'status'<>'needs_rework' OR
     (v_result->>'completed_goals')::int<>1 OR v_result->'goals'->0->>'correction_open'<>'true' THEN
    RAISE EXCEPTION 'Reopened error cannot be presented as closed or erase prior work: %',v_result;
  END IF;
  UPDATE private.exam_prep_correction_cases SET status='resolved' WHERE id=v_case;
  UPDATE private.exam_prep_retest_events SET status='completed' WHERE correction_case_id=v_case;
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF v_result->'goals'->0->>'status'<>'completed' OR v_result->'goals'->0->>'correction_open'<>'false' THEN
    RAISE EXCEPTION 'Resolved case not shown correctly: %',v_result; END IF;

  -- A new urgent task must not reset or silently replace historical weekly goals.
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_plan;
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,8,'active','New urgent work') RETURNING id INTO v_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_plan,1,'learning','P1-DIF-01','BUILD_FIRST_COVERAGE');
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF jsonb_array_length(v_result->'goals')<>3 OR (v_result->>'completed_goals')::int<>1
     OR v_result->'goals'->0->>'goal_id'<>v_goal_id
     OR v_result->'goals'->1->>'plan_changed'<>'true' THEN
    RAISE EXCEPTION 'Replan overwrote original commitments: %',v_result; END IF;

  -- Calendar rollover creates a new denominator while retaining prior records.
  UPDATE private.exam_prep_exam_profiles SET active_week_no=2 WHERE user_id=v_user;
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_plan;
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',2,1,'active','Second planning week') RETURNING id INTO v_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>1 THEN
    RAISE EXCEPTION 'New week did not anchor its independent first goal'; END IF;
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF jsonb_array_length(v_result->'goals')<>1 OR (v_result->>'completed_goals')::int<>0
     OR (v_result->>'finalized_study_sessions')::int<>5 OR
     (SELECT count(*) FROM private.exam_prep_weekly_goal_snapshots WHERE user_id=v_user AND component_code='P1')<>4 THEN
    RAISE EXCEPTION 'Week rollover erased history or invented work: %',v_result; END IF;
  END IF;
  -- Above intentional checkpoint closes rollover assertions only.
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='ProgressUXLifecycle') THEN
   RAISE EXCEPTION 'Progress UX lifecycle synthetic residue'; END IF;
 RAISE NOTICE 'Progress UX lifecycle rollback PASS';
END $$;
