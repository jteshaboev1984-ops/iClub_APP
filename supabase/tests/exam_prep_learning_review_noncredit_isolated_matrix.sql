-- DISPOSABLE GitHub Actions PostgreSQL 17 ONLY. No production SQL writes.
-- This synthetic fixture bypasses authorization intentionally to test existing
-- finalization semantics; it does NOT prove public repeat authorization is ready.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true' THEN
   RAISE EXCEPTION 'LEARNING REVIEW FIXTURE REFUSED: isolated DB required';
 END IF;
END $$;
BEGIN;
DO $matrix$
DECLARE
 v_uid uuid; v_program bigint; v_old private.exam_prep_sessions%rowtype;
 v_case uuid; v_auth uuid; v_review uuid; v_status jsonb;
 v_old_responses integer; v_review_items integer; v_review_responses integer;
 v_old_questions bigint[]; v_review_questions bigint[];
BEGIN
 SELECT f.user_id,p.program_version_id INTO STRICT v_uid,v_program
 FROM weekly_goal_ci.fixture f JOIN private.exam_prep_exam_profiles p ON p.user_id=f.user_id;
 SELECT * INTO STRICT v_old FROM private.exam_prep_sessions
 WHERE user_id=v_uid AND program_version_id=v_program AND component_code='P1'
   AND status='finalized' AND session_type='learning';
 SELECT count(*) INTO v_old_responses FROM private.exam_prep_responses WHERE session_id=v_old.id;
 SELECT array_agg(question_id ORDER BY item_order) INTO v_old_questions
 FROM private.exam_prep_session_items WHERE session_id=v_old.id AND question_id IS NOT NULL;
 IF v_old_responses<>4 OR array_length(v_old_questions,1)<>3 OR EXISTS(
   SELECT 1 FROM private.exam_prep_responses WHERE session_id=v_old.id AND is_correct IS TRUE
 ) THEN RAISE EXCEPTION 'Unexpected synthetic first-learning fixture'; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_correction_cases
    WHERE user_id=v_uid AND component_code='P1' AND skill_code='P1-QUA-01'
      AND status IN ('open','remediating','reopened','retest_due')) THEN
   RAISE EXCEPTION 'Expected clean synthetic correction baseline';
 END IF;

 v_status:=private.exam_prep_learning_review_verdict_v1(v_uid,v_program,'P1','P1-QUA-01',v_old.assessment_id);
 IF v_status->>'status'<>'repeat_learning' OR v_status->>'fresh_assessment'<>'false' THEN
   RAISE EXCEPTION 'Unsolved first attempt must offer labelled repeat: %',v_status;
 END IF;
 INSERT INTO private.exam_prep_correction_cases
   (user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(v_uid,'P1','P1-QUA-01','open','objective_state_v1',
        '{"source":"isolated_learning_review"}'::jsonb)
 RETURNING id INTO v_case;
 INSERT INTO private.exam_prep_session_authorizations
   (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
    correction_case_id,academic_credit,credit_context)
 VALUES(v_uid,v_old.assessment_id,'P1','learning','issued',now()+interval '1 hour',
        'Isolated duplicate-content review only',v_case,false,'learning_review')
 RETURNING id INTO v_auth;
 INSERT INTO private.exam_prep_sessions
   (authorization_id,user_id,program_version_id,content_version_id,assessment_id,
    assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
 VALUES(v_auth,v_uid,v_program,v_old.content_version_id,v_old.assessment_id,
        v_old.assessment_version,'P1','learning','active','synthetic-review-unique-id-001',4)
 RETURNING id INTO v_review;
 INSERT INTO private.exam_prep_session_items
   (session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,
    reserve_role,is_holdout,content_meta_id,question_snapshot_md5,item_version)
 SELECT v_review,item_order,item_kind,question_id,written_task_id,primary_skill_code,
        reserve_role,is_holdout,content_meta_id,question_snapshot_md5,item_version
 FROM private.exam_prep_session_items WHERE session_id=v_old.id;
 SELECT count(*),array_agg(question_id ORDER BY item_order) FILTER(WHERE question_id IS NOT NULL)
 INTO v_review_items,v_review_questions FROM private.exam_prep_session_items WHERE session_id=v_review;
 IF v_review_items<>4 OR v_review_questions IS DISTINCT FROM v_old_questions THEN
   RAISE EXCEPTION 'Review must keep exactly same three original objective items';
 END IF;
 UPDATE private.exam_prep_session_authorizations
 SET status='consumed',consumed_at=now(),consumed_session_id=v_review WHERE id=v_auth;
 INSERT INTO private.exam_prep_responses
   (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
    is_correct,evaluator_version,elapsed_ms)
 SELECT v_review,si.item_order,v_uid,'synthetic-review-machine-'||si.item_order::text,
        'machine','synthetic correct',true,'isolated-review',500
 FROM private.exam_prep_session_items si WHERE si.session_id=v_review AND si.question_id IS NOT NULL;
 INSERT INTO private.exam_prep_responses
   (session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,
    evaluator_version,elapsed_ms)
 SELECT v_review,si.item_order,v_uid,'synthetic-review-written-'||si.item_order::text,
        'written','{"text":"synthetic worked reasoning"}'::jsonb,'isolated-review',500
 FROM private.exam_prep_session_items si WHERE si.session_id=v_review AND si.written_task_id IS NOT NULL;
 SELECT count(*) INTO v_review_responses FROM private.exam_prep_responses WHERE session_id=v_review;
 IF v_review_responses<>4 THEN RAISE EXCEPTION 'Review response set incomplete'; END IF;
 -- Only now finalize; the existing correction reconciler must schedule a fresh
 -- delayed retest. It must NEVER close correction on this known-content review.
 UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
   finalize_idempotency_key='synthetic-review-final-001' WHERE id=v_review;
 IF (SELECT status FROM private.exam_prep_correction_cases WHERE id=v_case)<>'retest_due' OR
    NOT EXISTS(SELECT 1 FROM private.exam_prep_correction_actions
      WHERE correction_case_id=v_case AND session_id=v_review AND action_type='remediation_completed') OR
    NOT EXISTS(SELECT 1 FROM private.exam_prep_retest_events
      WHERE correction_case_id=v_case AND status='scheduled'
        AND due_not_before>private.exam_prep_effective_academic_now_v1(v_uid)) OR
    EXISTS(SELECT 1 FROM private.exam_prep_correction_actions
      WHERE correction_case_id=v_case AND action_type='case_closed') THEN
   RAISE EXCEPTION 'Existing remediation and fresh delayed retest contract violated';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_evidence_events
    WHERE session_id=v_review AND verification_status='app_verified') THEN
   RAISE EXCEPTION 'Known-content review was credited as independent mastery';
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=v_old.id)<>v_old_responses OR
    (SELECT status FROM private.exam_prep_sessions WHERE id=v_old.id)<>'finalized' THEN
   RAISE EXCEPTION 'Original learning history changed';
 END IF;
 v_status:=private.exam_prep_learning_review_verdict_v1(v_uid,v_program,'P1','P1-QUA-01',v_old.assessment_id);
 IF v_status->>'status'<>'fresh_retest_pending' THEN
   RAISE EXCEPTION 'Repeated remediation should wait for fresh retest: %',v_status;
 END IF;
 RAISE NOTICE 'GREEN isolated repeat same IDs noncredit, 3/3+written, correction waits fresh delayed retest, old history intact';
END;$matrix$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM private.exam_prep_sessions
    WHERE client_idempotency_key='synthetic-review-unique-id-001') THEN
   RAISE EXCEPTION 'Review fixture leaked into isolated DB';
 END IF;
 RAISE NOTICE 'GREEN learning review synthetic rollback clean';
END $$;
