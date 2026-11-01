-- Read-only P1 Coordinate Geometry independent second-pass oracle: 45 current published+reserve sources.
-- Expected results were separately derived from the source stem using slope,
-- midpoint, perpendicular, circle and tangent equations.
WITH expected(k,v) AS (VALUES
 ('P1COO04-A01','centre (−3,4), radius 6'),
 ('P1COO04-A02','(x−2)²+(y−4)²=13'),
 ('P1COO04-A03','4'),
 ('P1COO04-D01','centre (3, −2), radius 5'),
 ('P1COO04-D02','−8'),
 ('P1COO04-D03','(2,3)'),
 ('P1COO04-L01','(x−2)²+(y+1)²=9'),
 ('P1COO04-L02','centre (−4,1), radius 5'),
 ('P1COO04-L03','Yes, because 3²+4²=25'),
 ('P1COO04-M01','(x−1)²+(y+2)²=25'),
 ('P1COO04-M02','(x−4)²+y²=13'),
 ('P1COO04-R01','centre (1,3), radius 4'),
 ('P1COO04-R02','(x+2)²+(y−5)²=36'),
 ('P1COO04-R03','4'),
 ('P1COO04-R04','−3'),
 ('P1COO05-A01','−1'),
 ('P1COO05-A02','8'),
 ('P1COO05-A03','10'),
 ('P1COO05-D01','(−3,−1) and (7,−1)'),
 ('P1COO05-D02','It intersects the circle at two points'),
 ('P1COO05-D03','5x²−4x−24=0'),
 ('P1COO05-L01','±4'),
 ('P1COO05-L02','6'),
 ('P1COO05-L03','(3,3) and (−3,−3)'),
 ('P1COO05-M01','6'),
 ('P1COO05-M02','2'),
 ('P1COO05-R01','±3'),
 ('P1COO05-R02','±3'),
 ('P1COO05-R03','4'),
 ('P1COO05-R04','2 and −3'),
 ('P1COO06-A01','2√5'),
 ('P1COO06-A02','80'),
 ('P1COO06-A03','5'),
 ('P1COO06-D01','k=±5'),
 ('P1COO06-D02','y=5 and y=−5'),
 ('P1COO06-D03','c=4 or c=−4'),
 ('P1COO06-L01','c=±2sqrt(5)'),
 ('P1COO06-L02','−1 or 5'),
 ('P1COO06-L03','The line is tangent to the circle'),
 ('P1COO06-M01','k=±5'),
 ('P1COO06-M02','4'),
 ('P1COO06-R01','±2'),
 ('P1COO06-R02','±2'),
 ('P1COO06-R03','2'),
 ('P1COO06-R04','100')
),actual AS (
 SELECT m.content_key k,q.qtype,q.correct_answer key,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 WHEN q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$' THEN
 q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END answer,
 CASE WHEN q.qtype='mcq' THEN jsonb_array_length(q.options_text_en::jsonb)=4
 WHEN q.qtype='input' THEN q.options_text_en::jsonb='[]'::jsonb ELSE FALSE END valid_options
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P1' AND m.lifecycle_state IN('published','reserve')
 AND m.primary_skill_code IN('P1-COO-04','P1-COO-05','P1-COO-06')
), compared AS(
 SELECT coalesce(e.k,a.k) k,e.v,a.answer,
 (e.k IS NULL OR a.k IS NULL OR e.v IS DISTINCT FROM a.answer
 OR a.valid_options IS DISTINCT FROM TRUE) bad
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_COO_04_05_06_45_SECOND_PASS' audit,count(*) checked,
count(*) FILTER(WHERE bad) mismatches,
jsonb_agg(jsonb_build_object('key',k,'expected',v,'current',answer)) FILTER(WHERE bad) failures FROM compared;