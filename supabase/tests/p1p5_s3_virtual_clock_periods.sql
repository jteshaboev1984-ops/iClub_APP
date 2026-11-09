-- S3 CI-only synthetic clock. NEVER run on existing iClub Supabase.
-- No academic session/answer mutation: advance only a disposable learner's test clock.
\set ON_ERROR_STOP on
BEGIN;
DO $guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.users WHERE id='11111111-1111-4111-8111-111111111191'::uuid)
    OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities
              WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid)
    OR NOT EXISTS(
      SELECT 1 FROM private.exam_prep_component_placements p
      WHERE p.user_id='11111111-1111-4111-8111-111111111191'::uuid
        AND p.stage0_complete=true AND p.component_code IN ('P1','P5')
    )
 THEN RAISE EXCEPTION 'S3 requires fresh disposable owner with completed diagnostic'; END IF;
END;
$guard$;
INSERT INTO private.exam_prep_synthetic_validation_runs(
  run_id,scenario_set_version,git_sha,schema_generation,deterministic_seed,
  capability_mode,run_status,cleanup_status,evidence_ref)
VALUES (
 'SV-P1P5-S3-REPORT-CLOCK-01','s3_period_v1',:'candidate_sha','p1p5_pg17',450520,
 'core','running','not_started','signed-s3-isolated-clock-boundary'
);
INSERT INTO private.exam_prep_synthetic_run_clocks(
  run_id,virtual_now,step_no,clock_status,initialized_evidence_ref)
VALUES('SV-P1P5-S3-REPORT-CLOCK-01',now()+interval '40 days',1,'active',
 'signed-s3-isolated-clock-boundary');
INSERT INTO private.exam_prep_synthetic_identities(
  user_id,identity_status,evidence_ref,purpose,run_id,identity_kind,fixture_profile_key)
VALUES('11111111-1111-4111-8111-111111111191'::uuid,'active',
 'signed-s3-isolated-clock-boundary','S3 calendar month and 7-day report only',
 'SV-P1P5-S3-REPORT-CLOCK-01','learner','SVF-P1P5-S3-PERIOD-01');
COMMIT;
