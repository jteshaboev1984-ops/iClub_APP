\set ON_ERROR_STOP on
-- Disposable PostgreSQL-only recovery test; never deploy to production.
DO $guard$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'isolated PostgreSQL required'; END IF;
END $guard$;
\ir ../candidates/iclub_ai_practice_recover_pc4_dormant.sql
SET request.jwt.claim.role='service_role';
DO $test$
DECLARE
 u uuid:='00000000-0000-4000-8000-000000000011';
 rid uuid:='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
 x jsonb;
BEGIN
 UPDATE private.iclub_ai_practice_receipt_v1_control SET enabled=true WHERE singleton=1;
 UPDATE private.iclub_ai_practice_context_v1_control SET enabled=true WHERE singleton=1;
 UPDATE private.iclub_ai_practice_freeform_pc3_control SET enabled=true WHERE singleton=1;
 INSERT INTO private.iclub_ai_practice_receipts_v1(
  request_id,user_id,attempt_ref,locale,request_fingerprint,
  context_fingerprint,source_fingerprint,status,answer,answer_hash,
  provider_reported_microusd,stored_at)
 VALUES(rid,u,501,'ru',repeat('d',64),repeat('e',64),repeat('f',64),
  'ready','Restorable verified attempt response, 7 correct out of 10.',
  repeat('a',64),501,now());
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 VALUES(rid,u,repeat('d',64),50000,'charged');
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'ru');
 IF x->>'request_id' IS DISTINCT FROM rid::text OR x->>'action' IS DISTINCT FROM 'recoverable'
 THEN RAISE EXCEPTION 'Reload discovery failed %',x; END IF;
 x:=public.iclub_ai_practice_recover_pc4_service(
   '00000000-0000-4000-8000-000000000022',501,'ru');
 IF x->>'ok' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Cross-user receipt leaked %',x; END IF;
 x:=public.iclub_ai_practice_recover_pc4_service(u,502,'ru');
 IF x->>'ok' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Wrong-attempt receipt leaked %',x; END IF;
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'en');
 IF x->>'ok' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Wrong-locale receipt leaked %',x; END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_ledger SET state='unknown'
 WHERE request_id=rid;
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'ru');
 IF x->>'reason' IS DISTINCT FROM 'no_pending_answer'
 THEN RAISE EXCEPTION 'Unknown money cost leaked answer %',x; END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_ledger SET state='charged'
 WHERE request_id=rid;
 UPDATE private.iclub_ai_practice_receipts_v1 SET status='acknowledged'
 WHERE request_id=rid;
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'ru');
 IF x->>'reason' IS DISTINCT FROM 'no_pending_answer'
 THEN RAISE EXCEPTION 'Already delivered answer auto-restored %',x; END IF;
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'ru',rid);
 IF x->>'request_id' IS DISTINCT FROM rid::text
 THEN RAISE EXCEPTION 'Lost ACK response cannot be reconciled %',x; END IF;
 UPDATE private.iclub_ai_practice_receipts_v1 SET status='ready',
   expires_at=now()-interval '1 minute' WHERE request_id=rid;
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'ru');
 IF x->>'reason' IS DISTINCT FROM 'no_pending_answer'
 THEN RAISE EXCEPTION 'Expired answer leaked %',x; END IF;
 UPDATE private.iclub_ai_practice_receipt_v1_control SET enabled=false WHERE singleton=1;
 x:=public.iclub_ai_practice_recover_pc4_service(u,501,'ru');
 IF x->>'reason' IS DISTINCT FROM 'not_enabled'
 THEN RAISE EXCEPTION 'Kill switch bypass %',x; END IF;
 RAISE NOTICE 'PASS PC4 full reload: owned/charged/pending only, ACK retry, expiry, OFF';
END $test$;
SET request.jwt.claim.role='authenticated';
DO $test$
DECLARE x jsonb;
BEGIN
 x:=public.iclub_ai_practice_recover_pc4_service(
 '00000000-0000-4000-8000-000000000011',501,'ru');
 IF x->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'Authenticated browser called service-only recovery %',x; END IF;
END $test$;
