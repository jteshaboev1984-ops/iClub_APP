-- iClub AI v2.1 / P8 authority. QA-only / UNAPPLIED.
-- The v1 runtime, rollout, protected exam, subject-access and subscription
-- functions are read-only authorities. NEVER modify them from this draft.
-- No real tariff, learner, academic, checkout or Exam Prep writes.
DO $scratch$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
  AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
  AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
   AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
  RAISE EXCEPTION 'BLOCKED: v21 runtime authority only in local scratch';
 END IF;
END $scratch$;

-- This is an INDEPENDENT owner release permission, not an alternate
-- entitlement/subject/rollout table. No seed means explicit DENIAL.
-- Real identity, release administration and migration require owner approval.
CREATE TABLE private.iclub_ai_v21_release_control(
 id smallint PRIMARY KEY CHECK (id=1),
 release_approved boolean NOT NULL DEFAULT false,
 release_reference text,
 approved_at timestamptz
);
REVOKE ALL ON TABLE private.iclub_ai_v21_release_control
 FROM PUBLIC,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_runtime_service()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $runtime$
DECLARE
 r private.iclub_global_ai_runtime_config%rowtype;
 a private.iclub_ai_v21_release_control%rowtype;
BEGIN
 SELECT * INTO r FROM private.iclub_global_ai_runtime_config WHERE id=1;
 SELECT * INTO a FROM private.iclub_ai_v21_release_control WHERE id=1;
 RETURN jsonb_build_object(
  'ui_enabled',coalesce(r.ui_enabled,false),
  'gateway_enabled',coalesce(r.gateway_enabled,false),
  'kill_switch',coalesce(r.kill_switch,true),
  'release_approved',coalesce(a.release_approved,false));
END $runtime$;

CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_protected_service(
 p_user_id uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $protected$
BEGIN
 IF p_user_id IS NULL THEN
  RETURN jsonb_build_object('protected',true);
 END IF;
 RETURN jsonb_build_object('protected',
  coalesce(private.iclub_ai_has_active_protected_assessment_v1(p_user_id),true));
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('protected',true);
END $protected$;

-- v1 uses subject-wide 'full' for academic content. v2's approved topic
-- release is intentionally a SEPARATE, stricter source/locale gate.
-- Reuse v1 rollout + v1 subject-opening guard, never invent a new cohort,
-- and require real subject enrollment even in v1 legacy/shadow mode.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_rollout_service(
 p_user_id uuid,p_surface text,p_subject text,p_feature text,p_topic text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $rollout$
DECLARE
 r private.iclub_global_ai_runtime_config%rowtype;
 a private.iclub_ai_v21_release_control%rowtype;
 v_access jsonb;
BEGIN
 IF p_user_id IS NULL OR p_subject IS NULL
 OR p_subject !~ '^[a-z][a-z0-9_]{1,79}$'
 OR NOT (
  (p_surface='lesson' AND p_feature='topic_explanation'
   AND p_topic ~ '^lesson_[1-9][0-9]{0,17}$')
  OR
  (p_surface='practice' AND p_feature='answer_explanation'
   AND p_topic ~ '^question_[1-9][0-9]{0,17}$')
 ) THEN RETURN jsonb_build_object('allowed',false);END IF;
 SELECT * INTO r FROM private.iclub_global_ai_runtime_config WHERE id=1;
 SELECT * INTO a FROM private.iclub_ai_v21_release_control WHERE id=1;
 IF NOT coalesce(r.ui_enabled,false)
 OR NOT coalesce(r.gateway_enabled,false)
 OR coalesce(r.kill_switch,true)
 OR NOT coalesce(a.release_approved,false)
 OR NOT coalesce(private.iclub_rollout_allows_user_v1(
    p_user_id,r.global_ai_rollout_mode),false)
 OR coalesce(private.iclub_ai_has_active_protected_assessment_v1(p_user_id),true)
 THEN RETURN jsonb_build_object('allowed',false);END IF;

 IF NOT EXISTS(
  SELECT 1 FROM public.user_subjects us
   JOIN public.subjects s ON s.id=us.subject_id
  WHERE us.user_id=p_user_id AND s.subject_key=p_subject AND s.is_active
 ) THEN RETURN jsonb_build_object('allowed',false);END IF;
 v_access:=public.get_iclub_subject_access_guard_service_v1(
  p_user_id,p_subject,'open');
 IF v_access->>'allowed' IS DISTINCT FROM 'true' THEN
  RETURN jsonb_build_object('allowed',false);
 END IF;
 RETURN jsonb_build_object('allowed',true);
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('allowed',false);
END $rollout$;

-- Temporary QA meter policies only; the existing subscription service
-- remains the authority. The v2 policy mapping changes NO commercial plan.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_entitlement_service(
 p_user_id uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $entitlement$
DECLARE
 c jsonb;
 v_plan text;
 v_policy text;
 r private.iclub_global_ai_runtime_config%rowtype;
 a private.iclub_ai_v21_release_control%rowtype;
BEGIN
 IF p_user_id IS NULL THEN
  RETURN jsonb_build_object('allowed',false);END IF;
 SELECT * INTO r FROM private.iclub_global_ai_runtime_config WHERE id=1;
 SELECT * INTO a FROM private.iclub_ai_v21_release_control WHERE id=1;
 IF NOT coalesce(r.ui_enabled,false)
 OR NOT coalesce(r.gateway_enabled,false)
 OR coalesce(r.kill_switch,true)
 OR NOT coalesce(a.release_approved,false)
 OR coalesce(private.iclub_ai_has_active_protected_assessment_v1(p_user_id),true)
 THEN RETURN jsonb_build_object('allowed',false);END IF;
 c:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);
 IF c->>'resolved' IS DISTINCT FROM 'true' THEN
  RETURN jsonb_build_object('allowed',false);END IF;
 v_plan:=lower(coalesce(c->>'plan_code',''));
 v_policy:=CASE v_plan
  WHEN 'free' THEN 'free_qa_v2'
  WHEN 'plus' THEN 'plus_qa_v2'
  WHEN 'pro' THEN 'pro_qa_v2'
  ELSE NULL END;
 IF v_policy IS NULL OR
  (v_plan IN ('plus','pro') AND
   c->>'ai_generation_entitled' IS DISTINCT FROM 'true') THEN
  RETURN jsonb_build_object('allowed',false);END IF;
 RETURN jsonb_build_object('allowed',true,'usage_policy_code',v_policy);
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('allowed',false);
END $entitlement$;

-- Budget enforcement MUST be atomic before real model use. Existing Math
-- provider leases are NOT global AI money. Until P8 budget ledger + grants
-- have passed separate tests, fail closed for every generated request.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_provider_budget_service(
 p_user_id uuid,p_source_id text,p_route_class text
) RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $budget$
 SELECT jsonb_build_object('allowed',false,'reason','provider_budget_not_authorized')
$budget$;

REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_runtime_service()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_protected_service(uuid)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_rollout_service(uuid,text,text,text,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_entitlement_service(uuid)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_provider_budget_service(uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_runtime_service()
 TO service_role;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_protected_service(uuid)
 TO service_role;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_rollout_service(uuid,text,text,text,text)
 TO service_role;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_entitlement_service(uuid)
 TO service_role;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_provider_budget_service(uuid,text,text)
 TO service_role;
