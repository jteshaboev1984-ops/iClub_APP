-- Read-only independent second-pass P1-QUA03, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1QUA03-A01', 'x = 3 or 1/2'),
('P1QUA03-A02', 'x = 2 ± √5'),
('P1QUA03-A03', 'Factorisation'),
('P1QUA03-D01', 'x = 3 or x = 1/2'),
('P1QUA03-D02', 'x = −1 ± 2√2'),
('P1QUA03-D03', 'x = −5 ± 2√2'),
('P1QUA03-L01', 'x = 4 or 5'),
('P1QUA03-L02', 'x = 4/3 or −2'),
('P1QUA03-L03', 'x = −3 ± 2√2'),
('P1QUA03-M01', 'x = 8 or −3'),
('P1QUA03-M02', '6 cm'),
('P1QUA03-R01', 'x = 1/2 or 5/2'),
('P1QUA03-R02', 'x = 7 or −2'),
('P1QUA03-R03', 'x = 2 or x = −1/3'),
('P1QUA03-R04', 'x = (−3 ± √41)/4')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-QUA-03'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_QUA03_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;