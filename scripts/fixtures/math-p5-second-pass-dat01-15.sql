-- Read-only P5 Data 01: independent conceptual chart-selection source question oracle.
-- Mathematical expressions derived directly from stems, not stored answer keys.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT01-A01',NULL::numeric,'Cumulative-frequency graph' ),
('P5DAT01-A02',NULL::numeric,'Side-by-side box-and-whisker plots' ),
('P5DAT01-A03',NULL::numeric,'Pie chart' ),
('P5DAT01-D01',NULL::numeric,'Side-by-side box-and-whisker plots' ),
('P5DAT01-D02',NULL::numeric,'Histogram' ),
('P5DAT01-D03',NULL::numeric,'Cumulative-frequency graph' ),
('P5DAT01-L01',NULL::numeric,'Stem-and-leaf diagram' ),
('P5DAT01-L02',NULL::numeric,'Scatter plot' ),
('P5DAT01-L03',NULL::numeric,'Histogram using frequency density' ),
('P5DAT01-M02',NULL::numeric,'Histogram, using frequency density so bar area represents frequency' ),
('P5DAT01-R01',NULL::numeric,'Side-by-side box-and-whisker plots' ),
('P5DAT01-R02',NULL::numeric,'Back-to-back stem-and-leaf diagram' ),
('P5DAT01-R03',NULL::numeric,'Box-and-whisker plots' ),
('P5DAT01-R04',NULL::numeric,'Stem-and-leaf diagram' ),
('P5MIX-M03',NULL::numeric,'Side-by-side box plots using median and quartiles' )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-01'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN s.kind='input' AND s.opt_count<>0 OR s.kind='mcq' AND s.opt_count<>4 THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_01_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
