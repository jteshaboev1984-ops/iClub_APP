-- Read-only current P1-CIR-03 15-item geometric answer audit.
-- Arithmetic was independently derived from sector, annular-sector and triangle formulas,
-- including two corrected v2 sources. Exact-form answers compare canonical text.
WITH expected AS(
 SELECT * FROM (VALUES
 ('P1CIR03-A01-QA20261030','4.13 cm²'),
 ('P1CIR03-A02','1.5'),('P1CIR03-A03-QA20261030','25.05'),
 ('P1CIR03-D01','6π'),('P1CIR03-D02','35 cm²'),
 ('P1CIR03-D03','6π−9√3 cm²'),
 ('P1CIR03-L01','15'),('P1CIR03-L02','3'),('P1CIR03-L03','4π−8'),
 ('P1CIR03-M01','9π/2'),('P1CIR03-M02','12'),
 ('P1CIR03-R01','9'),('P1CIR03-R02','5'),('P1CIR03-R03','16'),('P1CIR03-R04','1.5')
 ) t(content_key,derived_answer)
), actual AS(
 SELECT m.content_key,q.id,q.qtype,
 CASE WHEN q.qtype='input' THEN q.correct_answer
      ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END keyed_answer
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE cv.component_code='P1' AND m.primary_skill_code='P1-CIR-03'
 AND m.lifecycle_state IN('published','reserve')
)
SELECT 'P1_CIR03_15_INDEPENDENT_KEYS' AS audit,count(*) AS questions,
 count(*) FILTER (WHERE actual.content_key IS NULL) AS missing_questions,
 count(*) FILTER (WHERE expected.content_key IS NULL
   OR actual.keyed_answer IS DISTINCT FROM expected.derived_answer) AS mismatched_answers
FROM expected FULL JOIN actual USING(content_key);
