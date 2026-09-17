-- Projection lifecycle matrix: disposable Postgres only; ALL fixture writes roll back.
-- Academic remediation and retest engines are tested separately. This matrix tests
-- their verified facts as consumed by the new presentation/read contract.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('progress_ux.isolated_db',true) IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'PROGRESS UX LIFECYCLE REFUSED: isolated database required';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
 u uuid:=gen_random_uuid(); other_u uuid:=gen_random_uuid();
 prog bigint; case_id uuid; plan_id uuid; assessment bigint; content_id bigint;
 assessment_ver text; question bigint; reserve_role text; meta bigint; checksum text;
 auth_id uuid; session_id uuid; response_id uuid; last_session uuid;
 result jsonb; frozen_id text; n integer; denied boolean:=false;
BEGIN
 INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
 VALUES(u,'authenticated','authenticated','px-life-a@invalid.example',now(),now(),false,false),
       (other_u,'authenticated','authenticated','px-life-b@invalid.example',now(),now(),false,false);
 INSERT INTO public.users(id,first_name,created_at,must_change_password)
 VALUES(u,'ProgressUXLifecycle',now(),false),(other_u,'ProgressUXLifecycle',now(),false);
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
 SELECT a.id,a.content_version_id,a.assessment_version,ai.question_id,ai.reserve_role,
        m.id,m.question_snapshot_md5
 INTO assessment,content_id,assessment_ver,question,reserve_role,meta,checksum
 FROM private.exam_prep_assessments a
 JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
 JOIN private.exam_prep_question_content_meta m ON m.content_version_id=a.content_version_id
                                     AND m.question_id=ai.question_id
 WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
   AND ai.primary_skill_code='P1-CIR-01' AND ai.question_id IS NOT NULL
 ORDER BY a.id,ai.item_order LIMIT 1;
 IF assessment IS NULL THEN RAISE EXCEPTION 'Learning fixture missing'; END IF;

 -- Five distinct historical plan versions; each has one separate finalized session.
 FOR n IN 1..5 LOOP
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u,prog,'P1',1,n,'superseded','Projection lifecycle fixture') RETURNING id INTO plan_id;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
  VALUES(plan_id,1,'correction','P1-CIR-01',case_id,'COMPLETE_CORRECTION_ANALOGUES');
  IF n=1 THEN
   INSERT INTO private.exam_prep_weekly_plan_items
   (plan_id,priority_order,item_type,skill_code,action_code)
   VALUES(plan_id,2,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE'),
         (plan_id,3,'learning','P1-QUA-02','BUILD_FIRST_COVERAGE');
  END IF;
  INSERT INTO private.exam_prep_session_authorizations
  (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
   academic_credit,plan_id,plan_priority_order)
  VALUES(u,assessment,'P1','learning','issued',clock_timestamp()+interval '1 hour',
         'Disposable finalized-history fixture',true,plan_id,1) RETURNING id INTO auth_id;
  session_id:=gen_random_uuid();
  INSERT INTO private.exam_prep_sessions
  (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
   assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
  VALUES(session_id,auth_id,u,prog,content_id,assessment,assessment_ver,'P1',
         'learning','active','px-life-session-'||n::text,1);
  INSERT INTO private.exam_prep_session_items
  (session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
   is_holdout,content_meta_id,question_snapshot_md5,item_version)
  VALUES(session_id,1,'question',question,'P1-CIR-01',reserve_role,
         false,meta,checksum,assessment_ver||'|px-life-'||n::text);
  INSERT INTO private.exam_prep_responses
  (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
   is_correct,evaluator_version,elapsed_ms)
  VALUES(session_id,1,u,'px-life-response-'||n::text,'machine','isolated-fixture',
         true,'progress_ux_projection_fixture',1000) RETURNING id INTO response_id;
  INSERT INTO private.exam_prep_evidence_events
  (user_id,component_code,skill_code,session_id,response_id,evidence_type,
   verification_status,is_correct,evidence_payload,source_version)
  VALUES(u,'P1','P1-CIR-01',session_id,response_id,'learning','app_verified',true,
         jsonb_build_object('isolated_fixture','progress_ux_lifecycle'),assessment_ver||'|px-life');
  UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
    last_activity_at=clock_timestamp(),finalize_idempotency_key='px-life-final-'||n::text
  WHERE id=session_id;
  last_session:=session_id;
 END LOOP;
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(u,prog,'P1',1,6,'active','Current plan') RETURNING id INTO plan_id;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
 VALUES(plan_id,1,'correction','P1-CIR-01',case_id,'COMPLETE_CORRECTION_ANALOGUES');
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(u,prog,'P5',1,1,'active','Independent P5 plan') RETURNING id INTO plan_id;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,action_code)
 VALUES(plan_id,1,'learning','P5-DAT-01','BUILD_FIRST_COVERAGE');
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>3 THEN
  RAISE EXCEPTION 'First P1 snapshot failed'; END IF;
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF (result->>'finalized_study_sessions')::int<>5 OR (result->>'completed_goals')::int<>0
    OR (result->'goals'->0->>'finalized_sessions')::int<>5
    OR result->'goals'->0->>'status'<>'in_progress' THEN
  RAISE EXCEPTION 'Five sessions must count once without fabricated mastery: %',result; END IF;
 frozen_id:=result->'goals'->0->>'goal_id';
 IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>0 THEN
  RAISE EXCEPTION 'Snapshot is not idempotent'; END IF;
 IF (public.ensure_exam_prep_weekly_goals_safe_v1('P5')->>'created')::int<>1 THEN
  RAISE EXCEPTION 'P5 snapshot missing'; END IF;
 result:=public.get_exam_prep_weekly_progress_safe_v1('P5');
 IF jsonb_array_length(result->'goals')<>1 OR (result->>'finalized_study_sessions')::int<>0 THEN
  RAISE EXCEPTION 'P1 history leaked into P5: %',result; END IF;

 -- Project an already-verified remediation action; academic-engine validation is separate.
 INSERT INTO private.exam_prep_correction_actions
 (correction_case_id,user_id,component_code,skill_code,action_type,session_id,payload)
 VALUES(case_id,u,'P1','P1-CIR-01','remediation_completed',last_session,
        jsonb_build_object('isolated_projection_fixture',true));
 UPDATE private.exam_prep_correction_cases SET status='retest_due' WHERE id=case_id;
 INSERT INTO private.exam_prep_retest_events
 (correction_case_id,user_id,component_code,skill_code,status,due_not_before)
 VALUES(case_id,u,'P1','P1-CIR-01','scheduled',now()+interval '2 days');
 UPDATE private.exam_prep_weekly_plans SET status='superseded'
 WHERE user_id=u AND component_code='P1' AND status='active';
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(u,prog,'P1',1,7,'active','Retest plan') RETURNING id INTO plan_id;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code)
 VALUES(plan_id,1,'retest','P1-CIR-01',case_id,now()+interval '2 days','COMPLETE_DELAYED_RETEST');
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF (result->>'completed_goals')::int<>1 OR result->'goals'->0->>'status'<>'waiting_retest'
    OR result->'goals'->0->>'correction_open'<>'true'
    OR result->'goals'->0->>'retest_due_at' IS NULL
    OR result->'goals'->0->>'goal_id'<>frozen_id THEN
  RAISE EXCEPTION 'Remediation complete must preserve the open correction: %',result; END IF;
 UPDATE private.exam_prep_correction_cases SET status='reopened' WHERE id=case_id;
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF result->'goals'->0->>'status'<>'needs_rework' OR
    (result->>'completed_goals')::int<>1 OR result->'goals'->0->>'correction_open'<>'true' THEN
  RAISE EXCEPTION 'Reopened case must preserve work, not claim closure: %',result; END IF;
 UPDATE private.exam_prep_correction_cases SET status='resolved' WHERE id=case_id;
 UPDATE private.exam_prep_retest_events SET status='completed' WHERE correction_case_id=case_id;
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF result->'goals'->0->>'status'<>'completed' OR result->'goals'->0->>'correction_open'<>'false' THEN
  RAISE EXCEPTION 'Resolved correction projection wrong: %',result; END IF;

 -- Urgent replan cannot erase the frozen first-week denominator or provenance.
 UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=plan_id;
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(u,prog,'P1',1,8,'active','Urgent replan') RETURNING id INTO plan_id;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,action_code)
 VALUES(plan_id,1,'learning','P1-DIF-01','BUILD_FIRST_COVERAGE');
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF jsonb_array_length(result->'goals')<>3 OR (result->>'completed_goals')::int<>1
    OR result->'goals'->0->>'goal_id'<>frozen_id
    OR result->'goals'->1->>'plan_changed'<>'true' THEN
  RAISE EXCEPTION 'Urgent replan reset earlier commitments: %',result; END IF;

 -- New active week gets its own denominator, while five past sessions survive.
 UPDATE private.exam_prep_exam_profiles SET active_week_no=2 WHERE user_id=u;
 UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=plan_id;
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(u,prog,'P1',2,1,'active','New week') RETURNING id INTO plan_id;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,action_code)
 VALUES(plan_id,1,'learning','P1-QUA-01','BUILD_FIRST_COVERAGE');
 IF (public.ensure_exam_prep_weekly_goals_safe_v1('P1')->>'created')::int<>1 THEN
  RAISE EXCEPTION 'New-week first goal was not anchored'; END IF;
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF jsonb_array_length(result->'goals')<>1 OR (result->>'completed_goals')::int<>0
    OR (result->>'finalized_study_sessions')::int<>5 OR
    (SELECT count(*) FROM private.exam_prep_weekly_goal_snapshots
     WHERE user_id=u AND component_code='P1')<>4 THEN
  RAISE EXCEPTION 'Week rollover erased history or invented work: %',result; END IF;

 PERFORM set_config('request.jwt.claim.sub',other_u::text,true);
 result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF result->>'plan_available'<>'false' OR jsonb_array_length(result->'goals')<>0
    OR (result->>'finalized_study_sessions')::int<>0 THEN
  RAISE EXCEPTION 'Cross-user history leak: %',result; END IF;
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 UPDATE private.exam_prep_feature_entitlements SET core_access=false WHERE user_id=u;
 BEGIN
  PERFORM public.get_exam_prep_weekly_progress_safe_v1('P1');
 EXCEPTION WHEN OTHERS THEN denied:=true;
 END;
 IF NOT denied THEN RAISE EXCEPTION 'Revoked Core must fail closed'; END IF;
 RAISE NOTICE 'Progress UX lifecycle PASS: five sessions, P1/P5, retest, reopen, replan, rollover, isolation';
END;
$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='ProgressUXLifecycle') THEN
  RAISE EXCEPTION 'Progress UX lifecycle synthetic residue'; END IF;
 RAISE NOTICE 'Progress UX lifecycle rollback PASS';
END $$;
