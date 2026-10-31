-- Read-only independent source-level P5 probability oracle (combinations and trees).
-- P5-PRO-02 and P5-PRO-06, 30 items; all published plus reserve.
WITH oracle(content_key,expected_answer) AS (VALUES
('P5PRO02-A01','14/99'),('P5PRO02-A02','41/55'),('P5PRO02-A03','7'),
('P5PRO02-D01','5/14'),('P5PRO02-D02','9/44'),('P5PRO02-D03','1/2'),
('P5PRO02-L01','3/10'),('P5PRO02-L02','3/10'),('P5PRO02-L03','2/15'),
('P5PRO02-M01','37/42'),('P5PRO02-M02','0.3'),
('P5PRO02-R01','5/33'),('P5PRO02-R02','1/3'),('P5PRO02-R03','21'),('P5PRO02-R04','3/10'),
('P5PRO06-A01','15/56'),('P5PRO06-A02','0.40'),('P5PRO06-A03','8'),
('P5PRO06-D01','2/7'),('P5PRO06-D02','5/9'),('P5PRO06-D03','0.032'),
('P5PRO06-L01','0.36'),('P5PRO06-L02','0.52'),('P5PRO06-L03','5/14'),
('P5PRO06-M01','3/5'),('P5PRO06-M02','3'),
('P5PRO06-R01','1/12'),('P5PRO06-R02','3/10'),('P5PRO06-R03','2'),('P5PRO06-R04','1/6')
), current_answers AS (
 SELECT m.content_key,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END AS selected
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN ('published','reserve')
 AND m.primary_skill_code IN ('P5-PRO-02','P5-PRO-06')
)
SELECT 'P5_PROBABILITY_30' audit,count(*) questions,
 count(*) FILTER(WHERE oracle.content_key IS NULL OR current_answers.content_key IS NULL
 OR oracle.expected_answer IS DISTINCT FROM current_answers.selected) AS failures
FROM oracle FULL JOIN current_answers USING (content_key);
