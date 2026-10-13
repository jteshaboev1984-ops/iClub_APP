-- iClub AI Layer v2.1: cross-worker claim/tombstone WITHOUT transcripts.
-- STRICTLY UNAPPLIED QA SQL, not under supabase/migrations.
-- A claim is not permission to call a provider. JWT+source+cohort+
-- protected-assessment checks and v2 quota reservation are separate.
-- No learner answers, raw prompts, provider replies or payment details stored.
DO $scratch$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL AND
   inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
   AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
    AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
  RAISE EXCEPTION 'BLOCKED: AI delivery claim is scratch-only';
 END IF;
END $scratch$;

CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE private.iclub_ai_request_tombstones_v21(
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 -- Hash of request-owned server session (not raw handle).
 session_fingerprint text NOT NULL CHECK(session_fingerprint ~ '^[0-9a-f]{64}$'),
 -- Identical to the immutable v2 quota reservation fingerprint.
 request_fingerprint text NOT NULL CHECK(request_fingerprint ~ '^[0-9a-f]{64}$'),
 route_class text NOT NULL CHECK(route_class IN ('prepared','generated')),
 status text NOT NULL DEFAULT 'claimed'
   CHECK(status IN ('claimed','completed','released')),
 claimed_at timestamptz NOT NULL DEFAULT now(),
 claim_expires_at timestamptz NOT NULL DEFAULT (now()+interval '90 seconds'),
 finished_at timestamptz,
 CHECK (finished_at IS NULL OR status<>'claimed')
);
REVOKE ALL ON TABLE private.iclub_ai_request_tombstones_v21 FROM public,anon,authenticated;
GRANT SELECT ON TABLE private.iclub_ai_request_tombstones_v21 TO service_role;

-- Atomic first-writer wins claim. Never reclaim an expired request ID:
-- a late provider reply may exist and retrying it could double-charge provider.
CREATE OR REPLACE FUNCTION public.claim_iclub_ai_delivery_service_v21(
 p_request_id uuid,p_user_id uuid,p_session_fingerprint text,
 p_request_fingerprint text,p_route_class text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 SET search_path='' AS $$
DECLARE v private.iclub_ai_request_tombstones_v21%rowtype;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
   OR p_session_fingerprint !~ '^[0-9a-f]{64}$'
   OR p_request_fingerprint !~ '^[0-9a-f]{64}$'
   OR p_session_fingerprint IS NULL OR p_request_fingerprint IS NULL
   OR p_route_class NOT IN ('prepared','generated') OR p_route_class IS NULL THEN
  RETURN jsonb_build_object('allowed',false,'reason','invalid_identity');
 END IF;
 -- The caller must have reserved new v2 quota BEFORE claiming delivery.
 -- Another request using the same ID or mismatched route cannot enter provider.
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_usage_reservations r
  WHERE r.request_id=p_request_id AND r.user_id=p_user_id
    AND r.request_fingerprint=p_request_fingerprint
    AND r.route_class=p_route_class AND r.status='reserved'
    AND r.expires_at>now()
 ) THEN
  RETURN jsonb_build_object('allowed',false,'reason','quota_reservation_unverified');
 END IF;
 INSERT INTO private.iclub_ai_request_tombstones_v21
   (request_id,user_id,session_fingerprint,request_fingerprint,route_class)
 VALUES (p_request_id,p_user_id,p_session_fingerprint,p_request_fingerprint,p_route_class)
 ON CONFLICT(request_id) DO NOTHING;
 IF FOUND THEN
  RETURN jsonb_build_object('allowed',true,'reason',null,'status','claimed');
 END IF;
 SELECT * INTO v FROM private.iclub_ai_request_tombstones_v21
 WHERE request_id=p_request_id;
 IF v.user_id IS DISTINCT FROM p_user_id
  OR v.session_fingerprint IS DISTINCT FROM p_session_fingerprint
  OR v.request_fingerprint IS DISTINCT FROM p_request_fingerprint
  OR v.route_class IS DISTINCT FROM p_route_class THEN
  RETURN jsonb_build_object('allowed',false,'reason','request_identity_mismatch');
 END IF;
 -- Same request MUST NOT be sent to provider again, even after TTL/worker restart.
 RETURN jsonb_build_object('allowed',false,
   'reason',CASE WHEN v.status='claimed' THEN 'request_in_progress'
      WHEN v.status='completed' THEN 'already_processed_no_receipt'
      ELSE 'request_already_released' END,'duplicate',true);
END;
$$;

-- Mark complete ONLY AFTER atomic usage_v2 finalization. The exact same
-- fingerprint, learner, session and route must match both durable ledgers.
CREATE OR REPLACE FUNCTION public.finish_iclub_ai_delivery_service_v21(
 p_request_id uuid,p_user_id uuid,p_session_fingerprint text,
 p_request_fingerprint text,p_route_class text,p_outcome text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 SET search_path='' AS $$
DECLARE
 v private.iclub_ai_request_tombstones_v21%rowtype;
 v_quota_status text;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
   OR p_session_fingerprint IS NULL OR p_session_fingerprint !~ '^[0-9a-f]{64}$'
   OR p_request_fingerprint IS NULL OR p_request_fingerprint !~ '^[0-9a-f]{64}$'
   OR p_route_class IS NULL OR p_route_class NOT IN ('prepared','generated')
   OR p_outcome IS NULL OR p_outcome NOT IN ('completed','released') THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_identity');
 END IF;
 SELECT * INTO v FROM private.iclub_ai_request_tombstones_v21
  WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'reason','claim_missing'); END IF;
 IF v.user_id IS DISTINCT FROM p_user_id
    OR v.session_fingerprint IS DISTINCT FROM p_session_fingerprint
    OR v.request_fingerprint IS DISTINCT FROM p_request_fingerprint
    OR v.route_class IS DISTINCT FROM p_route_class THEN
  RETURN jsonb_build_object('ok',false,'reason','request_identity_mismatch');
 END IF;
 IF v.status<>'claimed' THEN
   RETURN jsonb_build_object('ok',v.status=p_outcome,
       'reason',CASE WHEN v.status=p_outcome THEN null ELSE 'outcome_conflict' END,
       'duplicate',true,'status',v.status);
 END IF;
 IF v.claim_expires_at<=now() AND p_outcome='completed' THEN
  RETURN jsonb_build_object('ok',false,'reason','claim_expired');
 END IF;
 SELECT r.status INTO v_quota_status FROM private.iclub_ai_usage_reservations r
 WHERE r.request_id=p_request_id AND r.user_id=p_user_id
   AND r.request_fingerprint=p_request_fingerprint AND r.route_class=p_route_class
 FOR UPDATE;
 IF v_quota_status IS DISTINCT FROM p_outcome THEN
  RETURN jsonb_build_object('ok',false,'reason','quota_not_finalized');
 END IF;
 UPDATE private.iclub_ai_request_tombstones_v21
  SET status=p_outcome,finished_at=now() WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true,'status',p_outcome,'duplicate',false);
END;
$$;
REVOKE ALL ON FUNCTION public.claim_iclub_ai_delivery_service_v21(uuid,uuid,text,text,text)
  FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.claim_iclub_ai_delivery_service_v21(uuid,uuid,text,text,text)
  TO service_role;
REVOKE ALL ON FUNCTION public.finish_iclub_ai_delivery_service_v21(uuid,uuid,text,text,text,text)
  FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.finish_iclub_ai_delivery_service_v21(uuid,uuid,text,text,text,text)
  TO service_role;

-- Deliberately no deletion/TTL clean-up worker or reply cache. A tombstone
-- must outlive any possibility of repeated provider execution. Any retention
-- schedule requires later architect approval and a safety proof.
