-- iClub AI §34. ENCRYPTED short-lived delivery receipt / UNAPPLIED QA.
-- Run on empty local scratch only. PostgreSQL NEVER sees encryption keys or
-- unencrypted prompts, responses, model output or real user data.
DO $scratch$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
  AND inet_server_addr() NOT IN('127.0.0.1'::inet,'::1'::inet)
  AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
   AND current_setting('application_name')='iclub_ai_v21_local_scratch'))
 THEN RAISE EXCEPTION 'STOP: encrypted receipt is local scratch only';END IF;
END $scratch$;
CREATE TABLE private.iclub_ai_v21_encrypted_reply_receipts(
 request_id uuid PRIMARY KEY
  REFERENCES private.iclub_ai_request_tombstones_v21(request_id),
 user_id uuid NOT NULL,
 session_fingerprint text NOT NULL CHECK(session_fingerprint~'^[a-f0-9]{64}$'),
 request_fingerprint text NOT NULL CHECK(request_fingerprint~'^[a-f0-9]{64}$'),
 route_class text NOT NULL CHECK(route_class IN('prepared','generated')),
 identity_digest text NOT NULL CHECK(identity_digest~'^[a-f0-9]{64}$'),
 ciphertext text NOT NULL CHECK((length(ciphertext) BETWEEN 20 AND 11000 AND ciphertext~'^[A-Za-z0-9_-]+$')),
 nonce text NOT NULL CHECK(nonce~'^[A-Za-z0-9_-]{16}$'),
 auth_tag text NOT NULL CHECK(auth_tag~'^[A-Za-z0-9_-]{22}$'),
 key_ref text NOT NULL CHECK(key_ref~'^[A-Za-z0-9_-]{6,80}$'),
 created_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL DEFAULT(now()+interval '2 minutes'),
 CHECK(expires_at>created_at AND expires_at<=created_at+interval '2 minutes')
);
REVOKE ALL ON TABLE private.iclub_ai_v21_encrypted_reply_receipts
 FROM PUBLIC,anon,authenticated,service_role;

-- Exact result settlement and ciphertext insertion succeed or fail together.
-- All pre-delivery auth/exam/rollout/source/revocation checks are STILL required
-- in trusted Edge immediately before calling this RPC. PostgreSQL cannot
-- decrypt or validate academic safety; only a trusted backend may encrypt.
CREATE OR REPLACE FUNCTION public.finish_iclub_ai_delivery_with_receipt_service_v21(
 p_request_id uuid,p_user_id uuid,p_session_fingerprint text,
 p_request_fingerprint text,p_route_class text,
 p_identity_digest text,p_ciphertext text,p_nonce text,p_auth_tag text,p_key_ref text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $finish$
DECLARE v jsonb;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_session_fingerprint IS NULL OR p_session_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_request_fingerprint IS NULL OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_route_class IS NULL OR p_route_class NOT IN('prepared','generated')
 OR p_identity_digest IS NULL OR p_identity_digest !~ '^[a-f0-9]{64}$'
 OR p_ciphertext IS NULL OR (length(p_ciphertext) NOT BETWEEN 20 AND 11000 OR p_ciphertext !~ '^[A-Za-z0-9_-]+$')
 OR p_nonce IS NULL OR p_nonce !~ '^[A-Za-z0-9_-]{16}$'
 OR p_auth_tag IS NULL OR p_auth_tag !~ '^[A-Za-z0-9_-]{22}$'
 OR p_key_ref IS NULL OR p_key_ref !~ '^[A-Za-z0-9_-]{6,80}$'
 THEN RETURN jsonb_build_object('ok',false,'reason','invalid_receipt'); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_encrypted_reply_receipts
  WHERE request_id=p_request_id) THEN
  RETURN jsonb_build_object('ok',false,'reason','receipt_already_exists'); END IF;
 v:=public.finish_iclub_ai_delivery_service_v21(p_request_id,p_user_id,
  p_session_fingerprint,p_request_fingerprint,p_route_class,'completed');
 IF v->>'ok' IS DISTINCT FROM 'true' OR
    v->>'duplicate' IS DISTINCT FROM 'false' THEN
  RETURN jsonb_build_object('ok',false,'reason','delivery_not_finalized');
 END IF;
 -- On ANY INSERT error, PostgreSQL automatically rolls back the whole RPC,
 -- including the nested quota + tombstone completion in the same transaction.
 INSERT INTO private.iclub_ai_v21_encrypted_reply_receipts(
  request_id,user_id,session_fingerprint,request_fingerprint,route_class,
  identity_digest,ciphertext,nonce,auth_tag,key_ref)
 VALUES(p_request_id,p_user_id,p_session_fingerprint,p_request_fingerprint,
  p_route_class,p_identity_digest,p_ciphertext,p_nonce,p_auth_tag,p_key_ref);
 RETURN jsonb_build_object('ok',true);
END $finish$;

-- Return ONLY ciphertext to trusted server. The server must independently
-- verify the current user token, protected assessment, subject, screen,
-- source hash/revision/rights/rollout and completed receipt, THEN decrypt.
-- An expired receipt remains inaccessible; any physical deletion/retention
-- policy requires explicit review before production deployment.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_encrypted_reply_service(
 p_request_id uuid,p_user_id uuid,p_session_fingerprint text,
 p_request_fingerprint text,p_route_class text,p_identity_digest text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $lookup$
DECLARE r private.iclub_ai_v21_encrypted_reply_receipts%rowtype;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_session_fingerprint IS NULL OR p_session_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_request_fingerprint IS NULL OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_route_class IS NULL OR p_route_class NOT IN('prepared','generated')
 OR p_identity_digest IS NULL OR p_identity_digest !~ '^[a-f0-9]{64}$'
 THEN RETURN jsonb_build_object('available',false); END IF;
 SELECT a.* INTO r
 FROM private.iclub_ai_v21_encrypted_reply_receipts a
 JOIN private.iclub_ai_request_tombstones_v21 d
 ON d.request_id=a.request_id AND d.user_id=a.user_id
 JOIN private.iclub_ai_usage_reservations q
 ON q.request_id=a.request_id AND q.user_id=a.user_id
 WHERE a.request_id=p_request_id AND a.user_id=p_user_id
 AND a.session_fingerprint=p_session_fingerprint
 AND a.request_fingerprint=p_request_fingerprint
 AND a.route_class=p_route_class AND a.identity_digest=p_identity_digest
 AND a.expires_at>now()
 AND d.status='completed' AND d.session_fingerprint=p_session_fingerprint
 AND d.request_fingerprint=p_request_fingerprint
 AND d.route_class=p_route_class
 AND q.status='completed' AND q.request_fingerprint=p_request_fingerprint
 AND q.route_class=p_route_class;
 IF NOT FOUND THEN RETURN jsonb_build_object('available',false);END IF;
 RETURN jsonb_build_object('available',true,'ciphertext',r.ciphertext,
  'nonce',r.nonce,'auth_tag',r.auth_tag,'key_ref',r.key_ref);
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('available',false);
END $lookup$;

REVOKE ALL ON FUNCTION public.finish_iclub_ai_delivery_with_receipt_service_v21(
 uuid,uuid,text,text,text,text,text,text,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.finish_iclub_ai_delivery_with_receipt_service_v21(
 uuid,uuid,text,text,text,text,text,text,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_encrypted_reply_service(
 uuid,uuid,text,text,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_encrypted_reply_service(
 uuid,uuid,text,text,text,text) TO service_role;
-- Intentionally NO JSON plaintext response column, no academic writes, no key.
