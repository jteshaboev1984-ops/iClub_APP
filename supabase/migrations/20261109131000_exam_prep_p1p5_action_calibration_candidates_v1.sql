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
