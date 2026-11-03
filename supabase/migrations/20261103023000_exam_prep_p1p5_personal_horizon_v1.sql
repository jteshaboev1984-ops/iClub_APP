-- Mathematics Exam Prep P1/P5: personal exam-date/diagnostic horizon.
-- Additive only. Production application data, legacy appointments and stage rules untouched.
-- A learner-entered school/centre-confirmed start time is NOT an official Cambridge timetable.
-- The programme-wide exam_calendar is currently empty: never invent verified dates.

create or replace function public.save_my_exam_prep_exam_appointment_v2(
  p_component_code text,
  p_scheduled_start_at timestamptz,
  p_school_confirmed boolean
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_ops jsonb;
  v_series text;
  v_series_year int;
  v_actual_year int;
  v_actual_month int;
  v_expected_months int[];
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;
  if p_school_confirmed is distinct from true then
    raise exception 'exam_prep_school_date_confirmation_required';
  end if;
  if p_scheduled_start_at is null
     or p_scheduled_start_at <= now()
     or p_scheduled_start_at > now() + interval '3 years' then
    raise exception 'exam_prep_exam_date_out_of_range';
  end if;

  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null
     or nullif(trim(v_profile.exam_series),'') is null
     or v_profile.program_version_id is null then
    raise exception 'exam_prep_exam_profile_required';
  end if;

  -- Only consistent centre dates are accepted. The series is a season/year,
  -- never an exact official timetable: that remains separate provenance.
  v_series:=lower(trim(v_profile.exam_series));
  -- Match the declared session's season and calendar year, never guess an official day.
  v_series_year:=substring(v_series from '(20[0-9]{2})')::int;
  v_actual_year:=extract(year from p_scheduled_start_at at time zone 'Asia/Tashkent')::int;
  v_actual_month:=extract(month from p_scheduled_start_at at time zone 'Asia/Tashkent')::int;
  if v_series like 'may/june %' then
    v_expected_months:=array[5,6];
  elsif v_series like 'october/november %' or v_series like 'oct/nov %' then
    v_expected_months:=array[10,11];
  elsif v_series like 'october %' then
    v_expected_months:=array[10];
  else
    raise exception 'exam_prep_exam_series_unrecognized';
  end if;
  if v_series_year is null or v_actual_year<>v_series_year
     or not (v_actual_month=any(v_expected_months)) then
    raise exception 'exam_prep_exam_date_series_mismatch';
  end if;

  v_ops:=public.save_my_exam_prep_exam_appointment_v1(p_component_code,p_scheduled_start_at);
  return jsonb_build_object(
    'component_code',p_component_code,
    'scheduled_start_at',p_scheduled_start_at,
    'confirmation_source','learner_school_confirmation',
    'confirmed_at',now(),
    'status','saved',
    'official_timetable_verified',coalesce((v_ops->>'final_timetable_verified')::boolean,false)
  );
end;
$function$;

revoke all on function public.save_my_exam_prep_exam_appointment_v2(text,timestamptz,boolean)
  from public,anon;
grant execute on function public.save_my_exam_prep_exam_appointment_v2(text,timestamptz,boolean)
  to authenticated,service_role;

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
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  select * into v_profile
    from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;
  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);

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
      select max(s.finalized_at) into v_diagnostic_end
      from private.exam_prep_sessions s
      where s.user_id=v_uid and s.program_version_id=v_profile.program_version_id
        and s.component_code=v_code and s.session_type='diagnostic'
        and s.status='finalized' and s.finalized_at is not null;
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
