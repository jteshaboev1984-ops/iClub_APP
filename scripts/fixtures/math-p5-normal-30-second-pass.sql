-- Read-only second pass P5 mathematics: expected answers computed independently from questions.
-- Each key belongs to P5-NOR-03 or P5-NOR-06.
-- Stages published and reserve. No user or source mutations.
WITH oracle (content_key, expected_answer) AS (VALUES
('P5NOR03-A01','0.8413'),('P5NOR03-A02','0.0668'),('P5NOR03-A03','0.6827'),
('P5NOR03-D01','0.8413'),('P5NOR03-D02','0.0668'),('P5NOR03-D03','0.5762'),
('P5NOR03-L01','0.1587'),('P5NOR03-L02','0.6827'),('P5NOR03-L03','0.0668'),
('P5NOR03-M01','0.8186'),('P5NOR03-M02','0.95'),
('P5NOR03-R01','0.1587'),('P5NOR03-R02','0.5328'),('P5NOR03-R03','0.1357'),('P5NOR03-R04','0.5987'),
('P5NOR06-A01','Y~N(80,48) and use P(Y<90.5)'),('P5NOR06-A02','Y>34.5 for Y~N(30,21)'),
('P5NOR06-A03','12.5'),('P5NOR06-D01','Y~N(40,24) and use P(Y<45.5)'),
('P5NOR06-D02','Y~N(50,25) and use P(Y<55.5)'),
('P5NOR06-D03','Both np and n(1−p) should be sufficiently large'),('P5NOR06-L01','Bin(50,0.5)'),
('P5NOR06-L02','0.8428'),('P5NOR06-L03','0.1631'),('P5NOR06-M01','0.0317'),
('P5NOR06-M02','31.5'),('P5NOR06-R01','0.8697'),('P5NOR06-R02','0.7287'),
('P5NOR06-R03','24.5'),('P5NOR06-R04','44.5<Y<55.5')
), current_answers AS (
 SELECT m.content_key,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb ->> (ascii(q.correct_answer)-ascii('A')) END AS selected
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P5' AND m.lifecycle_state IN ('published','reserve')
 AND m.primary_skill_code IN ('P5-NOR-03','P5-NOR-06')
)
SELECT 'P5_NORMAL_30' audit, count(*) questions,
 count(*) FILTER(WHERE oracle.content_key IS NULL OR current_answers.content_key IS NULL OR oracle.expected_answer IS DISTINCT FROM current_answers.selected) AS failures
FROM oracle FULL JOIN current_answers USING (content_key);
