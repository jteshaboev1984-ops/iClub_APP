-- Global iClub AI v2.1 §33. Monetary exposure ledger (micro USD).
-- UNAPPLIED. ABSOLUTELY SCRATCH-ONLY. Synthetic money caps are NOT prices.
-- No real provider keys, payments, pupils, academic writes or live rollout.
DO $scratch$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
  AND inet_server_addr() NOT IN('127.0.0.1'::inet,'::1'::inet)
  AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
   AND current_setting('application_name')='iclub_ai_v21_local_scratch'))
 THEN RAISE EXCEPTION 'BLOCKED: provider monetary ledger only in local scratch';
 END IF;
END $scratch$;

CREATE TABLE private.iclub_ai_v21_provider_spend_control(
 singleton smallint PRIMARY KEY CHECK(singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 lifetime_cap_microusd bigint NOT NULL DEFAULT 0 CHECK(lifetime_cap_microusd>=0),
 per_request_ceiling_microusd bigint NOT NULL DEFAULT 0
  CHECK(per_request_ceiling_microusd>=0),
 policy_revision text NOT NULL DEFAULT 'not_approved',
 CHECK(per_request_ceiling_microusd<=lifetime_cap_microusd)
);
REVOKE ALL ON TABLE private.iclub_ai_v21_provider_spend_control
 FROM PUBLIC,anon,authenticated,service_role;
-- No INSERT/UPDATE RPC: independent finance governance must approve a
-- fixed price/token worst-case ceiling before this control can be enabled.

CREATE TABLE private.iclub_ai_v21_provider_spend_leases(
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 session_fingerprint text NOT NULL CHECK(session_fingerprint~'^[a-f0-9]{64}$'),
 request_fingerprint text NOT NULL CHECK(request_fingerprint~'^[a-f0-9]{64}$'),
 state text NOT NULL DEFAULT 'reserved'
  CHECK(state IN('reserved','dispatched','charged','unknown','no_charge')),
 held_microusd bigint NOT NULL CHECK(held_microusd>0),
 actual_microusd bigint CHECK(actual_microusd>=0),
 policy_revision text NOT NULL,
 reserved_at timestamptz NOT NULL DEFAULT now(),
 dispatched_at timestamptz,
 finished_at timestamptz,
 CHECK(actual_microusd IS NULL OR actual_microusd<=held_microusd),
 CHECK((state='charged' AND actual_microusd IS NOT NULL)
  OR (state<>'charged' AND actual_microusd IS NULL))
);
REVOKE ALL ON TABLE private.iclub_ai_v21_provider_spend_leases
 FROM PUBLIC,anon,authenticated,service_role;

-- Lifetime cap: the ledger retains all reservations/tombstones, including
-- ambiguous provider timeouts. No automatic reset/delete/reclaim.
-- A pending/dispatched/unknown amount counts its FULL worst-case ceiling.
-- Precisely billed calls count actual cost; definitely uncalled count zero.
CREATE OR REPLACE FUNCTION public.reserve_iclub_ai_v21_provider_spend_service(
 p_request_id uuid,p_user_id uuid,
 p_session_fingerprint text,p_request_fingerprint text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $reserve$
DECLARE
 c private.iclub_ai_v21_provider_spend_control%rowtype;
 e private.iclub_ai_v21_provider_spend_leases%rowtype;
 r private.iclub_global_ai_runtime_config%rowtype;
 a private.iclub_ai_v21_release_control%rowtype;
 used_microusd bigint;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_session_fingerprint IS NULL OR p_session_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_request_fingerprint IS NULL OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 THEN RETURN jsonb_build_object('allowed',false,'reason','invalid_identity'); END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_ai_v21_provider_money',32767));
 SELECT * INTO e FROM private.iclub_ai_v21_provider_spend_leases
 WHERE request_id=p_request_id FOR UPDATE;
 IF FOUND THEN
  RETURN jsonb_build_object('allowed',false,'reason',
   CASE WHEN e.user_id IS DISTINCT FROM p_user_id
     OR e.session_fingerprint IS DISTINCT FROM p_session_fingerprint
     OR e.request_fingerprint IS DISTINCT FROM p_request_fingerprint
   THEN 'request_identity_mismatch' ELSE 'provider_request_already_seen' END);
 END IF;
 SELECT * INTO c FROM private.iclub_ai_v21_provider_spend_control
 WHERE singleton=1 FOR UPDATE;
 SELECT * INTO r FROM private.iclub_global_ai_runtime_config WHERE id=1;
 SELECT * INTO a FROM private.iclub_ai_v21_release_control WHERE id=1;
 IF NOT coalesce(c.enabled,false)
 OR coalesce(c.lifetime_cap_microusd,0)<=0
 OR coalesce(c.per_request_ceiling_microusd,0)<=0
 OR NOT coalesce(a.release_approved,false)
 OR NOT coalesce(r.gateway_enabled,false)
 OR NOT coalesce(r.generation_enabled,false)
 OR coalesce(r.kill_switch,true)
 OR coalesce(private.iclub_ai_has_active_protected_assessment_v1(p_user_id),true)
 THEN RETURN jsonb_build_object('allowed',false,'reason','provider_not_authorized');END IF;
 -- A learner quota reservation AND first-writer delivery claim must precede
 -- this money reservation. Never use the existing Mathematics money leases.
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_usage_reservations q
   JOIN private.iclub_ai_request_tombstones_v21 d
     ON d.request_id=q.request_id AND d.user_id=q.user_id
  WHERE q.request_id=p_request_id AND q.user_id=p_user_id
    AND q.request_fingerprint=p_request_fingerprint AND q.route_class='generated'
    AND q.status='reserved' AND q.expires_at>now()
    AND d.status='claimed' AND d.claim_expires_at>now()
    AND d.session_fingerprint=p_session_fingerprint
    AND d.request_fingerprint=p_request_fingerprint
    AND d.route_class='generated'
 ) THEN RETURN jsonb_build_object('allowed',false,'reason','request_claim_unverified');END IF;
 SELECT coalesce(sum(CASE WHEN state='charged' THEN actual_microusd
    WHEN state='no_charge' THEN 0 ELSE held_microusd END),0)::bigint
 INTO used_microusd FROM private.iclub_ai_v21_provider_spend_leases;
 IF used_microusd>c.lifetime_cap_microusd-c.per_request_ceiling_microusd THEN
  RETURN jsonb_build_object('allowed',false,'reason','provider_budget_insufficient');
 END IF;
 INSERT INTO private.iclub_ai_v21_provider_spend_leases(
  request_id,user_id,session_fingerprint,request_fingerprint,
  held_microusd,policy_revision)
 VALUES(p_request_id,p_user_id,p_session_fingerprint,p_request_fingerprint,
  c.per_request_ceiling_microusd,c.policy_revision);
 RETURN jsonb_build_object('allowed',true,'reason',null);
EXCEPTION WHEN OTHERS THEN
 -- Never leak credentials, SQL errors or private billing values.
 RETURN jsonb_build_object('allowed',false,'reason','provider_budget_unavailable');
END;
$reserve$;

-- This is the LAST atomic gate before the model is contacted.
-- It cannot be replayed to obtain a second provider dispatch.
CREATE OR REPLACE FUNCTION public.dispatch_iclub_ai_v21_provider_spend_service(
 p_request_id uuid,p_user_id uuid,
 p_session_fingerprint text,p_request_fingerprint text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $dispatch$
DECLARE
 e private.iclub_ai_v21_provider_spend_leases%rowtype;
 r private.iclub_global_ai_runtime_config%rowtype;
 a private.iclub_ai_v21_release_control%rowtype;
 c private.iclub_ai_v21_provider_spend_control%rowtype;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_session_fingerprint IS NULL OR p_session_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_request_fingerprint IS NULL OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 THEN RETURN jsonb_build_object('allowed',false,'reason','invalid_identity');END IF;
 SELECT * INTO e FROM private.iclub_ai_v21_provider_spend_leases
  WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND OR e.user_id IS DISTINCT FROM p_user_id
 OR e.session_fingerprint IS DISTINCT FROM p_session_fingerprint
 OR e.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR e.state<>'reserved'
 THEN RETURN jsonb_build_object('allowed',false,'reason','dispatch_unavailable');END IF;
 SELECT * INTO c FROM private.iclub_ai_v21_provider_spend_control WHERE singleton=1;
 SELECT * INTO r FROM private.iclub_global_ai_runtime_config WHERE id=1;
 SELECT * INTO a FROM private.iclub_ai_v21_release_control WHERE id=1;
 IF NOT coalesce(c.enabled,false)
 OR NOT coalesce(a.release_approved,false)
 OR coalesce(r.kill_switch,true)
 OR NOT coalesce(r.gateway_enabled,false)
 OR NOT coalesce(r.generation_enabled,false)
 OR coalesce(private.iclub_ai_has_active_protected_assessment_v1(p_user_id),true)
 THEN RETURN jsonb_build_object('allowed',false,'reason','dispatch_not_authorized');END IF;
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_usage_reservations q
   JOIN private.iclub_ai_request_tombstones_v21 d
     ON q.request_id=d.request_id AND q.user_id=d.user_id
  WHERE q.request_id=p_request_id AND q.user_id=p_user_id
   AND q.status='reserved' AND q.expires_at>now()
   AND q.route_class='generated' AND q.request_fingerprint=p_request_fingerprint
   AND d.status='claimed' AND d.claim_expires_at>now()
   AND d.session_fingerprint=p_session_fingerprint
   AND d.request_fingerprint=p_request_fingerprint
 ) THEN RETURN jsonb_build_object('allowed',false,'reason','request_claim_unverified');END IF;
 UPDATE private.iclub_ai_v21_provider_spend_leases
 SET state='dispatched',dispatched_at=now() WHERE request_id=p_request_id;
 RETURN jsonb_build_object('allowed',true);
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('allowed',false,'reason','dispatch_unavailable');
END;
$dispatch$;

-- Release only a lease that was NEVER dispatched. Once dispatched,
-- provider timeout/cancellation/unknown bill retains its FULL cost ceiling.
CREATE OR REPLACE FUNCTION public.finish_iclub_ai_v21_provider_spend_service(
 p_request_id uuid,p_user_id uuid,p_session_fingerprint text,
 p_request_fingerprint text,p_outcome text,p_actual_microusd bigint DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $finish$
DECLARE e private.iclub_ai_v21_provider_spend_leases%rowtype;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_session_fingerprint IS NULL OR p_session_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_request_fingerprint IS NULL OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_outcome IS NULL OR p_outcome NOT IN ('no_charge','charged','unknown')
 THEN RETURN jsonb_build_object('ok',false,'reason','invalid_identity'); END IF;
 SELECT * INTO e FROM private.iclub_ai_v21_provider_spend_leases
  WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND OR e.user_id IS DISTINCT FROM p_user_id
 OR e.session_fingerprint IS DISTINCT FROM p_session_fingerprint
 OR e.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 THEN RETURN jsonb_build_object('ok',false,'reason','lease_unavailable'); END IF;
 IF e.state IN ('charged','unknown','no_charge') THEN
  RETURN jsonb_build_object('ok',e.state=p_outcome
   AND (e.state<>'charged' OR e.actual_microusd IS NOT DISTINCT FROM p_actual_microusd),
   'reason',CASE WHEN e.state=p_outcome THEN 'already_settled'
    ELSE 'outcome_conflict' END,'duplicate',true);
 END IF;
 IF (p_outcome='no_charge' AND e.state<>'reserved')
 OR (p_outcome IN ('charged','unknown') AND e.state<>'dispatched')
 OR (p_outcome='charged' AND (p_actual_microusd IS NULL
    OR p_actual_microusd<0 OR p_actual_microusd>e.held_microusd))
 OR (p_outcome<>'charged' AND p_actual_microusd IS NOT NULL)
 THEN RETURN jsonb_build_object('ok',false,'reason','unsafe_settlement'); END IF;
 UPDATE private.iclub_ai_v21_provider_spend_leases SET
  state=p_outcome,
  actual_microusd=CASE WHEN p_outcome='charged' THEN p_actual_microusd ELSE NULL END,
  finished_at=now()
 WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true,'duplicate',false);
END;
$finish$;

REVOKE ALL ON FUNCTION public.reserve_iclub_ai_v21_provider_spend_service(uuid,uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_iclub_ai_v21_provider_spend_service(uuid,uuid,text,text)
 TO service_role;
REVOKE ALL ON FUNCTION public.dispatch_iclub_ai_v21_provider_spend_service(uuid,uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.dispatch_iclub_ai_v21_provider_spend_service(uuid,uuid,text,text)
 TO service_role;
REVOKE ALL ON FUNCTION public.finish_iclub_ai_v21_provider_spend_service(uuid,uuid,text,text,text,bigint)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.finish_iclub_ai_v21_provider_spend_service(uuid,uuid,text,text,text,bigint)
 TO service_role;
-- No delete, reset, mutation-to-allow, or public budget configuration RPC.
