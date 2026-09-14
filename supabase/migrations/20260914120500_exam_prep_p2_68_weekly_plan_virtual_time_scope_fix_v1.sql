begin;

-- P2-68 hotfix: exam_prep_weekly_plan_items is owned through plan_id and does
-- not carry user_id directly. Resolve the learner from the parent weekly plan
-- before applying synthetic virtual academic time. Real learners remain on the
-- normal server clock and all existing trigger placements remain unchanged.

create or replace function private.stamp_exam_prep_synthetic_academic_time_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_user_id uuid;
  v_now timestamptz;
begin
  if tg_table_name='exam_prep_weekly_plan_items' then
    select p.user_id into v_user_id
    from private.exam_prep_weekly_plans p
    where p.id=new.plan_id;
  else
    v_user_id:=new.user_id;
  end if;

  if v_user_id is null
     or not exists(
       select 1
       from private.exam_prep_synthetic_identities s
       where s.user_id=v_user_id
     ) then
    return new;
  end if;

  v_now:=private.exam_prep_effective_academic_now_v1(v_user_id);

  if tg_table_name='exam_prep_evidence_events' then
    new.created_at:=v_now;
  elsif tg_table_name='exam_prep_correction_cases' then
    if tg_op='INSERT' then
      new.opened_at:=v_now;
    end if;
    new.updated_at:=v_now;
    if tg_op='UPDATE'
       and new.resolved_at is not null
       and new.resolved_at is distinct from old.resolved_at then
      new.resolved_at:=v_now;
    end if;
  elsif tg_table_name='exam_prep_retest_events' then
    if tg_op='INSERT' then
      new.created_at:=v_now;
    end if;
    if tg_op='UPDATE'
       and new.completed_at is not null
       and new.completed_at is distinct from old.completed_at then
      new.completed_at:=v_now;
    end if;
  elsif tg_table_name='exam_prep_correction_actions' then
    new.created_at:=v_now;
  elsif tg_table_name='exam_prep_weekly_plans' then
    new.generated_at:=v_now;
  elsif tg_table_name='exam_prep_weekly_plan_items' then
    new.created_at:=v_now;
  end if;

  return new;
end;
$$;

revoke all on function private.stamp_exam_prep_synthetic_academic_time_v1()
  from public,anon,authenticated;

commit;
