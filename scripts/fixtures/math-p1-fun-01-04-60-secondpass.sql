-- SOURCE-BACKED independent second-pass P1 Functions current published/reserve answer oracles (60 items).
-- Expected values authored from independently reading and solving the English stems.
-- This query checks current database values rather than trusting historic migration text.
WITH expected(key,oracle) AS (VALUES
 ('P1FUN01-A01','√x for x ≥ 0'),
 ('P1FUN01-A02','(x+7)/3'),
 ('P1FUN01-A03','25'),
 ('P1FUN01-D01','Each input has exactly one output'),
 ('P1FUN01-D02','2x²+1'),
 ('P1FUN01-D03','It has no inverse function on this domain because it is not one-one.'),
 ('P1FUN01-L01','the set of permitted input values'),
 ('P1FUN01-L02','Different inputs give different outputs'),
 ('P1FUN01-L03','f(g(x))'),
 ('P1FUN01-M01','f is one-one and f⁻¹(x) = √x for x ≥ 0'),
 ('P1FUN01-M02','All real x except x=2'),
 ('P1FUN01-R01','It must be one-one'),
 ('P1FUN01-R02','the set of output values produced from the allowed domain'),
 ('P1FUN01-R03','−√x, x≥0'),
 ('P1FUN01-R04','1'),
 ('P1FUN02-A01','−1 ≤ f(x) ≤ 8'),
 ('P1FUN02-A02','−13 ≤ f(x) ≤ 5'),
 ('P1FUN02-A03','−8 ≤ f(x) ≤ 13'),
 ('P1FUN02-D01','1 ≤ f(x) ≤ 10'),
 ('P1FUN02-D02','2≤f(x)≤11'),
 ('P1FUN02-D03','−5≤f(x)<5'),
 ('P1FUN02-L01','−3 ≤ f(x) ≤ 3'),
 ('P1FUN02-L02','0 ≤ f(x) ≤ 9'),
 ('P1FUN02-L03','0 ≤ f(x) ≤ 4'),
 ('P1FUN02-M01','0 ≤ f(x) ≤ 9'),
 ('P1FUN02-M02','11≤T≤20'),
 ('P1FUN02-R01','3 ≤ f(x) ≤ 12'),
 ('P1FUN02-R02','−3 ≤ f(x) < 7'),
 ('P1FUN02-R03','1≤f(x)<10'),
 ('P1FUN02-R04','-7'),
 ('P1FUN03-A01','x≥1'),
 ('P1FUN03-A02','x≠±√3'),
 ('P1FUN03-A03','16'),
 ('P1FUN03-D01','x ≠ −1'),
 ('P1FUN03-D02','x≠−2; x≠2'),
 ('P1FUN03-D03','x≥0 and x≠1'),
 ('P1FUN03-L01','2x + 7'),
 ('P1FUN03-L02','1'),
 ('P1FUN03-L03','x ≥ 5'),
 ('P1FUN03-M01','x² − 2, domain x ≥ 0'),
 ('P1FUN03-M02','x≤1 or x≥4'),
 ('P1FUN03-R01','6x + 4'),
 ('P1FUN03-R02','x ≠ 2'),
 ('P1FUN03-R03','5'),
 ('P1FUN03-R04','x≥√3'),
 ('P1FUN04-A01','f⁻¹(x)=2+√(x+3), x≥−3'),
 ('P1FUN04-A02','(3x+1)/(x−2), x≠2'),
 ('P1FUN04-A03','-2'),
 ('P1FUN04-D01','(x + 3)/2'),
 ('P1FUN04-D02','x≥3'),
 ('P1FUN04-D03','Different inputs can give the same output'),
 ('P1FUN04-L01','(x − 5)/3'),
 ('P1FUN04-L02','√x for x ≥ 0'),
 ('P1FUN04-L03','(1 + 2x)/(1 − x), x ≠ 1'),
 ('P1FUN04-M01','x ≥ 0'),
 ('P1FUN04-M02','8'),
 ('P1FUN04-R01','(5 − x)/2'),
 ('P1FUN04-R02','3x − 4'),
 ('P1FUN04-R03','7'),
 ('P1FUN04-R04','−1')
),
actual AS (
 SELECT m.content_key AS key, m.primary_skill_code, q.id AS question_id,
 CASE WHEN q.qtype='input' THEN q.correct_answer
 WHEN q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$'
 THEN q.options_text_en::jsonb ->> (ascii(q.correct_answer)-ascii('A')) END AS selected,
 CASE WHEN q.qtype='input' THEN q.options_text_en::jsonb='[]'::jsonb
 WHEN q.qtype='mcq' THEN jsonb_array_length(q.options_text_en::jsonb)=4 ELSE FALSE END AS option_type_valid,
 q.question_text_en IS NOT NULL AND q.question_text_ru IS NOT NULL AND q.question_text_uz IS NOT NULL
 AND q.explanation_en IS NOT NULL AND q.explanation_ru IS NOT NULL AND q.explanation_uz IS NOT NULL AS has_all_languages
 FROM private.exam_prep_question_content_meta m
 JOIN private.exam_prep_content_versions c ON c.id=m.content_version_id
 JOIN public.questions q ON q.id=m.question_id
 WHERE c.component_code='P1' AND m.lifecycle_state IN ('published','reserve')
 AND m.primary_skill_code IN ('P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04')
),
flags AS (
 SELECT coalesce(e.key,a.key) AS item,e.oracle,a.selected,
 (e.key IS NULL OR a.key IS NULL OR e.oracle IS DISTINCT FROM a.selected
 OR a.option_type_valid IS DISTINCT FROM TRUE OR a.has_all_languages IS DISTINCT FROM TRUE) AS failed
 FROM expected e FULL JOIN actual a USING(key)
)
SELECT 'P1_FUN_01_04_CURRENT_SECOND_PASS' AS audit,
 count(*) AS checked,count(*) FILTER (WHERE failed) AS mismatches,
 jsonb_agg(jsonb_build_object('key',item,'independently_expected',oracle,'current',selected))
 FILTER (WHERE failed) AS details FROM flags;
