-- HOLD: Mathematics S2 old-client fail-before-attempt guard.
-- Must be installed only together with a reviewed new private-image client and
-- private storage; cached S2 clients must reload rather than spend a Tour attempt.
-- Old #641 20-row redacted preflight with public image links is NOT secure enough.
-- Existing Season 1 / other subject preflight remains unchanged.
-- Not installed in hosted Supabase. Do not publish/activate Tours as part of this PR.
-- Production original get_tour_preflight_questions_safe_v4 prosrc MD5:
-- 91fc6b12dcb059426668bdff040223b1 (read-only 2026-11-20).
-- No S1, Chemistry, Biology, Economics or existing practice behavior changed.
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
  -- Mathematics Season 2 Tours: never return the entire examination bank
  -- before an actual one-attempt timer/session starts. Call
  -- start_tour_attempt_safe_v4 then get_tour_session_questions_safe_v4.
  if v_tour.subject_id=5 and exists(
    select 1 from public.seasons s where s.id=v_tour.season_id and s.season_no=2
  ) then
    raise exception 'math_s2_questions_require_started_attempt' using errcode='55000';
  end if;


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
    q.time_limit_sec,
    q.question_text,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.image_url,
    q.topic,
    q.subtopic,
    q.difficulty,
    q.qtype,
    q.book_ref
  from public.tour_questions tq
  join public.questions q on q.id=tq.question_id and q.is_active is true
  where tq.tour_id=p_tour_id
    and tq.is_active is true
    and q.subject_id=v_tour.subject_id
  order by tq.order_no,tq.id;
end;
$function$;
COMMIT;
