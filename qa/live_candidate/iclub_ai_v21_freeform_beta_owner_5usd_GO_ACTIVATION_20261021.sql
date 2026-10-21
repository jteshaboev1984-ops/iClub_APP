-- iClub Global AI v2.1 | Owner-authorized controlled Free beta, $5 LIFETIME.
-- APPLY ONLY AFTER: new JWT Edge v2 ACTIVE, main transport bundle READY,
-- immutable versioned source ledger intact, QA+current-main parity PASS.
-- This is a single atomic rollout of two independent kill switches.
DO $guard$
DECLARE v_consented integer; v_allowed integer;
BEGIN
 IF to_regclass('private.iclub_ai_v21_freeform_budget_control') IS NULL
 OR to_regclass('private.iclub_ai_v21_freeform_budget_ledger') IS NULL
 OR to_regclass('private.iclub_ai_v21_freeform_quota_holds') IS NULL
 OR to_regprocedure('public.get_iclub_ai_v21_freeform_help_bundle_v1(text)') IS NULL
 OR position('generation_no_longer_authorized' in pg_get_functiondef(
 'public.finish_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text,text)'::regprocedure))=0
 THEN RAISE EXCEPTION 'Required versioned beta backend missing'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_global_ai_runtime_config
   WHERE id=1 AND global_ai_rollout_mode='off' AND kill_switch
    AND NOT ui_enabled AND NOT gateway_enabled AND NOT generation_enabled
    AND NOT plans_ui_enabled AND NOT checkout_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled AND NOT generation_enabled
    AND approved_release<>'none')
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND enabled AND NOT provider_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND NOT enabled AND owner_permitted AND include_free_beta
   AND model='gpt-5.4-mini' AND maximum_lifetime_microusd=5000000
   AND maximum_per_request_microusd=50000
   AND output_token_cap=384
   AND input_microusd_per_token=0.750000
   AND output_microusd_per_token=4.500000)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_quota_holds)
 THEN RAISE EXCEPTION 'Owner $5 controlled beta activation baseline drift';END IF;
 SELECT count(*) INTO v_consented FROM private.iclub_ai_v21_beta_members
 WHERE enabled AND consent_version='global_ai_beta_v21'
  AND consent_at IS NOT NULL;
 SELECT count(*) INTO v_allowed FROM private.iclub_ai_v21_beta_members m
 WHERE private.iclub_rollout_allows_user_v1(m.user_id,'consented_beta_v21');
 IF v_consented NOT BETWEEN 1 AND 12 OR v_allowed<>v_consented
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members m
  WHERE (NOT m.enabled OR m.consent_at IS NULL
   OR m.consent_version IS DISTINCT FROM 'global_ai_beta_v21')
  AND private.iclub_rollout_allows_user_v1(m.user_id,'consented_beta_v21'))
 THEN RAISE EXCEPTION 'Free beta consent/rollout membership mismatch'; END IF;
 IF (SELECT count(*) FROM (SELECT locale FROM
   private.iclub_ai_v21_beta_help_sources WHERE published AND NOT revoked
     AND content_reviewed AND rights_reviewed AND locale_reviewed
     AND approved_at IS NOT NULL GROUP BY locale
   HAVING count(*)=13) trusted_locale)<>3
 OR NOT ((public.get_iclub_ai_v21_freeform_help_bundle_v1('en')->>'ok')::boolean)
 OR NOT ((public.get_iclub_ai_v21_freeform_help_bundle_v1('ru')->>'ok')::boolean)
 OR NOT ((public.get_iclub_ai_v21_freeform_help_bundle_v1('uz')->>'ok')::boolean)
 THEN RAISE EXCEPTION 'Approved sources incomplete'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources s
     WHERE private.iclub_ai_v21_source_admitted_v1(s))<>111
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_beta_releases)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_signed_review_receipts)
 THEN RAISE EXCEPTION 'Academic beta publication drift'; END IF;
END $guard$;

UPDATE private.iclub_global_ai_runtime_config
SET global_ai_rollout_mode='consented_beta_v21',
    kill_switch=false,ui_enabled=true,gateway_enabled=true,
    updated_at=clock_timestamp()
WHERE id=1;
UPDATE private.iclub_ai_v21_freeform_budget_control
SET enabled=true,updated_at=clock_timestamp()
WHERE singleton=1;

DO $post$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM private.iclub_global_ai_runtime_config
  WHERE id=1 AND global_ai_rollout_mode='consented_beta_v21'
   AND NOT kill_switch AND ui_enabled AND gateway_enabled
   AND NOT generation_enabled AND NOT plans_ui_enabled AND NOT checkout_enabled)
 OR NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta
  AND maximum_lifetime_microusd=5000000)
 THEN RAISE EXCEPTION 'Partial Global AI beta activation: rollback transaction'; END IF;
END $post$;
