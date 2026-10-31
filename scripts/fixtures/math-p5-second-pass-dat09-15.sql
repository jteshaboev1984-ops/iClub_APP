-- Read-only independent formula and semantic model for P5-DAT-09 published and reserve questions.
-- Each numeric expression is derived from its stem; textual answers have been manually checked.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT09-A01',NULL::numeric,'mean 9, standard deviation 2' ),
('P5DAT09-A02',((1*2+2*3+3*5)/10.0)::numeric,NULL::text ),
('P5DAT09-A03',(96.0/8)::numeric,NULL::text ),
('P5DAT09-D01',NULL::numeric,'mean 8, standard deviation sqrt(6)' ),
('P5DAT09-D02',(sqrt(290.0/5-(35.0/5)^2))::numeric,NULL::text ),
('P5DAT09-D03',((3+5+7+9+11)/5.0)::numeric,NULL::text ),
('P5DAT09-L01',NULL::numeric,'mean 5, standard deviation sqrt(5)' ),
('P5DAT09-L02',(sqrt(290.0/10-(50.0/10)^2))::numeric,NULL::text ),
('P5DAT09-L03',NULL::numeric,'mean 11/6, standard deviation sqrt(17)/6' ),
('P5DAT09-M01',(174.0/6-(30.0/6)^2)::numeric,NULL::text ),
('P5DAT09-M02',((2^2+2^2+4^2+8^2)/4.0-((2+2+4+8)/4.0)^2)::numeric,NULL::text ),
('P5DAT09-R01',NULL::numeric,'mean 5, standard deviation sqrt(5)' ),
('P5DAT09-R02',(sqrt(((1-2)^2+(1-2)^2+(3-2)^2+(3-2)^2)/4.0))::numeric,NULL::text ),
('P5DAT09-R03',(104.0/8)::numeric,NULL::text ),
('P5DAT09-R04',(sqrt(136.0/4-(20.0/4)^2))::numeric,NULL::text )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-09'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN (s.kind='input' AND s.opt_count<>0) OR (s.kind='mcq' AND s.opt_count<>4) THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_09_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
