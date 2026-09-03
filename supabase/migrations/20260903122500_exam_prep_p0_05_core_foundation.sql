-- P0-05: additive Exam Prep core foundation.
-- Scope intentionally stops before canonical registry, sessions, mastery/state engine,
-- assessments, correction/retest, weekly plans and learner UI.
-- Legacy Practice/Tours/ratings/certificates are not read or mutated here.

begin;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 1) Program/version anchor. P0-06 will insert/pin the canonical 81-skill map.
-- -----------------------------------------------------------------------------
create table if not exists private.exam_prep_program_versions (
  id bigint generated always as identity primary key,
  program_key text not null default 'math_as_p1_p5',
  version_key text not null,
  syllabus_version text null,
  canonical_skill_map_version text null,
  engine_version text null,
  rule_version text null,
  assessment_schema_version text not null default 'v1',
  status text not null default 'draft'
    check (status in ('draft','active','retired')),
  effective_from timestamptz null,
  retired_at timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  unique (program_key, version_key),
  check (retired_at is null or effective_from is null or retired_at >= effective_from)
);

create unique index if not exists exam_prep_program_versions_one_active_idx
  on private.exam_prep_program_versions(program_key)
  where status = 'active';

-- -----------------------------------------------------------------------------
-- 2) Shared learner Exam Profile. Planning metadata only; never mastery authority.
--    active_week_no is shared, while future stage/mastery records remain P1/P5-local.
-- -----------------------------------------------------------------------------
create table if not exists private.exam_prep_exam_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  program_version_id bigint null references private.exam_prep_program_versions(id) on delete restrict,
  exam_series text null,
  target_grade text null,
  total_student_hours_available numeric(8,2) null,
  mathematics_hours_budget numeric(8,2) null,
  active_week_no smallint not null default 0,
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  check (active_week_no between 0 and 36),
  check (total_student_hours_available is null or total_student_hours_available >= 0),
  check (mathematics_hours_budget is null or mathematics_hours_budget >= 0),
  check (
    total_student_hours_available is null
    or mathematics_hours_budget is null
    or mathematics_hours_budget <= total_student_hours_available
  ),
  check (target_grade is null or char_length(target_grade) between 1 and 20),
  check (exam_series is null or char_length(exam_series) between 1 and 80)
);

create index if not exists exam_prep_exam_profiles_program_version_idx
  on private.exam_prep_exam_profiles(program_version_id);

-- -----------------------------------------------------------------------------
-- 3) Mentor Care service lifecycle. Commercial entitlement != operational scope.
-- -----------------------------------------------------------------------------
create table if not exists private.exam_prep_mentor_service_status (
  learner_user_id uuid primary key references public.users(id) on delete cascade,
  service_status text not null default 'not_entitled'
    check (service_status in (
      'not_entitled',
      'entitled_waitlist',
      'assigned_active',
      'assigned_paused',
      'ended'
    )),
  status_reason text null,
  status_changed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

create index if not exists exam_prep_mentor_service_status_state_idx
  on private.exam_prep_mentor_service_status(service_status);

-- -----------------------------------------------------------------------------
-- 4) Mentor assignment permission anchor. One row owns exactly one component.
--    A mentor covering both P1 and P5 has two rows. Cross-component authority is
--    therefore impossible to infer from one assignment row.
-- -----------------------------------------------------------------------------
create table if not exists private.exam_prep_mentor_assignments (
  id bigint generated always as identity primary key,
  learner_user_id uuid not null references public.users(id) on delete cascade,
  mentor_user_id uuid not null references public.users(id) on delete restrict,
  component_code text not null check (component_code in ('P1','P5')),
  assignment_status text not null default 'active'
    check (assignment_status in ('active','paused','ended')),
  valid_from timestamptz not null default now(),
  valid_until timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  check (learner_user_id <> mentor_user_id),
  check (valid_until is null or valid_until > valid_from)
);

create unique index if not exists exam_prep_mentor_assignments_one_active_component_idx
  on private.exam_prep_mentor_assignments(learner_user_id, component_code)
  where assignment_status = 'active' and valid_until is null;

create index if not exists exam_prep_mentor_assignments_learner_idx
  on private.exam_prep_mentor_assignments(learner_user_id, component_code, assignment_status);

create index if not exists exam_prep_mentor_assignments_mentor_idx
  on private.exam_prep_mentor_assignments(mentor_user_id, component_code, assignment_status);

-- -----------------------------------------------------------------------------
-- 5) Append-only security/data/governance audit ledger.
-- -----------------------------------------------------------------------------
create table if not exists private.exam_prep_audit_events (
  id bigint generated always as identity primary key,
  program_key text not null default 'math_as_p1_p5',
  actor_user_id uuid null,
  actor_role text null,
  event_type text not null,
  object_type text not null,
  object_id text null,
  target_user_id uuid null,
  component_code text null check (component_code is null or component_code in ('P1','P5')),
  before_state jsonb null,
  after_state jsonb null,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create index if not exists exam_prep_audit_events_target_idx
  on private.exam_prep_audit_events(target_user_id, occurred_at desc);
create index if not exists exam_prep_audit_events_object_idx
  on private.exam_prep_audit_events(object_type, object_id, occurred_at desc);

-- -----------------------------------------------------------------------------
-- RLS and grants: authenticated may only read their own planning/service anchors.
-- No authenticated direct write exists. Mentor cross-user scope is deliberately
-- NOT opened in P0-05; it belongs to the later governed Mentor Care step.
-- -----------------------------------------------------------------------------
alter table private.exam_prep_program_versions enable row level security;
alter table private.exam_prep_exam_profiles enable row level security;
alter table private.exam_prep_mentor_service_status enable row level security;
alter table private.exam_prep_mentor_assignments enable row level security;
alter table private.exam_prep_audit_events enable row level security;

revoke all on private.exam_prep_program_versions from public, anon, authenticated;
revoke all on private.exam_prep_exam_profiles from public, anon, authenticated;
revoke all on private.exam_prep_mentor_service_status from public, anon, authenticated;
revoke all on private.exam_prep_mentor_assignments from public, anon, authenticated;
revoke all on private.exam_prep_audit_events from public, anon, authenticated;

grant select on private.exam_prep_exam_profiles to authenticated;
grant select on private.exam_prep_mentor_service_status to authenticated;
grant select on private.exam_prep_mentor_assignments to authenticated;

grant all on private.exam_prep_program_versions to service_role;
grant all on private.exam_prep_exam_profiles to service_role;
grant all on private.exam_prep_mentor_service_status to service_role;
grant all on private.exam_prep_mentor_assignments to service_role;
grant select, insert on private.exam_prep_audit_events to service_role;

grant usage, select on sequence private.exam_prep_program_versions_id_seq to service_role;
grant usage, select on sequence private.exam_prep_mentor_assignments_id_seq to service_role;
grant usage, select on sequence private.exam_prep_audit_events_id_seq to service_role;

drop policy if exists exam_prep_exam_profiles_owner_read on private.exam_prep_exam_profiles;
create policy exam_prep_exam_profiles_owner_read
on private.exam_prep_exam_profiles
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists exam_prep_mentor_service_status_owner_read on private.exam_prep_mentor_service_status;
create policy exam_prep_mentor_service_status_owner_read
on private.exam_prep_mentor_service_status
for select
to authenticated
using ((select auth.uid()) = learner_user_id);

drop policy if exists exam_prep_mentor_assignments_learner_read on private.exam_prep_mentor_assignments;
create policy exam_prep_mentor_assignments_learner_read
on private.exam_prep_mentor_assignments
for select
to authenticated
using ((select auth.uid()) = learner_user_id);

-- -----------------------------------------------------------------------------
-- Generic private audit trigger. It is intentionally SECURITY DEFINER and cannot
-- be executed directly by client roles.
-- -----------------------------------------------------------------------------
create or replace function private.exam_prep_audit_row_change_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_actor_text text;
  v_target_text text;
  v_component text;
  v_object_id text;
  v_program_key text;
begin
  if tg_op = 'INSERT' then
    v_before := null;
    v_after := to_jsonb(new);
  elsif tg_op = 'UPDATE' then
    v_before := to_jsonb(old);
    v_after := to_jsonb(new);
  else
    v_before := to_jsonb(old);
    v_after := null;
  end if;

  v_actor_text := coalesce(
    v_after->>'updated_by', v_after->>'created_by',
    v_before->>'updated_by', v_before->>'created_by'
  );
  v_target_text := coalesce(
    v_after->>'user_id', v_after->>'learner_user_id',
    v_before->>'user_id', v_before->>'learner_user_id'
  );
  v_component := coalesce(v_after->>'component_code', v_before->>'component_code');
  v_object_id := coalesce(
    v_after->>'id', v_after->>'program_key', v_after->>'user_id', v_after->>'learner_user_id',
    v_before->>'id', v_before->>'program_key', v_before->>'user_id', v_before->>'learner_user_id'
  );
  v_program_key := coalesce(v_after->>'program_key', v_before->>'program_key', 'math_as_p1_p5');

  insert into private.exam_prep_audit_events (
    program_key,
    actor_user_id,
    actor_role,
    event_type,
    object_type,
    object_id,
    target_user_id,
    component_code,
    before_state,
    after_state,
    metadata
  ) values (
    v_program_key,
    coalesce(nullif(v_actor_text, '')::uuid, auth.uid()),
    coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), session_user),
    lower(tg_op),
    tg_table_schema || '.' || tg_table_name,
    v_object_id,
    nullif(v_target_text, '')::uuid,
    case when v_component in ('P1','P5') then v_component else null end,
    v_before,
    v_after,
    jsonb_build_object('trigger', tg_name)
  );

  return coalesce(new, old);
end;
$$;

revoke all on function private.exam_prep_audit_row_change_v1() from public, anon, authenticated;

-- Existing P0-04 capability state is now audited too.
drop trigger if exists exam_prep_feature_config_audit_v1 on private.exam_prep_feature_config;
create trigger exam_prep_feature_config_audit_v1
after insert or update or delete on private.exam_prep_feature_config
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_feature_entitlements_audit_v1 on private.exam_prep_feature_entitlements;
create trigger exam_prep_feature_entitlements_audit_v1
after insert or update or delete on private.exam_prep_feature_entitlements
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_program_versions_audit_v1 on private.exam_prep_program_versions;
create trigger exam_prep_program_versions_audit_v1
after insert or update or delete on private.exam_prep_program_versions
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_exam_profiles_audit_v1 on private.exam_prep_exam_profiles;
create trigger exam_prep_exam_profiles_audit_v1
after insert or update or delete on private.exam_prep_exam_profiles
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_mentor_service_status_audit_v1 on private.exam_prep_mentor_service_status;
create trigger exam_prep_mentor_service_status_audit_v1
after insert or update or delete on private.exam_prep_mentor_service_status
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_mentor_assignments_audit_v1 on private.exam_prep_mentor_assignments;
create trigger exam_prep_mentor_assignments_audit_v1
after insert or update or delete on private.exam_prep_mentor_assignments
for each row execute function private.exam_prep_audit_row_change_v1();

-- -----------------------------------------------------------------------------
-- Upgrade P0-04 capability RPC: mentor assignment is effective only when ALL
-- gates are true: global Mentor enabled, entitlement active, operational service
-- state assigned_active, and a current component-scoped assignment exists.
-- Global OFF / kill switch still forces every capability false.
-- -----------------------------------------------------------------------------
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
  ), svc as (
    select s.learner_user_id, s.service_status
    from private.exam_prep_mentor_service_status s, caller u
    where s.learner_user_id = u.user_id
  ), assn as (
    select a.learner_user_id, bool_or(true) as has_active_assignment
    from private.exam_prep_mentor_assignments a, caller u
    where a.learner_user_id = u.user_id
      and a.assignment_status = 'active'
      and a.valid_from <= now()
      and (a.valid_until is null or a.valid_until > now())
      and a.component_code in ('P1','P5')
    group by a.learner_user_id
  ), effective as (
    select
      caller.user_id,
      cfg.program_key,
      cfg.rollout_state,
      cfg.core_enabled,
      cfg.ai_enabled,
      cfg.mentor_enabled,
      cfg.kill_switch,
      coalesce(ent.core_access, false) as ent_core,
      coalesce(ent.ai_assist, false) as ent_ai,
      coalesce(ent.mentor_care_entitled, false) as ent_mentor,
      coalesce(svc.service_status = 'assigned_active', false) as service_assigned_active,
      coalesce(assn.has_active_assignment, false) as has_active_assignment
    from caller
    left join cfg on true
    left join ent on ent.user_id = caller.user_id
    left join svc on svc.learner_user_id = caller.user_id
    left join assn on assn.learner_user_id = caller.user_id
  )
  select
    coalesce(e.program_key, 'math_as_p1_p5'::text) as program_key,
    coalesce(e.rollout_state, 'off'::text) as rollout_state,
    coalesce(
      e.user_id is not null
      and not e.kill_switch
      and e.core_enabled
      and e.rollout_state <> 'off'
      and e.ent_core,
      false
    ) as core_access,
    coalesce(
      e.user_id is not null
      and not e.kill_switch
      and e.core_enabled
      and e.ai_enabled
      and e.rollout_state <> 'off'
      and e.ent_core
      and e.ent_ai,
      false
    ) as ai_assist,
    coalesce(
      e.user_id is not null
      and not e.kill_switch
      and e.core_enabled
      and e.mentor_enabled
      and e.rollout_state <> 'off'
      and e.ent_core
      and e.ent_mentor,
      false
    ) as mentor_care_entitled,
    coalesce(
      e.user_id is not null
      and not e.kill_switch
      and e.core_enabled
      and e.mentor_enabled
      and e.rollout_state <> 'off'
      and e.ent_core
      and e.ent_mentor
      and e.service_assigned_active
      and e.has_active_assignment,
      false
    ) as mentor_assignment_active,
    coalesce(
      e.user_id is not null
      and not e.kill_switch
      and e.core_enabled
      and e.mentor_enabled
      and e.rollout_state <> 'off'
      and e.ent_core
      and e.ent_mentor
      and e.service_assigned_active
      and e.has_active_assignment,
      false
    ) as mentor_authority,
    coalesce(e.kill_switch, true) as kill_switch
  from effective e;
$$;

revoke execute on function public.get_exam_prep_capabilities_v1() from public, anon;
grant execute on function public.get_exam_prep_capabilities_v1() to authenticated, service_role;

-- Read-only own Exam Profile RPC. No write endpoint is opened in P0-05.
create or replace function public.get_exam_prep_exam_profile_v1()
returns table (
  user_id uuid,
  program_version_id bigint,
  exam_series text,
  target_grade text,
  total_student_hours_available numeric,
  mathematics_hours_budget numeric,
  active_week_no smallint,
  updated_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    p.user_id,
    p.program_version_id,
    p.exam_series,
    p.target_grade,
    p.total_student_hours_available,
    p.mathematics_hours_budget,
    p.active_week_no,
    p.updated_at
  from private.exam_prep_exam_profiles p
  where p.user_id = auth.uid();
$$;

revoke execute on function public.get_exam_prep_exam_profile_v1() from public, anon;
grant execute on function public.get_exam_prep_exam_profile_v1() to authenticated, service_role;

commit;
