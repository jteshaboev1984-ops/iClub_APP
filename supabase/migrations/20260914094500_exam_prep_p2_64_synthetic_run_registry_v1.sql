begin;

-- P2-64: every persistent synthetic identity must belong to one explicit
-- synthetic validation run. Run provenance is immutable; lifecycle changes are
-- service-role-only and append an immutable event trail.

create table if not exists private.exam_prep_synthetic_validation_runs(
  run_id text primary key
    check(run_id ~ '^SV-[A-Z0-9][A-Z0-9-]{7,63}$'),
  scenario_set_version text not null
    check(char_length(trim(scenario_set_version))>=3),
  git_sha text not null
    check(git_sha ~ '^[0-9a-f]{40}$'),
  schema_generation text not null
    check(char_length(trim(schema_generation))>=3),
  deterministic_seed bigint not null
    check(deterministic_seed>=0),
  capability_mode text not null
    check(capability_mode in ('core','ai_shadow','mentor_technical')),
  run_status text not null default 'registered'
    check(run_status in ('registered','running','completed','failed','aborted')),
  cleanup_status text not null default 'not_started'
    check(cleanup_status in ('not_started','pending','running','clean','failed')),
  evidence_ref text not null
    check(char_length(trim(evidence_ref))>=8),
  audit_result jsonb not null default '{}'::jsonb
    check(jsonb_typeof(audit_result)='object'),
  failure_code text,
  started_at timestamptz,
  finished_at timestamptz,
  cleanup_started_at timestamptz,
  cleaned_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check((cleanup_status='clean' and cleaned_at is not null) or cleanup_status<>'clean')
);

alter table private.exam_prep_synthetic_validation_runs enable row level security;
revoke all on table private.exam_prep_synthetic_validation_runs from public,anon,authenticated;
revoke all on table private.exam_prep_synthetic_validation_runs from service_role;
grant select on table private.exam_prep_synthetic_validation_runs to service_role;

create table if not exists private.exam_prep_synthetic_validation_run_events(
  id bigint generated always as identity primary key,
  run_id text not null references private.exam_prep_synthetic_validation_runs(run_id) on delete restrict,
  event_type text not null
    check(event_type in (
      'registered','run_started','run_completed','run_failed','run_aborted',
      'cleanup_pending','cleanup_started','cleanup_clean','cleanup_failed'
    )),
  run_status text not null,
  cleanup_status text not null,
  details jsonb not null default '{}'::jsonb
    check(jsonb_typeof(details)='object'),
  created_at timestamptz not null default now()
);

create index if not exists exam_prep_synthetic_validation_run_events_run_idx
  on private.exam_prep_synthetic_validation_run_events(run_id,id);

alter table private.exam_prep_synthetic_validation_run_events enable row level security;
revoke all on table private.exam_prep_synthetic_validation_run_events from public,anon,authenticated;
revoke all on table private.exam_prep_synthetic_validation_run_events from service_role;
grant select on table private.exam_prep_synthetic_validation_run_events to service_role;

-- No persistent synthetic identity may exist without a canonical run owner.
alter table private.exam_prep_synthetic_identities
  add column if not exists run_id text;

-- P2-63 production verification established zero registry rows before P2-64.
-- Still fail closed if this migration is replayed against an unexpected state.
do $$
begin
  if exists(
    select 1
    from private.exam_prep_synthetic_identities
    where run_id is null
  ) then
    raise exception 'exam_prep_p2_64_existing_synthetic_identity_without_run_owner';
  end if;
end;
$$;

alter table private.exam_prep_synthetic_identities
  alter column run_id set not null;

alter table private.exam_prep_synthetic_identities
  drop constraint if exists exam_prep_synthetic_identities_run_id_fkey;
alter table private.exam_prep_synthetic_identities
  add constraint exam_prep_synthetic_identities_run_id_fkey
  foreign key(run_id)
  references private.exam_prep_synthetic_validation_runs(run_id)
  on delete restrict;

create index if not exists exam_prep_synthetic_identities_run_idx
  on private.exam_prep_synthetic_identities(run_id,user_id);

-- Extend the P2-63 provenance immutability rule with immutable run ownership.
create or replace function private.enforce_exam_prep_synthetic_identity_registration_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_preflight jsonb;
begin
  if tg_op='INSERT' then
    if new.identity_status<>'active' or new.retired_at is not null then
      raise exception 'exam_prep_synthetic_identity_must_register_active';
    end if;
    if new.run_id is null or not exists(
      select 1
      from private.exam_prep_synthetic_validation_runs r
      where r.run_id=new.run_id
    ) then
      raise exception 'exam_prep_synthetic_identity_run_not_registered';
    end if;

    v_preflight:=private.exam_prep_synthetic_identity_preflight_v1(new.user_id);
    if coalesce((v_preflight->>'eligible')::boolean,false) is not true then
      raise exception 'exam_prep_synthetic_identity_preflight_failed: %',v_preflight->>'reason_code';
    end if;

    new.evidence_ref:=trim(new.evidence_ref);
    new.purpose:=trim(new.purpose);
    new.registered_at:=coalesce(new.registered_at,now());
    new.created_at:=coalesce(new.created_at,now());
    new.updated_at:=now();
    return new;
  end if;

  if new.user_id is distinct from old.user_id
     or new.run_id is distinct from old.run_id
     or new.evidence_ref is distinct from old.evidence_ref
     or new.purpose is distinct from old.purpose
     or new.registered_at is distinct from old.registered_at
     or new.created_at is distinct from old.created_at then
    raise exception 'exam_prep_synthetic_identity_provenance_immutable';
  end if;

  if old.identity_status='retired' and new.identity_status<>'retired' then
    raise exception 'exam_prep_synthetic_identity_cannot_reactivate';
  end if;

  if new.identity_status='retired' and new.retired_at is null then
    new.retired_at:=now();
  elsif new.identity_status='active' and new.retired_at is not null then
    raise exception 'exam_prep_active_synthetic_identity_cannot_have_retired_at';
  end if;

  new.updated_at:=now();
  return new;
end;
$$;

revoke all on function private.enforce_exam_prep_synthetic_identity_registration_v1() from public,anon,authenticated;

create or replace function private.register_exam_prep_synthetic_validation_run_v1(
  p_run_id text,
  p_scenario_set_version text,
  p_git_sha text,
  p_schema_generation text,
  p_deterministic_seed bigint,
  p_capability_mode text,
  p_evidence_ref text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_row private.exam_prep_synthetic_validation_runs%rowtype;
begin
  if p_run_id is null or p_run_id !~ '^SV-[A-Z0-9][A-Z0-9-]{7,63}$' then
    raise exception 'exam_prep_synthetic_run_id_invalid';
  end if;
  if p_git_sha is null or p_git_sha !~ '^[0-9a-f]{40}$' then
    raise exception 'exam_prep_synthetic_run_git_sha_invalid';
  end if;
  if p_deterministic_seed is null or p_deterministic_seed<0 then
    raise exception 'exam_prep_synthetic_run_seed_invalid';
  end if;
  if p_capability_mode not in ('core','ai_shadow','mentor_technical') then
    raise exception 'exam_prep_synthetic_run_capability_invalid';
  end if;

  insert into private.exam_prep_synthetic_validation_runs(
    run_id,scenario_set_version,git_sha,schema_generation,
    deterministic_seed,capability_mode,evidence_ref
  ) values(
    trim(p_run_id),trim(p_scenario_set_version),p_git_sha,trim(p_schema_generation),
    p_deterministic_seed,p_capability_mode,trim(p_evidence_ref)
  ) returning * into v_row;

  insert into private.exam_prep_synthetic_validation_run_events(
    run_id,event_type,run_status,cleanup_status,details
  ) values(
    v_row.run_id,'registered',v_row.run_status,v_row.cleanup_status,
    jsonb_build_object(
      'scenario_set_version',v_row.scenario_set_version,
      'git_sha',v_row.git_sha,
      'schema_generation',v_row.schema_generation,
      'deterministic_seed',v_row.deterministic_seed,
      'capability_mode',v_row.capability_mode,
      'evidence_ref',v_row.evidence_ref
    )
  );

  return to_jsonb(v_row);
exception
  when unique_violation then
    raise exception 'exam_prep_synthetic_run_already_registered';
end;
$$;

revoke all on function private.register_exam_prep_synthetic_validation_run_v1(text,text,text,text,bigint,text,text)
  from public,anon,authenticated;
grant execute on function private.register_exam_prep_synthetic_validation_run_v1(text,text,text,text,bigint,text,text)
  to service_role;

create or replace function private.transition_exam_prep_synthetic_validation_run_v1(
  p_run_id text,
  p_expected_status text,
  p_new_status text,
  p_audit_result jsonb default null,
  p_failure_code text default null,
  p_details jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_old private.exam_prep_synthetic_validation_runs%rowtype;
  v_new private.exam_prep_synthetic_validation_runs%rowtype;
  v_event text;
begin
  if p_details is null or jsonb_typeof(p_details)<>'object' then
    raise exception 'exam_prep_synthetic_run_details_invalid';
  end if;
  if p_audit_result is not null and jsonb_typeof(p_audit_result)<>'object' then
    raise exception 'exam_prep_synthetic_run_audit_result_invalid';
  end if;

  select * into v_old
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_old.run_id is null then
    raise exception 'exam_prep_synthetic_run_not_found';
  end if;
  if v_old.run_status<>p_expected_status then
    raise exception 'exam_prep_synthetic_run_status_changed expected=% actual=%',p_expected_status,v_old.run_status;
  end if;

  if not (
    (v_old.run_status='registered' and p_new_status in ('running','aborted'))
    or (v_old.run_status='running' and p_new_status in ('completed','failed','aborted'))
  ) then
    raise exception 'exam_prep_synthetic_run_transition_invalid %->%',v_old.run_status,p_new_status;
  end if;

  if p_new_status='failed' and nullif(trim(p_failure_code),'') is null then
    raise exception 'exam_prep_synthetic_run_failure_code_required';
  end if;

  update private.exam_prep_synthetic_validation_runs
  set run_status=p_new_status,
      audit_result=coalesce(p_audit_result,audit_result),
      failure_code=case when p_new_status='failed' then trim(p_failure_code) else failure_code end,
      started_at=case when p_new_status='running' and started_at is null then now() else started_at end,
      finished_at=case when p_new_status in ('completed','failed','aborted') then now() else finished_at end,
      updated_at=now()
  where run_id=p_run_id
  returning * into v_new;

  v_event:=case p_new_status
    when 'running' then 'run_started'
    when 'completed' then 'run_completed'
    when 'failed' then 'run_failed'
    when 'aborted' then 'run_aborted'
  end;

  insert into private.exam_prep_synthetic_validation_run_events(
    run_id,event_type,run_status,cleanup_status,details
  ) values(
    v_new.run_id,v_event,v_new.run_status,v_new.cleanup_status,
    p_details || jsonb_build_object('previous_run_status',v_old.run_status)
  );

  return to_jsonb(v_new);
end;
$$;

revoke all on function private.transition_exam_prep_synthetic_validation_run_v1(text,text,text,jsonb,text,jsonb)
  from public,anon,authenticated;
grant execute on function private.transition_exam_prep_synthetic_validation_run_v1(text,text,text,jsonb,text,jsonb)
  to service_role;

create or replace function private.transition_exam_prep_synthetic_cleanup_v1(
  p_run_id text,
  p_expected_cleanup_status text,
  p_new_cleanup_status text,
  p_details jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_old private.exam_prep_synthetic_validation_runs%rowtype;
  v_new private.exam_prep_synthetic_validation_runs%rowtype;
  v_event text;
begin
  if p_details is null or jsonb_typeof(p_details)<>'object' then
    raise exception 'exam_prep_synthetic_cleanup_details_invalid';
  end if;

  select * into v_old
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_old.run_id is null then
    raise exception 'exam_prep_synthetic_run_not_found';
  end if;
  if v_old.cleanup_status<>p_expected_cleanup_status then
    raise exception 'exam_prep_synthetic_cleanup_status_changed expected=% actual=%',p_expected_cleanup_status,v_old.cleanup_status;
  end if;
  if v_old.run_status not in ('completed','failed','aborted') then
    raise exception 'exam_prep_synthetic_cleanup_requires_terminal_run';
  end if;

  if not (
    (v_old.cleanup_status='not_started' and p_new_cleanup_status='pending')
    or (v_old.cleanup_status='pending' and p_new_cleanup_status in ('running','failed'))
    or (v_old.cleanup_status='running' and p_new_cleanup_status in ('clean','failed'))
    or (v_old.cleanup_status='failed' and p_new_cleanup_status='pending')
  ) then
    raise exception 'exam_prep_synthetic_cleanup_transition_invalid %->%',v_old.cleanup_status,p_new_cleanup_status;
  end if;

  update private.exam_prep_synthetic_validation_runs
  set cleanup_status=p_new_cleanup_status,
      cleanup_started_at=case when p_new_cleanup_status='running' and cleanup_started_at is null then now() else cleanup_started_at end,
      cleaned_at=case when p_new_cleanup_status='clean' then now() else cleaned_at end,
      updated_at=now()
  where run_id=p_run_id
  returning * into v_new;

  v_event:=case p_new_cleanup_status
    when 'pending' then 'cleanup_pending'
    when 'running' then 'cleanup_started'
    when 'clean' then 'cleanup_clean'
    when 'failed' then 'cleanup_failed'
  end;

  insert into private.exam_prep_synthetic_validation_run_events(
    run_id,event_type,run_status,cleanup_status,details
  ) values(
    v_new.run_id,v_event,v_new.run_status,v_new.cleanup_status,
    p_details || jsonb_build_object('previous_cleanup_status',v_old.cleanup_status)
  );

  return to_jsonb(v_new);
end;
$$;

revoke all on function private.transition_exam_prep_synthetic_cleanup_v1(text,text,text,jsonb)
  from public,anon,authenticated;
grant execute on function private.transition_exam_prep_synthetic_cleanup_v1(text,text,text,jsonb)
  to service_role;

-- Immutable append-only event provenance, including against privileged accidental
-- UPDATE/DELETE outside migrations.
create or replace function private.prevent_exam_prep_synthetic_run_event_mutation_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  raise exception 'exam_prep_synthetic_run_event_immutable';
end;
$$;

revoke all on function private.prevent_exam_prep_synthetic_run_event_mutation_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_synthetic_run_event_immutable_v1
  on private.exam_prep_synthetic_validation_run_events;
create trigger exam_prep_synthetic_run_event_immutable_v1
before update or delete on private.exam_prep_synthetic_validation_run_events
for each row execute function private.prevent_exam_prep_synthetic_run_event_mutation_v1();

commit;
