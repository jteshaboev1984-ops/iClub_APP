-- IMMEDIATE owner pilot kill switch, preserving every accounting record.
-- No deletion of user progression, prior requests, source versions or ledger.
UPDATE private.iclub_ai_v21_freeform_budget_control
 SET enabled=false,updated_at=clock_timestamp()
 WHERE singleton=1 AND enabled;
UPDATE private.iclub_global_ai_runtime_config
 SET kill_switch=true,ui_enabled=false,gateway_enabled=false,
  global_ai_rollout_mode='off',updated_at=clock_timestamp()
 WHERE id=1 AND global_ai_rollout_mode='consented_beta_v21';
DO $check$ BEGIN
 IF (SELECT enabled FROM private.iclub_ai_v21_freeform_budget_control WHERE singleton=1)
 OR (SELECT global_ai_rollout_mode FROM private.iclub_global_ai_runtime_config WHERE id=1)<>'off'
 OR (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'Pilot shutdown incomplete';END IF;
END $check$;
