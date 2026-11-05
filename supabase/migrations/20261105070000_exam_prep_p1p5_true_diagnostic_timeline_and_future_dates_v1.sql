-- Mathematics P1/P5 D09-07 / D08 / architect: no unapproved time blockers.
-- PREVIEW ONLY: read-only learner Stage0 start + nonblocking future personal dates.
-- One additive migration after D09 source/period migrations, no beta cleanup.
-- Copy the currently effective P2-16 owner RPCs without changing identity,
-- schedule calculations, dates already stored, scores, budgets or user progress.
BEGIN;

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
  v_periods jsonb;
  v_component_period jsonb;
  v_component_start timestamptz;
  v_first_diagnostic_start timestamptz;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;

  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  -- Reuse the already owner-verified independent P1/P5 Stage0 period API.
  -- Frozen T0 wins for new learners; historical completed beta has an
  -- explicitly derived fallback. No new gates, snapshots or student writes.
  v_periods:=public.get_exam_prep_diagnostic_periods_safe_v1();
  for v_component in select unnest(array['P1'::text,'P5'::text]) loop
    v_component_period:=v_periods->v_component;
    v_component_start:=case
      when v_component_period->>'status'='diagnostic_period_ready'
        then (v_component_period->>'diagnostic_completed_at')::timestamptz
      else null::timestamptz end;
    if v_component_start is not null
      and (v_first_diagnostic_start is null
           or v_component_start<v_first_diagnostic_start) then
      v_first_diagnostic_start:=v_component_start;
    end if;
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
      'start_at',v_component_start,
      'diagnostic_start_status',coalesce(v_component_period->>'status','diagnostic_pending'),
      'diagnostic_anchor_immutable',coalesce(
        (v_component_period->>'anchor_immutable')::boolean,false),
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
    'start_at',v_first_diagnostic_start,
    'profile_created_at',v_profile.created_at,
    'start_at_source','earliest_completed_p1_or_p5_diagnostic',
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
'Diagnostic-anchored owner timeline: P1 and P5 start independently from verified first Stage0 T0 (derived legacy fallback); no fabricated signup-as-diagnostic or automatic plan writes.';

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
  -- Architect-approved maximum: four calendar years from the learner's
  -- current Tashkent day. A personal planning date is not an official
  -- Cambridge exam appointment. Keep explicit Save and current owner ACL.
  v_last:=(v_today + interval '4 years')::date;
  if (p_p1_date is not null and (p_p1_date<=v_today or p_p1_date>v_last))
     or (p_p5_date is not null and (p_p5_date<=v_today or p_p5_date>v_last))
  then
    raise exception 'exam_prep_choose_future_date_within_four_years'
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
'Owner-only future P1/P5 personal dates within four calendar years, saved only after explicit tap. No official appointment or academic-result mutation. Returns refreshed iClub planning estimate.';

COMMIT;
