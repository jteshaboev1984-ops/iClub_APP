-- ISOLATED PostgreSQL 17 ONLY. All artificial changes ROLLBACK.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'REVIEW MODELS FIXTURE REFUSED: disposable DB required'; END IF;
END $$;
BEGIN;
DO $read$
DECLARE
 u uuid; plan uuid; goal uuid; outcome jsonb; recovery jsonb; sid uuid; old_sid uuid; c uuid;
BEGIN
 SELECT user_id,plan_id,goal_id INTO STRICT u,plan,goal FROM weekly_goal_ci.fixture;
 SELECT id INTO STRICT old_sid FROM private.exam_prep_sessions WHERE user_id=u AND status='finalized';
 INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(u,'P1','P1-QUA-01','open','objective_state_v1','{"source":"read_model_fixture"}'::jsonb)
 RETURNING id INTO c;
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 outcome:=public.get_exam_prep_goal_action_state_safe_v1('P1',goal,plan);
 IF outcome->>'status'<>'review_ready' OR outcome->>'reason'<>'same_pack_learning_review'
 OR outcome->>'goal_id'<>goal::text OR outcome->>'plan_id'<>plan::text
 OR outcome->>'fresh_assessment'<>'false' THEN
  RAISE EXCEPTION 'previously failed goal was not offered labelled review: %',outcome; END IF;
 outcome:=public.start_exam_prep_learning_review_safe_v1('P1',goal,plan,'models-review-idempotency-001');
 IF outcome->>'status'<>'started' THEN RAISE EXCEPTION 'review did not start: %',outcome; END IF;
 sid:=(outcome->>'session_id')::uuid;
 recovery:=public.get_exam_prep_active_plan_session_safe_v1('P1');
 IF recovery->>'status'<>'resume' OR recovery->>'session_id'<>sid::text OR
    recovery->>'source_plan_id'<>plan::text OR
    recovery->>'first_unanswered_item_order'<>'1' OR
    recovery->>'source_plan_priority_order'<>'1' THEN
  RAISE EXCEPTION 'existing recovery lost active written/review session: %',recovery; END IF;
 outcome:=public.start_exam_prep_plan_session_once_safe_v1(
  (SELECT authorization_id FROM private.exam_prep_sessions WHERE id=old_sid),
  'models-other-goal-idem-001');
 IF outcome->>'status'<>'attempt_already_saved' OR outcome?'session_id' THEN
  RAISE EXCEPTION 'finalized original replayed while review active: %',outcome; END IF;
 IF (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=u AND status='active')<>1 THEN
  RAISE EXCEPTION 'review recovery created extra live session'; END IF;
 RAISE NOTICE 'REVIEW RECOVERY GREEN: exact old goal, active noncredit review recovered, original saved attempt protected';
END;$read$;
ROLLBACK;

BEGIN;
DO $accounting$
DECLARE
 u uuid; v_prog bigint; old_plan uuid; new_plan uuid; new_goal uuid;
 old_sid uuid; v_ass bigint; v_case uuid; v_sid uuid; v_out jsonb;
 v_before jsonb; v_after jsonb; v_row record;
BEGIN
 SELECT f.user_id,f.plan_id,p.program_version_id INTO STRICT u,old_plan,v_prog
 FROM weekly_goal_ci.fixture f JOIN private.exam_prep_exam_profiles p ON p.user_id=f.user_id;
 SELECT s.id,s.assessment_id INTO STRICT old_sid,v_ass FROM private.exam_prep_sessions s
 WHERE s.user_id=u AND s.component_code='P1' AND s.status='finalized';
 INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(u,'P1','P1-QUA-01','open','objective_state_v1','{"source":"accounting_fixture"}'::jsonb)
 RETURNING id INTO v_case;
 UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=old_plan;
 INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,active_week_no,
  plan_version,status,policy_note)
 VALUES(u,v_prog,'P1',1,2,'active','Synthetic correction weekly target') RETURNING id INTO new_plan;
 INSERT INTO private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,
  correction_case_id,action_code)
 VALUES(new_plan,2,'correction','P1-QUA-01',v_case,'COMPLETE_CORRECTION_ANALOGUES');
 INSERT INTO private.exam_prep_weekly_goal_snapshots(user_id,program_version_id,component_code,
  active_week_no,priority_order,source_plan_id,item_type,skill_code,correction_case_id,action_code)
 VALUES(u,v_prog,'P1',1,2,new_plan,'correction','P1-QUA-01',v_case,'COMPLETE_CORRECTION_ANALOGUES')
 RETURNING id INTO new_goal;
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 v_before:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF (SELECT COALESCE((g->>'weekly_commitment_complete')::boolean,false)
     FROM jsonb_array_elements(v_before->'goals') g WHERE g->>'goal_id'=new_goal::text) THEN
  RAISE EXCEPTION 'correction was falsely complete before work: %',v_before; END IF;
 v_out:=public.get_exam_prep_goal_action_state_safe_v1('P1',new_goal,new_plan);
 IF v_out->>'status'<>'review_ready' THEN
  RAISE EXCEPTION 'correction goal not offered review: %',v_out; END IF;
 v_out:=public.start_exam_prep_learning_review_safe_v1('P1',new_goal,new_plan,
  'accounting-review-unique-001');
 IF v_out->>'status'<>'started' THEN RAISE EXCEPTION 'correction review start failed: %',v_out; END IF;
 v_sid:=(v_out->>'session_id')::uuid;
 FOR v_row IN SELECT item_order,item_kind FROM private.exam_prep_session_items WHERE session_id=v_sid LOOP
  IF v_row.item_kind='written' THEN
   INSERT INTO private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,
    response_kind,learner_artifact,evaluator_version,elapsed_ms)
   VALUES(v_sid,v_row.item_order,u,'accounting-written-'||v_row.item_order::text,
    'written','{"text":"synthetic reasoning"}'::jsonb,'fixture',200);
  ELSE
   INSERT INTO private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,
    response_kind,user_answer,is_correct,evaluator_version,elapsed_ms)
   VALUES(v_sid,v_row.item_order,u,'accounting-machine-'||v_row.item_order::text,
    'machine','fixture',true,'fixture',200);
  END IF;
 END LOOP;
 UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
  finalize_idempotency_key='accounting-review-final-001' WHERE id=v_sid;
 v_after:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF NOT (SELECT COALESCE((g->>'weekly_commitment_complete')::boolean,false)
       FROM jsonb_array_elements(v_after->'goals') g WHERE g->>'goal_id'=new_goal::text)
 OR (SELECT status FROM private.exam_prep_correction_cases WHERE id=v_case)<>'retest_due'
 OR (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=old_sid)<>4 THEN
  RAISE EXCEPTION 'completed remediation was not attributed to exact weekly correction: %',v_after;
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_evidence_events
    WHERE session_id=v_sid AND verification_status='app_verified') THEN
  RAISE EXCEPTION 'weekly remediation contaminated independent mastery'; END IF;
 RAISE NOTICE 'REVIEW ACCOUNTING GREEN: correction goal completed by actual remediation, original answers and mastery preserved';
END;$accounting$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions
   WHERE client_idempotency_key IN ('models-review-idempotency-001','accounting-review-unique-001')) THEN
  RAISE EXCEPTION 'read-model fixture leaked synthetic attempts'; END IF;
 RAISE NOTICE 'REVIEW READ MODELS ROLLBACK GREEN';
END $$;
