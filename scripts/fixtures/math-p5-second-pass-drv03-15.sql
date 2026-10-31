-- Independent read-only P5 discrete random variable 03 oracle; no learner data touched.
-- Math derived separately from question stems; fractions evaluated as rational numbers.
WITH oracle(k, derived, verbal) AS (VALUES
('P5DRV03-A01',(19-4^2)::numeric,NULL::text),
('P5DRV03-A02',(sqrt((0^2+4^2)/2.0-((0+4)/2.0)^2))::numeric,NULL::text),
('P5DRV03-A03',(sqrt(8.5-2.5^2))::numeric,NULL::text),
('P5DRV03-D01',((0^2*0.25+1^2*0.5+2^2*0.25)-(0*0.25+1*0.5+2*0.25)^2)::numeric,NULL::text),
('P5DRV03-D02',((0^2*0.5+1^2*0.25+4^2*0.25)-(0*0.5+1*0.25+4*0.25)^2)::numeric,NULL::text),
('P5DRV03-D03',NULL::numeric,'√13/2'),
('P5DRV03-L01',(11-3^2)::numeric,NULL::text),
('P5DRV03-L02',(sqrt(4.0))::numeric,NULL::text),
('P5DRV03-L03',((1^2*0.5+3^2*0.5)-(1*0.5+3*0.5)^2)::numeric,NULL::text),
('P5DRV03-M01',(sqrt((0^2+2^2)/2.0-((0+2)/2.0)^2))::numeric,NULL::text),
('P5DRV03-M02',((0^2*0.25+2^2*0.25+4^2*0.5)-(0*0.25+2*0.25+4*0.5)^2)::numeric,NULL::text),
('P5DRV03-R01',(6-2^2)::numeric,NULL::text),
('P5DRV03-R02',(sqrt(2.25))::numeric,NULL::text),
('P5DRV03-R03',(sqrt(6.25))::numeric,NULL::text),
('P5DRV03-R04',(sqrt(3.25-1.5^2))::numeric,NULL::text)
), source AS(
 SELECT m.content_key k,q.qtype kind, CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END answer,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DRV-03'
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
SELECT 'P5_DRV_03_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE mismatch) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'saved',answer,'independent',coalesce(derived::text,verbal))) FILTER(WHERE mismatch) details
FROM audit;
