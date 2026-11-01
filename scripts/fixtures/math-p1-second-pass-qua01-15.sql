-- Read-only independent second-pass P1-QUA01, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1QUA01-A01', '2(x + 3)² − 7'),
('P1QUA01-A02', '(2, 11)'),
('P1QUA01-A03', '5'),
('P1QUA01-D01', '(x − 3)² + 2'),
('P1QUA01-D02', '3(x − 3)² + 4'),
('P1QUA01-D03', 'The vertex is (−2, 9) and it is a maximum.'),
('P1QUA01-L01', '(x + 4)² + 3'),
('P1QUA01-L02', '(3, −11)'),
('P1QUA01-L03', '6'),
('P1QUA01-M01', '4'),
('P1QUA01-M02', '(4, 35)'),
('P1QUA01-R01', '(x + 2)² − 9'),
('P1QUA01-R02', '(3, 5)'),
('P1QUA01-R03', '3'),
('P1QUA01-R04', 'The vertex is (5, 7) and 7 is a maximum.')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-QUA-01'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_QUA01_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;