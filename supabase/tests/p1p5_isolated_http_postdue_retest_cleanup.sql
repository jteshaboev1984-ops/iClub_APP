-- Disposable isolated CI cleanup of only the canonical synthetic run,
-- using the existing P2-66 scoped governance protocol (NEVER production).
\set ON_ERROR_STOP on
DO $$
DECLARE
  v_run constant text:='SV-P1P5-RETEST-HTTP-CI-01';
  v_uid uuid;
  v_inventory jsonb;
  v_completed jsonb;
  v_cleaned jsonb;
BEGIN
  IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM public.users)<>3
    OR (SELECT count(*) FROM auth.users)<>3 THEN
    RAISE EXCEPTION 'REFUSED: synthetic cleanup must target exactly the disposable 3-user CI';
  END IF;
  SELECT user_id INTO v_uid FROM private.exam_prep_synthetic_identities
   WHERE run_id=v_run AND identity_kind='learner' AND identity_status='active';
  IF v_uid IS NULL THEN RAISE EXCEPTION 'canonical synthetic learner missing before cleanup'; END IF;
  v_inventory:=private.exam_prep_synthetic_run_inventory_v1(v_run);
  IF (v_inventory->>'clean_boundary')::boolean IS NOT TRUE
    OR coalesce((v_inventory#>>'{legacy_refs,total_refs}')::int,-1)<>0 THEN
    RAISE EXCEPTION 'virtual clock run contaminated legacy or beta: %',v_inventory;
  END IF;
  v_completed:=private.complete_exam_prep_synthetic_run_v1(
    v_run,1,jsonb_build_object('test','p1p5-real-http-postdue',
      'result','real-jwt-retired-correction-verified','protected_content','not_exported')
  );
  IF v_completed->>'run_status'<>'completed' THEN
    RAISE EXCEPTION 'canonical test completion not accepted';
  END IF;
  v_cleaned:=private.cleanup_exam_prep_synthetic_run_v1(
    v_run,1,'p1p5-postdue-isolated-cleanup-proof',
    'I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF v_cleaned->>'cleanup_status'<>'clean' OR
     (v_cleaned->>'deleted_identity_count')::int<>1 THEN
    RAISE EXCEPTION 'canonical synthetic cleanup failed: %',v_cleaned;
  END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities WHERE run_id=v_run)
    OR EXISTS(SELECT 1 FROM public.users WHERE id=v_uid)
    OR EXISTS(SELECT 1 FROM auth.users WHERE id=v_uid)
    OR (SELECT count(*) FROM public.users)<>2
    OR (SELECT count(*) FROM auth.users)<>2
    OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
    OR EXISTS(SELECT 1 FROM public.practice_attempts)
    OR EXISTS(SELECT 1 FROM public.tour_attempts)
    OR EXISTS(SELECT 1 FROM public.certificates) THEN
    RAISE EXCEPTION 'synthetic cleanup left identity or legacy/real-beta contamination';
  END IF;
END $$;
