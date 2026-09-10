-- P2-14: active_week_no is shared planning time derived from the learner's actual Exam Prep start.
-- It may advance planning windows, but it must never promote P1/P5 academic stages by calendar alone.
-- No legacy Practice/Tour/history tables are touched.

begin;

create or replace function private.exam_prep_effective_active_week_v1(p_user_id uuid)
returns smallint
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_elapsed_weeks integer;
begin
  if p_user_id is null then return null; end if;

  select * into v_profile
  from private.exam_prep_exam_profiles
  where user_id=p_user_id;

  if v_profile.user_id is null then return null; end if;

  v_elapsed_weeks:=greatest(
    0,
    floor(extract(epoch from (now()-v_profile.created_at))/604800.0)::integer
  );

  return least(
    36,
    greatest(coalesce(v_profile.active_week_no,1)::integer,1+v_elapsed_weeks)
  )::smallint;
end;
$$;
revoke all on function private.exam_prep_effective_active_week_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_effective_active_week_v1(uuid) to service_role;

create or replace function public.get_exam_prep_exam_profile_v1()
returns table(
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
set search_path=''
as $$
  select p.user_id,p.program_version_id,p.exam_series,p.target_grade,
         p.total_student_hours_available,p.mathematics_hours_budget,
         private.exam_prep_effective_active_week_v1(p.user_id),p.updated_at
  from private.exam_prep_exam_profiles p
  where p.user_id=auth.uid();
$$;
revoke execute on function public.get_exam_prep_exam_profile_v1() from public,anon;
grant execute on function public.get_exam_prep_exam_profile_v1() to authenticated,service_role;

create or replace function public.get_exam_prep_weekly_plan_safe_v2(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_effective_week smallint;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_recovery private.exam_prep_recovery_cases%rowtype;
  v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_effective_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_effective_week is null then raise exception 'exam_prep_profile_required'; end if;

  -- A plan from an earlier active week is historical planning, not the learner's current plan.
  -- Returning no current plan lets the existing client request the governed generator without a frontend change.
  select * into v_plan
  from private.exam_prep_weekly_plans
  where user_id=v_uid and component_code=p_component_code and status='active'
    and active_week_no=v_effective_week
  order by generated_at desc limit 1;

  if v_plan.id is null then
    return jsonb_build_object(
      'component_code',p_component_code,
      'active_week_no',v_effective_week,
      'plan',null,
      'items','[]'::jsonb,
      'recovery',jsonb_build_object('active',false,'recovery_mode','normal')
    );
  end if;

  if v_plan.recovery_case_id is not null then
    select * into v_recovery
    from private.exam_prep_recovery_cases
    where id=v_plan.recovery_case_id and user_id=v_uid and component_code=p_component_code;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'priority_order',i.priority_order,
    'item_type',i.item_type,
    'skill_code',i.skill_code,
    'correction_case_id',i.correction_case_id,
    'due_at',i.due_at,
    'action_code',i.action_code,
    'action_payload',i.action_payload,
    'status',i.status
  ) order by i.priority_order),'[]'::jsonb)
  into v_items
  from private.exam_prep_weekly_plan_items i
  where i.plan_id=v_plan.id;

  return jsonb_build_object(
    'plan_id',v_plan.id,
    'component_code',v_plan.component_code,
    'active_week_no',v_plan.active_week_no,
    'plan_version',v_plan.plan_version,
    'recovery_mode',v_plan.recovery_mode,
    'policy_note',v_plan.policy_note,
    'planning_horizon_days',v_plan.planning_horizon_days,
    'allocation_policy',v_plan.allocation_policy,
    'recovery',case when v_recovery.id is null then jsonb_build_object(
      'active',false,'recovery_mode','normal'
    ) else jsonb_build_object(
      'active',v_recovery.status='active',
      'missed_days',v_recovery.missed_days,
      'recovery_mode',v_recovery.recovery_mode,
      'source_gap',v_recovery.source_gap,
      'plan_review_required',v_recovery.plan_review_required,
      'feasibility_review_required',v_recovery.feasibility_review_required,
      'recovery_window_ends_on',v_recovery.recovery_window_ends_on,
      'allocation_policy',v_recovery.allocation_policy,
      'evidence_standards_unchanged',true,
      'stage_changed_by_recovery',false
    ) end,
    'items',v_items
  );
end;
$$;
revoke execute on function public.get_exam_prep_weekly_plan_safe_v2(text) from public,anon;
grant execute on function public.get_exam_prep_weekly_plan_safe_v2(text) to authenticated,service_role;

create or replace function public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_effective_week smallint;
  v_base jsonb;
  v_plan uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_failed record;
  v_replace smallint;
  v_count int;
  v_applied int:=0;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_effective_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_effective_week is null then raise exception 'exam_prep_profile_required'; end if;

  -- Persist planning time forward only. This cannot reduce a week and cannot change academic evidence/stage by itself.
  update private.exam_prep_exam_profiles
  set active_week_no=v_effective_week,updated_at=now(),updated_by=v_uid
  where user_id=v_uid and active_week_no<v_effective_week;

  v_base:=public.generate_exam_prep_weekly_plan_safe_v2(p_component_code);
  v_plan:=(v_base->>'plan_id')::uuid;

  select rv.* into v_case
  from private.exam_prep_progress_revalidation_cases rv
  join private.exam_prep_recovery_cases rc on rc.id=rv.recovery_case_id
  where rv.user_id=v_uid and rv.component_code=p_component_code
    and rv.status='refresh_recommended' and rc.status='active'
  order by rv.updated_at desc limit 1;

  if v_case.id is not null then
    for v_failed in
      select i.skill_code
      from private.exam_prep_progress_revalidation_items i
      where i.case_id=v_case.id and i.status='completed' and i.passed is false
      order by i.item_order
    loop
      continue when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.item_type in ('retest','correction')
      );
      continue when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.action_code='RECOVERY_REFRESH_RETAINED_SKILL'
      );

      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select max(priority_order)::smallint into v_replace
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';

      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      else
        continue;
      end if;

      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,action_code,action_payload
      ) values(
        v_plan,v_replace,'learning',v_failed.skill_code,'RECOVERY_REFRESH_RETAINED_SKILL',
        jsonb_build_object('progress_retained',true,'revalidation_failed',true,'academic_stage_unchanged',true)
      );
      v_applied:=v_applied+1;
    end loop;
  end if;

  return v_base || jsonb_build_object(
    'active_week_no',v_effective_week,
    'progress_retained',true,
    'revalidation_refresh_applied',(v_applied>0),
    'revalidation_refresh_count',v_applied,
    'academic_stage_changed_by_recovery',false,
    'calendar_auto_promotion',false
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

commit;
