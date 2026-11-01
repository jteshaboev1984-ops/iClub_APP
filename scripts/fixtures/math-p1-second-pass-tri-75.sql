-- P1-TRI-01..05: 75 independently inspected current published and reserve keys.
-- Formula-based checks supported by separate mathematical property tests.
-- This is read-only; a matching answer key alone is NOT proof of semantic correctness.
WITH expected(k,expected_answer) AS (VALUES
('P1TRI01-A01','π'),
('P1TRI01-A02','−1≤y≤5'),
('P1TRI01-A03','3'),
('P1TRI01-D01','The maximum is 1 at x=π/2'),
('P1TRI01-D02','2π/3'),
('P1TRI01-D03','−6≤y≤2'),
('P1TRI01-L01','2π'),
('P1TRI01-L02','maximum 2, minimum −2'),
('P1TRI01-L03','y=cos x+3'),
('P1TRI01-M01','max 3, min −1, midline y=1'),
('P1TRI01-M02','The maximum value is 2 and one maximum occurs at x=π/6.'),
('P1TRI01-R01','x=π/2'),
('P1TRI01-R02','−4≤y≤2'),
('P1TRI01-R03','5'),
('P1TRI01-R04','x=π/4'),
('P1TRI02-A01-QA20261101','−1/2'),
('P1TRI02-A02','3/2'),
('P1TRI02-A03','2'),
('P1TRI02-D01','1/2'),
('P1TRI02-D02','−√2/2'),
('P1TRI02-D03','−√3/3'),
('P1TRI02-L01','−1/2'),
('P1TRI02-L02','1'),
('P1TRI02-L03','−1/2'),
('P1TRI02-M01','0'),
('P1TRI02-M02','0'),
('P1TRI02-R01','1/2'),
('P1TRI02-R02','−1'),
('P1TRI02-R03','2'),
('P1TRI02-R04','1'),
('P1TRI03-A01','−30°'),
('P1TRI03-A02','Because cos⁻¹ returns values in the principal range 0°≤θ≤180°'),
('P1TRI03-A03','60'),
('P1TRI03-D01','120°'),
('P1TRI03-D02','135°'),
('P1TRI03-D03','−60°'),
('P1TRI03-L01','30°'),
('P1TRI03-L02','−45°'),
('P1TRI03-L03','−60°'),
('P1TRI03-M01','75.5°'),
('P1TRI03-M02','17.5'),
('P1TRI03-R01','90°'),
('P1TRI03-R02','60°'),
('P1TRI03-R03','113.6'),
('P1TRI03-R04','−90°<θ<90°'),
('P1TRI04-A01','cos x'),
('P1TRI04-A02','sin x'),
('P1TRI04-A03','0.64'),
('P1TRI04-D01','cos²x'),
('P1TRI04-D02','sin²x/cos x'),
('P1TRI04-D03','sin²x'),
('P1TRI04-L01','sin²x+cos²x=1'),
('P1TRI04-L02','tan x'),
('P1TRI04-L03','sin x'),
('P1TRI04-M01','tan x'),
('P1TRI04-M02','25'),
('P1TRI04-R01','cos²x'),
('P1TRI04-R02','1/cos x'),
('P1TRI04-R03','0.36'),
('P1TRI04-R04','3/5'),
('P1TRI05-A01','210°, 330°'),
('P1TRI05-A02','−90°, 90°'),
('P1TRI05-A03','4'),
('P1TRI05-D01','30°,150°'),
('P1TRI05-D02','−135°, 135°'),
('P1TRI05-D03','30°, 210°'),
('P1TRI05-L01','60°,300°'),
('P1TRI05-L02','45°,225°'),
('P1TRI05-L03','240°,300°'),
('P1TRI05-M01','30°,150°'),
('P1TRI05-M02','270'),
('P1TRI05-R01','120°,240°'),
('P1TRI05-R02','120°,300°'),
('P1TRI05-R03','5'),
('P1TRI05-R04','120°, 240°')
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
 AND m.primary_skill_code LIKE 'P1-TRI-%'
), comparisons AS(
 SELECT coalesce(e.k,a.k) item,e.expected_answer,a.actual_answer,
 (e.k IS NULL OR a.k IS NULL
   OR a.actual_answer IS DISTINCT FROM e.expected_answer
   OR a.options_valid IS DISTINCT FROM true) AS differs
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_TRI_75_SECOND_PASS' audit,count(*) checked,
count(*) FILTER(WHERE differs) mismatches,
jsonb_agg(jsonb_build_object('item',item,'expected',expected_answer,'saved',actual_answer))
 FILTER(WHERE differs) AS defects
FROM comparisons;