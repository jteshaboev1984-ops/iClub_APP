-- Controlled Global AI v2.1 beta: only 3 preselected existing Math-beta
-- accounts, plus EXPLICIT separate voluntary Global AI opt-in.
-- Authorisation: architect approved real-user beta after source publication.
-- ZERO provider calls, ZERO alteration to legacy Mathematics Exam Prep.
DO $guard$
DECLARE n integer;
BEGIN
 IF md5(pg_get_functiondef('public.iclub_ai_v21_beta_opt_in_service_v1(text)'::regprocedure))
    <> '79c3aa5e958e615e2fc0aba928d0ff4f'
 THEN RAISE EXCEPTION 'Consent RPC changed after preflight'; END IF;
 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_v21_beta_control
  WHERE singleton=1 AND NOT beta_enabled AND NOT prepared_enabled
   AND NOT generation_enabled AND approved_release='none'
 ) OR EXISTS (
  SELECT 1 FROM private.iclub_global_ai_runtime_config
  WHERE ui_enabled OR gateway_enabled OR generation_enabled OR NOT kill_switch
 ) THEN RAISE EXCEPTION 'Beta/runtime already enabled unexpectedly'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_members) <> 3
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members WHERE enabled OR consent_at IS NOT NULL)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_deliveries)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_usage)
 THEN RAISE EXCEPTION 'New beta must contain only 3 unconsented and unused candidates'; END IF;
 SELECT count(*) INTO n FROM private.iclub_ai_v21_beta_help_sources
 WHERE source_version='app-nav-main-453127c3-v1'
 AND published AND NOT revoked AND content_reviewed AND rights_reviewed
 AND locale_reviewed AND approved_at IS NOT NULL
 AND publication_revision=1
 AND source_hash=encode(extensions.digest(convert_to(message,'UTF8'),'sha256'),'hex');
 IF n<>18 OR
  (SELECT count(*) FROM private.iclub_ai_v21_beta_help_sources)<>18
 THEN RAISE EXCEPTION 'First verified navigational publication is not intact'; END IF;
 SELECT count(DISTINCT b.user_id) INTO n
 FROM private.iclub_ai_v21_beta_members b
 JOIN private.exam_prep_beta_members m ON m.user_id=b.user_id
 JOIN private.exam_prep_feature_entitlements e ON e.user_id=b.user_id
 WHERE m.member_status='active'
 AND m.service_mode='ai_assist' AND e.entitlement_status='active'
 AND e.ai_assist AND e.core_access AND e.cohort_key='math_as_p1_p5_beta_2026_09_01'
 AND (e.valid_from IS NULL OR e.valid_from<=now())
 AND (e.valid_until IS NULL OR e.valid_until>now());
 IF n<>3 THEN RAISE EXCEPTION 'Only 3 currently eligible existing Math-beta candidates may be staged'; END IF;
END $guard$;

-- Only allow voluntary consent for ALREADY admitted beta candidates.
-- No enrollment is produced merely by the Math-beta consent.
CREATE OR REPLACE FUNCTION public.iclub_ai_v21_beta_opt_in_service_v1(
 p_consent_version text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $consent$
DECLARE v_uid uuid:=auth.uid();
BEGIN
 IF v_uid IS NULL OR p_consent_version<>'global_ai_beta_v21' THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_consent'); END IF;
 UPDATE private.iclub_ai_v21_beta_members
 SET consent_at=coalesce(consent_at,clock_timestamp()),
     consent_version='global_ai_beta_v21',updated_at=clock_timestamp()
 WHERE user_id=v_uid AND enabled=true AND consent_at IS NULL;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'recorded',true); END IF;
 RETURN jsonb_build_object('ok',false,'reason','not_eligible_or_already_recorded');
END $consent$;
REVOKE ALL ON FUNCTION public.iclub_ai_v21_beta_opt_in_service_v1(text)
 FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.iclub_ai_v21_beta_opt_in_service_v1(text)
 TO authenticated;

-- Cohort enablement alone grants NO access: no one has separately consented.
UPDATE private.iclub_ai_v21_beta_members
SET enabled=true,updated_at=clock_timestamp()
WHERE consent_at IS NULL AND consent_version IS NULL AND enabled=false;

-- Prepared-only beta release is independent from older disabled global AI.
-- It can deliver only exact owner-checked, integrity-checked public navigation.
UPDATE private.iclub_ai_v21_beta_control
SET beta_enabled=true,prepared_enabled=true,generation_enabled=false,
    approved_release='app-nav-main-453127c3-v1',
    updated_at=clock_timestamp()
WHERE singleton=1 AND NOT beta_enabled AND NOT prepared_enabled
  AND NOT generation_enabled AND approved_release='none';

DO $verify$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_members WHERE enabled)<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_members WHERE consent_at IS NOT NULL)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_control
     WHERE beta_enabled AND prepared_enabled AND NOT generation_enabled
     AND approved_release='app-nav-main-453127c3-v1')<>1
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_deliveries)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_usage)<>0
 THEN RAISE EXCEPTION 'Controlled beta launch postconditions failed'; END IF;
END $verify$;
