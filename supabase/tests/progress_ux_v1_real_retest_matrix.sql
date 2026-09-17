-- Disposable integration test: exercise the real finalized-session retest trigger,
-- then verify Progress UX projects pass/fail truthfully. All fixture writes ROLLBACK.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('progress_ux.isolated_db',true) IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'PROGRESS UX REAL RETEST REFUSED: isolated database required';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
  u uuid:=gen_random_uuid();
  prog bigint;
  pass_case uuid; fail_case uuid;
  source_plan uuid; active_plan uuid;
  rec record;
  ass bigint; content_id bigint; ass_ver text;
  q bigint; reserve_role text; meta bigint; checksum text;
  auth_id uuid; rt_id uuid; v_session_id uuid;
  result jsonb; goal jsonb;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(u,'authenticated','authenticated','px-real-retest@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(u,'ProgressUXRealRetest',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(u,'active',true);
  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
      mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
  SELECT id INTO STRICT prog FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles
    (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(u,prog,'May/June 2027','A',12,6,1);

  INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status)
  VALUES(u,'P1','P1-QUA-01','retest_due') RETURNING id INTO pass_case;
  INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status)
  VALUES(u,'P1','P1-QUA-02','retest_due') RETURNING id INTO fail_case;

  -- The week's stable commitments began as correction work.
  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,1,'superseded','Real retest projection source') RETURNING id INTO source_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
  VALUES(source_plan,1,'correction','P1-QUA-01',pass_case,'COMPLETE_CORRECTION_ANALOGUES'),
        (source_plan,2,'correction','P1-QUA-02',fail_case,'COMPLETE_CORRECTION_ANALOGUES');

  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>2 THEN
    RAISE EXCEPTION 'Stable correction goals were not anchored'; END IF;

  -- Existing academic engine has already verified remediation completion.
  INSERT INTO private.exam_prep_correction_actions
    (correction_case_id,user_id,component_code,skill_code,action_type,payload)
  VALUES(pass_case,u,'P1','P1-QUA-01','remediation_completed',jsonb_build_object('fixture','real_retest')),
        (fail_case,u,'P1','P1-QUA-02','remediation_completed',jsonb_build_object('fixture','real_retest'));

  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,2,'active','Real delayed retest actions') RETURNING id INTO active_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code)
  VALUES(active_plan,1,'retest','P1-QUA-01',pass_case,now()-interval '1 day','COMPLETE_DELAYED_RETEST'),
        (active_plan,2,'retest','P1-QUA-02',fail_case,now()-interval '1 day','COMPLETE_DELAYED_RETEST');

  FOR rec IN
    SELECT * FROM (VALUES
      (pass_case,'P1-QUA-01'::text,true,1),
      (fail_case,'P1-QUA-02'::text,false,2)
    ) AS x(case_id,skill_code,should_pass,priority_order)
  LOOP
    SELECT a.id,a.content_version_id,a.assessment_version,ai.question_id,ai.reserve_role,
           m.id,m.question_snapshot_md5
      INTO ass,content_id,ass_ver,q,reserve_role,meta,checksum
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
    JOIN private.exam_prep_question_content_meta m ON m.content_version_id=a.content_version_id
      AND m.question_id=ai.question_id
    WHERE a.component_code='P1' AND a.assessment_type='retest' AND a.status='published'
      AND ai.primary_skill_code=rec.skill_code AND ai.question_id IS NOT NULL
      AND NOT EXISTS(
        SELECT 1 FROM private.exam_prep_assessment_items other
        WHERE other.assessment_id=a.id AND other.primary_skill_code<>rec.skill_code)
    ORDER BY a.id,ai.item_order LIMIT 1;
    IF ass IS NULL THEN RAISE EXCEPTION 'Retest fixture missing for %',rec.skill_code; END IF;

    INSERT INTO private.exam_prep_session_authorizations
      (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
       academic_credit,correction_case_id,plan_id,plan_priority_order)
    VALUES(u,ass,'P1','retest','issued',clock_timestamp()+interval '1 hour',
      'Progress UX real retest fixture',true,rec.case_id,active_plan,rec.priority_order)
    RETURNING id INTO auth_id;

    INSERT INTO private.exam_prep_retest_events
      (correction_case_id,user_id,component_code,skill_code,status,due_not_before,authorization_id)
    VALUES(rec.case_id,u,'P1',rec.skill_code,'authorized',now()-interval '1 day',auth_id)
    RETURNING id INTO rt_id;

    v_session_id:=gen_random_uuid();
    INSERT INTO private.exam_prep_sessions
      (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
       assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
    VALUES(v_session_id,auth_id,u,prog,content_id,ass,ass_ver,'P1','retest','active',
      'px-real-retest-'||rec.priority_order::text,1);
    INSERT INTO private.exam_prep_session_items
      (session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
       is_holdout,content_meta_id,question_snapshot_md5,item_version)
    VALUES(v_session_id,1,'question',q,rec.skill_code,reserve_role,false,meta,checksum,
      ass_ver||'|px-real-retest-'||rec.priority_order::text);
    INSERT INTO private.exam_prep_responses
      (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
       is_correct,evaluator_version,elapsed_ms)
    VALUES(v_session_id,1,u,'px-real-retest-response-'||rec.priority_order::text,'machine',
      'isolated-fixture',rec.should_pass,'progress_ux_real_retest_fixture',1000);

    -- This status transition invokes the EXISTING real retest reconciliation trigger.
    UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
      last_activity_at=clock_timestamp(),finalize_idempotency_key='px-real-retest-final-'||rec.priority_order::text
    WHERE id=v_session_id;

    IF rec.should_pass THEN
      IF NOT EXISTS(SELECT 1 FROM private.exam_prep_correction_cases c WHERE c.id=rec.case_id AND c.status='resolved')
         OR NOT EXISTS(SELECT 1 FROM private.exam_prep_correction_actions ca WHERE ca.correction_case_id=rec.case_id AND ca.action_type='retest_passed' AND ca.session_id=v_session_id) THEN
        RAISE EXCEPTION 'Real passing retest did not resolve/log pass'; END IF;
    ELSE
      IF NOT EXISTS(SELECT 1 FROM private.exam_prep_correction_cases c WHERE c.id=rec.case_id AND c.status='reopened')
         OR NOT EXISTS(SELECT 1 FROM private.exam_prep_correction_actions ca WHERE ca.correction_case_id=rec.case_id AND ca.action_type='retest_failed' AND ca.session_id=v_session_id) THEN
        RAISE EXCEPTION 'Real failing retest did not reopen/log failure'; END IF;
    END IF;
  END LOOP;

  result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  SELECT value INTO goal FROM jsonb_array_elements(result->'goals') value WHERE (value->>'priority_order')::int=1;
  IF goal->>'status'<>'completed' OR goal->>'correction_open'<>'false' THEN
    RAISE EXCEPTION 'Passing real retest projected incorrectly: %',result; END IF;
  SELECT value INTO goal FROM jsonb_array_elements(result->'goals') value WHERE (value->>'priority_order')::int=2;
  IF goal->>'status'<>'needs_rework' OR goal->>'correction_open'<>'true' THEN
    RAISE EXCEPTION 'Failed real retest projected incorrectly: %',result; END IF;
  IF (result->>'completed_goals')::int<>2 THEN
    RAISE EXCEPTION 'Remediation commitments should remain historically complete after retest outcomes: %',result; END IF;

  RAISE NOTICE 'Progress UX real retest PASS: actual pass resolves, actual fail reopens, projection preserves weekly work truth';
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='ProgressUXRealRetest') THEN
  RAISE EXCEPTION 'Real retest fixture leaked into database'; END IF;
 RAISE NOTICE 'Progress UX real retest rollback PASS';
END $$;
