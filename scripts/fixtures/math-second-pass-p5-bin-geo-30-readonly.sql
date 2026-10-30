-- Read-only: independently re-derived answer oracle for all 30 P5 BIN-02 / GEO-02
-- published and reserve source questions. No academic status changes.
WITH expected AS (
 SELECT * FROM (VALUES
 ('P5BIN02-A01','0.3915'),('P5BIN02-A02','0.2639'),('P5BIN02-A03','32'),
 ('P5BIN02-D01','0.32768'),('P5BIN02-D02','0.8999'),('P5BIN02-D03','0.3110'),
 ('P5BIN02-L01','0.375'),('P5BIN02-L02','0.488'),('P5BIN02-L03','0.420175'),
 ('P5BIN02-M01','0.875'),('P5BIN02-M02','0.7176'),('P5BIN02-R01','0.03125'),
 ('P5BIN02-R02','0.31640625'),('P5BIN02-R03','5/16'),('P5BIN02-R04','0.8131'),
 ('P5GEO02-A01','175/256'),('P5GEO02-A02','7/16'),('P5GEO02-A03','81'),
 ('P5GEO02-D01','0.128'),('P5GEO02-D02','(0.8)^2(0.2)'),('P5GEO02-D03','0.2401'),
 ('P5GEO02-L01','0.2401'),('P5GEO02-L02','0.578125'),('P5GEO02-L03','0.40'),
 ('P5GEO02-M01','0.31232'),('P5GEO02-M02','0.6'),('P5GEO02-R01','0.0625'),
 ('P5GEO02-R02','0.81'),('P5GEO02-R03','7/8'),('P5GEO02-R04','7/16')
 ) t(content_key, expected_keyed_answer)
), actual AS(
 SELECT m.content_key,q.id,q.qtype,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected
 FROM private.exam_prep_question_content_meta m
 JOIN public.questions q ON q.id=m.question_id
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 WHERE cv.component_code='P5'
   AND m.primary_skill_code IN('P5-BIN-02','P5-GEO-02')
   AND m.lifecycle_state IN ('published','reserve')
)
SELECT 'P5_BIN_GEO_30_ORACLES' AS audit, count(*) AS questions,
  count(*) FILTER(WHERE expected.content_key IS NULL OR actual.selected IS DISTINCT FROM expected.expected_keyed_answer) AS wrong_keyed_answers,
  count(*) FILTER(WHERE actual.content_key IS NULL) AS not_found
FROM expected FULL JOIN actual ON actual.content_key=expected.content_key;
