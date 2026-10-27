\set ON_ERROR_STOP on
-- SAME ephemeral PostgreSQL 17 as the previous finalized 7/10 fixture.
DO $isolation$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: isolated database only'; END IF;
END $isolation$;
CREATE TABLE private.iclub_ai_v21_freeform_budget_ledger(
 request_id uuid PRIMARY KEY,user_id uuid,request_fingerprint text,
 held_microusd bigint,state text);
CREATE TABLE private.iclub_ai_v21_freeform_quota_holds(
 request_id uuid PRIMARY KEY,user_id uuid,request_fingerprint text,
 weight smallint,state text);
\ir ../candidates/iclub_ai_practice_receipts_pc4_dormant.sql
\ir ../candidates/iclub_ai_practice_receipt_rpc_pc4_dormant.sql
SET request.jwt.claim.role='service_role';
DO $test$
DECLARE
 u uuid:='00000000-0000-4000-8000-000000000011';
 rid uuid:='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 fp text:=repeat('a',64);
 cp text:=repeat('b',64);
 sp text:=repeat('c',64);
 answer text:='Verified sample: 7 correct, 3 incorrect. Review questions 2, 6, and 9.';
 x jsonb;
BEGIN
 x:=public.iclub_ai_practice_receipt_pc4_service('begin',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'not_enabled' THEN
  RAISE EXCEPTION 'OFF flag bypass: %',x; END IF;
 UPDATE private.iclub_ai_practice_receipt_v1_control SET enabled=true WHERE singleton=1;
 x:=public.iclub_ai_practice_receipt_pc4_service('begin',rid,u,501,fp,cp,sp,'ru');
 IF x->>'action' IS DISTINCT FROM 'registered' THEN
  RAISE EXCEPTION 'Cannot create durable receipt: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('begin',rid,u,501,fp,cp,sp,'ru');
 IF x->>'action' IS DISTINCT FROM 'existing' THEN
  RAISE EXCEPTION 'Duplicate key created new receipt: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('dispatch',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'shared_hold_missing' THEN
  RAISE EXCEPTION 'Dispatched without global money/learner holds: %',x; END IF;
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 VALUES(rid,u,fp,50000,'reserved');
 INSERT INTO private.iclub_ai_v21_freeform_quota_holds
 VALUES(rid,u,fp,3,'reserved');
 UPDATE private.iclub_ai_v21_freeform_budget_ledger SET state='dispatched' WHERE request_id=rid;
 x:=public.iclub_ai_practice_receipt_pc4_service('dispatch',rid,u,501,fp,cp,sp,'ru');
 IF x->>'action' IS DISTINCT FROM 'dispatch_once' THEN
  RAISE EXCEPTION 'First dispatch denied: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('dispatch',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'dispatch_already_decided' THEN
  RAISE EXCEPTION 'Second provider dispatch was allowed: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('replay',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'replay_unavailable' THEN
  RAISE EXCEPTION 'Dispatched-but-unverified response was replayed: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('store',rid,u,501,fp,cp,sp,'ru',answer,12500);
 IF x->>'action' IS DISTINCT FROM 'stored' THEN
  RAISE EXCEPTION 'Verified result not persisted: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('replay',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'budget_settlement_pending'
 THEN RAISE EXCEPTION 'Delivered before recording provider cost: %',x; END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_ledger SET state='charged' WHERE request_id=rid;
 x:=public.iclub_ai_practice_receipt_pc4_service('replay',rid,u,501,fp,cp,sp,'ru');
 IF x->>'message' IS DISTINCT FROM answer OR x->>'provider_called' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Replay did not recover same result: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('begin',rid,u,501,repeat('d',64),cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'request_conflict' THEN
  RAISE EXCEPTION 'Fingerprint-conflicting request accepted: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('ack',rid,u,501,fp,cp,sp,'ru');
 IF x->>'action' IS DISTINCT FROM 'acknowledged' OR
    x->>'quota_settlement_pending' IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'ACK semantics wrong: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('ack',rid,u,501,fp,cp,sp,'ru');
 IF x->>'action' IS DISTINCT FROM 'acknowledged' THEN
  RAISE EXCEPTION 'Repeated ACK is not idempotent: %',x; END IF;
 x:=public.iclub_ai_practice_receipt_pc4_service('accounted',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'shared_settlement_unconfirmed' THEN
  RAISE EXCEPTION 'Marked quota paid without shared ledger settlement: %',x; END IF;
 UPDATE private.iclub_ai_v21_freeform_quota_holds
 SET state='completed' WHERE request_id=rid;
 x:=public.iclub_ai_practice_receipt_pc4_service('accounted',rid,u,501,fp,cp,sp,'ru');
 IF x->>'action' IS DISTINCT FROM 'accounted' THEN
  RAISE EXCEPTION 'Acknowledged quota marker unavailable: %',x; END IF;
 UPDATE private.iclub_ai_practice_receipt_v1_control SET enabled=false WHERE singleton=1;
 x:=public.iclub_ai_practice_receipt_pc4_service('replay',rid,u,501,fp,cp,sp,'ru');
 IF x->>'reason' IS DISTINCT FROM 'not_enabled' THEN
  RAISE EXCEPTION 'OFF flag still leaks saved answer: %',x; END IF;
 RAISE NOTICE 'PASS PC4: shared holds, one dispatch, stored replay, conflict, ACK, flag OFF';
END $test$;
SET request.jwt.claim.role='authenticated';
DO $test$
DECLARE x jsonb;
BEGIN
 x:=public.iclub_ai_practice_receipt_pc4_service('replay',
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 '00000000-0000-4000-8000-000000000011',501,
 repeat('a',64),repeat('b',64),repeat('c',64),'ru');
 IF x->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'Authenticated client bypassed service restriction: %',x; END IF;
END $test$;
