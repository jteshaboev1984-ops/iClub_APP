-- Mathematics P1/P5 Stage C — read-only current object/routing integrity guard.
-- 2026-11-02 reference: 1,215 objective questions (486 released + 729 withheld)
-- plus 233 distinct currently approved written task keys = 1,448.
-- 101 older written task versions must remain stored, not double-counted.
-- Operational SAFETY: SELECT only; no real user/session/answer values fetched.
-- Never export question contents, correct_answer, holdout item IDs or PII.
-- Run via an explicitly READ-ONLY production SQL connector or against a safe clone.
-- This snapshot count is expected to change only through governed future releases.
-- Subtle but essential: latest written versions are ordered by approved_at/created_at,
-- NOT bigint id, because IDs do not increase chronologically across source batches.

WITH q AS (
 SELECT m.id,m.question_id,cv.component_code,cv.program_version_id,
        m.primary_skill_code,m.reserve_role,m.exposure_state,m.lifecycle_state,
        m.question_snapshot_md5,m.qa_scope_status,m.qa_math_status,
        m.qa_language_status,m.qa_technical_status,
        p.subject_id,p.qtype,p.question_text_en,p.question_text_ru,p.question_text_uz,
        p.options_text_en,p.options_text_ru,p.options_text_uz,p.time_limit_sec
 FROM private.exam_prep_question_content_meta AS m
 JOIN private.exam_prep_content_versions AS cv ON cv.id=m.content_version_id
 LEFT JOIN public.questions AS p ON p.id=m.question_id
 WHERE m.lifecycle_state IN ('published','reserve')
), w_ranked AS (
 SELECT w.*,cv.program_version_id,
        row_number() OVER (
          PARTITION BY w.component_code,w.task_key
          ORDER BY w.approved_at DESC NULLS LAST,w.created_at DESC,w.id DESC
        ) AS rn
 FROM private.exam_prep_written_tasks AS w
 JOIN private.exam_prep_content_versions AS cv ON cv.id=w.content_version_id
 WHERE w.lifecycle_state='published'
), w AS (
 SELECT * FROM w_ranked WHERE rn=1
), checks AS (
 SELECT 'question'::text AS kind,q.component_code AS component,q.id AS object_id,
        array_remove(ARRAY[
          CASE WHEN q.subject_id IS DISTINCT FROM 5 THEN 'q_wrong_subject_or_missing' END,
          CASE WHEN q.component_code NOT IN ('P1','P5') THEN 'q_invalid_component' END,
          CASE WHEN q.qtype NOT IN ('mcq','input') THEN 'q_invalid_type' END,
          CASE WHEN coalesce(btrim(q.question_text_en),'')=''
                 OR coalesce(btrim(q.question_text_ru),'')=''
                 OR coalesce(btrim(q.question_text_uz),'')=''
               THEN 'q_missing_locale_text' END,
          CASE WHEN q.qtype='mcq' AND (
                 coalesce(btrim(q.options_text_en),'')='' OR
                 coalesce(btrim(q.options_text_ru),'')='' OR
                 coalesce(btrim(q.options_text_uz),'')='')
               THEN 'q_missing_mcq_options' END,
          CASE WHEN q.time_limit_sec IS NULL OR q.time_limit_sec<=0
               THEN 'q_bad_time_limit' END,
          CASE WHEN q.qa_scope_status IS DISTINCT FROM 'pass'
                 OR q.qa_math_status IS DISTINCT FROM 'pass'
                 OR q.qa_language_status IS DISTINCT FROM 'pass'
                 OR q.qa_technical_status IS DISTINCT FROM 'pass'
                 OR length(coalesce(q.question_snapshot_md5,''))<>32
               THEN 'q_qa_or_snapshot_failure' END,
          CASE WHEN NOT EXISTS (
                 SELECT 1 FROM private.exam_prep_skill_contracts AS c
                 WHERE c.program_version_id=q.program_version_id
                   AND c.component_code=q.component_code
                   AND c.skill_code=q.primary_skill_code
               ) THEN 'q_skill_not_in_component_contract' END,
          CASE WHEN NOT EXISTS (
                 SELECT 1 FROM private.exam_prep_assessment_items AS ai
                 JOIN private.exam_prep_assessments AS a
                   ON a.id=ai.assessment_id
                 WHERE ai.question_id=q.question_id AND a.status='published'
               ) THEN 'q_not_routed_to_published_assessment' END,
          CASE WHEN EXISTS (
                 SELECT 1 FROM private.exam_prep_assessment_items AS ai
                 JOIN private.exam_prep_assessments AS a
                   ON a.id=ai.assessment_id
                 WHERE ai.question_id=q.question_id
                   AND a.status='published'
                   AND a.component_code IS DISTINCT FROM q.component_code
               ) THEN 'q_cross_component_route' END,
          CASE WHEN q.exposure_state='withheld' AND EXISTS (
                 SELECT 1 FROM private.exam_prep_assessment_items AS ai
                 JOIN private.exam_prep_assessments AS a
                   ON a.id=ai.assessment_id
                 WHERE ai.question_id=q.question_id
                   AND a.status='published' AND a.assessment_type='learning'
               ) THEN 'q_withheld_on_learning_route' END,
          CASE WHEN (
                 q.exposure_state='released'
                 AND (q.lifecycle_state<>'published' OR q.reserve_role<>'learning')
               ) OR (
                 q.exposure_state='withheld'
                 AND (q.lifecycle_state<>'reserve'
                      OR q.reserve_role NOT IN ('diagnostic','mixed','retest'))
               ) THEN 'q_exposure_role_mismatch' END
        ]::text[],NULL) AS failure
 FROM q
 UNION ALL
 SELECT 'written',w.component_code,w.id,
        array_remove(ARRAY[
          CASE WHEN w.component_code NOT IN ('P1','P5') THEN 'w_invalid_component' END,
          CASE WHEN coalesce(btrim(w.prompt_en),'')=''
                 OR coalesce(btrim(w.prompt_ru),'')=''
                 OR coalesce(btrim(w.prompt_uz),'')=''
               THEN 'w_missing_locale_prompt' END,
          CASE WHEN coalesce(btrim(w.self_review_en),'')=''
                 OR coalesce(btrim(w.self_review_ru),'')=''
                 OR coalesce(btrim(w.self_review_uz),'')=''
               THEN 'w_missing_locale_self_review' END,
          CASE WHEN jsonb_typeof(w.rubric_json) IS DISTINCT FROM 'object'
                 OR coalesce(w.task_version,'')=''
               THEN 'w_invalid_rubric_or_version' END,
          CASE WHEN w.qa_math_status IS DISTINCT FROM 'pass'
                 OR w.qa_language_status IS DISTINCT FROM 'pass'
                 OR w.qa_technical_status IS DISTINCT FROM 'pass'
               THEN 'w_quality_fail' END,
          CASE WHEN NOT EXISTS (
                 SELECT 1 FROM private.exam_prep_skill_contracts AS c
                 WHERE c.program_version_id=w.program_version_id
                   AND c.component_code=w.component_code
                   AND c.skill_code=w.primary_skill_code
               ) THEN 'w_skill_not_in_component_contract' END,
          CASE WHEN NOT EXISTS (
                 SELECT 1 FROM private.exam_prep_assessment_items AS ai
                 JOIN private.exam_prep_assessments AS a ON a.id=ai.assessment_id
                 WHERE ai.written_task_id=w.id AND a.status='published'
               ) THEN 'w_latest_not_routed' END,
          CASE WHEN EXISTS (
                 SELECT 1 FROM private.exam_prep_assessment_items AS ai
                 JOIN private.exam_prep_assessments AS a ON a.id=ai.assessment_id
                 WHERE ai.written_task_id=w.id AND a.status='published'
                   AND a.component_code IS DISTINCT FROM w.component_code
               ) THEN 'w_cross_component_route' END
        ]::text[],NULL)
 FROM w
), expanded AS (
 SELECT kind,component,object_id,unnest(failure) AS issue FROM checks
), totals AS (
 SELECT
  (SELECT count(*) FROM q) AS current_questions,
  (SELECT count(*) FROM q WHERE exposure_state='released') AS released_questions,
  (SELECT count(*) FROM q WHERE exposure_state='withheld') AS withheld_questions,
  (SELECT count(*) FROM w) AS current_written_task_keys,
  (SELECT count(*) FROM w_ranked WHERE rn>1) AS historical_written_versions,
  (SELECT count(*) FROM checks) AS checked_once,
  (SELECT count(DISTINCT (kind,object_id)) FROM checks) AS distinct_objects,
  (SELECT count(DISTINCT (component,primary_skill_code))
     FROM (SELECT component_code component,primary_skill_code FROM q
           UNION ALL
           SELECT component_code,primary_skill_code FROM w) AS x
  ) AS covered_component_skills,
  (SELECT jsonb_object_agg(kind||'_'||component,n)
     FROM (SELECT kind,component,count(*) AS n FROM checks GROUP BY kind,component) AS s
  ) AS by_component,
  coalesce((SELECT jsonb_object_agg(issue,n)
              FROM (SELECT issue,count(*) AS n FROM expanded GROUP BY issue) AS bad),
           '{}'::jsonb) AS failed_checks
)
SELECT CASE WHEN checked_once=1448
                  AND distinct_objects=1448
                  AND current_questions=1215
                  AND released_questions=486
                  AND withheld_questions=729
                  AND current_written_task_keys=233
                  AND covered_component_skills=81
                  AND failed_checks='{}'::jsonb
            THEN 'PASS' ELSE 'FAIL' END AS snapshot_verdict,
       current_questions,released_questions,withheld_questions,
       current_written_task_keys,historical_written_versions,
       checked_once,distinct_objects,covered_component_skills,
       by_component,failed_checks
FROM totals;
