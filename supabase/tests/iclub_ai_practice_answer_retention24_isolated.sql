\set ON_ERROR_STOP on
-- Daily cleanup candidate, compiled and exercised ONLY in disposable PG17.
-- No real cron task, no production rows, no new paid request.
DO $guard$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: disposable PG17 fixture only'; END IF;
END $guard$;

BEGIN;
\ir ../candidates/iclub_ai_practice_answer_retention24_isolated.sql

DO $check$
DECLARE v_count integer;
BEGIN
 SELECT count(*) INTO v_count FROM cron.iclub_ai_daily_cleanup_schedule_test
 WHERE job_name='iclub-practice-ai-answer-expired-daily'
   AND schedule='0 3 * * *'
   AND command='SELECT private.iclub_ai_practice_clear_expired_answers_daily_v1();';
 IF v_count<>1 THEN RAISE EXCEPTION 'Daily 03:00 GMT job not registered in test'; END IF;
 IF has_function_privilege('authenticated',
   'private.iclub_ai_practice_clear_expired_answers_daily_v1()','EXECUTE')
 OR has_function_privilege('anon',
   'private.iclub_ai_practice_clear_expired_answers_daily_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'Browser or learner can invoke private cleanup'; END IF;
END $check$;

-- Fully synthetic: expired historical, recently expired, unexpired,
-- not-yet-24h even with a custom earlier expires_at, and unknown charge.
INSERT INTO private.iclub_ai_practice_receipts_v1(
 request_id,user_id,attempt_ref,locale,request_fingerprint,
 context_fingerprint,source_fingerprint,status,answer,answer_hash,
 provider_reported_microusd,received_at,expires_at)
VALUES
 ('11111111-1111-4111-8111-111111111101',
  '00000000-0000-4000-8000-000000000011',501,'ru',
  repeat('a',64),repeat('b',64),repeat('c',64),'acknowledged',
  'Historical synthetic acknowledged answer, should be cleaned when job runs.',
  repeat('d',64),12000,
  clock_timestamp()-interval '50 hours',clock_timestamp()-interval '26 hours'),
 ('11111111-1111-4111-8111-111111111102',
  '00000000-0000-4000-8000-000000000011',502,'uz',
  repeat('a',64),repeat('b',64),repeat('c',64),'ready',
  'Synthetic expired ready answer: remove the text, keep account history.',
  repeat('d',64),13000,
  clock_timestamp()-interval '25 hours',clock_timestamp()-interval '1 hour'),
 ('11111111-1111-4111-8111-111111111103',
  '00000000-0000-4000-8000-000000000011',503,'en',
  repeat('a',64),repeat('b',64),repeat('c',64),'acknowledged',
  'Synthetic expired acknowledged answer: remove text but retain receipt.',
  repeat('d',64),14000,
  clock_timestamp()-interval '25 hours',clock_timestamp()-interval '1 hour'),
 ('11111111-1111-4111-8111-111111111104',
  '00000000-0000-4000-8000-000000000011',504,'en',
  repeat('a',64),repeat('b',64),repeat('c',64),'ready',
  'Synthetic unexpired answer: retain for the full recovery window.',
  repeat('d',64),15000,
  clock_timestamp()-interval '22 hours',clock_timestamp()+interval '2 hours'),
 ('11111111-1111-4111-8111-111111111105',
  '00000000-0000-4000-8000-000000000011',505,'ru',
  repeat('a',64),repeat('b',64),repeat('c',64),'unknown',
  NULL,NULL,NULL,
  clock_timestamp()-interval '25 hours',clock_timestamp()-interval '1 hour'),
 ('11111111-1111-4111-8111-111111111106',
  '00000000-0000-4000-8000-000000000011',506,'en',
  repeat('a',64),repeat('b',64),repeat('c',64),'ready',
  'Synthetic less-than-24h answer with an abnormally early expiry.',
  repeat('d',64),15001,
  clock_timestamp()-interval '23 hours',clock_timestamp()-interval '1 hour');

DO $verify$
DECLARE v_count bigint; n integer; initial_rows bigint; final_rows bigint;
BEGIN
 SELECT count(*) INTO initial_rows FROM private.iclub_ai_practice_receipts_v1;
 v_count:=private.iclub_ai_practice_clear_expired_answers_daily_v1();
 IF v_count<>3 THEN
  RAISE EXCEPTION 'Expected 3 older-than-24h answers to clear, got %',v_count;
 END IF;
 IF private.iclub_ai_practice_clear_expired_answers_daily_v1()<>0
 THEN RAISE EXCEPTION 'Second daily run did not stay idempotent'; END IF;

 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id IN(
  '11111111-1111-4111-8111-111111111101',
  '11111111-1111-4111-8111-111111111102',
  '11111111-1111-4111-8111-111111111103')
 AND answer IS NULL AND answer_hash IS NULL
 AND answer_redacted_at IS NOT NULL AND
     answer_redacted_at>=received_at+interval '24 hours'
 AND status IN ('ready','acknowledged')
 AND provider_reported_microusd IN (12000,13000,14000);
 IF n<>3 THEN RAISE EXCEPTION 'Old or new text not cleared or costs/status lost'; END IF;

 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id IN(
  '11111111-1111-4111-8111-111111111104',
  '11111111-1111-4111-8111-111111111106')
 AND answer IS NOT NULL AND answer_hash IS NOT NULL
 AND answer_redacted_at IS NULL AND status='ready';
 IF n<>2 THEN RAISE EXCEPTION 'Premature cleanup of under-24h answer'; END IF;

 SELECT count(*) INTO n FROM private.iclub_ai_practice_receipts_v1
 WHERE request_id='11111111-1111-4111-8111-111111111105'
 AND status='unknown' AND answer IS NULL AND answer_redacted_at IS NULL;
 IF n<>1 THEN RAISE EXCEPTION 'Unknown-charge receipt was modified'; END IF;

 SELECT count(*) INTO final_rows FROM private.iclub_ai_practice_receipts_v1;
 IF final_rows<>initial_rows THEN RAISE EXCEPTION 'Receipt history deleted'; END IF;

 BEGIN
  UPDATE private.iclub_ai_practice_receipts_v1
  SET answer='Accidentally restored text is forbidden after redaction.'
  WHERE request_id='11111111-1111-4111-8111-111111111101';
  RAISE EXCEPTION 'Redacted response resurrected';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
 RAISE NOTICE 'PASS PC4 DAILY: one GMT 03:00 schedule, all >24h text+hash removed, unexpired preserved, no record/cost change, repeat=0';
END $verify$;

-- No synthetic data, constraints or cron schedules survive this transaction.
ROLLBACK;
