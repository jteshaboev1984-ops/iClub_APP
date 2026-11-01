-- Read-only, independently derived rubric checkpoints for 31 CURRENT P5 written
-- full-paper, timed-block, mini-mock tasks. Pinned 2026-11-01.
-- Each result was derived from the English prompt before live key comparison.
-- Does NOT independently certify translation prose or freehand diagrams.
WITH expected(task_key, expected_result_fragment) AS (VALUES
 ('P5FP01-Q01','11.76'),
 ('P5FP01-Q02','2520'),
 ('P5FP01-Q03','2/9'),
 ('P5FP01-Q04','Var(X)=5-2^2=1'),
 ('P5FP01-Q05','0.915'),
 ('P5FP01-Q06','0.4096'),
 ('P5FP01-Q07','0.8465'),
 ('P5FP02-Q01','68.64'),
 ('P5FP02-Q02','900'),
 ('P5FP02-Q03','13/18'),
 ('P5FP02-Q04','0.96'),
 ('P5FP02-Q05','E(Y)=40'),
 ('P5FP02-Q06','0.3845'),
 ('P5FP02-Q07','0.4783'),
 ('P5FP03-Q01','207.76'),
 ('P5FP03-Q02','3000'),
 ('P5FP03-Q03','2/9'),
 ('P5FP03-Q04','0.3412'),
 ('P5FP03-Q05','0.377856'),
 ('P5FP03-Q06','80.3'),
 ('P5FP03-Q07','0.870'),
 ('P5TB01-Q01','0.917'),
 ('P5TB01-Q02','37/256'),
 ('P5TB01-Q03','0.8186'),
 ('P5TB02-Q01','444'),
 ('P5TB02-Q02','2/3'),
 ('P5TB02-Q03','Var(X)=5-2^2=1'),
 ('P5MM01-Q01','15.6'),
 ('P5MM01-Q02','0.5'),
 ('P5MM01-Q03','81/1024'),
 ('P5MM01-Q04','0.7788')
), current AS (
  SELECT DISTINCT ON (content_version_id,task_key) id,content_version_id,component_code,task_key,
    task_version,approved_at,created_at,rubric_json,prompt_en,prompt_ru,prompt_uz
  FROM private.exam_prep_written_tasks
  WHERE lifecycle_state='published' AND component_code='P5'
    AND (task_key LIKE 'P5FP0%-Q%' OR task_key LIKE 'P5TB0%-Q%' OR task_key LIKE 'P5MM0%-Q%')
  ORDER BY content_version_id,task_key,approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC
), compared AS (
  SELECT coalesce(e.task_key,w.task_key) task_key,e.expected_result_fragment expected,w.id,
    CASE WHEN e.task_key IS NULL OR w.task_key IS NULL THEN 'missing_or_extra'
    WHEN w.rubric_json::text NOT LIKE ('%'||e.expected_result_fragment||'%') THEN 'wrong_or_missing_math'
    WHEN (SELECT sum((v->>'marks')::int) FROM jsonb_array_elements(w.rubric_json->'criteria') v)
      IS DISTINCT FROM (w.rubric_json->>'max_marks')::int THEN 'bad_max_marks'
    WHEN w.prompt_en IS NULL OR w.prompt_ru IS NULL OR w.prompt_uz IS NULL THEN 'missing_translation'
    ELSE NULL END issue
  FROM expected e FULL JOIN current w ON e.task_key=w.task_key
)
SELECT 'P5_31_MIXED_WRITTEN_SECOND_PASS' audit,count(*) checked,
  count(*) FILTER(WHERE issue IS NOT NULL) mismatches,
  jsonb_agg(jsonb_build_object('key',task_key,'expected',expected,'id',id,'issue',issue))
    FILTER(WHERE issue IS NOT NULL) details
FROM compared;
