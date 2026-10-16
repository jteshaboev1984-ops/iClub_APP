-- Additive, operator-only iClub AI funded pilot. NO existing learner tables.
-- This candidate MUST pass isolated PG tests before any live migration.
CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE IF NOT EXISTS private.iclub_ai_paid_canary_control_v1 (
 singleton smallint PRIMARY KEY DEFAULT 1 CHECK(singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 max_lifetime_microusd bigint NOT NULL DEFAULT 1000000 CHECK(max_lifetime_microusd BETWEEN 0 AND 1000000),
 max_day_microusd bigint NOT NULL DEFAULT 500000 CHECK(max_day_microusd BETWEEN 0 AND 500000),
 max_actor_day_microusd bigint NOT NULL DEFAULT 50000 CHECK(max_actor_day_microusd BETWEEN 0 AND 50000),
 per_call_hold_microusd bigint NOT NULL DEFAULT 10000 CHECK(per_call_hold_microusd BETWEEN 1 AND 10000),
 max_inflight smallint NOT NULL DEFAULT 2 CHECK(max_inflight BETWEEN 1 AND 2),
 created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(max_actor_day_microusd<=max_day_microusd),
 CHECK(max_day_microusd<=max_lifetime_microusd),
 CHECK(per_call_hold_microusd<=max_actor_day_microusd)
);
INSERT INTO private.iclub_ai_paid_canary_control_v1(singleton,enabled)
VALUES(1,false) ON CONFLICT(singleton) DO NOTHING;
CREATE TABLE IF NOT EXISTS private.iclub_ai_paid_canary_ledger_v1 (
 request_id uuid PRIMARY KEY,
 actor text NOT NULL DEFAULT 'pilot_operator' CHECK(actor='pilot_operator'),
 state text NOT NULL DEFAULT 'reserved'
   CHECK(state IN('reserved','dispatched','charged','unknown','no_charge')),
 hold_microusd bigint NOT NULL CHECK(hold_microusd BETWEEN 1 AND 10000),
 actual_microusd bigint,
 reserved_at timestamptz NOT NULL DEFAULT now(),
 dispatched_at timestamptz,finished_at timestamptz,
 CHECK(actual_microusd IS NULL OR actual_microusd BETWEEN 0 AND hold_microusd),
 CHECK((state='charged' AND actual_microusd IS NOT NULL) OR
       (state<>'charged' AND actual_microusd IS NULL))
);
REVOKE ALL ON private.iclub_ai_paid_canary_control_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_ai_paid_canary_ledger_v1 FROM PUBLIC,anon,authenticated,service_role;
ALTER TABLE private.iclub_ai_paid_canary_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_ai_paid_canary_ledger_v1 ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.reserve_iclub_ai_paid_canary_v1(p_request_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $reserve$
DECLARE c private.iclub_ai_paid_canary_control_v1%rowtype;
 total_used bigint;today_used bigint;actor_today_used bigint;active_count bigint;
 today_utc timestamptz;
BEGIN
 IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('allowed',false,'reason','not_authorized');END IF;
 IF p_request_id IS NULL THEN
  RETURN jsonb_build_object('allowed',false,'reason','invalid_request');END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_paid_canary_money_v1',12026));
 IF EXISTS(SELECT 1 FROM private.iclub_ai_paid_canary_ledger_v1 WHERE request_id=p_request_id) THEN
  RETURN jsonb_build_object('allowed',false,'reason','request_already_seen');END IF;
 SELECT * INTO c FROM private.iclub_ai_paid_canary_control_v1 WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT coalesce(c.enabled,false) THEN
  RETURN jsonb_build_object('allowed',false,'reason','disabled');END IF;
 today_utc:=date_trunc('day',now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
 SELECT
  coalesce(sum(CASE WHEN state='charged' THEN actual_microusd WHEN state='no_charge'
    THEN 0 ELSE hold_microusd END),0)::bigint,
  coalesce(sum(CASE WHEN state='charged' THEN actual_microusd WHEN state='no_charge'
    THEN 0 ELSE hold_microusd END) FILTER(WHERE reserved_at>=today_utc),0)::bigint,
  coalesce(sum(CASE WHEN state='charged' THEN actual_microusd WHEN state='no_charge'
    THEN 0 ELSE hold_microusd END) FILTER(WHERE reserved_at>=today_utc AND actor='pilot_operator'),0)::bigint,
  count(*) FILTER(WHERE state IN('reserved','dispatched'))
 INTO total_used,today_used,actor_today_used,active_count
 FROM private.iclub_ai_paid_canary_ledger_v1;
 IF total_used>c.max_lifetime_microusd-c.per_call_hold_microusd THEN
  RETURN jsonb_build_object('allowed',false,'reason','lifetime_limit');END IF;
 IF today_used>c.max_day_microusd-c.per_call_hold_microusd OR
    actor_today_used>c.max_actor_day_microusd-c.per_call_hold_microusd THEN
  RETURN jsonb_build_object('allowed',false,'reason','daily_limit');END IF;
 IF active_count>=c.max_inflight THEN
  RETURN jsonb_build_object('allowed',false,'reason','concurrency_limit');END IF;
 INSERT INTO private.iclub_ai_paid_canary_ledger_v1(request_id,hold_microusd)
 VALUES(p_request_id,c.per_call_hold_microusd);
 RETURN jsonb_build_object('allowed',true,'hold_microusd',c.per_call_hold_microusd);
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('allowed',false,'reason','money_unavailable');
END;
$reserve$;

CREATE OR REPLACE FUNCTION public.dispatch_iclub_ai_paid_canary_v1(p_request_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $dispatch$
DECLARE c private.iclub_ai_paid_canary_control_v1%rowtype;
BEGIN
 IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('allowed',false,'reason','not_authorized');END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_paid_canary_money_v1',12026));
 SELECT * INTO c FROM private.iclub_ai_paid_canary_control_v1 WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT coalesce(c.enabled,false) THEN
  RETURN jsonb_build_object('allowed',false,'reason','disabled');END IF;
 UPDATE private.iclub_ai_paid_canary_ledger_v1
 SET state='dispatched',dispatched_at=now()
 WHERE request_id=p_request_id AND state='reserved';
 IF NOT FOUND THEN RETURN jsonb_build_object('allowed',false,'reason','dispatch_unavailable');END IF;
 RETURN jsonb_build_object('allowed',true);
END;
$dispatch$;

CREATE OR REPLACE FUNCTION public.finish_iclub_ai_paid_canary_v1(
 p_request_id uuid,p_outcome text,p_actual_microusd bigint DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $finish$
DECLARE e private.iclub_ai_paid_canary_ledger_v1%rowtype;
BEGIN
 IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');END IF;
 IF p_outcome IS NULL OR p_outcome NOT IN('no_charge','unknown','charged') THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_outcome');END IF;
 SELECT * INTO e FROM private.iclub_ai_paid_canary_ledger_v1
 WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'reason','not_found');END IF;
 IF e.state IN('no_charge','charged','unknown') THEN
  RETURN jsonb_build_object('ok',e.state=p_outcome AND
   (e.state<>'charged' OR e.actual_microusd IS NOT DISTINCT FROM p_actual_microusd),
   'duplicate',true);END IF;
 IF (p_outcome='no_charge' AND e.state<>'reserved') OR
    (p_outcome IN('charged','unknown') AND e.state<>'dispatched') OR
    (p_outcome='charged' AND (p_actual_microusd IS NULL OR
     p_actual_microusd<0 OR p_actual_microusd>e.hold_microusd)) OR
    (p_outcome<>'charged' AND p_actual_microusd IS NOT NULL) THEN
  RETURN jsonb_build_object('ok',false,'reason','unsafe_financial_settlement');END IF;
 UPDATE private.iclub_ai_paid_canary_ledger_v1 SET state=p_outcome,
 actual_microusd=CASE WHEN p_outcome='charged' THEN p_actual_microusd ELSE NULL END,
 finished_at=now() WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true,'duplicate',false);
END;
$finish$;

CREATE OR REPLACE FUNCTION public.status_iclub_ai_paid_canary_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $status$
DECLARE c private.iclub_ai_paid_canary_control_v1%rowtype;
 lifetime bigint;daily bigint;inflight bigint;today_utc timestamptz;
BEGIN
 IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role' THEN
  RETURN jsonb_build_object('ok',false,'reason','not_authorized');END IF;
 SELECT * INTO c FROM private.iclub_ai_paid_canary_control_v1 WHERE singleton=1;
 today_utc:=date_trunc('day',now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
 SELECT coalesce(sum(CASE WHEN state='charged' THEN actual_microusd
     WHEN state='no_charge' THEN 0 ELSE hold_microusd END),0)::bigint,
   coalesce(sum(CASE WHEN state='charged' THEN actual_microusd
     WHEN state='no_charge' THEN 0 ELSE hold_microusd END)
     FILTER(WHERE reserved_at>=today_utc),0)::bigint,
   count(*) FILTER(WHERE state IN('reserved','dispatched'))
 INTO lifetime,daily,inflight FROM private.iclub_ai_paid_canary_ledger_v1;
 RETURN jsonb_build_object('ok',true,'enabled',coalesce(c.enabled,false),
  'lifetime_microusd',lifetime,'day_microusd',daily,'inflight',inflight,
  'max_lifetime_microusd',c.max_lifetime_microusd,
  'max_day_microusd',c.max_day_microusd,
  'max_actor_day_microusd',c.max_actor_day_microusd,
  'max_per_call_microusd',c.per_call_hold_microusd,
  'max_inflight',c.max_inflight);
END;
$status$;
REVOKE ALL ON FUNCTION public.reserve_iclub_ai_paid_canary_v1(uuid) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.dispatch_iclub_ai_paid_canary_v1(uuid) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.finish_iclub_ai_paid_canary_v1(uuid,text,bigint) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.status_iclub_ai_paid_canary_v1() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_iclub_ai_paid_canary_v1(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.dispatch_iclub_ai_paid_canary_v1(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.finish_iclub_ai_paid_canary_v1(uuid,text,bigint) TO service_role;
GRANT EXECUTE ON FUNCTION public.status_iclub_ai_paid_canary_v1() TO service_role;
