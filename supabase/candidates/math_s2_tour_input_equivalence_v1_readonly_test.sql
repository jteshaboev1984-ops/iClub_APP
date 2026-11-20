-- READ-ONLY POST-CANDIDATE ACCEPTANCE. Run on a DISPOSABLE PostgreSQL17 copy
-- AFTER the HOLD candidate is installed there. Never run candidate on live iClub
-- without separate owner GO. No protected stems, answer keys or learner records output.
BEGIN READ ONLY;

-- Synthetic positive/negative cases; raw values are invented test-only examples.
WITH cases(label,reply,expected,should_pass) AS (
 VALUES
 ('equivalent_fractions','6/12','1/2',true),
 ('fraction_to_decimal','0.5','1/2',true),
 ('decimal_to_fraction','3/2','1.5',true),
 ('decimal_comma','0,5','1/2',true),
 ('spaces_around_slash',' 3 / 6 ','1/2',true),
 ('unicode_minus','−1/2','-0.5',true),
 ('plus_sign','+4','4',true),
 ('fraction_negative_denom','1/-2','-0.5',true),
 ('near_decimal','0.3333333333','1/3',true),
 ('wrong_numerator','2/3','1/2',false),
 ('wrong_sign','-1/2','1/2',false),
 ('divide_by_zero','1/0','1/2',false),
 ('nonnumeric','drop table','1/2',false),
 ('unallowed_word','half','1/2',false),
 ('wrong_decimal','0.51','1/2',false),
 ('empty','','1/2',false)
)
SELECT count(*) AS cases_total,
       count(*) FILTER (WHERE private.iclub_math_s2_tour_numeric_equiv_v1(reply,expected)=should_pass) AS cases_pass,
       array_agg(label ORDER BY label)
         FILTER (WHERE private.iclub_math_s2_tour_numeric_equiv_v1(reply,expected) IS DISTINCT FROM should_pass)
         AS failures
FROM cases;

-- Actual content, aggregate only. This intentionally calls the reviewed
-- SELECT-only evaluator (does not create a Tour attempt or regrade history).
WITH items AS (
 SELECT DISTINCT q.id,q.correct_answer
 FROM public.questions q JOIN public.tour_questions tq ON tq.question_id=q.id
 JOIN public.tours t ON t.id=tq.tour_id
 JOIN public.seasons s ON s.id=t.season_id
 WHERE q.subject_id=5 AND q.qtype='input' AND tq.is_active
   AND t.subject_id=5 AND s.season_no=2
), tests AS (
 SELECT id,
   (public.iclub_eval_tour_question_safe_v4(id,correct_answer,NULL,true)->>'is_correct')::boolean AS canonical_ok,
   CASE WHEN correct_answer ~ '^[0-9]+/[0-9]+$' THEN
     (public.iclub_eval_tour_question_safe_v4(
       id,
       (2*split_part(correct_answer,'/',1)::integer)::text||'/'||
       (2*split_part(correct_answer,'/',2)::integer)::text,NULL,true
     )->>'is_correct')::boolean
   END AS equivalent_fraction_ok,
   CASE WHEN correct_answer ~ '^[0-9]+[.]5$' THEN
     (public.iclub_eval_tour_question_safe_v4(
       id,(correct_answer::numeric*2)::integer::text||'/2',NULL,true
     )->>'is_correct')::boolean
   END AS equivalent_decimal_ok
 FROM items
)
SELECT count(*) AS math_s2_input_total,
       count(*) FILTER (WHERE canonical_ok) AS canonical_pass,
       count(*) FILTER (WHERE equivalent_fraction_ok IS true) AS fraction_equivalence_pass,
       count(*) FILTER (WHERE equivalent_fraction_ok IS NOT NULL) AS fraction_equivalence_total,
       count(*) FILTER (WHERE equivalent_decimal_ok IS true) AS decimal_equivalence_pass,
       count(*) FILTER (WHERE equivalent_decimal_ok IS NOT NULL) AS decimal_equivalence_total
FROM tests;

-- Preserve live boundary; confirms no dates/activation are accidentally set.
SELECT count(*) AS math_s2_tours,
       count(*) FILTER (WHERE NOT t.is_active AND t.start_date IS NULL AND t.end_date IS NULL)
         AS draft_undated
FROM public.tours t JOIN public.seasons s ON s.id=t.season_id
WHERE t.subject_id=5 AND s.season_no=2;

ROLLBACK;
