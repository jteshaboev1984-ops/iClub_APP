-- Read-only independent formula and semantic model for P5-DAT-05 published and reserve questions.
-- Each numeric expression is derived from its stem; textual answers have been manually checked.
WITH oracle(k, value, verbal) AS (VALUES
('P5DAT05-A01',(0.75*160)::numeric,NULL::text ),
('P5DAT05-A02',(96-38)::numeric,NULL::text ),
('P5DAT05-A03',(0.35*200)::numeric,NULL::text ),
('P5DAT05-D01',NULL::numeric,'60%' ),
('P5DAT05-D02',NULL::numeric,'Q1' ),
('P5DAT05-D03',(140-47)::numeric,NULL::text ),
('P5DAT05-L01',(0.25*120)::numeric,NULL::text ),
('P5DAT05-L02',(31-18)::numeric,NULL::text ),
('P5DAT05-L03',NULL::numeric,'75% are at most 47' ),
('P5DAT05-M01',(116-44)::numeric,NULL::text ),
('P5DAT05-M02',((110-35)*100.0/160)::numeric,NULL::text ),
('P5DAT05-R01',(64*0.5)::numeric,NULL::text ),
('P5DAT05-R02',(29-12)::numeric,NULL::text ),
('P5DAT05-R03',(117*100.0/180)::numeric,NULL::text ),
('P5DAT05-R04',(45/0.5)::numeric,NULL::text )
), source AS (
 SELECT m.content_key k,q.qtype kind,
 CASE WHEN q.qtype='input' THEN q.correct_answer ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END saved,
 jsonb_array_length(q.options_text_en::jsonb) opt_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P5-DAT-05'
), bad AS (
 SELECT coalesce(o.k,s.k) k,o.value,o.verbal,s.saved,
 CASE WHEN o.k IS NULL OR s.k IS NULL THEN TRUE
 WHEN (s.kind='input' AND s.opt_count<>0) OR (s.kind='mcq' AND s.opt_count<>4) THEN TRUE
 WHEN o.verbal IS NOT NULL THEN o.verbal IS DISTINCT FROM s.saved
 WHEN s.saved ~ '^[-+]?[0-9]+([.][0-9]+)?$' THEN abs(s.saved::numeric-o.value)>0.000001
 ELSE TRUE END wrong
 FROM oracle o FULL JOIN source s USING(k)
)
SELECT 'P5_DAT_05_SECOND_PASS' audit,count(*) checked,count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'actual',saved,'derived',coalesce(value::text,verbal))) FILTER(WHERE wrong) details
FROM bad;
