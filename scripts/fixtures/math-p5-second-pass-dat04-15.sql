-- Read-only P5 Data 04: independent histogram-density source question oracle.
-- Mathematical expressions derived directly from stems, not stored answer keys.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT04-A01',(45.0/6)::numeric,NULL::text ),
('P5DAT04-A02',(2.4*5)::numeric,NULL::text ),
('P5DAT04-A03',NULL::numeric,'The first bar is 4/3 times the height of the second' ),
('P5DAT04-D01',(40.0/(30-20))::numeric,NULL::text ),
('P5DAT04-D02',(30.0/5)::numeric,NULL::text ),
('P5DAT04-D03',NULL::numeric,'The two classes have equal frequencies.' ),
('P5DAT04-L01',(30.0/(10-5))::numeric,NULL::text ),
('P5DAT04-L02',(4*7)::numeric,NULL::text ),
('P5DAT04-L03',NULL::numeric,'The bars have equal height' ),
('P5DAT04-M02',(4*3+6*2.5)::numeric,NULL::text ),
('P5DAT04-R01',(32.0/8)::numeric,NULL::text ),
('P5DAT04-R02',(5*6)::numeric,NULL::text ),
('P5DAT04-R03',((12.0/4)/(18.0/6))::numeric,NULL::text ),
('P5DAT04-R04',NULL::numeric,'The two classes have equal frequencies.' ),
('P5MIX-M01',NULL::numeric,'Histogram; height 4' )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-04'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN s.kind='input' AND s.opt_count<>0 OR s.kind='mcq' AND s.opt_count<>4 THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_04_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
