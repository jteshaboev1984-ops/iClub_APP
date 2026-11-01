-- P1-SER-01..05: 75 independently inspected current published and reserve keys.
-- Formula-based checks supported by separate mathematical property tests.
-- This is read-only; a matching answer key alone is NOT proof of semantic correctness.
WITH expected(k,expected_answer) AS (VALUES
('P1SER01-A01','15'),
('P1SER01-A02','6'),
('P1SER01-A03','216'),
('P1SER01-D01','24'),
('P1SER01-D02','6'),
('P1SER01-D03','3'),
('P1SER01-L01','3'),
('P1SER01-L02','40'),
('P1SER01-L03','81'),
('P1SER01-M01','9'),
('P1SER01-M02','2'),
('P1SER01-R01','−12'),
('P1SER01-R02','24'),
('P1SER01-R03','625'),
('P1SER01-R04','−6'),
('P1SER02-A01','arithmetic with common difference 5'),
('P1SER02-A02','geometric with common ratio 1/2'),
('P1SER02-A03','11'),
('P1SER02-D01','arithmetic with common difference 3'),
('P1SER02-D02','arithmetic with difference 3'),
('P1SER02-D03','geometric with ratio −2'),
('P1SER02-L01','geometric with ratio 3'),
('P1SER02-L02','arithmetic, d=−3'),
('P1SER02-L03','geometric, r=1/3'),
('P1SER02-M01','geometric with ratio 2'),
('P1SER02-M02','162'),
('P1SER02-R01','arithmetic, d=3'),
('P1SER02-R02','geometric, r=2'),
('P1SER02-R03','-4'),
('P1SER02-R04','geometric with ratio 3'),
('P1SER03-A01','3'),
('P1SER03-A02','4'),
('P1SER03-A03','3'),
('P1SER03-D01','185'),
('P1SER03-D02','4'),
('P1SER03-D03','40'),
('P1SER03-L01','51'),
('P1SER03-L02','610'),
('P1SER03-L03','4'),
('P1SER03-M01','6n−1'),
('P1SER03-M02','20'),
('P1SER03-R01','270'),
('P1SER03-R02','3'),
('P1SER03-R03','2'),
('P1SER03-R04','41'),
('P1SER04-A01','5'),
('P1SER04-A02','3'),
('P1SER04-A03','3'),
('P1SER04-D01','189'),
('P1SER04-D02','3'),
('P1SER04-D03','315'),
('P1SER04-L01','5/128'),
('P1SER04-L02','484'),
('P1SER04-L03','3'),
('P1SER04-M01','5'),
('P1SER04-M02','80'),
('P1SER04-R01','90'),
('P1SER04-R02','5'),
('P1SER04-R03','5'),
('P1SER04-R04','93/16'),
('P1SER05-A01','10−5+2.5−...'),
('P1SER05-A02','0.4'),
('P1SER05-A03','1.5'),
('P1SER05-D01','24'),
('P1SER05-D02','27'),
('P1SER05-D03','14−7+3.5−...'),
('P1SER05-L01','|r|<1'),
('P1SER05-L02','6.25'),
('P1SER05-L03','0.2'),
('P1SER05-M01','0.75'),
('P1SER05-M02','4'),
('P1SER05-R01','13.5'),
('P1SER05-R02','It converges and S∞=50/7'),
('P1SER05-R03','-4'),
('P1SER05-R04','10.8')
), actual AS(
 SELECT m.content_key k, q.id AS question_id,q.qtype kind,q.correct_answer key,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 WHEN q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$'
  THEN q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END AS actual_answer,
 CASE WHEN q.qtype='input' THEN jsonb_array_length(q.options_text_en::jsonb)=0
      WHEN q.qtype='mcq' THEN jsonb_array_length(q.options_text_en::jsonb)=4
      ELSE false END AS options_valid
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions v ON v.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE v.component_code='P1' AND m.lifecycle_state IN('published','reserve')
 AND m.primary_skill_code LIKE 'P1-SER-%'
), comparisons AS(
 SELECT coalesce(e.k,a.k) item,e.expected_answer,a.actual_answer,
 (e.k IS NULL OR a.k IS NULL
   OR a.actual_answer IS DISTINCT FROM e.expected_answer
   OR a.options_valid IS DISTINCT FROM true) AS differs
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_SER_75_SECOND_PASS' audit,count(*) checked,
count(*) FILTER(WHERE differs) mismatches,
jsonb_agg(jsonb_build_object('item',item,'expected',expected_answer,'saved',actual_answer))
 FILTER(WHERE differs) AS defects
FROM comparisons;