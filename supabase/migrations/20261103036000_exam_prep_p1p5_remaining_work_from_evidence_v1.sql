-- iClub Mathematics P1/P5: learner-result-first REMAINING WORK inventory.
-- Package 2 / Issue #450 / Architect decision: evidence identifies outstanding
-- work; do NOT multiply repeated wrong responses by a whole learning cycle.
-- No learner-specific hours until real independently approved activity-duration
-- norms exist. Additive owner-only READ-ONLY API. Legacy state untouched.

create or replace function public.get_exam_prep_remaining_work_by_skill_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_program_version_id bigint;
  v_component text;
  v_rows jsonb;
  v_unknown int;
  v_unconfirmed int;
  v_confirmed int;
  v_needs_correction int;
  v_unresolved_errors int;
  v_pending_action_slots int;
  v_result jsonb:='{}'::jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  select p.program_version_id into v_program_version_id
  from private.exam_prep_exam_profiles p
  where p.user_id=v_uid;

  if v_program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;

  foreach v_component in array array['P1','P5'] loop
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
      where s.user_id=v_uid and
            s.program_version_id=v_program_version_id and
            s.component_code=v_component
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
      where c.program_version_id=v_program_version_id
        and c.component_code=v_component
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
    select
      coalesce(jsonb_agg(
        jsonb_build_object(
          'skill_code',w.skill_code,
          'component_code',w.component_code,
          'syllabus_section',w.official_syllabus_section,
          'evidence_status',w.evidence_category,
          'pending_actions',to_jsonb(w.pending_actions),
          'wrong_answer_multiplication_allowed',false,
          'recorded_unresolved_correction_count',w.open_corrections,
          'unresolved_corrections_counted_as_separate_full_skill_courses',false,
          'correction_retest_may_be_required_after_resolution',
             w.open_corrections>0,
          'written_activity_is_verified_method_mark',false,
          'remaining_minutes_min',null,
          'remaining_minutes_max',null,
          'academic_hours_approved',false
        ) order by w.skill_code
      ),'[]'::jsonb),
      count(*) filter(where w.evidence_category='unobserved')::int,
      count(*) filter(where w.evidence_category='observed_unconfirmed')::int,
      count(*) filter(where w.evidence_category='objective_coverage_confirmed')::int,
      count(*) filter(where w.open_corrections>0)::int,
      coalesce(sum(w.open_corrections),0)::int,
      coalesce(sum(cardinality(w.pending_actions)),0)::int
    into v_rows,v_unknown,v_unconfirmed,v_confirmed,
         v_needs_correction,v_unresolved_errors,v_pending_action_slots
    from work w;

    if jsonb_array_length(v_rows) <> case when v_component='P1' then 45 else 36 end then
      raise exception 'exam_prep_canonical_81_skill_contract_incomplete';
    end if;

    v_result:=v_result||jsonb_build_object(
      v_component,jsonb_build_object(
        'component_code',v_component,
        'skills_total',jsonb_array_length(v_rows),
        'skills_unobserved',v_unknown,
        'skills_observed_not_yet_confirmed',v_unconfirmed,
        'skills_objective_coverage_confirmed_not_final_mastery',v_confirmed,
        'skills_with_open_corrections',v_needs_correction,
        'historical_current_open_correction_entries',v_unresolved_errors,
        'unique_pending_action_slots',v_pending_action_slots,
        'items',v_rows,
        'remaining_study_minutes_min',null,
        'remaining_study_minutes_max',null,
        'individually_recommended_weekly_hours',null
      )
    );
  end loop;

  return jsonb_build_object(
    'contract_version','exam_prep_result_led_remaining_work_v1',
    'academic_authority','existing_server_verified_skill_states_and_contracts',
    'P1',v_result->'P1',
    'P5',v_result->'P5',
    'time_estimate_status','academic_activity_durations_not_approved',
    'numeric_recommendation_available',false,
    'recommended_weekly_hours',null,
    'recommendation_accept_enabled',false,
    'unknown_is_not_weak',true,
    'repeated_errors_deduplicated_by_component_skill_phase',true,
    'objective_coverage_is_not_written_method_verification',true,
    'shared_mathematics_budget_double_counted',false,
    'student_may_study_beyond_plan',true,
    'grades_predicted',false,
    'writes_academic_progress',false
  );
end;
$function$;

revoke all on function public.get_exam_prep_remaining_work_by_skill_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_remaining_work_by_skill_safe_v1()
  to authenticated,service_role;

comment on function public.get_exam_prep_remaining_work_by_skill_safe_v1() is
'Owner-only read-only 81-skill P1/P5 remaining actions. Unknown is checked, not assumed weak; repeated wrong responses collapse into one skill correction action; no unapproved personal minutes, no written method score or learning caps.';
