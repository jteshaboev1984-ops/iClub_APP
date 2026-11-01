-- Read-only independent second-pass P1-QUA02, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1QUA02-A01', '0'),
('P1QUA02-A02', 'k < −2 or k > 6'),
('P1QUA02-A03', 'm = −3 or 3'),
('P1QUA02-D01', '4'),
('P1QUA02-D02', 'No real roots'),
('P1QUA02-D03', 'p = 1'),
('P1QUA02-L01', '0'),
('P1QUA02-L02', 'k < −8 or k > 8'),
('P1QUA02-L03', '−1/2'),
('P1QUA02-M01', '4'),
('P1QUA02-M02', '3'),
('P1QUA02-R01', 'c > 3'),
('P1QUA02-R02', 'p < −6 or p > 6'),
('P1QUA02-R03', '−2√10 < q < 2√10'),
('P1QUA02-R04', 'm = −1 or m = 1')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-QUA-02'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_QUA02_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;