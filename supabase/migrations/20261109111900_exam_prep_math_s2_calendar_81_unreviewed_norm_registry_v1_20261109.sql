-- Supabase applied migration version 20261109111900: calendar, schedules and 81 UNREVIEWED skill norm sources.
-- Live release originally passed stricter bank/source guarded preflight and immutable postflight.
-- This logically equivalent portable source is for fresh test stacks; NO write to existing student attempts.
BEGIN;
-- Original source 20261103023000_exam_prep_p1p5_personal_horizon_v1.sql
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
    v_expected_months:=array[4,5,6]; -- June series can contain April papers (e.g. 9709 P1 in 2026)
  elsif v_series like 'october/november %' or v_series like 'oct/nov %' then
    v_expected_months:=array[9,10,11]; -- November series can start in late September
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


-- Original source 20261103024000_exam_prep_p1p5_study_schedule_v1.sql
-- Mathematics P1/P5 daily study cadence, additive and owner-only.
-- Explicit learner choice. Do not silently change chosen total weekly hours.
-- No Cambridge per-skill hours, grade forecast or plan generator in this migration.

alter table private.exam_prep_exam_profiles
  add column if not exists study_minutes_per_day smallint,
  add column if not exists study_days_per_week smallint,
  add column if not exists study_schedule_revision integer not null default 0,
  add column if not exists study_schedule_updated_at timestamptz;

alter table private.exam_prep_exam_profiles
  add constraint exam_prep_profile_study_minutes_valid
    check (study_minutes_per_day is null or
      (study_minutes_per_day between 15 and 240 and study_minutes_per_day % 5 = 0)),
  add constraint exam_prep_profile_study_days_valid
    check (study_days_per_week is null or study_days_per_week between 1 and 7),
  add constraint exam_prep_profile_study_cadence_complete
    check ((study_minutes_per_day is null)=(study_days_per_week is null)),
  add constraint exam_prep_profile_study_revision_valid
    check (study_schedule_revision >= 0);

create or replace function public.get_exam_prep_study_schedule_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_profile.user_id is null then raise exception 'exam_prep_profile_required'; end if;
  return jsonb_build_object(
    'study_minutes_per_day',v_profile.study_minutes_per_day,
    'study_days_per_week',v_profile.study_days_per_week,
    'mathematics_hours_per_week',v_profile.mathematics_hours_budget,
    'total_student_hours_per_week',v_profile.total_student_hours_available,
    'study_schedule_revision',v_profile.study_schedule_revision,
    'study_schedule_updated_at',v_profile.study_schedule_updated_at,
    'schedule_confirmed',v_profile.study_minutes_per_day is not null,
    'schedule_source','learner_explicit_choice',
    'forecast_available',false
  );
end;
$function$;

revoke all on function public.get_exam_prep_study_schedule_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_study_schedule_safe_v1()
  to authenticated,service_role;

create or replace function public.save_exam_prep_study_schedule_safe_v1(
  p_minutes_per_day integer,
  p_days_per_week integer
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_old private.exam_prep_exam_profiles%rowtype;
  v_new private.exam_prep_exam_profiles%rowtype;
  v_budget numeric;
  v_change boolean;
  v_profile_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_minutes_per_day is null or p_minutes_per_day<15 or
     p_minutes_per_day>240 or mod(p_minutes_per_day,5)<>0 then
    raise exception 'exam_prep_study_minutes_invalid';
  end if;
  if p_days_per_week is null or p_days_per_week<1 or p_days_per_week>7 then
    raise exception 'exam_prep_study_days_invalid';
  end if;
  v_budget:=round((p_minutes_per_day::numeric * p_days_per_week::numeric)/60,4);

  select * into v_old from private.exam_prep_exam_profiles
  where user_id=v_uid for update;
  if v_old.user_id is null or v_old.program_version_id is null or
     v_old.total_student_hours_available is null or
     v_old.total_student_hours_available<=0 then
    raise exception 'exam_prep_profile_required';
  end if;
  if v_budget>v_old.total_student_hours_available then
    raise exception 'exam_prep_study_exceeds_total_weekly_budget';
  end if;
  v_change:=v_old.study_minutes_per_day is distinct from p_minutes_per_day
        or v_old.study_days_per_week is distinct from p_days_per_week;
  if v_old.mathematics_hours_budget is distinct from v_budget then
    -- Existing governed profile change creates a revision and preserves all
    -- old learning/session evidence. Does not change the overall hours.
    v_profile_result:=public.save_exam_prep_exam_profile_v2(
      v_old.exam_series,
      v_old.target_grade,
      v_old.total_student_hours_available,
      v_budget
    );
  end if;
  if v_change then
    update private.exam_prep_exam_profiles
    set study_minutes_per_day=p_minutes_per_day,
        study_days_per_week=p_days_per_week,
        study_schedule_revision=study_schedule_revision+1,
        study_schedule_updated_at=now(),
        updated_at=now(),
        updated_by=v_uid
    where user_id=v_uid;
  end if;
  select * into v_new from private.exam_prep_exam_profiles where user_id=v_uid;

  return jsonb_build_object(
    'study_minutes_per_day',v_new.study_minutes_per_day,
    'study_days_per_week',v_new.study_days_per_week,
    'mathematics_hours_per_week',v_new.mathematics_hours_budget,
    'total_student_hours_per_week',v_new.total_student_hours_available,
    'study_schedule_revision',v_new.study_schedule_revision,
    'study_schedule_updated_at',v_new.study_schedule_updated_at,
    'changed',v_change or v_old.mathematics_hours_budget is distinct from v_budget,
    'plan_rebuild_required',coalesce((v_profile_result->>'plan_rebuild_required')::boolean,false),
    'progress_retained',true,
    'forecast_available',false
  );
end;
$function$;

revoke all on function public.save_exam_prep_study_schedule_safe_v1(integer,integer)
  from public,anon;
grant execute on function public.save_exam_prep_study_schedule_safe_v1(integer,integer)
  to authenticated,service_role;

comment on function public.save_exam_prep_study_schedule_safe_v1(integer,integer) is
'Explicit owner-confirmed Math study cadence: minutes/day multiplied by days/week; never a forecast or implicit total-hours change.';


-- Original source 20261103030000_exam_prep_p1p5_workload_norm_registry_v1.sql
-- Mathematics P1/P5 Package 2, 2026-11-03.
-- Curriculum-grounded *source register*, NOT invented official Cambridge hours.
-- Stage 0: one draft row per existing 81 canonical skills; all numeric norm
-- fields NULL until a source-backed independent academic review accepts each.
-- No modifications to learner evidence, published questions, sessions or profile.

create table private.exam_prep_skill_workload_norms_v1 (
  program_version_id bigint not null,
  skill_code text not null,
  component_code text not null check(component_code in ('P1','P5')),
  source_syllabus_section text not null,
  source_syllabus_url text not null,
  source_book_chapter text not null,
  source_prerequisites text not null,
  estimated_core_min_minutes integer,
  estimated_core_max_minutes integer,
  estimated_revision_min_minutes integer,
  estimated_revision_max_minutes integer,
  estimate_status text not null default 'unreviewed'
    check (estimate_status in ('unreviewed','under_review','approved','retired')),
  estimate_provenance text not null default 'pending_academic_review'
    check (estimate_provenance in ('pending_academic_review','iclub_syllabus_aligned_estimate')),
  methodology_notes text,
  revision integer not null default 1 check(revision>=1),
  reviewed_by text,
  reviewed_at timestamptz,
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(program_version_id,skill_code),
  foreign key(program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code)
    on update restrict on delete restrict,
  constraint exam_prep_workload_norm_range_check check(
    (estimated_core_min_minutes is null or estimated_core_min_minutes between 5 and 1200) and
    (estimated_core_max_minutes is null or estimated_core_max_minutes between 5 and 2400) and
    (estimated_revision_min_minutes is null or estimated_revision_min_minutes between 0 and 1200) and
    (estimated_revision_max_minutes is null or estimated_revision_max_minutes between 0 and 2400) and
    (estimated_core_min_minutes is null or estimated_core_max_minutes is null or
      estimated_core_max_minutes>=estimated_core_min_minutes) and
    (estimated_revision_min_minutes is null or estimated_revision_max_minutes is null or
      estimated_revision_max_minutes>=estimated_revision_min_minutes)
  ),
  constraint exam_prep_workload_norm_approval_check check(
    estimate_status <> 'approved' or (
      estimate_provenance='iclub_syllabus_aligned_estimate' and
      estimated_core_min_minutes is not null and
      estimated_core_max_minutes is not null and
      estimated_revision_min_minutes is not null and
      estimated_revision_max_minutes is not null and
      nullif(btrim(coalesce(methodology_notes,'')),'') is not null and
      nullif(btrim(coalesce(reviewed_by,'')),'') is not null and
      nullif(btrim(coalesce(approved_by,'')),'') is not null and
      reviewed_at is not null and approved_at is not null and
      reviewed_by<>approved_by and reviewed_at<=approved_at
    )
  )
);

alter table private.exam_prep_skill_workload_norms_v1 enable row level security;
revoke all on private.exam_prep_skill_workload_norms_v1 from public,anon,authenticated;
comment on table private.exam_prep_skill_workload_norms_v1 is
'Internal versioned iClub workload estimates for 2026-27 Cambridge 9709 P1/P5 skills. Not Cambridge-published personal hours, cannot become approved without review and independent approval.';

-- Seed only canonical published-program syllabus sources already evidenced in
-- database. No hardcoded third-party book text or guessed skill hours.
insert into private.exam_prep_skill_workload_norms_v1(
  program_version_id,skill_code,component_code,
  source_syllabus_section,source_syllabus_url,source_book_chapter,
  source_prerequisites
)
select s.program_version_id,s.skill_code,s.component_code,
       s.official_syllabus_section,s.official_source_url,
       s.book_chapter,s.prerequisites_text
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions p on p.id=s.program_version_id
where p.program_key='math_as_p1_p5'
  and p.status='active'
  and s.component_code in ('P1','P5')
  and nullif(btrim(s.official_syllabus_section),'') is not null
  and nullif(btrim(s.official_source_url),'') is not null
  and nullif(btrim(s.book_chapter),'') is not null
  and s.prerequisites_text is not null
on conflict do nothing;

do $$
declare v_n int; v_p1 int; v_p5 int;
begin
  select count(*),count(*) filter(where component_code='P1'),
                  count(*) filter(where component_code='P5')
    into v_n,v_p1,v_p5
  from private.exam_prep_skill_workload_norms_v1 w
  join private.exam_prep_program_versions p on p.id=w.program_version_id
  where p.program_key='math_as_p1_p5' and p.status='active';
  -- Fail closed on unexpected source drift: do not silently advertise a
  -- complete quantitative recommendation without source coverage.
  if v_n<>81 or v_p1<>45 or v_p5<>36 then
    raise exception 'exam_prep_workload_registry_source_coverage_mismatch';
  end if;
end $$;

create or replace function public.get_exam_prep_workload_norm_status_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_version bigint;
  v_payload jsonb := '{}'::jsonb;
  v_component text;
  v_expected int;
  v_total int;
  v_approved int;
  v_missing int;
  v_revision int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select program_version_id into v_version from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_version is null then raise exception 'exam_prep_profile_required'; end if;

  foreach v_component in array array['P1','P5'] loop
    select count(*) into v_expected from private.exam_prep_syllabus_nodes s
    where s.program_version_id=v_version and s.component_code=v_component;
    select count(*)::int,
           count(*) filter(where w.estimate_status='approved' and
              w.estimated_core_min_minutes is not null and
              w.estimated_core_max_minutes is not null and
              w.estimated_revision_min_minutes is not null and
              w.estimated_revision_max_minutes is not null)::int,
           max(w.revision)::int
      into v_total,v_approved,v_revision
      from private.exam_prep_skill_workload_norms_v1 w
      where w.program_version_id=v_version and w.component_code=v_component;
    v_missing:=greatest(v_expected-coalesce(v_total,0),0);
    v_payload:=v_payload||jsonb_build_object(
      v_component,jsonb_build_object(
        'component_code',v_component,
        'skills_expected',v_expected,
        'norm_rows',v_total,
        'approved_norms',v_approved,
        'not_ready_norms',greatest(v_expected-v_approved,0),
        'missing_source_rows',v_missing,
        'norm_revision',v_revision,
        'status',case when v_expected>0 and v_total=v_expected and
                v_approved=v_expected then 'all_norms_academically_approved'
              else 'academic_review_incomplete' end,
        'norms_kind','internal_iclub_estimate_based_on_cambridge_syllabus',
        'official_cambridge_per_skill_hours',false,
        'personal_hour_recommendation_available',false
      )
    );
  end loop;
  return jsonb_build_object(
    'contract_version','exam_prep_workload_norm_status_v1',
    'P1',v_payload->'P1','P5',v_payload->'P5',
    'numeric_recommendation_enabled',false,
    'reason','Syllabus sources alone do not prove personalized per-skill study hours. Require independent academic-approved norms and an audited scheduling engine.',
    'no_grade_forecast',true,
    'no_study_time_cap',true
  );
end;
$function$;

revoke all on function public.get_exam_prep_workload_norm_status_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_workload_norm_status_safe_v1()
  to authenticated,service_role;


-- Original source 20261103031000_exam_prep_p1p5_historical_topic_teaching_references_v1.sql
-- Cambridge-authored 9709 Scheme of Work (for examination from 2020).
-- Historical suggested GUIDED TEACHING time PER TOPIC, NOT private self-study
-- hours or 2026-27 verified per-skill norms. Never use as an automatic
-- personal recommendation. Store the source/version/caveat explicitly.
create table private.exam_prep_historical_topic_teaching_refs_v1 (
 program_version_id bigint not null
   references private.exam_prep_program_versions(id) on delete restrict,
 component_code text not null check (component_code in ('P1','P5')),
 official_syllabus_section text not null,
 suggested_guided_teaching_hours smallint not null
   check (suggested_guided_teaching_hours between 1 and 100),
 source_document text not null,
 source_url text not null,
 source_scheme_version text not null default 'from_2020_v1',
 status text not null default 'historical_reference_unverified_for_2026_27'
   check (status in ('historical_reference_unverified_for_2026_27','confirmed_for_current_content','retired')),
 approved_as_personal_study_norm boolean not null default false
   check (approved_as_personal_study_norm=false),
 created_at timestamptz not null default now(),
 primary key(program_version_id,component_code,official_syllabus_section)
);
alter table private.exam_prep_historical_topic_teaching_refs_v1
  enable row level security;
revoke all on private.exam_prep_historical_topic_teaching_refs_v1 from public,anon,authenticated;
comment on table private.exam_prep_historical_topic_teaching_refs_v1 is
'Historical Cambridge-authored 9709 2020 Scheme of Work topic GUIDED TEACHING time only. 2026/27 applicability unconfirmed. Not hours needed by a learner. Never feed directly to personal daily study hours.';

-- Only 13 exact Cambridge syllabus topics existing in active canonical P1/P5
-- map: 8 Pure1 topics + 5 ProbStats1 topics.
-- P1 source: Cambridge Assessment International Education, Pure Mathematics 1,
-- Scheme of Work, for examinations from 2020, Version 1, page 5.
-- https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf
-- P5 source: Cambridge Assessment International Education, Probability & Statistics 1,
-- Scheme of Work, for examinations from 2020, Version 1, page 5.
-- https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf
-- Official 2026-27 syllabus content is maintained separately in
-- private.exam_prep_syllabus_nodes; do not infer 2026-27 topic hours.
with source_hours(component_code,section,hours,document_name,reference_url) as (
 values
 ('P1','1.1 Quadratics',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.2 Functions',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.3 Coordinate geometry',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.4 Circular measure',4,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.5 Trigonometry',14,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.6 Series',10,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.7 Differentiation',16,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P1','1.8 Integration',16,'Cambridge 9709 Pure Mathematics 1 Scheme of Work from 2020',
  'https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf'),
 ('P5','5.1 Representation of data',14,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.2 Permutations and combinations',4,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.3 Probability',12,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.4 Discrete random variables',8,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf'),
 ('P5','5.5 The normal distribution',12,'Cambridge 9709 Probability & Statistics 1 Scheme of Work from 2020',
  'https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf')
)
insert into private.exam_prep_historical_topic_teaching_refs_v1(
  program_version_id,component_code,official_syllabus_section,
  suggested_guided_teaching_hours,source_document,source_url
)
select distinct s.program_version_id,r.component_code,r.section,r.hours,
  r.document_name,r.reference_url
from source_hours r
join private.exam_prep_syllabus_nodes s
  on s.component_code=r.component_code and
     s.official_syllabus_section=r.section
join private.exam_prep_program_versions p
  on p.id=s.program_version_id
where p.program_key='math_as_p1_p5' and p.status='active'
on conflict do nothing;

do $$
declare v_p1_count int;v_p5_count int;v_p1_hours int;v_p5_hours int;
begin
 select count(*) filter(where component_code='P1'),
        count(*) filter(where component_code='P5'),
        sum(suggested_guided_teaching_hours) filter(where component_code='P1'),
        sum(suggested_guided_teaching_hours) filter(where component_code='P5')
 into v_p1_count,v_p5_count,v_p1_hours,v_p5_hours
 from private.exam_prep_historical_topic_teaching_refs_v1 h
 join private.exam_prep_program_versions p on p.id=h.program_version_id
 where p.program_key='math_as_p1_p5' and p.status='active';
 if v_p1_count<>8 or v_p5_count<>5 or v_p1_hours<>90 or v_p5_hours<>50 then
   raise exception 'exam_prep_historical_scheme_source_mismatch';
 end if;
end $$;


-- Original source 20261103032000_exam_prep_p1p5_workload_review_projection_v1.sql
-- Mathematics 9709 P1/P5: owner-scoped workload REVIEW projection.
-- Uses real syllabus, objective evidence, verified component diagnostics and
-- confirmed appointment records. NEVER infers personalized Cambridge hours.
-- Earlier PR adds norm register; this is standalone in Package 2 branch and
-- does NOT depend on draft Package 1 RPCs or access/rollout changes.

create or replace function public.get_exam_prep_workload_review_projection_safe_v1()
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
 v_component text;
 v_total int;
 v_norm_total int;
 v_approved int;
 v_unobserved int;
 v_observed_unconfirmed int;
 v_confirmed int;
 v_corrections int;
 v_other_evidence int;
 v_screening boolean;
 v_diagnostic_done_at timestamptz;
 v_start timestamptz;
 v_appointment private.exam_prep_exam_appointments%rowtype;
 v_days_remaining int;
 v_state text;
 v_paper_minutes int;
 v_result jsonb:='{}'::jsonb;
begin
 v_uid:=private.exam_prep_require_core_access_v1();

 select * into v_profile
 from private.exam_prep_exam_profiles
 where user_id=v_uid;
 if v_profile.user_id is null or v_profile.program_version_id is null then
   raise exception 'exam_prep_profile_required';
 end if;
 v_now:=private.exam_prep_effective_academic_now_v1(v_uid);

 foreach v_component in array array['P1','P5'] loop
   v_total:=0;v_norm_total:=0;v_approved:=0;
   v_unobserved:=0;v_observed_unconfirmed:=0;v_confirmed:=0;
   v_corrections:=0;v_other_evidence:=0;v_days_remaining:=null;
   v_start:=null;v_diagnostic_done_at:=null;v_screening:=false;
   v_paper_minutes:=case when v_component='P1' then 110 else 75 end;

   -- Distinct-on prevents old engine-version rows from being counted twice.
   -- A missing skill state or zero OBJECTIVE evidence is UNKNOWN, never weak.
   with latest_states as (
     select distinct on (s.skill_code)
       s.skill_code,s.objective_evidence_count,s.objective_level,
       s.coverage_confirmed,s.unresolved_correction_count,
       s.written_count,s.has_mentor_verified_evidence
     from private.exam_prep_skill_states s
     where s.user_id=v_uid
       and s.program_version_id=v_profile.program_version_id
       and s.component_code=v_component
     order by s.skill_code,s.derived_at desc,s.engine_version desc
   )
   select count(*)::int,
          count(n.skill_code)::int,
          count(n.skill_code) filter (
            where n.estimate_status='approved' and
              n.estimated_core_min_minutes is not null and
              n.estimated_core_max_minutes is not null and
              n.estimated_revision_min_minutes is not null and
              n.estimated_revision_max_minutes is not null)::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)=0)::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)>0 and
            not (t.coverage_confirmed=true and t.objective_level>=2 and
                 t.unresolved_correction_count=0))::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)>0 and
            t.coverage_confirmed=true and t.objective_level>=2 and
            t.unresolved_correction_count=0)::int,
          count(*) filter(where coalesce(t.unresolved_correction_count,0)>0)::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)=0 and
              (coalesce(t.written_count,0)>0 or
               coalesce(t.has_mentor_verified_evidence,false)=true))::int
   into v_total,v_norm_total,v_approved,v_unobserved,v_observed_unconfirmed,
        v_confirmed,v_corrections,v_other_evidence
   from private.exam_prep_syllabus_nodes c
   left join private.exam_prep_skill_workload_norms_v1 n
      on n.program_version_id=c.program_version_id and
         n.skill_code=c.skill_code and n.component_code=c.component_code
   left join latest_states t on t.skill_code=c.skill_code
   where c.program_version_id=v_profile.program_version_id
     and c.component_code=v_component;

   -- Do not assume a finalized screening chunk means full diagnostic.
   select coalesce(p.stage0_complete,false) into v_screening
   from private.exam_prep_component_placements p
   where p.user_id=v_uid and p.program_version_id=v_profile.program_version_id
     and p.component_code=v_component
   order by p.derived_at desc limit 1;
   v_screening:=coalesce(v_screening,false);
   if v_screening then
     select max(s.finalized_at) into v_diagnostic_done_at
     from private.exam_prep_sessions s
     where s.user_id=v_uid and s.program_version_id=v_profile.program_version_id
       and s.component_code=v_component and s.session_type='diagnostic'
       and s.status='finalized' and s.finalized_at is not null;
   end if;

   select * into v_appointment
   from private.exam_prep_exam_appointments a
   where a.user_id=v_uid and a.program_version_id=v_profile.program_version_id
     and a.component_code=v_component and
     (a.exam_series_snapshot is null or
      lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))));
   if v_appointment.user_id is not null then
      v_start:=v_appointment.scheduled_start_at;
      v_days_remaining:=(
        (v_start at time zone 'Asia/Tashkent')::date -
        (v_now at time zone 'Asia/Tashkent')::date
      );
   end if;

   v_state:=case
     when not v_screening or v_diagnostic_done_at is null
       then 'diagnostic_incomplete'
     when v_start is null then 'exam_date_not_confirmed'
     when not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_start)
       then 'exam_date_series_mismatch'
     when v_start<=v_now then 'exam_date_passed'
     when v_start<=v_diagnostic_done_at then 'exam_before_diagnostic'
     when v_norm_total<>v_total or v_approved<>v_total
       then 'academic_workload_norms_incomplete'
     else 'personal_workload_engine_not_approved'
   end;

   v_result:=v_result||jsonb_build_object(
     v_component,jsonb_build_object(
       'component_code',v_component,
       'status',v_state,
       'curriculum_skills',v_total,
       'source_mapped_norms',v_norm_total,
       'academically_approved_norms',v_approved,
       'skills_unknown_objective_level',v_unobserved,
       'skills_with_observed_but_unconfirmed_objective_level',v_observed_unconfirmed,
       'skills_with_confirmed_objective_coverage',v_confirmed,
       'skills_with_unresolved_corrections',v_corrections,
       'skills_with_other_evidence_only',v_other_evidence,
       'diagnostic_complete',v_screening and v_diagnostic_done_at is not null,
       'diagnostic_completed_at',v_diagnostic_done_at,
       'exam_start_at',v_start,
       'exam_date_confirmation',case when v_start is null then null
           else v_appointment.confirmation_source end,
       'days_to_exam',case when v_start is null or
             not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_start)
             then null else greatest(v_days_remaining,0) end,
       'cambridge_full_paper_exam_minutes',v_paper_minutes,
       'cambridge_paper_time_is_study_quota',false,
       'current_weekly_math_budget_hours',v_profile.mathematics_hours_budget,
       'recommended_daily_minutes',null,
       'recommended_weekly_hours_min',null,
       'recommended_weekly_hours_max',null,
       'numeric_recommendation_available',false,
       'learning_time_cap',false,
       'confidence','unverified_skill_study_time'
     )
   );
 end loop;
 return jsonb_build_object(
   'contract_version','exam_prep_workload_review_projection_v1',
   'as_of',v_now,
   'P1',v_result->'P1','P5',v_result->'P5',
   'syllabus_ref','Cambridge 9709 syllabus for 2026 and 2027',
   'paper_duration_ref_url',
     'https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf',
   'recommended_daily_minutes',null,
   'recommendation_accept_enabled',false,
   'grade_prediction_available',false,
   'outside_iclub_study_minutes','unknown',
   'notifications_only','after_completed_week_or_month',
   'learning_time_cap',false
 );
end;
$function$;

revoke all on function public.get_exam_prep_workload_review_projection_safe_v1()
 from public,anon;
grant execute on function public.get_exam_prep_workload_review_projection_safe_v1()
 to authenticated,service_role;

comment on function public.get_exam_prep_workload_review_projection_safe_v1() is
'Read-only owner P1/P5 evidence and exact Cambridge paper-duration source. Unknown objective skill evidence is NOT graded as weak; no invented 81-skill study-hour forecast, no grade predictions or study caps.';


-- Original source 20261103033000_exam_prep_p1p5_workload_academic_review_queue_v1.sql
-- Internal academic workload review queue: every current P1/P5 canonical
-- skill with its real syllabus/book evidence and historical 2020 topic contact
-- hours shown ONLY as contextual teaching reference.
-- No fabricated personal-study time, learner rows or UI access.
create or replace view private.exam_prep_workload_academic_review_queue_v1
with (security_barrier = true)
as
select
  p.program_key,
  p.version_key,
  p.syllabus_version,
  s.program_version_id,
  s.component_code,
  s.sequence_no,
  s.skill_code,
  s.canonical_description,
  s.official_syllabus_section,
  s.official_source_url,
  s.book_chapter,
  s.prerequisites_text,
  s.required_mastery_evidence,
  s.app_can_verify,
  s.mentor_must_verify,
  count(*) over (partition by s.program_version_id,s.component_code,s.official_syllabus_section)
    as skills_in_same_topic,
  h.suggested_guided_teaching_hours as historical_topic_teacher_contact_hours,
  h.source_scheme_version as historical_scheme_version,
  h.source_url as historical_scheme_source,
  h.status as historical_reference_status,
  w.estimate_status as personal_skill_estimate_review_status,
  w.estimate_provenance,
  w.estimated_core_min_minutes,
  w.estimated_core_max_minutes,
  w.estimated_revision_min_minutes,
  w.estimated_revision_max_minutes,
  w.methodology_notes,
  w.reviewed_at,
  w.approved_at,
  'Teaching time per topic does NOT imply personal independent study minutes for a skill.'::text
    as historical_reference_caveat
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions p on p.id=s.program_version_id
left join private.exam_prep_historical_topic_teaching_refs_v1 h
  on h.program_version_id=s.program_version_id
  and h.component_code=s.component_code
  and h.official_syllabus_section=s.official_syllabus_section
left join private.exam_prep_skill_workload_norms_v1 w
  on w.program_version_id=s.program_version_id
  and w.skill_code=s.skill_code
  and w.component_code=s.component_code
where p.program_key='math_as_p1_p5'
  and p.status='active'
  and s.component_code in ('P1','P5');

revoke all on private.exam_prep_workload_academic_review_queue_v1
  from public,anon,authenticated;
comment on view private.exam_prep_workload_academic_review_queue_v1 is
'Private academic audit of 81 true P1/P5 source skills. Historical Cambridge 2020 topic contact hours shown as separate context, never learner estimates.';


-- Original source 20261103034000_exam_prep_p1p5_real_content_calibration_inventory_v1.sql
-- Package 2 real academic calibration inventory, read-only, private.
-- Uses the actual current 9709 P1/P5 syllabus, published content QA,
-- quarantined reserve pools, question-specific timer ceilings and published
-- written tasks. This does NOT create per-skill study-hour recommendations.
-- Critical: public.questions.is_active=false is intentional for Exam Prep.
-- NEVER toggle it or use it to decide which private Exam Prep content is
-- published. Actual release state is protected content lifecycle + QA.

create or replace view private.exam_prep_skill_content_calibration_inventory_v1
with (security_barrier=true) as
with published_content as (
  select
    cv.program_version_id,
    cv.component_code,
    m.primary_skill_code as skill_code,
    count(distinct m.question_id) filter (
      where m.lifecycle_state='published')::int as published_objective_items,
    count(distinct m.question_id) filter (
      where m.lifecycle_state='reserve')::int as protected_reserve_items,
    count(distinct m.question_id) filter (
      where m.lifecycle_state='retired')::int as retired_objective_items,
    count(distinct m.question_id) filter (
      where m.lifecycle_state='published'
      and m.qa_math_status='pass'
      and m.qa_scope_status='pass'
      and m.qa_language_status='pass'
      and m.qa_technical_status='pass')::int as qa_passed_published_objective,
    min(q.time_limit_sec) filter (
      where m.lifecycle_state='published')::int as min_published_item_timer_sec,
    max(q.time_limit_sec) filter (
      where m.lifecycle_state='published')::int as max_published_item_timer_sec,
    sum(q.time_limit_sec) filter (
      where m.lifecycle_state='published')::bigint as sum_all_published_item_timer_caps_sec
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv
    on cv.id=m.content_version_id and cv.status='published'
  join public.questions q on q.id=m.question_id
  join private.exam_prep_program_versions p
    on p.id=cv.program_version_id and p.status='active'
    and p.program_key='math_as_p1_p5'
  group by cv.program_version_id,cv.component_code,m.primary_skill_code
),
written_content as (
  select cv.program_version_id,cv.component_code,
    w.primary_skill_code as skill_code,
    count(distinct w.id) filter (
      where w.lifecycle_state='published')::int as published_written_tasks,
    count(distinct w.id) filter (
      where w.lifecycle_state='published'
      and w.qa_math_status='pass'
      and w.qa_language_status='pass'
      and w.qa_technical_status='pass')::int as qa_passed_published_written
  from private.exam_prep_written_tasks w
  join private.exam_prep_content_versions cv
    on cv.id=w.content_version_id and cv.status='published'
  join private.exam_prep_program_versions p
    on p.id=cv.program_version_id and p.status='active'
    and p.program_key='math_as_p1_p5'
  group by cv.program_version_id,cv.component_code,w.primary_skill_code
),
published_assessment_routes as (
  select cv.program_version_id,a.component_code,
    i.primary_skill_code as skill_code,
    count(distinct a.id) filter (
      where a.assessment_type='diagnostic')::int as published_diagnostic_assessments,
    count(distinct a.id) filter (
      where a.assessment_type='learning')::int as published_learning_assessments,
    count(distinct a.id) filter (
      where a.assessment_type='mixed')::int as published_mixed_assessments,
    count(distinct a.id) filter (
      where a.assessment_type='retest')::int as published_retest_assessments,
    count(distinct a.id) filter (
      where a.assessment_type='timed')::int as published_timed_assessments,
    count(distinct a.id) filter (
      where a.assessment_type='paper')::int as published_paper_assessments
  from private.exam_prep_assessment_items i
  join private.exam_prep_assessments a
    on a.id=i.assessment_id and a.status='published'
  join private.exam_prep_content_versions cv
    on cv.id=a.content_version_id and cv.status='published'
  join private.exam_prep_program_versions p
    on p.id=cv.program_version_id and p.status='active'
    and p.program_key='math_as_p1_p5'
  group by cv.program_version_id,a.component_code,i.primary_skill_code
)
select
 s.program_version_id,
 s.component_code,
 s.sequence_no,
 s.skill_code,
 s.official_syllabus_section,
 s.official_source_url,
 s.canonical_description,
 s.book_chapter,
 s.prerequisites_text,
 s.required_mastery_evidence,
 s.written_suitability,
 coalesce(q.published_objective_items,0) as published_objective_items,
 coalesce(q.protected_reserve_items,0) as protected_reserve_items,
 coalesce(q.retired_objective_items,0) as retired_objective_items,
 coalesce(q.qa_passed_published_objective,0) as qa_passed_published_objective,
 coalesce(w.published_written_tasks,0) as published_written_tasks,
 coalesce(w.qa_passed_published_written,0) as qa_passed_published_written,
 coalesce(a.published_diagnostic_assessments,0) as published_diagnostic_assessments,
 coalesce(a.published_learning_assessments,0) as published_learning_assessments,
 coalesce(a.published_mixed_assessments,0) as published_mixed_assessments,
 coalesce(a.published_retest_assessments,0) as published_retest_assessments,
 coalesce(a.published_timed_assessments,0) as published_timed_assessments,
 coalesce(a.published_paper_assessments,0) as published_paper_assessments,
 q.min_published_item_timer_sec,
 q.max_published_item_timer_sec,
 q.sum_all_published_item_timer_caps_sec,
 case
   when coalesce(q.published_objective_items,0)=0
     or coalesce(w.published_written_tasks,0)=0 then 'missing_published_content'
   when q.qa_passed_published_objective<>q.published_objective_items
     or w.qa_passed_published_written<>w.published_written_tasks
     then 'published_content_qa_incomplete'
   when coalesce(a.published_diagnostic_assessments,0)=0
     or coalesce(a.published_learning_assessments,0)=0
     or coalesce(a.published_retest_assessments,0)=0
     then 'missing_core_assessment_route'
   else 'core_content_source_mapped'
 end as content_coverage_status,
 false::boolean as question_timer_is_personal_skill_study_norm,
 false::boolean as observed_elapsed_is_reliable_learning_hours,
 false::boolean as historic_scheme_is_personal_study_norm,
 'Published/QA question time_limit_sec is an assessment ceiling, not time to learn. ' ||
 'Response elapsed_ms can include synthetic/idle/transport and needs independent quality review. ' ||
 'Protected reserve item identifiers must never be displayed to students.'::text
   as workload_calibration_warning
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions p
  on p.id=s.program_version_id and p.status='active'
  and p.program_key='math_as_p1_p5'
left join published_content q
  on q.program_version_id=s.program_version_id
  and q.component_code=s.component_code and q.skill_code=s.skill_code
left join written_content w
  on w.program_version_id=s.program_version_id
  and w.component_code=s.component_code and w.skill_code=s.skill_code
left join published_assessment_routes a
  on a.program_version_id=s.program_version_id
  and a.component_code=s.component_code and a.skill_code=s.skill_code
where s.component_code in ('P1','P5');

revoke all on private.exam_prep_skill_content_calibration_inventory_v1
 from public,anon,authenticated;
comment on view private.exam_prep_skill_content_calibration_inventory_v1 is
'Internal 81-skill P1/P5 content QA inventory and objective item timer ceilings. No learner data, no invented personal-study minutes, no public exposure of reserved items.';


-- Original source 20261103035000_exam_prep_p1p5_shared_study_capacity_v1.sql
-- P1/P5 source-backed planning: real student-CHOSEN weekly Mathematics
-- availability + own school-confirmed paper dates. NO required-study-hour
-- estimate, recommendation, grades, learning caps, or auto profile edits.
-- IMPORTANT: P1/P5 share one hour budget. Never add their horizon totals.

-- Private fail-closed validation also protects the read-only planner from
-- legacy direct calls to save_my_exam_prep_exam_appointment_v1, which does
-- not itself validate a date against the selected exam session.
create or replace function private.exam_prep_exam_date_matches_series_v1(
 p_series text,p_start timestamptz
)
returns boolean
language plpgsql
stable
set search_path to ''
as $function$
declare
 v_series text:=lower(trim(coalesce(p_series,'')));
 v_year int;
 v_month int;
 v_calendar_year int;
 v_months int[];
begin
 if p_start is null then return false; end if;
 v_year:=substring(v_series from '(20[0-9]{2})$')::int;
 v_calendar_year:=extract(year from p_start at time zone 'Asia/Tashkent')::int;
 v_month:=extract(month from p_start at time zone 'Asia/Tashkent')::int;
 if v_series like 'may/june %' then v_months:=array[4,5,6];
 elsif v_series like 'october/november %' or v_series like 'oct/nov %'
     then v_months:=array[9,10,11];
 elsif v_series like 'october %' then v_months:=array[10];
 else return false;
 end if;
 return v_year is not null and v_year=v_calendar_year and
        v_month=any(v_months);
end;
$function$;
revoke all on function private.exam_prep_exam_date_matches_series_v1(text,timestamptz)
 from public,anon,authenticated;

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


-- Original source 20261103036000_exam_prep_p1p5_remaining_work_from_evidence_v1.sql
-- Internal SQL computation, read-only. No numeric-hour recommendations.
create or replace function private.exam_prep_remaining_work_internal_v1(p_uid uuid,p_version bigint,p_component text)
returns jsonb language sql stable security invoker set search_path to '' as $q$
    with latest_states as (
      select distinct on (s.skill_code)
        s.skill_code,
        s.objective_evidence_count,
        s.objective_level,
        s.coverage_confirmed,
        s.unresolved_correction_count,
        s.has_delayed_successful_retest,
        s.has_transfer_evidence,
        s.has_written_evidence
      from private.exam_prep_skill_states s
      where s.user_id=p_uid and
            s.program_version_id=p_version and
            s.component_code=p_component
      order by s.skill_code,s.derived_at desc,s.engine_version desc
    ),
    joined as (
      select c.component_code,c.skill_code,c.official_syllabus_section,
        coalesce(s.objective_evidence_count,0) as objective_count,
        coalesce(s.objective_level,0) as objective_level,
        coalesce(s.coverage_confirmed,false) as coverage_confirmed,
        greatest(coalesce(s.unresolved_correction_count,0),0) as open_corrections,
        coalesce(s.has_delayed_successful_retest,false) as delayed_retest_proven,
        coalesce(s.has_transfer_evidence,false) as transfer_proven,
        coalesce(s.has_written_evidence,false) as written_activity_recorded,
        coalesce(k.requires_retest_for_l3,false) as retest_required,
        coalesce(k.requires_transfer_for_l3,false) as transfer_required,
        coalesce(k.requires_mixed_for_l3,false) as mixed_required,
        coalesce(k.requires_written_for_l2,false) as written_activity_required,
        (k.skill_code is not null) as contract_present
      from private.exam_prep_syllabus_nodes c
      left join latest_states s on s.skill_code=c.skill_code
      left join private.exam_prep_skill_contracts k
        on k.program_version_id=c.program_version_id
          and k.component_code=c.component_code
          and k.skill_code=c.skill_code
      where c.program_version_id=p_version
        and c.component_code=p_component
    ),
    categories as (
      select j.*,
        case
          when j.objective_count=0 then 'unobserved'
          when j.coverage_confirmed and j.objective_level>=2
            and j.open_corrections=0 then 'objective_coverage_confirmed'
          else 'observed_unconfirmed'
        end as evidence_category
      from joined j
    ),
    work as (
      select z.*,
        case
          when not z.contract_present then array['academic_contract_missing']::text[]
          when z.evidence_category='unobserved'
            then array['targeted_check']::text[]
          when z.open_corrections>0
            then array['correction']::text[]
          when z.evidence_category='observed_unconfirmed'
            then array['targeted_practice']::text[]
          else array_remove(array[
            case when z.retest_required and not z.delayed_retest_proven
              then 'delayed_retest'::text end,
            case when (z.transfer_required or z.mixed_required)
                    and not z.transfer_proven
              then 'mixed_transfer'::text end,
            case when z.written_activity_required and not z.written_activity_recorded
              then 'written_work_unscored'::text end
          ]::text[],null::text)
        end as pending_actions
      from categories z
    )

select jsonb_build_object(
 'component_code',p_component,
 'skills_total',count(*),
 'skills_unobserved',count(*) filter(where evidence_category='unobserved'),
 'skills_observed_not_yet_confirmed',count(*) filter(where evidence_category='observed_unconfirmed'),
 'skills_objective_coverage_confirmed_not_final_mastery',count(*) filter(where evidence_category='objective_coverage_confirmed'),
 'skills_with_open_corrections',count(*) filter(where open_corrections>0),
 'historical_current_open_correction_entries',coalesce(sum(open_corrections),0),
 'unique_pending_action_slots',coalesce(sum(cardinality(pending_actions)),0),
 'items',coalesce(jsonb_agg(jsonb_build_object(
  'component_code',component_code,'skill_code',skill_code,
  'evidence_status',evidence_category,'pending_actions',to_jsonb(pending_actions),
  'recorded_unresolved_correction_count',open_corrections,
  'remaining_minutes_min',null,'remaining_minutes_max',null,
  'academic_hours_approved',false,'wrong_answer_multiplication_allowed',false,
  'unresolved_corrections_counted_as_separate_full_skill_courses',false,
  'written_activity_is_verified_method_mark',false
 ) order by skill_code),'[]'::jsonb),
 'remaining_study_minutes_min',null,'remaining_study_minutes_max',null,
 'individually_recommended_weekly_hours',null
) from work;
$q$;
revoke all on function private.exam_prep_remaining_work_internal_v1(uuid,bigint,text) from public,anon,authenticated;

create or replace function public.get_exam_prep_remaining_work_by_skill_safe_v1()
returns jsonb language plpgsql stable security definer set search_path to '' as $p$
declare u uuid; v bigint; a jsonb; b jsonb;
begin
 u:=private.exam_prep_require_core_access_v1();
 select program_version_id into v from private.exam_prep_exam_profiles where user_id=u;
 if v is null then raise exception 'exam_prep_profile_required'; end if;
 a:=private.exam_prep_remaining_work_internal_v1(u,v,'P1');
 b:=private.exam_prep_remaining_work_internal_v1(u,v,'P5');
 if (a->>'skills_total')::int<>45 or (b->>'skills_total')::int<>36
 then raise exception 'exam_prep_canonical_81_skill_contract_incomplete'; end if;
 return jsonb_build_object(
 'contract_version','exam_prep_result_led_remaining_work_v1',
 'P1',a,'P5',b,'numeric_recommendation_available',false,
 'recommended_weekly_hours',null,'recommendation_accept_enabled',false,
 'unknown_is_not_weak',true,'repeated_errors_deduplicated_by_component_skill_phase',true,
 'shared_mathematics_budget_double_counted',false,
 'student_may_study_beyond_plan',true,'grades_predicted',false);
end;
$p$;
revoke all on function public.get_exam_prep_remaining_work_by_skill_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_remaining_work_by_skill_safe_v1() to authenticated,service_role;


-- Original source 20261103037000_exam_prep_p1p5_action_time_norm_registry_v1.sql
-- P2-10 | iClub Mathematics 9709 P1/P5 | DRAFT / isolated PG17 only.
-- Source-bound pending skill actions are study units. Wrong answers do not
-- multiply a full learning course. No invented per-action time values.

create table private.exam_prep_skill_action_time_norms_v1 (
  program_version_id bigint not null,
  component_code text not null check (component_code in ('P1','P5')),
  skill_code text not null,
  action_code text not null check (action_code in (
    'targeted_check','correction','targeted_practice',
    'delayed_retest','mixed_transfer','written_work_unscored'
  )),
  min_active_minutes integer,
  max_active_minutes integer,
  review_status text not null default 'unreviewed'
    check (review_status in ('unreviewed','under_review','approved','retired')),
  method_version text,
  methodology_notes text,
  evidence_references text[] not null default array[]::text[],
  primary_reviewer_ref text,
  independent_approver_ref text,
  reviewed_at timestamptz,
  approved_at timestamptz,
  revision integer not null default 1 check(revision >= 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (program_version_id,skill_code,action_code),
  foreign key (program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code)
    on update restrict on delete restrict,
  constraint exam_prep_skill_action_paper_code_check check (
    (component_code = 'P1' and skill_code like 'P1-%') or
    (component_code = 'P5' and skill_code like 'P5-%')
  ),
  constraint exam_prep_skill_action_valid_intervals check (
    (min_active_minutes is null or min_active_minutes between 1 and 1440) and
    (max_active_minutes is null or max_active_minutes between 1 and 2880) and
    (min_active_minutes is null or max_active_minutes is null or
       max_active_minutes >= min_active_minutes)
  ),
  constraint exam_prep_skill_action_approval_gate check (
    review_status <> 'approved' or (
      min_active_minutes is not null and max_active_minutes is not null and
      nullif(btrim(coalesce(method_version,'')),'') is not null and
      length(btrim(coalesce(methodology_notes,''))) >= 40 and
      coalesce(array_length(evidence_references,1),0) >= 1 and
      nullif(btrim(coalesce(primary_reviewer_ref,'')),'') is not null and
      nullif(btrim(coalesce(independent_approver_ref,'')),'') is not null and
      primary_reviewer_ref <> independent_approver_ref and
      reviewed_at is not null and approved_at is not null and
      reviewed_at <= approved_at
    )
  )
);

alter table private.exam_prep_skill_action_time_norms_v1 enable row level security;
revoke all on private.exam_prep_skill_action_time_norms_v1
  from public,anon,authenticated;
comment on table private.exam_prep_skill_action_time_norms_v1 is
'PRIVATE unreviewed 81-skill x 6-action time source register. No Cambridge-issued personal minutes or learner time quotas. Independent-review gate before arithmetic.';

insert into private.exam_prep_skill_action_time_norms_v1 (
  program_version_id,component_code,skill_code,action_code
)
select s.program_version_id,s.component_code,s.skill_code,a.action_code
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions p on p.id=s.program_version_id
cross join (values
 ('targeted_check'::text),('correction'::text),('targeted_practice'::text),
 ('delayed_retest'::text),('mixed_transfer'::text),('written_work_unscored'::text)
) as a(action_code)
where p.program_key='math_as_p1_p5' and p.status='active'
  and s.component_code in ('P1','P5')
on conflict do nothing;

do $$
declare n int; p1 int; p5 int; numbered int; permitted int;
begin
 select count(*)::int,
        count(*) filter(where component_code='P1')::int,
        count(*) filter(where component_code='P5')::int,
        count(*) filter(where min_active_minutes is not null or
          max_active_minutes is not null)::int,
        count(*) filter(where review_status='approved')::int
 into n,p1,p5,numbered,permitted
 from private.exam_prep_skill_action_time_norms_v1;
 if n<>486 or p1<>270 or p5<>216 or numbered<>0 or permitted<>0 then
   raise exception 'P2-10 requires 81 canonical skills x 6 unapproved, zero-duration actions';
 end if;
end $$;

-- Sum ONLY private reviewed pending-action ranges; NEVER let a learner see
-- them as a complete Cambridge preparation estimate or schedule recommendation.
create or replace function private.exam_prep_action_time_calibration_internal_v1(
 p_uid uuid,p_program_version_id bigint,p_component text
)
returns jsonb
language sql
stable
security invoker
set search_path to ''
as $fn$
with skills as (
 select private.exam_prep_remaining_work_internal_v1(
   p_uid,p_program_version_id,p_component
 ) as payload
), actions as (
 select skill.item->>'skill_code' as skill_code,
        action.action_code
 from skills s
 cross join lateral jsonb_array_elements(s.payload->'items') as skill(item)
 cross join lateral jsonb_array_elements_text(skill.item->'pending_actions')
   as action(action_code)
), examined as (
 select a.skill_code,a.action_code,
        n.min_active_minutes,n.max_active_minutes,
        (n.review_status='approved' and
          n.min_active_minutes is not null and
          n.max_active_minutes is not null) as is_approved
 from actions a
 left join private.exam_prep_skill_action_time_norms_v1 n
   on n.program_version_id=p_program_version_id
   and n.component_code=p_component
   and n.skill_code=a.skill_code and n.action_code=a.action_code
)
select jsonb_build_object(
 'component_code',p_component,
 'unique_pending_action_count',count(*)::int,
 'academically_approved_action_count',count(*) filter(where is_approved)::int,
 'unapproved_action_count',count(*) filter(where not coalesce(is_approved,false))::int,
 'all_pending_action_ranges_reviewed',
    count(*) > 0 and count(*)=count(*) filter(where is_approved),
 'private_targeted_only_min_minutes',case when count(*) > 0 and
    count(*)=count(*) filter(where is_approved)
      then sum(min_active_minutes)::int else null::int end,
 'private_targeted_only_max_minutes',case when count(*) > 0 and
    count(*)=count(*) filter(where is_approved)
      then sum(max_active_minutes)::int else null::int end,
 'all_study_time_approved',false,
 'separate_paper_revision_and_shared_prerequisites_still_required',true
) from examined;
$fn$;

revoke all on function private.exam_prep_action_time_calibration_internal_v1(uuid,bigint,text)
 from public,anon,authenticated;

create or replace function public.get_exam_prep_action_time_calibration_status_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $fn$
declare
 v_uid uuid;
 v_program_version_id bigint;
 v_p1 jsonb;
 v_p5 jsonb;
begin
 v_uid:=private.exam_prep_require_core_access_v1();
 select p.program_version_id into v_program_version_id
 from private.exam_prep_exam_profiles p where p.user_id=v_uid;
 if v_program_version_id is null then raise exception 'exam_prep_profile_required'; end if;

 v_p1:=private.exam_prep_action_time_calibration_internal_v1(v_uid,v_program_version_id,'P1');
 v_p5:=private.exam_prep_action_time_calibration_internal_v1(v_uid,v_program_version_id,'P5');

 return jsonb_build_object(
   'contract_version','exam_prep_action_time_calibration_status_v1',
   'P1',jsonb_build_object(
     'unique_pending_action_count',v_p1->'unique_pending_action_count',
     'academically_approved_action_count',v_p1->'academically_approved_action_count',
     'unapproved_action_count',v_p1->'unapproved_action_count',
     'targeted_minutes_min',null,'targeted_minutes_max',null
   ),
   'P5',jsonb_build_object(
     'unique_pending_action_count',v_p5->'unique_pending_action_count',
     'academically_approved_action_count',v_p5->'academically_approved_action_count',
     'unapproved_action_count',v_p5->'unapproved_action_count',
     'targeted_minutes_min',null,'targeted_minutes_max',null
   ),
   'numeric_recommendation_available',false,
   'recommendation_accept_enabled',false,
   'recommended_weekly_hours',null,
   'paper_practice_and_revision_estimate_pending',true,
   'shared_p1_p5_calendar_capacity_nonadditive',true,
   'no_learning_time_cap',true,
   'no_grade_forecast',true
 );
end;
$fn$;

revoke all on function public.get_exam_prep_action_time_calibration_status_safe_v1()
 from public,anon;
grant execute on function public.get_exam_prep_action_time_calibration_status_safe_v1()
 to authenticated,service_role;

comment on function public.get_exam_prep_action_time_calibration_status_safe_v1() is
'Owner-only aggregated P1/P5 action coverage; ALWAYS withholds targeted hour totals and numeric recommendation pending independent full calendar/paper/academic approval.';


-- Original source 20261103038000_exam_prep_p1p5_action_calibration_candidates_v1.sql
-- P2-11: source-backed calibration CANDIDATES. This is not a study-time estimate.
-- All task metadata stays in private schema; published QA task counts are NOT
-- observation evidence or personal-hour recommendations.
create or replace view private.exam_prep_action_calibration_candidates_v1
with (security_invoker=true,security_barrier=true)
as
select
  n.program_version_id,
  n.component_code,
  n.skill_code,
  n.action_code,
  s.official_syllabus_section,
  s.official_source_url,
  s.book_chapter,
  s.prerequisites_text,
  s.required_mastery_evidence,
  i.published_objective_items,
  i.qa_passed_published_objective,
  i.published_written_tasks,
  i.qa_passed_published_written,
  i.published_diagnostic_assessments,
  i.published_learning_assessments,
  i.published_retest_assessments,
  i.published_mixed_assessments,
  i.content_coverage_status,
  case
    when i.skill_code is null then 'missing_content_inventory'
    when i.content_coverage_status <> 'core_content_source_mapped'
       then 'content_qa_incomplete'
    when n.action_code = 'correction'
       then 'correction_workflow_needs_direct_academic_observation'
    when n.action_code = 'targeted_check'
       and i.published_diagnostic_assessments > 0
       and i.qa_passed_published_objective > 0
       then 'published_candidate_available'
    when n.action_code = 'targeted_practice'
       and i.published_learning_assessments > 0
       and i.qa_passed_published_objective > 0
       then 'published_candidate_available'
    when n.action_code = 'delayed_retest'
       and i.published_retest_assessments > 0
       and i.qa_passed_published_objective > 0
       then 'published_candidate_available'
    when n.action_code = 'mixed_transfer'
       and i.published_mixed_assessments > 0
       and i.qa_passed_published_objective > 0
       then 'published_candidate_available'
    when n.action_code = 'written_work_unscored'
       and i.published_written_tasks > 0
       and i.qa_passed_published_written = i.published_written_tasks
       then 'published_candidate_available'
    else 'no_direct_published_candidate_route'
  end as academic_candidate_status,
  case
    when n.action_code = 'correction'
      then 'Requires a directly observed independent correction workflow, not just another published question'
    when n.action_code = 'written_work_unscored'
      then 'Written completion is practice; correctness of a method is not automatically graded'
    else 'Published assessment availability is not proof of self-study minutes or individual readiness'
  end as calibration_warning,
  n.review_status as time_range_review_status,
  n.min_active_minutes as min_observed_active_minutes_unreleased,
  n.max_active_minutes as max_observed_active_minutes_unreleased,
  n.method_version,
  n.revision as calibration_revision,
  false::boolean as calibrated_personal_duration,
  false::boolean as candidate_route_equals_actual_observation,
  false::boolean as question_timers_equal_independent_study_minutes
from private.exam_prep_skill_action_time_norms_v1 n
join private.exam_prep_syllabus_nodes s
  on s.program_version_id=n.program_version_id
 and s.component_code=n.component_code and s.skill_code=n.skill_code
join private.exam_prep_program_versions p
  on p.id=n.program_version_id and p.program_key='math_as_p1_p5'
  and p.status='active'
left join private.exam_prep_skill_content_calibration_inventory_v1 i
  on i.program_version_id=n.program_version_id
 and i.component_code=n.component_code and i.skill_code=n.skill_code
where n.component_code in ('P1','P5');

revoke all on private.exam_prep_action_calibration_candidates_v1
  from public,anon,authenticated;

comment on view private.exam_prep_action_calibration_candidates_v1 is
'Internal 486 source-bound action calibration CANDIDATES; published QA content is not time evidence. Corrections require directly observed workflow. No learner ID, question key, reserve identifier, personal-minute recommendation or public grant.';


-- Original source 20261103039000_exam_prep_p1p5_conditional_learning_trajectory_v1.sql
-- P2-12 | Conditional remaining-work trajectory.
-- CURRENT verified action is not the same as FUTURE possible work.
-- Additive private projection only, no student UI, changes to academic
-- progress, time estimates or learner budgets.
create or replace function private.exam_prep_remaining_work_trajectory_internal_v1(
  p_uid uuid,
  p_program_version_id bigint,
  p_component text
)
returns jsonb
language sql
stable
security invoker
set search_path to ''
as $trajectory$
with input as (
  select private.exam_prep_remaining_work_internal_v1(
     p_uid,p_program_version_id,p_component
  ) as projection
), items as (
  select step.item as work_item,
         step.item->>'skill_code' as skill_code,
         step.item->>'evidence_status' as evidence_status,
         step.item->'pending_actions' as current_actions
  from input i
  cross join lateral jsonb_array_elements(i.projection->'items') step(item)
), joined as (
  select i.*,
         c.skill_code is not null as skill_contract_present,
         coalesce(c.requires_retest_for_l3,false) as requires_retest,
         coalesce(c.requires_transfer_for_l3,false) as requires_transfer,
         coalesce(c.requires_mixed_for_l3,false) as requires_mixed,
         coalesce(c.requires_written_for_l2,false) as requires_written,
         c.min_retest_delay_days,
         coalesce(s.has_delayed_successful_retest,false) as delayed_retest_proven,
         coalesce(s.has_transfer_evidence,false) as transfer_proven,
         coalesce(s.has_written_evidence,false) as written_activity_recorded
  from items i
  left join private.exam_prep_skill_contracts c
    on c.program_version_id=p_program_version_id
   and c.component_code=p_component
   and c.skill_code=i.skill_code
  left join lateral (
    select s.has_delayed_successful_retest,s.has_transfer_evidence,
           s.has_written_evidence
    from private.exam_prep_skill_states s
    where s.user_id=p_uid and s.program_version_id=p_program_version_id
      and s.component_code=p_component and s.skill_code=i.skill_code
    order by s.derived_at desc,s.engine_version desc
    limit 1
  ) s on true
), trajectories as (
 select j.*,
   case
     when j.evidence_status='unobserved'
       then array['correction','targeted_practice']::text[]
     when j.evidence_status='observed_unconfirmed'
       and j.current_actions @> '["correction"]'::jsonb
       then array['targeted_practice']::text[]
     when j.evidence_status='observed_unconfirmed'
       then array['correction']::text[]
     else array[]::text[]
   end as contingent_if_next_result_not_confirmed,
   case
     when j.evidence_status='objective_coverage_confirmed'
       then array[]::text[]
     else array_remove(array[
       case when j.requires_retest and not j.delayed_retest_proven
         then 'delayed_retest'::text end,
       case when (j.requires_transfer or j.requires_mixed)
           and not j.transfer_proven
         then 'mixed_transfer'::text end,
       case when j.requires_written and not j.written_activity_recorded
         then 'written_work_unscored'::text end
     ]::text[],null::text)
   end as deferred_gates_after_objective_coverage
 from joined j
)
select jsonb_build_object(
 'contract_version','exam_prep_conditional_trajectory_internal_v1',
 'component_code',p_component,
 'canonical_skills',count(*)::int,
 'current_unique_action_slots',
    coalesce(sum(jsonb_array_length(current_actions)),0)::int,
 'currently_unobserved_skills',
    count(*) filter(where evidence_status='unobserved')::int,
 'currently_observed_unconfirmed_skills',
    count(*) filter(where evidence_status='observed_unconfirmed')::int,
 'currently_objective_coverage_confirmed_skills',
    count(*) filter(where evidence_status='objective_coverage_confirmed')::int,
 'missing_academic_contracts',
    count(*) filter(where not skill_contract_present)::int,
 'skills_with_contingent_future_work',
    count(*) filter(where cardinality(contingent_if_next_result_not_confirmed)>0
                       or cardinality(deferred_gates_after_objective_coverage)>0)::int,
 'conditional_future_actions_are_not_current_assignments',true,
 'conditional_future_actions_are_not_calculated_study_hours',true,
 'total_time_to_demonstrated_mastery_minutes_min',null,
 'total_time_to_demonstrated_mastery_minutes_max',null,
 'shared_math_calendar_budget_counted_once',true,
 'all_future_actions_require_new_earned_evidence',true,
 'student_schedule_modified',false,
 'items',coalesce(jsonb_agg(jsonb_build_object(
   'component_code',p_component,
   'skill_code',skill_code,
   'current_evidence_status',evidence_status,
   'current_pending_actions',current_actions,
   'repeated_wrong_answers_billed_separately',false,
   'academic_contract_present',skill_contract_present,
   'possible_next_if_not_confirmed',
      to_jsonb(contingent_if_next_result_not_confirmed),
   'deferred_evidence_gates_after_objective_coverage',
      to_jsonb(deferred_gates_after_objective_coverage),
   'minimum_retest_wait_days_if_required',
      case when requires_retest and not delayed_retest_proven
        then min_retest_delay_days else null::smallint end,
   'written_work_is_a_verified_cambridge_mark',false,
   'future_actions_counted_in_current_study_minutes',false,
   'whole_skill_time_to_mastery_min',null,
   'whole_skill_time_to_mastery_max',null
 ) order by skill_code),'[]'::jsonb)
) from trajectories;
$trajectory$;
revoke all on function
  private.exam_prep_remaining_work_trajectory_internal_v1(uuid,bigint,text)
from public,anon,authenticated;

comment on function
  private.exam_prep_remaining_work_trajectory_internal_v1(uuid,bigint,text)
is 'P2-12: private 81-skill pathway separates verified next work from potential future corrections/retention, preserves objective and written evidence distinction, never issues hours, grades or a user schedule.';


-- OWNER-ONLY, nonbinding workload summary. Potential future activities
-- must NEVER be presented as existing required work or numeric hours.
create or replace function public.get_exam_prep_conditional_trajectory_status_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $fn$
declare
 v_uid uuid;
 v_program_version_id bigint;
 v_p1 jsonb;
 v_p5 jsonb;
begin
 v_uid:=private.exam_prep_require_core_access_v1();

 select p.program_version_id into v_program_version_id
 from private.exam_prep_exam_profiles p
 where p.user_id=v_uid;
 if v_program_version_id is null then
   raise exception 'exam_prep_profile_required';
 end if;

 v_p1:=private.exam_prep_remaining_work_trajectory_internal_v1(
   v_uid,v_program_version_id,'P1'
 );
 v_p5:=private.exam_prep_remaining_work_trajectory_internal_v1(
   v_uid,v_program_version_id,'P5'
 );
 if coalesce((v_p1->>'canonical_skills')::int,0)<>45
     or coalesce((v_p5->>'canonical_skills')::int,0)<>36
     or coalesce((v_p1->>'missing_academic_contracts')::int,81)<>0
     or coalesce((v_p5->>'missing_academic_contracts')::int,81)<>0
 then raise exception 'exam_prep_trajectory_source_incomplete'; end if;

 return jsonb_build_object(
  'contract_version','exam_prep_conditional_trajectory_status_v1',
  'P1',jsonb_build_object(
     'canonical_skills',v_p1->'canonical_skills',
     'current_unique_action_slots',v_p1->'current_unique_action_slots',
     'skills_with_possible_downstream_work',v_p1->'skills_with_contingent_future_work',
     'total_time_to_demonstrated_mastery_minutes_min',null,
     'total_time_to_demonstrated_mastery_minutes_max',null
   ),
  'P5',jsonb_build_object(
     'canonical_skills',v_p5->'canonical_skills',
     'current_unique_action_slots',v_p5->'current_unique_action_slots',
     'skills_with_possible_downstream_work',v_p5->'skills_with_contingent_future_work',
     'total_time_to_demonstrated_mastery_minutes_min',null,
     'total_time_to_demonstrated_mastery_minutes_max',null
   ),
  'possible_future_work_not_assigned',true,
  'unknown_skill_needs_check_not_whole_tuition',true,
  'wrong_responses_not_multiplied_into_courses',true,
  'full_workload_time_calibration_status','unverified_trajectory_durations',
  'numerical_weekly_hour_recommendation',null,
  'recommendation_accept_enabled',false,
  'paper_rehearsal_and_periodic_revision_not_double_counted',true,
  'total_math_calendar_capacity_not_summed_twice',true,
  'no_written_self_awarded_grade',true,
  'student_progress_changed',false
 );
end;
$fn$;

revoke all on function public.get_exam_prep_conditional_trajectory_status_safe_v1()
 from public,anon;
grant execute on function public.get_exam_prep_conditional_trajectory_status_safe_v1()
 to authenticated,service_role;

comment on function public.get_exam_prep_conditional_trajectory_status_safe_v1() is
'Owner-only current-action count separate from contingent future work. No estimates, no grade, no user study schedule modification.';


-- Original source 20261103040000_exam_prep_simple_learning_timeline_v1.sql
-- P2-13 architect simplification: ONE timeline at present.
-- Start -> today -> selected exam date. What is proven, what is still
-- unproven, how much student-elected Mathematics calendar time remains.
-- No guessed "required study hours" from practice question timers.
-- READ-ONLY additive owner RPC, no UI switch or legacy mutations.
create or replace function public.get_exam_prep_simple_learning_timeline_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $fn$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_now timestamptz;
  v_component text;
  v_p1 jsonb;
  v_p5 jsonb;
  v_data jsonb;
  v_evidence jsonb;
  v_exam timestamptz;
  v_total int;
  v_confirmed int;
  v_in_progress int;
  v_not_checked int;
  v_remaining int;
  v_calendar_status text;
  v_weeks numeric;
  v_earliest timestamptz;
  v_latest timestamptz;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;

  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  for v_component in select unnest(array['P1'::text,'P5'::text]) loop
    v_evidence:=private.exam_prep_remaining_work_internal_v1(
      v_uid,v_profile.program_version_id,v_component
    );
    v_total:=coalesce((v_evidence->>'skills_total')::int,0);
    if (v_component='P1' and v_total<>45)
       or (v_component='P5' and v_total<>36) then
      raise exception 'exam_prep_incomplete_syllabus';
    end if;
    v_confirmed:=coalesce((v_evidence->>'skills_objective_coverage_confirmed_not_final_mastery')::int,0);
    v_in_progress:=coalesce((v_evidence->>'skills_observed_not_yet_confirmed')::int,0);
    v_not_checked:=coalesce((v_evidence->>'skills_unobserved')::int,0);
    if v_confirmed+v_in_progress+v_not_checked<>v_total then
      raise exception 'exam_prep_inconsistent_evidence';
    end if;

    select a.scheduled_start_at into v_exam
    from private.exam_prep_exam_appointments a
    where a.user_id=v_uid
      and a.program_version_id=v_profile.program_version_id
      and a.component_code=v_component
      and (a.exam_series_snapshot is null or
       lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))))
    order by a.confirmed_at desc nulls last limit 1;

    v_calendar_status:=case
      when v_exam is null then 'exam_date_not_yet_selected'
      when not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_exam)
        then 'exam_date_mismatch'
      when v_exam<=v_now then 'exam_already_passed'
      else 'valid_exam_date'
    end;
    v_weeks:=case when v_calendar_status='valid_exam_date'
       then greatest(extract(epoch from (v_exam-v_now))::numeric/604800,0)
       else null::numeric end;
    if v_weeks is not null then
      if v_earliest is null or v_exam<v_earliest then v_earliest:=v_exam; end if;
      if v_latest is null or v_exam>v_latest then v_latest:=v_exam; end if;
    end if;

    v_remaining:=v_total-v_confirmed;
    v_data:=jsonb_build_object(
      'component_code',v_component,
      'start_at',v_profile.created_at,
      'as_of',v_now,
      'exam_at',v_exam,
      'exam_date_status',v_calendar_status,
      'weeks_to_exam',round(v_weeks,2),
      'total_syllabus_skills',v_total,
      'objectively_covered_skills',v_confirmed,
      'already_attempted_not_yet_confirmed_skills',v_in_progress,
      'not_yet_checked_skills',v_not_checked,
      'skills_not_yet_objectively_covered',v_remaining,
      'objectively_confirmed_progress_percent',
        round(100*v_confirmed::numeric/v_total,1),
      'remaining_skill_share_percent',
        round(100*v_remaining::numeric/v_total,1),
      'planned_math_hours_available_to_this_exam',
        case when v_weeks is not null and v_profile.mathematics_hours_budget is not null
          then round(v_weeks*v_profile.mathematics_hours_budget,1)
          else null::numeric end,
      'required_hours_for_remaining_skills',null,
      'required_hours_status','personal_active_study_pace_not_verified',
      'confirmed_objective_coverage_is_not_final_written_exam_mastery',true
    );
    if v_component='P1' then v_p1:=v_data; else v_p5:=v_data; end if;
  end loop;
  return jsonb_build_object(
    'contract_version','exam_prep_one_line_progress_timeline_v1',
    'as_of',v_now,
    'start_at',v_profile.created_at,
    'P1',v_p1,
    'P5',v_p5,
    'math_hours_per_week_chosen_by_student',v_profile.mathematics_hours_budget,
    'earliest_valid_exam',v_earliest,
    'latest_valid_exam',v_latest,
    'shared_math_hours_available_to_earliest_exam',
      case when v_earliest is not null and v_profile.mathematics_hours_budget is not null
       then round(greatest(extract(epoch from (v_earliest-v_now)),0)::numeric /
                  604800*v_profile.mathematics_hours_budget,1)
       else null::numeric end,
    'shared_math_hours_available_to_latest_exam',
      case when v_latest is not null and v_profile.mathematics_hours_budget is not null
       then round(greatest(extract(epoch from (v_latest-v_now)),0)::numeric /
                  604800*v_profile.mathematics_hours_budget,1)
       else null::numeric end,
    'p1_p5_hour_budgets_are_not_additive',true,
    'planned_calendar_hours_are_not_proven_required_learning_hours',true,
    'required_personal_hours_total',null,
    'required_personal_hours_method','only_after_observed_learning_pace_is_available',
    'no_automatic_schedule_change',true,
    'no_study_cap',true,
    'no_progress_mutation',true,
    'no_written_exam_grade_claim',true
  );
end;
$fn$;
revoke all on function public.get_exam_prep_simple_learning_timeline_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_simple_learning_timeline_safe_v1()
  to authenticated,service_role;
comment on function public.get_exam_prep_simple_learning_timeline_safe_v1() is
'Simple current snapshot: start-now-exam line, proven vs unproven skills, student chosen available calendar hours; no false learning-hour forecasts, no writes.';


-- Original source 20261103041000_exam_prep_simple_cambridge_source_time_estimate_v1.sql
-- iClub P2-14: practical time estimate from Cambridge Scheme of Work,
-- source-mapped current 9709 P1/P5 skill evidence. Architect requested a
-- useful number without waiting for empirical personal timing research.
--
-- Cambridge 2020 topic hours = GUIDED TEACHING, NOT independent study.
-- iClub's explicit 1:1 planning proxy and 0.6/0.8 completion adjustments
-- are a product HEURISTIC, NOT official Cambridge individual requirements.
-- NO updates to live learner evidence, profile, exams, questions or clocks.

create or replace function private.exam_prep_simple_guided_effort_internal_v1(
  p_uid uuid,p_version bigint,p_component text
)
returns jsonb language sql stable security invoker set search_path to ''
as $fn$
with authentic as (
  select private.exam_prep_remaining_work_internal_v1(p_uid,p_version,p_component)
     as evidence
), items as (
  select e.item->>'skill_code' skill_code,
         e.item->>'evidence_status' evidence_status,
         coalesce((e.item->>'recorded_unresolved_correction_count')::int,0) open_corrections
  from authentic a
  cross join lateral jsonb_array_elements(a.evidence->'items') e(item)
), sections as (
 select s.skill_code,s.component_code,s.official_syllabus_section,
        h.suggested_guided_teaching_hours::numeric as topic_guided_hours,
        h.source_url,h.source_scheme_version,
        count(*) over(partition by s.program_version_id,s.component_code,
           s.official_syllabus_section)::numeric as skills_in_section
 from private.exam_prep_syllabus_nodes s
 left join private.exam_prep_historical_topic_teaching_refs_v1 h
   on h.program_version_id=s.program_version_id
   and h.component_code=s.component_code
   and h.official_syllabus_section=s.official_syllabus_section
 where s.program_version_id=p_version and s.component_code=p_component
), weighted as (
 select s.*,i.evidence_status,i.open_corrections,
   case
     when i.evidence_status='objective_coverage_confirmed' then 0.00::numeric
     when i.evidence_status='unobserved' then 1.00::numeric
     when i.evidence_status='observed_unconfirmed' and i.open_corrections>0
       then 0.80::numeric
     when i.evidence_status='observed_unconfirmed' then 0.60::numeric
     else null::numeric
   end as remaining_work_factor,
   (s.topic_guided_hours*60/s.skills_in_section) as baseline_guided_minutes
 from sections s left join items i on i.skill_code=s.skill_code
)
select jsonb_build_object(
 'component_code',p_component,
 'skill_count',count(*)::int,
 'source_coverage_count',count(topic_guided_hours)::int,
 'historical_guided_content_hours',round(sum(topic_guided_hours/skills_in_section),2),
 'estimated_remaining_hours',case
   when count(*)=count(topic_guided_hours) and count(*)=count(remaining_work_factor)
     then round(sum(baseline_guided_minutes*remaining_work_factor)/60,1)
   else null::numeric end,
 'estimated_remaining_hours_lower_sensitivity',case
   when count(*)=count(topic_guided_hours) and count(*)=count(remaining_work_factor)
     then round(sum(baseline_guided_minutes*remaining_work_factor)*0.75/60,1)
   else null::numeric end,
 'estimated_remaining_hours_upper_sensitivity',case
   when count(*)=count(topic_guided_hours) and count(*)=count(remaining_work_factor)
     then round(sum(baseline_guided_minutes*remaining_work_factor)*1.25/60,1)
   else null::numeric end,
 'source_kind','cambridge_2020_scheme_of_work_guided_teaching_topic_hours',
 'assumption_kind','iclub_explicit_guided_to_study_planning_proxy_not_measured',
 'factors',jsonb_build_object(
    'unobserved',1.0,'attempted_unconfirmed_no_open_error',0.6,
    'attempted_unconfirmed_open_error',0.8,'objective_covered',0.0),
 'sensitivity_band_is_statistical_confidence_interval',false,
 'source_hours_are_official_private_study_requirement',false,
 'estimate_is_cambridge_endorsed_personal_hour_requirement',false,
 'items',coalesce(jsonb_agg(jsonb_build_object(
    'skill_code',skill_code,'section',official_syllabus_section,
    'source_topic_teaching_hours',topic_guided_hours,
    'source_skills_in_topic',skills_in_section,
    'base_guided_minutes',round(baseline_guided_minutes,1),
    'remaining_work_factor',remaining_work_factor,
    'estimated_remaining_minutes',round(baseline_guided_minutes*remaining_work_factor,1)
 ) order by skill_code),'[]'::jsonb)
) from weighted;
$fn$;
revoke all on function private.exam_prep_simple_guided_effort_internal_v1(uuid,bigint,text)
 from public,anon,authenticated;

create or replace function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
returns jsonb language plpgsql stable security definer set search_path to ''
as $fn$
declare
 v_uid uuid;
 v_version bigint;
 v_original jsonb;
 v_p1 jsonb;
 v_p5 jsonb;
 v_p1hrs numeric;
 v_p5hrs numeric;
 v_w1 numeric;
 v_w5 numeric;
 v_total numeric;
 v_weekly numeric;
 v_first_rate numeric;
 v_later_rate numeric;
 v_known text;
 v_budget numeric;
begin
 v_uid:=private.exam_prep_require_core_access_v1();
 select p.program_version_id,p.mathematics_hours_budget
 into v_version,v_budget
 from private.exam_prep_exam_profiles p
 where p.user_id=v_uid;
 if v_version is null then raise exception 'exam_prep_profile_required'; end if;

 v_original:=public.get_exam_prep_simple_learning_timeline_safe_v1();
 v_p1:=private.exam_prep_simple_guided_effort_internal_v1(v_uid,v_version,'P1');
 v_p5:=private.exam_prep_simple_guided_effort_internal_v1(v_uid,v_version,'P5');

 if (v_p1->>'skill_count')::int<>45 or (v_p5->>'skill_count')::int<>36
   or (v_p1->>'source_coverage_count')::int<>45
   or (v_p5->>'source_coverage_count')::int<>36
   or (v_p1->>'historical_guided_content_hours')::numeric<>90
   or (v_p5->>'historical_guided_content_hours')::numeric<>50
 then raise exception 'exam_prep_guided_content_source_incomplete'; end if;

 v_p1hrs:=(v_p1->>'estimated_remaining_hours')::numeric;
 v_p5hrs:=(v_p5->>'estimated_remaining_hours')::numeric;
 if v_p1hrs is null or v_p5hrs is null then
    raise exception 'exam_prep_current_skill_evidence_incomplete';
 end if;
 v_total:=v_p1hrs+v_p5hrs;
 v_w1:=case when v_original->'P1'->>'exam_date_status'='valid_exam_date'
   then (v_original->'P1'->>'weeks_to_exam')::numeric else null::numeric end;
 v_w5:=case when v_original->'P5'->>'exam_date_status'='valid_exam_date'
   then (v_original->'P5'->>'weeks_to_exam')::numeric else null::numeric end;
 v_w1:=case when v_w1>0 then v_w1 else null::numeric end;
 v_w5:=case when v_w5>0 then v_w5 else null::numeric end;

 -- If both confirmed deadlines exist, solve minimal constant joint Math
 -- weekly pace satisfying earlier deadline and combined later deadline.
 -- This is a SHARED resource, not P1 weeks + P5 weeks.
 if v_w1 is not null and v_w5 is not null then
    if v_w1<=v_w5 then
      v_first_rate:=v_p1hrs/v_w1;
      v_later_rate:=v_total/v_w5;
    else
      v_first_rate:=v_p5hrs/v_w5;
      v_later_rate:=v_total/v_w1;
    end if;
    v_weekly:=round(greatest(v_first_rate,v_later_rate),1);
    v_known:='both_paper_dates_confirmed';
 else
    v_weekly:=null;
    v_known:='missing_at_least_one_paper_exam_date';
 end if;

 return (v_original || jsonb_build_object(
  'contract_version','exam_prep_one_line_progress_timeline_v2_estimated',
  'P1',v_original->'P1'||jsonb_build_object(
    'estimated_remaining_study_hours',v_p1hrs,
    'estimated_remaining_study_hours_low',v_p1->'estimated_remaining_hours_lower_sensitivity',
    'estimated_remaining_study_hours_high',v_p1->'estimated_remaining_hours_upper_sensitivity',
    'estimated_component_weekly_hours',case when v_w1 is not null
       then round(v_p1hrs/v_w1,1) else null::numeric end,
    'estimate_is_iclub_heuristic',true),
  'P5',v_original->'P5'||jsonb_build_object(
    'estimated_remaining_study_hours',v_p5hrs,
    'estimated_remaining_study_hours_low',v_p5->'estimated_remaining_hours_lower_sensitivity',
    'estimated_remaining_study_hours_high',v_p5->'estimated_remaining_hours_upper_sensitivity',
    'estimated_component_weekly_hours',case when v_w5 is not null
       then round(v_p5hrs/v_w5,1) else null::numeric end,
    'estimate_is_iclub_heuristic',true),
  'estimated_remaining_math_hours',v_total,
  'baseline_math_guided_content_hours',140,
  'estimated_joint_math_hours_per_week',v_weekly,
  'joint_paper_dates_status',v_known,
  'existing_chosen_math_hours_per_week',v_budget,
  'estimated_weekly_hours_difference_from_chosen',
     case when v_weekly is not null and v_budget is not null
       then round(v_weekly-v_budget,1) else null::numeric end,
  'estimate_method','iclub_cambridge_2020_topic_guided_hours_times_skill_status_factors',
  'source_guided_hours_are_not_private_study_hours',true,
  'factors_are_iclub_planning_assumptions_not_official_cambridge',true,
  'estimate_is_not_a_grade_or_completion_guarantee',true,
  'recommended_schedule_applied_automatically',false,
  'study_access_capped',false,
  'learning_evidence_mutated',false
 ));
end;
$fn$;
revoke all on function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
 from public,anon;
grant execute on function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
 to authenticated,service_role;

comment on function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2() is
'iClub approximate 9709 P1/P5 source-weighted remaining hours and joint deadline pace. Historical Cambridge teacher-guided hours are an explicit unvalidated student planning proxy, not official independent-study guidance. Strict owner-only, read-only, no automatic plan edits.';


-- Original source 20261103042000_exam_prep_learner_chosen_dates_v1.sql
-- P2-16: student calendar day is THEIR own exam date in iClub.
-- No school approval, no false official Cambridge exam clock, no series gating
-- for personal dates, no reads/writes to legacy appointments or exam results.
-- This new private table has NO exposed direct role privileges.
create table if not exists private.exam_prep_learner_exam_dates_v1 (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  exam_date date null,
  source text not null default 'learner_selected'
    check(source='learner_selected'),
  updated_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code)
);
alter table private.exam_prep_learner_exam_dates_v1 enable row level security;
revoke all on table private.exam_prep_learner_exam_dates_v1
  from public,anon,authenticated;
comment on table private.exam_prep_learner_exam_dates_v1 is
'Only learner-chosen calendar-day preferences for P1/P5 planning; nullable day means intentional clear. Not a school-confirmed official timetable. No direct client grants.';

-- P2-13 architect simplification: ONE timeline at present.
-- Start -> today -> selected exam date. What is proven, what is still
-- unproven, how much student-elected Mathematics calendar time remains.
-- No guessed "required study hours" from practice question timers.
-- READ-ONLY additive owner RPC, no UI switch or legacy mutations.
create or replace function public.get_exam_prep_simple_learning_timeline_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $fn$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_now timestamptz;
  v_component text;
  v_p1 jsonb;
  v_p5 jsonb;
  v_data jsonb;
  v_evidence jsonb;
  v_exam timestamptz;
  v_learner_date date;
  v_has_learner_date boolean;
  v_total int;
  v_confirmed int;
  v_in_progress int;
  v_not_checked int;
  v_remaining int;
  v_calendar_status text;
  v_weeks numeric;
  v_earliest timestamptz;
  v_latest timestamptz;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;

  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  for v_component in select unnest(array['P1'::text,'P5'::text]) loop
    v_evidence:=private.exam_prep_remaining_work_internal_v1(
      v_uid,v_profile.program_version_id,v_component
    );
    v_total:=coalesce((v_evidence->>'skills_total')::int,0);
    if (v_component='P1' and v_total<>45)
       or (v_component='P5' and v_total<>36) then
      raise exception 'exam_prep_incomplete_syllabus';
    end if;
    v_confirmed:=coalesce((v_evidence->>'skills_objective_coverage_confirmed_not_final_mastery')::int,0);
    v_in_progress:=coalesce((v_evidence->>'skills_observed_not_yet_confirmed')::int,0);
    v_not_checked:=coalesce((v_evidence->>'skills_unobserved')::int,0);
    if v_confirmed+v_in_progress+v_not_checked<>v_total then
      raise exception 'exam_prep_inconsistent_evidence';
    end if;

    -- Student-chosen P1/P5 dates are authoritative for this PERSONAL plan.
    -- They are separate from legacy exam-operations appointment records.
    select d.exam_date into v_learner_date
    from private.exam_prep_learner_exam_dates_v1 d
    where d.user_id=v_uid
      and d.program_version_id=v_profile.program_version_id
      and d.component_code=v_component;
    v_has_learner_date:=found;
    if v_has_learner_date then
      -- The date is a calendar DAY, not a claimed official exam start time.
      -- Midday Tashkent prevents timezone midnight drift on rendering.
      v_exam:=case when v_learner_date is not null
        then ((v_learner_date + time '12:00') at time zone 'Asia/Tashkent')
        else null::timestamptz end;
    else
      -- Preserve previously entered appointment if no personal preference
      -- has been saved; never overwrite or mutate these historic records.
      select a.scheduled_start_at into v_exam
      from private.exam_prep_exam_appointments a
      where a.user_id=v_uid
        and a.program_version_id=v_profile.program_version_id
        and a.component_code=v_component
        and (a.exam_series_snapshot is null or
         lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))))
      order by a.confirmed_at desc nulls last limit 1;
    end if;

    v_calendar_status:=case
      when v_exam is null then 'exam_date_not_yet_selected'
      when v_has_learner_date and
        v_learner_date<=(v_now at time zone 'Asia/Tashkent')::date
        then 'exam_already_passed'
      when not v_has_learner_date and
        not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_exam)
        then 'exam_date_mismatch'
      when v_exam<=v_now then 'exam_already_passed'
      else 'valid_exam_date'
    end;
    v_weeks:=case when v_calendar_status='valid_exam_date'
       then greatest(extract(epoch from (v_exam-v_now))::numeric/604800,0)
       else null::numeric end;
    if v_weeks is not null then
      if v_earliest is null or v_exam<v_earliest then v_earliest:=v_exam; end if;
      if v_latest is null or v_exam>v_latest then v_latest:=v_exam; end if;
    end if;

    v_remaining:=v_total-v_confirmed;
    v_data:=jsonb_build_object(
      'component_code',v_component,
      'start_at',v_profile.created_at,
      'as_of',v_now,
      'exam_at',v_exam,
      'exam_date_status',v_calendar_status,
      'exam_date_source',case when v_has_learner_date then 'learner_selected'
        else 'legacy_exam_appointment' end,
      'weeks_to_exam',round(v_weeks,2),
      'total_syllabus_skills',v_total,
      'objectively_covered_skills',v_confirmed,
      'already_attempted_not_yet_confirmed_skills',v_in_progress,
      'not_yet_checked_skills',v_not_checked,
      'skills_not_yet_objectively_covered',v_remaining,
      'objectively_confirmed_progress_percent',
        round(100*v_confirmed::numeric/v_total,1),
      'remaining_skill_share_percent',
        round(100*v_remaining::numeric/v_total,1),
      'planned_math_hours_available_to_this_exam',
        case when v_weeks is not null and v_profile.mathematics_hours_budget is not null
          then round(v_weeks*v_profile.mathematics_hours_budget,1)
          else null::numeric end,
      'required_hours_for_remaining_skills',null,
      'required_hours_status','personal_active_study_pace_not_verified',
      'confirmed_objective_coverage_is_not_final_written_exam_mastery',true
    );
    if v_component='P1' then v_p1:=v_data; else v_p5:=v_data; end if;
  end loop;
  return jsonb_build_object(
    'contract_version','exam_prep_one_line_progress_timeline_v1',
    'as_of',v_now,
    'start_at',v_profile.created_at,
    'P1',v_p1,
    'P5',v_p5,
    'math_hours_per_week_chosen_by_student',v_profile.mathematics_hours_budget,
    'earliest_valid_exam',v_earliest,
    'latest_valid_exam',v_latest,
    'shared_math_hours_available_to_earliest_exam',
      case when v_earliest is not null and v_profile.mathematics_hours_budget is not null
       then round(greatest(extract(epoch from (v_earliest-v_now)),0)::numeric /
                  604800*v_profile.mathematics_hours_budget,1)
       else null::numeric end,
    'shared_math_hours_available_to_latest_exam',
      case when v_latest is not null and v_profile.mathematics_hours_budget is not null
       then round(greatest(extract(epoch from (v_latest-v_now)),0)::numeric /
                  604800*v_profile.mathematics_hours_budget,1)
       else null::numeric end,
    'p1_p5_hour_budgets_are_not_additive',true,
    'planned_calendar_hours_are_not_proven_required_learning_hours',true,
    'required_personal_hours_total',null,
    'required_personal_hours_method','only_after_observed_learning_pace_is_available',
    'no_automatic_schedule_change',true,
    'no_study_cap',true,
    'no_progress_mutation',true,
    'no_written_exam_grade_claim',true
  );
end;
$fn$;
revoke all on function public.get_exam_prep_simple_learning_timeline_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_simple_learning_timeline_safe_v1()
  to authenticated,service_role;
comment on function public.get_exam_prep_simple_learning_timeline_safe_v1() is
'Simple current snapshot: start-now-exam line, proven vs unproven skills, student chosen available calendar hours; no false learning-hour forecasts, no writes.';


-- One explicit "Save dates" action writes both dates atomically for this owner.
-- NULL is an intentional clear; never touches legacy appointment/status records.
create or replace function public.save_my_exam_prep_timeline_dates_safe_v1(
  p_p1_date date default null,
  p_p5_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_uid uuid;
  v_version bigint;
  v_today date;
  v_last date;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select p.program_version_id into v_version
  from private.exam_prep_exam_profiles p where p.user_id=v_uid;
  if v_version is null then raise exception 'exam_prep_profile_required'; end if;

  v_today:=(now() at time zone 'Asia/Tashkent')::date;
  v_last:=(v_today + interval '3 years')::date;
  if (p_p1_date is not null and (p_p1_date<=v_today or p_p1_date>v_last))
     or (p_p5_date is not null and (p_p5_date<=v_today or p_p5_date>v_last))
  then
    raise exception 'exam_prep_choose_future_date_within_three_years'
      using errcode='22007';
  end if;

  insert into private.exam_prep_learner_exam_dates_v1
    (user_id,program_version_id,component_code,exam_date,source,updated_at)
  values
    (v_uid,v_version,'P1',p_p1_date,'learner_selected',now()),
    (v_uid,v_version,'P5',p_p5_date,'learner_selected',now())
  on conflict(user_id,program_version_id,component_code)
  do update set exam_date=excluded.exam_date,
    source='learner_selected',updated_at=now();

  -- Return the refreshed approximate-hours timeline as part of this one
  -- explicit user-initiated save: no extra read or UI reload required.
  return public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2();
end;
$fn$;
revoke all on function public.save_my_exam_prep_timeline_dates_safe_v1(date,date)
  from public,anon;
grant execute on function public.save_my_exam_prep_timeline_dates_safe_v1(date,date)
  to authenticated,service_role;
comment on function public.save_my_exam_prep_timeline_dates_safe_v1(date,date) is
'Owner-only P1/P5 personal calendar dates saved on explicit tap. No school approval, no historical appointment or learning-result mutation. Returns renewed approximate iClub study plan.';

COMMIT;
