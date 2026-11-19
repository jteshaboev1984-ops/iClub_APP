-- Source-controlled copy of already APPLIED Supabase migration
-- Supabase project: mmmduffgpvwjdpruzikw; migration 20261119131140
-- Owner explicitly approved production activation and clean-up of two old
-- expired Practice PC4 answers on 2026-11-19, without merging this PR.
-- Original executable statements were applied using Supabase apply_migration
-- from candidate blob 471de39655e90fb7092140f6a9316ef7026935ce. Keep this version aligned with
-- the deployed migration record; DO NOT reapply manually.
-- Issue #412: daily cleanup of Practice PC4 AI answer TEXT older than 24h.
-- REVIEW CANDIDATE ONLY. Not a migration; do not run on live Supabase
-- without separate owner approval to deploy the schema, daily cron and
-- cleanup of pre-existing expired answer text.
--
-- Recovery eligibility remains 24h; daily cleanup runs at 03:00 GMT
-- (= 08:00 Asia/Tashkent). Physical text can remain ~24-48h (or more
-- if the job fails). PostgreSQL WAL/backups can preserve old bytes.
-- This is the owner's simplified daily-cleanup policy, not a claim of
-- exact 24h physical deletion.
--
-- Keep each receipt row, owner, UUID, status, attempt history, and every
-- financial/quota ledger record. Never clear uncertain-charge evidence.

ALTER TABLE private.iclub_ai_practice_receipts_v1
 ADD COLUMN IF NOT EXISTS answer_redacted_at timestamptz;

-- Existing live constraint requires answer for all ready/acknowledged rows;
-- allow those same statuses once their expired response has been redacted.
ALTER TABLE private.iclub_ai_practice_receipts_v1
 DROP CONSTRAINT IF EXISTS iclub_ai_practice_receipts_v1_check1;
ALTER TABLE private.iclub_ai_practice_receipts_v1
 ADD CONSTRAINT iclub_ai_practice_receipts_v1_check1
 CHECK (
   (answer_redacted_at IS NULL AND
     (status NOT IN ('ready','acknowledged') OR answer IS NOT NULL))
   OR
   (answer_redacted_at IS NOT NULL AND
     status IN ('ready','acknowledged')
     AND answer IS NULL AND answer_hash IS NULL
     AND answer_redacted_at >= expires_at
     AND answer_redacted_at >= received_at + interval '24 hours')
 );

-- Internal scheduled operation only. No input, no exposed learner data.
-- A single UPDATE covers ALL overdue answer-bearing ready/acknowledged
-- receipts, including pre-existing expired answers IF separately deployed.
-- It cannot change receipt state, attempt, user, billed amount or ledgers.
CREATE OR REPLACE FUNCTION private.iclub_ai_practice_clear_expired_answers_daily_v1()
RETURNS bigint LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO '' AS $fn$
DECLARE v_redacted bigint;
BEGIN
 UPDATE private.iclub_ai_practice_receipts_v1 AS r
 SET answer=NULL, answer_hash=NULL, answer_redacted_at=clock_timestamp()
 WHERE r.status IN ('ready','acknowledged')
   AND r.answer IS NOT NULL
   AND r.expires_at <= statement_timestamp()
   AND r.received_at + interval '24 hours' <= statement_timestamp();
 GET DIAGNOSTICS v_redacted = ROW_COUNT;
 RETURN v_redacted;
END;
$fn$;

REVOKE ALL ON FUNCTION
 private.iclub_ai_practice_clear_expired_answers_daily_v1()
 FROM PUBLIC, anon, authenticated;

-- Supabase already has pg_cron enabled. Named schedule updates an
-- existing same-named job rather than creating a second recurring task.
-- Cron timezone is GMT in the live project; run once each day at
-- 03:00 GMT / 08:00 Tashkent. No new service or paid model needed.
SELECT cron.schedule(
 'iclub-practice-ai-answer-expired-daily',
 '0 3 * * *',
 $job$SELECT private.iclub_ai_practice_clear_expired_answers_daily_v1();$job$
);
