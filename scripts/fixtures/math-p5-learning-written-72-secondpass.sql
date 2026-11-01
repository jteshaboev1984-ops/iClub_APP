-- READ-ONLY verified 2026-11-01, 72 latest APPROVED P5 learning written tasks.
-- 36 core W01 and 36 supplemental AW; excludes 31 FP/TB/MM separately reviewed.
-- One independently derived mathematical endpoint / conceptual rule per task,
-- checked together with all current marking criteria by human-readable inspection.
-- No learner response, session, grading authority, or source row is modified.
WITH expected(task_key, result_fragment) AS (VALUES
 ('P5BIN01-AW14','B(15,0.04)'),
 ('P5BIN01-W01','n=12,p=1/6'),
 ('P5BIN02-AW18','P(X=10)=0.75^10'),
 ('P5BIN02-W01','C(8,2)(0.25)^2(0.75)^6'),
 ('P5BIN03-AW18','p=0.3'),
 ('P5BIN03-W01','n=30'),
 ('P5CNT01-AW06','9P2=72'),
 ('P5CNT01-W01','504'),
 ('P5CNT02-AW06','840'),
 ('P5CNT02-W01','5040'),
 ('P5CNT03-AW06','1260'),
 ('P5CNT03-W01','50400'),
 ('P5CNT04-AW06','2×5!×2=480'),
 ('P5CNT04-W01','720−240=480'),
 ('P5CNT05-AW10','840 outcomes'),
 ('P5CNT05-W01','840'),
 ('P5DAT01-AW02','side-by-side box-and-whisker plots'),
 ('P5DAT01-W01','side-by-side box plots'),
 ('P5DAT02-AW02','range 4.2-2.3=1.9'),
 ('P5DAT02-W01','Median=(20+22)/2=21'),
 ('P5DAT03-AW10','upper fence 48'),
 ('P5DAT03-W01','upper fence=31+1.5×14=52'),
 ('P5DAT04-AW02','densities 2,3,2'),
 ('P5DAT04-W01','densities 2,3,4'),
 ('P5DAT05-AW10','78.75%'),
 ('P5DAT05-W01','77.5%'),
 ('P5DAT06-AW02','28/12=7/3'),
 ('P5DAT06-W01','Mean = 10'),
 ('P5DAT07-AW10','7.8'),
 ('P5DAT07-W01','3×12−7 = 29'),
 ('P5DAT08-AW22','A as more consistent'),
 ('P5DAT08-W01','median 72>68'),
 ('P5DAT09-AW22','264/6−36=8'),
 ('P5DAT09-W01','62/8-2.5^2=1.5'),
 ('P5DAT10-AW22','1530/30=51'),
 ('P5DAT10-W01','53800/20-51.5^2=37.75'),
 ('P5DRV01-AW14','k=0.20'),
 ('P5DRV01-W01','P(X≥2)=0.7'),
 ('P5DRV02-AW14','1.40'),
 ('P5DRV02-W01','2.5'),
 ('P5DRV03-AW14','√2'),
 ('P5DRV03-W01','sqrt(2)'),
 ('P5GEO01-AW14','p=0.3'),
 ('P5GEO01-W01','p=1/6'),
 ('P5GEO02-AW18','0.65^3(0.35)'),
 ('P5GEO02-W01','0.4599'),
 ('P5GEO03-AW18','p=0.25'),
 ('P5GEO03-W01','0.1024'),
 ('P5NOR01-AW18','496 and 504'),
 ('P5NOR01-W01','standard deviations 4 and 6'),
 ('P5NOR02-AW22','0.8185'),
 ('P5NOR02-W01','0.6827'),
 ('P5NOR03-AW22','0.8186'),
 ('P5NOR03-W01','0.7745'),
 ('P5NOR04-AW22','66.4'),
 ('P5NOR04-W01','[66.2,73.8]'),
 ('P5NOR05-AW22','μ=56'),
 ('P5NOR05-W01','mu approximately 70.0'),
 ('P5NOR06-AW22','0.9189'),
 ('P5NOR06-W01','0.7742'),
 ('P5PRO01-AW06','4/6=2/3'),
 ('P5PRO01-W01','E={T2,T4}'),
 ('P5PRO02-AW10','28/55'),
 ('P5PRO02-W01','14/33'),
 ('P5PRO03-AW06','0.84'),
 ('P5PRO03-W01','0.75'),
 ('P5PRO04-AW10','0.6875'),
 ('P5PRO04-W01','0.105'),
 ('P5PRO05-AW14','18/(18+12)=3/5'),
 ('P5PRO05-W01','0.36'),
 ('P5PRO06-AW14','14/45'),
 ('P5PRO06-W01','15/28')
), current AS (
 SELECT DISTINCT ON(content_version_id,task_key)
 id,content_version_id,task_key,component_code,primary_skill_code,task_version,
 approved_at,created_at,rubric_json,prompt_en,prompt_ru,prompt_uz
 FROM private.exam_prep_written_tasks
 WHERE lifecycle_state='published' AND component_code='P5'
   AND task_key ~ '^P5[A-Z]{3}[0-9]{2}-(AW|W)'
 ORDER BY content_version_id,task_key,approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC
), flags AS (
 SELECT coalesce(e.task_key,c.task_key) task_key,c.id,e.result_fragment expected,
 CASE WHEN e.task_key IS NULL OR c.task_key IS NULL THEN 'missing_or_extra'
 WHEN c.rubric_json::text NOT LIKE '%'||e.result_fragment||'%' THEN 'expected_math_not_in_rubric'
 WHEN (SELECT sum((el->>'marks')::integer) FROM jsonb_array_elements(c.rubric_json->'criteria') el)
   <> (c.rubric_json->>'max_marks')::integer THEN 'rubric_sum_mismatch'
 WHEN c.prompt_en IS NULL OR c.prompt_ru IS NULL OR c.prompt_uz IS NULL THEN 'missing_locale'
 ELSE NULL END issue
 FROM expected e FULL JOIN current c ON c.task_key=e.task_key
)
SELECT 'P5_LEARNING_WRITTEN_72_SECOND_PASS' audit,count(*) checked,
 count(*) FILTER(WHERE issue IS NOT NULL) mismatches,
 jsonb_agg(jsonb_build_object('task_key',task_key,'expected',expected,'id',id,'issue',issue))
   FILTER(WHERE issue IS NOT NULL) details
FROM flags;
