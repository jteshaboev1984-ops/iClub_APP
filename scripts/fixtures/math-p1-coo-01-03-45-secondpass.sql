-- Read-only P1 Coordinate Geometry independent second-pass oracle: 45 current published+reserve sources.
-- Expected results were separately derived from the source stem using slope,
-- midpoint, perpendicular, circle and tangent equations.
WITH expected(k,v) AS (VALUES
 ('P1COO01-A01','y=−3x+1'),
 ('P1COO01-A02','y=2x+5'),
 ('P1COO01-A03','7'),
 ('P1COO01-D01','y = 3x − 7'),
 ('P1COO01-D02','y=5x+7'),
 ('P1COO01-D03','y=3x−11'),
 ('P1COO01-L01','y = 2x + 6'),
 ('P1COO01-L02','y = 2x'),
 ('P1COO01-L03','y = −x + 8'),
 ('P1COO01-M01','x − y + 3 = 0'),
 ('P1COO01-M02','(−2,−1)'),
 ('P1COO01-R01','y = 4x − 3'),
 ('P1COO01-R02','y = 2x + 5'),
 ('P1COO01-R03','12'),
 ('P1COO01-R04','y=−2x+9'),
 ('P1COO02-A01','(−1,6)'),
 ('P1COO02-A02','10'),
 ('P1COO02-A03','3'),
 ('P1COO02-D01','(1, 5)'),
 ('P1COO02-D02','(−2,−2)'),
 ('P1COO02-D03','10'),
 ('P1COO02-L01','5'),
 ('P1COO02-L02','(2,5)'),
 ('P1COO02-L03','−2'),
 ('P1COO02-M01','7'),
 ('P1COO02-M02','5'),
 ('P1COO02-R01','(5,1)'),
 ('P1COO02-R02','10'),
 ('P1COO02-R03','2'),
 ('P1COO02-R04','(5,−3)'),
 ('P1COO03-A01','3/2'),
 ('P1COO03-A02','y=−(3/2)x−5'),
 ('P1COO03-A03','6'),
 ('P1COO03-D01','−2/3'),
 ('P1COO03-D02','5/4'),
 ('P1COO03-D03','y=(2/3)x+5'),
 ('P1COO03-L01','y=−4x−1'),
 ('P1COO03-L02','−2'),
 ('P1COO03-L03','parallel'),
 ('P1COO03-M01','y=−2x+9'),
 ('P1COO03-M02','y=−2x+1'),
 ('P1COO03-R01','−5'),
 ('P1COO03-R02','y=−(1/2)x+1'),
 ('P1COO03-R03','-7'),
 ('P1COO03-R04','y=3x−5')
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
 AND m.primary_skill_code IN('P1-COO-01','P1-COO-02','P1-COO-03')
), compared AS(
 SELECT coalesce(e.k,a.k) k,e.v,a.answer,
 (e.k IS NULL OR a.k IS NULL OR e.v IS DISTINCT FROM a.answer
 OR a.valid_options IS DISTINCT FROM TRUE) bad
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_COO_01_02_03_45_SECOND_PASS' audit,count(*) checked,
count(*) FILTER(WHERE bad) mismatches,
jsonb_agg(jsonb_build_object('key',k,'expected',v,'current',answer)) FILTER(WHERE bad) failures FROM compared;