-- Read-only independent second-pass P1-QUA05, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1QUA05-A01', '3±√3'),
('P1QUA05-A02', '(3,4) and (4,3)'),
('P1QUA05-A03', '-1'),
('P1QUA05-D01', '2 − √2 and 2 + √2'),
('P1QUA05-D02', '(3,3) and (−4,10)'),
('P1QUA05-D03', 'x²+2x−6=0'),
('P1QUA05-L01', '0 and 2'),
('P1QUA05-L02', '−3 and 2'),
('P1QUA05-L03', '1 and 3'),
('P1QUA05-M01', 'k > −1/4'),
('P1QUA05-M02', '2'),
('P1QUA05-R01', '1 and 2'),
('P1QUA05-R02', '0 and 2'),
('P1QUA05-R03', '5'),
('P1QUA05-R04', '0')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-QUA-05'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_QUA05_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;