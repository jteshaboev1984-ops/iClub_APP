-- 39 P1 calculus written tasks: independently derived value checkpoints,
-- complete rubric arithmetic + locale structural checks. Read-only.
-- These are the 22 current DIF and 17 current INT tasks including mixed/final-paper cases.
WITH expected(k,independent_result_fragment) AS (VALUES
 ('P1DIF01-AW14','gradient 8'),
 ('P1DIF01-W01','hence 8'),
 ('P1DIF02-AW18','89/8'),
 ('P1DIF02-W01','383/8'),
 ('P1DIF03-AW18','240 at x=1'),
 ('P1DIF03-W01','f′(1)=48'),
 ('P1DIF04-AW18','y=9x−14'),
 ('P1DIF04-W01','54'),
 ('P1DIF05-AW22','3(x−1)(x−3)'),
 ('P1DIF05-W01','3(x−3)(x+1)'),
 ('P1DIF06-AW22','20π'),
 ('P1DIF06-W01','40pi'),
 ('P1DIF07-AW22','144'),
 ('P1DIF07-W01','100'),
 ('P1FP01-Q07','(-1,10)'),
 ('P1FP01-Q08','2/3'),
 ('P1FP01-Q09','32/3'),
 ('P1FP01-Q10','512/15'),
 ('P1FP02-Q07','45/11'),
 ('P1FP02-Q08','(1,6)'),
 ('P1FP02-Q09','1/16'),
 ('P1FP02-Q10','a=25'),
 ('P1FP03-Q07','(1,8)'),
 ('P1FP03-Q08','maximum area 32'),
 ('P1FP03-Q09','62/27'),
 ('P1FP03-Q10','145/27'),
 ('P1INT01-AW22','2(3x+1)³/9'),
 ('P1INT01-W01','(2x−1)^3/2'),
 ('P1INT02-AW22','y(2)=15'),
 ('P1INT02-W01','y(3)=21'),
 ('P1INT03-AW22','Gets 4.'),
 ('P1INT03-W01','Gets 15.'),
 ('P1INT04-AW22','46/3'),
 ('P1INT04-W01','total area 4'),
 ('P1INT05-AW22','36π'),
 ('P1INT05-W01','16pi/15'),
 ('P1MM01-Q04','24pi'),
 ('P1TB01-Q03','(1,4)'),
 ('P1TB02-Q03','16pi/15')
), current AS (
 SELECT DISTINCT ON(component_code,task_key) id,component_code,task_key,
 primary_skill_code,prompt_en,prompt_ru,prompt_uz,rubric_json,
 self_review_en,self_review_ru,self_review_uz
 FROM private.exam_prep_written_tasks
 WHERE lifecycle_state='published' ORDER BY component_code,task_key,id DESC
), compared AS (
 SELECT coalesce(e.k,c.task_key) k,c.id,c.primary_skill_code,
 CASE WHEN e.k IS NULL OR c.task_key IS NULL THEN 'missing_or_extra'
 WHEN NOT (c.rubric_json::text LIKE '%'||e.independent_result_fragment||'%') THEN 'independent_solution_not_in_rubric'
 WHEN (SELECT coalesce(sum((el->>'marks')::integer),0)
 FROM jsonb_array_elements(c.rubric_json->'criteria') el)<>
 (c.rubric_json->>'max_marks')::integer THEN 'rubric_marks_do_not_sum'
 WHEN c.prompt_en IS NULL OR c.prompt_ru IS NULL OR c.prompt_uz IS NULL
 OR c.self_review_en IS NULL OR c.self_review_ru IS NULL OR c.self_review_uz IS NULL THEN 'missing_locale'
 ELSE NULL END issue,e.independent_result_fragment expected_result
 FROM expected e FULL JOIN (SELECT * FROM current WHERE primary_skill_code LIKE 'P1-DIF-%' OR primary_skill_code LIKE 'P1-INT-%') c ON e.k=c.task_key
)
SELECT 'P1_CALCULUS_WRITTEN_39_SECOND_PASS' audit,count(*) checked,
 count(*) FILTER(WHERE issue IS NOT NULL) mismatches,
 jsonb_agg(jsonb_build_object('task_key',k,'problem',issue,'expected',expected_result)) FILTER(WHERE issue IS NOT NULL) details FROM compared;
