-- CANDIDATE ONLY. DO NOT APPLY TO HOSTED SUPABASE WITHOUT A SEPARATE OWNER GO.
-- Mathematics Season 2 Tours only. No question/key/attempt/score mutation.
-- Tested source preflight: 2026-11-20, public.iclub_eval_tour_question_safe_v4
-- Existing owner=postgres, SECURITY DEFINER, search_path public/auth/pg_temp.
--
-- Before ANY application: independent security review; isolated PostgreSQL 17 +
-- signed JWT/PostgREST + Chromium tests; fresh live source hash and session checks.
-- Rollback: restore pre-cutover exact function source; keep helper dormant.
BEGIN;

DO $preflight$
DECLARE
  v_hash text;
BEGIN
  SELECT md5(p.prosrc) INTO v_hash
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='iclub_eval_tour_question_safe_v4'
    AND pg_get_function_identity_arguments(p.oid)=
      'p_question_id bigint, p_user_answer text, p_picked_index integer, p_answered boolean';
  IF v_hash IS DISTINCT FROM '7f564255956fbe61ab8d1a14cade9389' THEN
    RAISE EXCEPTION 'math_s2_tour_input_preflight_source_mismatch';
  END IF;
END
$preflight$;

-- Exact rational equality for future S2 Mathematics inputs. Mathematically
-- equivalent integer/decimal/fraction forms compare by CROSS MULTIPLICATION;
-- no floating error and no tolerance that awards nearly-correct guesses.
-- Limit 500 UTF-8 characters, matching current Tour client text input.
-- This is an exact rational comparison, NOT symbolic algebra evaluation.
CREATE OR REPLACE FUNCTION private.iclub_math_s2_tour_numeric_equiv_v1(
  p_user_answer text, p_expected_answer text
) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER
SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
DECLARE
  v_user text := trim(translate(coalesce(p_user_answer,''), '−–—', '---'));
  v_expected text := trim(translate(coalesce(p_expected_answer,''), '−–—', '---'));
  v_user_n numeric;
  v_user_d numeric;
  v_expected_n numeric;
  v_expected_d numeric;
  v_dec numeric;
BEGIN
  IF v_user='' OR v_expected='' OR length(v_user)>500 OR length(v_expected)>500 THEN
    RETURN false;
  END IF;
  v_user := replace(v_user, ',', '.');
  v_expected := replace(v_expected, ',', '.');
  v_user := regexp_replace(v_user, '[[:space:]]*/[[:space:]]*', '/', 'g');
  v_expected := regexp_replace(v_expected, '[[:space:]]*/[[:space:]]*', '/', 'g');
  BEGIN
    IF v_user ~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]{1,2})?$' THEN
      v_dec := v_user::numeric;
      v_user_d := power(10::numeric,scale(v_dec));
      v_user_n := v_dec*v_user_d;
    ELSIF v_user ~ '^[+-]?[0-9]+/[+-]?[0-9]+$' THEN
      v_user_n := split_part(v_user,'/',1)::numeric;
      v_user_d := split_part(v_user,'/',2)::numeric;
      IF v_user_d=0 THEN RETURN false; END IF;
    ELSE
      RETURN false;
    END IF;
    IF v_expected ~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]{1,2})?$' THEN
      v_dec := v_expected::numeric;
      v_expected_d := power(10::numeric,scale(v_dec));
      v_expected_n := v_dec*v_expected_d;
    ELSIF v_expected ~ '^[+-]?[0-9]+/[+-]?[0-9]+$' THEN
      v_expected_n := split_part(v_expected,'/',1)::numeric;
      v_expected_d := split_part(v_expected,'/',2)::numeric;
      IF v_expected_d=0 THEN RETURN false; END IF;
    ELSE
      -- Explicit nonnumeric answers continue using the existing comparator.
      RETURN public.iclub_tour_input_is_correct_v4(p_user_answer,p_expected_answer);
    END IF;
  EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range
    OR division_by_zero THEN
    RETURN false;
  END;
  RETURN v_user_n*v_expected_d = v_expected_n*v_user_d;
END
$function$;

REVOKE ALL ON FUNCTION private.iclub_math_s2_tour_numeric_equiv_v1(text,text)
  FROM PUBLIC, anon, authenticated;

-- Exact original evaluator body preserved; one added conditional immediately
-- before the original last ELSE branch, scoped by S2 Mathematics membership.
CREATE OR REPLACE FUNCTION public.iclub_eval_tour_question_safe_v4(
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer DEFAULT NULL::integer,
  p_answered boolean DEFAULT true
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public','auth','pg_temp'
AS $function$
DECLARE
  v_q public.questions%rowtype;
  v_selected text;
  v_correct boolean := false;
BEGIN
  SELECT q.* INTO v_q FROM public.questions q
   WHERE q.id=p_question_id AND q.is_active IS true;
  IF v_q.id IS NULL THEN
    RAISE EXCEPTION 'question_not_found_or_inactive' USING errcode='P0002';
  END IF;
  IF coalesce(p_answered,true) IS false THEN
    RETURN jsonb_build_object('selected_answer',null,'is_correct',false);
  END IF;
  IF lower(coalesce(v_q.qtype,''))='mcq' THEN
    IF p_picked_index IS NOT NULL AND p_picked_index BETWEEN 0 AND 25 THEN
      v_selected := chr(65+p_picked_index);
    ELSIF upper(trim(coalesce(p_user_answer,''))) ~ '^[A-Z]$' THEN
      v_selected := upper(trim(p_user_answer));
    ELSIF trim(coalesce(p_user_answer,'')) ~ '^[0-9]+$'
      AND trim(p_user_answer)::integer BETWEEN 0 AND 25 THEN
      v_selected := chr(65+trim(p_user_answer)::integer);
    ELSE
      v_selected := upper(trim(coalesce(p_user_answer,'')));
    END IF;
    v_correct := upper(trim(coalesce(v_selected,'')))=
      upper(trim(coalesce(v_q.correct_answer,'')));
  ELSE
    v_selected := trim(coalesce(p_user_answer,''));
    IF v_q.subject_id=4 AND (v_q.id IN (1946,1965) OR exists (
      SELECT 1 FROM private.chemistry_t1_stage_20261015 s
       WHERE s.question_id=v_q.id
         AND s.payload->>'candidate_id'=s.candidate_id AND v_q.qtype='input'
    )) THEN
      v_correct:=private.iclub_chemistry_t1_typed_correct_20261015(
        v_q.id,p_user_answer);
    ELSIF v_q.subject_id=4 AND exists (
      SELECT 1 FROM private.chemistry_t3_stage_20261015 s
       WHERE s.question_id=v_q.id AND s.payload->>'qtype'='input'
    ) THEN
      v_correct:=private.iclub_chem_t3_numeric_correct_20261015(
        v_q.id,v_selected);
    ELSIF v_q.subject_id=4 AND exists (
      SELECT 1 FROM private.chemistry_release_staging_20261015 s
       WHERE s.question_id=v_q.id AND s.payload->>'qtype'='input'
    ) THEN
      v_correct:=private.iclub_chemistry_release_numeric_correct_20261015(
        v_q.id,v_selected);
    ELSIF v_q.subject_id=4 AND exists (
      SELECT 1 FROM private.chemistry_t2_stage_20261015 s
       WHERE s.question_id=v_q.id AND s.payload->>'qtype'='input'
    ) THEN
      v_correct:=private.iclub_chem_t2_numeric_correct_20261015(
        v_q.id,v_selected);
    ELSIF v_q.subject_id=5 AND EXISTS (
      SELECT 1
      FROM public.tour_questions tq
      JOIN public.tours t ON t.id=tq.tour_id
      JOIN public.seasons s ON s.id=t.season_id
      WHERE tq.question_id=v_q.id AND tq.is_active IS true
        AND t.subject_id=5 AND s.season_no=2
    ) THEN
      v_correct:=private.iclub_math_s2_tour_numeric_equiv_v1(
        v_selected,v_q.correct_answer);
    ELSE
      v_correct:=public.iclub_tour_input_is_correct_v4(
        v_selected,v_q.correct_answer);
    END IF;
  END IF;
  RETURN jsonb_build_object(
    'selected_answer',nullif(v_selected,''),'is_correct',v_correct);
END
$function$;

COMMIT;
