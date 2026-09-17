-- Disposable PostgreSQL contract test: a skill is not a complete assignment identity.
-- Actual finalized session + verified response of a recovery refresh must not
-- complete or inflate an earlier first-coverage weekly commitment.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('progress_ux.isolated_db',true) IS DISTINCT FROM 'true' THEN
   RAISE EXCEPTION 'PROGRESS UX PROVENANCE REFUSED: isolated database required';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
  v_user uuid:=gen_random_uuid();
  v_program bigint;
  v_first uuid;
  v_recovery uuid;
  v_recreated uuid;
  v_assessment bigint;
  v_content bigint;
  v_assessment_version text;
  v_question bigint;
  v_reserve_role text;
  v_meta bigint;
  v_checksum text;
  v_auth uuid;
  v_session uuid;
  v_response uuid;
  v_result jsonb;
  v_goal_id text;
  v_plan uuid;
  v_iteration integer;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_user,'authenticated','authenticated','px-provenance@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(v_user,'ProgressUXProvenance',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(v_user,'active',true);
  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
      mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
  SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles
    (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(v_user,v_program,'May/June 2027','A',12,6,1);
  SELECT a.id,a.content_version_id,a.assessment_version,ai.question_id,ai.reserve_role,
         m.id,m.question_snapshot_md5
  INTO v_assessment,v_content,v_assessment_version,v_question,v_reserve_role,v_meta,v_checksum
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
  JOIN private.exam_prep_question_content_meta m ON m.content_version_id=a.content_version_id
      AND m.question_id=ai.question_id
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
    AND ai.primary_skill_code='P1-QUA-01' AND ai.question_id IS NOT NULL
  ORDER BY a.id,ai.item_order LIMIT 1;
  IF v_assessment IS NULL THEN RAISE EXCEPTION 'Real QUA-01 assessment fixture missing'; END IF;

  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,1,'superseded','First-coverage weekly commitment') RETURNING id INTO v_first;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_first,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');

  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>1 THEN
    RAISE EXCEPTION 'First coverage goal snapshot failed'; END IF;
  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  v_goal_id:=v_result->'goals'->0->>'goal_id';

  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(v_user,v_program,'P1',1,2,'active','Different recovery assignment, same skill') RETURNING id INTO v_recovery;
  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(v_recovery,1,'learning','P1-QUA-01','RECOVERY_REFRESH_RETAINED_SKILL');

  v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
  IF v_result->'goals'->0->>'action_priority_order' IS NOT NULL
     OR v_result->'goals'->0->>'plan_changed'<>'true' THEN
    RAISE EXCEPTION 'Recovery action must not masquerade as first-coverage goal: %',v_result;
  END IF;

  -- Two finalized academic sessions, each attached to its OWN plan authorization.
  FOR v_iteration IN 1..2 LOOP
    v_plan:=CASE WHEN v_iteration=1 THEN v_recovery ELSE v_recreated END;
    IF v_iteration=2 THEN
      UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_recovery;
      INSERT INTO private.exam_prep_weekly_plans
        (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
      VALUES(v_user,v_program,'P1',1,3,'active','Original assignment returned') RETURNING id INTO v_recreated;
      INSERT INTO private.exam_prep_weekly_plan_items
        (plan_id,priority_order,item_type,skill_code,action_code)
      VALUES(v_recreated,2,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
      v_plan:=v_recreated;
      v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
      IF v_result->'goals'->0->>'action_priority_order'<>'2' THEN
        RAISE EXCEPTION 'Recreated original assignment must be actionable: %',v_result; END IF;
    END IF;
    INSERT INTO private.exam_prep_session_authorizations
      (user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit,plan_id,plan_priority_order)
    VALUES(v_user,v_assessment,'P1','learning','issued',clock_timestamp()+interval '1 hour',
      'Isolated provenance test',true,v_plan,CASE WHEN v_iteration=1 THEN 1 ELSE 2 END)
    RETURNING id INTO v_auth;
    v_session:=gen_random_uuid();
    INSERT INTO private.exam_prep_sessions
      (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
       assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
    VALUES(v_session,v_auth,v_user,v_program,v_content,v_assessment,v_assessment_version,'P1',
      'learning','active','px-provenance-session-'||v_iteration,1);
    INSERT INTO private.exam_prep_session_items
      (session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
       is_holdout,content_meta_id,question_snapshot_md5,item_version)
    VALUES(v_session,1,'question',v_question,'P1-QUA-01',v_reserve_role,false,
       v_meta,v_checksum,v_assessment_version||'|px-provenance-'||v_iteration);
    INSERT INTO private.exam_prep_responses
      (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
       is_correct,evaluator_version,elapsed_ms)
    VALUES(v_session,1,v_user,'px-provenance-response-'||v_iteration,'machine',
       'isolated-fixture',true,'progress_ux_provenance_fixture',1000) RETURNING id INTO v_response;
    INSERT INTO private.exam_prep_evidence_events
      (user_id,component_code,skill_code,session_id,response_id,evidence_type,
       verification_status,is_correct,evidence_payload,source_version)
    VALUES(v_user,'P1','P1-QUA-01',v_session,v_response,'learning','app_verified',true,
      jsonb_build_object('isolated_fixture','progress_ux_action_provenance'),
      v_assessment_version||'|px-provenance');
    UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
      last_activity_at=clock_timestamp(),finalize_idempotency_key='px-provenance-final-'||v_iteration
    WHERE id=v_session;
    v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
    IF (v_result->>'finalized_study_sessions')::int<>v_iteration
       OR v_result->'goals'->0->>'goal_id'<>v_goal_id
       OR (v_result->'goals'->0->>'finalized_sessions')::int<>v_iteration-1
       OR (v_result->>'completed_goals')::int<>v_iteration-1 THEN
       RAISE EXCEPTION 'Cross-assignment session wrongly credited or original missed: %',v_result;
    END IF;
  END LOOP;
  IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>0 THEN
    RAISE EXCEPTION 'Replanning must not produce extra weekly goals'; END IF;
  RAISE NOTICE 'Progress UX provenance PASS: different action excluded, correct action bound, two real finalized sessions, original goal immutable';
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='ProgressUXProvenance') THEN
  RAISE EXCEPTION 'Provenance fixture leaked into database'; END IF;
 RAISE NOTICE 'Progress UX provenance rollback PASS';
END $$;
