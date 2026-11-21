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
 ('near_decimal','0.3333333333','1/3',false),
 ('wrong_numerator','2/3','1/2',false),
 ('wrong_sign','-1/2','1/2',false),
 ('divide_by_zero','1/0','1/2',false),
 ('nonnumeric','drop table','1/2',false),
 ('unallowed_word','half','1/2',false),
 ('wrong_decimal','0.51','1/2',false),
 ('empty','','1/2',false),
 ('near_half_wrong','0.5000000001','1/2',false),
 ('hundred_digit_exact','1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000/2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000','1/2',true)
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


-- Make the exact PG17 rehearsal FAIL when mathematical or authorization
-- expectations are violated; SELECT-only statistics alone are not a test.
DO $acceptance$
DECLARE
  v_case_total integer;
  v_case_pass integer;
  v_input_total integer;
  v_canonical integer;
  v_fraction_total integer;
  v_fraction_pass integer;
  v_lowest_terms_total integer;
  v_lowest_terms_rejected integer;
  v_decimal_total integer;
  v_decimal_pass integer;
  v_s2_tours integer;
  v_draft_tours integer;
BEGIN
  WITH cases(reply,expected,should_pass) AS (
    VALUES
     ('6/12','1/2',true),('0.5','1/2',true),
     ('3/2','1.5',true),('0,5','1/2',true),
     (' 3 / 6 ','1/2',true),('−1/2','-0.5',true),
     ('+4','4',true),('1/-2','-0.5',true),
     ('0.3333333333','1/3',false),
     ('2/3','1/2',false),('-1/2','1/2',false),
     ('1/0','1/2',false),('drop table','1/2',false),
     ('half','1/2',false),('0.51','1/2',false),
     ('','1/2',false),
     ('0.5000000001','1/2',false),
     ('1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000/2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000','1/2',true)
  ) SELECT count(*),
    count(*) FILTER (WHERE private.iclub_math_s2_tour_numeric_equiv_v1(
        reply,expected) IS NOT DISTINCT FROM should_pass)
    INTO v_case_total,v_case_pass FROM cases;
  IF v_case_total<>18 OR v_case_pass<>18 THEN
    RAISE EXCEPTION 'MATH_S2_SCORER_FAILED: synthetic equivalence cases %/%',
      v_case_pass,v_case_total;
  END IF;
  WITH items AS (
    SELECT DISTINCT q.id,q.correct_answer
    FROM public.questions q
    JOIN public.tour_questions tq ON tq.question_id=q.id
    JOIN public.tours t ON t.id=tq.tour_id
    JOIN public.seasons s ON s.id=t.season_id
    WHERE q.subject_id=5 AND q.qtype='input' AND tq.is_active
      AND t.subject_id=5 AND s.season_no=2
  ), checks AS (
    SELECT id,
      (public.iclub_eval_tour_question_safe_v4(
        id,correct_answer,NULL,true)->>'is_correct')::boolean canon,
      CASE WHEN correct_answer ~ '^[0-9]+/[0-9]+$' THEN
        (public.iclub_eval_tour_question_safe_v4(id,
          (2*split_part(correct_answer,'/',1)::integer)::text||'/'||
          (2*split_part(correct_answer,'/',2)::integer)::text,
          NULL,true)->>'is_correct')::boolean END frac,
      CASE WHEN correct_answer ~ '^[0-9]+[.]5$' THEN
        (public.iclub_eval_tour_question_safe_v4(id,
          (correct_answer::numeric*2)::integer::text||'/2',
          NULL,true)->>'is_correct')::boolean END dec
    FROM items
  )
  SELECT count(*),count(*) FILTER (WHERE canon IS true),
    count(frac) FILTER (WHERE id<>6089),
    count(*) FILTER (WHERE id<>6089 AND frac IS true),
    count(frac) FILTER (WHERE id=6089),
    count(*) FILTER (WHERE id=6089 AND frac IS false),
    count(dec),count(*) FILTER (WHERE dec IS true)
  INTO v_input_total,v_canonical,v_fraction_total,v_fraction_pass,
       v_lowest_terms_total,v_lowest_terms_rejected,
       v_decimal_total,v_decimal_pass
  FROM checks;
  IF v_input_total<>28 OR v_canonical<>28 OR
     v_fraction_total+v_lowest_terms_total<>4
     OR v_fraction_pass<>v_fraction_total
     OR v_lowest_terms_rejected<>v_lowest_terms_total
     OR v_lowest_terms_total NOT IN(0,1)
     OR v_decimal_total<>1 OR v_decimal_pass<>1 THEN
    RAISE EXCEPTION 'MATH_S2_SCORER_FAILED: input %/% fraction %/% decimal %/%',
      v_canonical,v_input_total,v_fraction_pass,v_fraction_total,
      v_decimal_pass,v_decimal_total;
  END IF;
  SELECT count(*),count(*) FILTER (
    WHERE t.is_active IS false AND t.start_date IS NULL
      AND t.end_date IS NULL)
  INTO v_s2_tours,v_draft_tours
  FROM public.tours t JOIN public.seasons s ON s.id=t.season_id
  WHERE t.subject_id=5 AND s.season_no=2;
  IF v_s2_tours<>7 OR v_draft_tours<>7 THEN
    RAISE EXCEPTION 'S2 draft/undated invariant violated';
  END IF;
  IF has_function_privilege('anon',
    'public.iclub_eval_tour_question_safe_v4(bigint,text,integer,boolean)',
    'EXECUTE') OR has_function_privilege('authenticated',
    'public.iclub_eval_tour_question_safe_v4(bigint,text,integer,boolean)',
    'EXECUTE') THEN
    RAISE EXCEPTION 'Direct Tour answer oracle was exposed';
  END IF;
  RAISE NOTICE 'MATH_S2_TOUR_SCORER_SQL_28_INPUT_18_SYNTHETIC_LOWEST_TERMS_GUARD_PASS';
END $acceptance$;

ROLLBACK;
