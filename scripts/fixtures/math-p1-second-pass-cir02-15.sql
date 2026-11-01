-- Read-only independent second-pass P1-CIR02, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1CIR02-A01', '1.6'),
('P1CIR02-A02', '9 cm'),
('P1CIR02-A03', '1.5'),
('P1CIR02-D01', '7.2 cm'),
('P1CIR02-D02', '5/3'),
('P1CIR02-D03', '3/4'),
('P1CIR02-L01', '4 cm'),
('P1CIR02-L02', '1.5'),
('P1CIR02-L03', '15 cm'),
('P1CIR02-M01', '2/3 rad'),
('P1CIR02-M02', '2.4'),
('P1CIR02-R01', '9 m'),
('P1CIR02-R02', '2.5 rad'),
('P1CIR02-R03', '12'),
('P1CIR02-R04', '150°')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-CIR-02'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_CIR02_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;