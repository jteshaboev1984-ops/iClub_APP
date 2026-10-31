-- Read-only P5 Data 03: independent boxplot/quartile source question oracle.
-- Mathematical expressions derived directly from stems, not stored answer keys.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT03-A01',NULL::numeric,'50 is not an outlier' ),
('P5DAT03-A02',NULL::numeric,'B has the higher median and larger IQR' ),
('P5DAT03-A03',(40-(58-40)/1.5)::numeric,NULL::text ),
('P5DAT03-D01',(26)::numeric,NULL::text ),
('P5DAT03-D02',NULL::numeric,'4, 8, 10, 15, 20' ),
('P5DAT03-D03',NULL::numeric,'A has the larger range' ),
('P5DAT03-L01',NULL::numeric,'minimum, Q1, median, Q3, maximum' ),
('P5DAT03-L02',NULL::numeric,'A has higher centre and smaller middle spread' ),
('P5DAT03-L03',(12-1.5*(20-12))::numeric,NULL::text ),
('P5DAT03-M01',NULL::numeric,'Y is more spread out in the middle' ),
('P5DAT03-M02',NULL::numeric,'median 33, IQR 12' ),
('P5DAT03-R01',(22-14)::numeric,NULL::text ),
('P5DAT03-R02',NULL::numeric,'About 50% of values lie between 24 and 35' ),
('P5DAT03-R03',(18+((18-(-3))/1.5))::numeric,NULL::text ),
('P5DAT03-R04',(26+1.5*(26-14))::numeric,NULL::text )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-03'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN s.kind='input' AND s.opt_count<>0 OR s.kind='mcq' AND s.opt_count<>4 THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_03_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
