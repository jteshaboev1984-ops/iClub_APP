-- Cambridge International Economics 9708 (2026–2028) evidence inventory.
-- AUDIT ONLY. SELECT statements; do not run through migration. Zero production writes.
-- Project mmmduffgpvwjdpruzikw, current deployment baseline SHA ad048f9b008243169a4d4cb7ec8a4a576dc40674.
-- Original iClub 498 internal skill decomposition; not an official Cambridge skill count.

-- 1. Canonical syllabus inventory by unit; approved direct MCQ count.
WITH skills AS (
 SELECT syllabus_unit, level_code, skill_key, syllabus_point
 FROM private.iclub_exam_core_skills_v1
 WHERE program_key='economics_9708'
), approved AS (
 SELECT paper_code, skill_key, legacy_question_id
 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='economics_9708' AND status='approved'
)
SELECT s.level_code,s.syllabus_unit,
 count(DISTINCT s.skill_key) internal_skills,
 count(DISTINCT s.syllabus_point) distinct_official_points,
 count(DISTINCT a.skill_key) approved_primary_skills,
 count(DISTINCT a.legacy_question_id) approved_mcqs
FROM skills s LEFT JOIN approved a ON a.skill_key=s.skill_key
 AND a.paper_code = CASE WHEN s.level_code='AS' THEN 'P1' ELSE 'P3' END
GROUP BY 1,2 ORDER BY 2;

-- 2. Official point presence and canonical-skill presence.
WITH skills AS (
 SELECT level_code, syllabus_point, skill_key
 FROM private.iclub_exam_core_skills_v1
 WHERE program_key='economics_9708'
), approved AS (
 SELECT paper_code, skill_key
 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='economics_9708' AND status='approved'
)
SELECT s.level_code,count(DISTINCT s.syllabus_point) official_points_total,
 count(DISTINCT s.skill_key) canonical_skill_total,
 count(DISTINCT s.syllabus_point) FILTER (WHERE a.skill_key IS NOT NULL) official_points_with_approved_direct_mcq,
 count(DISTINCT s.skill_key) FILTER (WHERE a.skill_key IS NOT NULL) skills_with_approved_direct_mcq
FROM skills s LEFT JOIN approved a ON a.skill_key=s.skill_key
 AND a.paper_code= CASE WHEN s.level_code='AS' THEN 'P1' ELSE 'P3' END
GROUP BY 1;

-- 3. Export-ready 498 canonical skill rows. DO NOT include private answer keys or rubric contents.
SELECT s.level_code,s.syllabus_unit,s.syllabus_point,s.skill_key,s.status skill_review_status,s.tour_no,
t.locales->'en'->>'title' title_en,
t.locales->'ru'->>'title' title_ru,
t.locales->'uz'->>'title' title_uz,
(t.locales ? 'en' AND t.locales ? 'ru' AND t.locales ? 'uz') theory_3_locales_structural,
COALESCE(string_agg(DISTINCT c.legacy_question_id::text,';') FILTER(WHERE c.paper_code='P1' AND c.status='approved'),'') p1_approved_mcq_ids,
COALESCE(string_agg(DISTINCT c.legacy_question_id::text,';') FILTER(WHERE c.paper_code='P3' AND c.status='approved'),'') p3_approved_mcq_ids
FROM private.iclub_exam_core_skills_v1 s
LEFT JOIN private.iclub_subject_library_theory t
 ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key AND t.skill_key=s.skill_key
LEFT JOIN private.iclub_exam_core_question_candidates_v1 c
 ON c.program_key=s.program_key AND c.version_key=s.version_key AND c.skill_key=s.skill_key
WHERE s.program_key='economics_9708'
GROUP BY s.level_code,s.syllabus_unit,s.syllabus_point,s.skill_key,s.status,s.tour_no,t.locales
ORDER BY s.syllabus_unit, (split_part(s.syllabus_point,'.',2))::int,(split_part(s.syllabus_point,'.',3))::int,s.skill_key;

-- 4. Written approved editorial task counts; not an approved direct skill-map.
SELECT paper_code,status,release_enabled,academic_review,language_review,source_review,count(*) n
FROM private.iclub_exam_core_written_tasks_v1
WHERE program_key='economics_9708'
GROUP BY 1,2,3,4,5,6 ORDER BY 1,2,3;

-- 5. Original Practice overlap for approved MCQ primary records; do not mutate either bank.
SELECT c.paper_code,count(*) approved_mcq,
count(*) FILTER(WHERE EXISTS(SELECT 1 FROM public.practice_pool_questions p WHERE p.question_id=c.legacy_question_id)) reused_practice_ids,
count(*) FILTER(WHERE EXISTS(SELECT 1 FROM public.tour_questions t WHERE t.question_id=c.legacy_question_id)) tour_ids,
count(*) FILTER(WHERE q.image_url IS NOT NULL AND trim(q.image_url)<>'') image_attached
FROM private.iclub_exam_core_question_candidates_v1 c
JOIN public.questions q ON q.id=c.legacy_question_id
WHERE c.program_key='economics_9708' AND c.status='approved'
GROUP BY 1 ORDER BY 1;

-- 6. Runtime config is not identical to unrestricted learner access.
SELECT program_key,version_key,status,launch_enabled
FROM private.iclub_exam_core_programs_v1 WHERE program_key='economics_9708';
SELECT paper_code,status,assessment_kind,duration_seconds,total_marks,mcq_count
FROM private.iclub_exam_core_papers_v1 WHERE program_key='economics_9708' ORDER BY paper_no;
SELECT enabled,max_members FROM private.iclub_econ_written_beta_control_v1;

-- 7. Historical written plan state COUNTS ONLY (avoid exposing user IDs).
SELECT w.status,count(DISTINCT w.id) plans,count(wi.id) items,
count(wi.id) FILTER(WHERE wi.status='advanced') advanced,
count(wi.id) FILTER(WHERE wi.status='pending') pending
FROM private.iclub_exam_core_written_plans_v1 w
LEFT JOIN private.iclub_exam_core_written_plan_items_v1 wi ON wi.plan_id=w.id
WHERE w.program_key='economics_9708'
GROUP BY w.status;
