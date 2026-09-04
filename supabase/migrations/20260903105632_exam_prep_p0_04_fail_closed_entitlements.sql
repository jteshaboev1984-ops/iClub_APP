-- P0-04: fail-closed Exam Prep capability/entitlement layer.
-- Additive only. Does not touch legacy Practice/Tours/history.

create schema if not exists private;

revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated, service_role;

create table private.exam_prep_feature_config (
  id smallint primary key default 1 check (id = 1),
  program_key text not null unique default 'math_as_p1_p5',
  rollout_state text not null default 'off'
    check (rollout_state in ('off','internal_alpha','controlled_beta','expanded_beta','mass')),
  core_enabled boolean not null default false,
  ai_enabled boolean not null default false,
  mentor_enabled boolean not null default false,
  kill_switch boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

create table private.exam_prep_feature_entitlements (
  user_id uuid primary key references public.users(id) on delete cascade,
  entitlement_status text not null default 'disabled'
    check (entitlement_status in ('disabled','active','paused','revoked')),
  core_access boolean not null default false,
  ai_assist boolean not null default false,
  mentor_care_entitled boolean not null default false,
  cohort_key text null,
  valid_from timestamptz null,
  valid_until timestamptz null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  check (valid_until is null or valid_from is null or valid_until > valid_from)
);

alter table private.exam_prep_feature_config enable row level security;
alter table private.exam_prep_feature_entitlements enable row level security;

revoke all on private.exam_prep_feature_config from public, anon, authenticated;
revoke all on private.exam_prep_feature_entitlements from public, anon, authenticated;
grant select on private.exam_prep_feature_config to authenticated;
grant select on private.exam_prep_feature_entitlements to authenticated;
grant all on private.exam_prep_feature_config to service_role;
grant all on private.exam_prep_feature_entitlements to service_role;

create policy exam_prep_feature_config_authenticated_read
on private.exam_prep_feature_config
for select
to authenticated
using (true);

create policy exam_prep_feature_entitlements_owner_read
on private.exam_prep_feature_entitlements
for select
to authenticated
using ((select auth.uid()) = user_id);

insert into private.exam_prep_feature_config (
  id, program_key, rollout_state, core_enabled, ai_enabled, mentor_enabled, kill_switch
) values (
  1, 'math_as_p1_p5', 'off', false, false, false, true
)
on conflict (id) do nothing;

create or replace function public.get_exam_prep_capabilities_v1()
returns table (
  program_key text,
  rollout_state text,
  core_access boolean,
  ai_assist boolean,
  mentor_care_entitled boolean,
  mentor_assignment_active boolean,
  mentor_authority boolean,
  kill_switch boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  with caller as (
    select auth.uid() as user_id
  ), cfg as (
    select c.program_key, c.rollout_state, c.core_enabled, c.ai_enabled, c.mentor_enabled, c.kill_switch
    from private.exam_prep_feature_config c
    where c.id = 1
  ), ent as (
    select e.user_id, e.core_access, e.ai_assist, e.mentor_care_entitled
    from private.exam_prep_feature_entitlements e, caller u
    where e.user_id = u.user_id
      and e.entitlement_status = 'active'
      and (e.valid_from is null or e.valid_from <= now())
      and (e.valid_until is null or e.valid_until > now())
  )
  select
    coalesce(cfg.program_key, 'math_as_p1_p5'::text) as program_key,
    coalesce(cfg.rollout_state, 'off'::text) as rollout_state,
    coalesce(
      caller.user_id is not null
      and not cfg.kill_switch
      and cfg.core_enabled
      and cfg.rollout_state <> 'off'
      and ent.core_access,
      false
    ) as core_access,
    coalesce(
      caller.user_id is not null
      and not cfg.kill_switch
      and cfg.core_enabled
      and cfg.ai_enabled
      and cfg.rollout_state <> 'off'
      and ent.core_access
      and ent.ai_assist,
      false
    ) as ai_assist,
    coalesce(
      caller.user_id is not null
      and not cfg.kill_switch
      and cfg.core_enabled
      and cfg.mentor_enabled
      and cfg.rollout_state <> 'off'
      and ent.core_access
      and ent.mentor_care_entitled,
      false
    ) as mentor_care_entitled,
    false as mentor_assignment_active,
    false as mentor_authority,
    coalesce(cfg.kill_switch, true) as kill_switch
  from caller
  left join cfg on true
  left join ent on ent.user_id = caller.user_id;
$$;

revoke execute on function public.get_exam_prep_capabilities_v1() from public, anon;
grant execute on function public.get_exam_prep_capabilities_v1() to authenticated, service_role;
