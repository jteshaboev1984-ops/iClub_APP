DO $verify$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_global_ai_runtime_config
  WHERE id=1 AND global_ai_rollout_mode='off' AND kill_switch
    AND NOT ui_enabled AND NOT gateway_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 AND NOT enabled)
 OR (SELECT count(*) FROM private.iclub_ai_v21_freeform_budget_ledger)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_members WHERE enabled)<>3
 THEN RAISE EXCEPTION 'Pilot instant kill altered beta users or enabled spend';END IF;
END $verify$;
SELECT 'PASS_FREEFORM_BETA_OWNER_5USD_KILL_SWITCH_NO_USER_DATA_LOSS' result;
