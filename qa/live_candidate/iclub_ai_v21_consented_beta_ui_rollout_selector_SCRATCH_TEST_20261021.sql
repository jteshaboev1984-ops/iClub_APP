DO $scope$
DECLARE u1 uuid:='11111111-1111-4111-8111-111111111111';
 u2 uuid:='22222222-2222-4222-8222-222222222222';
 u3 uuid:='33333333-3333-4333-8333-333333333333';
BEGIN
 IF NOT private.iclub_rollout_allows_user_v1(u1,'consented_beta_v21')
 OR NOT private.iclub_rollout_allows_user_v1(u2,'consented_beta_v21')
 OR private.iclub_rollout_allows_user_v1(u3,'consented_beta_v21')
 THEN RAISE EXCEPTION 'Consented-only membership is not respected'; END IF;
 IF private.iclub_rollout_allows_user_v1(u1,'off')
 OR private.iclub_rollout_allows_user_v1(u1,'canary')
 OR NOT private.iclub_rollout_allows_user_v1(u3,'all')
 OR private.iclub_rollout_allows_user_v1(NULL,'all')
 OR private.iclub_rollout_allows_user_v1(u1,'unrecognized')
 THEN RAISE EXCEPTION 'Existing UI rollout semantics changed'; END IF;
 UPDATE private.iclub_ai_v21_beta_members SET enabled=false WHERE user_id=u1;
 IF private.iclub_rollout_allows_user_v1(u1,'consented_beta_v21')
 THEN RAISE EXCEPTION 'Disabled beta member retained UI access'; END IF;
 UPDATE private.iclub_ai_v21_beta_members SET enabled=true WHERE user_id=u1;
 UPDATE private.iclub_ai_v21_beta_control SET beta_enabled=false WHERE singleton=1;
 IF private.iclub_rollout_allows_user_v1(u2,'consented_beta_v21')
 THEN RAISE EXCEPTION 'Beta kill switch failed to hide AI UI'; END IF;
 UPDATE private.iclub_ai_v21_beta_control SET beta_enabled=true WHERE singleton=1;
 IF (SELECT global_ai_rollout_mode FROM private.iclub_global_ai_runtime_config WHERE id=1)<>'off'
 OR (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'UI unexpectedly activated';END IF;
END $scope$;
SELECT 'PASS_AI_V21_CONSENTED_BETA_UI_SELECTOR_NO_LEAK' result;
