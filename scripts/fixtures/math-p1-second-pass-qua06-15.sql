-- Read-only independent second-pass P1-QUA06, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1QUA06-A01', '4'),
('P1QUA06-A02', 'u=2 or 3'),
('P1QUA06-A03', '12'),
('P1QUA06-D01', 'x = −2, −1, 1, 2'),
('P1QUA06-D02', 'u=x⁴'),
('P1QUA06-D03', 'x²−x=2 or x²−x=5'),
('P1QUA06-L01', 'x = 0, ±√3'),
('P1QUA06-L02', 'x = 1 or x = ∛4'),
('P1QUA06-L03', 'x = −1, 1, 3, 5'),
('P1QUA06-M01', 'x = ±⁴√3, ±√2'),
('P1QUA06-M02', '14'),
('P1QUA06-R01', 'x = −3, −2, 2, 3'),
('P1QUA06-R02', 'x = −1, 0, 1, 2'),
('P1QUA06-R03', '3'),
('P1QUA06-R04', '6')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-QUA-06'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_QUA06_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;