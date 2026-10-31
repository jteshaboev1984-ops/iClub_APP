-- Read-only independent formula and semantic model for P5-DAT-10 published and reserve questions.
-- Each numeric expression is derived from its stem; textual answers have been manually checked.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT10-A01',((15*24+25*30)/40.0)::numeric,NULL::text ),
('P5DAT10-A02',(50+5*2.4)::numeric,NULL::text ),
('P5DAT10-A03',((20*17.5-180)/8.0)::numeric,NULL::text ),
('P5DAT10-D01',((20*12+30*18)/50.0)::numeric,NULL::text ),
('P5DAT10-D02',((10*12+15*18)/25.0)::numeric,NULL::text ),
('P5DAT10-D03',((19-4)/3.0)::numeric,NULL::text ),
('P5DAT10-L01',((10*4+15*6)/25.0)::numeric,NULL::text ),
('P5DAT10-L02',((40*12-15*10)/25.0)::numeric,NULL::text ),
('P5DAT10-L03',(10+12/8.0)::numeric,NULL::text ),
('P5DAT10-M01',(14+10*6+25*3)::numeric,NULL::text ),
('P5DAT10-M02',(2*4.5+6)::numeric,NULL::text ),
('P5DAT10-R01',((5*8+5*12)/10.0)::numeric,NULL::text ),
('P5DAT10-R02',((5*6+4*20)/4.0)::numeric,NULL::text ),
('P5DAT10-R03',(12*7)::numeric,NULL::text ),
('P5DAT10-R04',((8*5+12*9)/20.0)::numeric,NULL::text )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-10'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN (s.kind='input' AND s.opt_count<>0) OR (s.kind='mcq' AND s.opt_count<>4) THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_10_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
