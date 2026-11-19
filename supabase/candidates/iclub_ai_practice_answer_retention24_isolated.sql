-- Issue #412. ONLY an isolated PostgreSQL 17 rehearsal of the approved
-- Practice PC4 answer-text retention decision. NOT a production migration.
-- The production migration, activation time, scheduler and treatment of
-- existing records each require separate owner approval.
-- Never touch user attempts, receipt identities, statuses, ledger, quotas,
-- audit evidence, answer source or request fingerprints.
DO $isolated$
BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: retention prototype allowed only in disposable PG17';
 END IF;
END $isolated$;

ALTER TABLE private.iclub_ai_practice_receipts_v1
  ADD COLUMN IF NOT EXISTS answer_redacted_at timestamptz;

-- The old CHECK required text in EVERY ready/acknowledged receipt forever.
-- Preserve that until explicit, irreversible redaction is recorded; the
-- paired answer_hash must be cleared with the text.
ALTER TABLE private.iclub_ai_practice_receipts_v1
  DROP CONSTRAINT IF EXISTS iclub_ai_practice_receipts_v1_check1;
ALTER TABLE private.iclub_ai_practice_receipts_v1
  ADD CONSTRAINT iclub_ai_practice_answer_retention24_v1_check
  CHECK (
    (answer_redacted_at IS NULL AND
      (status NOT IN ('ready','acknowledged') OR answer IS NOT NULL))
    OR
    (answer_redacted_at IS NOT NULL AND
      status IN ('ready','acknowledged') AND
      answer IS NULL AND answer_hash IS NULL AND
      answer_redacted_at >= expires_at AND
      answer_redacted_at >= received_at + interval '24 hours')
  );

-- Never turn on during DDL / feature rollout. When the owner separately
-- authorizes production activation, cutover_at must be the actual approval
-- activation time, not a backdated timestamp. All earlier rows stay untouched.
CREATE TABLE IF NOT EXISTS private.iclub_ai_practice_answer_retention24_control (
 singleton smallint PRIMARY KEY CHECK(singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 cutover_at timestamptz,
 CHECK (NOT enabled OR cutover_at IS NOT NULL)
);
INSERT INTO private.iclub_ai_practice_answer_retention24_control(singleton,enabled)
VALUES (1,false) ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.iclub_ai_practice_answer_retention24_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_practice_answer_retention24_control
 FROM PUBLIC,anon,authenticated;

-- Service-only, bounded, no answer/PII in output, no learner-visible route.
-- Does not delete receipts or anything in the money/quota ledgers.
-- Does not retry a provider request or touch uncertain-charge records.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_redact_expired24_service(
 p_batch_size integer DEFAULT 100
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO '' AS $fn$
DECLARE
 v_enabled boolean;
 v_cutover timestamptz;
 v_count integer:=0;
BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RETURN jsonb_build_object('ok',false,'reason','isolated_only'); END IF;
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role'
 THEN RETURN jsonb_build_object('ok',false,'reason','not_authorized'); END IF;
 IF p_batch_size IS NULL OR p_batch_size<1 OR p_batch_size>100
 THEN RETURN jsonb_build_object('ok',false,'reason','invalid_limit'); END IF;
 SELECT enabled,cutover_at INTO v_enabled,v_cutover
 FROM private.iclub_ai_practice_answer_retention24_control
 WHERE singleton=1;
 IF v_enabled IS DISTINCT FROM true OR v_cutover IS NULL
 THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;
 IF v_cutover>clock_timestamp()
 THEN RETURN jsonb_build_object('ok',false,'reason','not_started'); END IF;

 WITH due AS MATERIALIZED (
   SELECT r.request_id
   FROM private.iclub_ai_practice_receipts_v1 r
   WHERE r.received_at>=v_cutover
     AND r.answer IS NOT NULL
     AND r.answer_redacted_at IS NULL
     AND r.status IN ('ready','acknowledged')
     AND r.expires_at<=clock_timestamp()
     AND r.received_at + interval '24 hours'<=clock_timestamp()
   ORDER BY r.expires_at,r.request_id
   LIMIT p_batch_size FOR UPDATE OF r SKIP LOCKED
 )
 UPDATE private.iclub_ai_practice_receipts_v1 r
 SET answer=NULL, answer_hash=NULL, answer_redacted_at=clock_timestamp()
 FROM due WHERE r.request_id=due.request_id;
 GET DIAGNOSTICS v_count=ROW_COUNT;
 RETURN jsonb_build_object('ok',true,'action','answer_text_redaction_only',
   'redacted_count',v_count,'provider_called',false,
   'financial_state_changed',false);
END;
$fn$;

REVOKE ALL ON FUNCTION public.iclub_ai_practice_redact_expired24_service(integer)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_redact_expired24_service(integer)
 TO service_role;
