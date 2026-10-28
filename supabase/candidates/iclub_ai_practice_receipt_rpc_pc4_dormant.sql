-- DORMANT PC4 RPC. Compile only after the receipt-table candidate.
-- Edge remains responsible for JWT validation, source/version admission,
-- existing shared quota + budget reservation, provider result validation.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_receipt_pc4_service(
 p_action text,p_request_id uuid,p_user_id uuid,p_attempt_ref bigint,
 p_request_fingerprint text,p_context_fingerprint text,
 p_source_fingerprint text,p_locale text,
 p_answer text DEFAULT NULL,p_actual_microusd bigint DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO '' AS $fn$
DECLARE r private.iclub_ai_practice_receipts_v1%ROWTYPE;
 ctx jsonb;
 money_state text;
 quota_state text;
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_action NOT IN('begin','inspect','dispatch','store','replay','ack','accounted','void','unknown')
 OR p_request_id IS NULL OR p_user_id IS NULL
 OR p_attempt_ref IS NULL OR p_attempt_ref<=0
 OR p_locale NOT IN('ru','uz','en')
 OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_context_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_source_fingerprint !~ '^[a-f0-9]{64}$' THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;
 -- Financial cleanup remains necessary AFTER consent/entitlement is
 -- revoked or an emergency kill switch is engaged. These actions NEVER
 -- release student content, create a receipt, or dispatch a model request.
 -- All still require service_role and exact UUID/owner/fingerprint matching.
 IF p_action NOT IN('void','unknown','inspect','accounted') THEN
  IF NOT EXISTS (
   SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control a
   JOIN private.iclub_ai_practice_context_v1_control b
    ON a.singleton=b.singleton
   WHERE a.singleton=1 AND a.enabled AND b.enabled
  ) THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;
  ctx:=public.get_iclub_ai_practice_context_v1_service(
   p_user_id,p_attempt_ref,'practice_visibility',NULL,p_locale);
  IF ctx->>'ok' IS DISTINCT FROM 'true' THEN
   RETURN jsonb_build_object('ok',false,'reason','context_unavailable');
  END IF;
 END IF;
 -- Serialize one learner's receipt creation before checking pending count.
 PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text),4516);
 PERFORM pg_advisory_xact_lock(hashtext(p_request_id::text),4517);
 SELECT * INTO r FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND THEN
  IF p_action<>'begin' THEN
   RETURN jsonb_build_object('ok',false,'reason','receipt_missing');
  END IF;
  IF (SELECT count(*) FROM private.iclub_ai_practice_receipts_v1
      WHERE user_id=p_user_id AND status IN('registered','dispatched','ready')
        AND expires_at>now())>=2 THEN
   RETURN jsonb_build_object('ok',false,'reason','pending_limit');
  END IF;
  INSERT INTO private.iclub_ai_practice_receipts_v1(
   request_id,user_id,attempt_ref,locale,request_fingerprint,
   context_fingerprint,source_fingerprint)
  VALUES(p_request_id,p_user_id,p_attempt_ref,p_locale,p_request_fingerprint,
    p_context_fingerprint,p_source_fingerprint);
  RETURN jsonb_build_object('ok',true,'action','registered');
 END IF;
 IF r.user_id IS DISTINCT FROM p_user_id OR
    r.attempt_ref IS DISTINCT FROM p_attempt_ref OR
    r.locale IS DISTINCT FROM p_locale OR
    r.request_fingerprint IS DISTINCT FROM p_request_fingerprint OR
    r.context_fingerprint IS DISTINCT FROM p_context_fingerprint OR
    r.source_fingerprint IS DISTINCT FROM p_source_fingerprint THEN
  RETURN jsonb_build_object('ok',false,'reason','request_conflict');
 END IF;
 IF p_action='begin' THEN
  RETURN jsonb_build_object('ok',true,'action','existing',
    'state',r.status,'provider_called',false);
 END IF;
 IF p_action='inspect' THEN
  -- Internal accounting metadata only; no learner answer or keys returned.
  -- "void" alone does NOT prove no model dispatch: an unknown-charge
  -- receipt may be void if the dispatch acknowledgement was lost.
  RETURN jsonb_build_object('ok',true,'action','inspection',
    'state',r.status,'actual_microusd',r.provider_reported_microusd,
    'quota_accounted',r.quota_confirmed_at IS NOT NULL,
    'safe_new_request',(r.status='void'
      AND NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger b
        WHERE b.request_id=p_request_id AND b.state<>'no_charge')
      AND NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_quota_holds h
        WHERE h.request_id=p_request_id AND h.state='reserved')));
 END IF;
 IF p_action='replay' THEN
  IF r.status NOT IN('ready','acknowledged') OR now()>=r.expires_at THEN
   RETURN jsonb_build_object('ok',false,'reason','replay_unavailable');
  END IF;
  -- Do not deliver a stored response before the shared budget records cost.
  IF NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger
      WHERE request_id=p_request_id AND user_id=p_user_id
        AND request_fingerprint=p_request_fingerprint AND state='charged') THEN
    RETURN jsonb_build_object('ok',false,'reason','budget_settlement_pending');
  END IF;
  RETURN jsonb_build_object('ok',true,'action','replay',
   'message',r.answer,'message_hash',r.answer_hash,
   'state',r.status,'provider_called',false);
 END IF;
 IF p_action='dispatch' THEN
  IF r.status<>'registered' OR now()>=r.expires_at THEN
   RETURN jsonb_build_object('ok',false,'reason','dispatch_already_decided');
  END IF;
  -- Verify holds in the EXISTING $5 shared accounting structures.
  -- Provider may be called only after this transaction commits.
  SELECT state INTO money_state FROM private.iclub_ai_v21_freeform_budget_ledger
   WHERE request_id=p_request_id AND user_id=p_user_id
    AND request_fingerprint=p_request_fingerprint
    AND held_microusd=50000;
  SELECT state INTO quota_state FROM private.iclub_ai_v21_freeform_quota_holds
   WHERE request_id=p_request_id AND user_id=p_user_id
    AND request_fingerprint=p_request_fingerprint
    AND weight=CASE WHEN private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)
      THEN 5 ELSE 3 END;
  IF coalesce(money_state,'')<>'dispatched'
     OR coalesce(quota_state,'')<>'reserved' THEN
   RETURN jsonb_build_object('ok',false,'reason','shared_hold_missing');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='dispatched',dispatched_at=now() WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','dispatch_once');
 END IF;
 IF p_action='store' THEN
  IF r.status<>'dispatched' OR p_answer IS NULL
     OR char_length(p_answer) NOT BETWEEN 20 AND 2400
     OR p_actual_microusd IS NULL OR p_actual_microusd NOT BETWEEN 0 AND 50000
     OR p_answer ~* '<[/!]?[a-z][^>]*>' THEN
   RETURN jsonb_build_object('ok',false,'reason','invalid_store');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='ready',answer=p_answer,stored_at=now(),
    answer_hash=encode(extensions.digest(convert_to(p_answer,'UTF8'),'sha256'),'hex'),
    provider_reported_microusd=p_actual_microusd
   WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','stored');
 END IF;
 IF p_action='ack' THEN
  IF r.status='acknowledged' THEN
   RETURN jsonb_build_object('ok',true,'action','acknowledged',
     'quota_settlement_pending',r.quota_confirmed_at IS NULL);
  END IF;
  IF r.status<>'ready' OR now()>=r.expires_at THEN
   RETURN jsonb_build_object('ok',false,'reason','ack_unavailable');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='acknowledged',acknowledged_at=now() WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','acknowledged',
    'quota_settlement_pending',true);
 END IF;
 IF p_action='accounted' THEN
  IF r.status<>'acknowledged' THEN
   RETURN jsonb_build_object('ok',false,'reason','ack_required');
  END IF;
  SELECT state INTO quota_state FROM private.iclub_ai_v21_freeform_quota_holds
    WHERE request_id=p_request_id AND user_id=p_user_id
      AND request_fingerprint=p_request_fingerprint;
  SELECT state INTO money_state FROM private.iclub_ai_v21_freeform_budget_ledger
    WHERE request_id=p_request_id AND user_id=p_user_id
      AND request_fingerprint=p_request_fingerprint;
  IF coalesce(quota_state,'')<>'completed' OR
     coalesce(money_state,'')<>'charged' THEN
   RETURN jsonb_build_object('ok',false,'reason','shared_settlement_unconfirmed');
  END IF;
  UPDATE private.iclub_ai_practice_receipts_v1
   SET quota_confirmed_at=coalesce(quota_confirmed_at,now())
   WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','accounted');
 END IF;
 IF p_action='void' AND r.status='registered' THEN
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='void' WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','void_before_dispatch');
 END IF;
 IF p_action='unknown' AND r.status='dispatched' THEN
  UPDATE private.iclub_ai_practice_receipts_v1
   SET status='unknown' WHERE request_id=p_request_id;
  RETURN jsonb_build_object('ok',true,'action','provider_exposure_unknown');
 END IF;
 RETURN jsonb_build_object('ok',false,'reason','invalid_transition');
END;
$fn$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_receipt_pc4_service(
 text,uuid,uuid,bigint,text,text,text,text,text,bigint)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_receipt_pc4_service(
 text,uuid,uuid,bigint,text,text,text,text,text,bigint)
 TO service_role;
