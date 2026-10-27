-- DORMANT PC4 RECOVERY. Service-only lookup; never expose raw table to browser.
-- Current live learner and current owned finalized main Practice checked on EVERY call.
-- Only a charged and still-available reply can be discovered after full reload.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_recover_pc4_service(
 p_user_id uuid,p_attempt_ref bigint,p_locale text,
 p_request_id uuid DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO '' AS $fn$
DECLARE r private.iclub_ai_practice_receipts_v1%ROWTYPE;
 granted jsonb;
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_user_id IS NULL OR p_attempt_ref IS NULL OR p_attempt_ref<1
    OR p_locale NOT IN('ru','uz','en') THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;
 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control pc4
  JOIN private.iclub_ai_practice_context_v1_control pc1 USING(singleton)
  JOIN private.iclub_ai_practice_freeform_pc3_control pc3 USING(singleton)
  WHERE pc4.singleton=1 AND pc4.enabled AND pc1.enabled AND pc3.enabled
 ) THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;
 granted:=public.get_iclub_ai_practice_context_v1_service(
   p_user_id,p_attempt_ref,'practice_visibility',NULL,p_locale);
 IF granted->>'ok' IS DISTINCT FROM 'true' THEN
  RETURN jsonb_build_object('ok',false,'reason','context_unavailable');
 END IF;
 SELECT x.* INTO r FROM private.iclub_ai_practice_receipts_v1 x
 JOIN private.iclub_ai_v21_freeform_budget_ledger money
   ON money.request_id=x.request_id AND money.user_id=x.user_id
  AND money.request_fingerprint=x.request_fingerprint
 WHERE x.user_id=p_user_id AND x.attempt_ref=p_attempt_ref
   AND x.locale=p_locale
   AND (x.status='ready' OR
        (p_request_id IS NOT NULL AND x.status='acknowledged'))
   AND x.expires_at>clock_timestamp() AND money.state='charged'
   AND (p_request_id IS NULL OR x.request_id=p_request_id)
 ORDER BY x.received_at DESC,x.request_id DESC LIMIT 1;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'reason','no_pending_answer'); END IF;
 -- All hashes are sent ONLY to the internally authenticated service Edge;
 -- its fresh PC1 snapshot must match both hashes before any response/ACK.
 RETURN jsonb_build_object('ok',true,'action','recoverable',
  'request_id',r.request_id,
  'request_fingerprint',r.request_fingerprint,
  'context_fingerprint',r.context_fingerprint,
  'source_fingerprint',r.source_fingerprint);
END $fn$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_recover_pc4_service(
 uuid,bigint,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_recover_pc4_service(
 uuid,bigint,text,uuid) TO service_role;
