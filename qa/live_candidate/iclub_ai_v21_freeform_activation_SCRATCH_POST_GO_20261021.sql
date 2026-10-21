DO $verify$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_global_ai_runtime_config
   WHERE id=1 AND global_ai_rollout_mode='consented_beta_v21'
     AND NOT kill_switch AND ui_enabled AND gateway_enabled
     AND NOT generation_enabled AND NOT plans_ui_enabled AND NOT checkout_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND enabled AND maximum_lifetime_microusd=5000000)
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_members m
   WHERE private.iclub_rollout_allows_user_v1(m.user_id,'consented_beta_v21'))<>2
 OR (SELECT count(*) FROM private.iclub_ai_v21_freeform_budget_ledger)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_freeform_quota_holds)<>0
 THEN RAISE EXCEPTION 'Pilot activation not consent-only or introduced spend';END IF;
END $verify$;
SELECT 'PASS_FREEFORM_BETA_OWNER_5USD_CONSENTED_ROLLOUT_ACTIVE_ONLY' result;
