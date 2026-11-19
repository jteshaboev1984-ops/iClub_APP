\set ON_ERROR_STOP on
-- Synthetic-only 24h answer-text policy validation: no production migrations,
-- no real learners, no change to prior PC4 financial/receipt test fixtures.
DO $guard$
BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: disposable PostgreSQL only'; END IF;
END $guard$;

BEGIN;
\ir ../candidates/iclub_ai_practice_answer_retention24_isolated.sql

SET LOCAL request.jwt.claim.role='authenticated';
DO $test$
DECLARE out jsonb;
BEGIN
 out:=public.iclub_ai_practice_redact_expired24_service(100);
 IF out->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'Learner invoked redaction RPC'; END IF;
 IF has_function_privilege('authenticated',
   'public.iclub_ai_practice_redact_expired24_service(integer)','EXECUTE')
 THEN RAISE EXCEPTION 'Direct authenticated function EXECUTE leaked'; END IF;
 IF has_function_privilege('anon',
   'public.iclub_ai_practice_redact_expired24_service(integer)','EXECUTE')
 THEN RAISE EXCEPTION 'Direct anon function EXECUTE leaked'; END IF;
 out:=public.iclub_ai_practice_strict24_admission_probe_v1();
 IF out->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'Learner bypassed strict24 admission: %',out; END IF;
 IF has_function_privilege('authenticated',
   'public.iclub_ai_practice_strict24_admission_probe_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'Learner can directly probe strict24 gate'; END IF;
END $test$;

SET LOCAL request.jwt.claim.role='service_role';
DO $test$
DECLARE out jsonb;
BEGIN
 out:=public.iclub_ai_practice_redact_expired24_service(100);
 IF out->>'reason' IS DISTINCT FROM 'not_enabled'
 THEN RAISE EXCEPTION 'Retention switched ON by candidate: %',out; END IF;
 out:=public.iclub_ai_practice_redact_expired24_service(101);
 IF out->>'reason' IS DISTINCT FROM 'invalid_limit'
 THEN RAISE EXCEPTION 'Unbounded cleanup allowed: %',out; END IF;
 out:=public.iclub_ai_practice_strict24_admission_probe_v1();
 IF out->>'reason' IS DISTINCT FROM 'not_enabled'
 THEN RAISE EXCEPTION 'New strict retention gate switched ON prematurely: %',out; END IF;
END $test$;

-- These test-only UUIDs never existed on production.
INSERT INTO private.iclub_ai_practice_receipts_v1(
 request_id,user_id,attempt_ref,locale,request_fingerprint,
 context_fingerprint,source_fingerprint,status,answer,answer_hash,
 provider_reported_microusd,received_at,expires_at)
VALUES
 ('11111111-1111-4111-8111-111111111101',
  '00000000-0000-4000-8000-000000000011',501,'ru',
  repeat('a',64),repeat('b',64),repeat('c',64),'acknowledged',
  'Synthetic old acknowledged AI answer: leave text untouched.',
  repeat('d',64),12000,
  clock_timestamp()-interval '50 hours',clock_timestamp()-interval '26 hours'),
 ('11111111-1111-4111-8111-111111111102',
  '00000000-0000-4000-8000-000000000011',502,'uz',
  repeat('a',64),repeat('b',64),repeat('c',64),'ready',
  'Synthetic newly eligible ready answer: redact only answer and hash.',
  repeat('d',64),13000,
  clock_timestamp()-interval '25 hours',clock_timestamp()-interval '1 hour'),
 ('11111111-1111-4111-8111-111111111103',
  '00000000-0000-4000-8000-000000000011',503,'en',
  repeat('a',64),repeat('b',64),repeat('c',64),'acknowledged',
  'Synthetic newly eligible acknowledged answer: redact only text.',
  repeat('d',64),14000,
  clock_timestamp()-interval '25 hours',clock_timestamp()-interval '1 hour'),
 ('11111111-1111-4111-8111-111111111104',
  '00000000-0000-4000-8000-000000000011',504,'en',
  repeat('a',64),repeat('b',64),repeat('c',64),'ready',
  'Synthetic unexpired answer: available until its normal deadline.',
  repeat('d',64),15000,
  clock_timestamp()-interval '22 hours',clock_timestamp()+interval '2 hours'),
 ('11111111-1111-4111-8111-111111111105',
  '00000000-0000-4000-8000-000000000011',505,'ru',
  repeat('a',64),repeat('b',64),repeat('c',64),'unknown',
  NULL,NULL,NULL,
  clock_timestamp()-interval '25 hours',clock_timestamp()-interval '1 hour');

-- Cutover is deliberately backdated ONLY in this rollback-only synthetic
-- test so a 25-hour-old new cohort can be simulated without waiting a day.
-- Actual future production activation must use the time of owner GO, not
-- a backdated value. Rows before that activation are never eligible.
UPDATE private.iclub_ai_practice_answer_retention24_control
SET enabled=true,cutover_at=clock_timestamp()-interval '26 hours'
WHERE singleton=1;

DO $strict$
DECLARE result jsonb; count_after integer;
BEGIN
 -- The strict policy cannot be satisfied by an ordinary scheduled UPDATE:
 -- before ANY paid request we must deny unproven answer storage.
 result:=public.iclub_ai_practice_strict24_admission_probe_v1();
 IF result->>'reason' IS DISTINCT FROM
      'strict_24h_physical_retention_not_proven'
    OR result->>'provider_allowed' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Unproved strict24 admitted a provider: %',result; END IF;

 -- Even a caller that skipped the admission preflight cannot persist a
 -- future new plaintext answer while strict policy is enabled.
 BEGIN
  INSERT INTO private.iclub_ai_practice_receipts_v1(
   request_id,user_id,attempt_ref,locale,request_fingerprint,
   context_fingerprint,source_fingerprint,status,answer,answer_hash,
   received_at,expires_at)
  VALUES(
   '11111111-1111-4111-8111-111111111106',
   '00000000-0000-4000-8000-000000000011',506,'en',
   repeat('a',64),repeat('b',64),repeat('c',64),'ready',
   'Synthetic forbidden new plaintext after strict admission cutoff.',
   repeat('d',64),clock_timestamp(),clock_timestamp()+interval '24 hours');
  RAISE EXCEPTION 'Unproved future plaintext was inserted';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
 SELECT count(*) INTO count_after
 FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id='11111111-1111-4111-8111-111111111106';
 IF count_after<>0 THEN RAISE EXCEPTION 'Forbidden plaintext receipt remains'; END IF;
 RAISE NOTICE 'PASS PC4 strict24 negative gate: provider admission denied and post-cutover plaintext refused';
END $strict$;

DO $test$
DECLARE
 out jsonb; n integer; before_count bigint; after_count bigint;
BEGIN
 SELECT count(*) INTO before_count FROM private.iclub_ai_practice_receipts_v1;
 out:=public.iclub_ai_practice_redact_expired24_service(1);
 IF out->>'ok' IS DISTINCT FROM 'true' OR
    (out->>'redacted_count')::integer<>1 OR
    out->>'provider_called' IS DISTINCT FROM 'false' OR
    out->>'financial_state_changed' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'First bounded redaction failed: %',out; END IF;
 out:=public.iclub_ai_practice_redact_expired24_service(100);
 IF out->>'ok' IS DISTINCT FROM 'true' OR
    (out->>'redacted_count')::integer<>1
 THEN RAISE EXCEPTION 'Second bounded redaction failed: %',out; END IF;
 out:=public.iclub_ai_practice_redact_expired24_service(100);
 IF (out->>'redacted_count')::integer<>0
 THEN RAISE EXCEPTION 'Repeat redaction not idempotent: %',out; END IF;

 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id IN (
  '11111111-1111-4111-8111-111111111102',
  '11111111-1111-4111-8111-111111111103')
 AND answer IS NULL AND answer_hash IS NULL
 AND answer_redacted_at>=expires_at AND
     answer_redacted_at>=received_at+interval '24 hours'
 AND status IN('ready','acknowledged')
 AND provider_reported_microusd IN (13000,14000);
 IF n<>2 THEN RAISE EXCEPTION 'Financial evidence lost or content not redacted'; END IF;

 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id='11111111-1111-4111-8111-111111111101'
 AND answer IS NOT NULL AND answer_hash IS NOT NULL
 AND answer_redacted_at IS NULL AND provider_reported_microusd=12000
 AND status='acknowledged';
 IF n<>1 THEN RAISE EXCEPTION 'Pre-cutover historical receipt modified'; END IF;

 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id='11111111-1111-4111-8111-111111111104'
 AND answer IS NOT NULL AND answer_redacted_at IS NULL AND status='ready';
 IF n<>1 THEN RAISE EXCEPTION 'Unexpired answer redacted'; END IF;
 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id='11111111-1111-4111-8111-111111111105'
 AND status='unknown' AND answer IS NULL AND answer_redacted_at IS NULL;
 IF n<>1 THEN RAISE EXCEPTION 'Unknown-cost receipt was modified'; END IF;
 SELECT count(*) INTO after_count FROM private.iclub_ai_practice_receipts_v1;
 IF before_count<>after_count
 THEN RAISE EXCEPTION 'Receipt history deleted'; END IF;

 -- Redacted text cannot be resurrected with its redaction marker retained.
 BEGIN
  UPDATE private.iclub_ai_practice_receipts_v1
  SET answer='Synthetic attempt to restore cleared text after expiry.'
  WHERE request_id='11111111-1111-4111-8111-111111111102';
  RAISE EXCEPTION 'Resurrection constraint was bypassed';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
 RAISE NOTICE 'PASS PC4 isolated 24h answer redaction: historical untouched, both new statuses redacted, unexpired preserved, no receipt deletion or financial mutation';
END $test$;

-- This entire rehearsal (including candidate DDL) is rolled back. It never
-- configures production cleanup or modifies real learners / money / history.
ROLLBACK;
