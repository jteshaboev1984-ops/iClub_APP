-- Read-only P5 Data 02: independent stem-and-leaf source question oracle.
-- Mathematical expressions derived directly from stems, not stored answer keys.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT02-A01',NULL::numeric,'4.7' ),
('P5DAT02-A02',NULL::numeric,'2 | 1 4 4 9; 3 | 1 6' ),
('P5DAT02-A03',((48.0+52.0)/2)::numeric,NULL::text ),
('P5DAT02-D01',NULL::numeric,'12, 14, 17, 21, 23' ),
('P5DAT02-D02',(6.5)::numeric,NULL::text ),
('P5DAT02-D03',NULL::numeric,'4 | 1 3 3 ; 5 | 0' ),
('P5DAT02-L01',(23)::numeric,NULL::text ),
('P5DAT02-L02',NULL::numeric,'3 | 1 4 4 8; 4 | 2' ),
('P5DAT02-L03',((18.0+20.0)/2)::numeric,NULL::text ),
('P5DAT02-M01',NULL::numeric,'1 4 9' ),
('P5DAT02-M02',NULL::numeric,'The mode is 32 and the median is 36.5.' ),
('P5DAT02-R01',(47)::numeric,NULL::text ),
('P5DAT02-R02',(39-21)::numeric,NULL::text ),
('P5DAT02-R03',(30)::numeric,NULL::text ),
('P5DAT02-R04',(6.7-5.2)::numeric,NULL::text )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-02'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN s.kind='input' AND s.opt_count<>0 OR s.kind='mcq' AND s.opt_count<>4 THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_02_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
