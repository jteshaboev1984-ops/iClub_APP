-- iClub Global AI v2.1: OWNER-AUTHORIZED $5 TOTAL beta model exposure.
-- QA-reviewed migration candidate ONLY. No live generation, no cost by installation.
-- Every reserve/dispatch/settle requires trusted Edge service_role, not browser.
-- In the first migration the feature is DISABLED and no paid call is possible.
DO $p0$
BEGIN
 IF to_regclass('private.iclub_ai_v21_freeform_budget_control') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_freeform_budget_ledger') IS NOT NULL
 OR NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled AND NOT generation_enabled)
 OR NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND enabled AND NOT provider_enabled)
 THEN RAISE EXCEPTION 'Refuse to replace funded pilot or change existing beta'; END IF;
END $p0$;

CREATE TABLE private.iclub_ai_v21_freeform_budget_control(
 singleton smallint PRIMARY KEY CHECK(singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 owner_permitted boolean NOT NULL DEFAULT true,
 include_free_beta boolean NOT NULL DEFAULT true,
 maximum_lifetime_microusd bigint NOT NULL DEFAULT 5000000
   CHECK(maximum_lifetime_microusd=5000000),
 maximum_per_request_microusd bigint NOT NULL DEFAULT 50000
   CHECK(maximum_per_request_microusd=50000),
 maximum_per_learner_microusd bigint NOT NULL DEFAULT 750000
   CHECK(maximum_per_learner_microusd=750000),
 maximum_parallel smallint NOT NULL DEFAULT 2
   CHECK(maximum_parallel BETWEEN 0 AND 2),
 model text NOT NULL DEFAULT 'gpt-5.4-mini'
   CHECK(model='gpt-5.4-mini'),
 input_microusd_per_token numeric(12,6) NOT NULL DEFAULT 0.750000
   CHECK(input_microusd_per_token=0.750000),
 output_microusd_per_token numeric(12,6) NOT NULL DEFAULT 4.500000
   CHECK(output_microusd_per_token=4.500000),
 output_token_cap smallint NOT NULL DEFAULT 384
   CHECK(output_token_cap=384),
 approval_ref text NOT NULL DEFAULT 'owner_chat_beta_free_5usd_20261021',
 approved_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO private.iclub_ai_v21_freeform_budget_control(singleton) VALUES (1);
ALTER TABLE private.iclub_ai_v21_freeform_budget_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_freeform_budget_control
 FROM PUBLIC,anon,authenticated,service_role;

CREATE TABLE private.iclub_ai_v21_freeform_budget_ledger(
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 session_fingerprint text NOT NULL
  CHECK(session_fingerprint ~ '^[a-f0-9]{64}$'),
 request_fingerprint text NOT NULL
  CHECK(request_fingerprint ~ '^[a-f0-9]{64}$'),
 source_fingerprint text NOT NULL
  CHECK(source_fingerprint ~ '^[a-f0-9]{64}$'),
 source_version text NOT NULL CHECK(length(source_version) BETWEEN 2 AND 120),
 locale text NOT NULL CHECK(locale IN('en','ru','uz')),
 state text NOT NULL CHECK(state IN
 ('reserved','dispatched','charged','unknown','no_charge')),
 held_microusd bigint NOT NULL CHECK(held_microusd=50000),
 actual_microusd bigint
  CHECK(actual_microusd IS NULL OR actual_microusd BETWEEN 0 AND 50000),
 reserved_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 dispatched_at timestamptz,
 finished_at timestamptz,
 CHECK((state='charged' AND actual_microusd IS NOT NULL)
    OR (state<>'charged' AND actual_microusd IS NULL)),
 CHECK(state<>'dispatched' OR dispatched_at IS NOT NULL),
 CHECK(state NOT IN ('charged','unknown','no_charge') OR finished_at IS NOT NULL)
);
CREATE INDEX iclub_freeform_budget_ledger_owner_idx
 ON private.iclub_ai_v21_freeform_budget_ledger(user_id,state);
ALTER TABLE private.iclub_ai_v21_freeform_budget_ledger ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_freeform_budget_ledger
 FROM PUBLIC,anon,authenticated,service_role;

-- One advisory lock serializes ALL monetary decisions, including concurrent workers.
-- A repeat UUID is a DENY, not a second model call.
CREATE FUNCTION public.reserve_iclub_ai_v21_freeform_budget_v1(
 p_request_id uuid,p_user_id uuid,
 p_session_fingerprint text,p_request_fingerprint text,
 p_source_fingerprint text,p_source_version text,p_locale text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE c private.iclub_ai_v21_freeform_budget_control%rowtype;
 b private.iclub_ai_v21_beta_control%rowtype;
 exposure bigint;owner_exposure bigint;inflight bigint;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_session_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 OR p_source_fingerprint !~ '^[a-f0-9]{64}$'
 OR length(p_source_version) NOT BETWEEN 2 AND 120
 OR p_locale NOT IN ('en','ru','uz')
 THEN RETURN jsonb_build_object('allowed',false,'reason','invalid_budget_request'); END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_ai_v21_freeform_paid_total',504));
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger
     WHERE request_id=p_request_id)
 THEN RETURN jsonb_build_object('allowed',false,'reason','request_already_seen'); END IF;
 SELECT * INTO c FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 FOR UPDATE;
 SELECT * INTO b FROM private.iclub_ai_v21_beta_control WHERE singleton=1;
 IF c.enabled IS DISTINCT FROM true OR c.owner_permitted IS DISTINCT FROM true
  OR c.include_free_beta IS DISTINCT FROM true
  OR b.beta_enabled IS DISTINCT FROM true
  OR b.prepared_enabled IS DISTINCT FROM true
  OR b.generation_enabled IS DISTINCT FROM false
  OR c.model<>'gpt-5.4-mini'
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
     WHERE user_id=p_user_id AND enabled AND consent_at IS NOT NULL
       AND consent_version='global_ai_beta_v21')
 THEN RETURN jsonb_build_object('allowed',false,'reason','beta_generation_disabled'); END IF;
 SELECT COALESCE(SUM(CASE WHEN state='charged'
    THEN actual_microusd ELSE held_microusd END),0),
    COALESCE(SUM(CASE WHEN user_id=p_user_id THEN
    CASE WHEN state='charged' THEN actual_microusd ELSE held_microusd END
      ELSE 0 END),0),
    COUNT(*) FILTER(WHERE state IN ('reserved','dispatched'))
 INTO exposure,owner_exposure,inflight
 FROM private.iclub_ai_v21_freeform_budget_ledger
 WHERE state<>'no_charge';
 IF exposure+c.maximum_per_request_microusd>c.maximum_lifetime_microusd
  OR owner_exposure+c.maximum_per_request_microusd>c.maximum_per_learner_microusd
  OR inflight>=c.maximum_parallel
 THEN RETURN jsonb_build_object('allowed',false,'reason','pilot_budget_exhausted'); END IF;
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 (request_id,user_id,session_fingerprint,request_fingerprint,source_fingerprint,
  source_version,locale,state,held_microusd)
 VALUES(p_request_id,p_user_id,p_session_fingerprint,p_request_fingerprint,
  p_source_fingerprint,p_source_version,p_locale,'reserved',
  c.maximum_per_request_microusd);
 RETURN jsonb_build_object('allowed',true,'held_microusd',50000);
END $fn$;

-- Dispatch may occur once, and only for the exact immutable request context.
CREATE FUNCTION public.dispatch_iclub_ai_v21_freeform_budget_v1(
 p_request_id uuid,p_user_id uuid,
 p_session_fingerprint text,p_request_fingerprint text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE l private.iclub_ai_v21_freeform_budget_ledger%rowtype;
 c private.iclub_ai_v21_freeform_budget_control%rowtype;
 b private.iclub_ai_v21_beta_control%rowtype;
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_ai_v21_freeform_paid_total',504));
 SELECT * INTO l FROM private.iclub_ai_v21_freeform_budget_ledger
  WHERE request_id=p_request_id FOR UPDATE;
 SELECT * INTO c FROM private.iclub_ai_v21_freeform_budget_control WHERE singleton=1;
 SELECT * INTO b FROM private.iclub_ai_v21_beta_control WHERE singleton=1;
 IF l.request_id IS NULL OR l.state<>'reserved'
 OR l.user_id IS DISTINCT FROM p_user_id
 OR l.session_fingerprint IS DISTINCT FROM p_session_fingerprint
 OR l.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR c.enabled IS DISTINCT FROM true
 OR b.beta_enabled IS DISTINCT FROM true
 OR b.prepared_enabled IS DISTINCT FROM true
 OR b.generation_enabled IS DISTINCT FROM false
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
   WHERE user_id=p_user_id AND enabled AND consent_at IS NOT NULL
   AND consent_version='global_ai_beta_v21')
 THEN RETURN jsonb_build_object('allowed',false,'reason','dispatch_denied'); END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_ledger
 SET state='dispatched',dispatched_at=clock_timestamp()
 WHERE request_id=p_request_id;
 RETURN jsonb_build_object('allowed',true);
END $fn$;

-- Unknown HTTP/provider result is FULL liability, never reset automatically.
-- After a successful provider response, caller supplies full-price actual
-- input/output token calculation as integer microUSD (no caching discount).
CREATE FUNCTION public.settle_iclub_ai_v21_freeform_budget_v1(
 p_request_id uuid,p_user_id uuid,
 p_session_fingerprint text,p_request_fingerprint text,
 p_outcome text,p_actual_microusd bigint DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE l private.iclub_ai_v21_freeform_budget_ledger%rowtype;
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_ai_v21_freeform_paid_total',504));
 SELECT * INTO l FROM private.iclub_ai_v21_freeform_budget_ledger
  WHERE request_id=p_request_id FOR UPDATE;
 IF l.request_id IS NULL
 OR l.user_id IS DISTINCT FROM p_user_id
 OR l.session_fingerprint IS DISTINCT FROM p_session_fingerprint
 OR l.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR p_outcome NOT IN ('no_charge','charged','unknown')
 THEN RETURN jsonb_build_object('ok',false,'reason','settlement_denied'); END IF;
 IF p_outcome='no_charge' THEN
  IF l.state<>'reserved' OR p_actual_microusd IS NOT NULL
  THEN RETURN jsonb_build_object('ok',false,'reason','possible_provider_liability'); END IF;
 ELSIF p_outcome='charged' THEN
  IF l.state<>'dispatched' OR p_actual_microusd IS NULL OR
   p_actual_microusd NOT BETWEEN 0 AND l.held_microusd
  THEN RETURN jsonb_build_object('ok',false,'reason','charge_not_verified'); END IF;
 ELSE
  IF l.state NOT IN ('reserved','dispatched') OR p_actual_microusd IS NOT NULL
  THEN RETURN jsonb_build_object('ok',false,'reason','unknown_not_allowed'); END IF;
 END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_ledger SET
 state=p_outcome,actual_microusd=p_actual_microusd,
 finished_at=clock_timestamp()
 WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true,'state',p_outcome);
END $fn$;

REVOKE ALL ON FUNCTION public.reserve_iclub_ai_v21_freeform_budget_v1(
 uuid,uuid,text,text,text,text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.dispatch_iclub_ai_v21_freeform_budget_v1(
 uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.settle_iclub_ai_v21_freeform_budget_v1(
 uuid,uuid,text,text,text,bigint) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_iclub_ai_v21_freeform_budget_v1(
 uuid,uuid,text,text,text,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.dispatch_iclub_ai_v21_freeform_budget_v1(
 uuid,uuid,text,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.settle_iclub_ai_v21_freeform_budget_v1(
 uuid,uuid,text,text,text,bigint) TO service_role;

-- Still OFF. Independently release student Edge and guarded finance switch.
DO $post$
BEGIN
 IF (SELECT enabled FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1) IS DISTINCT FROM false
 OR (SELECT count(*) FROM private.iclub_ai_v21_freeform_budget_ledger)<>0
 OR (SELECT generation_enabled FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Budget gate installation enabled model unexpectedly'; END IF;
END $post$;
