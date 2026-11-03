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
