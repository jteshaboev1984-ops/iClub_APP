-- Isolated PostgreSQL runtime matrix. No learner records, secrets or prod access.
-- Called after the complete Exam Prep migration replay in P2-36.
\set ON_ERROR_STOP on
DO $qa$
DECLARE
  v_out jsonb;
  v_before bigint;
  v_after bigint;
BEGIN
  IF to_regprocedure('public.iclub_econ_written_start_v2()') IS NULL
  THEN RAISE EXCEPTION 'New consent-free Economics start RPC missing'; END IF;
  IF has_function_privilege('anon','public.iclub_econ_written_start_v2()','EXECUTE')
  THEN RAISE EXCEPTION 'Anonymous users must not execute written start'; END IF;
  IF NOT has_function_privilege('authenticated','public.iclub_econ_written_start_v2()','EXECUTE')
  THEN RAISE EXCEPTION 'Authenticated users cannot access gated written start'; END IF;
  IF EXISTS(
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='iclub_econ_written_start_v2'
     AND pg_get_function_identity_arguments(p.oid)<>''
  ) THEN RAISE EXCEPTION 'No learner consent acknowledgement parameter allowed'; END IF;
  IF auth.uid() IS NOT NULL
  THEN RAISE EXCEPTION 'CI PostgreSQL session unexpectedly has a user identity'; END IF;
  SELECT count(*) INTO v_before FROM private.exam_prep_beta_consents;
  SELECT public.iclub_econ_written_start_v2() INTO v_out;
  IF v_out->>'ok'<>'false' OR v_out->>'code'<>'not_authorized'
  THEN RAISE EXCEPTION 'No-session written start must fail closed: %',v_out; END IF;
  SELECT count(*) INTO v_after FROM private.exam_prep_beta_consents;
  IF v_after<>v_before THEN RAISE EXCEPTION 'Denied start mutated historical consent rows'; END IF;
  SELECT public.iclub_econ_written_beta_status_v1() INTO v_out;
  IF v_out->>'ok'<>'false' OR v_out->>'code'<>'not_authorized'
  THEN RAISE EXCEPTION 'No-session written status must fail closed: %',v_out; END IF;
  IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='private' AND p.proname='iclub_ai_math_beta_pro_quota_eligible_v1'
      AND pg_get_functiondef(p.oid) NOT LIKE '%global_ai.consent_at IS NOT NULL%')
  THEN RAISE EXCEPTION 'Independent global AI provider gate was weakened'; END IF;
END $qa$;
SELECT 'EXAM PREP NO EXTRA CONSENT RUNTIME: PASS' AS result;
