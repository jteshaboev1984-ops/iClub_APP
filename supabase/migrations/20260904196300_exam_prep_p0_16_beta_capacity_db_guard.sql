-- P0-16 defense-in-depth capacity guard.
--
-- The governed RPC already enforces planned_size as an upper bound (3..12).
-- This migration closes the remaining server-side bypass path by enforcing the
-- same invariant directly on private tables, including concurrent/direct writes.
-- It is additive, activates no learner, grants no entitlement, and leaves the
-- production feature config fail-closed.

begin;

create or replace function private.enforce_exam_prep_beta_member_capacity_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_capacity smallint;
  v_occupied integer;
begin
  -- A removed historical row does not occupy a current cohort seat.
  if new.member_status='removed' then
    return new;
  end if;

  -- Serialize all membership additions/reactivations for a cohort. This makes
  -- the capacity check safe against concurrent direct service-role writes too.
  select planned_size
    into v_capacity
  from private.exam_prep_beta_cohorts
  where id=new.cohort_id
  for update;

  if v_capacity is null then
    raise exception 'exam_prep_beta_capacity_cohort_not_found' using errcode='P0002';
  end if;

  select count(*)
    into v_occupied
  from private.exam_prep_beta_members m
  where m.cohort_id=new.cohort_id
    and m.member_status<>'removed'
    and (tg_op='INSERT' or m.id<>new.id);

  if v_occupied>=v_capacity then
    raise exception 'exam_prep_beta_capacity_reached_db: capacity %, occupied %',v_capacity,v_occupied;
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_exam_prep_beta_member_capacity_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_beta_member_capacity_guard_v1
on private.exam_prep_beta_members;
create trigger exam_prep_beta_member_capacity_guard_v1
before insert or update of cohort_id,member_status
on private.exam_prep_beta_members
for each row execute function private.enforce_exam_prep_beta_member_capacity_v1();

create or replace function private.enforce_exam_prep_beta_cohort_capacity_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_occupied integer;
begin
  if new.planned_size is not distinct from old.planned_size then
    return new;
  end if;

  select count(*)
    into v_occupied
  from private.exam_prep_beta_members m
  where m.cohort_id=new.id
    and m.member_status<>'removed';

  if v_occupied>new.planned_size then
    raise exception 'exam_prep_beta_capacity_shrink_below_roster: capacity %, occupied %',new.planned_size,v_occupied;
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_exam_prep_beta_cohort_capacity_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_beta_cohort_capacity_guard_v1
on private.exam_prep_beta_cohorts;
create trigger exam_prep_beta_cohort_capacity_guard_v1
before update of planned_size
on private.exam_prep_beta_cohorts
for each row execute function private.enforce_exam_prep_beta_cohort_capacity_v1();

-- Deployment invariant: capacity hardening must never open Exam Prep.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P0-16 DB capacity guard requires fail-closed feature state';
  end if;
end
$$;

commit;
