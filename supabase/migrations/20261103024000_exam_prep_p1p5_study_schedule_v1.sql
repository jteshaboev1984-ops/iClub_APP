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
