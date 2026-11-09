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
