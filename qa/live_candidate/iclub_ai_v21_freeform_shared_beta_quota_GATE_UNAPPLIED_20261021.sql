-- QA candidate: shared 3-per-five-hours beta usage reservation, GENERATED=3.
-- Existing prepared(1) RPC stays byte-identical and still locks singleton row.
-- Requires separately installed $5 money control. No enablement on installation.
DO $guard$
BEGIN
 IF to_regclass('private.iclub_ai_v21_freeform_quota_holds') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_freeform_budget_control') IS NULL
 OR to_regclass('private.iclub_ai_v21_beta_usage') IS NULL
 OR NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 AND beta_enabled AND prepared_enabled AND NOT generation_enabled)
 THEN RAISE EXCEPTION 'Freeform quota adapter baseline drift'; END IF;
END $guard$;

CREATE TABLE private.iclub_ai_v21_freeform_quota_holds(
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 request_fingerprint text NOT NULL CHECK(request_fingerprint ~ '^[a-f0-9]{64}$'),
 period_started_at timestamptz NOT NULL,
 weight smallint NOT NULL CHECK(weight=3),
 state text NOT NULL CHECK(state IN('reserved','completed','released')),
 held_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 finished_at timestamptz,
 CHECK((state='reserved' AND finished_at IS NULL) OR
  (state<>'reserved' AND finished_at IS NOT NULL))
);
CREATE INDEX iclub_freeform_quota_owner_idx
 ON private.iclub_ai_v21_freeform_quota_holds(user_id,period_started_at,state);
ALTER TABLE private.iclub_ai_v21_freeform_quota_holds ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_freeform_quota_holds
 FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION public.reserve_iclub_ai_v21_freeform_quota_v1(
 p_request_id uuid,p_user_id uuid,p_request_fingerprint text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $quota$
DECLARE c private.iclub_ai_v21_beta_control%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 v_now timestamptz:=clock_timestamp();
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 THEN RETURN jsonb_build_object('allowed',false,'reason','invalid_quota_request'); END IF;
 -- Exact SAME lock order as existing prepared-Help RPC, so prepared(1)
 -- cannot arrive concurrently and overbook generated(3).
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none'
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id AND enabled AND consent_at IS NOT NULL
   AND consent_version='global_ai_beta_v21')
 THEN RETURN jsonb_build_object('allowed',false,'reason','beta_generation_disabled'); END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (SELECT 1 FROM public.practice_sessions_v4
 WHERE user_id=p_user_id AND status='in_progress')
 THEN RETURN jsonb_build_object('allowed',false,'reason','active_assessment'); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_quota_holds
   WHERE request_id=p_request_id)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_deliveries
   WHERE request_id=p_request_id)
 THEN RETURN jsonb_build_object('allowed',false,'reason','request_already_seen'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES(p_user_id,v_now,0) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
 WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at<=v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
  SET started_at=v_now,committed_count=0,updated_at=v_now
  WHERE user_id=p_user_id;
  u.started_at:=v_now;u.committed_count:=0;
 END IF;
 IF u.committed_count+3>3
 THEN RETURN jsonb_build_object('allowed',false,
   'reason','usage_exhausted','reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_freeform_quota_holds(
 request_id,user_id,request_fingerprint,period_started_at,weight,state)
 VALUES(p_request_id,p_user_id,p_request_fingerprint,u.started_at,3,'reserved');
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+3,updated_at=v_now WHERE user_id=p_user_id;
 RETURN jsonb_build_object('allowed',true,'weight',3);
END $quota$;

-- An error/no-source/denied provider output returns the reserved 3 units;
-- paid exposure remains independent and is never erased here.
CREATE FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(
 p_request_id uuid,p_user_id uuid,p_request_fingerprint text,p_outcome text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $quota$
DECLARE c private.iclub_ai_v21_beta_control%rowtype;
 h private.iclub_ai_v21_freeform_quota_holds%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
BEGIN
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
  WHERE singleton=1 FOR UPDATE;
 SELECT * INTO h FROM private.iclub_ai_v21_freeform_quota_holds
  WHERE request_id=p_request_id FOR UPDATE;
 IF h.request_id IS NULL OR h.user_id IS DISTINCT FROM p_user_id
 OR h.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR h.state<>'reserved' OR p_outcome NOT IN('completed','released')
 THEN RETURN jsonb_build_object('ok',false,'reason','quota_settlement_denied'); END IF;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF p_outcome='released' AND u.started_at=h.period_started_at THEN
  UPDATE private.iclub_ai_v21_beta_usage SET
  committed_count=greatest(0,committed_count-3),
  updated_at=clock_timestamp()
  WHERE user_id=p_user_id;
 END IF;
 UPDATE private.iclub_ai_v21_freeform_quota_holds SET
  state=p_outcome,finished_at=clock_timestamp()
 WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true,'state',p_outcome);
END $quota$;

REVOKE ALL ON FUNCTION public.reserve_iclub_ai_v21_freeform_quota_v1(
 uuid,uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(
 uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_iclub_ai_v21_freeform_quota_v1(
 uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(
 uuid,uuid,text,text) TO service_role;

DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_freeform_quota_holds)<>0
 OR (SELECT enabled FROM private.iclub_ai_v21_freeform_budget_control WHERE singleton=1)
 THEN RAISE EXCEPTION 'Quotas unexpectedly active on install'; END IF;
END $post$;
