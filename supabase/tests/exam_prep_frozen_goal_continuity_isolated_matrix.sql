-- DISPOSABLE PostgreSQL 17 ONLY. Synthetic identities and writes ROLLBACK.
-- Tests the public eligibility + atomic noncredit review, not just helper SQL.
\set ON_ERROR_STOP on
DO $$BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
 OR to_regprocedure('private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)') IS NULL
 OR to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') IS NULL
 THEN RAISE EXCEPTION 'frozen_goal_fixture_requires_disposable_installed_contract'; END IF;
END$$;
BEGIN;
DO $matrix$
DECLARE
 uid uuid:=gen_random_uuid(); prog bigint; ass record;
 old_plan uuid; current_plan uuid; prior_plan uuid; history_plan uuid;
 cir_case uuid; coo_case uuid; cir_goal uuid; coo_goal uuid;
 original_auth uuid; original_session uuid; review_session uuid;
 version_no integer; v_result jsonb; v_count integer;
 old_saved_fingerprint text; old_goal_fingerprint text;
BEGIN
 SELECT id INTO STRICT prog FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0';
 SELECT a.id assessment_id,a.content_version_id,a.assessment_version
 INTO STRICT ass FROM private.exam_prep_assessments a
 JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
 WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
 AND cv.program_version_id=prog AND cv.status='published'
 AND (SELECT count(*) FROM private.exam_prep_assessment_items ai
      WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL AND ai.primary_skill_code='P1-CIR-01')=3
 AND (SELECT count(*) FROM private.exam_prep_assessment_items ai
      WHERE ai.assessment_id=a.id AND ai.written_task_id IS NOT NULL AND ai.primary_skill_code='P1-CIR-01')=1
 ORDER BY a.id LIMIT 1;
 INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
 VALUES(uid,'authenticated','authenticated','frozen-goal-continuity@example.invalid',now(),now(),false,false);
 INSERT INTO public.users(id,first_name,created_at,must_change_password)
 VALUES(uid,'FrozenGoalContinuityFixture',now(),false);
 INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
 VALUES(uid,'active',true);
 UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',core_enabled=true,
 ai_enabled=false,mentor_enabled=false,kill_switch=false WHERE program_key='math_as_p1_p5';
 INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
 VALUES(uid,true,uid,now());
 INSERT INTO private.exam_prep_exam_profiles
 (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,
 mathematics_hours_budget,active_week_no)
 VALUES(uid,prog,'May/June 2027','A',12,6,1);
 INSERT INTO private.exam_prep_correction_cases
 (user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(uid,'P1','P1-CIR-01','open','objective_state_v1','{"synthetic":true}'::jsonb)
 RETURNING id INTO cir_case;
 INSERT INTO private.exam_prep_correction_cases
 (user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(uid,'P1','P1-COO-02','open','objective_state_v1','{"synthetic":true}'::jsonb)
 RETURNING id INTO coo_case;
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(uid,prog,'P1',1,1,'active','Synthetic preserved initial commitments')
 RETURNING id INTO old_plan;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
 VALUES(old_plan,1,'correction','P1-CIR-01',cir_case,'COMPLETE_CORRECTION_ANALOGUES'),
 (old_plan,2,'correction','P1-COO-02',coo_case,'COMPLETE_CORRECTION_ANALOGUES');
 INSERT INTO private.exam_prep_weekly_goal_snapshots
 (user_id,program_version_id,component_code,active_week_no,priority_order,source_plan_id,
 item_type,skill_code,correction_case_id,action_code)
 VALUES(uid,prog,'P1',1,1,old_plan,'correction','P1-CIR-01',cir_case,'COMPLETE_CORRECTION_ANALOGUES')
 RETURNING id INTO cir_goal;
 INSERT INTO private.exam_prep_weekly_goal_snapshots
 (user_id,program_version_id,component_code,active_week_no,priority_order,source_plan_id,
 item_type,skill_code,correction_case_id,action_code)
 VALUES(uid,prog,'P1',1,2,old_plan,'correction','P1-COO-02',coo_case,'COMPLETE_CORRECTION_ANALOGUES')
 RETURNING id INTO coo_goal;
 -- A real-shaped old finalized learning session has three original objective
 -- items and one written item. Previously exposed questions are NOT fresh.
 INSERT INTO private.exam_prep_session_authorizations
 (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
 correction_case_id,academic_credit,plan_id,plan_priority_order)
 VALUES(uid,ass.assessment_id,'P1','learning','issued',now()+interval '1 hour',
 'Synthetic initial correction attempt',cir_case,true,old_plan,1)
 RETURNING id INTO original_auth;
 INSERT INTO private.exam_prep_sessions
 (authorization_id,user_id,program_version_id,content_version_id,assessment_id,
 assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
 VALUES(original_auth,uid,prog,ass.content_version_id,ass.assessment_id,
 ass.assessment_version,'P1','learning','active','frozen-original-session-0001',4)
 RETURNING id INTO original_session;
 INSERT INTO private.exam_prep_session_items
 (session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,
 reserve_role,is_holdout,content_meta_id,question_snapshot_md5,item_version)
 SELECT original_session,ai.item_order,
 CASE WHEN ai.question_id IS NOT NULL THEN 'question' ELSE 'written' END,
 ai.question_id,ai.written_task_id,ai.primary_skill_code,ai.reserve_role,ai.is_holdout,
 m.id,m.question_snapshot_md5,
 CASE WHEN ai.question_id IS NOT NULL THEN 'qmd5:'||m.question_snapshot_md5
      ELSE 'written:'||wt.task_version END
 FROM private.exam_prep_assessment_items ai
 LEFT JOIN private.exam_prep_question_content_meta m
 ON m.question_id=ai.question_id AND m.content_version_id=ass.content_version_id
 LEFT JOIN private.exam_prep_written_tasks wt
 ON wt.id=ai.written_task_id AND wt.content_version_id=ass.content_version_id
 WHERE ai.assessment_id=ass.assessment_id;
 IF (SELECT count(*) FROM private.exam_prep_session_items WHERE session_id=original_session)<>4
 THEN RAISE EXCEPTION 'synthetic original four-item session incomplete'; END IF;
 UPDATE private.exam_prep_session_authorizations SET status='consumed',consumed_at=now(),
 consumed_session_id=original_session WHERE id=original_auth;
 INSERT INTO private.exam_prep_responses
 (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
 is_correct,evaluator_version,elapsed_ms)
 SELECT original_session,si.item_order,uid,'frozen-original-answer-'||si.item_order::text,
 'machine','synthetic',si.item_order<>3,'synthetic-test',500
 FROM private.exam_prep_session_items si WHERE si.session_id=original_session
 AND si.question_id IS NOT NULL;
 INSERT INTO private.exam_prep_responses
 (session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,
 evaluator_version,elapsed_ms)
 SELECT original_session,si.item_order,uid,'frozen-original-written-'||si.item_order::text,
 'written','{"text":"synthetic original work"}'::jsonb,'synthetic-test',500
 FROM private.exam_prep_session_items si WHERE si.session_id=original_session
 AND si.written_task_id IS NOT NULL;
 UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
 finalize_idempotency_key='frozen-original-finalized-0001' WHERE id=original_session;
 IF (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=original_session)<>4
 THEN RAISE EXCEPTION 'synthetic original answer history not saved'; END IF;
 SELECT md5(string_agg(to_jsonb(r)::text,'|' ORDER BY r.id::text)) INTO old_saved_fingerprint
 FROM private.exam_prep_responses r WHERE r.session_id=original_session;
 SELECT md5(string_agg(to_jsonb(g)::text,'|' ORDER BY g.priority_order)) INTO old_goal_fingerprint
 FROM private.exam_prep_weekly_goal_snapshots g WHERE g.user_id=uid;
 -- Eleven successive plan versions; initial goal order remains 1,2. Only
 -- version 11 swaps action priorities to 2,1, exactly as seen in live data.
 prior_plan:=old_plan;
 FOR version_no IN 2..11 LOOP
  UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=prior_plan;
  INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(uid,prog,'P1',1,version_no,'active','Synthetic historical replan')
  RETURNING id INTO current_plan;
  INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
  VALUES(current_plan,CASE WHEN version_no=11 THEN 2 ELSE 1 END,
  'correction','P1-CIR-01',cir_case,'COMPLETE_CORRECTION_ANALOGUES'),
  (current_plan,CASE WHEN version_no=11 THEN 1 ELSE 2 END,
  'correction','P1-COO-02',coo_case,'COMPLETE_CORRECTION_ANALOGUES');
  prior_plan:=current_plan;
 END LOOP;
 IF private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P1',1::smallint,cir_goal,current_plan) IS DISTINCT FROM 2
 OR private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P1',1::smallint,coo_goal,current_plan) IS DISTINCT FROM 1
 OR private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P1',1::smallint,cir_goal,old_plan) IS NOT NULL
 OR private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P5',1::smallint,cir_goal,current_plan) IS NOT NULL
 THEN RAISE EXCEPTION 'frozen/reordered/current/other-component proof incorrect'; END IF;
 PERFORM set_config('request.jwt.claim.sub',uid::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 v_result:=public.get_exam_prep_goal_action_state_safe_v1('P1',cir_goal,current_plan);
 IF v_result->>'status'<>'review_ready' OR (v_result->>'priority_order')::int<>2
 OR v_result->>'goal_id'<>cir_goal::text OR v_result->>'plan_id'<>current_plan::text
 THEN RAISE EXCEPTION 'same-pack old goal failed read model continuity: %',v_result; END IF;
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',cir_goal,current_plan,
  'frozen-lineage-review-unique-0001');
 IF v_result->>'status'<>'started' OR v_result->>'repeat_learning'<>'true'
 OR v_result->>'academic_credit'<>'false' OR v_result->>'not_a_new_independent_check'<>'true'
 OR v_result->>'session_id' IS NULL THEN
  RAISE EXCEPTION 'proved historical goal cannot start noncredit review: %',v_result; END IF;
 review_session:=(v_result->>'session_id')::uuid;
 IF EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations a
 JOIN private.exam_prep_sessions s ON s.authorization_id=a.id WHERE s.id=review_session
 AND (a.academic_credit IS TRUE OR a.plan_id IS NOT NULL OR a.credit_context<>'learning_review'))
 OR (SELECT array_agg(question_id ORDER BY item_order) FROM private.exam_prep_session_items
 WHERE session_id=review_session AND question_id IS NOT NULL) IS DISTINCT FROM
 (SELECT array_agg(question_id ORDER BY item_order) FROM private.exam_prep_session_items
 WHERE session_id=original_session AND question_id IS NOT NULL)
 THEN RAISE EXCEPTION 'review reused wrong questions or granted independent credit'; END IF;
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',cir_goal,current_plan,
  'frozen-lineage-review-unique-0002');
 IF v_result->>'status'<>'resume_existing_session_first' OR
 (v_result->>'session_id')::uuid<>review_session THEN
  RAISE EXCEPTION 'second start did not preserve active review: %',v_result; END IF;
 -- Alter ONLY synthetic intermediate provenance. The current plan still
 -- matches the frozen goal, but a broken chain MUST NOT be accepted.
 SELECT p.id INTO STRICT history_plan FROM private.exam_prep_weekly_plans p
 WHERE p.user_id=uid AND p.component_code='P1' AND p.plan_version=6;
 UPDATE private.exam_prep_weekly_plan_items SET action_code='BUILD_FIRST_COVERAGE'
 WHERE plan_id=history_plan AND skill_code='P1-CIR-01';
 IF private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P1',1::smallint,cir_goal,current_plan)
 IS NOT NULL THEN RAISE EXCEPTION 'changed intermediate action was accepted'; END IF;
 v_result:=public.get_exam_prep_goal_action_state_safe_v1('P1',cir_goal,current_plan);
 IF v_result->>'status'<>'stale' OR v_result->>'reason'<>'goal_lineage_unverified'
 THEN RAISE EXCEPTION 'unproven lineage shown as runnable: %',v_result; END IF;
 SELECT count(*) INTO v_count FROM private.exam_prep_session_authorizations WHERE user_id=uid;
 v_result:=public.start_exam_prep_learning_review_safe_v1('P1',cir_goal,current_plan,
  'frozen-lineage-review-denied-0003');
 IF v_result->>'status'<>'stale' OR v_result?'session_id' OR
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=uid)<>v_count
 THEN RAISE EXCEPTION 'broken lineage started/replayed a review: %',v_result; END IF;
 UPDATE private.exam_prep_weekly_plan_items SET action_code='COMPLETE_CORRECTION_ANALOGUES'
 WHERE plan_id=history_plan AND skill_code='P1-CIR-01';
 -- Even an intact history cannot authorize an ambiguous current identity.
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
 VALUES(current_plan,3,'correction','P1-CIR-01',cir_case,'COMPLETE_CORRECTION_ANALOGUES');
 IF private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P1',1::smallint,cir_goal,current_plan)
 IS NOT NULL THEN RAISE EXCEPTION 'ambiguous current duplicate accepted'; END IF;
 DELETE FROM private.exam_prep_weekly_plan_items
 WHERE plan_id=current_plan AND priority_order=3;
 -- A missing intermediate version is equally unprovable.
 UPDATE private.exam_prep_weekly_plans SET plan_version=60 WHERE id=history_plan;
 IF private.exam_prep_frozen_goal_current_priority_v1(uid,prog,'P1',1::smallint,cir_goal,current_plan)
 IS NOT NULL THEN RAISE EXCEPTION 'missing plan version accepted'; END IF;
 IF (SELECT md5(string_agg(to_jsonb(r)::text,'|' ORDER BY r.id::text))
 FROM private.exam_prep_responses r WHERE r.session_id=original_session)
 IS DISTINCT FROM old_saved_fingerprint OR
 (SELECT md5(string_agg(to_jsonb(g)::text,'|' ORDER BY g.priority_order))
 FROM private.exam_prep_weekly_goal_snapshots g WHERE g.user_id=uid)
 IS DISTINCT FROM old_goal_fingerprint
 THEN RAISE EXCEPTION 'original frozen goals/responses modified'; END IF;
 RAISE NOTICE 'GREEN: 11-version reorder, exact original questions, noncredit, saved written, duplicate start, broken lineage, ambiguity, component and frozen history';
END;$matrix$;
ROLLBACK;
DO $$BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='FrozenGoalContinuityFixture')
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE client_idempotency_key='frozen-lineage-review-unique-0001')
 THEN RAISE EXCEPTION 'synthetic frozen-goal fixture leaked'; END IF;
 RAISE NOTICE 'GREEN: isolated frozen-goal fixture fully rolled back';
END$$;
