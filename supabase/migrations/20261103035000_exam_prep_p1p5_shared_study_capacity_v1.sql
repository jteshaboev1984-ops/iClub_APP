-- P1/P5 source-backed planning: real student-CHOSEN weekly Mathematics
-- availability + own school-confirmed paper dates. NO required-study-hour
-- estimate, recommendation, grades, learning caps, or auto profile edits.
-- IMPORTANT: P1/P5 share one hour budget. Never add their horizon totals.

create or replace function public.get_exam_prep_shared_study_capacity_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_now timestamptz;
  v_budget numeric;
  v_earliest timestamptz;
  v_latest timestamptz;
  v_first_hours numeric;
  v_last_hours numeric;
  v_p1_date timestamptz;
  v_p5_date timestamptz;
  v_p1_state text;
  v_p5_state text;
  v_p1_diagnostic boolean;
  v_p5_diagnostic boolean;
  v_p1_diag_end timestamptz;
  v_p5_diag_end timestamptz;
  v_code text;
  v_start timestamptz;
  v_has_complete boolean;
  v_diagnostic_end timestamptz;
  v_status text;
  v_components jsonb:='{}'::jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile
  from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null
     or v_profile.mathematics_hours_budget is null then
    raise exception 'exam_prep_profile_required';
  end if;
  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  v_budget:=v_profile.mathematics_hours_budget;
  if v_budget<0 or
     (v_profile.total_student_hours_available is not null and
       v_budget>v_profile.total_student_hours_available) then
    raise exception 'exam_prep_invalid_shared_math_budget';
  end if;

  foreach v_code in array array['P1','P5'] loop
    v_start:=null;v_has_complete:=false;v_diagnostic_end:=null;
    select a.scheduled_start_at into v_start
    from private.exam_prep_exam_appointments a
    where a.user_id=v_uid
      and a.program_version_id=v_profile.program_version_id
      and a.component_code=v_code
      and (a.exam_series_snapshot is null or
           lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))));
    select coalesce(p.stage0_complete,false) into v_has_complete
    from private.exam_prep_component_placements p
    where p.user_id=v_uid and p.program_version_id=v_profile.program_version_id
      and p.component_code=v_code
    order by p.derived_at desc limit 1;
    v_has_complete:=coalesce(v_has_complete,false);
    if v_has_complete then
      select max(s.finalized_at) into v_diagnostic_end
      from private.exam_prep_sessions s
      where s.user_id=v_uid
        and s.program_version_id=v_profile.program_version_id
        and s.component_code=v_code
        and s.session_type='diagnostic'
        and s.status='finalized' and s.finalized_at is not null;
    end if;
    v_status:=case
      when not v_has_complete or v_diagnostic_end is null
        then 'diagnostic_incomplete'
      when v_start is null then 'exam_date_unconfirmed'
      when v_start<=v_now then 'exam_date_passed'
      when v_start<=v_diagnostic_end then 'exam_before_diagnostic'
      else 'calendar_capacity_available'
    end;
    v_components:=v_components||jsonb_build_object(
      v_code,jsonb_build_object(
        'component_code',v_code,
        'diagnostic_completed_at',v_diagnostic_end,
        'exam_date_confirmed',v_start is not null,
        'exam_start_at',v_start,
        'status',v_status,
        'paper_minutes',case when v_code='P1' then 110 else 75 end,
        'paper_minutes_are_daily_study_quota',false
      )
    );
    if v_status='calendar_capacity_available' then
      if v_earliest is null or v_start<v_earliest then v_earliest:=v_start; end if;
      if v_latest is null or v_start>v_latest then v_latest:=v_start; end if;
    end if;
  end loop;

  -- A wall-clock capacity at the student's ELECTED Math budget, not an
  -- effort requirement. Fractional weeks avoid turning five 30-minute days
  -- into seven daily hours. Shared and NON-ADDITIVE across both papers.
  if v_earliest is not null then
    v_first_hours:=round(v_budget * greatest(
      extract(epoch from (v_earliest-v_now)),0)::numeric / 604800,2);
    v_last_hours:=round(v_budget * greatest(
      extract(epoch from (v_latest-v_now)),0)::numeric / 604800,2);
  end if;

  return jsonb_build_object(
    'contract_version','exam_prep_shared_study_capacity_v1',
    'as_of',v_now,
    'P1',v_components->'P1',
    'P5',v_components->'P5',
    'chosen_math_hours_per_week',v_budget,
    'chosen_total_study_hours_per_week',v_profile.total_student_hours_available,
    'earliest_ready_paper_start_at',v_earliest,
    'latest_ready_paper_start_at',v_latest,
    'planned_shared_math_hours_to_earliest_exam',v_first_hours,
    'planned_shared_math_hours_to_latest_exam',v_last_hours,
    'shared_across_both_papers',true,
    'horizon_hours_additive_across_p1_p5',false,
    'capacity_is_recommendation',false,
    'capacity_is_access_limit',false,
    'may_study_above_plan',true,
    'recommended_study_hours_per_week',null,
    'recommended_daily_minutes',null,
    'recommendation_accept_enabled',false,
    'outside_iclub_study_minutes','unknown',
    'progress_notifications_only','after_completed_week_or_month',
    'explanation','Elected weekly hours scaled by exact remaining time, shared by P1 and P5. Does not estimate the hours necessary to learn unverified skills; no study access is ever capped.'
  );
end;
$function$;

revoke all on function public.get_exam_prep_shared_study_capacity_safe_v1()
 from public,anon;
grant execute on function public.get_exam_prep_shared_study_capacity_safe_v1()
 to authenticated,service_role;

comment on function public.get_exam_prep_shared_study_capacity_safe_v1() is
'Owner-only, read-only total elective Mathematics capacity to confirmed P1/P5 exam dates; shared P1/P5 (never doubled), no invented required hours, no study cap or notifications.';
