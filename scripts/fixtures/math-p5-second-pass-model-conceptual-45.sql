-- Read-only P5 conceptual choice validity: binomial, geometric and normal model identification.
-- All 45 sources were separately compared with stem, distractors and RU/UZ numbers.
WITH current AS(
 SELECT m.content_key,m.primary_skill_code,q.qtype,q.correct_answer,
 q.question_text_en,q.question_text_ru,q.question_text_uz,
 q.options_text_en::jsonb oe,q.options_text_ru::jsonb oru,q.options_text_uz::jsonb ouz
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve')
 AND m.primary_skill_code IN('P5-BIN-01','P5-GEO-01','P5-NOR-01')
), audit AS(
SELECT *,
CASE WHEN qtype='mcq' THEN
  (correct_answer !~ '^[A-D]$'
  OR jsonb_array_length(oe)<>4 OR jsonb_array_length(oru)<>4 OR jsonb_array_length(ouz)<>4
  OR (SELECT count(DISTINCT v.option) FROM jsonb_array_elements_text(oe) v(option))<>4
  OR (SELECT count(DISTINCT v.option) FROM jsonb_array_elements_text(oru) v(option))<>4
  OR (SELECT count(DISTINCT v.option) FROM jsonb_array_elements_text(ouz) v(option))<>4)
 WHEN qtype='input' THEN (trim(correct_answer)='' OR jsonb_array_length(oe)<>0
    OR jsonb_array_length(oru)<>0 OR jsonb_array_length(ouz)<>0)
 ELSE TRUE END
 OR nullif(trim(question_text_en),'') IS NULL
 OR nullif(trim(question_text_ru),'') IS NULL
 OR nullif(trim(question_text_uz),'') IS NULL AS broken
 FROM current
)
SELECT 'P5_MODEL_IDENTIFICATION_45' audit,count(*) checked,
 count(*) FILTER(WHERE broken) AS structural_issues,
 count(DISTINCT primary_skill_code) AS skills,
 jsonb_agg(content_key ORDER BY content_key) FILTER(WHERE broken) AS problem_keys
FROM audit;
