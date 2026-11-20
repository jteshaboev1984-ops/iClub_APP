-- HOLD ONLY: not installed on Supabase. Owner separate GO required.
-- Paired S2 protection: the public view AND the SECURITY DEFINER
-- get_safe_questions_by_ids RPC must be repaired atomically.
-- Current production source hashes, checked SELECT-only on 2026-11-20:
-- safe_questions_public view MD5 a65a5ecf9fb596cef8b679c8d116316d
-- get_safe_questions_by_ids prosrc MD5 174fd3df820650c2d37b93f5e4131e90
-- Do not publish without checking these are STILL the deployed sources.
BEGIN;
DO $pin$
DECLARE v_view text; v_rpc text;
BEGIN
 SELECT md5(pg_get_viewdef('public.safe_questions_public'::regclass,true)) INTO v_view;
 SELECT md5(p.prosrc) INTO v_rpc FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname='get_safe_questions_by_ids';
 IF v_view IS DISTINCT FROM 'a65a5ecf9fb596cef8b679c8d116316d'
    OR v_rpc IS DISTINCT FROM '174fd3df820650c2d37b93f5e4131e90'
 THEN RAISE EXCEPTION 'math_s2_public_access_source_drift'; END IF;
END $pin$;

-- HOLD / NOT INSTALLED IN HOSTED SUPABASE.
-- Prevent anonymous/authenticated catalogue access to unreleased Mathematics Season 2
-- Tour question stems/options without changing Season 1 or any question rows.
-- This view is NOT used to supply secure open Tour sessions; existing Tour RPCs remain.
-- Recheck existing grants, dependencies and current live view definition before any owner-GO deployment.
-- The current installed view is owned by postgres and returns every active question,
-- including inactive/undated S2 Tour questions: 140 protected contents exposed.
--
-- NOTE: Do not switch to security_invoker without independently redesigning its
-- public API; it would change established legacy catalogue access.
CREATE OR REPLACE VIEW public.safe_questions_public AS
 SELECT
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
 FROM public.questions q
 WHERE q.is_active IS TRUE
 AND NOT EXISTS (
   SELECT 1
   FROM public.tour_questions tq
   JOIN public.tours t ON t.id = tq.tour_id
   JOIN public.seasons s ON s.id = t.season_id
   WHERE tq.question_id = q.id
     AND t.subject_id = 5
     AND s.season_no = 2
 );

-- Keep existing view owner, grants and column order. Do not change S1/other
-- subject visibility, publish draft bank, alter Tour dates or grant SELECT on
-- public.questions. Current Season2 Tour preflight RPC remains auth/dates gated.

-- Existing signature, table columns, request ordering and grants retained.
-- Change only the source relation: protected view, never raw questions.
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
  join public.safe_questions_public q
    on q.id = ids.question_id
   and q.is_active is true
  order by ids.request_order;
$function$;

COMMIT;
