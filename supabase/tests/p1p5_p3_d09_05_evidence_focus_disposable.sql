-- D09-05: source-backed current objective next steps, SELECT-only test on
-- synthetic 2-user PG17 after REAL signed HTTP diagnostic and learning.
-- Do not turn unknown skill into weak learner or invent tuition hours.
\set ON_ERROR_STOP on
DO $test$
DECLARE
 v_user uuid:='11111111-1111-4111-8111-111111111191'::uuid;
 v_version bigint;
 v_remain jsonb;
 v_focus jsonb;
 v_repeated jsonb;
 v_report_function text;
 v_rows integer;
 v_report_receipts_before integer;
 v_report_receipts_after integer;
 v_sessions_before integer;
 v_sessions_after integer;
 v_corrections_before integer;
 v_corrections_after integer;
BEGIN
 IF current_database()<>'postgres'
   OR current_setting('server_version_num')::integer<170000
   OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
   OR (SELECT count(*) FROM auth.users)<>2
   OR (SELECT count(*) FROM public.users)<>2
   OR to_regprocedure('private.exam_prep_current_evidence_next_focus_v1(uuid,bigint)') IS NULL
 THEN RAISE EXCEPTION 'D09-05 REFUSED: only real-diagnostic disposable PG17 fixture'; END IF;
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM set_config('request.jwt.claims',
   jsonb_build_object('sub',v_user::text,'role','authenticated')::text,true);
 IF private.exam_prep_require_core_access_v1() IS DISTINCT FROM v_user
 THEN RAISE EXCEPTION 'D09-05 owner guard absent'; END IF;
 SELECT program_version_id INTO STRICT v_version
 FROM private.exam_prep_exam_profiles WHERE user_id=v_user;
 SELECT count(*) INTO v_report_receipts_before
 FROM private.exam_prep_periodic_study_report_receipts_v1
 WHERE user_id=v_user AND program_version_id=v_version;
 SELECT count(*) INTO v_sessions_before FROM private.exam_prep_sessions
 WHERE user_id=v_user;
 SELECT count(*) INTO v_corrections_before FROM private.exam_prep_correction_cases
 WHERE user_id=v_user;
 v_remain:=public.get_exam_prep_remaining_work_by_skill_safe_v1();
 v_focus:=private.exam_prep_current_evidence_next_focus_v1(v_user,v_version);
 v_repeated:=private.exam_prep_current_evidence_next_focus_v1(v_user,v_version);
 IF v_remain->>'contract_version'<>'exam_prep_result_led_remaining_work_v1'
  OR (v_remain->'P1'->>'skills_total')::integer<>45
  OR (v_remain->'P5'->>'skills_total')::integer<>36
  OR v_focus->>'contract_version'<>'exam_prep_weekly_evidence_focus_v1'
  OR jsonb_typeof(v_focus->'items')<>'array'
  OR jsonb_array_length(v_focus->'items')>3
  OR v_focus IS DISTINCT FROM v_repeated
  OR v_focus->>'read_at'<>'report_claim_time_not_historical_week_end'
  OR v_focus->>'recommended_weekly_hours' IS NOT NULL
  OR v_focus->>'recommended_daily_minutes' IS NOT NULL
  OR v_focus->>'student_selected_math_hours_unchanged'<>'true'
  OR v_focus->>'not_additional_weekly_plan'<>'true'
  OR v_focus->>'unknown_skill_is_not_failed'<>'true'
  OR v_focus->>'recommendation_accept_enabled'<>'false'
  OR v_focus->>'academic_grades_changed'<>'false'
  OR v_focus->>'learning_access_capped'<>'false'
 THEN RAISE EXCEPTION 'D09-05 objective-only/no-hours evidence payload invalid: %',v_focus; END IF;
 SELECT count(*) INTO v_rows FROM (
   SELECT DISTINCT (f.value->>'component_code')||':'||(f.value->>'skill_code') AS k
   FROM jsonb_array_elements(v_focus->'items') f(value)
 ) s;
 IF v_rows<>jsonb_array_length(v_focus->'items')
 THEN RAISE EXCEPTION 'D09-05 repeated a skill as multiple new courses'; END IF;
 IF EXISTS (
   SELECT 1
   FROM jsonb_array_elements(v_focus->'items') f(value)
   WHERE f.value->>'component_code' NOT IN ('P1','P5')
      OR f.value->>'next_action' NOT IN ('correction','delayed_retest',
         'mixed_transfer','targeted_practice','targeted_check','written_work_unscored')
      OR NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(
          v_remain->(f.value->>'component_code')->'items') s(value)
        WHERE s.value->>'skill_code'=f.value->>'skill_code'
          AND s.value->>'evidence_status'=f.value->>'evidence_status'
          AND (s.value->'pending_actions') ? (f.value->>'next_action')
      )
 ) THEN RAISE EXCEPTION 'D09-05 next step is not supported by source-stored skill evidence'; END IF;
 IF EXISTS (
   SELECT 1
   FROM jsonb_array_elements(v_focus->'items') f(value)
   WHERE f.value->>'next_action'='targeted_check'
     AND f.value->>'evidence_status'<>'unobserved'
 ) THEN RAISE EXCEPTION 'D09-05 unknown skill was classified as weak evidence'; END IF;
 IF has_function_privilege('anon',
   'private.exam_prep_current_evidence_next_focus_v1(uuid,bigint)'::regprocedure,'EXECUTE')
   OR has_function_privilege('authenticated',
   'private.exam_prep_current_evidence_next_focus_v1(uuid,bigint)'::regprocedure,'EXECUTE')
 THEN RAISE EXCEPTION 'D09-05 private helper exposed to learners'; END IF;
 v_report_function:=pg_get_functiondef(
   'public.claim_exam_prep_periodic_study_report_safe_v1()'::regprocedure);
 IF position('private.exam_prep_current_evidence_next_focus_v1' in v_report_function)=0
   OR position('evidence_next_steps' in v_report_function)=0
 THEN RAISE EXCEPTION 'D09-05 weekly receipts do not capture verified focus'; END IF;
 SELECT count(*) INTO v_report_receipts_after
 FROM private.exam_prep_periodic_study_report_receipts_v1
 WHERE user_id=v_user AND program_version_id=v_version;
 SELECT count(*) INTO v_sessions_after FROM private.exam_prep_sessions
 WHERE user_id=v_user;
 SELECT count(*) INTO v_corrections_after FROM private.exam_prep_correction_cases
 WHERE user_id=v_user;
 IF v_report_receipts_before<>v_report_receipts_after
    OR v_sessions_before<>v_sessions_after
    OR v_corrections_before<>v_corrections_after
 THEN RAISE EXCEPTION 'D09-05 read-only next-action projection mutated receipts or progress'; END IF;
 RAISE NOTICE 'D09-05 PASS: 81 original skills, max three source-backed next steps, unknown is not weak, no invented hours, unchanged learner records';
END;
$test$;
