-- D09-05: prove REAL periodic RPC emits one academic 7-day digest with
-- source-backed, claim-time focused next steps and refuses repeat delivery.
-- DISPOSABLE PG17, exactly two fake learners, one transaction ROLLBACK ONLY.
-- Academic virtual time below is a temporary *local* replacement of the
-- synthetic clock wrapper, NEVER part of a migration or production code.
\set ON_ERROR_STOP on
BEGIN;
DO $preflight$
DECLARE
 v_source text;
BEGIN
 IF current_database()<>'postgres'
   OR current_setting('server_version_num')::integer<170000
   OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
   OR (SELECT count(*) FROM auth.users)<>2
   OR (SELECT count(*) FROM public.users)<>2
   OR to_regprocedure('public.claim_exam_prep_periodic_study_report_safe_v1()') IS NULL
   OR to_regprocedure('private.exam_prep_current_evidence_next_focus_v1(uuid,bigint)') IS NULL
 THEN RAISE EXCEPTION 'D09-05 REPORT REFUSED: only seeded disposable PG17'; END IF;
 v_source:=pg_get_functiondef(
   'private.exam_prep_effective_academic_now_v1(uuid)'::regprocedure);
 IF position('exam_prep_synthetic_identities' in v_source)=0
 THEN RAISE EXCEPTION 'D09-05 REPORT REFUSED: original synthetic academic clock changed'; END IF;
END;
$preflight$;

-- Proof-only offset. Original function body and all data are restored by
-- ROLLBACK at end (or on a failed connection/psql error).
CREATE OR REPLACE FUNCTION private.exam_prep_effective_academic_now_v1(
 p_user_id uuid
) RETURNS timestamptz LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO '' AS $isolated_clock$
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR p_user_id IS NULL
 THEN RAISE EXCEPTION 'D09-05 REPORT: synthetic-only clock refused'; END IF;
 IF p_user_id='11111111-1111-4111-8111-111111111191'::uuid
 THEN RETURN now()+interval '8 days'; END IF;
 RETURN now();
END;
$isolated_clock$;

DO $proof$
DECLARE
 v_user uuid:='11111111-1111-4111-8111-111111111191'::uuid;
 v_other uuid:='22222222-2222-4222-8222-222222222292'::uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_first jsonb;
 v_second jsonb;
 v_report jsonb;
 v_focus jsonb;
 v_expected jsonb;
 v_before integer;
 v_after integer;
 v_week_end timestamptz;
 v_first_t0 timestamptz;
 v_session_count integer;
 v_sessions_after integer;
 v_corrections_before integer;
 v_corrections_after integer;
 v_plans_before integer;
 v_plans_after integer;
BEGIN
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM set_config('request.jwt.claims',
  jsonb_build_object('sub',v_user::text,'role','authenticated')::text,true);
 IF private.exam_prep_require_core_access_v1() IS DISTINCT FROM v_user
 THEN RAISE EXCEPTION 'D09-05 REPORT owner authentication failed'; END IF;
 SELECT * INTO STRICT v_profile FROM private.exam_prep_exam_profiles
 WHERE user_id=v_user;
 SELECT min(t.diagnostic_completed_at) INTO v_first_t0
 FROM private.exam_prep_diagnostic_t0_snapshots_v1 t
 WHERE t.user_id=v_user AND t.program_version_id=v_profile.program_version_id
 AND t.component_code IN ('P1','P5');
 IF v_first_t0 IS NULL OR v_first_t0>now()+interval '1 day'
 THEN RAISE EXCEPTION 'D09-05 REPORT real first diagnostic T0 not found'; END IF;
 v_week_end:=v_first_t0+interval '7 days';
 SELECT count(*) INTO v_before
 FROM private.exam_prep_periodic_study_report_receipts_v1
 WHERE user_id=v_user AND period_kind='week';
 SELECT count(*) INTO v_session_count FROM private.exam_prep_sessions
 WHERE user_id=v_user;
 SELECT count(*) INTO v_corrections_before FROM private.exam_prep_correction_cases
 WHERE user_id=v_user;
 SELECT count(*) INTO v_plans_before FROM private.exam_prep_weekly_plans
 WHERE user_id=v_user;
 v_expected:=private.exam_prep_current_evidence_next_focus_v1(
   v_user,v_profile.program_version_id);
 v_first:=public.claim_exam_prep_periodic_study_report_safe_v1();
 IF v_first->>'contract_version'<>'periodic_study_report_v1'
    OR v_first->>'daily_reminders'<>'false'
    OR jsonb_array_length(v_first->'reports')<>1
 THEN RAISE EXCEPTION 'D09-05 REPORT no exactly one seven-day summary: %',v_first; END IF;
 v_report:=(v_first->'reports')->0;
 v_focus:=v_report->'evidence_next_steps';
 IF v_report->>'period_kind'<>'week'
   OR (v_report->>'period_ended_at')::timestamptz IS DISTINCT FROM v_week_end
   OR v_focus IS DISTINCT FROM v_expected
   OR jsonb_array_length(v_focus->'items')>3
   OR v_focus->>'read_at'<>'report_claim_time_not_historical_week_end'
   OR v_focus->>'recommended_weekly_hours' IS NOT NULL
   OR v_focus->>'recommendation_accept_enabled'<>'false'
   OR v_report->>'learning_minutes' IS NOT NULL
   OR v_report->>'no_auto_schedule_change'<>'true'
 THEN RAISE EXCEPTION 'D09-05 REPORT focus/week/session honesty mismatch: %',v_report; END IF;
 v_second:=public.claim_exam_prep_periodic_study_report_safe_v1();
 IF jsonb_array_length(v_second->'reports')<>0
 THEN RAISE EXCEPTION 'D09-05 REPORT duplicate notice across dashboard opens: %',v_second; END IF;
 SELECT count(*) INTO v_after
 FROM private.exam_prep_periodic_study_report_receipts_v1
 WHERE user_id=v_user AND period_kind='week';
 IF v_after<>v_before+1
 THEN RAISE EXCEPTION 'D09-05 REPORT no unique durable receipt'; END IF;
 SELECT count(*) INTO v_sessions_after FROM private.exam_prep_sessions
 WHERE user_id=v_user;
 SELECT count(*) INTO v_corrections_after FROM private.exam_prep_correction_cases
 WHERE user_id=v_user;
 SELECT count(*) INTO v_plans_after FROM private.exam_prep_weekly_plans
 WHERE user_id=v_user;
 IF v_session_count<>v_sessions_after OR v_corrections_before<>v_corrections_after
   OR v_plans_before<>v_plans_after
   OR EXISTS(SELECT 1 FROM private.exam_prep_periodic_study_report_receipts_v1
     WHERE user_id=v_other)
 THEN RAISE EXCEPTION 'D09-05 REPORT mutated historical academic state or other learner'; END IF;
 RAISE NOTICE 'D09-05 ROLLOVER PASS: real completed week, max 3 existing evidence focus, one durable receipt, second empty, unchanged plans/attempts';
END;
$proof$;
ROLLBACK;

DO $postflight$
DECLARE
 v_original text;
BEGIN
 IF current_database()<>'postgres'
  OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'D09-05 REPORT unsafe postflight'; END IF;
 v_original:=pg_get_functiondef(
   'private.exam_prep_effective_academic_now_v1(uuid)'::regprocedure);
 IF position('exam_prep_synthetic_identities' in v_original)=0
   OR EXISTS(SELECT 1
     FROM private.exam_prep_periodic_study_report_receipts_v1
     WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid)
 THEN RAISE EXCEPTION 'D09-05 REPORT rollback failed to restore original clock/receipts'; END IF;
 RAISE NOTICE 'D09-05 ROLLBACK PASS: original academic clock and learner receipt state restored';
END;
$postflight$;
