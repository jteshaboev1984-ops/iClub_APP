-- OPERATIONAL REVERSION — disable provider-free Tutor Template canary.
-- Restores immediate fallback to the existing provider-backed theory path.
-- Does not change Tutor Card approval, learner academic state, entitlements or cohort membership.

SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';

DO $precheck$
BEGIN
  IF NOT EXISTS(
    SELECT 1
    FROM private.exam_prep_ai_tutor_template_policy
    WHERE id=1 AND template_canary_enabled
  ) THEN
    RAISE EXCEPTION 'tutor_template_canary_not_enabled';
  END IF;
END
$precheck$;

UPDATE private.exam_prep_ai_tutor_template_policy
SET template_canary_enabled=false,
    updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_audit_events(
  actor_role,event_type,object_type,object_id,metadata
) VALUES(
  'product_architect_reversion',
  'tutor_template_controlled_beta_canary_disabled',
  'ai_tutor_template',
  'tutor_template_canary_v1',
  jsonb_build_object(
    'fallback','provider_backed_theory_explanation',
    'academic_state_changed',false,
    'legacy_state_changed',false
  )
);

DO $postcheck$
BEGIN
  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_ai_tutor_template_policy
    WHERE id=1 AND template_canary_enabled
  ) THEN
    RAISE EXCEPTION 'tutor_template_canary_reversion_failed';
  END IF;
END
$postcheck$;
