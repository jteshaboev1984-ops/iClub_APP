-- Issue #450 P0-17: 30 genuine authenticated CORE write-entrypoint shadow gate.
-- ABSOLUTELY DISPOSABLE PostgreSQL 17 TEST ONLY, never production migration.
-- Requires already successful P0-16 six-real-RPC signed HTTP session epoch proof.
-- NOT a complete 37-root gate: seven separately governed safety/mentor/consent
-- entrypoints MUST NOT be mass-rewritten as Core learner writers.
\set ON_ERROR_STOP on
DO $p017$
DECLARE
 v_targets text[]:=ARRAY[
   'advance_exam_prep_written_step_safe_v1',
   'authorize_exam_prep_correction_safe_v1',
   'authorize_exam_prep_goal_once_safe_v1',
   'authorize_exam_prep_mixed_safe_v1',
   'authorize_exam_prep_plan_item_safe_v1',
   'authorize_exam_prep_retest_safe_v1',
   'authorize_exam_prep_revalidation_item_safe_v1',
   'ensure_exam_prep_balanced_weekly_plan_safe_v1',
   'ensure_exam_prep_stable_weekly_plan_safe_v1',
   'ensure_exam_prep_weekly_goals_safe_v1',
   'finalize_exam_prep_session_written_v1',
   'finalize_exam_prep_timed_safe_v1',
   'generate_exam_prep_weekly_plan_safe_v1',
   'generate_exam_prep_weekly_plan_safe_v2',
   'generate_exam_prep_weekly_plan_safe_v3',
   'record_exam_prep_integrity_event_safe_v1',
   'record_my_exam_prep_interruption_v1',
   'record_my_exam_prep_interruption_v2',
   'save_exam_prep_exam_profile_v1',
   'save_my_exam_prep_exam_appointment_v1',
   'set_my_exam_prep_exam_ops_confirmation_v1',
   'start_exam_prep_learning_review_safe_v1',
   'start_exam_prep_plan_session_once_safe_v1',
   'submit_exam_prep_timed_written_self_mark_safe_v1'
 ];
 v_target text;
 v_oid oid;
 v_definition text;
 v_anchor text;
 v_new text;
 v_args text;
 v_patched integer:=0;
 v_total integer;
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR to_regclass('private.p0_16_academic_epoch_gate') IS NULL
 OR (SELECT epoch FROM private.p0_16_academic_epoch_gate
     WHERE program_key='math_as_p1_p5')<>2
 OR (SELECT paused FROM private.p0_16_academic_epoch_gate
     WHERE program_key='math_as_p1_p5')<>false
 OR (SELECT count(*) FROM private.exam_prep_sessions WHERE p0_16_issued_epoch=1)<2
 THEN RAISE EXCEPTION 'P0-17 requires completed disposable P0-16 and two fake learners'; END IF;

 IF cardinality(v_targets)<>24 OR
 (SELECT count(DISTINCT name) FROM unnest(v_targets) AS x(name))<>24
 THEN RAISE EXCEPTION 'P0-17 source allowlist changed or duplicated'; END IF;
 FOR v_target IN SELECT unnest(v_targets) LOOP
  SELECT p.oid INTO STRICT v_oid FROM pg_proc p
   JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname=v_target
     AND has_function_privilege('authenticated',p.oid,'EXECUTE');
  v_definition:=pg_get_functiondef(v_oid);
  IF v_definition LIKE '%p0_16_require_current_epoch_v1%' THEN
    RAISE EXCEPTION 'P0-17 endpoint unexpectedly prepatched: %',v_target;
  END IF;
  v_anchor:=CASE
   WHEN v_definition LIKE '%v_uid:=private.exam_prep_require_core_access_v1();%'
     THEN 'v_uid:=private.exam_prep_require_core_access_v1();'
   WHEN v_definition LIKE '%v_uid := private.exam_prep_require_core_access_v1();%'
     THEN 'v_uid := private.exam_prep_require_core_access_v1();'
   ELSE NULL END;
  IF v_anchor IS NULL OR
   (length(v_definition)-length(replace(v_definition,v_anchor,'')))<>length(v_anchor)
   OR v_definition NOT ILIKE '%SECURITY DEFINER%'
  THEN RAISE EXCEPTION 'P0-17 refusing actual RPC core-auth source drift %',v_target; END IF;

  v_args:=CASE WHEN v_target IN (
   'advance_exam_prep_written_step_safe_v1',
   'finalize_exam_prep_session_written_v1',
   'finalize_exam_prep_timed_safe_v1',
   'record_exam_prep_integrity_event_safe_v1',
   'submit_exam_prep_timed_written_self_mark_safe_v1'
  ) THEN 'p_session_id' ELSE 'NULL::uuid' END;
  v_new:=replace(v_definition,v_anchor,
      v_anchor||E'\n  PERFORM private.p0_16_require_current_epoch_v1(v_uid,'||v_args||');');
  EXECUTE v_new;
  v_patched:=v_patched+1;
 END LOOP;
 IF v_patched<>24 THEN RAISE EXCEPTION 'P0-17 failed to patch all planned 24'; END IF;

 SELECT count(*) INTO v_total FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public'
 AND p.proname=ANY(ARRAY[
   'save_exam_prep_exam_profile_v2',
   'start_exam_prep_next_diagnostic_safe_v1',
   'authorize_exam_prep_timed_safe_v1',
   'start_exam_prep_session_safe_v1',
   'submit_exam_prep_response_safe_v1',
   'finalize_exam_prep_session_safe_v1'
 ]||v_targets)
 AND pg_get_functiondef(p.oid) LIKE '%private.p0_16_require_current_epoch_v1%';
 IF v_total<>30 THEN
   RAISE EXCEPTION 'P0-17 30 real Core write path coverage incomplete: %',v_total;
 END IF;

 IF EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
  AND p.proname=ANY(ARRAY[
   'claim_my_exam_prep_beta_core_seat_v1',
   'handover_exam_prep_mentor_assignment_safe_v1',
   'pause_exam_prep_mentor_assignment_safe_v1',
   'raise_exam_prep_safeguarding_safe_v1',
   'revoke_my_exam_prep_beta_consent_v1',
   'submit_exam_prep_mentor_review_safe_v1',
   'submit_exam_prep_second_check_safe_v1'
  ])
  AND pg_get_functiondef(p.oid) LIKE '%private.p0_16_require_current_epoch_v1%'
 ) THEN RAISE EXCEPTION 'P0-17 protected mentor/beta/consent RPC was silently rewritten'; END IF;
 RAISE NOTICE 'PASS P0-17 precisely 30/30 genuine Core writer paths shadow fenced; seven non-Core governance routes untouched';
END $p017$;
