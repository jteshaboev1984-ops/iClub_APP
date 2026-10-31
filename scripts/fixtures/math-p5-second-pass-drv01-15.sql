-- Independent read-only P5 discrete random variable 01 oracle; no learner data touched.
-- Math derived separately from question stems; fractions evaluated as rational numbers.
WITH oracle(k, derived, verbal) AS (VALUES
('P5DRV01-A01',(1.0/(1+2+1+2))::numeric,NULL::text),
('P5DRV01-A02',NULL::numeric,'0.20, 0.40, 0.50'),
('P5DRV01-A03',(1-0.20-0.30)::numeric,NULL::text),
('P5DRV01-D01',(1-0.2-0.3)::numeric,NULL::text),
('P5DRV01-D02',((1-0.2)/4.0)::numeric,NULL::text),
('P5DRV01-D03',NULL::numeric,'0.15, 0.25, 0.20, 0.40'),
('P5DRV01-L01',NULL::numeric,'It lies between 0 and 1 inclusive'),
('P5DRV01-L02',(1.0/(1+2+3))::numeric,NULL::text),
('P5DRV01-L03',(2.0/4)::numeric,NULL::text),
('P5DRV01-M01',(0.40+0.10)::numeric,NULL::text),
('P5DRV01-M02',(2)::numeric,NULL::text),
('P5DRV01-R01',(1-0.15-0.25)::numeric,NULL::text),
('P5DRV01-R02',((1-0.10)/4)::numeric,NULL::text),
('P5DRV01-R03',(1-0.10-0.30)::numeric,NULL::text),
('P5DRV01-R04',NULL::numeric,'P(0)=1/3, P(1)=1/2, P(2)=1/6')
), source AS(
 SELECT m.content_key k,q.qtype kind, CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END answer,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DRV-01'
), audit AS(
 SELECT coalesce(o.k,s.k) k,o.derived,o.verbal,s.answer,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN s.kind='mcq' AND s.opt_count<>4 OR s.kind='input' AND s.opt_count<>0 THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.answer
 WHEN s.answer ~ '^[-+]?[0-9]+/[0-9]+$' THEN abs(split_part(s.answer,'/',1)::numeric/split_part(s.answer,'/',2)::numeric-o.derived)>0.0000001
 WHEN s.answer ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.answer::numeric-o.derived)>0.0000001
 ELSE TRUE END mismatch
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DRV_01_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE mismatch) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'saved',answer,'independent',coalesce(derived::text,verbal))) FILTER(WHERE mismatch) details
FROM audit;
