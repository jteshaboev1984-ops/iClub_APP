-- iClub Global AI v2.1: additive consented-beta-only UI rollout selector.
-- ALL and CANARY keep EXACT old behavior; current global rollout stays 'off'.
-- No change to Math Tutor, questions, learners, enrollment, tariffs or runtime.
DO $guard$ BEGIN
 IF (SELECT global_ai_rollout_mode FROM private.iclub_global_ai_runtime_config WHERE id=1)<>'off'
 OR (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 OR (SELECT ui_enabled FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM false
 OR (SELECT gateway_enabled FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM false
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled AND NOT generation_enabled)
 THEN RAISE EXCEPTION 'iClub beta UI rollout baseline drift'; END IF;
END $guard$;

CREATE OR REPLACE FUNCTION private.iclub_rollout_allows_user_v1(
 p_user_id uuid,p_rollout_mode text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $fn$
 SELECT CASE
 WHEN p_user_id IS NULL THEN false
 WHEN p_rollout_mode='all' THEN true
 WHEN p_rollout_mode='canary' THEN private.iclub_is_product_canary_v1(p_user_id)
 WHEN p_rollout_mode='consented_beta_v21' THEN EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_beta_members m
  WHERE m.user_id=p_user_id AND m.enabled
   AND m.consent_version='global_ai_beta_v21'
   AND m.consent_at IS NOT NULL
   AND EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control c
    WHERE c.singleton=1 AND c.beta_enabled AND c.prepared_enabled
      AND NOT c.generation_enabled AND c.approved_release<>'none'))
 ELSE false END;
$fn$;
REVOKE ALL ON FUNCTION private.iclub_rollout_allows_user_v1(uuid,text)
 FROM PUBLIC,anon,authenticated;
-- Reapply only the exact legacy grants if they existed, via existing schema
-- ownership. PostgreSQL CREATE OR REPLACE preserves prior function ACL.

DO $post$ BEGIN
 IF (SELECT global_ai_rollout_mode FROM private.iclub_global_ai_runtime_config WHERE id=1)<>'off'
 OR (SELECT kill_switch FROM private.iclub_global_ai_runtime_config WHERE id=1) IS DISTINCT FROM true
 THEN RAISE EXCEPTION 'UI selector inadvertently enabled user access'; END IF;
END $post$;
