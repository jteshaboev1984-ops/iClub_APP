begin;

-- P2-77 backward-compatibility hardening.
-- P2-65 established a fail-closed error contract for mentor-shaped synthetic
-- identities outside an explicitly opened Mentor Technical run. Preserve that
-- contract while still allowing P2-77's governed mentor_technical fixtures.
create or replace function private.enforce_exam_prep_synthetic_staff_role_firewall_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_identity private.exam_prep_synthetic_identities%rowtype;
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
begin
  select * into v_identity
  from private.exam_prep_synthetic_identities s
  where s.user_id=new.user_id;

  if v_identity.user_id is null then
    return new;
  end if;

  select * into v_run
  from private.exam_prep_synthetic_validation_runs r
  where r.run_id=v_identity.run_id;

  -- A learner-shaped synthetic identity can never become human staff, even
  -- inside a valid Mentor Technical run.
  if v_identity.identity_kind<>'mentor' then
    raise exception 'exam_prep_synthetic_staff_role_requires_open_mentor_technical_run';
  end if;

  -- Preserve the P2-65 denial contract for mentor-shaped fixtures that belong
  -- to Core/AI/other runs. P2-77 opens authority only for mentor_technical.
  if v_run.run_id is null or v_run.capability_mode<>'mentor_technical' then
    raise exception 'exam_prep_synthetic_staff_role_forbidden_until_mentor_technical_gate';
  end if;

  -- Even a mentor_technical fixture loses authority when its identity/run is
  -- no longer active, or when cleanup has started.
  if v_identity.identity_status<>'active'
     or v_run.run_status not in ('registered','running')
     or v_run.cleanup_status<>'not_started'
     or new.role_code not in ('mentor','lead_mentor','academic_moderator','mentor_ops','safeguarding_lead') then
    raise exception 'exam_prep_synthetic_staff_role_requires_open_mentor_technical_run';
  end if;

  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_synthetic_staff_role_firewall_v1() from public,anon,authenticated;

commit;
