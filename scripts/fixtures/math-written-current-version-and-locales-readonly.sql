-- Current P1/P5 written-source provenance. READ ONLY.
-- Crucial: highest numeric id selects 18 *historical* published versions.
-- For each content-version/key take last approved; do not change session bindings.
WITH current AS (
 SELECT DISTINCT ON(content_version_id,task_key) id,content_version_id,task_key,
   component_code,task_version,approved_at,created_at,rubric_json,
   prompt_en,prompt_ru,prompt_uz,self_review_en,self_review_ru,self_review_uz
 FROM private.exam_prep_written_tasks WHERE lifecycle_state='published'
 ORDER BY content_version_id,task_key,approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC
), by_id AS (
 SELECT DISTINCT ON(content_version_id,task_key) id,content_version_id,task_key
 FROM private.exam_prep_written_tasks WHERE lifecycle_state='published'
 ORDER BY content_version_id,task_key,id DESC
), criteria AS (
 SELECT w.id,count(*) n,count(DISTINCT c.value->>'id') unique_ids,
   sum((c.value->>'marks')::integer) sum_marks,
   count(*) FILTER(WHERE length(btrim(c.value->>'rule'))<5) blank_rules,
   count(*)*2 expected_locale_rows,
   count(*) FILTER(WHERE
     NOT EXISTS (SELECT 1 FROM private.exam_prep_written_criteria_locale_v1 l
       WHERE l.written_task_id=w.id AND l.task_version=w.task_version
         AND l.criterion_id=c.value->>'id' AND l.language='ru'
         AND l.review_state='approved' AND l.source_rule_md5=md5(c.value->>'rule') AND btrim(l.translated_rule)<>'')
     OR NOT EXISTS (SELECT 1 FROM private.exam_prep_written_criteria_locale_v1 l
       WHERE l.written_task_id=w.id AND l.task_version=w.task_version
         AND l.criterion_id=c.value->>'id' AND l.language='uz'
         AND l.review_state='approved' AND l.source_rule_md5=md5(c.value->>'rule') AND btrim(l.translated_rule)<>'')) as missing_criterion_locale
 FROM current w CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
 GROUP BY w.id
), flags AS (
 SELECT w.*,b.id numeric_id,c.n,c.sum_marks,c.unique_ids,c.blank_rules,c.missing_criterion_locale,
 CASE WHEN w.id<>b.id THEN true ELSE false END historical_id_collision,
 CASE WHEN c.sum_marks IS DISTINCT FROM (w.rubric_json->>'max_marks')::int
   OR c.n<>c.unique_ids OR c.blank_rules<>0 OR c.missing_criterion_locale<>0
   OR w.prompt_en IS NULL OR w.prompt_ru IS NULL OR w.prompt_uz IS NULL
   OR w.self_review_en IS NULL OR w.self_review_ru IS NULL OR w.self_review_uz IS NULL
 THEN true ELSE false END content_integrity_fail
 FROM current w JOIN by_id b USING(content_version_id,task_key) JOIN criteria c ON c.id=w.id
)
SELECT component_code,count(*) current_tasks,
 count(*) FILTER(WHERE historical_id_collision) wrong_if_highest_id,
 count(*) FILTER(WHERE content_integrity_fail) current_structure_defects,
 jsonb_agg(jsonb_build_object('task_key',task_key,'old_by_id',numeric_id,'new_by_approval',id))
   FILTER(WHERE historical_id_collision) historical_selection_issues
FROM flags GROUP BY component_code ORDER BY component_code;
