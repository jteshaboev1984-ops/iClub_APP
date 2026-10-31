-- Read-only independent formula and semantic model for P5-DAT-07 published and reserve questions.
-- Each numeric expression is derived from its stem; textual answers have been manually checked.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT07-A01',(abs(-3)*2.4)::numeric,NULL::text ),
('P5DAT07-A02',(9.0/2)::numeric,NULL::text ),
('P5DAT07-A03',(abs(-2)*14)::numeric,NULL::text ),
('P5DAT07-D01',NULL::numeric,'It is unchanged' ),
('P5DAT07-D02',NULL::numeric,'y=x+7' ),
('P5DAT07-D03',NULL::numeric,'All three are multiplied by 3' ),
('P5DAT07-L01',(26-7)::numeric,NULL::text ),
('P5DAT07-L02',(31-18)::numeric,NULL::text ),
('P5DAT07-L03',(sqrt(((2-3)^2+(2-3)^2+(4-3)^2+(4-3)^2)/4.0))::numeric,NULL::text ),
('P5DAT07-M01',NULL::numeric,'IQR 10, SD 6' ),
('P5DAT07-M02',(10.0/4)::numeric,NULL::text ),
('P5DAT07-R01',(17-9)::numeric,NULL::text ),
('P5DAT07-R02',(4*3)::numeric,NULL::text ),
('P5DAT07-R03',(abs(-2)*(8+3))::numeric,NULL::text ),
('P5DAT07-R04',NULL::numeric,'B has greater spread as measured by standard deviation' )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-07'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN (s.kind='input' AND s.opt_count<>0) OR (s.kind='mcq' AND s.opt_count<>4) THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_07_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
