-- Issue #450 / D09-03: make ALL current P1/P5 horizon/capacity readouts
-- use the same confirmed original diagnostic date as academic weekly reports.
-- These are existing read-only owner-scoped API functions: NO plan writes,
-- no attempt scoring, no weekly budget duplication and NO production release.
-- The existing client signatures/return structures remain compatible;
-- legacy Stage0 completions without a frozen origin keep the prior derived T0.
BEGIN;

create or replace function public.get_exam_prep_personal_horizon_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_code text;
  v_appointment private.exam_prep_exam_appointments%rowtype;
  v_complete boolean;
  v_diagnostic_end timestamptz;
  v_days_left int;
  v_total_days int;
  v_verified boolean;
  v_status text;
  v_payload jsonb:='{}'::jsonb;
  v_now timestamptz;
  v_diagnostic_periods jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  select * into v_profile
    from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;
  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  -- One owner-scoped diagnostic source for the paper clocks and report receipts.
  v_diagnostic_periods:=public.get_exam_prep_diagnostic_periods_safe_v1();

  foreach v_code in array array['P1','P5'] loop
    v_appointment:=null;
    v_complete:=false;
    v_diagnostic_end:=null;
    v_days_left:=null;
    v_total_days:=null;
    v_verified:=false;

    select * into v_appointment
    from private.exam_prep_exam_appointments a
    where a.user_id=v_uid
      and a.program_version_id=v_profile.program_version_id
      and a.component_code=v_code
      and (a.exam_series_snapshot is null
           or lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))))
    limit 1;

    select coalesce(p.stage0_complete,false) into v_complete
    from private.exam_prep_component_placements p
    where p.user_id=v_uid and p.program_version_id=v_profile.program_version_id
      and p.component_code=v_code
    order by p.derived_at desc limit 1;
    v_complete:=coalesce(v_complete,false);

    if v_complete then
      -- First verified Stage0 time is immutable when captured; historical
      -- accounts use the visibly derived fallback from the same read model.
      v_diagnostic_end:=nullif(
        v_diagnostic_periods->v_code->>'diagnostic_completed_at',''
      )::timestamptz;
    end if;

    if v_appointment.user_id is not null then
      select exists(
        select 1 from private.exam_prep_exam_calendar c
        where c.program_version_id=v_profile.program_version_id
          and c.component_code=v_code
          and c.status='final_verified'
          and lower(trim(c.exam_series_key))=lower(trim(coalesce(v_profile.exam_series,'')))
          and c.exam_date=(v_appointment.scheduled_start_at at time zone 'Asia/Tashkent')::date
      ) into v_verified;

      v_days_left:=((v_appointment.scheduled_start_at at time zone 'Asia/Tashkent')::date
                     -(v_now at time zone 'Asia/Tashkent')::date);
    end if;

    if v_appointment.user_id is null then v_status:='date_not_confirmed';
    elsif v_appointment.scheduled_start_at <= v_now then v_status:='exam_date_passed';
    elsif not v_complete or v_diagnostic_end is null then v_status:='diagnostic_incomplete';
    elsif v_diagnostic_end >= v_appointment.scheduled_start_at then v_status:='exam_before_diagnostic';
    else
      v_status:='horizon_ready';
      v_total_days:=((v_appointment.scheduled_start_at at time zone 'Asia/Tashkent')::date
                      -(v_diagnostic_end at time zone 'Asia/Tashkent')::date);
    end if;

    v_payload:=v_payload||jsonb_build_object(
      v_code,jsonb_build_object(
        'component_code',v_code,
        'status',v_status,
        'exam_series',v_profile.exam_series,
        'exam_start_at',v_appointment.scheduled_start_at,
        'confirmed_by_school_or_centre',v_appointment.user_id is not null,
        'official_timetable_verified',v_verified,
        'diagnostic_complete',v_complete,
        'diagnostic_completed_at',v_diagnostic_end,
        'diagnostic_anchor_immutable',coalesce((v_diagnostic_periods->v_code->>'anchor_immutable')::boolean,false),
        'days_remaining',case when v_appointment.user_id is null then null else greatest(v_days_left,0) end,
        'days_diagnostic_to_exam',v_total_days,
        'estimated_study_hours',null,
        'forecast_status','not_calculated',
        'explanation','Study-time estimates require approved syllabus workload norms. Exam dates supplied by learners do not constitute official Cambridge verification.'
      )
    );
  end loop;

  return jsonb_build_object(
    'program_key','math_as_p1_p5',
    'exam_series',v_profile.exam_series,
    'time_zone','Asia/Tashkent',
    'as_of',v_now,
    'P1',v_payload->'P1',
    'P5',v_payload->'P5',
    'grade_prediction_available',false
  );
end;
$function$;

revoke all on function public.get_exam_prep_personal_horizon_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_personal_horizon_safe_v1()
  to authenticated,service_role;

comment on function public.get_exam_prep_personal_horizon_safe_v1() is
'Owner-only planning horizon from completed component diagnostic to learner-confirmed paper start; never grades, predicts A or invents workload norms.';


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
  v_diagnostic_periods jsonb;
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
  v_diagnostic_periods:=public.get_exam_prep_diagnostic_periods_safe_v1();
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
      v_diagnostic_end:=nullif(
        v_diagnostic_periods->v_code->>'diagnostic_completed_at',''
      )::timestamptz;
    end if;
    v_status:=case
      when not v_has_complete or v_diagnostic_end is null
        then 'diagnostic_incomplete'
      when v_start is null then 'exam_date_unconfirmed'
      when not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_start)
        then 'exam_date_series_mismatch'
      when v_start<=v_now then 'exam_date_passed'
      when v_start<=v_diagnostic_end then 'exam_before_diagnostic'
      else 'calendar_capacity_available'
    end;
    v_components:=v_components||jsonb_build_object(
      v_code,jsonb_build_object(
        'component_code',v_code,
        'diagnostic_completed_at',v_diagnostic_end,
        'diagnostic_anchor_immutable',coalesce((v_diagnostic_periods->v_code->>'anchor_immutable')::boolean,false),
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

COMMIT;
