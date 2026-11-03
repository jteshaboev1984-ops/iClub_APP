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
