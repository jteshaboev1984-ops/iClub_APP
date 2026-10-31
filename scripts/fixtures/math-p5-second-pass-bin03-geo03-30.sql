-- Read-only independently calculated answer oracle: Binomial moments and Geometric expectation.
-- 30 current questions including 12 published + 18 reserve. No response/student writes.
WITH expected(k,n,verbal) AS (VALUES
('P5BIN03-A01',((1-sqrt(1-4*8.4/40))/2)::numeric,NULL),
('P5BIN03-A02',(14.4/24)::numeric,NULL),
('P5BIN03-A03',(7.5*0.75)::numeric,NULL),
('P5BIN03-D01',(20*0.3*0.7)::numeric,NULL),
('P5BIN03-D02',(1-0.8)::numeric,NULL),
('P5BIN03-D03',(80*0.15*0.85)::numeric,NULL),
('P5BIN03-L01',(10*0.2)::numeric,NULL),
('P5BIN03-L02',(12/0.4)::numeric,NULL),
('P5BIN03-L03',(5/20.0)::numeric,NULL),
('P5BIN03-M01',NULL::numeric,'n=20, p=0.4'),
('P5BIN03-M02',(4.5/0.75)::numeric,NULL),
('P5BIN03-R01',(10*0.2*0.8)::numeric,NULL),
('P5BIN03-R02',(10/25.0)::numeric,NULL),
('P5BIN03-R03',(21/70.0)::numeric,NULL),
('P5BIN03-R04',(32*0.25*0.75)::numeric,NULL),
('P5GEO03-A01',(1/6.25)::numeric,NULL),
('P5GEO03-A02',NULL::numeric,'5 and 2.5'),
('P5GEO03-A03',(3/0.25)::numeric,NULL),
('P5GEO03-D01',(1/0.25)::numeric,NULL),
('P5GEO03-D02',(1/5.0)::numeric,NULL),
('P5GEO03-D03',NULL::numeric,'(0.125,8)'),
('P5GEO03-L01',(1/0.2)::numeric,NULL),
('P5GEO03-L02',(1/8.0)::numeric,NULL),
('P5GEO03-L03',(1/2.5)::numeric,NULL),
('P5GEO03-M01',NULL::numeric,'p=0.4, E(X)=2.5'),
('P5GEO03-M02',(3/15.0)::numeric,NULL),
('P5GEO03-R01',(1/0.5)::numeric,NULL),
('P5GEO03-R02',(1/4.0)::numeric,NULL),
('P5GEO03-R03',(1/4.0)::numeric,NULL),
('P5GEO03-R04',(2/10.0)::numeric,NULL)
), actual AS(
 SELECT m.content_key k,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END chosen,
 q.qtype kind,
 jsonb_array_length(q.options_text_en::jsonb) option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN('published','reserve')
 AND m.primary_skill_code IN('P5-BIN-03','P5-GEO-03')
), checked AS (
 SELECT e.k, a.chosen, e.n, e.verbal,
 CASE WHEN e.k IS NULL OR a.k IS NULL THEN TRUE
 WHEN a.kind='mcq' AND a.option_count<>4 THEN TRUE
 WHEN a.kind='input' AND a.option_count<>0 THEN TRUE
 WHEN e.verbal IS NOT NULL THEN e.verbal IS DISTINCT FROM a.chosen
 WHEN a.chosen ~ '^[-+]?[0-9]+([.][0-9]+)?$'
 THEN abs(a.chosen::numeric-e.n)>0.00000001
 ELSE TRUE END AS incorrect
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P5_BIN03_GEO03_INDEPENDENT_30' AS audit,
 count(*) AS checked,count(*) FILTER (WHERE incorrect) AS mismatches,
 jsonb_agg(jsonb_build_object('key',k,'saved',chosen,'formula',coalesce(n::text,verbal)))
 FILTER(WHERE incorrect) AS details
FROM checked;
