-- Read-only independent second-pass P1-QUA04, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1QUA04-A01', '1≤x≤5'),
('P1QUA04-A02', '2/3<x<4'),
('P1QUA04-A03', '4'),
('P1QUA04-D01', 'x < 2 or x > 3'),
('P1QUA04-D02', 'x<1 or x>6'),
('P1QUA04-D03', '1/2≤x≤3'),
('P1QUA04-L01', '−3 ≤ x ≤ 3'),
('P1QUA04-L02', '−4 < x < 1'),
('P1QUA04-L03', 'x ≤ −4 or x ≥ 2'),
('P1QUA04-M01', 'x ≤ −1 or x ≥ 5'),
('P1QUA04-M02', '4'),
('P1QUA04-R01', '2 < x < 5'),
('P1QUA04-R02', '−3/2 ≤ x ≤ 1'),
('P1QUA04-R03', '7'),
('P1QUA04-R04', '6')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-QUA-04'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_QUA04_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;