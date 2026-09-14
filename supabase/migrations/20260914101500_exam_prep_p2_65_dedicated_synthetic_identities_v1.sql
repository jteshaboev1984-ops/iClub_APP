begin;

-- P2-65: dedicated synthetic learner/mentor identities.
-- Synthetic identities remain structurally separate from real beta controls.
-- Mentor-shaped synthetic identities receive no real staff privilege in this stage.

alter table private.exam_prep_synthetic_identities
  add column if not exists identity_kind text;
alter table private.exam_prep_synthetic_identities
  add column if not exists fixture_profile_key text;

-- P2-64 production verification established zero persistent synthetic identities.
-- Fail closed if an unexpected row would otherwise receive fabricated provenance.
do $$
begin
  if exists(
    select 1
    from private.exam_prep_synthetic_identities
    where identity_kind is null or fixture_profile_key is null
  ) then
    raise exception 'exam_prep_p2_65_existing_synthetic_identity_missing_dedicated_provenance';
  end if;
end;
$$;

alter table private.exam_prep_synthetic_identities
  alter column identity_kind set not null;
alter table private.exam_prep_synthetic_identities
  alter column fixture_profile_key set not null;

alter table private.exam_prep_synthetic_identities
  drop constraint if exists exam_prep_synthetic_identities_identity_kind_check;
alter table private.exam_prep_synthetic_identities
  add constraint exam_prep_synthetic_identities_identity_kind_check
  check(identity_kind in ('learner','mentor'));

alter table private.exam_prep_synthetic_identities
  drop constraint if exists exam_prep_synthetic_identities_fixture_profile_key_check;
alter table private.exam_prep_synthetic_identities
  add constraint exam_prep_synthetic_identities_fixture_profile_key_check
  check(fixture_profile_key ~ '^SVF-[A-Z0-9][A-Z0-9-]{3,63}$');

create index if not exists exam_prep_synthetic_identities_run_kind_idx
  on private.exam_prep_synthetic_identities(run_id,identity_kind,user_id);

-- Extend identity provenance immutability. Registration is allowed only while
-- the owning synthetic run is pre-terminal and cleanup has not started.
create or replace function private.enforce_exam_prep_synthetic_identity_registration_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_preflight jsonb;
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
begin
  if tg_op='INSERT' then
    if new.identity_status<>'active' or new.retired_at is not null then
      raise exception 'exam_prep_synthetic_identity_must_register_active';
    end if;
    if new.identity_kind not in ('learner','mentor') then
      raise exception 'exam_prep_synthetic_identity_kind_invalid';
    end if;
    if new.fixture_profile_key is null
       or new.fixture_profile_key !~ '^SVF-[A-Z0-9][A-Z0-9-]{3,63}$' then
      raise exception 'exam_prep_synthetic_fixture_profile_key_invalid';
    end if;

    select * into v_run
    from private.exam_prep_synthetic_validation_runs r
    where r.run_id=new.run_id
    for update;
    if v_run.run_id is null then
      raise exception 'exam_prep_synthetic_identity_run_not_registered';
    end if;
    if v_run.run_status not in ('registered','running')
       or v_run.cleanup_status<>'not_started' then
      raise exception 'exam_prep_synthetic_identity_run_not_open_for_fixture_registration';
    end if;

    v_preflight:=private.exam_prep_synthetic_identity_preflight_v1(new.user_id);
    if coalesce((v_preflight->>'eligible')::boolean,false) is not true then
      raise exception 'exam_prep_synthetic_identity_preflight_failed: %',v_preflight->>'reason_code';
    end if;

    new.evidence_ref:=trim(new.evidence_ref);
    new.purpose:=trim(new.purpose);
    new.fixture_profile_key:=trim(new.fixture_profile_key);
    new.registered_at:=coalesce(new.registered_at,now());
    new.created_at:=coalesce(new.created_at,now());
    new.updated_at:=now();
    return new;
  end if;

  if new.user_id is distinct from old.user_id
     or new.run_id is distinct from old.run_id
     or new.identity_kind is distinct from old.identity_kind
     or new.fixture_profile_key is distinct from old.fixture_profile_key
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

-- Real staff roles are a production human-authority surface. Synthetic mentor
-- identities stay unprivileged until the later governed Mentor Technical stage.
create or replace function private.enforce_exam_prep_synthetic_staff_role_firewall_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if private.is_exam_prep_synthetic_identity_v1(new.user_id) then
    raise exception 'exam_prep_synthetic_staff_role_forbidden_until_mentor_technical_gate';
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_synthetic_staff_role_firewall_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_staff_roles_synthetic_firewall_v1
  on private.exam_prep_staff_roles;
create trigger exam_prep_staff_roles_synthetic_firewall_v1
before insert or update on private.exam_prep_staff_roles
for each row execute function private.enforce_exam_prep_synthetic_staff_role_firewall_v1();

-- Synthetic assignment anchors are permitted only inside one synthetic run and
-- only with learner->mentor identity kinds. Any real/synthetic crossing fails.
create or replace function private.enforce_exam_prep_synthetic_assignment_firewall_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_learner private.exam_prep_synthetic_identities%rowtype;
  v_mentor private.exam_prep_synthetic_identities%rowtype;
  v_learner_synth boolean:=false;
  v_mentor_synth boolean:=false;
begin
  select * into v_learner
  from private.exam_prep_synthetic_identities s
  where s.user_id=new.learner_user_id;
  v_learner_synth:=v_learner.user_id is not null;

  select * into v_mentor
  from private.exam_prep_synthetic_identities s
  where s.user_id=new.mentor_user_id;
  v_mentor_synth:=v_mentor.user_id is not null;

  if not v_learner_synth and not v_mentor_synth then
    return new;
  end if;

  if v_learner_synth is distinct from v_mentor_synth then
    raise exception 'exam_prep_synthetic_assignment_real_boundary_crossing';
  end if;
  if v_learner.run_id is distinct from v_mentor.run_id then
    raise exception 'exam_prep_synthetic_assignment_cross_run_forbidden';
  end if;
  if v_learner.identity_kind<>'learner' or v_mentor.identity_kind<>'mentor' then
    raise exception 'exam_prep_synthetic_assignment_identity_kind_mismatch';
  end if;
  if v_learner.identity_status<>'active' or v_mentor.identity_status<>'active' then
    raise exception 'exam_prep_synthetic_assignment_requires_active_identities';
  end if;

  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_synthetic_assignment_firewall_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_mentor_assignments_synthetic_firewall_v1
  on private.exam_prep_mentor_assignments;
create trigger exam_prep_mentor_assignments_synthetic_firewall_v1
before insert or update on private.exam_prep_mentor_assignments
for each row execute function private.enforce_exam_prep_synthetic_assignment_firewall_v1();

-- Count-only invariant report. It exposes no learner identifiers.
create or replace function private.exam_prep_synthetic_identity_isolation_report_v1()
returns jsonb
language sql
stable security definer
set search_path=''
as $$
  with counts as (
    select
      (select count(*) from private.exam_prep_synthetic_identities)::int as synthetic_identities,
      (
        select count(*)
        from private.exam_prep_synthetic_identities s
        join private.exam_prep_staff_roles r on r.user_id=s.user_id
      )::int as synthetic_staff_role_rows,
      (
        select count(*)
        from private.exam_prep_mentor_assignments a
        left join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        left join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
        where (l.user_id is null) is distinct from (m.user_id is null)
      )::int as real_synthetic_assignment_crossings,
      (
        select count(*)
        from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
        where l.run_id is distinct from m.run_id
      )::int as cross_run_assignments,
      (
        select count(*)
        from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
        where l.identity_kind<>'learner' or m.identity_kind<>'mentor'
      )::int as identity_kind_assignment_mismatches
  )
  select jsonb_build_object(
    'synthetic_identities',synthetic_identities,
    'synthetic_staff_role_rows',synthetic_staff_role_rows,
    'real_synthetic_assignment_crossings',real_synthetic_assignment_crossings,
    'cross_run_assignments',cross_run_assignments,
    'identity_kind_assignment_mismatches',identity_kind_assignment_mismatches,
    'eligible',
      synthetic_staff_role_rows=0
      and real_synthetic_assignment_crossings=0
      and cross_run_assignments=0
      and identity_kind_assignment_mismatches=0
  )
  from counts;
$$;
revoke all on function private.exam_prep_synthetic_identity_isolation_report_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_identity_isolation_report_v1() to service_role;

-- Existing production state must already satisfy the new isolation contract.
do $$
declare
  v_report jsonb;
begin
  v_report:=private.exam_prep_synthetic_identity_isolation_report_v1();
  if coalesce((v_report->>'eligible')::boolean,false) is not true then
    raise exception 'exam_prep_p2_65_synthetic_identity_isolation_violation: %',v_report;
  end if;
end;
$$;

commit;