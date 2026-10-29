-- Finance safety v1: no production changes until separately approved.
-- Aggregate cross-route emergency spend cap starts OFF, amounts not guessed.
-- Never rewrite historical payments, scores or student progress.
BEGIN;
CREATE TABLE IF NOT EXISTS private.iclub_ai_all_route_spend_control_v1 (
 singleton integer PRIMARY KEY DEFAULT 1 CHECK (singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 max_day_microusd bigint,
 max_lifetime_microusd bigint,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT iclub_ai_all_route_positive_limits_v1 CHECK (
 NOT enabled OR (max_day_microusd>0 AND max_lifetime_microusd>=max_day_microusd))
);
INSERT INTO private.iclub_ai_all_route_spend_control_v1(singleton,enabled) VALUES(1,false) ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.iclub_ai_all_route_spend_control_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_all_route_spend_control_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT,UPDATE ON private.iclub_ai_all_route_spend_control_v1 TO service_role;
ALTER TABLE private.exam_prep_ai_provider_leases ADD COLUMN IF NOT EXISTS dispatched_at timestamptz;
ALTER TABLE private.practice_ai_provider_leases ADD COLUMN IF NOT EXISTS dispatched_at timestamptz;
ALTER TABLE private.exam_prep_ai_provider_leases DROP CONSTRAINT exam_prep_ai_provider_leases_status_check;
ALTER TABLE private.exam_prep_ai_provider_leases ADD CONSTRAINT exam_prep_ai_provider_leases_status_check CHECK(status IN('active','completed','released','expired','unknown'));
ALTER TABLE private.practice_ai_provider_leases DROP CONSTRAINT practice_ai_provider_leases_status_check;
ALTER TABLE private.practice_ai_provider_leases ADD CONSTRAINT practice_ai_provider_leases_status_check CHECK(status IN('active','completed','released','expired','unknown'));

CREATE OR REPLACE FUNCTION private.iclub_ai_all_route_budget_allowed_v1(p_new_hold_microusd bigint)
RETURNS boolean LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $body$
DECLARE c private.iclub_ai_all_route_spend_control_v1%rowtype;
 lifetime_cost numeric;today_cost numeric;
 utc_day timestamptz:=date_trunc('day',now() at time zone 'UTC') at time zone 'UTC';
BEGIN
 IF p_new_hold_microusd IS NULL OR p_new_hold_microusd<=0 THEN RETURN false;END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('iclub_ai_all_route_spend_v1',20261029));
 SELECT * INTO c FROM private.iclub_ai_all_route_spend_control_v1 WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND THEN RETURN false;END IF;
 IF NOT c.enabled THEN RETURN true;END IF;
 IF c.max_day_microusd IS NULL OR c.max_day_microusd<=0
  OR c.max_lifetime_microusd IS NULL OR c.max_lifetime_microusd<c.max_day_microusd THEN RETURN false;END IF;
 SELECT coalesce(sum(cost),0),coalesce(sum(cost) FILTER(WHERE reserved_at>=utc_day),0)
 INTO lifetime_cost,today_cost
 FROM (
 SELECT CASE WHEN status='released' THEN 0
  WHEN status='completed' THEN coalesce(actual_cost_usd,reserved_cost_usd)*1000000
  ELSE reserved_cost_usd*1000000 END AS cost,created_at reserved_at
 FROM private.exam_prep_ai_provider_leases
 UNION ALL SELECT CASE WHEN status='released' THEN 0
  WHEN status='completed' THEN coalesce(actual_cost_usd,reserved_cost_usd)*1000000
  ELSE reserved_cost_usd*1000000 END,created_at
 FROM private.practice_ai_provider_leases
 UNION ALL SELECT CASE WHEN state='no_charge' THEN 0
  WHEN state='charged' THEN coalesce(actual_microusd,held_microusd)
  ELSE held_microusd END,reserved_at
 FROM private.iclub_ai_v21_freeform_budget_ledger
 UNION ALL SELECT CASE WHEN state='no_charge' THEN 0
  WHEN state='charged' THEN coalesce(actual_microusd,hold_microusd)
  ELSE hold_microusd END,reserved_at
 FROM private.iclub_ai_paid_canary_ledger_v1
 ) liabilities;
 RETURN lifetime_cost+p_new_hold_microusd<=c.max_lifetime_microusd
   AND today_cost+p_new_hold_microusd<=c.max_day_microusd;
END;
$body$;
REVOKE ALL ON FUNCTION private.iclub_ai_all_route_budget_allowed_v1(bigint) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_ai_all_route_budget_allowed_v1(bigint) TO service_role;

CREATE OR REPLACE FUNCTION public.mark_exam_prep_ai_provider_dispatched_service_v1(p_request_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $body$
DECLARE r private.exam_prep_ai_provider_leases%rowtype;
BEGIN
 IF p_request_id IS NULL THEN RETURN jsonb_build_object('ok',false,'reason','invalid_id');END IF;
 SELECT * INTO r FROM private.exam_prep_ai_provider_leases WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND OR r.status<>'active' OR r.expires_at<=now() OR r.dispatched_at IS NOT NULL
 THEN RETURN jsonb_build_object('ok',false,'reason','dispatch_unavailable');END IF;
 UPDATE private.exam_prep_ai_provider_leases SET dispatched_at=now() WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true);
END;
$body$;
REVOKE ALL ON FUNCTION public.mark_exam_prep_ai_provider_dispatched_service_v1(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mark_exam_prep_ai_provider_dispatched_service_v1(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.mark_practice_ai_provider_dispatched_service_v1(p_request_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $body$
DECLARE r private.practice_ai_provider_leases%rowtype;
BEGIN
 IF p_request_id IS NULL THEN RETURN jsonb_build_object('ok',false,'reason','invalid_id');END IF;
 SELECT * INTO r FROM private.practice_ai_provider_leases WHERE request_id=p_request_id FOR UPDATE;
 IF NOT FOUND OR r.status<>'active' OR r.expires_at<=now() OR r.dispatched_at IS NOT NULL
 THEN RETURN jsonb_build_object('ok',false,'reason','dispatch_unavailable');END IF;
 UPDATE private.practice_ai_provider_leases SET dispatched_at=now() WHERE request_id=p_request_id;
 RETURN jsonb_build_object('ok',true);
END;
$body$;
REVOKE ALL ON FUNCTION public.mark_practice_ai_provider_dispatched_service_v1(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mark_practice_ai_provider_dispatched_service_v1(uuid) TO service_role;
CREATE OR REPLACE FUNCTION public.reserve_exam_prep_ai_provider_call_service_v1(p_request_id uuid, p_user_id uuid, p_estimated_cost_usd numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_policy private.exam_prep_ai_policy%rowtype;
  v_existing private.exam_prep_ai_provider_leases%rowtype;
  v_active_count integer := 0;
  v_user_calls integer := 0;
  v_global_cost numeric := 0;
  v_user_cost numeric := 0;
  v_ttl interval;
begin
  if p_request_id is null or p_user_id is null then
    return jsonb_build_object('allowed',false,'reason','invalid_reservation_identity');
  end if;

  if p_estimated_cost_usd is null or p_estimated_cost_usd <= 0 then
    return jsonb_build_object('allowed',false,'reason','invalid_estimated_cost');
  end if;

  -- Single global admission lock. Provider traffic is intentionally small in AI-1,
  -- and this prevents cross-instance races in concurrency and spend checks.
  perform pg_advisory_xact_lock(202609251);

  select * into v_policy
  from private.exam_prep_ai_policy
  where id=1
  for update;

  if not found then
    return jsonb_build_object('allowed',false,'reason','policy_missing');
  end if;

  select * into v_existing
  from private.exam_prep_ai_provider_leases
  where request_id=p_request_id;

  if found then
    return jsonb_build_object('allowed',false,'reason','duplicate_request');
  end if;

  update private.exam_prep_ai_provider_leases
  set status='unknown',
      actual_cost_usd=NULL,
      finished_at=coalesce(finished_at,now())
  where status='active'
    and expires_at <= now();

  if p_estimated_cost_usd > v_policy.max_provider_request_cost_usd then
    return jsonb_build_object(
      'allowed',false,
      'reason','request_cost_limit',
      'max_request_cost_usd',v_policy.max_provider_request_cost_usd
    );
  end if;

  select count(*) into v_user_calls
  from private.exam_prep_ai_provider_leases
  where user_id=p_user_id
    and created_at >= date_trunc('day',now());

  if v_user_calls >= v_policy.max_daily_requests then
    return jsonb_build_object(
      'allowed',false,
      'reason','daily_request_limit',
      'max_daily_requests',v_policy.max_daily_requests
    );
  end if;

  select count(*) into v_active_count
  from private.exam_prep_ai_provider_leases
  where status='active'
    and expires_at > now();

  if v_active_count >= v_policy.max_concurrent_provider_calls then
    return jsonb_build_object(
      'allowed',false,
      'reason','provider_concurrency_limit',
      'max_concurrent_provider_calls',v_policy.max_concurrent_provider_calls
    );
  end if;

  select coalesce(sum(
    case
      when status in ('active','unknown') then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0) into v_global_cost
  from private.exam_prep_ai_provider_leases
  where created_at >= date_trunc('day',now());

  if v_global_cost + p_estimated_cost_usd > v_policy.max_daily_provider_cost_usd then
    return jsonb_build_object(
      'allowed',false,
      'reason','global_daily_cost_limit',
      'used_or_reserved_cost_usd',v_global_cost,
      'max_daily_provider_cost_usd',v_policy.max_daily_provider_cost_usd
    );
  end if;

  select coalesce(sum(
    case
      when status in ('active','unknown') then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0) into v_user_cost
  from private.exam_prep_ai_provider_leases
  where user_id=p_user_id
    and created_at >= date_trunc('day',now());

  if v_user_cost + p_estimated_cost_usd > v_policy.max_user_daily_provider_cost_usd then
    return jsonb_build_object(
      'allowed',false,
      'reason','user_daily_cost_limit',
      'used_or_reserved_cost_usd',v_user_cost,
      'max_user_daily_provider_cost_usd',v_policy.max_user_daily_provider_cost_usd
    );
  end if;

  v_ttl := make_interval(secs => v_policy.provider_lease_ttl_seconds);

  IF NOT private.iclub_ai_all_route_budget_allowed_v1(ceil(p_estimated_cost_usd*1000000)::bigint) THEN
    RETURN jsonb_build_object('allowed',false,'reason','shared_provider_budget_exhausted');
  END IF;

  insert into private.exam_prep_ai_provider_leases(
    request_id,user_id,reserved_cost_usd,status,created_at,expires_at
  ) values (
    p_request_id,p_user_id,p_estimated_cost_usd,'active',now(),now()+v_ttl
  );

  return jsonb_build_object(
    'allowed',true,
    'reason',null,
    'request_id',p_request_id,
    'reserved_cost_usd',p_estimated_cost_usd,
    'lease_ttl_seconds',v_policy.provider_lease_ttl_seconds,
    'max_concurrent_provider_calls',v_policy.max_concurrent_provider_calls
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.reserve_practice_ai_provider_call_service_v1(p_request_id uuid, p_user_id uuid, p_estimated_cost_usd numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_policy private.practice_ai_policy%rowtype;
  v_existing private.practice_ai_provider_leases%rowtype;
  v_active_count integer:=0;
  v_user_calls integer:=0;
  v_global_cost numeric:=0;
  v_user_cost numeric:=0;
begin
  if p_request_id is null or p_user_id is null then
    return jsonb_build_object('allowed',false,'reason','invalid_reservation_identity');
  end if;

  if p_estimated_cost_usd is null or p_estimated_cost_usd<=0 then
    return jsonb_build_object('allowed',false,'reason','invalid_estimated_cost');
  end if;

  perform pg_advisory_xact_lock(202609252);

  select * into v_policy
  from private.practice_ai_policy
  where id=1
  for update;

  if not found then
    return jsonb_build_object('allowed',false,'reason','policy_missing');
  end if;

  select * into v_existing
  from private.practice_ai_provider_leases
  where request_id=p_request_id;

  if found then
    return jsonb_build_object('allowed',false,'reason','duplicate_request');
  end if;

  update private.practice_ai_provider_leases
  set status='unknown',
      actual_cost_usd=NULL,
      finished_at=coalesce(finished_at,now())
  where status='active' and expires_at<=now();

  if p_estimated_cost_usd>v_policy.max_provider_request_cost_usd then
    return jsonb_build_object('allowed',false,'reason','request_cost_limit');
  end if;

  select count(*) into v_user_calls
  from private.practice_ai_provider_leases
  where user_id=p_user_id
    and created_at>=date_trunc('day',now());

  if v_user_calls>=v_policy.max_daily_requests then
    return jsonb_build_object('allowed',false,'reason','daily_request_limit');
  end if;

  select count(*) into v_active_count
  from private.practice_ai_provider_leases
  where status='active' and expires_at>now();

  if v_active_count>=v_policy.max_concurrent_provider_calls then
    return jsonb_build_object('allowed',false,'reason','provider_concurrency_limit');
  end if;

  select coalesce(sum(
    case when status in ('active','unknown')
      then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0)
  into v_global_cost
  from private.practice_ai_provider_leases
  where created_at>=date_trunc('day',now());

  if v_global_cost+p_estimated_cost_usd>v_policy.max_daily_provider_cost_usd then
    return jsonb_build_object('allowed',false,'reason','global_daily_cost_limit');
  end if;

  select coalesce(sum(
    case when status in ('active','unknown')
      then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0)
  into v_user_cost
  from private.practice_ai_provider_leases
  where user_id=p_user_id
    and created_at>=date_trunc('day',now());

  if v_user_cost+p_estimated_cost_usd>v_policy.max_user_daily_provider_cost_usd then
    return jsonb_build_object('allowed',false,'reason','user_daily_cost_limit');
  end if;

  IF NOT private.iclub_ai_all_route_budget_allowed_v1(ceil(p_estimated_cost_usd*1000000)::bigint) THEN
    RETURN jsonb_build_object('allowed',false,'reason','shared_provider_budget_exhausted');
  END IF;

  insert into private.practice_ai_provider_leases(
    request_id,user_id,reserved_cost_usd,status,created_at,expires_at
  ) values(
    p_request_id,p_user_id,p_estimated_cost_usd,'active',now(),
    now()+make_interval(secs=>v_policy.provider_lease_ttl_seconds)
  );

  return jsonb_build_object(
    'allowed',true,
    'request_id',p_request_id,
    'reserved_cost_usd',p_estimated_cost_usd,
    'lease_ttl_seconds',v_policy.provider_lease_ttl_seconds
  );
end;
$function$;

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
 IF NOT private.iclub_ai_all_route_budget_allowed_v1(c.maximum_per_request_microusd) THEN
  RETURN jsonb_build_object('allowed',false,'reason','shared_provider_budget_exhausted'); END IF;
 INSERT INTO private.iclub_ai_v21_freeform_budget_ledger
 (request_id,user_id,session_fingerprint,request_fingerprint,source_fingerprint,
  source_version,locale,state,held_microusd)
 VALUES(p_request_id,p_user_id,p_session_fingerprint,p_request_fingerprint,
  p_source_fingerprint,p_source_version,p_locale,'reserved',
  c.maximum_per_request_microusd);
 RETURN jsonb_build_object('allowed',true,'held_microusd',50000);
END $function$;

CREATE OR REPLACE FUNCTION public.reserve_iclub_ai_paid_canary_v1(p_request_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE c private.iclub_ai_paid_canary_control_v1%rowtype;
 total_used bigint;today_used bigint;actor_today_used bigint;active_count bigint;
 today_utc timestamptz;
BEGIN
 IF coalesce(auth.role(), nullif(current_setting('request.jwt.claim.role',true),'')) IS DISTINCT FROM 'service_role' THEN
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
 IF NOT private.iclub_ai_all_route_budget_allowed_v1(c.per_call_hold_microusd) THEN
  RETURN jsonb_build_object('allowed',false,'reason','shared_provider_budget_exhausted'); END IF;
 INSERT INTO private.iclub_ai_paid_canary_ledger_v1(request_id,hold_microusd)
 VALUES(p_request_id,c.per_call_hold_microusd);
 RETURN jsonb_build_object('allowed',true,'hold_microusd',c.per_call_hold_microusd);
EXCEPTION WHEN OTHERS THEN
 RETURN jsonb_build_object('allowed',false,'reason','money_unavailable');
END;
$function$;

CREATE OR REPLACE FUNCTION public.finalize_exam_prep_ai_provider_call_service_v1(p_request_id uuid, p_status text, p_actual_cost_usd numeric DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_row private.exam_prep_ai_provider_leases%rowtype;
  v_status text;
  v_actual numeric := greatest(coalesce(p_actual_cost_usd,0),0);
begin
  if p_request_id is null then
    return jsonb_build_object('ok',false,'reason','invalid_request_id');
  end if;

  IF p_status NOT IN ('completed','released','unknown') THEN
    RETURN jsonb_build_object('ok',false,'reason','invalid_settlement_status');
  END IF;
  v_status:=p_status;

  select * into v_row
  from private.exam_prep_ai_provider_leases
  where request_id=p_request_id
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','reservation_missing');
  end if;

  if v_row.status NOT IN ('active','unknown') then
    return jsonb_build_object('ok',false,'reason','reservation_not_active','status',v_row.status);
  end if;
  -- The previous Edge version can falsely claim a free pre-dispatch release.
  -- Refuse all zero-cost release claims until separately proven by a versioned
  -- service-only no-dispatch protocol; never silently erase a possible bill.
  IF v_status='released' THEN
    RETURN jsonb_build_object('ok',false,'reason','provider_cost_unresolved');
  END IF;

  update private.exam_prep_ai_provider_leases
  set status=v_status,
      actual_cost_usd=CASE WHEN v_status='completed' THEN v_actual WHEN v_status='released' THEN 0 ELSE NULL END,
      finished_at=now()
  where request_id=p_request_id;

  return jsonb_build_object(
    'ok',true,
    'request_id',p_request_id,
    'status',v_status,
    'reserved_cost_usd',v_row.reserved_cost_usd,
    'actual_cost_usd',v_actual
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.finalize_practice_ai_provider_call_service_v1(p_request_id uuid, p_status text, p_actual_cost_usd numeric DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_row private.practice_ai_provider_leases%rowtype;
  v_status text;
  v_actual numeric:=greatest(coalesce(p_actual_cost_usd,0),0);
begin
  if p_request_id is null then
    return jsonb_build_object('ok',false,'reason','invalid_request_id');
  end if;

  IF p_status NOT IN ('completed','released','unknown') THEN
    RETURN jsonb_build_object('ok',false,'reason','invalid_settlement_status');
  END IF;
  v_status:=p_status;

  select * into v_row
  from private.practice_ai_provider_leases
  where request_id=p_request_id
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','reservation_missing');
  end if;

  if v_row.status NOT IN ('active','unknown') then
    return jsonb_build_object('ok',false,'reason','reservation_not_active','status',v_row.status);
  end if;
  -- The previous Edge version can falsely claim a free pre-dispatch release.
  -- Refuse all zero-cost release claims until separately proven by a versioned
  -- service-only no-dispatch protocol; never silently erase a possible bill.
  IF v_status='released' THEN
    RETURN jsonb_build_object('ok',false,'reason','provider_cost_unresolved');
  END IF;

  update private.practice_ai_provider_leases
  set status=v_status,
      actual_cost_usd=CASE WHEN v_status='completed' THEN v_actual WHEN v_status='released' THEN 0 ELSE NULL END,
      finished_at=now()
  where request_id=p_request_id;

  return jsonb_build_object(
    'ok',true,
    'request_id',p_request_id,
    'status',v_status,
    'reserved_cost_usd',v_row.reserved_cost_usd,
    'actual_cost_usd',v_actual
  );
end;
$function$;

COMMIT;
