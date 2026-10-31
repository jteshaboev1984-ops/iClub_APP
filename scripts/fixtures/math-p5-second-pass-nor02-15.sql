-- Read-only 15 normal standardisation / CDF independently derived z-scores.
-- Z=(X-mu)/sqrt(variance). Standard-normal CDF constants evaluated without stored keys.
WITH expected(k,n) AS (VALUES
('P5NOR02-A01',(58-50)/sqrt(16::numeric)),
('P5NOR02-A02',(90-100)/sqrt(25::numeric)),
('P5NOR02-A03',(36-30)/sqrt(9::numeric)),
('P5NOR02-D01',(58-50)/sqrt(16::numeric)),
('P5NOR02-D02',(68-60)/sqrt(16::numeric)),
('P5NOR02-D03',(20-30)/sqrt(25::numeric)),
('P5NOR02-L01',(90-100)/sqrt(25::numeric)),
('P5NOR02-L02',round(0.841344746::numeric,4)),
('P5NOR02-L03',round((1-0.933192798)::numeric,4)),
('P5NOR02-M01',round((1-0.841344746)::numeric,4)),
('P5NOR02-M02',(66-80)/sqrt(49::numeric)),
('P5NOR02-R01',(23-20)/sqrt(9::numeric)),
('P5NOR02-R02',round(0.3085375387::numeric,4)),
('P5NOR02-R03',(112-100)/sqrt(36::numeric)),
('P5NOR02-R04',(44-50)/sqrt(9::numeric))
),actual AS (
SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) options_count
FROM private.exam_prep_question_content_meta m
JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
JOIN public.questions q ON q.id=m.question_id
WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve')
AND m.primary_skill_code='P5-NOR-02'
),audit AS (
SELECT e.k,e.n,a.saved,
CASE WHEN e.k IS NULL OR a.k IS NULL THEN TRUE
 WHEN a.kind='mcq' AND a.options_count<>4 THEN TRUE
 WHEN a.kind='input' AND a.options_count<>0 THEN TRUE
 WHEN replace(a.saved,'−','-') ~ '^[-+]?[0-9]+([.][0-9]+)?$'
 THEN abs(replace(a.saved,'−','-')::numeric-e.n)>0.000001
 ELSE TRUE END bad
FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P5_NOR02_STANDARDISE_15' audit,count(*) checked,
 count(*) FILTER(WHERE bad) AS mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'formula',n))
 FILTER(WHERE bad) AS problems FROM audit;
