-- HOLD / NOT A MIGRATION: source-pinned candidate for Mathematics Season 2 ONLY.
-- Preserve original client preflight -> image preload -> start -> issued-questions sequence.
-- For eligible S2 Mathematics, preflight returns the same 20 IDs and image URLs,
-- but NO question texts, MCQ options, time limits, topics, difficulty, or book refs.
-- Image URLs remain public; this candidate alone DOES NOT authorize Tour launch.
-- Old clients loaded before rollout can still preflight and retry image failures
-- without consuming an attempt. Must test real cached JS and server permissions.
BEGIN;
DO $pin$
DECLARE v_md5 text;
BEGIN
 SELECT md5(p.prosrc) INTO v_md5 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname='get_tour_preflight_questions_safe_v4';
 IF v_md5 IS DISTINCT FROM '91fc6b12dcb059426668bdff040223b1' THEN
  RAISE EXCEPTION 'math_s2_preflight_source_drift';
 END IF;
END $pin$;
CREATE OR REPLACE FUNCTION public.get_tour_preflight_questions_safe_v4(p_tour_id bigint)
 RETURNS TABLE(order_no integer, id bigint, subject_id bigint, time_limit_sec integer, question_text text, question_text_ru text, question_text_uz text, question_text_en text, options_text text, options_text_ru text, options_text_uz text, options_text_en text, image_url text, topic text, subtopic text, difficulty text, qtype text, book_ref text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_tour public.tours%rowtype;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
  v_redact boolean := false;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  if p_tour_id is null or p_tour_id <= 0 then
    raise exception 'invalid_tour_id' using errcode='22023';
  end if;

  select * into v_tour
  from public.tours t
  where t.id=p_tour_id
    and t.is_active is true;

  if v_tour.id is null then
    raise exception 'tour_not_found_or_inactive' using errcode='P0002';
  end if;
  -- Redact content rather than denying preflight: released/cached clients
  -- require exactly 20 rows to pre-load images BEFORE consuming an attempt.
  v_redact := v_tour.subject_id=5 AND EXISTS (
    SELECT 1 FROM public.seasons s
    WHERE s.id=v_tour.season_id AND s.season_no=2
  );


  if v_tour.start_date is null
     or v_tour.end_date is null
     or v_today < v_tour.start_date
     or v_today > v_tour.end_date then
    raise exception 'tour_not_open' using errcode='55000';
  end if;

  if not exists(
    select 1 from public.users u
    where u.id=v_uid and coalesce(u.is_school_student,false) is true
  ) then
    raise exception 'tour_requires_school_student' using errcode='42501';
  end if;

  if not exists(
    select 1 from public.user_subjects us
    where us.user_id=v_uid
      and us.subject_id=v_tour.subject_id
      and us.mode='competitive'
  ) then
    raise exception 'tour_subject_not_competitive_for_user' using errcode='42501';
  end if;

  if (
    select count(*)
    from public.tour_questions tq
    join public.questions q on q.id=tq.question_id and q.is_active is true
    where tq.tour_id=p_tour_id
      and tq.is_active is true
      and q.subject_id=v_tour.subject_id
  ) <> 20 then
    raise exception 'tour_question_count_not_20' using errcode='55000';
  end if;

  return query
  select
    tq.order_no::integer,
    q.id,
    q.subject_id,
    (CASE WHEN v_redact THEN NULL ELSE q.time_limit_sec END),
    (CASE WHEN v_redact THEN NULL ELSE q.question_text END),
    (CASE WHEN v_redact THEN NULL ELSE q.question_text_ru END),
    (CASE WHEN v_redact THEN NULL ELSE q.question_text_uz END),
    (CASE WHEN v_redact THEN NULL ELSE q.question_text_en END),
    (CASE WHEN v_redact THEN NULL ELSE q.options_text END),
    (CASE WHEN v_redact THEN NULL ELSE q.options_text_ru END),
    (CASE WHEN v_redact THEN NULL ELSE q.options_text_uz END),
    (CASE WHEN v_redact THEN NULL ELSE q.options_text_en END),
    q.image_url,
    (CASE WHEN v_redact THEN NULL ELSE q.topic END),
    (CASE WHEN v_redact THEN NULL ELSE q.subtopic END),
    (CASE WHEN v_redact THEN NULL ELSE q.difficulty END),
    q.qtype,
    (CASE WHEN v_redact THEN NULL ELSE q.book_ref END)
  from public.tour_questions tq
  join public.questions q on q.id=tq.question_id and q.is_active is true
  where tq.tour_id=p_tour_id
    and tq.is_active is true
    and q.subject_id=v_tour.subject_id
  order by tq.order_no,tq.id;
end;
$function$;
COMMIT;
