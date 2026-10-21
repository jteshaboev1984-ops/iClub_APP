-- QA-ONLY draft: expand the ONE Global AI UI rollout check (not plans).
-- No switch changes; startup remains OFF.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_ai_v21_beta_members') IS NULL
 OR (SELECT global_ai_rollout_mode FROM private.iclub_global_ai_runtime_config WHERE id=1)<>'off'
 OR (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 OR NOT EXISTS(SELECT 1 FROM pg_constraint c
   WHERE c.conrelid='private.iclub_global_ai_runtime_config'::regclass
   AND c.conname='iclub_global_ai_runtime_config_global_ai_rollout_mode_check'
   AND pg_get_constraintdef(c.oid) LIKE '%off%'
   AND pg_get_constraintdef(c.oid) LIKE '%canary%'
   AND pg_get_constraintdef(c.oid) LIKE '%all%'
   AND pg_get_constraintdef(c.oid) NOT LIKE '%consented_beta_v21%')
 THEN RAISE EXCEPTION 'UI rollout enum baseline drift';END IF;
END $pre$;

ALTER TABLE private.iclub_global_ai_runtime_config
 DROP CONSTRAINT iclub_global_ai_runtime_config_global_ai_rollout_mode_check;
ALTER TABLE private.iclub_global_ai_runtime_config
 ADD CONSTRAINT iclub_global_ai_runtime_config_global_ai_rollout_mode_check
 CHECK(global_ai_rollout_mode IN ('off','canary','all','consented_beta_v21'));

DO $post$ BEGIN
 IF (SELECT global_ai_rollout_mode FROM private.iclub_global_ai_runtime_config WHERE id=1)<>'off'
 OR (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 OR (SELECT ui_enabled FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM false
 OR (SELECT gateway_enabled FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Consent-only UI enum migration unexpectedly opened AI'; END IF;
END $post$;
