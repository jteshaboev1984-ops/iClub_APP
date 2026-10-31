-- Read-only independent formula and semantic model for P5-DAT-08 published and reserve questions.
-- Each numeric expression is derived from its stem; textual answers have been manually checked.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT08-A01',NULL::numeric,'B has the higher typical value, but A is more consistent' ),
('P5DAT08-A02',NULL::numeric,'A has the smaller spread' ),
('P5DAT08-A03',(47-42)::numeric,NULL::text ),
('P5DAT08-D01',NULL::numeric,'B has a higher typical score, but A is more consistent' ),
('P5DAT08-D02',NULL::numeric,'Route B usually takes longer but is more consistent in its middle 50%' ),
('P5DAT08-D03',NULL::numeric,'A has the higher median, while B has the smaller range' ),
('P5DAT08-L01',NULL::numeric,'Machine X' ),
('P5DAT08-L02',NULL::numeric,'A has the higher centre; B has the smaller spread' ),
('P5DAT08-L03',NULL::numeric,'A is better centred on target; B is more consistent' ),
('P5DAT08-M01',NULL::numeric,'The datasets have the same central location, but A is less spread out' ),
('P5DAT08-M02',(abs(72-68))::numeric,NULL::text ),
('P5DAT08-R01',NULL::numeric,'P' ),
('P5DAT08-R02',NULL::numeric,'B is typically faster, while A is more consistent' ),
('P5DAT08-R03',(27-19)::numeric,NULL::text ),
('P5DAT08-R04',NULL::numeric,'X is more consistent in its middle 50%' )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-08'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN (s.kind='input' AND s.opt_count<>0) OR (s.kind='mcq' AND s.opt_count<>4) THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_08_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
