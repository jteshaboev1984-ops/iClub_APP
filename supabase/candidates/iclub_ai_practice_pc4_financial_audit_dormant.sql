-- PC4 FINANCIAL AUDIT QUEUE — DORMANT, READ-ONLY, SERVICE-ROLE ONLY.
-- This query NEVER changes money/quota/receipts and NEVER erases an unknown.
-- Manual provider billing evidence is REQUIRED for any final classification.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_pc4_financial_audit_service(
 p_limit integer DEFAULT 25
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO '' AS $audit$
DECLARE
 v_pending jsonb;
 v_total bigint;
 v_unknown bigint;
 v_max_exposure bigint;
 v_orphan_quota bigint;
BEGIN
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');
 END IF;
 IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 100 THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_limit');
 END IF;
 -- Deliberately works even when PC3/PC4 release switches are OFF:
 -- operators must be able to audit liabilities after an emergency shutdown.
 SELECT count(*),
   count(*) FILTER(WHERE r.status='unknown' OR b.state='unknown'),
   coalesce(sum(CASE WHEN b.state='charged' THEN
      coalesce(b.actual_microusd,0)
      WHEN b.state IN('reserved','dispatched','unknown')
        THEN coalesce(b.held_microusd,0) ELSE 0 END),0),
   count(*) FILTER(WHERE r.status='void' AND q.state='reserved')
 INTO v_total,v_unknown,v_max_exposure,v_orphan_quota
 FROM private.iclub_ai_practice_receipts_v1 r
 LEFT JOIN private.iclub_ai_v21_freeform_budget_ledger b
   ON b.request_id=r.request_id AND b.user_id=r.user_id
   AND b.request_fingerprint=r.request_fingerprint
 LEFT JOIN private.iclub_ai_v21_freeform_quota_holds q
   ON q.request_id=r.request_id AND q.user_id=r.user_id
   AND q.request_fingerprint=r.request_fingerprint
 -- Even a closed/void receipt may retain an unresolved money hold after
 -- a network failure. Include it in reserved exposure until proven settled.
 WHERE r.status IN('registered','dispatched','ready','acknowledged','unknown')
    OR b.state IN('reserved','dispatched','unknown')
    OR q.state='reserved';
 SELECT coalesce(jsonb_agg(entry ORDER BY created_at,request_id), '[]'::jsonb)
 INTO v_pending FROM (
  SELECT x.received_at AS created_at,x.request_id,
   jsonb_build_object(
    'request_id',x.request_id,
    'receipt_state',x.status,
    'money_state',coalesce(b.state,'missing'),
    'quota_state',coalesce(q.state,'missing'),
    'age_seconds',greatest(0,floor(extract(epoch from
      (clock_timestamp()-x.received_at)))::bigint),
    'maximum_possible_microusd',CASE
       WHEN b.state='charged' THEN coalesce(b.actual_microusd,0)
       WHEN b.state IN('reserved','dispatched','unknown')
         THEN coalesce(b.held_microusd,0)
       ELSE 0 END,
    'action',CASE
      WHEN x.status='unknown' OR b.state='unknown'
        THEN 'confirm_external_provider_charge_manually'
      WHEN x.status='void' AND b.state IN('reserved','dispatched')
        THEN 'investigate_closed_receipt_with_open_money_hold'
      WHEN x.status='void' AND q.state='reserved'
        THEN 'investigate_closed_receipt_with_reserved_learner_quota'
      WHEN x.status='void' AND b.state='charged'
        THEN 'investigate_charged_receipt_marked_void'
      WHEN b.request_id IS NULL OR q.request_id IS NULL
        THEN 'investigate_missing_canonical_ledger'
      WHEN x.status='dispatched'
        THEN 'do_not_retry_provider_manual_check'
      WHEN x.status='registered'
        THEN 'investigate_unfinished_reservation'
      WHEN x.status='ready'
        THEN 'replay_original_receipt_do_not_regenerate'
      WHEN x.status='acknowledged'
        THEN 'verify_quota_settlement'
      ELSE 'review_needed' END
   ) entry
  FROM private.iclub_ai_practice_receipts_v1 x
  LEFT JOIN private.iclub_ai_v21_freeform_budget_ledger b
    ON b.request_id=x.request_id AND b.user_id=x.user_id
    AND b.request_fingerprint=x.request_fingerprint
  LEFT JOIN private.iclub_ai_v21_freeform_quota_holds q
    ON q.request_id=x.request_id AND q.user_id=x.user_id
    AND q.request_fingerprint=x.request_fingerprint
  WHERE (x.status='unknown' OR b.state='unknown')
     OR (x.status='void' AND b.state IN('reserved','dispatched','charged'))
     OR (x.status='void' AND q.state='reserved')
     OR (x.status='dispatched' AND x.dispatched_at <
          clock_timestamp()-interval '5 minutes')
     OR (x.status='registered' AND x.received_at <
          clock_timestamp()-interval '10 minutes')
     OR (x.status='ready' AND x.stored_at <
          clock_timestamp()-interval '1 hour')
     OR (x.status='acknowledged' AND x.quota_confirmed_at IS NULL
          AND x.acknowledged_at < clock_timestamp()-interval '10 minutes')
     OR b.request_id IS NULL OR q.request_id IS NULL
  ORDER BY x.received_at ASC,x.request_id ASC LIMIT p_limit
 ) k;
 RETURN jsonb_build_object(
   'ok',true,'mode','read_only_financial_audit',
   'pending_count',jsonb_array_length(v_pending),
   'total_receipts_monitored',v_total,
   'unknown_count',v_unknown,
   'orphaned_quota_count',v_orphan_quota,
   'maximum_possible_microusd',v_max_exposure,
   'items',v_pending,
   'billing_attribution','no_automatic_per_request_cost_lookup',
   'automatic_write_performed',false);
END;
$audit$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_pc4_financial_audit_service(integer)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_pc4_financial_audit_service(integer)
 TO service_role;
