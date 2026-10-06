-- iClub Global AI gateway foundation v1.
-- Depends on 20261006102000_iclub_global_ai_tariff_foundation_v1.sql.
-- Dormant by default: no UI enablement, no generation provider, no learner state mutation.

begin;

create table if not exists private.iclub_global_ai_gateway_policy (
  id smallint primary key default 1 check (id=1),
  policy_version text not null default 'global_ai_gateway_policy_v1',
  allowed_interactions text[] not null default array[
    'topic_explanation',
    'freeform_question',
    'app_help'
  ]::text[],
  allowed_locales text[] not null default array['ru','uz','en']::text[],
  max_user_text_chars integer not null default 2000
    check (max_user_text_chars between 0 and 12000),
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

insert into private.iclub_global_ai_gateway_policy(id)
values(1)
on conflict(id) do nothing;

alter table private.iclub_ai_subject_readiness
  add column if not exists adapter_code text null;

update private.iclub_ai_subject_readiness
set adapter_code='math_exam_prep_v1',
    updated_at=now()
where subject_key='mathematics'
  and scope_code='exam_prep'
  and adapter_code is null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid='private.iclub_ai_subject_readiness'::regclass
      and conname='iclub_ai_subject_readiness_full_adapter_check'
  ) then
    alter table private.iclub_ai_subject_readiness
      add constraint iclub_ai_subject_readiness_full_adapter_check
      check (readiness<>'full' or adapter_code is not null);
  end if;
end
$$;

create table if not exists private.iclub_global_ai_gateway_audit (
  request_id uuid primary key,
  user_id uuid null references public.users(id) on delete set null,
  subject_key text not null,
  scope_code text not null,
  interaction_type text not null,
  route_class text null check (route_class is null or route_class in ('prepared','generated')),
  mode text not null check (mode in (
    'prepared',
    'generated',
    'blocked',
    'unavailable',
    'no_source',
    'failed'
  )),
  reason text null,
  adapter_code text null,
  policy_version text not null,
  latency_ms integer null check (latency_ms is null or latency_ms>=0),
  output_hash text null,
  created_at timestamptz not null default now()
);

create index if not exists iclub_global_ai_gateway_audit_user_created_idx
  on private.iclub_global_ai_gateway_audit(user_id,created_at desc);

create index if not exists iclub_global_ai_gateway_audit_mode_created_idx
  on private.iclub_global_ai_gateway_audit(mode,created_at desc);

alter table private.iclub_global_ai_gateway_policy enable row level security;
alter table private.iclub_global_ai_gateway_audit enable row level security;

revoke all on private.iclub_global_ai_gateway_policy from public,anon,authenticated;
revoke all on private.iclub_global_ai_gateway_audit from public,anon,authenticated;

grant all on private.iclub_global_ai_gateway_policy to service_role;
grant all on private.iclub_global_ai_gateway_audit to service_role;

create or replace function private.iclub_ai_has_active_protected_assessment_v1(p_user_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_tour boolean:=true;
  v_exam boolean:=true;
  v_has_tour_contract boolean:=false;
begin
  if p_user_id is null then
    return true;
  end if;

  select
    to_regclass('public.tour_attempts') is not null
    and exists(
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='tour_attempts'
        and column_name='user_id'
    )
    and exists(
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='tour_attempts'
        and column_name='status'
    )
  into v_has_tour_contract;

  if v_has_tour_contract then
    execute
      'select exists(
         select 1
         from public.tour_attempts
         where user_id=$1
           and status=''in_progress''
       )'
    into v_tour
    using p_user_id;
  else
    -- Fail closed if the protected Tour contract is unexpectedly missing.
    v_tour:=true;
  end if;

  if to_regprocedure('private.exam_prep_has_active_protected_assessment_v1(uuid)') is not null then
    execute
      'select private.exam_prep_has_active_protected_assessment_v1($1)'
    into v_exam
    using p_user_id;
  else
    -- Fail closed if the protected Exam Prep contract is unexpectedly missing.
    v_exam:=true;
  end if;

  return coalesce(v_tour,true) or coalesce(v_exam,true);
end;
$$;

revoke all on function private.iclub_ai_has_active_protected_assessment_v1(uuid)
  from public,anon,authenticated;
grant execute on function private.iclub_ai_has_active_protected_assessment_v1(uuid)
  to service_role;

create or replace function public.get_iclub_subscription_capabilities_service_v1(
  p_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_ent private.iclub_subscription_entitlements%rowtype;
  v_plan private.iclub_plan_policies%rowtype;
begin
  if p_user_id is null then
    return jsonb_build_object('resolved',false,'reason','invalid_user');
  end if;

  select * into v_ent
  from private.iclub_subscription_entitlements
  where user_id=p_user_id
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  if not found then
    return jsonb_build_object('resolved',false,'reason','subscription_unassigned');
  end if;

  select * into v_plan
  from private.iclub_plan_policies
  where plan_code=v_ent.plan_code
    and is_active;

  if not found then
    return jsonb_build_object('resolved',false,'reason','plan_unavailable');
  end if;

  return jsonb_build_object(
    'resolved',true,
    'plan_code',v_plan.plan_code,
    'study_subject_limit',v_plan.study_subject_limit,
    'all_available_subjects',v_plan.study_subject_limit is null,
    'competitive_subject_limit',v_plan.competitive_subject_limit,
    'ai_generation_entitled',v_plan.ai_generation_entitled,
    'ai_usage_policy_code',v_plan.ai_usage_policy_code,
    'priority_support',v_plan.priority_support,
    'early_access_entitled',v_plan.early_access_entitled
  );
end;
$$;

revoke all on function public.get_iclub_subscription_capabilities_service_v1(uuid)
  from public,anon,authenticated;
grant execute on function public.get_iclub_subscription_capabilities_service_v1(uuid)
  to service_role;

create or replace function public.get_iclub_global_ai_guard_service_v1(
  p_user_id uuid,
  p_subject_key text,
  p_scope_code text,
  p_interaction_type text,
  p_route_class text,
  p_requested_locale text,
  p_user_text_length integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_policy private.iclub_global_ai_gateway_policy%rowtype;
  v_readiness private.iclub_ai_subject_readiness%rowtype;
  v_caps jsonb;
  v_is_academic boolean;
begin
  if p_user_id is null then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','auth_required');
  end if;

  select * into v_policy
  from private.iclub_global_ai_gateway_policy
  where id=1;

  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','gateway_policy_missing');
  end if;

  if p_interaction_type is null
     or not (p_interaction_type=any(v_policy.allowed_interactions)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','interaction_not_allowed');
  end if;

  if p_route_class not in ('prepared','generated') then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','invalid_route_class');
  end if;

  if p_requested_locale is null
     or not (p_requested_locale=any(v_policy.allowed_locales)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','locale_not_allowed');
  end if;

  if coalesce(p_user_text_length,0)<0
     or coalesce(p_user_text_length,0)>v_policy.max_user_text_chars then
    return jsonb_build_object(
      'allowed',false,
      'mode','blocked',
      'reason','input_too_long',
      'max_chars',v_policy.max_user_text_chars
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or v_runtime.kill_switch
     or not v_runtime.gateway_enabled then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','gateway_disabled');
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'allowed',false,
      'mode','unavailable',
      'reason',coalesce(v_caps->>'reason','subscription_unavailable')
    );
  end if;

  -- Protected assessment is checked before subject source/readiness and before usage.
  if private.iclub_ai_has_active_protected_assessment_v1(p_user_id) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment');
  end if;

  select * into v_readiness
  from private.iclub_ai_subject_readiness
  where subject_key=p_subject_key
    and scope_code=p_scope_code;

  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','subject_not_ready');
  end if;

  if v_readiness.readiness='blocked' then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','subject_blocked');
  end if;

  v_is_academic:=p_interaction_type in ('topic_explanation','freeform_question');

  if v_is_academic and v_readiness.readiness<>'full' then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','subject_not_ready');
  end if;

  if p_route_class='generated' then
    -- Operational availability wins over upsell. During a generation incident or
    -- staged rollout, Free learners must not be told to upgrade to a feature that
    -- is not currently working for paid learners either.
    if not v_runtime.generation_enabled then
      return jsonb_build_object('allowed',false,'mode','unavailable','reason','generation_disabled');
    end if;

    if coalesce((v_caps->>'ai_generation_entitled')::boolean,false) is not true then
      return jsonb_build_object('allowed',false,'mode','unavailable','reason','generation_upgrade_required');
    end if;

    if v_readiness.readiness<>'full'
       or not v_readiness.generation_allowed then
      return jsonb_build_object('allowed',false,'mode','unavailable','reason','subject_generation_not_ready');
    end if;
  end if;

  return jsonb_build_object(
    'allowed',true,
    'mode','ready',
    'interaction_type',p_interaction_type,
    'route_class',p_route_class,
    'requested_locale',p_requested_locale,
    'policy_version',v_policy.policy_version,
    'plan_code',v_caps->>'plan_code',
    'ai_usage_policy_code',v_caps->>'ai_usage_policy_code',
    'adapter_code',v_readiness.adapter_code,
    'subject_key',v_readiness.subject_key,
    'scope_code',v_readiness.scope_code
  );
end;
$$;

revoke all on function public.get_iclub_global_ai_guard_service_v1(uuid,text,text,text,text,text,integer)
  from public,anon,authenticated;
grant execute on function public.get_iclub_global_ai_guard_service_v1(uuid,text,text,text,text,text,integer)
  to service_role;

create or replace function public.record_iclub_global_ai_gateway_audit_service_v1(
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
  p_output_hash text default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path=''
as $$
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
    mode,reason,adapter_code,policy_version,latency_ms,output_hash
  ) values (
    p_request_id,p_user_id,p_subject_key,p_scope_code,p_interaction_type,p_route_class,
    p_mode,p_reason,p_adapter_code,p_policy_version,
    case when p_latency_ms is null then null else greatest(0,p_latency_ms) end,
    p_output_hash
  )
  on conflict(request_id) do nothing
  returning request_id into v_inserted;

  return v_inserted is not null;
end;
$$;

revoke all on function public.record_iclub_global_ai_gateway_audit_service_v1(uuid,uuid,text,text,text,text,text,text,text,text,integer,text)
  from public,anon,authenticated;
grant execute on function public.record_iclub_global_ai_gateway_audit_service_v1(uuid,uuid,text,text,text,text,text,text,text,text,integer,text)
  to service_role;

create or replace function public.get_iclub_global_ai_gateway_snapshot_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select jsonb_build_object(
    'runtime',(
      select jsonb_build_object(
        'ui_enabled',c.ui_enabled,
        'gateway_enabled',c.gateway_enabled,
        'generation_enabled',c.generation_enabled,
        'kill_switch',c.kill_switch,
        'config_version',c.config_version
      )
      from private.iclub_global_ai_runtime_config c
      where c.id=1
    ),
    'gateway_policy',(
      select jsonb_build_object(
        'policy_version',p.policy_version,
        'allowed_interactions',p.allowed_interactions,
        'allowed_locales',p.allowed_locales,
        'max_user_text_chars',p.max_user_text_chars
      )
      from private.iclub_global_ai_gateway_policy p
      where p.id=1
    ),
    'subject_readiness',(
      select coalesce(jsonb_agg(jsonb_build_object(
        'subject_key',r.subject_key,
        'scope_code',r.scope_code,
        'readiness',r.readiness,
        'generation_allowed',r.generation_allowed,
        'adapter_code',r.adapter_code,
        'readiness_version',r.readiness_version
      ) order by r.subject_key,r.scope_code),'[]'::jsonb)
      from private.iclub_ai_subject_readiness r
    ),
    'audit_24h',(
      select coalesce(jsonb_object_agg(x.mode,x.cnt),'{}'::jsonb)
      from (
        select a.mode,count(*)::integer cnt
        from private.iclub_global_ai_gateway_audit a
        where a.created_at>=now()-interval '24 hours'
        group by a.mode
      ) x
    )
  );
$$;

revoke all on function public.get_iclub_global_ai_gateway_snapshot_v1()
  from public,anon,authenticated;
grant execute on function public.get_iclub_global_ai_gateway_snapshot_v1()
  to service_role;

commit;