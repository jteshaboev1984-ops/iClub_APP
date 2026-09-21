-- Disposable GitHub Actions PG17 ONLY. No production, no real accounts.
-- Requires synthetic weekly_goal_ci.fixture after finalized P1-QUA-01 session.
\set ON_ERROR_STOP on
DO $guard$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
    OR to_regclass('weekly_goal_ci.fixture') IS NULL THEN
   RAISE EXCEPTION 'fresh_learning_test_requires_disposable_fixture';
 END IF;
END;$guard$;
BEGIN;
DO $test$
DECLARE
 v_user uuid;
 v_program bigint;
 v_fresh bigint;
 v_first bigint;
 v_alias bigint;
 v_cv bigint;
BEGIN
 SELECT f.user_id,p.program_version_id INTO STRICT v_user,v_program
 FROM weekly_goal_ci.fixture f JOIN private.exam_prep_exam_profiles p ON p.user_id=f.user_id;
 IF (SELECT count(*) FROM private.exam_prep_sessions s
     WHERE s.user_id=v_user AND s.component_code='P1'
       AND s.status='finalized')<>1 THEN
   RAISE EXCEPTION 'expected_one_finalized_synthetic_session';
 END IF;
 IF private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P1','P1-QUA-01') IS NOT NULL THEN
   RAISE EXCEPTION 'finalized_assessment_was_reoffered';
 END IF;
 SELECT a.id,a.content_version_id INTO STRICT v_first,v_cv
 FROM private.exam_prep_assessments a
 JOIN private.exam_prep_assessment_items i ON i.assessment_id=a.id
 WHERE a.assessment_type='learning' AND a.status='published'
   AND a.component_code='P1' AND i.primary_skill_code='P1-CIR-01'
 LIMIT 1;
 v_fresh:=private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P1','P1-CIR-01');
 IF v_fresh IS DISTINCT FROM v_first THEN RAISE EXCEPTION 'fresh_original_not_selected'; END IF;
 IF private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program+1000,'P1','P1-CIR-01') IS NOT NULL
    OR private.exam_prep_select_fresh_learning_assessment_v1(gen_random_uuid(),v_program,'P1','P1-CIR-01') IS NOT NULL
    OR private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P5','P1-CIR-01') IS NOT NULL THEN
   RAISE EXCEPTION 'selector_user_program_component_scope_violation';
 END IF;
 IF private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P5','P5-BIN-01') IS NULL THEN
   RAISE EXCEPTION 'fresh_p5_content_lost_by_p1_history';
 END IF;
 -- Attempting to relabel/repackage existing IDs is NOT new original material.
 INSERT INTO private.exam_prep_assessments
  (content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
   title_en,title_ru,title_uz,approved_at)
 VALUES(v_cv,'isolated_duplicate_alias','av1','P1','learning','published',
   'Synthetic duplicate','Синтетический дубликат','Sun’iy nusxa',clock_timestamp())
 RETURNING id INTO v_alias;
 INSERT INTO private.exam_prep_assessment_items
  (assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
 SELECT v_alias,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
 FROM private.exam_prep_assessment_items WHERE assessment_id=v_first;
 IF private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P1','P1-CIR-01') IS NOT NULL THEN
   RAISE EXCEPTION 'duplicate_question_or_written_ids_accepted_as_fresh';
 END IF;
 IF has_function_privilege('authenticated',
   'private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)','EXECUTE') OR
    has_function_privilege('anon',
   'private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)','EXECUTE') OR
    has_function_privilege('service_role',
   'private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)','EXECUTE') THEN
   RAISE EXCEPTION 'selector_became_publicly_executable';
 END IF;
 RAISE NOTICE 'ISOLATED SELECTOR GREEN: finalized blocked; first fresh P1 and separate P5; identity and duplicated-ID guards';
END;$test$;
ROLLBACK;
DO $verify$
DECLARE v_user uuid;v_program bigint;v_first bigint;
BEGIN
 SELECT f.user_id,p.program_version_id INTO STRICT v_user,v_program
 FROM weekly_goal_ci.fixture f JOIN private.exam_prep_exam_profiles p ON p.user_id=f.user_id;
 IF EXISTS (SELECT 1 FROM private.exam_prep_assessments WHERE assessment_key='isolated_duplicate_alias')
    OR private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P1','P1-QUA-01') IS NOT NULL
    OR private.exam_prep_select_fresh_learning_assessment_v1(v_user,v_program,'P1','P1-CIR-01') IS NULL THEN
   RAISE EXCEPTION 'selector_rollback_or_original_state_changed';
 END IF;
 RAISE NOTICE 'ISOLATED SELECTOR ROLLBACK GREEN: no duplicate content or learner history changed';
END;$verify$;
