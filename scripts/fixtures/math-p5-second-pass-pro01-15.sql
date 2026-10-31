-- Read-only independent outcome-space cardinalities from products of trial outcomes.
WITH expected(k,n,verbal) AS (VALUES
('P5PRO01-A01',(2*4)::numeric,NULL),
('P5PRO01-A02',(6*6*2)::numeric,NULL),
('P5PRO01-A03',(3*5)::numeric,NULL),
('P5PRO01-D01',NULL::numeric,'{HH,HT,TH,TT}'),
('P5PRO01-D02',(2*2*4)::numeric,NULL),
('P5PRO01-D03',(4*6)::numeric,NULL),
('P5PRO01-L01',(6*2)::numeric,NULL),
('P5PRO01-L02',(6*6)::numeric,NULL),
('P5PRO01-L03',(3*2)::numeric,NULL),
('P5PRO01-M01',(2*2*6)::numeric,NULL),
('P5PRO01-M02',(4*5*2)::numeric,NULL),
('P5PRO01-R01',(2*2*2)::numeric,NULL),
('P5PRO01-R02',(6*6)::numeric,NULL),
('P5PRO01-R03',(14/2)::numeric,NULL),
('P5PRO01-R04',(2*6*3)::numeric,NULL)
), actual AS (
SELECT m.content_key k,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END chosen,
 q.qtype kind,jsonb_array_length(q.options_text_en::jsonb) optcount
FROM private.exam_prep_question_content_meta m
JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
JOIN public.questions q ON q.id=m.question_id
WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve')
AND m.primary_skill_code='P5-PRO-01'
), diffs AS(
 SELECT e.k,a.chosen,e.n,e.verbal, CASE
 WHEN e.k IS NULL OR a.k IS NULL THEN TRUE
 WHEN a.kind='mcq' AND a.optcount<>4 THEN TRUE
 WHEN a.kind='input' AND a.optcount<>0 THEN TRUE
 WHEN e.verbal IS NOT NULL THEN a.chosen IS DISTINCT FROM e.verbal
 WHEN a.chosen ~ '^[0-9]+$' THEN a.chosen::numeric<>e.n
 ELSE TRUE END bad
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P5_PRO01_OUTCOME_SPACE_15' audit,count(*) checked,
 count(*) FILTER(WHERE bad) AS mismatches,
 jsonb_agg(jsonb_build_object('key',k,'saved',chosen,'expected',coalesce(n::text,verbal)))
 FILTER (WHERE bad) AS failures
FROM diffs;
