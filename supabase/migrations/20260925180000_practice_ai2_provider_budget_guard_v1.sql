-- AI-2 Practice provider budget/concurrency guard v1.
-- Additive and dormant-safe: no learner enablement and no academic-state mutation.

alter table private.practice_ai_policy
  add column if not exists max_daily_provider_cost_usd numeric(10,4) not null default 0.2500
    check (max_daily_provider_cost_usd > 0 and max_daily_provider_cost_usd <= 100),
  add column if not exists max_user_daily_provider_cost_usd numeric(10,4) not null default 0.0300
    check (max_user_daily_provider_cost_usd > 0 and max_user_daily_provider_cost_usd <= max_daily_provider_cost_usd),
  add column if not exists max_provider_request_cost_usd numeric(10,4) not null default 0.0100
    check (max_provider_request_cost_usd > 0 and max_provider_request_cost_usd <= max_user_daily_provider_cost_usd),
  add column if not exists max_concurrent_provider_calls integer not null default 2
    check (max_concurrent_provider_calls between 1 and 20),
  add column if not exists provider_lease_ttl_seconds integer not null default 45
    check (provider_lease_ttl_seconds between 10 and 180);

create table if not exists private.practice_ai_provider_leases (
  request_id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  reserved_cost_usd numeric(12,6) not null check (reserved_cost_usd > 0),
  actual_cost_usd numeric(12,6) null check (actual_cost_usd is null or actual_cost_usd >= 0),
  status text not null default 'active' check (status in ('active','completed','released','expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  finished_at timestamptz null,
  check (expires_at > created_at)
);

create index if not exists practice_ai_provider_leases_active_idx
  on private.practice_ai_provider_leases(status,expires_at)
  where status='active';

create index if not exists practice_ai_provider_leases_user_day_idx
  on private.practice_ai_provider_leases(user_id,created_at);

alter table private.practice_ai_provider_leases enable row level security;
revoke all on private.practice_ai_provider_leases from public,anon,authenticated;
grant all on private.practice_ai_provider_leases to service_role;

create or replace function public.reserve_practice_ai_provider_call_service_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_estimated_cost_usd numeric
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_policy private.practice_ai_policy%rowtype;
  v_existing private.practice_ai_provider_leases%rowtype;
  v_active_count integer:=0;
  v_user_calls integer:=0;
  v_global_cost numeric:=0;
  v_user_cost numeric:=0;
  v_ttl interval;
begin
  if p_request_id is null or p_user_id is null then
    return jsonb_build_object('allowed',false,'reason','invalid_reservation_identity');
  end if;

  if p_estimated_cost_usd is null or p_estimated_cost_usd<=0 then
    return jsonb_build_object('allowed',false,'reason','invalid_estimated_cost');
  end if;

  -- Separate global admission lock for Practice AI provider traffic.
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
  set status='expired',
      actual_cost_usd=coalesce(actual_cost_usd,0),
      finished_at=coalesce(finished_at,now())
  where status='active'
    and expires_at<=now();

  if p_estimated_cost_usd>v_policy.max_provider_request_cost_usd then
    return jsonb_build_object(
      'allowed',false,'reason','request_cost_limit',
      'max_provider_request_cost_usd',v_policy.max_provider_request_cost_usd
    );
  end if;

  select count(*) into v_user_calls
  from private.practice_ai_provider_leases
  where user_id=p_user_id
    and created_at>=date_trunc('day',now());

  if v_user_calls>=v_policy.max_daily_requests then
    return jsonb_build_object(
      'allowed',false,'reason','daily_request_limit',
      'max_daily_requests',v_policy.max_daily_requests
    );
  end if;

  select count(*) into v_active_count
  from private.practice_ai_provider_leases
  where status='active'
    and expires_at>now();

  if v_active_count>=v_policy.max_concurrent_provider_calls then
    return jsonb_build_object(
      'allowed',false,'reason','provider_concurrency_limit',
      'max_concurrent_provider_calls',v_policy.max_concurrent_provider_calls
    );
  end if;

  select coalesce(sum(
    case
      when status='active' and expires_at>now() then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0) into v_global_cost
  from private.practice_ai_provider_leases
  where created_at>=date_trunc('day',now());

  if v_global_cost+p_estimated_cost_usd>v_policy.max_daily_provider_cost_usd then
    return jsonb_build_object(
      'allowed',false,'reason','global_daily_cost_limit',
      'used_or_reserved_cost_usd',v_global_cost,
      'max_daily_provider_cost_usd',v_policy.max_daily_provider_cost_usd
    );
  end if;

  select coalesce(sum(
    case
      when status='active' and expires_at>now() then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0) into v_user_cost
  from private.practice_ai_provider_leases
  where user_id=p_user_id
    and created_at>=date_trunc('day',now());

  if v_user_cost+p_estimated_cost_usd>v_policy.max_user_daily_provider_cost_usd then
    return jsonb_build_object(
      'allowed',false,'reason','user_daily_cost_limit',
      'used_or_reserved_cost_usd',v_user_cost,
      'max_user_daily_provider_cost_usd',v_policy.max_user_daily_provider_cost_usd
    );
  end if;

  v_ttl:=make_interval(secs=>v_policy.provider_lease_ttl_seconds);

  insert into private.practice_ai_provider_leases(
    request_id,user_id,reserved_cost_usd,status,created_at,expires_at
  ) values (
    p_request_id,p_user_id,p_estimated_cost_usd,'active',now(),now()+v_ttl
  );

  return jsonb_build_object(
    'allowed',true,
    'request_id',p_request_id,
    'reserved_cost_usd',p_estimated_cost_usd,
    'lease_ttl_seconds',v_policy.provider_lease_ttl_seconds,
    'max_concurrent_provider_calls',v_policy.max_concurrent_provider_calls
  );
end;
$$;

revoke all on function public.reserve_practice_ai_provider_call_service_v1(uuid,uuid,numeric)
  from public,anon,authenticated;
grant execute on function public.reserve_practice_ai_provider_call_service_v1(uuid,uuid,numeric)
  to service_role;

create or replace function public.finalize_practice_ai_provider_call_service_v1(
  p_request_id uuid,
  p_status text,
  p_actual_cost_usd numeric default 0
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_row private.practice_ai_provider_leases%rowtype;
  v_status text;
  v_actual numeric:=greatest(coalesce(p_actual_cost_usd,0),0);
begin
  if p_request_id is null then
    return jsonb_build_object('ok',false,'reason','invalid_request_id');
  end if;

  v_status:=case when p_status='completed' then 'completed' else 'released' end;

  select * into v_row
  from private.practice_ai_provider_leases
  where request_id=p_request_id
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','reservation_missing');
  end if;

  if v_row.status<>'active' then
    return jsonb_build_object('ok',false,'reason','reservation_not_active','status',v_row.status);
  end if;

  update private.practice_ai_provider_leases
  set status=v_status,
      actual_cost_usd=v_actual,
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
$$;

revoke all on function public.finalize_practice_ai_provider_call_service_v1(uuid,text,numeric)
  from public,anon,authenticated;
grant execute on function public.finalize_practice_ai_provider_call_service_v1(uuid,text,numeric)
  to service_role;

create or replace function public.get_practice_ai_operational_snapshot_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select jsonb_build_object(
    'policy',jsonb_build_object(
      'rollout_state',p.rollout_state,
      'enabled',p.enabled,
      'generation_enabled',p.generation_enabled,
      'kill_switch',p.kill_switch,
      'policy_version',p.policy_version,
      'prompt_version',p.prompt_version,
      'retrieval_policy_version',p.retrieval_policy_version,
      'response_schema_version',p.response_schema_version,
      'max_daily_requests',p.max_daily_requests,
      'max_daily_provider_cost_usd',p.max_daily_provider_cost_usd,
      'max_user_daily_provider_cost_usd',p.max_user_daily_provider_cost_usd,
      'max_provider_request_cost_usd',p.max_provider_request_cost_usd,
      'max_concurrent_provider_calls',p.max_concurrent_provider_calls,
      'provider_lease_ttl_seconds',p.provider_lease_ttl_seconds
    ),
    'active_entitlements',(
      select count(*) from private.practice_ai_entitlements e
      where e.entitlement_status='active'
        and (e.valid_from is null or e.valid_from<=now())
        and (e.valid_until is null or e.valid_until>now())
    ),
    'runtime_source_cards',(
      select count(*) from private.practice_ai_source_cards c
      where c.approval_status='approved'
        and c.is_runtime_allowed
        and c.rights_status<>'blocked'
    ),
    'provider_active_leases',(
      select count(*) from private.practice_ai_provider_leases l
      where l.status='active' and l.expires_at>now()
    ),
    'provider_cost_today_usd',(
      select coalesce(sum(
        case
          when l.status='active' and l.expires_at>now() then l.reserved_cost_usd
          else coalesce(l.actual_cost_usd,0)
        end
      ),0)
      from private.practice_ai_provider_leases l
      where l.created_at>=date_trunc('day',now())
    ),
    'audit_24h',coalesce((
      select jsonb_object_agg(q.mode,q.cnt)
      from (
        select a.mode,count(*)::int cnt
        from private.practice_ai_audit a
        where a.created_at>=now()-interval '24 hours'
        group by a.mode
      ) q
    ),'{}'::jsonb)
  )
  from private.practice_ai_policy p
  where p.id=1;
$$;

revoke all on function public.get_practice_ai_operational_snapshot_v1()
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_operational_snapshot_v1()
  to service_role;
