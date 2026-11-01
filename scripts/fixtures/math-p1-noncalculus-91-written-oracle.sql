-- Read-only independent answer checkpoints for ALL 91 current P1 written
-- tasks outside DIF/INT (already audited separately). 2026-11-01.
-- Inventories use APPROVED/CREATED time, never highest numeric ID.
-- A rubric fragment check is evidence of expected mathematical endpoints,
-- not automatic certification of English/Russian/Uzbek prose or freehand method.
WITH expected(k,result_fragment) AS (VALUES
 ('P1CIR01-AW06','3pi/4'),
 ('P1CIR01-W01','7pi/6'),
 ('P1CIR02-AW10','14.4'),
 ('P1CIR02-W01','12 cm'),
 ('P1CIR03-AW14','10.85'),
 ('P1CIR03-W01','6.68'),
 ('P1COO01-AW06','3x+2y+1=0'),
 ('P1COO01-W01','3x+4y-7=0'),
 ('P1COO02-AW06','2sqrt(29)'),
 ('P1COO02-W01','4sqrt5'),
 ('P1COO03-AW06','y+1=(3/2)(x-4)'),
 ('P1COO03-W01','y=-x/2'),
 ('P1COO04-AW10','(x−3)²+(y+4)²=36'),
 ('P1COO04-W01','(x−2)²+(y+3)²=25'),
 ('P1COO05-AW22','x²+(x+1)²=25'),
 ('P1COO05-W01','7sqrt(2)'),
 ('P1COO06-AW22','k=±10'),
 ('P1COO06-W01','c=±5sqrt(2)'),
 ('P1FP01-Q01','4±2sqrt(2)'),
 ('P1FP01-Q02','x=1/2'),
 ('P1FP01-Q03','13/2'),
 ('P1FP01-Q04','48-32 sin(3/2)'),
 ('P1FP01-Q05','4pi/3'),
 ('P1FP01-Q06','-100'),
 ('P1FP02-Q01','4±6sqrt(2)'),
 ('P1FP02-Q02','(5/2,-2)'),
 ('P1FP02-Q03','y=25/13'),
 ('P1FP02-Q04','40 cm'),
 ('P1FP02-Q05','3pi/2'),
 ('P1FP02-Q06','least n=9'),
 ('P1FP03-Q01','c>-1'),
 ('P1FP03-Q02','sqrt(5)'),
 ('P1FP03-Q03','area 12'),
 ('P1FP03-Q04','18 sin(2/3)'),
 ('P1FP03-Q05','pi/6, pi/2, 5pi/6'),
 ('P1FP03-Q06','n=25'),
 ('P1FUN01-AW02','(x-2)^2'),
 ('P1FUN01-W01','2x^2+3'),
 ('P1FUN02-AW02','1<=f(x)<=17'),
 ('P1FUN02-W01','2≤f(x)≤11'),
 ('P1FUN03-AW10','x≥−1/3'),
 ('P1FUN03-W01','x≠−1'),
 ('P1FUN04-AW10','(-2−4x)/(x−3)'),
 ('P1FUN04-W01','(3x+1)/(x−2)'),
 ('P1FUN05-AW10','(6,6)'),
 ('P1FUN05-W01','(1,−2)'),
 ('P1FUN06-AW06','(5,3)'),
 ('P1FUN06-W01','(2,7)'),
 ('P1FUN07-AW06','(-2,-5)'),
 ('P1FUN07-W01','y=f(−x)'),
 ('P1FUN08-AW06','(3,-6)'),
 ('P1FUN08-W01','(2,−4)'),
 ('P1MM01-Q01','x=0,-2'),
 ('P1MM01-Q02','12pi-9sqrt(3)'),
 ('P1MM01-Q03','n=5'),
 ('P1QUA01-AW02','3(x-3)^2-7'),
 ('P1QUA01-W01','(x-4)^2-3'),
 ('P1QUA02-AW02','1-2sqrt(6)'),
 ('P1QUA02-W01','c>9'),
 ('P1QUA03-AW02','3±sqrt(13)'),
 ('P1QUA03-W01','x=3/2'),
 ('P1QUA04-AW10','3<x≤5'),
 ('P1QUA04-W01','1≤x≤4'),
 ('P1QUA05-AW10','(1,3) and (3,7)'),
 ('P1QUA05-W01','(0,1) and (3,7)'),
 ('P1QUA06-AW10','1±√2'),
 ('P1QUA06-W01','x=−3,−1,1,3'),
 ('P1SER01-AW14','80−80=0'),
 ('P1SER01-W01','−40'),
 ('P1SER02-AW14','ratio 1/3'),
 ('P1SER02-W01','d=4'),
 ('P1SER03-AW18','1800'),
 ('P1SER03-W01','909'),
 ('P1SER04-AW18','1530'),
 ('P1SER04-W01','3066'),
 ('P1SER05-AW18','tail after four terms as 1/2'),
 ('P1SER05-W01','0.0625'),
 ('P1TB01-Q01','(-4,2) and (4,-2)'),
 ('P1TB01-Q02','5pi/6'),
 ('P1TB02-Q01','2+sqrt(x+3)'),
 ('P1TB02-Q02','34.584'),
 ('P1TRI01-AW06','3pi/4'),
 ('P1TRI01-W01','π/6 and x=5π/6'),
 ('P1TRI02-AW14','sin210°=−1/2'),
 ('P1TRI02-W01','cos240°=−1/2'),
 ('P1TRI03-AW14','−60°'),
 ('P1TRI03-W01','−30°,150°,45°'),
 ('P1TRI04-AW14','sec²x'),
 ('P1TRI04-W01','1/cos²x'),
 ('P1TRI05-AW14','240° and 300°'),
 ('P1TRI05-W01','60°,120°')
), current AS (
 SELECT DISTINCT ON(content_version_id,task_key)
   id,content_version_id,task_key,component_code,primary_skill_code,task_version,
   approved_at,created_at,rubric_json,prompt_en,prompt_ru,prompt_uz
 FROM private.exam_prep_written_tasks
 WHERE lifecycle_state='published' AND component_code='P1'
   AND primary_skill_code NOT LIKE 'P1-DIF-%'
   AND primary_skill_code NOT LIKE 'P1-INT-%'
 ORDER BY content_version_id,task_key,approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC
), scan AS (
 SELECT coalesce(e.k,c.task_key) task_key,e.result_fragment expected,c.id,c.primary_skill_code,
 CASE WHEN e.k IS NULL OR c.task_key IS NULL THEN 'missing_or_extra'
 WHEN c.rubric_json::text NOT LIKE ('%'||e.result_fragment||'%') THEN 'key_result_mismatch'
 WHEN (SELECT sum((z->>'marks')::integer) FROM jsonb_array_elements(c.rubric_json->'criteria') z)
   <> (c.rubric_json->>'max_marks')::integer THEN 'marks_mismatch'
 WHEN c.prompt_en IS NULL OR c.prompt_ru IS NULL OR c.prompt_uz IS NULL THEN 'missing_translation'
 ELSE NULL END issue
 FROM expected e FULL JOIN current c ON e.k=c.task_key
)
SELECT 'P1_NONCALCULUS_91_WRITTEN_SECOND_PASS' audit,count(*) checked,
 count(*) FILTER(WHERE issue IS NOT NULL) mismatches,
 jsonb_agg(jsonb_build_object('key',task_key,'expected',expected,'id',id,'issue',issue))
   FILTER(WHERE issue IS NOT NULL) details
FROM scan;
