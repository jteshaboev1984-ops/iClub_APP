-- READ ONLY: current source-version-aware Mathematics P1/P5 structural integrity.
-- Compare active snapshots, not a stale static 1,448-row figure; include
-- retired question versions separately to protect historical learner records.
-- No answer text or answer keys leave the database.
WITH q AS (
 SELECT m.*,cv.component_code,q0.qtype,q0.subject_id,
        q0.question_text_en,q0.question_text_ru,q0.question_text_uz,
        q0.correct_answer
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 LEFT JOIN public.questions q0 ON q0.id=m.question_id
 WHERE cv.component_code IN ('P1','P5')
), w AS (
 SELECT wt.*,cv.status version_status
 FROM private.exam_prep_written_tasks wt
 JOIN private.exam_prep_content_versions cv ON cv.id=wt.content_version_id
 WHERE wt.component_code IN ('P1','P5')
), ai AS (
 SELECT i.*,a.component_code,a.status assessment_status
 FROM private.exam_prep_assessment_items i
 JOIN private.exam_prep_assessments a ON a.id=i.assessment_id
 WHERE a.component_code IN ('P1','P5')
), metrics AS (
 SELECT
 (SELECT count(*) FROM q) all_question_versions,
 (SELECT count(*) FROM q WHERE lifecycle_state='retired') retired_question_versions,
 (SELECT count(*) FROM q WHERE lifecycle_state<>'retired') active_question_versions,
 (SELECT count(*) FROM q WHERE lifecycle_state='published' AND reserve_role='learning') released_learning_questions,
 (SELECT count(*) FROM q WHERE lifecycle_state='reserve' AND exposure_state='withheld') protected_reserve_questions,
 (SELECT count(*) FROM w WHERE lifecycle_state='published') active_written_versions,
 (SELECT count(*) FROM w) all_written_versions,
 (SELECT count(DISTINCT component_code||':'||skill_code) FROM private.exam_prep_syllabus_nodes WHERE component_code IN ('P1','P5')) syllabus_skills,
 (SELECT count(*) FROM q WHERE lifecycle_state<>'retired'
   AND (qtype IS NULL OR question_text_en IS NULL OR question_text_ru IS NULL OR question_text_uz IS NULL
   OR nullif(btrim(question_text_en),'') IS NULL OR nullif(btrim(question_text_ru),'') IS NULL OR nullif(btrim(question_text_uz),'') IS NULL
   OR nullif(btrim(coalesce(correct_answer,'')),'') IS NULL)) bad_question_text_or_answer,
 (SELECT count(*) FROM q WHERE lifecycle_state<>'retired'
   AND (qa_scope_status IS DISTINCT FROM 'pass' OR qa_math_status IS DISTINCT FROM 'pass'
   OR qa_language_status IS DISTINCT FROM 'pass' OR qa_technical_status IS DISTINCT FROM 'pass')) bad_question_qa,
 (SELECT count(*) FROM w WHERE lifecycle_state='published'
   AND (qa_math_status IS DISTINCT FROM 'pass' OR qa_language_status IS DISTINCT FROM 'pass'
   OR qa_technical_status IS DISTINCT FROM 'pass'
   OR nullif(btrim(coalesce(prompt_ru,'')),'') IS NULL
   OR nullif(btrim(coalesce(prompt_uz,'')),'') IS NULL
   OR nullif(btrim(coalesce(prompt_en,'')),'') IS NULL)) bad_written_qa_locale,
 (SELECT count(*) FROM q WHERE lifecycle_state<>'retired'
   AND ((reserve_role='learning' AND exposure_state<>'released')
     OR (reserve_role<>'learning' AND exposure_state<>'withheld'))) incorrect_exposure,
 (SELECT count(*) FROM q WHERE lifecycle_state<>'retired'
   AND NOT EXISTS (SELECT 1 FROM private.exam_prep_syllabus_nodes n
     WHERE n.component_code=q.component_code AND n.skill_code=q.primary_skill_code)) missing_question_skill,
 (SELECT count(*) FROM w WHERE lifecycle_state='published'
   AND NOT EXISTS (SELECT 1 FROM private.exam_prep_syllabus_nodes n
     WHERE n.component_code=w.component_code AND n.skill_code=w.primary_skill_code)) missing_written_skill,
 (SELECT count(*) FROM ai i WHERE i.question_id IS NOT NULL
   AND NOT EXISTS(SELECT 1 FROM q WHERE q.question_id=i.question_id)) missing_assessment_question,
 (SELECT count(*) FROM ai i JOIN q ON q.question_id=i.question_id
   WHERE i.component_code<>q.component_code) cross_paper_question,
 (SELECT count(*) FROM ai i JOIN w ON w.id=i.written_task_id
   WHERE i.component_code<>w.component_code) cross_paper_written,
 (SELECT count(*) FROM ai i JOIN q ON q.question_id=i.question_id
   WHERE q.reserve_role<>'learning' AND i.reserve_role='learning') withheld_in_learning,
 (SELECT count(*) FROM ai i JOIN q ON q.question_id=i.question_id
   WHERE i.assessment_status='published' AND q.lifecycle_state='retired') retired_in_published_assessment,
 (SELECT count(*) FROM ai i WHERE (i.question_id IS NULL)=(i.written_task_id IS NULL)) invalid_assessment_item_target,
 (SELECT count(*) FROM ai i WHERE i.question_id IS NOT NULL AND i.reserve_role='learning'
   AND i.is_holdout=true) released_holdout_mismatch,
 (SELECT count(*) FROM private.exam_prep_assessment_items) all_assessment_routes,
 (SELECT count(*) FROM private.exam_prep_synthetic_scenarios WHERE scenario_set_version='p2_67_canonical_v2_0' AND scenario_type='canonical_profile') canonical_models,
 (SELECT count(*) FROM private.exam_prep_synthetic_scenarios WHERE scenario_set_version='p2_67_canonical_v2_0' AND scenario_type='adversarial_variant') adversarial_models
)
SELECT row_to_json(metrics)::text FROM metrics;
