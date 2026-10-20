-- iClub AI v2.1: ADDITIVE beta candidate staging + separate Global AI consent.
-- No existing Math, auth, academic, fee, production AI or progress mutation.
DO $preflight$
DECLARE v_count integer;
BEGIN
 IF to_regprocedure('public.iclub_ai_v21_beta_opt_in_service_v1(text)') IS NOT NULL
 OR to_regprocedure('public.get_iclub_ai_v21_beta_status_service(uuid)') IS NOT NULL
 THEN RAISE EXCEPTION 'Beta opt-in/status RPC already installed'; END IF;
 SELECT count(DISTINCT q.user_id) INTO v_count
 FROM private.iclub_ai_qa_global_operator_v1 q
 JOIN private.exam_prep_beta_members m ON m.user_id=q.user_id
 JOIN private.exam_prep_feature_entitlements e ON e.user_id=q.user_id
 WHERE q.enabled=false AND m.member_status='active'
 AND m.service_mode='ai_assist'
 AND e.entitlement_status='active' AND e.ai_assist=true
 AND e.core_access=true AND e.cohort_key='math_as_p1_p5_beta_2026_09_01'
 AND (e.valid_from IS NULL OR e.valid_from<=now())
 AND (e.valid_until IS NULL OR e.valid_until>now());
 IF v_count<>3 THEN
  RAISE EXCEPTION 'Expected exactly 3 existing eligible Math beta candidates, found %',v_count;
 END IF;
END $preflight$;

-- Identity selectors originate from existing, already-disabled QA candidates.
-- These 3 new records do not grant access and do not mark Global AI consent.
INSERT INTO private.iclub_ai_v21_beta_members(
 user_id,enabled,consent_version,consent_at
)
SELECT DISTINCT q.user_id,false,NULL,NULL
FROM private.iclub_ai_qa_global_operator_v1 q
JOIN private.exam_prep_beta_members m ON m.user_id=q.user_id
JOIN private.exam_prep_feature_entitlements e ON e.user_id=q.user_id
WHERE q.enabled=false AND m.member_status='active'
AND m.service_mode='ai_assist' AND e.entitlement_status='active'
AND e.ai_assist=true AND e.core_access=true
AND e.cohort_key='math_as_p1_p5_beta_2026_09_01'
AND (e.valid_from IS NULL OR e.valid_from<=now())
AND (e.valid_until IS NULL OR e.valid_until>now())
ON CONFLICT (user_id) DO NOTHING;

DO $checked$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_beta_members)<>3 OR
    EXISTS (SELECT 1 FROM private.iclub_ai_v21_beta_members
            WHERE enabled OR consent_version IS NOT NULL OR consent_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Global beta must contain exactly three DISABLED unconsented candidates'; END IF;
END $checked$;

-- The learner's own current signed JWT is the sole identity authority.
-- The explicit button is a distinct opt-in; Math consent is NEVER reused.
CREATE FUNCTION public.iclub_ai_v21_beta_opt_in_service_v1(
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
 WHERE user_id=v_uid AND enabled=false AND consent_at IS NULL;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'recorded',true); END IF;
 RETURN jsonb_build_object('ok',false,'reason','not_eligible_or_already_recorded');
END $consent$;
REVOKE ALL ON FUNCTION public.iclub_ai_v21_beta_opt_in_service_v1(text)
 FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.iclub_ai_v21_beta_opt_in_service_v1(text)
 TO authenticated;

-- Read-only status; still invisible without approved sources and release.
-- This RPC never returns user IDs, progress, answers or a financial switch.
CREATE FUNCTION public.get_iclub_ai_v21_beta_status_service(
 p_user_id uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $status$
DECLARE
 m private.iclub_ai_v21_beta_members%rowtype;
 c private.iclub_ai_v21_beta_control%rowtype;
 protected boolean:=true;
 ready boolean:=false;
BEGIN
 IF p_user_id IS NULL THEN
  RETURN jsonb_build_object('ok',true,'candidate',false,'consented',false,
     'eligible',false,'preparedOnly',true); END IF;
 SELECT * INTO m FROM private.iclub_ai_v21_beta_members
 WHERE user_id=p_user_id;
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control WHERE singleton=1;
 BEGIN
  protected:=private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
  OR EXISTS (SELECT 1 FROM public.practice_sessions_v4
   WHERE user_id=p_user_id AND status='in_progress');
 EXCEPTION WHEN OTHERS THEN protected:=true;
 END;
 SELECT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_beta_help_sources
  WHERE published AND NOT revoked AND rights_reviewed
  AND content_reviewed AND locale_reviewed AND approved_at IS NOT NULL
 ) INTO ready;
 RETURN jsonb_build_object('ok',true,
  'candidate',m.user_id IS NOT NULL,
  'consented',coalesce(m.consent_version='global_ai_beta_v21'
   AND m.consent_at IS NOT NULL,false),
  'eligible',coalesce(c.beta_enabled,false)
   AND coalesce(c.prepared_enabled,false)
   AND NOT coalesce(c.generation_enabled,true)
   AND coalesce(c.approved_release,'none')<>'none'
   AND coalesce(m.enabled,false)
   AND m.consent_version='global_ai_beta_v21'
   AND m.consent_at IS NOT NULL
   AND NOT protected AND ready,
  'preparedOnly',true);
END $status$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_beta_status_service(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_beta_status_service(uuid)
 TO service_role;
