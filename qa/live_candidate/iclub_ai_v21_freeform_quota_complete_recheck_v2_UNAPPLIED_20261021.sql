-- Safe incremental v2 completion guard for newly installed Free beta quota.
-- The previous function is already in production; do not alter historical SQL.
-- No learner writes during installation. Replaces only the NEW beta function.
DO $scope$ BEGIN
 IF to_regclass('private.iclub_ai_v21_freeform_quota_holds') IS NULL
 OR to_regclass('private.iclub_ai_v21_freeform_budget_ledger') IS NULL
 OR to_regprocedure('public.finish_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text,text)') IS NULL
 THEN RAISE EXCEPTION 'Freeform v2 completion guard missing current admission objects'; END IF;
END $scope$;

CREATE OR REPLACE FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(
 p_request_id uuid,p_user_id uuid,p_request_fingerprint text,p_outcome text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $quota$
DECLARE h private.iclub_ai_v21_freeform_quota_holds%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 final_state text:=p_outcome;
 denied boolean:=false;
BEGIN
 PERFORM 1 FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 FOR UPDATE;
 SELECT * INTO h FROM private.iclub_ai_v21_freeform_quota_holds
  WHERE request_id=p_request_id FOR UPDATE;
 IF h.request_id IS NULL OR h.user_id IS DISTINCT FROM p_user_id
 OR h.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR h.state<>'reserved' OR p_outcome NOT IN('completed','released')
 THEN RETURN jsonb_build_object('ok',false,'reason','quota_settlement_denied'); END IF;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
 WHERE user_id=p_user_id FOR UPDATE;
 IF p_outcome='completed' AND (
  NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
   WHERE user_id=p_user_id AND enabled
   AND consent_version='global_ai_beta_v21' AND consent_at IS NOT NULL)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled
    AND NOT generation_enabled AND approved_release<>'none')
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND enabled AND owner_permitted)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger
   WHERE request_id=p_request_id AND user_id=p_user_id
   AND request_fingerprint=p_request_fingerprint AND state='charged')
  OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
  OR EXISTS(SELECT 1 FROM public.practice_sessions_v4
   WHERE user_id=p_user_id AND status='in_progress')
 ) THEN
  -- A charged provider response is still a real cost, but a revoked/blocked
  -- user must NOT receive or pay learner units for the model explanation.
  final_state:='released';denied:=true;
 END IF;
 IF final_state='released' AND u.started_at=h.period_started_at THEN
  UPDATE private.iclub_ai_v21_beta_usage SET
   committed_count=greatest(0,committed_count-3),
   updated_at=clock_timestamp()
  WHERE user_id=p_user_id;
 END IF;
 UPDATE private.iclub_ai_v21_freeform_quota_holds
 SET state=final_state,finished_at=clock_timestamp()
 WHERE request_id=p_request_id;
 IF denied THEN
  RETURN jsonb_build_object('ok',false,'released',true,
   'reason','generation_no_longer_authorized');
 END IF;
 RETURN jsonb_build_object('ok',true,'state',final_state);
END $quota$;
REVOKE ALL ON FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(
 uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(
 uuid,uuid,text,text) TO service_role;
