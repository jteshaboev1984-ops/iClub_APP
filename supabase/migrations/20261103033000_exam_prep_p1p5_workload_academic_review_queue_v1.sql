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
