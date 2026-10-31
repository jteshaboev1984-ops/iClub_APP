-- Independent factorial/combination/permutation oracle for P5-CNT-02 (15 items).
-- Read-only on current published and reserve content; no learner data accessed.
WITH expected(k,num,verbal) AS(VALUES
('P5CNT02-A01',((factorial(7)/factorial(3)))::numeric,NULL::text),
('P5CNT02-A02',((factorial(8)/factorial(3)))::numeric,NULL::text),
('P5CNT02-A03',((factorial(10)/factorial(7)))::numeric,NULL::text),
('P5CNT02-D01',(factorial(7))::numeric,NULL::text),
('P5CNT02-D02',((factorial(9)/factorial(3)))::numeric,NULL::text),
('P5CNT02-D03',((factorial(9)/factorial(5)))::numeric,NULL::text),
('P5CNT02-L01',(factorial(6))::numeric,NULL::text),
('P5CNT02-L02',((factorial(7)/factorial(3)))::numeric,NULL::text),
('P5CNT02-L03',(factorial(5))::numeric,NULL::text),
('P5CNT02-M01',((factorial(8)/factorial(3)))::numeric,NULL::text),
('P5CNT02-M02',((factorial(8)/factorial(5)))::numeric,NULL::text),
('P5CNT02-R01',(factorial(8))::numeric,NULL::text),
('P5CNT02-R02',((factorial(9)/factorial(6)))::numeric,NULL::text),
('P5CNT02-R03',((factorial(8)/factorial(4)))::numeric,NULL::text),
('P5CNT02-R04',(6)::numeric,NULL::text)
), actual AS(
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE
 q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END AS chosen,
 jsonb_array_length(q.options_text_en::jsonb) AS opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve')
 AND m.primary_skill_code='P5-CNT-02'
), findings AS(
 SELECT coalesce(e.k,a.k) k,e.num,e.verbal,a.chosen,
 CASE WHEN e.k IS NULL OR a.k IS NULL THEN TRUE
 WHEN a.kind='mcq' AND a.opt_count<>4 THEN TRUE
 WHEN a.kind='input' AND a.opt_count<>0 THEN TRUE
 WHEN e.verbal IS NOT NULL THEN e.verbal IS DISTINCT FROM a.chosen
 WHEN a.chosen ~ '^[0-9]+$' THEN a.chosen::numeric IS DISTINCT FROM e.num
 ELSE TRUE END AS bad
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P5_CNT_02_15_ORACLE' audit,count(*) checked,
 count(*) FILTER(WHERE bad) mismatch,
 jsonb_agg(jsonb_build_object('key',k,'saved',chosen,'derived',coalesce(num::text,verbal))) FILTER(WHERE bad) details
FROM findings;
