-- READ ONLY: Cambridge Economics 9708 2026–2028 reserve and written AO checks.
-- No schema writes, no user IDs, no correct answers returned.
-- The CTE eligibility filters mirror public.iclub_exam_native_mcq_start_v1.
WITH quota(paper_code,syllabus_unit,need) AS (
 VALUES ('P1',1,4),('P1',2,12),('P1',3,3),('P1',4,3),('P1',5,3),('P1',6,5),
 ('P3',7,8),('P3',8,7),('P3',9,4),('P3',10,3),('P3',11,8)
), eligible AS (
 SELECT qc.paper_code,sk.syllabus_unit,qc.skill_key,q.id
 FROM private.iclub_exam_core_question_candidates_v1 qc
 JOIN private.iclub_exam_core_skills_v1 sk ON sk.program_key=qc.program_key
  AND sk.version_key=qc.version_key AND sk.skill_key=qc.skill_key
 JOIN private.iclub_exam_core_paper_skills_v1 ps ON ps.program_key=qc.program_key
  AND ps.version_key=qc.version_key AND ps.paper_code=qc.paper_code
  AND ps.skill_key=qc.skill_key AND ps.link_role=qc.link_role
 JOIN private.iclub_exam_core_question_review_v1 qr ON qr.program_key=qc.program_key
  AND qr.version_key=qc.version_key AND qr.legacy_question_id=qc.legacy_question_id
 JOIN public.questions q ON q.id=qc.legacy_question_id
 WHERE qc.program_key='economics_9708' AND qc.version_key='economics_2026_2028_v1'
 AND qc.paper_code IN ('P1','P3') AND qc.status='approved'
 AND qc.qa_scope_status='pass' AND qc.qa_academic_status='pass'
 AND qc.qa_language_status='pass' AND qc.qa_format_status='pass'
 AND sk.status='reviewed' AND ps.status='approved' AND sk.level_code =
  CASE WHEN qc.paper_code='P1' THEN 'AS' ELSE 'A' END
 AND qc.link_role='direct' AND qr.source_snapshot_md5=qc.source_snapshot_md5
 AND q.subject_id=7 AND q.is_active AND q.quality_status='published'
 AND q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$'
 AND jsonb_array_length(q.options_text_en::jsonb)=4
 AND jsonb_array_length(q.options_text_ru::jsonb)=4
 AND jsonb_array_length(q.options_text_uz::jsonb)=4
 AND qc.source_snapshot_md5=md5(jsonb_build_object(
  'topic',q.topic,'subtopic',q.subtopic,'difficulty',q.difficulty,'qtype',q.qtype,
  'q_en',q.question_text_en,'q_ru',q.question_text_ru,'q_uz',q.question_text_uz,
  'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,
  'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,
  'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,
  'image_url',q.image_url,'book_ref',q.book_ref,'quality_status',q.quality_status,
  'is_active',q.is_active)::text)
 AND q.id NOT IN(8751,9044,9732)
)
SELECT qu.paper_code,qu.syllabus_unit,qu.need,
 count(DISTINCT e.skill_key) eligible_unique_skill_count,
 count(DISTINCT e.id) eligible_mcq_count,
 count(DISTINCT e.skill_key)-qu.need reserve_slack,
 CASE WHEN count(DISTINCT e.skill_key)>=qu.need THEN 'PASS' ELSE 'FAIL' END as readiness
FROM quota qu LEFT JOIN eligible e ON e.paper_code=qu.paper_code AND e.syllabus_unit=qu.syllabus_unit
GROUP BY qu.paper_code,qu.syllabus_unit,qu.need ORDER BY 1,2;

-- Original iClub written scheme, for planning only. No written grade is assigned or calculated.
-- Separate AO1 and AO2 cannot be checked from ao12_marks.
SELECT t.paper_code,
 CASE WHEN t.task_key LIKE 'P2.A.%' THEN 'Section A'
      WHEN t.task_key LIKE 'P2.B1.%' THEN 'Section B1'
      WHEN t.task_key LIKE 'P2.B2.%' THEN 'Section B2'
      WHEN t.task_key LIKE 'P2.C1.%' THEN 'Section C1'
      WHEN t.task_key LIKE 'P2.C2.%' THEN 'Section C2'
      WHEN t.task_key LIKE 'P4.A.%' THEN 'Section A'
      WHEN t.task_key='P4.B1' THEN 'Section B1'
      WHEN t.task_key='P4.B2' THEN 'Section B2'
      WHEN t.task_key='P4.C1' THEN 'Section C1'
      WHEN t.task_key='P4.C2' THEN 'Section C2'
      ELSE 'unclassified' END section_or_essay,
 sum(m.max_marks) max_marks_iClub,
 sum(m.ao12_marks) ao1_ao2_joint,
 sum(m.ao3_marks) ao3_marks_iClub
FROM private.iclub_exam_core_written_tasks_v1 t
JOIN private.iclub_exam_written_mark_scheme_v1 m
 ON m.program_key=t.program_key AND m.version_key=t.version_key
 AND m.task_key=t.task_key AND m.task_version=t.task_version
WHERE t.program_key='economics_9708' AND t.status='approved' AND t.release_enabled
GROUP BY 1,2 ORDER BY 1,2;

-- Read-only exposure reuse profile; public question access/assessment state not modified.
SELECT q.topic,count(*) active_published_MCQs,
 count(*) FILTER(WHERE EXISTS(SELECT 1 FROM public.practice_pool_questions pp WHERE pp.question_id=q.id)) in_Practice,
 count(*) FILTER(WHERE EXISTS(SELECT 1 FROM public.tour_questions tq WHERE tq.question_id=q.id)) in_Tours,
 count(*) FILTER(WHERE NOT EXISTS(SELECT 1 FROM public.practice_pool_questions pp WHERE pp.question_id=q.id)
  AND NOT EXISTS(SELECT 1 FROM public.tour_questions tq WHERE tq.question_id=q.id)) unattached_to_both
FROM public.questions q
WHERE q.subject_id=7 AND q.topic IN ('The macroeconomy (AS Level)','The macroeconomy (A Level)')
 AND q.qtype='mcq' AND q.is_active AND q.quality_status='published'
GROUP BY 1 ORDER BY 1;
