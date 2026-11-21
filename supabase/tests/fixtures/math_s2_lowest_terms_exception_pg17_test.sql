-- Disposable fixture ONLY. The value assigned to the synthetic qID 6089
-- is an invented fraction, NOT the live bank question or answer.
-- Keep the genuine source bank and correct key out of public GitHub/CI.
BEGIN;
DO $guard$ BEGIN
  IF current_database()<>'postgres'
     OR NOT EXISTS (
       SELECT 1 FROM public.questions q WHERE q.id=995001
         AND q.subject_id=5 AND q.correct_answer='1/2'
     )
     OR EXISTS (SELECT 1 FROM public.questions q WHERE q.id=6089)
  THEN RAISE EXCEPTION 'MATH_S2_SYNTHETIC_PG17_FIXTURE_ONLY'; END IF;
END $guard$;
INSERT INTO public.questions(id,subject_id,qtype,correct_answer,is_active)
VALUES (6089,5,'input','13/17',true);
INSERT INTO public.tour_questions(tour_id,question_id,is_active)
VALUES (999201,6089,true);
DO $assert$
DECLARE
  v_good boolean;
  v_unsimplified boolean;
  v_wrong boolean;
  v_other_equivalent boolean;
  v_other_decimal boolean;
  v_s1_unchanged boolean;
BEGIN
  v_good:=(public.iclub_eval_tour_question_safe_v4(
    6089,'13/17',NULL,true)->>'is_correct')::boolean;
  v_unsimplified:=(public.iclub_eval_tour_question_safe_v4(
    6089,'26/34',NULL,true)->>'is_correct')::boolean;
  v_wrong:=(public.iclub_eval_tour_question_safe_v4(
    6089,'13/18',NULL,true)->>'is_correct')::boolean;
  v_other_equivalent:=(public.iclub_eval_tour_question_safe_v4(
    995001,'6/12',NULL,true)->>'is_correct')::boolean;
  v_other_decimal:=(public.iclub_eval_tour_question_safe_v4(
    995002,'9/2',NULL,true)->>'is_correct')::boolean;
  v_s1_unchanged:=(public.iclub_eval_tour_question_safe_v4(
    995011,'6/12',NULL,true)->>'is_correct')::boolean;
  IF v_good IS DISTINCT FROM true
    OR v_unsimplified IS DISTINCT FROM false
    OR v_wrong IS DISTINCT FROM false
    OR v_other_equivalent IS DISTINCT FROM true
    OR v_other_decimal IS DISTINCT FROM true
    OR v_s1_unchanged IS DISTINCT FROM false
  THEN RAISE EXCEPTION 'S2_LOWEST_TERMS_AND_OTHER_EXACT_EQUIVALENCE_REGRESSION';
  END IF;
  RAISE NOTICE 'S2_LOWEST_TERMS_EXCEPTION_AND_OTHER_EXACT_EQUIVALENCE_PASS';
END $assert$;
ROLLBACK;
DO $after$
BEGIN
  IF EXISTS (SELECT 1 FROM public.questions WHERE id=6089) THEN
    RAISE EXCEPTION 'S2_SYNTHETIC_LOWEST_TERMS_FIXTURE_DID_NOT_ROLLBACK';
  END IF;
END $after$;
