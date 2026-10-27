-- OWNER-APPROVED CONTROLLED BETA. Apply ONLY after vetted migration and isolated
-- authorization/payment tests. Additive grants + independent ON switches.
-- No exam, result, submission, learning progress, consent, budget or
-- preexisting access is modified. Strictly 3 presently active Math P1/P5 testers.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='90s';
DO $enroll$
DECLARE n integer;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control
   WHERE singleton=1 AND NOT enabled AND owner_user_id IS NULL AND NOT error_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control WHERE singleton=1 AND NOT enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control WHERE singleton=1 AND NOT enabled)
 THEN RAISE EXCEPTION 'Practice AI gates not in reviewed OFF baseline'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_practice_beta_grants_v1)
 THEN RAISE EXCEPTION 'Unexpected existing Practice beta grants'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled AND NOT generation_enabled
     AND approved_release<>'none')
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND enabled AND NOT provider_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta
     AND model='gpt-5.4-mini'
     AND maximum_lifetime_microusd=5000000
     AND maximum_per_request_microusd=50000
     AND maximum_per_learner_microusd=750000 AND maximum_parallel=2
     AND output_token_cap=384 AND input_microusd_per_token=0.75
     AND output_microusd_per_token=4.5)
 THEN RAISE EXCEPTION 'Existing safety, source or financial policy differs'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
     WHERE id=1 AND rollout_state='controlled_beta' AND core_enabled AND ai_enabled AND NOT kill_switch)
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_optional_capability_status
     WHERE capability_code='ai_assist' AND runtime_status='ready')
 THEN RAISE EXCEPTION 'Exam Prep beta AI is no longer ready'; END IF;
 SELECT count(*) INTO n FROM (
   SELECT DISTINCT bm.user_id
   FROM private.exam_prep_beta_members bm
   JOIN private.exam_prep_beta_cohorts cohort
    ON cohort.id=bm.cohort_id AND cohort.program_key='math_as_p1_p5'
     AND cohort.cohort_status='canary'
   JOIN private.exam_prep_beta_consents consent
    ON consent.user_id=bm.user_id AND consent.cohort_id=cohort.id
     AND consent.consent_scope='exam_prep_controlled_beta_v1'
     AND consent.consent_status='granted' AND consent.revoked_at IS NULL
   JOIN private.exam_prep_feature_entitlements ent
    ON ent.user_id=bm.user_id AND ent.entitlement_status='active'
     AND ent.core_access AND ent.ai_assist
     AND (ent.valid_from IS NULL OR ent.valid_from<=now())
     AND (ent.valid_until IS NULL OR ent.valid_until>now())
   JOIN private.iclub_ai_v21_beta_members g ON g.user_id=bm.user_id
    AND (g.consent_at IS NOT NULL AND g.consent_version='global_ai_beta_v21'
         AND g.enabled OR
         g.consent_at IS NULL AND NOT g.enabled)
   WHERE bm.member_status='active' AND bm.service_mode='ai_assist'
 ) authorized;
 IF n<>3 THEN RAISE EXCEPTION 'Expected 3, found % eligible Mathematics beta accounts',n; END IF;
END $enroll$;
INSERT INTO private.iclub_ai_practice_beta_grants_v1(user_id,enabled)
 SELECT DISTINCT bm.user_id,true
 FROM private.exam_prep_beta_members bm
 JOIN private.exam_prep_beta_cohorts cohort
  ON cohort.id=bm.cohort_id AND cohort.program_key='math_as_p1_p5'
   AND cohort.cohort_status='canary'
 JOIN private.exam_prep_beta_consents consent
  ON consent.user_id=bm.user_id AND consent.cohort_id=cohort.id
   AND consent.consent_scope='exam_prep_controlled_beta_v1'
   AND consent.consent_status='granted' AND consent.revoked_at IS NULL
 JOIN private.exam_prep_feature_entitlements ent
  ON ent.user_id=bm.user_id AND ent.entitlement_status='active'
   AND ent.core_access AND ent.ai_assist
   AND (ent.valid_from IS NULL OR ent.valid_from<=now())
   AND (ent.valid_until IS NULL OR ent.valid_until>now())
 JOIN private.iclub_ai_v21_beta_members g ON g.user_id=bm.user_id
  AND ((g.consent_at IS NOT NULL AND g.consent_version='global_ai_beta_v21'
      AND g.enabled) OR (g.consent_at IS NULL AND NOT g.enabled))
 WHERE bm.member_status='active' AND bm.service_mode='ai_assist';
DO $verify$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 THEN RAISE EXCEPTION 'Incorrect Practice beta grant population'; END IF;
END $verify$;
UPDATE private.iclub_ai_practice_context_v1_control
 SET enabled=true,owner_user_id=NULL,error_enabled=false,updated_at=now()
 WHERE singleton=1;
UPDATE private.iclub_ai_practice_receipt_v1_control
 SET enabled=true,updated_at=now() WHERE singleton=1;
UPDATE private.iclub_ai_practice_freeform_pc3_control
 SET enabled=true,updated_at=now() WHERE singleton=1;
DO $release$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control
     WHERE singleton=1 AND enabled AND owner_user_id IS NULL AND NOT error_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control
     WHERE singleton=1 AND enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control
     WHERE singleton=1 AND enabled)
 OR (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 THEN RAISE EXCEPTION 'Controlled beta activation failed'; END IF;
END $release$;
COMMIT;
