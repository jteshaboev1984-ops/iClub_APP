-- CI ONLY: a brand-new, canonical registered synthetic identity whose
-- virtual academic clock is guarded by the existing P2-67/P2-68 contracts.
-- Must NEVER be run against production. After earlier 2-user postflight.
\set ON_ERROR_STOP on
DO $$
DECLARE
  v_run constant text := 'SV-P1P5-RETEST-HTTP-CI-01';
  v_user uuid;
  v_clock jsonb;
BEGIN
  IF current_database()<>'postgres' OR
    current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR
    (SELECT count(*) FROM public.users) <> 2 OR
    (SELECT count(*) FROM auth.users) <> 2 OR
    EXISTS(SELECT 1 FROM private.exam_prep_synthetic_validation_runs WHERE run_id=v_run)
  THEN
    RAISE EXCEPTION 'REFUSED: post-due retest fixture requires pristine 2-user disposable isolated CI';
  END IF;
  PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',repeat('a',40),'p1p5-http-postdue',26911,'core',
    'p1p5-http-postdue-exact-ci-candidate-proof'
  );
  v_user:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P1P5-HTTP-RETEST-01',
    'p1p5-http-postdue-canonical-identity-proof',
    'Disposable post-due retest with real learner HTTP/JWT RPCs','en'
  );
  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,
    jsonb_build_object('test','p1p5-http-postdue','isolation','disposable-only')
  );
  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(
    v_run,'p1p5-http-postdue-clock-initialized-proof');
  IF (v_clock->>'clock_status')<>'active'
     OR private.exam_prep_effective_academic_now_v1(v_user) IS NULL THEN
     RAISE EXCEPTION 'synthetic identity virtual clock not active';
  END IF;
  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_user,'active',true,false,false,null,now()-interval '1 minute');
  IF (SELECT count(*) FROM private.exam_prep_synthetic_identities s
       WHERE s.run_id=v_run AND s.user_id=v_user AND s.identity_status='active')<>1 THEN
    RAISE EXCEPTION 'canonical synthetic run identity not registered';
  END IF;
END $$;
