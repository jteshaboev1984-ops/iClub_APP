-- Read-only independent second-pass P1-CIR01, current published and reserve keys.
-- Expected answers checked against the stem independently; no student data or mutations.
WITH expected(k,derived) AS (VALUES
('P1CIR01-A01', '7π/6'),
('P1CIR01-A02', '110°'),
('P1CIR01-A03', '80'),
('P1CIR01-D01', '5π/6'),
('P1CIR01-D02', '11π/6'),
('P1CIR01-D03', '195°'),
('P1CIR01-L01', 'π/3'),
('P1CIR01-L02', '105°'),
('P1CIR01-L03', '5π/4'),
('P1CIR01-M01', '7π/18'),
('P1CIR01-M02', '2π/3'),
('P1CIR01-R01', '22.5°'),
('P1CIR01-R02', '7π/4'),
('P1CIR01-R03', '90'),
('P1CIR01-R04', '2π/5')
), actual AS(
 SELECT m.content_key k,q.qtype kind,q.correct_answer answer_letter,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 ELSE q.options_text_en::jsonb->>(ascii(q.correct_answer)-ascii('A')) END selected,
 jsonb_array_length(q.options_text_en::jsonb) AS option_count
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN('published','reserve') AND m.primary_skill_code='P1-CIR-01'
), comparison AS (
 SELECT coalesce(e.k,a.k) k,e.derived,a.selected,
 (e.k IS NULL OR a.k IS NULL OR e.derived IS DISTINCT FROM a.selected
 OR (a.kind='mcq' AND (a.answer_letter !~ '^[A-D]$' OR a.option_count<>4))
 OR (a.kind='input' AND a.option_count<>0)) AS wrong
 FROM expected e FULL JOIN actual a USING(k)
)
SELECT 'P1_CIR01_SECOND_PASS_15' audit,count(*) checked,
 count(*) FILTER(WHERE wrong) mismatches,
 jsonb_agg(jsonb_build_object('key',k,'source_key',selected,'expected',derived)) FILTER(WHERE wrong) defects
FROM comparison;