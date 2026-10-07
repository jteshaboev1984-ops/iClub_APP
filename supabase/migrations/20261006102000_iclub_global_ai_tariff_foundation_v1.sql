-- iClub Global AI + tariffs foundation v1.
-- Additive and dormant by design:
-- - no existing learner row is updated/deleted;
-- - no tariff is assigned to any existing user;
-- - no subject access is changed;
-- - Global AI UI/gateway/generation remain OFF behind a kill switch.
--
-- This foundation only creates server-owned policy/entitlement/usage primitives
-- for the approved Free / Plus / Pro product model.

begin;

create schema if not exists private;

create table if not exists private.iclub_ai_usage_policies (
  usage_policy_code text primary key,
  policy_version text not null,
  period_seconds integer not null check (period_seconds between 300 and 86400),
  allowance_units integer not null check (allowance_units between 1 and 10000),
  prepared_weight integer not null check (prepared_weight between 1 and allowance_units),
  generation_weight integer not null check (generation_weight between 1 and allowance_units),
  generation_enabled boolean not null default false,
  reservation_ttl_seconds integer not null default 90
    check (reservation_ttl_seconds between 15 and 300),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into private.iclub_ai_usage_policies(
  usage_policy_code,policy_version,period_seconds,allowance_units,
  prepared_weight,generation_weight,generation_enabled,reservation_ttl_seconds,is_active
) values
  ('free_v1','global_ai_tariffs_v1',18000,3,1,3,false,90,true),
  ('plus_v1','global_ai_tariffs_v1',18000,9,1,5,true,90,true),
  ('pro_v1','global_ai_tariffs_v1',18000,14,1,5,true,90,true)
on conflict (usage_policy_code) do nothing;

create table if not exists private.iclub_plan_policies (
  plan_code text primary key check (plan_code in ('free','plus','pro')),
  policy_version text not null,
  monthly_price_uzs integer not null check (monthly_price_uzs >= 0),
  study_subject_limit integer null check (study_subject_limit is null or study_subject_limit between 1 and 50),
  competitive_subject_limit integer not null check (competitive_subject_limit between 0 and 10),
  ai_generation_entitled boolean not null default false,
  ai_usage_policy_code text not null references private.iclub_ai_usage_policies(usage_policy_code),
  priority_support boolean not null default false,
  early_access_entitled boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into private.iclub_plan_policies(
  plan_code,policy_version,monthly_price_uzs,study_subject_limit,competitive_subject_limit,
  ai_generation_entitled,ai_usage_policy_code,priority_support,early_access_entitled,is_active
) values
  ('free','global_ai_tariffs_v1',0,1,1,false,'free_v1',false,false,true),
  ('plus','global_ai_tariffs_v1',35000,3,2,true,'plus_v1',false,false,true),
  ('pro','global_ai_tariffs_v1',50000,null,2,true,'pro_v1',true,true,true)
on conflict (plan_code) do nothing;

create table if not exists private.iclub_subscription_entitlements (
  user_id uuid primary key references public.users(id) on delete cascade,
  plan_code text not null references private.iclub_plan_policies(plan_code),
  entitlement_status text not null default 'active'
    check (entitlement_status in ('active','paused','cancelled','revoked')),
  entitlement_source text not null default 'manual'
    check (char_length(entitlement_source) between 2 and 80),
  valid_from timestamptz null,
  valid_until timestamptz null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  check (valid_until is null or valid_from is null or valid_until > valid_from)
);

create table if not exists private.iclub_global_ai_runtime_config (
  id smallint primary key default 1 check (id=1),
  config_version text not null default 'global_ai_runtime_v1',
  ui_enabled boolean not null default false,
  gateway_enabled boolean not null default false,
  generation_enabled boolean not null default false,
  kill_switch boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

insert into private.iclub_global_ai_runtime_config(id)
values (1)
on conflict (id) do nothing;

create table if not exists private.iclub_ai_subject_readiness (
  subject_key text not null,
  scope_code text not null,
  readiness text not null default 'basic'
    check (readiness in ('basic','full','blocked')),
  generation_allowed boolean not null default false,
  approved_source_set text null,
  readiness_version text not null default 'global_ai_subject_readiness_v1',
  notes text null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  primary key(subject_key,scope_code),
  check (char_length(subject_key) between 2 and 80),
  check (char_length(scope_code) between 2 and 80),
  check (readiness='full' or not generation_allowed)
);

insert into private.iclub_ai_subject_readiness(
  subject_key,scope_code,readiness,generation_allowed,approved_source_set,notes
) values
  ('biology','global','basic',false,null,'Academic Global AI not promoted yet.'),
  ('chemistry','global','basic',false,null,'Academic Global AI not promoted yet.'),
  ('mathematics','global','basic',false,null,'Global subject-wide AI not promoted yet.'),
  ('informatics','global','basic',false,null,'Academic Global AI not promoted yet.'),
  ('economics','global','basic',false,null,'Academic Global AI not promoted yet.'),
  ('mathematics','exam_prep','full',true,'tutor_v3_learner_first','Existing governed Mathematics Exam Prep AI source path only.')
on conflict (subject_key,scope_code) do nothing;

create table if not exists private.iclub_ai_usage_periods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  usage_policy_code text not null references private.iclub_ai_usage_policies(usage_policy_code),
  status text not null default 'provisional'
    check (status in ('provisional','active','closed')),
  started_at timestamptz null,
  reset_at timestamptz null,
  committed_units integer not null default 0 check (committed_units >= 0),
  reserved_units integer not null default 0 check (reserved_units >= 0),
  exhausted boolean not null default false,
  exhausted_at timestamptz null,
  close_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((started_at is null and reset_at is null) or (started_at is not null and reset_at is not null and reset_at > started_at)),
  check (status <> 'active' or started_at is not null)
);

create unique index if not exists iclub_ai_usage_periods_one_open_user_idx
  on private.iclub_ai_usage_periods(user_id)
  where status in ('provisional','active');

create index if not exists iclub_ai_usage_periods_user_created_idx
  on private.iclub_ai_usage_periods(user_id,created_at desc);

create table if not exists private.iclub_ai_usage_reservations (
  request_id uuid primary key,
  period_id uuid not null references private.iclub_ai_usage_periods(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  route_class text not null check (route_class in ('prepared','generated')),
  weight_units integer not null check (weight_units > 0),
  status text not null default 'reserved'
    check (status in ('reserved','completed','released')),
  release_reason text null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  finished_at timestamptz null,
  check (expires_at > created_at)
);

create index if not exists iclub_ai_usage_reservations_user_created_idx
  on private.iclub_ai_usage_reservations(user_id,created_at desc);

create index if not exists iclub_ai_usage_reservations_active_idx
  on private.iclub_ai_usage_reservations(status,expires_at)
  where status='reserved';

alter table private.iclub_ai_usage_policies enable row level security;
alter table private.iclub_plan_policies enable row level security;
alter table private.iclub_subscription_entitlements enable row level security;
alter table private.iclub_global_ai_runtime_config enable row level security;
alter table private.iclub_ai_subject_readiness enable row level security;
alter table private.iclub_ai_usage_periods enable row level security;
alter table private.iclub_ai_usage_reservations enable row level security;

revoke all on private.iclub_ai_usage_policies from public,anon,authenticated;
revoke all on private.iclub_plan_policies from public,anon,authenticated;
revoke all on private.iclub_subscription_entitlements from public,anon,authenticated;
revoke all on private.iclub_global_ai_runtime_config from public,anon,authenticated;
revoke all on private.iclub_ai_subject_readiness from public,anon,authenticated;
revoke all on private.iclub_ai_usage_periods from public,anon,authenticated;
revoke all on private.iclub_ai_usage_reservations from public,anon,authenticated;

grant all on private.iclub_ai_usage_policies to service_role;
grant all on private.iclub_plan_policies to service_role;
grant all on private.iclub_subscription_entitlements to service_role;
grant all on private.iclub_global_ai_runtime_config to service_role;
grant all on private.iclub_ai_subject_readiness to service_role;
grant all on private.iclub_ai_usage_periods to service_role;
grant all on private.iclub_ai_usage_reservations to service_role;

create or replace function public.get_iclub_public_plan_catalog_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'plan_code',p.plan_code,
      'monthly_price_uzs',p.monthly_price_uzs,
      'study_subject_limit',p.study_subject_limit,
      'all_available_subjects',p.study_subject_limit is null,
      'competitive_subject_limit',p.competitive_subject_limit,
      'ai_generation_entitled',p.ai_generation_entitled,
      'priority_support',p.priority_support,
      'early_access_entitled',p.early_access_entitled
    )
    order by case p.plan_code when 'free' then 1 when 'plus' then 2 else 3 end
  ),'[]'::jsonb)
  from private.iclub_plan_policies p
  where p.is_active;
$$;

revoke all on function public.get_iclub_public_plan_catalog_v1() from public;
grant execute on function public.get_iclub_public_plan_catalog_v1() to anon,authenticated,service_role;

create or replace function public.reserve_iclub_ai_usage_service_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_usage_policy_code text,
  p_route_class text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_policy private.iclub_ai_usage_policies%rowtype;
  v_period private.iclub_ai_usage_periods%rowtype;
  v_existing private.iclub_ai_usage_reservations%rowtype;
  v_weight integer;
  v_remaining integer;
  v_without_reservations integer;
begin
  if p_request_id is null or p_user_id is null then
    return jsonb_build_object('allowed',false,'reason','invalid_identity');
  end if;

  if p_route_class not in ('prepared','generated') then
    return jsonb_build_object('allowed',false,'reason','invalid_route_class');
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));

  select * into v_policy
  from private.iclub_ai_usage_policies
  where usage_policy_code=p_usage_policy_code
    and is_active;

  if not found then
    return jsonb_build_object('allowed',false,'reason','usage_policy_unavailable');
  end if;

  if p_route_class='generated' and not v_policy.generation_enabled then
    return jsonb_build_object('allowed',false,'reason','generation_not_entitled');
  end if;

  v_weight:=case when p_route_class='generated' then v_policy.generation_weight else v_policy.prepared_weight end;

  select * into v_existing
  from private.iclub_ai_usage_reservations
  where request_id=p_request_id
  for update;

  if found then
    if v_existing.user_id<>p_user_id then
      return jsonb_build_object('allowed',false,'reason','request_identity_mismatch');
    end if;
    return jsonb_build_object(
      'allowed',v_existing.status in ('reserved','completed'),
      'reason',case when v_existing.status='released' then coalesce(v_existing.release_reason,'request_released') else null end,
      'duplicate',true,
      'reservation_status',v_existing.status,
      'request_id',v_existing.request_id
    );
  end if;

  with released as (
    update private.iclub_ai_usage_reservations r
    set status='released',
        release_reason='reservation_expired',
        finished_at=coalesce(r.finished_at,now())
    where r.user_id=p_user_id
      and r.status='reserved'
      and r.expires_at<=now()
    returning r.period_id,r.weight_units
  ), totals as (
    select period_id,sum(weight_units)::integer released_units
    from released
    group by period_id
  )
  update private.iclub_ai_usage_periods p
  set reserved_units=greatest(0,p.reserved_units-t.released_units),
      updated_at=now()
  from totals t
  where p.id=t.period_id;

  select * into v_period
  from private.iclub_ai_usage_periods
  where user_id=p_user_id
    and status in ('provisional','active')
  order by created_at desc
  limit 1
  for update;

  if found and v_period.status='active' and v_period.reset_at<=now() then
    if v_period.reserved_units>0 then
      return jsonb_build_object(
        'allowed',false,
        'reason','usage_busy',
        'reset_at',v_period.reset_at
      );
    end if;

    update private.iclub_ai_usage_periods
    set status='closed',
        close_reason='period_elapsed',
        exhausted=false,
        updated_at=now()
    where id=v_period.id;
    v_period.id:=null;
  end if;

  if v_period.id is null then
    insert into private.iclub_ai_usage_periods(
      user_id,usage_policy_code,status,committed_units,reserved_units,exhausted
    ) values (
      p_user_id,v_policy.usage_policy_code,'provisional',0,0,false
    )
    returning * into v_period;
  elsif v_period.usage_policy_code<>v_policy.usage_policy_code then
    return jsonb_build_object(
      'allowed',false,
      'reason','usage_policy_transition_required',
      'current_usage_policy_code',v_period.usage_policy_code
    );
  end if;

  if v_period.status='active' and v_period.exhausted then
    return jsonb_build_object(
      'allowed',false,
      'reason','usage_exhausted',
      'reset_at',v_period.reset_at
    );
  end if;

  v_remaining:=v_policy.allowance_units-v_period.committed_units-v_period.reserved_units;
  v_without_reservations:=v_policy.allowance_units-v_period.committed_units;

  if v_weight>v_remaining then
    if v_period.reserved_units>0 and v_weight<=v_without_reservations then
      return jsonb_build_object(
        'allowed',false,
        'reason','usage_busy',
        'reset_at',v_period.reset_at
      );
    end if;

    if v_period.status='active' then
      update private.iclub_ai_usage_periods
      set exhausted=true,
          exhausted_at=coalesce(exhausted_at,now()),
          updated_at=now()
      where id=v_period.id;

      return jsonb_build_object(
        'allowed',false,
        'reason','usage_exhausted',
        'reset_at',v_period.reset_at
      );
    end if;

    return jsonb_build_object('allowed',false,'reason','usage_unavailable');
  end if;

  insert into private.iclub_ai_usage_reservations(
    request_id,period_id,user_id,route_class,weight_units,status,created_at,expires_at
  ) values (
    p_request_id,v_period.id,p_user_id,p_route_class,v_weight,'reserved',now(),
    now()+make_interval(secs=>v_policy.reservation_ttl_seconds)
  );

  update private.iclub_ai_usage_periods
  set reserved_units=reserved_units+v_weight,
      updated_at=now()
  where id=v_period.id;

  return jsonb_build_object(
    'allowed',true,
    'reason',null,
    'duplicate',false,
    'request_id',p_request_id,
    'reservation_status','reserved'
  );
end;
$$;

revoke all on function public.reserve_iclub_ai_usage_service_v1(uuid,uuid,text,text)
  from public,anon,authenticated;
grant execute on function public.reserve_iclub_ai_usage_service_v1(uuid,uuid,text,text)
  to service_role;

create or replace function public.finalize_iclub_ai_usage_service_v1(
  p_request_id uuid,
  p_outcome text,
  p_release_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_res private.iclub_ai_usage_reservations%rowtype;
  v_period private.iclub_ai_usage_periods%rowtype;
  v_policy private.iclub_ai_usage_policies%rowtype;
  v_now timestamptz:=now();
  v_new_committed integer;
begin
  if p_request_id is null then
    return jsonb_build_object('ok',false,'reason','invalid_request_id');
  end if;

  if p_outcome not in ('completed','released') then
    return jsonb_build_object('ok',false,'reason','invalid_outcome');
  end if;

  select * into v_res
  from private.iclub_ai_usage_reservations
  where request_id=p_request_id;

  if not found then
    return jsonb_build_object('ok',false,'reason','reservation_missing');
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_res.user_id::text,0));

  select * into v_res
  from private.iclub_ai_usage_reservations
  where request_id=p_request_id
  for update;

  if v_res.status='completed' then
    select * into v_period from private.iclub_ai_usage_periods where id=v_res.period_id;
    return jsonb_build_object('ok',true,'duplicate',true,'status','completed','reset_at',v_period.reset_at);
  end if;

  if v_res.status='released' then
    return jsonb_build_object('ok',p_outcome='released','duplicate',true,'status','released');
  end if;

  select * into v_period
  from private.iclub_ai_usage_periods
  where id=v_res.period_id
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','usage_period_missing');
  end if;

  select * into v_policy
  from private.iclub_ai_usage_policies
  where usage_policy_code=v_period.usage_policy_code;

  if not found then
    return jsonb_build_object('ok',false,'reason','usage_policy_missing');
  end if;

  if p_outcome='released' then
    update private.iclub_ai_usage_reservations
    set status='released',
        release_reason=coalesce(p_release_reason,'not_delivered'),
        finished_at=v_now
    where request_id=p_request_id;

    update private.iclub_ai_usage_periods
    set reserved_units=greatest(0,reserved_units-v_res.weight_units),
        status=case
          when status='provisional'
           and committed_units=0
           and greatest(0,reserved_units-v_res.weight_units)=0
          then 'closed'
          else status
        end,
        close_reason=case
          when status='provisional'
           and committed_units=0
           and greatest(0,reserved_units-v_res.weight_units)=0
          then 'no_successful_response'
          else close_reason
        end,
        updated_at=v_now
    where id=v_period.id
    returning * into v_period;

    return jsonb_build_object(
      'ok',true,
      'duplicate',false,
      'status','released',
      'reset_at',v_period.reset_at
    );
  end if;

  v_new_committed:=v_period.committed_units+v_res.weight_units;

  if v_new_committed>v_policy.allowance_units then
    return jsonb_build_object('ok',false,'reason','usage_invariant_exceeded');
  end if;

  update private.iclub_ai_usage_reservations
  set status='completed',
      finished_at=v_now,
      release_reason=null
  where request_id=p_request_id;

  update private.iclub_ai_usage_periods
  set reserved_units=greatest(0,reserved_units-v_res.weight_units),
      committed_units=v_new_committed,
      status='active',
      started_at=coalesce(started_at,v_now),
      reset_at=coalesce(reset_at,v_now+make_interval(secs=>v_policy.period_seconds)),
      exhausted=case when v_new_committed>=v_policy.allowance_units then true else exhausted end,
      exhausted_at=case
        when v_new_committed>=v_policy.allowance_units then coalesce(exhausted_at,v_now)
        else exhausted_at
      end,
      updated_at=v_now
  where id=v_period.id
  returning * into v_period;

  return jsonb_build_object(
    'ok',true,
    'duplicate',false,
    'status','completed',
    'reset_at',v_period.reset_at,
    'exhausted',v_period.exhausted
  );
end;
$$;

revoke all on function public.finalize_iclub_ai_usage_service_v1(uuid,text,text)
  from public,anon,authenticated;
grant execute on function public.finalize_iclub_ai_usage_service_v1(uuid,text,text)
  to service_role;

create or replace function public.get_iclub_global_ai_foundation_snapshot_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select jsonb_build_object(
    'runtime',(
      select jsonb_build_object(
        'config_version',c.config_version,
        'ui_enabled',c.ui_enabled,
        'gateway_enabled',c.gateway_enabled,
        'generation_enabled',c.generation_enabled,
        'kill_switch',c.kill_switch
      )
      from private.iclub_global_ai_runtime_config c
      where c.id=1
    ),
    'plans',(
      select jsonb_object_agg(p.plan_code,jsonb_build_object(
        'monthly_price_uzs',p.monthly_price_uzs,
        'study_subject_limit',p.study_subject_limit,
        'competitive_subject_limit',p.competitive_subject_limit,
        'ai_generation_entitled',p.ai_generation_entitled,
        'ai_usage_policy_code',p.ai_usage_policy_code,
        'priority_support',p.priority_support,
        'early_access_entitled',p.early_access_entitled
      ))
      from private.iclub_plan_policies p
      where p.is_active
    ),
    'assigned_subscriptions',(select count(*) from private.iclub_subscription_entitlements),
    'usage_periods',(select count(*) from private.iclub_ai_usage_periods),
    'usage_reservations',(select count(*) from private.iclub_ai_usage_reservations),
    'subject_readiness',(select count(*) from private.iclub_ai_subject_readiness)
  );
$$;

revoke all on function public.get_iclub_global_ai_foundation_snapshot_v1()
  from public,anon,authenticated;
grant execute on function public.get_iclub_global_ai_foundation_snapshot_v1()
  to service_role;

commit;
