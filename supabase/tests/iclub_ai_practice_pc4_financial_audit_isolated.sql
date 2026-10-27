\set ON_ERROR_STOP on
DO $isolated$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'STOP: audit tests on disposable PostgreSQL only'; END IF;
END $isolated$;
\ir ../candidates/iclub_ai_practice_pc4_financial_audit_dormant.sql
SET request.jwt.claim.role='service_role';
DO $test$
DECLARE
 o jsonb; before_state text; after_state text;
 item jsonb;
BEGIN
 SELECT r.status||':'||b.state||':'||q.state INTO before_state
 FROM private.iclub_ai_practice_receipts_v1 r
 JOIN private.iclub_ai_v21_freeform_budget_ledger b USING(request_id)
 JOIN private.iclub_ai_v21_freeform_quota_holds q USING(request_id)
 WHERE r.request_id='99999999-9999-4999-8999-999999999999';
 IF before_state IS DISTINCT FROM 'unknown:unknown:released'
 THEN RAISE EXCEPTION 'Missing canonical ambiguous-provider fixture %',before_state; END IF;
 -- A reserve RPC can commit while the Edge loses its HTTP response.
 -- The app then closes its receipt, BUT the money remains reserved. This is
 -- synthetic only: it must stay visible to the read-only financial auditor.
 INSERT INTO private.iclub_ai_practice_receipts_v1(
   request_id,user_id,attempt_ref,locale,request_fingerprint,
   context_fingerprint,source_fingerprint,status)
 VALUES('88888888-8888-4888-8888-888888888888',
   '00000000-0000-4000-8000-000000000011',501,'ru',
   repeat('3',64),repeat('4',64),repeat('5',64),'void');
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger(
   request_id,user_id,request_fingerprint,held_microusd,state)
 VALUES('88888888-8888-4888-8888-888888888888',
   '00000000-0000-4000-8000-000000000011',
   repeat('3',64),50000,'reserved');
 INSERT INTO private.iclub_ai_v21_freeform_quota_holds(
   request_id,user_id,request_fingerprint,weight,state)
 VALUES('88888888-8888-4888-8888-888888888888',
   '00000000-0000-4000-8000-000000000011',
   repeat('3',64),3,'released');
 -- A quota reservation can also commit while its HTTP response disappears.
 -- An abandoned request with NO money ledger but RESERVED learner quota
 -- must be visible for manual reconciliation, not silently consume credits.
 INSERT INTO private.iclub_ai_practice_receipts_v1(
   request_id,user_id,attempt_ref,locale,request_fingerprint,
   context_fingerprint,source_fingerprint,status)
 VALUES('66666666-6666-4666-8666-666666666666',
   '00000000-0000-4000-8000-000000000011',501,'ru',
   repeat('6',64),repeat('7',64),repeat('8',64),'void');
 INSERT INTO private.iclub_ai_v21_freeform_quota_holds(
   request_id,user_id,request_fingerprint,weight,state)
 VALUES('66666666-6666-4666-8666-666666666666',
   '00000000-0000-4000-8000-000000000011',
   repeat('6',64),3,'reserved');
 -- The PC3 kill switch is OFF from the final E2E: the auditor MUST
 -- still report risk after emergency shutdown.
 o:=public.iclub_ai_practice_pc4_financial_audit_service(100);
 IF o->>'ok' IS DISTINCT FROM 'true' OR
    o->>'mode' IS DISTINCT FROM 'read_only_financial_audit' OR
    (o->>'unknown_count')::integer<1 OR
    (o->>'orphaned_quota_count')::integer<>1 OR
    (o->>'maximum_possible_microusd')::bigint<100000 OR
    o->>'automatic_write_performed' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'No-write financial audit failed %',o; END IF;
 SELECT value INTO item
 FROM jsonb_array_elements(o->'items') AS e(value)
 WHERE e.value->>'request_id'='99999999-9999-4999-8999-999999999999';
 IF item IS NULL OR
    item->>'action' IS DISTINCT FROM 'confirm_external_provider_charge_manually' OR
    item->>'money_state' IS DISTINCT FROM 'unknown' OR
    item->>'quota_state' IS DISTINCT FROM 'released' OR
    (item->>'maximum_possible_microusd')::bigint<>50000
 THEN RAISE EXCEPTION 'Unknown risk not prioritized correctly %',item; END IF;
 -- A closed receipt must NOT disappear while its canonical money hold
 -- remains reserved, otherwise a beta could burn its $5 without visibility.
 SELECT value INTO item FROM jsonb_array_elements(o->'items') AS e(value)
 WHERE e.value->>'request_id'='88888888-8888-4888-8888-888888888888';
 IF item IS NULL OR
    item->>'receipt_state' IS DISTINCT FROM 'void' OR
    item->>'money_state' IS DISTINCT FROM 'reserved' OR
    item->>'action' IS DISTINCT FROM
      'investigate_closed_receipt_with_open_money_hold' OR
    (item->>'maximum_possible_microusd')::bigint<>50000
 THEN RAISE EXCEPTION 'Closed receipt hid an existing reserved money hold %',item; END IF;
 IF item ? 'user_id' OR item ? 'attempt_ref' OR item ? 'answer' OR
    item ? 'source_fingerprint' OR item ? 'request_fingerprint'
 THEN RAISE EXCEPTION 'Closed receipt audit exposed student metadata %',item; END IF;
 -- Verify the no-money but reserved-quota orphan.
 SELECT value INTO item FROM jsonb_array_elements(o->'items') AS e(value)
 WHERE e.value->>'request_id'='66666666-6666-4666-8666-666666666666';
 IF item IS NULL OR
    item->>'money_state' IS DISTINCT FROM 'missing' OR
    item->>'quota_state' IS DISTINCT FROM 'reserved' OR
    item->>'action' IS DISTINCT FROM
      'investigate_closed_receipt_with_reserved_learner_quota' OR
    (item->>'maximum_possible_microusd')::bigint<>0
 THEN RAISE EXCEPTION 'Orphan learner quota was hidden from the audit %',item; END IF;
 IF item ? 'user_id' OR item ? 'attempt_ref' OR item ? 'answer' OR
    item ? 'source_fingerprint' OR item ? 'request_fingerprint'
 THEN RAISE EXCEPTION 'Audit exposed student data / academic metadata %',item; END IF;
 SELECT r.status||':'||b.state||':'||q.state INTO after_state
 FROM private.iclub_ai_practice_receipts_v1 r
 JOIN private.iclub_ai_v21_freeform_budget_ledger b USING(request_id)
 JOIN private.iclub_ai_v21_freeform_quota_holds q USING(request_id)
 WHERE r.request_id='99999999-9999-4999-8999-999999999999';
 IF before_state IS DISTINCT FROM after_state
 THEN RAISE EXCEPTION 'Audit mutated financial records % -> %',before_state,after_state; END IF;
 o:=public.iclub_ai_practice_pc4_financial_audit_service(0);
 IF o->>'reason' IS DISTINCT FROM 'invalid_limit'
 THEN RAISE EXCEPTION 'Failed audit limit enforcement %',o; END IF;
 RAISE NOTICE 'PASS PC4 no-write audit: unknown cost, closed money hold and orphan learner quota visible, no user content, OFF';
END $test$;
SET request.jwt.claim.role='authenticated';
DO $test$
DECLARE o jsonb;
BEGIN
 o:=public.iclub_ai_practice_pc4_financial_audit_service(100);
 IF o->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'Direct learner access to financial audit %',o; END IF;
END $test$;
