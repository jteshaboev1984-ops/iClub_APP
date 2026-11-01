-- SOURCE-BACKED independent second-pass P1 Functions current published/reserve answer oracles (60 items).
-- Expected values authored from independently reading and solving the English stems.
-- This query checks current database values rather than trusting historic migration text.
WITH expected(key,oracle) AS (VALUES
 ('P1FUN05-A01','Q=(7,−3) and the midpoint of PQ is (2,2)'),
 ('P1FUN05-A02','(5,5)'),
 ('P1FUN05-A03','4'),
 ('P1FUN05-D01','(5, 2)'),
 ('P1FUN05-D02','y=x'),
 ('P1FUN05-D03','−1'),
 ('P1FUN05-L01','3'),
 ('P1FUN05-L02','y = x'),
 ('P1FUN05-L03','f⁻¹(4) = 4'),
 ('P1FUN05-M01','(−3, −3)'),
 ('P1FUN05-M02','4'),
 ('P1FUN05-R01','(6, −1)'),
 ('P1FUN05-R02','[2, ∞)'),
 ('P1FUN05-R03','7'),
 ('P1FUN05-R04','3'),
 ('P1FUN06-A01','4 units left and 3 units down'),
 ('P1FUN06-A02','(1,7)'),
 ('P1FUN06-A03','2'),
 ('P1FUN06-D01','(5, 9)'),
 ('P1FUN06-D02','(2,−1)'),
 ('P1FUN06-D03','3 left, 5 up'),
 ('P1FUN06-L01','Translation 2 units up'),
 ('P1FUN06-L02','Translation 4 units right'),
 ('P1FUN06-L03','(−3, −2)'),
 ('P1FUN06-M01','(4, 4)'),
 ('P1FUN06-M02','(3,7)'),
 ('P1FUN06-R01','a translation 7 units down'),
 ('P1FUN06-R02','5 units left'),
 ('P1FUN06-R03','7'),
 ('P1FUN06-R04','(−1,−2)'),
 ('P1FUN07-A01','(−3,−4)'),
 ('P1FUN07-A02','Reflection in the x-axis'),
 ('P1FUN07-A03','5'),
 ('P1FUN07-D01','(2, 3)'),
 ('P1FUN07-D02','(−3,−7)'),
 ('P1FUN07-D03','(−5,−2)'),
 ('P1FUN07-L01','y = f(−x)'),
 ('P1FUN07-L02','(4, 5)'),
 ('P1FUN07-L03','Reflection in both coordinate axes'),
 ('P1FUN07-M01','(−5, 4)'),
 ('P1FUN07-M02','y=−f(−x)'),
 ('P1FUN07-R01','(3, −1)'),
 ('P1FUN07-R02','(2, −6)'),
 ('P1FUN07-R03','2'),
 ('P1FUN07-R04','(−4,7)'),
 ('P1FUN08-A01','(18,−4)'),
 ('P1FUN08-A02','1/5'),
 ('P1FUN08-A03','7'),
 ('P1FUN08-D01','(2, 6)'),
 ('P1FUN08-D02','(4,−12)'),
 ('P1FUN08-D03','4'),
 ('P1FUN08-L01','Vertical stretch by factor 3'),
 ('P1FUN08-L02','Compressed by scale factor 1/4'),
 ('P1FUN08-L03','(−4, 5)'),
 ('P1FUN08-M01','(4, 2)'),
 ('P1FUN08-M02','(27,−8)'),
 ('P1FUN08-R01','(6, −1)'),
 ('P1FUN08-R02','(4, 3)'),
 ('P1FUN08-R03','1'),
 ('P1FUN08-R04','(−3,5)')
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
 AND m.primary_skill_code IN ('P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08')
),
flags AS (
 SELECT coalesce(e.key,a.key) AS item,e.oracle,a.selected,
 (e.key IS NULL OR a.key IS NULL OR e.oracle IS DISTINCT FROM a.selected
 OR a.option_type_valid IS DISTINCT FROM TRUE OR a.has_all_languages IS DISTINCT FROM TRUE) AS failed
 FROM expected e FULL JOIN actual a USING(key)
)
SELECT 'P1_FUN_05_08_CURRENT_SECOND_PASS' AS audit,
 count(*) AS checked,count(*) FILTER (WHERE failed) AS mismatches,
 jsonb_agg(jsonb_build_object('key',item,'independently_expected',oracle,'current',selected))
 FILTER (WHERE failed) AS details FROM flags;
