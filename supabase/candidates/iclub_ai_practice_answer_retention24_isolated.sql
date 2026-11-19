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

-- Strict 24h requirement: the scheduled redactor below is NOT proof of
-- physical erasure. PostgreSQL retains previous tuple versions and WAL; backups
-- can preserve earlier text. Until a separately reviewed non-plaintext
-- recovery design meets the rule, activation of strict mode must fail CLOSED.
-- This isolated-only gate is a demonstration contract, not a live admission
-- integration. The existing provider caller MUST check before any budget hold
-- or model dispatch; installing a write guard alone would be too late.
CREATE OR REPLACE FUNCTION public.iclub_ai_practice_strict24_admission_probe_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO '' AS $admit$
DECLARE v_on boolean;
BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RETURN jsonb_build_object('ok',false,'reason','isolated_only'); END IF;
 IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role'
 THEN RETURN jsonb_build_object('ok',false,'reason','not_authorized'); END IF;
 SELECT enabled INTO v_on
 FROM private.iclub_ai_practice_answer_retention24_control WHERE singleton=1;
 IF v_on IS DISTINCT FROM true
 THEN RETURN jsonb_build_object('ok',false,'reason','not_enabled'); END IF;
 -- There is no verified ephemeral key store / no-plaintext recovery
 -- implementation yet. Never mistake a cron success for one.
 RETURN jsonb_build_object('ok',false,
   'reason','strict_24h_physical_retention_not_proven',
   'provider_allowed',false);
END;
$admit$;
REVOKE ALL ON FUNCTION public.iclub_ai_practice_strict24_admission_probe_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_ai_practice_strict24_admission_probe_v1()
 TO service_role;

-- Additional last-resort protection in the disposable database: when the
-- owner-specified future cutoff is enabled, NO new plaintext AI answer may be
-- persisted. Historical/pre-cutover rows remain untouched, existing TEXT
-- redaction (answer->NULL) is still allowed. A future recovery design
-- must replace this prototype *only after* strict 24h proof is accepted.
CREATE OR REPLACE FUNCTION private.iclub_ai_practice_strict24_plaintext_guard_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO '' AS $guard$
DECLARE v_on boolean; v_cutover timestamptz;
BEGIN
 SELECT enabled,cutover_at INTO v_on,v_cutover
 FROM private.iclub_ai_practice_answer_retention24_control WHERE singleton=1;
 IF v_on IS TRUE AND v_cutover IS NOT NULL AND
    NEW.received_at>=v_cutover AND NEW.answer IS NOT NULL AND
    (TG_OP='INSERT' OR OLD.answer IS DISTINCT FROM NEW.answer)
 THEN
   RAISE EXCEPTION 'strict24 plaintext persistence not authorized'
     USING ERRCODE='23514';
 END IF;
 RETURN NEW;
END;
$guard$;
REVOKE ALL ON FUNCTION private.iclub_ai_practice_strict24_plaintext_guard_v1()
 FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS iclub_ai_practice_strict24_plaintext_guard_v1
 ON private.iclub_ai_practice_receipts_v1;
CREATE TRIGGER iclub_ai_practice_strict24_plaintext_guard_v1
 BEFORE INSERT OR UPDATE ON private.iclub_ai_practice_receipts_v1
 FOR EACH ROW EXECUTE FUNCTION
 private.iclub_ai_practice_strict24_plaintext_guard_v1();

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
