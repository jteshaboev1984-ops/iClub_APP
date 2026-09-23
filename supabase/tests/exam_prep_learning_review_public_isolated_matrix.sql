-- DISPOSABLE CI POSTGRES 17 ONLY. Synthetic writes ROLLBACK in full.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'REVIEW START FIXTURE REFUSED outside isolated CI'; END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
 v_uid uuid; v_program bigint; v_plan uuid; v_goal uuid;
 v_prior private.exam_prep_sessions%rowtype;
 v_case uuid; v_result jsonb; v_id uuid; v_auth uuid;
 v_initial_responses integer; v_initial_auths integer;
 v_denied boolean:=false; v_status text;
BEGIN
 SELECT f.user_id,f.plan_id,f.goal_id,p.program_version_id
 INTO STRICT v_uid,v_plan,v_goal,v_program
 FROM weekly_goal_ci.fixture f JOIN private.exam_prep_exam_profiles p ON p.user_id=f.user_id;
 SELECT * INTO STRICT v_prior FROM private.exam_prep_sessions s
 WHERE s.user_id=v_uid AND s.program_version_id=v_program AND s.component_code='P1'
 AND s.status='finalized' AND s.session_type='learning';
 SELECT count(*) INTO v_initial_responses FROM private.exam_prep_responses WHERE session_id=v_prior.id;
 SELECT count(*) INTO v_initial_auths FROM private.exam_prep_session_authorizations WHERE user_id=v_uid;
 IF v_initial_responses<>4 THEN RAISE EXCEPTION 'original synthetic answer history incomplete'; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 e
  WHERE e.user_id=v_uid AND e.enabled) IS FALSE THEN RAISE EXCEPTION 'synthetic enrolment prerequisite absent'; END IF;
 INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(v_uid,'P1','P1-QUA-01','open','objective_state_v1',
        '{"source":"synthetic_review_validation"}'::jsonb) RETURNING id INTO v_case;
 PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',v_goal,v_plan,'review-start-unique-id-001');
 IF v_result->>'status'<>'started' OR v_result->>'repeat_learning'<>'true'
 OR v_result->>'academic_credit'<>'false' OR v_result->>'not_a_new_independent_check'<>'true'
 OR v_result->>'session_id' IS NULL THEN
  RAISE EXCEPTION 'atomic review did not start: %',v_result; END IF;
 v_id:=(v_result->>'session_id')::uuid;
 SELECT a.id INTO STRICT v_auth FROM private.exam_prep_session_authorizations a
 JOIN private.exam_prep_learning_review_starts_v1 r ON r.authorization_id=a.id
 WHERE r.user_id=v_uid AND r.goal_id=v_goal AND r.plan_id=v_plan AND r.correction_case_id=v_case;
 IF EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations
   WHERE id=v_auth AND (academic_credit IS TRUE OR plan_id IS NOT NULL
     OR credit_context<>'learning_review' OR consumed_session_id<>v_id)) THEN
  RAISE EXCEPTION 'review authorization scope wrong'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_session_items WHERE session_id=v_id)<>4 OR
    (SELECT array_agg(question_id ORDER BY item_order) FROM private.exam_prep_session_items
      WHERE session_id=v_id AND question_id IS NOT NULL) IS DISTINCT FROM
    (SELECT array_agg(question_id ORDER BY item_order) FROM private.exam_prep_session_items
      WHERE session_id=v_prior.id AND question_id IS NOT NULL) THEN
  RAISE EXCEPTION 'same-pack review did not retain original frozen question identities'; END IF;
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',v_goal,v_plan,'review-start-unique-id-002');
 IF v_result->>'status'<>'resume_existing_session_first' OR (v_result->>'session_id')::uuid<>v_id THEN
  RAISE EXCEPTION 'repeat click started different review: %',v_result; END IF;
 IF (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=v_uid)<>v_initial_auths+1 OR
    (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_uid)<>2 THEN
  RAISE EXCEPTION 'double click created duplicate review authorization or session'; END IF;
 PERFORM set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
 BEGIN
  PERFORM public.start_exam_prep_learning_review_safe_v1('P1',v_goal,v_plan,'foreign-review-key-0001');
 EXCEPTION WHEN OTHERS THEN v_denied:=true;
 END;
 IF NOT v_denied THEN RAISE EXCEPTION 'foreign learner accessed review'; END IF;
 PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
 -- Simulate correctly solved original questions WITHOUT trusting a browser score.
 INSERT INTO private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,
  response_kind,user_answer,is_correct,evaluator_version,elapsed_ms)
 SELECT v_id,si.item_order,v_uid,'review-real-machine-'||si.item_order::text,
  'machine','synthetic',true,'isolated-review',300
 FROM private.exam_prep_session_items si WHERE si.session_id=v_id AND si.question_id IS NOT NULL;
 INSERT INTO private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,
  response_kind,learner_artifact,evaluator_version,elapsed_ms)
 SELECT v_id,si.item_order,v_uid,'review-real-written-'||si.item_order::text,
  'written','{"text":"synthetic work"}'::jsonb,'isolated-review',300
 FROM private.exam_prep_session_items si WHERE si.session_id=v_id AND si.written_task_id IS NOT NULL;
 INSERT INTO private.exam_prep_evidence_events(user_id,component_code,skill_code,session_id,response_id,
  evidence_type,verification_status,is_correct,evidence_payload,source_version)
 SELECT v_uid,'P1','P1-QUA-01',v_id,r.id,'learning','app_verified',true,'{}'::jsonb,'isolated'
 FROM private.exam_prep_responses r WHERE r.session_id=v_id AND r.response_kind='machine';
 IF EXISTS(SELECT 1 FROM private.exam_prep_evidence_events
  WHERE session_id=v_id AND verification_status='app_verified') OR
    (SELECT count(*) FROM private.exam_prep_evidence_events
       WHERE session_id=v_id AND verification_status='app_checked_noncredit')<>3 THEN
  RAISE EXCEPTION 'repeated known questions received independent academic credit'; END IF;
 UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
  finalize_idempotency_key='review-final-unique-001' WHERE id=v_id;
 SELECT status INTO STRICT v_status FROM private.exam_prep_correction_cases WHERE id=v_case;
 IF v_status<>'retest_due' OR NOT EXISTS(
   SELECT 1 FROM private.exam_prep_retest_events r WHERE r.correction_case_id=v_case
    AND r.status='scheduled' AND r.due_not_before>private.exam_prep_effective_academic_now_v1(v_uid)) OR
    EXISTS(SELECT 1 FROM private.exam_prep_correction_actions a
      WHERE a.correction_case_id=v_case AND a.action_type='case_closed') THEN
  RAISE EXCEPTION 'review incorrectly closed case without fresh delayed retest'; END IF;
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',v_goal,v_plan,'review-start-unique-id-001');
 IF v_result->>'status'<>'attempt_already_saved' OR v_result?'session_id' THEN
  RAISE EXCEPTION 'finalized review replay exposed a saved session ID: %',v_result; END IF;
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',v_goal,v_plan,'review-start-unique-id-003');
 IF v_result->>'status' NOT IN ('waiting','stale') OR v_result?'session_id' THEN
  RAISE EXCEPTION 'new repeat started after remediation completed: %',v_result; END IF;
 IF (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=v_prior.id)<>v_initial_responses
 OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_prior.id)<>'finalized'
 OR EXISTS(SELECT 1 FROM private.exam_prep_evidence_events
     WHERE session_id=v_id AND verification_status='app_verified') THEN
  RAISE EXCEPTION 'historical responses or independent evidence changed'; END IF;
 RAISE NOTICE 'REVIEW PUBLIC END-TO-END GREEN: original IDs, noncredit, exact binding, duplicate click, owner, 3/3 written, separate fresh retest, history intact';
END;$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions
   WHERE client_idempotency_key='review-start-unique-id-001') THEN
  RAISE EXCEPTION 'review public fixture leaked synthetic rows'; END IF;
 RAISE NOTICE 'REVIEW PUBLIC FIXTURE ROLLBACK GREEN';
END $$;
