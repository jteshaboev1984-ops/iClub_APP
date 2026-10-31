-- Read-only independent formula and semantic model for P5-DAT-06 published and reserve questions.
-- Each numeric expression is derived from its stem; textual answers have been manually checked.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT06-A01',((8+8)/2.0)::numeric,NULL::text ),
('P5DAT06-A02',((2*2.5+4*10+2*20)/8.0)::numeric,NULL::text ),
('P5DAT06-A03',NULL::numeric,'Median' ),
('P5DAT06-D01',((1+2+2+6+9)/5.0)::numeric,NULL::text ),
('P5DAT06-D02',NULL::numeric,'11/6' ),
('P5DAT06-D03',((5+6)/2.0)::numeric,NULL::text ),
('P5DAT06-L01',(7)::numeric,NULL::text ),
('P5DAT06-L02',((5+2*15+25)/4.0)::numeric,NULL::text ),
('P5DAT06-L03',(4)::numeric,NULL::text ),
('P5DAT06-M02',NULL::numeric,'The medians are equal, but B has the larger mean because of the high value 32.' ),
('P5DAT06-R01',((6+8+8+9+14)/5.0)::numeric,NULL::text ),
('P5DAT06-R02',((2*2+4*6+2*10)/8.0)::numeric,NULL::text ),
('P5DAT06-R03',((22-21)/(7.0-6))::numeric,NULL::text ),
('P5DAT06-R04',NULL::numeric,'The mean increases by 2, while the median and mode are unchanged.' ),
('P5MIX-M02',NULL::numeric,'Mean 6; side-by-side box plots' )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-06'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN (s.kind='input' AND s.opt_count<>0) OR (s.kind='mcq' AND s.opt_count<>4) THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_06_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
