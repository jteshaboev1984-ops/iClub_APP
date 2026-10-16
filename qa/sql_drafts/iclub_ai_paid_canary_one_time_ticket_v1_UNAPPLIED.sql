-- Isolated operator-only, short-lived single-use ticket for FIRST paid AI canary.
-- No keys or JWT service_role token need to enter Supabase Dashboard Test.
-- Zero learner reads, zero changes to existing app tables, no new public grants.
CREATE TABLE IF NOT EXISTS private.iclub_ai_paid_canary_tickets_v1 (
  request_id uuid PRIMARY KEY,
  token_sha256 bytea NOT NULL UNIQUE,
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  used_at timestamptz NULL,
  CHECK (expires_at <= issued_at + interval '10 minutes')
);
ALTER TABLE private.iclub_ai_paid_canary_tickets_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_paid_canary_tickets_v1
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.issue_iclub_ai_paid_canary_ticket_v1()
RETURNS TABLE (request_id uuid, ticket text)
LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = ''
AS $fn$
DECLARE
  t text := encode(extensions.gen_random_bytes(24), 'hex');
  r uuid := pg_catalog.gen_random_uuid();
BEGIN
  -- Only the DB operator in SQL Editor may issue a canary ticket.
  IF session_user <> 'postgres' THEN
    RAISE EXCEPTION 'operator_only';
  END IF;
  INSERT INTO private.iclub_ai_paid_canary_tickets_v1
    (request_id, token_sha256, expires_at)
  VALUES (r, extensions.digest(t, 'sha256'),
          now() + interval '10 minutes');
  RETURN QUERY SELECT r,t;
END;
$fn$;
REVOKE ALL ON FUNCTION private.issue_iclub_ai_paid_canary_ticket_v1()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.issue_iclub_ai_paid_canary_ticket_v1()
  TO postgres;

CREATE OR REPLACE FUNCTION public.claim_iclub_ai_paid_canary_ticket_v1(
 p_request_id uuid, p_ticket text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = ''
AS $claim$
BEGIN
  IF current_setting('request.jwt.claim.role',true)
    IS DISTINCT FROM 'service_role' THEN
    RETURN jsonb_build_object('allowed',false,'reason','operator_only');
  END IF;
  IF p_request_id IS NULL OR p_ticket IS NULL OR
     p_ticket !~ '^[0-9a-f]{48}$' THEN
    RETURN jsonb_build_object('allowed',false,'reason','invalid_ticket');
  END IF;
  UPDATE private.iclub_ai_paid_canary_tickets_v1
  SET used_at=now()
  WHERE request_id=p_request_id
    AND token_sha256=extensions.digest(p_ticket,'sha256')
    AND used_at IS NULL
    AND expires_at>now();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('allowed',false,'reason','invalid_or_used_ticket');
  END IF;
  RETURN jsonb_build_object('allowed',true);
END;
$claim$;
REVOKE ALL ON FUNCTION public.claim_iclub_ai_paid_canary_ticket_v1(uuid,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_iclub_ai_paid_canary_ticket_v1(uuid,text)
  TO service_role;
