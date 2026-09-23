-- Isolated PostgreSQL 17 ONLY. Disposable synthetic users, transaction ROLLBACK.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
   RAISE EXCEPTION 'WEEKLY GOAL FIXTURE REFUSED: isolated database only';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
  u uuid:=gen_random_uuid(); other_u uuid:=gen_random_uuid();
  prog bigint; case_id uuid; old_plan uuid; new_plan uuid; goal_id uuid;
  ass bigint; cv bigint; av text; auth_id uuid; sid uuid:=gen_random_uuid();
  result jsonb; n integer; r record; denied boolean:=false;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(u,'authenticated','authenticated','weekly-proposal-a@invalid.example',now(),now(),false,false),
        (other_u,'authenticated','authenticated','weekly-proposal-b@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES(u,'WeeklyProposalFixture',now(),false),(other_u,'WeeklyProposalFixture',now(),false);
  INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
  VALUES(u,'active',true),(other_u,'active',true);
  UPDATE private.exam_prep_feature_config
    SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
        mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
  SELECT id INTO STRICT prog FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  INSERT INTO private.exam_prep_exam_profiles
  (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
  VALUES(u,prog,'May/June 2027','A',12,6,1),
        (other_u,prog,'May/June 2027','A',12,6,1);
  INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status)
  VALUES(u,'P1','P1-CIR-01','remediating') RETURNING id INTO case_id;
  SELECT a.id,a.content_version_id,a.assessment_version
    INTO STRICT ass,cv,av
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
               WHERE ai.assessment_id=a.id AND ai.primary_skill_code='P1-CIR-01')
  ORDER BY a.id LIMIT 1;
  SELECT count(*) INTO n FROM private.exam_prep_assessment_items WHERE assessment_id=ass;
  IF n<>4 THEN RAISE EXCEPTION 'Expected governed four-item learning pack, got %',n; END IF;

  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,1,'active','Isolated old plan') RETURNING id INTO old_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
  VALUES(old_plan,1,'correction','P1-CIR-01',case_id,'COMPLETE_CORRECTION_ANALOGUES');
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(old_plan,2,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
  IF (result->>'created')::integer<>2 THEN
    RAISE EXCEPTION 'Expected two frozen goals: %',result;
  END IF;
  SELECT id INTO STRICT goal_id FROM private.exam_prep_weekly_goal_snapshots
  WHERE user_id=u AND component_code='P1' AND active_week_no=1
    AND correction_case_id=case_id AND priority_order=1;
  result:=public.get_exam_prep_goal_action_state_safe_v1('P1',goal_id,old_plan);
  IF result->>'status'<>'ready' OR (result->>'priority_order')::int<>1 THEN
    RAISE EXCEPTION 'Original goal not verified: %',result;
  END IF;

  INSERT INTO private.exam_prep_session_authorizations
  (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
   academic_credit,plan_id,plan_priority_order,correction_case_id)
  VALUES(u,ass,'P1','learning','issued',clock_timestamp()+interval '1 hour',
         'Isolated session replan fixture',true,old_plan,1,case_id)
  RETURNING id INTO auth_id;
  INSERT INTO private.exam_prep_sessions
  (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
   assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
  VALUES(sid,auth_id,u,prog,cv,ass,av,'P1','learning','active','weekly-proposal-session-01',4);
  INSERT INTO private.exam_prep_session_items
  (session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,
   reserve_role,is_holdout,content_meta_id,question_snapshot_md5,item_version)
  SELECT sid,ai.item_order,
         CASE WHEN ai.question_id IS NOT NULL THEN 'question' ELSE 'written' END,
         ai.question_id,ai.written_task_id,ai.primary_skill_code,ai.reserve_role,
         ai.is_holdout,m.id,m.question_snapshot_md5,
         CASE WHEN ai.question_id IS NOT NULL THEN 'qmd5:'||m.question_snapshot_md5
              ELSE 'written:'||wt.task_version END
  FROM private.exam_prep_assessment_items ai
  LEFT JOIN private.exam_prep_question_content_meta m
    ON m.question_id=ai.question_id AND m.content_version_id=cv
  LEFT JOIN private.exam_prep_written_tasks wt
    ON wt.id=ai.written_task_id AND wt.content_version_id=cv
  WHERE ai.assessment_id=ass;
  SELECT count(*) INTO n FROM private.exam_prep_session_items WHERE session_id=sid;
  IF n<>4 THEN RAISE EXCEPTION 'Four session items were not frozen'; END IF;
  UPDATE private.exam_prep_session_authorizations
    SET status='consumed',consumed_at=now(),consumed_session_id=sid WHERE id=auth_id;
  FOR r IN SELECT item_order FROM private.exam_prep_session_items
           WHERE session_id=sid AND item_kind='question' ORDER BY item_order LIMIT 3 LOOP
    INSERT INTO private.exam_prep_responses
    (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
     is_correct,evaluator_version,elapsed_ms)
    VALUES(sid,r.item_order,u,'weekly-proposal-response-'||r.item_order::text,
           'machine','fixture',false,'isolated-recovery-matrix',1000);
  END LOOP;
  result:=public.get_exam_prep_active_plan_session_safe_v1('P1');
  IF result->>'status'<>'resume' OR (result->>'session_id')::uuid<>sid
     OR (result->>'first_unanswered_item_order')::integer<>4
     OR (result->>'answered_items')::integer<>3 THEN
    RAISE EXCEPTION 'First unanswered item 4 not recovered: %',result;
  END IF;
  IF (public.get_exam_prep_active_plan_session_safe_v1('P5')->>'status')<>'none' THEN
    RAISE EXCEPTION 'P1 active session leaked into P5'; END IF;

  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=old_plan;
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,2,'active','Reordered plan') RETURNING id INTO new_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,action_code)
  VALUES(new_plan,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
  VALUES(new_plan,2,'correction','P1-CIR-01',case_id,'COMPLETE_CORRECTION_ANALOGUES');
  result:=public.get_exam_prep_active_plan_session_safe_v1('P1');
  IF result->>'status'<>'resume' OR (result->>'session_id')::uuid<>sid
     OR result->>'source_plan_status'<>'superseded' THEN
    RAISE EXCEPTION 'Replan orphaned active session: %',result;
  END IF;
  result:=public.get_exam_prep_goal_action_state_safe_v1('P1',goal_id,new_plan);
  IF result->>'status'<>'waiting' OR result->>'reason'<>'resume_existing_session_first' THEN
    RAISE EXCEPTION 'New goal must resume old session first: %',result;
  END IF;
  UPDATE private.exam_prep_exam_profiles SET active_week_no=2 WHERE user_id=u;
  result:=public.get_exam_prep_active_plan_session_safe_v1('P1');
  IF result->>'status'<>'resume' OR (result->>'session_id')::uuid<>sid
     OR (result->>'first_unanswered_item_order')::integer<>4 THEN
    RAISE EXCEPTION 'Week rollover orphaned the active session: %',result;
  END IF;
  result:=public.get_exam_prep_goal_action_state_safe_v1('P1',goal_id,new_plan);
  IF result->>'status'<>'stale' THEN RAISE EXCEPTION 'Old-week goal remained actionable: %',result; END IF;
  UPDATE private.exam_prep_exam_profiles SET active_week_no=1 WHERE user_id=u;

  PERFORM set_config('request.jwt.claim.sub',other_u::text,true);
  result:=public.get_exam_prep_active_plan_session_safe_v1('P1');
  IF result->>'status'<>'none' OR result?'session_id' THEN
    RAISE EXCEPTION 'Cross-user session disclosure: %',result;
  END IF;
  result:=public.get_exam_prep_goal_action_state_safe_v1('P1',goal_id,new_plan);
  IF result->>'status'<>'stale' OR result?'session_id' THEN
    RAISE EXCEPTION 'Cross-user goal disclosure: %',result;
  END IF;
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  INSERT INTO private.exam_prep_responses
  (session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,
   evaluator_version,elapsed_ms)
  VALUES(sid,4,u,'weekly-proposal-response-written-04','written',
         jsonb_build_object('text','isolated sample only'),'isolated-recovery-matrix',1000);
  result:=public.get_exam_prep_active_plan_session_safe_v1('P1');
  IF result->>'status'<>'ready_to_finalize' OR (result->>'session_id')::uuid<>sid
     OR (result->>'answered_items')::integer<>4 OR result->'first_unanswered_item_order'<>'null'::jsonb THEN
    RAISE EXCEPTION 'All answers saved must offer same-session finalization: %',result;
  END IF;
  UPDATE private.exam_prep_sessions
    SET status='finalized',finalized_at=clock_timestamp(),
        finalize_idempotency_key='weekly-proposal-finalize-01' WHERE id=sid;
  result:=public.get_exam_prep_active_plan_session_safe_v1('P1');
  IF result->>'status'<>'none' OR result?'session_id' THEN
    RAISE EXCEPTION 'Finalized session replayed via resume: %',result;
  END IF;
  result:=public.get_exam_prep_goal_action_state_safe_v1('P1',goal_id,new_plan);
  IF result->>'status'<>'content_exhausted'
     OR result->>'reason'<>'previously_seen_learning_pack' THEN
    RAISE EXCEPTION 'Exposed learning pack advertised as fresh evidence: %',result;
  END IF;
  UPDATE private.exam_prep_feature_entitlements SET core_access=false WHERE user_id=u;
  BEGIN
    PERFORM public.get_exam_prep_active_plan_session_safe_v1('P1');
  EXCEPTION WHEN OTHERS THEN denied:=true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Revoked user was allowed session discovery'; END IF;
  RAISE NOTICE 'ISOLATED WEEKLY GOAL MATRIX GREEN: goal identity, item4, P1/P5, replan, rollover, cross-user, finalized, content exhaustion, revocation';
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='WeeklyProposalFixture') THEN
   RAISE EXCEPTION 'Synthetic user residue after rollback';
 END IF;
 RAISE NOTICE 'ISOLATED WEEKLY GOAL MATRIX ROLLBACK GREEN';
END $$;
