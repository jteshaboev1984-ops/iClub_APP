-- Standalone isolated 4-route SQL regression. Rolls back all synthetic ledger rows.
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('request.jwt.claim.role','service_role',true);
DO $matrix$
DECLARE
 u uuid:='00000000-0000-4000-8000-000000000001';
 r_release uuid:='00000000-0000-4000-8000-000000000011';
 r_unknown uuid:='00000000-0000-4000-8000-000000000012';
 r_freeform uuid:='00000000-0000-4000-8000-000000000013';
 r_canary uuid:='00000000-0000-4000-8000-000000000014';
 r_expired uuid:='00000000-0000-4000-8000-000000000015';
 r_denied uuid:='00000000-0000-4000-8000-000000000016';
 v jsonb;
 n bigint;
BEGIN
 IF (SELECT enabled FROM private.iclub_ai_all_route_spend_control_v1 WHERE singleton=1) IS DISTINCT FROM false THEN
  RAISE EXCEPTION 'New global spending gate did not default OFF'; END IF;
 IF has_function_privilege('anon','public.mark_exam_prep_ai_provider_dispatched_service_v1(uuid)','EXECUTE')
 OR has_function_privilege('authenticated','public.mark_practice_ai_provider_dispatched_service_v1(uuid)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_ai_all_route_budget_allowed_v1(bigint)','EXECUTE') THEN
  RAISE EXCEPTION 'Financial settlement/guard exposed to learner roles';END IF;
 -- Even an old Edge version must not clear its liability by claiming zero charge.
 v:=public.reserve_exam_prep_ai_provider_call_service_v1(r_release,u,0.005);
 IF v->>'allowed'<>'true' THEN RAISE EXCEPTION 'Initial legacy reservation denied: %',v;END IF;
 v:=public.finalize_exam_prep_ai_provider_call_service_v1(r_release,'released',0);
 IF v->>'ok'<>'false' THEN RAISE EXCEPTION 'Unverified pre-dispatch release wiped liability: %',v;END IF;
 v:=public.finalize_exam_prep_ai_provider_call_service_v1(r_release,'unknown',0);
 IF v->>'ok'<>'true' THEN RAISE EXCEPTION 'Unverified pre-dispatch reserve not retained: %',v;END IF;
 -- Dispatched: release must fail and UNKNOWN retains full hold, not zero cost.
 v:=public.reserve_exam_prep_ai_provider_call_service_v1(r_unknown,u,0.006);
 IF v->>'allowed'<>'true' THEN RAISE EXCEPTION 'Exam reserve failed: %',v;END IF;
 v:=public.mark_exam_prep_ai_provider_dispatched_service_v1(r_unknown);
 IF v->>'ok'<>'true' THEN RAISE EXCEPTION 'Dispatch marker failed: %',v;END IF;
 v:=public.mark_exam_prep_ai_provider_dispatched_service_v1(r_unknown);
 IF v->>'ok'<>'false' THEN RAISE EXCEPTION 'Duplicate dispatch marker was allowed: %',v;END IF;
 v:=public.finalize_exam_prep_ai_provider_call_service_v1(r_unknown,'released',0);
 IF v->>'ok'<>'false' THEN RAISE EXCEPTION 'Uncertain provider charge was released: %',v;END IF;
 v:=public.finalize_exam_prep_ai_provider_call_service_v1(r_unknown,'unknown',0);
 IF v->>'ok'<>'true' THEN RAISE EXCEPTION 'Unknown charge was not retained: %',v;END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_ai_provider_leases
 WHERE request_id=r_unknown AND status='unknown' AND actual_cost_usd IS NULL AND dispatched_at IS NOT NULL) THEN
  RAISE EXCEPTION 'Unknown charge mutated to zero or lost dispatch evidence';END IF;
 v:=public.reserve_exam_prep_ai_provider_call_service_v1(r_unknown,u,0.006);
 IF v->>'allowed'<>'false' THEN RAISE EXCEPTION 'Repeated UUID can trigger provider again: %',v;END IF;
 -- The architect's amounts are not configured in production. Synthetic ONLY.
 UPDATE private.iclub_ai_all_route_spend_control_v1
 SET enabled=true,max_day_microusd=75000,max_lifetime_microusd=75000 WHERE singleton=1;
 INSERT INTO private.iclub_ai_v21_beta_members
 VALUES(u,true,now(),'global_ai_beta_v21');
 v:=public.reserve_iclub_ai_v21_freeform_budget_v1(
 r_freeform,u,repeat('a',64),repeat('b',64),repeat('c',64),'v1','en');
 IF v->>'allowed'<>'true' THEN RAISE EXCEPTION 'Freeform shared cap unexpectedly blocked: %',v;END IF;
 v:=public.reserve_iclub_ai_paid_canary_v1(r_canary);
 IF v->>'allowed'<>'true' THEN RAISE EXCEPTION 'Canary shared cap unexpectedly blocked: %',v;END IF;
 -- 5,000 + 6,000 + 50,000 + 10,000 = 71,000 microUSD, next 5,000 must fail.
 v:=public.reserve_practice_ai_provider_call_service_v1(r_denied,u,0.005);
 IF v->>'allowed'<>'false' OR v->>'reason'<>'shared_provider_budget_exhausted' THEN
  RAISE EXCEPTION 'Cross-route cap failed to block fourth ledger: %',v;END IF;
 IF EXISTS(SELECT 1 FROM private.practice_ai_provider_leases WHERE request_id=r_denied) THEN
  RAISE EXCEPTION 'Global cap rejected but local reservation inserted';END IF;
 -- Expired legacy in-flight requests must not be reset to zero (74k exposure).
 INSERT INTO private.practice_ai_provider_leases(
 request_id,user_id,reserved_cost_usd,status,created_at,expires_at)
 VALUES(r_expired,u,0.003,'active',now()-interval '2 minutes',now()-interval '1 minute');
 v:=public.reserve_practice_ai_provider_call_service_v1(r_denied,u,0.002);
 IF v->>'allowed'<>'false' THEN RAISE EXCEPTION 'Expired but uncertain cost was omitted from cap: %',v;END IF;
 IF NOT EXISTS(SELECT 1 FROM private.practice_ai_provider_leases
 WHERE request_id=r_expired AND status='unknown' AND actual_cost_usd IS NULL) THEN
  RAISE EXCEPTION 'Legacy lease expiry cleared an uncertain cost';END IF;
 v:=public.finalize_practice_ai_provider_call_service_v1(r_expired,'released',0);
 IF v->>'ok'<>'false' THEN RAISE EXCEPTION 'Expired unknown charge improperly released';END IF;
 -- No learner data changes and no zero-charge mark on unresolved states.
 SELECT count(*) INTO n FROM private.iclub_ai_v21_freeform_budget_ledger
 WHERE request_id=r_freeform AND state='reserved' AND held_microusd=50000;
 IF n<>1 THEN RAISE EXCEPTION 'General Freeform financial hold changed';END IF;
 RAISE NOTICE 'AI ALL-ROUTE FINANCE TEST GREEN: predispatch, unknown, duplicate, shared cap, expiry, ACL';
END $matrix$;
ROLLBACK;
SELECT CASE WHEN EXISTS(SELECT 1 FROM private.exam_prep_ai_provider_leases) THEN 1 ELSE 0 END AS synthetic_leases_remaining;
