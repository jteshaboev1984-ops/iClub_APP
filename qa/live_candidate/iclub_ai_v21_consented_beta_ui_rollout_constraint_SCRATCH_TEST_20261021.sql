DO $check$ DECLARE refused boolean:=false;
BEGIN
 UPDATE private.iclub_global_ai_runtime_config
 SET global_ai_rollout_mode='consented_beta_v21' WHERE id=1;
 IF NOT private.iclub_rollout_allows_user_v1(
  '11111111-1111-4111-8111-111111111111','consented_beta_v21')
 OR private.iclub_rollout_allows_user_v1(
  '33333333-3333-4333-8333-333333333333','consented_beta_v21')
 THEN RAISE EXCEPTION 'UI rollout enum uses invalid audience'; END IF;
 BEGIN
  UPDATE private.iclub_global_ai_runtime_config
  SET global_ai_rollout_mode='all_users_and_more' WHERE id=1;
 EXCEPTION WHEN check_violation THEN refused:=true; END;
 IF NOT refused THEN RAISE EXCEPTION 'UI allowed unrestricted new mode'; END IF;
 UPDATE private.iclub_global_ai_runtime_config
 SET global_ai_rollout_mode='off' WHERE id=1;
 IF (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 OR (SELECT ui_enabled FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Synthetic UI was not reset to OFF'; END IF;
END $check$;
SELECT 'PASS_CONSENTED_BETA_UI_MODE_CONSTRAINT_FAIL_CLOSED' result;
