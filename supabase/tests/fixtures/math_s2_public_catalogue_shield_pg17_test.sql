-- Disposable PostgreSQL17 ONLY; invented S1/S2 Math + Chemistry IDs.
-- Proves old anon-readable view exposure and surgical S2-only shield.
-- No real question stems, answers, clients, scores or production mutations.
ALTER TABLE public.questions
 ADD COLUMN topic text,
 ADD COLUMN subtopic text,
 ADD COLUMN difficulty text,
 ADD COLUMN question_text text,
 ADD COLUMN options_text text,
 ADD COLUMN image_url text,
 ADD COLUMN created_at timestamptz DEFAULT now(),
 ADD COLUMN question_text_ru text,
 ADD COLUMN question_text_uz text,
 ADD COLUMN question_text_en text,
 ADD COLUMN options_text_ru text,
 ADD COLUMN options_text_uz text,
 ADD COLUMN options_text_en text,
 ADD COLUMN book_ref text,
 ADD COLUMN time_limit_sec integer,
 ADD COLUMN quality_status text;

CREATE VIEW public.safe_questions_public AS
 SELECT q.id,q.subject_id,q.topic,q.subtopic,q.difficulty,q.qtype,
 q.question_text,q.options_text,q.image_url,q.is_active,q.created_at,
 q.question_text_ru,q.question_text_uz,q.question_text_en,
 q.options_text_ru,q.options_text_uz,q.options_text_en,
 q.book_ref,q.time_limit_sec,q.quality_status
 FROM public.questions q WHERE q.is_active IS TRUE;
GRANT SELECT ON public.safe_questions_public TO anon,authenticated;

-- Exact installed original ID lookup RPC, read-only copied from hosted source.
-- Privileged function intentionally reproduces pre-fix S2 leak in synthetic PG17.
CREATE OR REPLACE FUNCTION public.get_safe_questions_by_ids(p_question_ids bigint[])
 RETURNS TABLE(request_order integer, id bigint, subject_id bigint, topic text, subtopic text, difficulty text, qtype text, question_text text, options_text text, image_url text, is_active boolean, created_at timestamp with time zone, question_text_ru text, question_text_uz text, question_text_en text, options_text_ru text, options_text_uz text, options_text_en text, book_ref text, time_limit_sec integer, quality_status text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    ids.request_order::integer,
    q.id,
    q.subject_id,
    q.topic,
    q.subtopic,
    q.difficulty,
    q.qtype,
    q.question_text,
    q.options_text,
    q.image_url,
    q.is_active,
    q.created_at,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.book_ref,
    q.time_limit_sec,
    q.quality_status
  from unnest(coalesce(p_question_ids, array[]::bigint[])) with ordinality
    as ids(question_id, request_order)
  join public.questions q
    on q.id = ids.question_id
   and q.is_active is true
  order by ids.request_order;
$function$

GRANT EXECUTE ON FUNCTION public.get_safe_questions_by_ids(bigint[]) TO anon,authenticated;

-- Prove the baseline bug: draft/undated S2 Math still appears in public view.
DO $baseline$
BEGIN
 IF (SELECT count(*) FROM public.get_safe_questions_by_ids(ARRAY[995001,995005]::bigint[])) <> 2
 THEN RAISE EXCEPTION 'baseline_privileged_id_rpc_exposure_not_reproduced'; END IF;
 IF (SELECT count(*) FROM public.safe_questions_public WHERE id IN(995001,995005)) <> 2
 THEN RAISE EXCEPTION 'baseline_s2_public_exposure_not_reproduced'; END IF;
END $baseline$;

\i supabase/candidates/math_s2_safe_questions_public_shield_v1_hold.sql

-- As true unprivileged database role, no direct questions SELECT.
SET ROLE anon;
DO $safe$
BEGIN
 IF EXISTS(SELECT 1 FROM public.get_safe_questions_by_ids(ARRAY[995001,995005,995030]::bigint[]))
 THEN RAISE EXCEPTION 'anon_s2_math_id_lookup_leaked'; END IF;
 IF (SELECT count(*) FROM public.get_safe_questions_by_ids(ARRAY[995011,995021]::bigint[]))<>2
 THEN RAISE EXCEPTION 'anon_s1_chemistry_id_lookup_regressed'; END IF;
 IF EXISTS(SELECT 1 FROM public.safe_questions_public WHERE id IN(995001,995005,995030))
 THEN RAISE EXCEPTION 's2_math_protected_bank_leaked'; END IF;
 IF (SELECT count(*) FROM public.safe_questions_public WHERE id IN(995011,995021)) <> 2
 THEN RAISE EXCEPTION 'season1_or_chemistry_view_regressed'; END IF;
 IF has_table_privilege('anon','public.questions','SELECT')
 THEN RAISE EXCEPTION 'unexpected_raw_questions_grant'; END IF;
END $safe$;
RESET ROLE;

SET ROLE authenticated;
DO $safe$
BEGIN
 IF EXISTS(SELECT 1 FROM public.get_safe_questions_by_ids(ARRAY[995001,995005,995030]::bigint[]))
 THEN RAISE EXCEPTION 'authenticated_s2_math_id_lookup_leaked'; END IF;
 IF (SELECT count(*) FROM public.get_safe_questions_by_ids(ARRAY[995011,995021]::bigint[]))<>2
 THEN RAISE EXCEPTION 'authenticated_s1_chemistry_id_lookup_regressed'; END IF;
 IF EXISTS(SELECT 1 FROM public.safe_questions_public WHERE id IN(995001,995005,995030))
 THEN RAISE EXCEPTION 'authenticated_s2_math_bank_leaked'; END IF;
 IF (SELECT count(*) FROM public.safe_questions_public WHERE id IN(995011,995021)) <> 2
 THEN RAISE EXCEPTION 'authenticated_other_season_regression'; END IF;
END $safe$;
RESET ROLE;

DO $scope$
BEGIN
 IF (SELECT count(*) FROM public.questions WHERE id IN (995001,995005,995011,995021))<>4
 OR (SELECT count(*) FROM public.tour_questions WHERE tour_id=999201)<>6
 THEN RAISE EXCEPTION 'shield_modified_question_or_tour_rows'; END IF;
 RAISE NOTICE 'MATH_S2_ANON_AND_AUTH_CATALOGUE_AND_ID_RPC_SHIELD_PASS';
END $scope$;
