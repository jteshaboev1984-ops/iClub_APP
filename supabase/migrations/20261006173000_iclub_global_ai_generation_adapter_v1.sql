-- iClub Global AI generated Mathematics adapter v1.
-- Additive and dormant by default. No runtime flags are enabled here.
--
-- Uses the same proven provider-budget pattern as Exam Prep AI, but with a
-- separate Global AI budget pool. Tariff usage accounting remains independent:
-- failed/rejected generation spends no learner allowance even if provider cost occurred.

begin;

alter table private.iclub_global_ai_gateway_audit
  add column if not exists source_card_keys text[] not null default '{}'::text[],
  add column if not exists safety_flags text[] not null default '{}'::text[],
  add column if not exists model_provider text null,
  add column if not exists model_id text null,
  add column if not exists input_tokens integer null
    check (input_tokens is null or input_tokens>=0),
  add column if not exists output_tokens integer null
    check (output_tokens is null or output_tokens>=0),
  add column if not exists estimated_cost_usd numeric(12,6) null
    check (estimated_cost_usd is null or estimated_cost_usd>=0);

create table if not exists private.iclub_global_ai_provider_policy (
  id smallint primary key default 1 check (id=1),
  policy_version text not null default 'global_ai_provider_v1',
  max_daily_provider_cost_usd numeric(10,4) not null default 0.5000
    check (max_daily_provider_cost_usd>0 and max_daily_provider_cost_usd<=100),
  max_user_daily_provider_cost_usd numeric(10,4) not null default 0.0500
    check (max_user_daily_provider_cost_usd>0 and max_user_daily_provider_cost_usd<=max_daily_provider_cost_usd),
  max_provider_request_cost_usd numeric(10,4) not null default 0.0100
    check (max_provider_request_cost_usd>0 and max_provider_request_cost_usd<=max_user_daily_provider_cost_usd),
  max_user_daily_provider_calls integer not null default 20
    check (max_user_daily_provider_calls between 1 and 500),
  max_concurrent_provider_calls integer not null default 2
    check (max_concurrent_provider_calls between 1 and 20),
  provider_lease_ttl_seconds integer not null default 45
    check (provider_lease_ttl_seconds between 10 and 180),
  updated_at timestamptz not null default now()
);

insert into private.iclub_global_ai_provider_policy(id)
values(1)
on conflict(id) do nothing;

create table if not exists private.iclub_global_ai_provider_leases (
  request_id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  subject_key text not null,
  scope_code text not null,
  adapter_code text not null,
  reserved_cost_usd numeric(12,6) not null check (reserved_cost_usd>0),
  actual_cost_usd numeric(12,6) null check (actual_cost_usd is null or actual_cost_usd>=0),
  status text not null default 'active'
    check (status in ('active','completed','released','expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  finished_at timestamptz null,
  check (expires_at>created_at)
);

create index if not exists iclub_global_ai_provider_active_idx
  on private.iclub_global_ai_provider_leases(status,expires_at)
  where status='active';

create index if not exists iclub_global_ai_provider_user_day_idx
  on private.iclub_global_ai_provider_leases(user_id,created_at);

alter table private.iclub_global_ai_provider_policy enable row level security;
alter table private.iclub_global_ai_provider_leases enable row level security;
revoke all on private.iclub_global_ai_provider_policy from public,anon,authenticated;
revoke all on private.iclub_global_ai_provider_leases from public,anon,authenticated;
grant all on private.iclub_global_ai_provider_policy to service_role;
grant all on private.iclub_global_ai_provider_leases to service_role;

create or replace function public.reserve_iclub_global_ai_provider_call_service_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_subject_key text,
  p_scope_code text,
  p_adapter_code text,
  p_estimated_cost_usd numeric
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $reserve$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_readiness private.iclub_ai_subject_readiness%rowtype;
  v_policy private.iclub_global_ai_provider_policy%rowtype;
  v_caps jsonb;
  v_existing private.iclub_global_ai_provider_leases%rowtype;
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

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or v_runtime.kill_switch
     or not v_runtime.gateway_enabled
     or not v_runtime.generation_enabled then
    return jsonb_build_object('allowed',false,'reason','generation_disabled');
  end if;

  if not private.iclub_rollout_allows_user_v1(
    p_user_id,v_runtime.global_ai_rollout_mode
  ) then
    return jsonb_build_object('allowed',false,'reason','rollout_unavailable');
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'allowed',false,
      'reason',coalesce(v_caps->>'reason','subscription_unavailable')
    );
  end if;

  if coalesce((v_caps->>'ai_generation_entitled')::boolean,false) is not true then
    return jsonb_build_object('allowed',false,'reason','generation_upgrade_required');
  end if;

  if private.iclub_ai_has_active_protected_assessment_v1(p_user_id) then
    return jsonb_build_object('allowed',false,'reason','active_assessment');
  end if;

  select * into v_readiness
  from private.iclub_ai_subject_readiness
  where subject_key=p_subject_key
    and scope_code=p_scope_code;

  if not found
     or v_readiness.readiness<>'full'
     or not v_readiness.generation_allowed
     or coalesce(v_readiness.adapter_code,'')<>coalesce(p_adapter_code,'') then
    return jsonb_build_object('allowed',false,'reason','subject_generation_not_ready');
  end if;

  if p_subject_key<>'mathematics'
     or p_scope_code<>'exam_prep'
     or p_adapter_code<>'math_exam_prep_v1' then
    return jsonb_build_object('allowed',false,'reason','generation_adapter_not_promoted');
  end if;

  -- One short admission lock protects cost and concurrency limits across Edge instances.
  perform pg_advisory_xact_lock(hashtextextended('iclub-global-ai-provider-v1',0));

  select * into v_policy
  from private.iclub_global_ai_provider_policy
  where id=1
  for update;

  if not found then
    return jsonb_build_object('allowed',false,'reason','provider_policy_missing');
  end if;

  select * into v_existing
  from private.iclub_global_ai_provider_leases
  where request_id=p_request_id;

  if found then
    return jsonb_build_object('allowed',false,'reason','duplicate_request');
  end if;

  update private.iclub_global_ai_provider_leases
  set status='expired',
      actual_cost_usd=coalesce(actual_cost_usd,0),
      finished_at=coalesce(finished_at,now())
  where status='active'
    and expires_at<=now();

  if p_estimated_cost_usd>v_policy.max_provider_request_cost_usd then
    return jsonb_build_object(
      'allowed',false,'reason','request_cost_limit',
      'max_request_cost_usd',v_policy.max_provider_request_cost_usd
    );
  end if;

  select count(*) into v_user_calls
  from private.iclub_global_ai_provider_leases
  where user_id=p_user_id
    and created_at>=date_trunc('day',now());

  if v_user_calls>=v_policy.max_user_daily_provider_calls then
    return jsonb_build_object(
      'allowed',false,'reason','provider_daily_request_limit'
    );
  end if;

  select count(*) into v_active_count
  from private.iclub_global_ai_provider_leases
  where status='active'
    and expires_at>now();

  if v_active_count>=v_policy.max_concurrent_provider_calls then
    return jsonb_build_object(
      'allowed',false,'reason','provider_concurrency_limit'
    );
  end if;

  select coalesce(sum(
    case
      when status='active' and expires_at>now() then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0)
  into v_global_cost
  from private.iclub_global_ai_provider_leases
  where created_at>=date_trunc('day',now());

  if v_global_cost+p_estimated_cost_usd>v_policy.max_daily_provider_cost_usd then
    return jsonb_build_object('allowed',false,'reason','global_daily_cost_limit');
  end if;

  select coalesce(sum(
    case
      when status='active' and expires_at>now() then reserved_cost_usd
      else coalesce(actual_cost_usd,0)
    end
  ),0)
  into v_user_cost
  from private.iclub_global_ai_provider_leases
  where user_id=p_user_id
    and created_at>=date_trunc('day',now());

  if v_user_cost+p_estimated_cost_usd>v_policy.max_user_daily_provider_cost_usd then
    return jsonb_build_object('allowed',false,'reason','user_daily_cost_limit');
  end if;

  v_ttl:=make_interval(secs=>v_policy.provider_lease_ttl_seconds);

  insert into private.iclub_global_ai_provider_leases(
    request_id,user_id,subject_key,scope_code,adapter_code,
    reserved_cost_usd,status,created_at,expires_at
  ) values (
    p_request_id,p_user_id,p_subject_key,p_scope_code,p_adapter_code,
    p_estimated_cost_usd,'active',now(),now()+v_ttl
  );

  return jsonb_build_object(
    'allowed',true,
    'reason',null,
    'request_id',p_request_id,
    'lease_ttl_seconds',v_policy.provider_lease_ttl_seconds
  );
end;
$reserve$;

revoke all on function public.reserve_iclub_global_ai_provider_call_service_v1(
  uuid,uuid,text,text,text,numeric
) from public,anon,authenticated;
grant execute on function public.reserve_iclub_global_ai_provider_call_service_v1(
  uuid,uuid,text,text,text,numeric
) to service_role;

create or replace function public.finalize_iclub_global_ai_provider_call_service_v1(
  p_request_id uuid,
  p_status text,
  p_actual_cost_usd numeric default 0
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $finalize$
declare
  v_row private.iclub_global_ai_provider_leases%rowtype;
  v_status text;
  v_actual numeric:=greatest(coalesce(p_actual_cost_usd,0),0);
begin
  if p_request_id is null then
    return jsonb_build_object('ok',false,'reason','invalid_request_id');
  end if;

  v_status:=case when p_status='completed' then 'completed' else 'released' end;

  select * into v_row
  from private.iclub_global_ai_provider_leases
  where request_id=p_request_id
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','reservation_missing');
  end if;

  if v_row.status<>'active' then
    return jsonb_build_object(
      'ok',false,'reason','reservation_not_active','status',v_row.status
    );
  end if;

  update private.iclub_global_ai_provider_leases
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
$finalize$;

revoke all on function public.finalize_iclub_global_ai_provider_call_service_v1(
  uuid,text,numeric
) from public,anon,authenticated;
grant execute on function public.finalize_iclub_global_ai_provider_call_service_v1(
  uuid,text,numeric
) to service_role;

create or replace function public.record_iclub_global_ai_gateway_audit_service_v2(
  p_request_id uuid,
  p_user_id uuid,
  p_subject_key text,
  p_scope_code text,
  p_interaction_type text,
  p_route_class text,
  p_mode text,
  p_reason text,
  p_adapter_code text,
  p_policy_version text,
  p_latency_ms integer,
  p_output_hash text default null,
  p_source_card_keys text[] default '{}'::text[],
  p_safety_flags text[] default '{}'::text[],
  p_model_provider text default null,
  p_model_id text default null,
  p_input_tokens integer default null,
  p_output_tokens integer default null,
  p_estimated_cost_usd numeric default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path=''
as $audit$
declare
  v_inserted uuid;
begin
  if p_request_id is null
     or p_subject_key is null
     or p_scope_code is null
     or p_interaction_type is null
     or p_policy_version is null then
    return false;
  end if;

  if p_route_class is not null and p_route_class not in ('prepared','generated') then
    return false;
  end if;

  if p_mode not in ('prepared','generated','blocked','unavailable','no_source','failed') then
    return false;
  end if;

  insert into private.iclub_global_ai_gateway_audit(
    request_id,user_id,subject_key,scope_code,interaction_type,route_class,
    mode,reason,adapter_code,policy_version,latency_ms,output_hash,
    source_card_keys,safety_flags,model_provider,model_id,input_tokens,
    output_tokens,estimated_cost_usd
  ) values (
    p_request_id,p_user_id,p_subject_key,p_scope_code,p_interaction_type,p_route_class,
    p_mode,p_reason,p_adapter_code,p_policy_version,
    case when p_latency_ms is null then null else greatest(0,p_latency_ms) end,
    p_output_hash,
    coalesce(p_source_card_keys,'{}'::text[]),
    coalesce(p_safety_flags,'{}'::text[]),
    p_model_provider,p_model_id,
    case when p_input_tokens is null then null else greatest(0,p_input_tokens) end,
    case when p_output_tokens is null then null else greatest(0,p_output_tokens) end,
    case when p_estimated_cost_usd is null then null else greatest(0,p_estimated_cost_usd) end
  )
  on conflict(request_id) do nothing
  returning request_id into v_inserted;

  return v_inserted is not null;
end;
$audit$;

revoke all on function public.record_iclub_global_ai_gateway_audit_service_v2(
  uuid,uuid,text,text,text,text,text,text,text,text,integer,text,text[],text[],text,text,integer,integer,numeric
) from public,anon,authenticated;
grant execute on function public.record_iclub_global_ai_gateway_audit_service_v2(
  uuid,uuid,text,text,text,text,text,text,text,text,integer,text,text[],text[],text,text,integer,integer,numeric
) to service_role;

commit;