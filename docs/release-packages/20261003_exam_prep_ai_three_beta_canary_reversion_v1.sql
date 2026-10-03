-- Controlled reversion: return the three existing real beta learners from AI Assist to Core-only.
-- Operational release package, not a schema migration.
-- Safe to apply after the P3-02 real-beta AI canary if rollback/reversion is required.
-- This package intentionally does not touch academic evidence, legacy history, provider budgets, or Mentor Care.

SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '60s';

CREATE TEMP TABLE _ep_ai_canary_revert_legacy_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM public.users) AS users_count,
  (SELECT count(*) FROM public.practice_answers) AS practice_answers_count,
  (SELECT count(*) FROM public.tour_answers) AS tour_answers_count,
  (SELECT count(*) FROM public.certificates) AS certificates_count,
  (SELECT count(*) FROM private.exam_prep_sessions) AS sessions_count,
  (SELECT count(*) FROM private.exam_prep_responses) AS responses_count,
  (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
  (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_states_count,
  (SELECT count(*) FROM private.exam_prep_correction_cases) AS correction_cases_count,
  (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_events_count,
  (SELECT count(*) FROM private.exam_prep_weekly_plans) AS weekly_plans_count,
  (SELECT count(*) FROM private.exam_prep_weekly_plan_items) AS weekly_plan_items_count;

CREATE TEMP TABLE _ep_ai_canary_revert_targets ON COMMIT DROP AS
SELECT bm.user_id,bm.cohort_id
FROM private.exam_prep_beta_members bm
JOIN private.exam_prep_beta_cohorts bc ON bc.id=bm.cohort_id
WHERE bc.cohort_key='math_as_p1_p5_beta_2026_09_01'
  AND bm.member_status='active';

DO $preflight$
DECLARE
  v_cfg private.exam_prep_feature_config%ROWTYPE;
  v_runtime private.exam_prep_optional_capability_status%ROWTYPE;
  v_policy private.exam_prep_ai_policy%ROWTYPE;
  v_count integer;
BEGIN
  SELECT * INTO STRICT v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta'
     OR NOT v_cfg.core_enabled
     OR NOT v_cfg.ai_enabled
     OR v_cfg.mentor_enabled
     OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'ai_canary_revert_bad_feature_baseline %',row_to_json(v_cfg);
  END IF;

  SELECT count(*) INTO v_count FROM _ep_ai_canary_revert_targets;
  IF v_count<>3 THEN
    RAISE EXCEPTION 'ai_canary_revert_requires_exactly_three_active_beta_learners got=%',v_count;
  END IF;

  IF EXISTS(
    SELECT 1 FROM _ep_ai_canary_revert_targets t
    JOIN private.exam_prep_synthetic_identities s ON s.user_id=t.user_id
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_synthetic_identity_forbidden';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM _ep_ai_canary_revert_targets t
    LEFT JOIN private.exam_prep_beta_consents c
      ON c.cohort_id=t.cohort_id AND c.user_id=t.user_id
    WHERE c.id IS NULL OR c.consent_status<>'granted' OR c.revoked_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_target_without_valid_beta_consent';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE ai_assist)<>3 THEN
    RAISE EXCEPTION 'ai_canary_revert_expected_exactly_three_ai_entitlements';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_feature_entitlements e
    WHERE e.ai_assist
      AND NOT EXISTS(
        SELECT 1 FROM _ep_ai_canary_revert_targets t WHERE t.user_id=e.user_id
      )
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_non_target_ai_entitlement';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM _ep_ai_canary_revert_targets t
    LEFT JOIN private.exam_prep_feature_entitlements e ON e.user_id=t.user_id
    LEFT JOIN private.exam_prep_beta_members bm
      ON bm.user_id=t.user_id AND bm.cohort_id=t.cohort_id
    WHERE e.user_id IS NULL
       OR e.entitlement_status<>'active'
       OR NOT e.core_access
       OR NOT e.ai_assist
       OR e.mentor_care_entitled
       OR bm.service_mode<>'ai_assist'
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_bad_target_ai_baseline';
  END IF;

  SELECT * INTO STRICT v_runtime
  FROM private.exam_prep_optional_capability_status
  WHERE capability_code='ai_assist';
  IF v_runtime.runtime_status<>'ready'
     OR v_runtime.gate_version IS DISTINCT FROM 'p3_02_real_beta_ai_canary_v1' THEN
    RAISE EXCEPTION 'ai_canary_revert_runtime_not_active baseline=% gate=%',
      v_runtime.runtime_status,v_runtime.gate_version;
  END IF;

  SELECT * INTO STRICT v_policy FROM private.exam_prep_ai_policy WHERE id=1;
  IF NOT v_policy.generation_enabled THEN
    RAISE EXCEPTION 'ai_canary_revert_generation_not_enabled';
  END IF;

  IF (private.exam_prep_active_plan_transition_audit_v1()->>'hard_anomaly_count')::integer<>0 THEN
    RAISE EXCEPTION 'ai_canary_revert_core_transition_audit_not_green';
  END IF;
END;
$preflight$;

UPDATE private.exam_prep_feature_config
SET ai_enabled=false,
    updated_at=now()
WHERE id=1;

UPDATE private.exam_prep_ai_policy
SET generation_enabled=false,
    updated_at=now()
WHERE id=1;

UPDATE private.exam_prep_optional_capability_status
SET runtime_status='shadow',
    gate_version='p3_02_real_beta_ai_canary_reverted_v1',
    evidence=coalesce(evidence,'{}'::jsonb) || jsonb_build_object(
      'reverted_at',now(),
      'reverted_from','p3_02_real_beta_ai_canary_v1',
      'real_beta_learners',3,
      'academic_state_changed',false,
      'mentor_care_changed',false,
      'active_provider_leases_at_reversion',(
        SELECT count(*)
        FROM private.exam_prep_ai_provider_leases
        WHERE status='active' AND expires_at>now()
      )
    ),
    updated_at=now()
WHERE capability_code='ai_assist';

UPDATE private.exam_prep_beta_members bm
SET service_mode='core',
    updated_at=now()
FROM _ep_ai_canary_revert_targets t
WHERE bm.cohort_id=t.cohort_id
  AND bm.user_id=t.user_id
  AND bm.member_status='active';

UPDATE private.exam_prep_feature_entitlements e
SET ai_assist=false,
    updated_at=now()
FROM _ep_ai_canary_revert_targets t
WHERE e.user_id=t.user_id
  AND e.entitlement_status='active'
  AND e.core_access=true;

INSERT INTO private.exam_prep_audit_events(
  actor_role,event_type,object_type,object_id,metadata
) VALUES(
  'product_architect_explicit_decision',
  'ai_controlled_beta_canary_reverted',
  'ai_assist',
  'p3_02_real_beta_ai_canary_reverted_v1',
  jsonb_build_object(
    'cohort_key','math_as_p1_p5_beta_2026_09_01',
    'learner_count',3,
    'mentor_care_changed',false,
    'academic_state_changed',false,
    'legacy_state_changed',false
  )
);

INSERT INTO private.exam_prep_audit_events(
  actor_role,event_type,object_type,object_id,target_user_id,metadata
)
SELECT
  'product_architect_explicit_decision',
  'ai_assist_entitlement_reverted',
  'feature_entitlement',
  t.user_id::text,
  t.user_id,
  jsonb_build_object(
    'cohort_key','math_as_p1_p5_beta_2026_09_01',
    'service_mode','core',
    'academic_state_changed',false
  )
FROM _ep_ai_canary_revert_targets t;

DO $postcheck$
DECLARE
  r record;
  c record;
  v_guard jsonb;
  v_before record;
BEGIN
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_feature_config
    WHERE id=1
      AND rollout_state='controlled_beta'
      AND core_enabled
      AND NOT ai_enabled
      AND NOT mentor_enabled
      AND NOT kill_switch
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_feature_postcheck_failed';
  END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_optional_capability_status
    WHERE capability_code='ai_assist'
      AND runtime_status='shadow'
      AND gate_version='p3_02_real_beta_ai_canary_reverted_v1'
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_runtime_postcheck_failed';
  END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_ai_policy
    WHERE id=1 AND NOT generation_enabled
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_generation_postcheck_failed';
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_feature_entitlements WHERE ai_assist
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_entitlement_scope_leak';
  END IF;

  IF (SELECT count(*)
      FROM private.exam_prep_beta_members bm
      JOIN _ep_ai_canary_revert_targets t
        ON t.cohort_id=bm.cohort_id AND t.user_id=bm.user_id
      WHERE bm.member_status='active' AND bm.service_mode='core')<>3 THEN
    RAISE EXCEPTION 'ai_canary_revert_service_mode_postcheck_failed';
  END IF;

  FOR r IN SELECT user_id FROM _ep_ai_canary_revert_targets ORDER BY user_id
  LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);

    SELECT * INTO STRICT c FROM public.get_exam_prep_capabilities_v1();
    IF NOT c.core_access OR c.ai_assist
       OR c.mentor_care_entitled OR c.mentor_assignment_active
       OR c.mentor_authority OR c.kill_switch THEN
      RAISE EXCEPTION 'ai_canary_revert_capability_postcheck_failed user=% cap=%',r.user_id,row_to_json(c);
    END IF;

    v_guard:=public.get_exam_prep_ai_guard_v1('P1','theory_explanation','en',0);
    IF coalesce((v_guard->>'allowed')::boolean,false) IS TRUE THEN
      RAISE EXCEPTION 'ai_canary_revert_guard_still_open user=% guard=%',r.user_id,v_guard;
    END IF;
  END LOOP;

  SELECT * INTO STRICT v_before FROM _ep_ai_canary_revert_legacy_before;
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
    RAISE EXCEPTION 'ai_canary_revert_academic_or_legacy_state_changed';
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_synthetic_identities
    WHERE identity_status='active'
  ) THEN
    RAISE EXCEPTION 'ai_canary_revert_active_synthetic_residue';
  END IF;

  IF (private.exam_prep_active_plan_transition_audit_v1()->>'hard_anomaly_count')::integer<>0 THEN
    RAISE EXCEPTION 'ai_canary_revert_core_transition_audit_drift';
  END IF;
END;
$postcheck$;
