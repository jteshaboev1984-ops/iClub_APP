-- OPERATIONAL RELEASE PACKAGE — enable provider-free Tutor Template canary.
-- Apply only after the canary code PR is merged, Edge Function is deployed,
-- current frontend asset is visible in production, and CI/smoke preflight is GREEN.
-- Scope: exactly the existing three real beta learners. No cohort expansion.

SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';

CREATE TEMP TABLE _ep_tutor_template_legacy_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM public.users) users_count,
  (SELECT count(*) FROM public.practice_answers) practice_answers_count,
  (SELECT count(*) FROM public.tour_answers) tour_answers_count,
  (SELECT count(*) FROM public.certificates) certificates_count,
  (SELECT count(*) FROM private.exam_prep_sessions) sessions_count,
  (SELECT count(*) FROM private.exam_prep_responses) responses_count,
  (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_count,
  (SELECT count(*) FROM private.exam_prep_skill_states) skill_states_count,
  (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases_count,
  (SELECT count(*) FROM private.exam_prep_retest_events) retest_events_count,
  (SELECT count(*) FROM private.exam_prep_weekly_plans) weekly_plans_count,
  (SELECT count(*) FROM private.exam_prep_weekly_plan_items) weekly_plan_items_count;

CREATE TEMP TABLE _ep_tutor_template_targets ON COMMIT DROP AS
SELECT bm.user_id,bm.cohort_id
FROM private.exam_prep_beta_members bm
JOIN private.exam_prep_beta_cohorts bc on bc.id=bm.cohort_id
WHERE bc.cohort_key='math_as_p1_p5_beta_2026_09_01'
  AND bm.member_status='active'
  AND bm.service_mode='ai_assist';

DO $preflight$
DECLARE
  v_count integer;
  v_cfg private.exam_prep_feature_config%ROWTYPE;
  v_policy private.exam_prep_ai_tutor_template_policy%ROWTYPE;
BEGIN
  SELECT * INTO STRICT v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta'
     OR NOT v_cfg.core_enabled
     OR NOT v_cfg.ai_enabled
     OR v_cfg.mentor_enabled
     OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'tutor_template_bad_feature_state %',row_to_json(v_cfg);
  END IF;

  SELECT * INTO STRICT v_policy FROM private.exam_prep_ai_tutor_template_policy WHERE id=1;
  IF v_policy.template_canary_enabled THEN
    RAISE EXCEPTION 'tutor_template_canary_already_enabled';
  END IF;
  IF v_policy.cohort_key<>'math_as_p1_p5_beta_2026_09_01'
     OR NOT v_policy.preset_followups_enabled THEN
    RAISE EXCEPTION 'tutor_template_policy_drift %',row_to_json(v_policy);
  END IF;

  SELECT count(*) INTO v_count FROM _ep_tutor_template_targets;
  IF v_count<>3 THEN
    RAISE EXCEPTION 'tutor_template_requires_exactly_three_real_beta_learners got=%',v_count;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM _ep_tutor_template_targets t
    JOIN private.exam_prep_synthetic_identities s ON s.user_id=t.user_id
  ) THEN
    RAISE EXCEPTION 'tutor_template_synthetic_target_forbidden';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM _ep_tutor_template_targets t
    LEFT JOIN private.exam_prep_beta_consents c
      ON c.cohort_id=t.cohort_id AND c.user_id=t.user_id
    WHERE c.id IS NULL OR c.consent_status<>'granted' OR c.revoked_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'tutor_template_target_without_valid_consent';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM _ep_tutor_template_targets t
    LEFT JOIN private.exam_prep_feature_entitlements e ON e.user_id=t.user_id
    WHERE e.user_id IS NULL
       OR e.entitlement_status<>'active'
       OR NOT e.core_access
       OR NOT e.ai_assist
       OR e.mentor_care_entitled
       OR e.cohort_key IS DISTINCT FROM 'math_as_p1_p5_beta_2026_09_01'
       OR (e.valid_from IS NOT NULL AND e.valid_from>now())
       OR (e.valid_until IS NOT NULL AND e.valid_until<=now())
  ) THEN
    RAISE EXCEPTION 'tutor_template_bad_target_entitlement';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_ai_tutor_cards
      WHERE content_version='tutor_v2_learner_first'
        AND approval_status='approved'
        AND is_runtime_allowed)<>243 THEN
    RAISE EXCEPTION 'tutor_template_243_runtime_cards_required';
  END IF;

  IF public.get_exam_prep_ai_tutor_card_coverage_service_v1()
     <> '{"expected":243,"ready":243,"missing":0,"p1_ready":135,"p5_ready":108}'::jsonb THEN
    RAISE EXCEPTION 'tutor_template_coverage_not_243 %',
      public.get_exam_prep_ai_tutor_card_coverage_service_v1();
  END IF;

  IF (private.exam_prep_active_plan_transition_audit_v1()->>'hard_anomaly_count')::integer<>0 THEN
    RAISE EXCEPTION 'tutor_template_core_transition_audit_not_green';
  END IF;
END
$preflight$;

UPDATE private.exam_prep_ai_tutor_template_policy
SET template_canary_enabled=true,
    updated_at=now()
WHERE id=1
  AND template_canary_enabled=false;

INSERT INTO private.exam_prep_audit_events(
  actor_role,event_type,object_type,object_id,metadata
) VALUES(
  'product_architect_explicit_decision',
  'tutor_template_controlled_beta_canary_activated',
  'ai_tutor_template',
  'tutor_template_canary_v1',
  jsonb_build_object(
    'cohort_key','math_as_p1_p5_beta_2026_09_01',
    'learner_count',3,
    'tutor_cards_ready',243,
    'preset_followups_provider_free',true,
    'free_text_followup_provider_backed',true,
    'academic_state_changed',false,
    'legacy_state_changed',false
  )
);

DO $postcheck$
DECLARE
  r record;
  v_before record;
  v_gate jsonb;
BEGIN
  FOR r IN SELECT user_id FROM _ep_tutor_template_targets ORDER BY user_id
  LOOP
    v_gate:=public.get_exam_prep_ai_tutor_template_canary_service_v1(r.user_id);
    IF coalesce((v_gate->>'enabled')::boolean,false) IS NOT TRUE
       OR coalesce((v_gate->>'preset_followups_enabled')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'tutor_template_canary_gate_not_enabled user=% gate=%',r.user_id,v_gate;
    END IF;
  END LOOP;

  IF (SELECT count(*) FROM private.exam_prep_feature_entitlements
      WHERE entitlement_status='active' AND ai_assist)<>3 THEN
    RAISE EXCEPTION 'tutor_template_canary_scope_leak';
  END IF;

  SELECT * INTO STRICT v_before FROM _ep_tutor_template_legacy_before;
  IF v_before.users_count IS DISTINCT FROM (SELECT count(*) FROM public.users)
     OR v_before.practice_answers_count IS DISTINCT FROM (SELECT count(*) FROM public.practice_answers)
     OR v_before.tour_answers_count IS DISTINCT FROM (SELECT count(*) FROM public.tour_answers)
     OR v_before.certificates_count IS DISTINCT FROM (SELECT count(*) FROM public.certificates)
     OR v_before.sessions_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_sessions)
     OR v_before.responses_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_responses)
     OR v_before.evidence_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_evidence_events)
     OR v_before.skill_states_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_skill_states)
     OR v_before.correction_cases_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_correction_cases)
     OR v_before.retest_events_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_retest_events)
     OR v_before.weekly_plans_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_weekly_plans)
     OR v_before.weekly_plan_items_count IS DISTINCT FROM (SELECT count(*) FROM private.exam_prep_weekly_plan_items)
  THEN
    RAISE EXCEPTION 'tutor_template_canary_changed_academic_or_legacy_state';
  END IF;

  IF (private.exam_prep_active_plan_transition_audit_v1()->>'hard_anomaly_count')::integer<>0 THEN
    RAISE EXCEPTION 'tutor_template_canary_transition_audit_drift';
  END IF;
END
$postcheck$;
