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
