-- ISOLATED CI ONLY: snapshots of existing production quota/budget RPC definitions,
-- extracted READ-ONLY from pg_get_functiondef on 2026-10-27.
-- Do not apply this file to production. No user rows or credentials.
-- Before sourcing: synth PC1, PC4, PC3 test schemas must exist.
DO $guard$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'isolated PostgreSQL only'; END IF;
END $guard$;
ALTER TABLE private.iclub_ai_v21_freeform_budget_ledger
 ADD COLUMN session_fingerprint text,
 ADD COLUMN source_fingerprint text,
 ADD COLUMN source_version text,
 ADD COLUMN locale text,
 ADD COLUMN actual_microusd bigint,
 ADD COLUMN dispatched_at timestamptz,
 ADD COLUMN finished_at timestamptz;
ALTER TABLE private.iclub_ai_v21_freeform_quota_holds
 ADD COLUMN period_started_at timestamptz,
 ADD COLUMN finished_at timestamptz;
-- The deployed quota RPC also checks the existing delivery journal.
CREATE TABLE private.iclub_ai_v21_beta_deliveries(request_id uuid PRIMARY KEY);
CREATE TABLE private.iclub_ai_v21_beta_usage(
 user_id uuid PRIMARY KEY,started_at timestamptz NOT NULL,
 committed_count smallint NOT NULL DEFAULT 0,
 updated_at timestamptz NOT NULL DEFAULT now()
);
UPDATE private.iclub_ai_v21_beta_control
 SET approved_release='owner_beta' WHERE singleton=1;
UPDATE private.iclub_ai_practice_context_v1_control SET enabled=true WHERE singleton=1;
UPDATE private.iclub_ai_practice_receipt_v1_control SET enabled=true WHERE singleton=1;
UPDATE private.iclub_ai_practice_freeform_pc3_control SET enabled=true WHERE singleton=1;

CREATE OR REPLACE FUNCTION public.reserve_iclub_ai_v21_freeform_quota_v1(p_request_id uuid, p_user_id uuid, p_request_fingerprint text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE c private.iclub_ai_v21_beta_control%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 v_now timestamptz:=clock_timestamp();
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 THEN RETURN jsonb_build_object('allowed',false,'reason','invalid_quota_request'); END IF;
 -- Exact SAME lock order as existing prepared-Help RPC, so prepared(1)
 -- cannot arrive concurrently and overbook generated(3).
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none'
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id AND enabled AND consent_at IS NOT NULL
   AND consent_version='global_ai_beta_v21')
 THEN RETURN jsonb_build_object('allowed',false,'reason','beta_generation_disabled'); END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (SELECT 1 FROM public.practice_sessions_v4
 WHERE user_id=p_user_id AND status='in_progress')
 THEN RETURN jsonb_build_object('allowed',false,'reason','active_assessment'); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_quota_holds
   WHERE request_id=p_request_id)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_deliveries
   WHERE request_id=p_request_id)
 THEN RETURN jsonb_build_object('allowed',false,'reason','request_already_seen'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES(p_user_id,v_now,0) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
 WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at<=v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
  SET started_at=v_now,committed_count=0,updated_at=v_now
  WHERE user_id=p_user_id;
  u.started_at:=v_now;u.committed_count:=0;
 END IF;
 IF u.committed_count+3>3
 THEN RETURN jsonb_build_object('allowed',false,
   'reason','usage_exhausted','reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_freeform_quota_holds(
 request_id,user_id,request_fingerprint,period_started_at,weight,state)
 VALUES(p_request_id,p_user_id,p_request_fingerprint,u.started_at,3,'reserved');
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+3,updated_at=v_now WHERE user_id=p_user_id;
 RETURN jsonb_build_object('allowed',true,'weight',3);
END $function$;


CREATE OR REPLACE FUNCTION public.reserve_iclub_ai_v21_freeform_budget_v1(p_request_id uuid, p_user_id uuid, p_session_fingerprint text, p_request_fingerprint text, p_source_fingerprint text, p_source_version text, p_locale text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
END $function$;


CREATE OR REPLACE FUNCTION public.dispatch_iclub_ai_v21_freeform_budget_v1(p_request_id uuid, p_user_id uuid, p_session_fingerprint text, p_request_fingerprint text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
END $function$;


CREATE OR REPLACE FUNCTION public.settle_iclub_ai_v21_freeform_budget_v1(p_request_id uuid, p_user_id uuid, p_session_fingerprint text, p_request_fingerprint text, p_outcome text, p_actual_microusd bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
END $function$;


CREATE OR REPLACE FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(p_request_id uuid, p_user_id uuid, p_request_fingerprint text, p_outcome text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE h private.iclub_ai_v21_freeform_quota_holds%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 final_state text:=p_outcome;
 denied boolean:=false;
BEGIN
 PERFORM 1 FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 FOR UPDATE;
 SELECT * INTO h FROM private.iclub_ai_v21_freeform_quota_holds
  WHERE request_id=p_request_id FOR UPDATE;
 IF h.request_id IS NULL OR h.user_id IS DISTINCT FROM p_user_id
 OR h.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR h.state<>'reserved' OR p_outcome NOT IN('completed','released')
 THEN RETURN jsonb_build_object('ok',false,'reason','quota_settlement_denied'); END IF;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
 WHERE user_id=p_user_id FOR UPDATE;
 IF p_outcome='completed' AND (
  NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
   WHERE user_id=p_user_id AND enabled
   AND consent_version='global_ai_beta_v21' AND consent_at IS NOT NULL)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled
    AND NOT generation_enabled AND approved_release<>'none')
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND enabled AND owner_permitted)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger
   WHERE request_id=p_request_id AND user_id=p_user_id
   AND request_fingerprint=p_request_fingerprint AND state='charged')
  OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
  OR EXISTS(SELECT 1 FROM public.practice_sessions_v4
   WHERE user_id=p_user_id AND status='in_progress')
 ) THEN
  -- A charged provider response is still a real cost, but a revoked/blocked
  -- user must NOT receive or pay learner units for the model explanation.
  final_state:='released';denied:=true;
 END IF;
 IF final_state='released' AND u.started_at=h.period_started_at THEN
  UPDATE private.iclub_ai_v21_beta_usage SET
   committed_count=greatest(0,committed_count-3),
   updated_at=clock_timestamp()
  WHERE user_id=p_user_id;
 END IF;
 UPDATE private.iclub_ai_v21_freeform_quota_holds
 SET state=final_state,finished_at=clock_timestamp()
 WHERE request_id=p_request_id;
 IF denied THEN
  RETURN jsonb_build_object('ok',false,'released',true,
   'reason','generation_no_longer_authorized');
 END IF;
 RETURN jsonb_build_object('ok',true,'state',final_state);
END $function$;

