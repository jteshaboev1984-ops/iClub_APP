-- P0-02 Tour frontend cutover helpers.
-- 1) Safe, read-only preflight prompt payload before an attempt is consumed.
-- 2) Safe full review payload after the tour is globally closed.

create or replace function public.get_tour_preflight_questions_safe_v4(p_tour_id bigint)
returns table(
  order_no integer,
  id bigint,
  subject_id bigint,
  time_limit_sec integer,
  question_text text,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  image_url text,
  topic text,
  subtopic text,
  difficulty text,
  qtype text,
  book_ref text
)
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
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

revoke all on function public.get_tour_preflight_questions_safe_v4(bigint) from public, anon;
grant execute on function public.get_tour_preflight_questions_safe_v4(bigint) to authenticated, service_role;

comment on function public.get_tour_preflight_questions_safe_v4(bigint) is
'P0-02 safe Tour preflight. Returns prompt/options/image metadata only for an authenticated eligible participant while the tour is open; never returns answer keys or explanations and does not consume an attempt.';

create or replace function public.get_tour_review_full_safe_v4(p_attempt_id bigint)
returns table(
  question_id bigint,
  user_answer text,
  answered boolean,
  is_correct boolean,
  time_spent integer,
  correct_answer text,
  explanation text,
  explanation_ru text,
  explanation_uz text,
  explanation_en text,
  topic text,
  subtopic text,
  book_ref text,
  difficulty text,
  qtype text,
  question_text text,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  image_url text
)
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_tour public.tours%rowtype;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  select t.* into v_tour
  from public.tour_attempts ta
  join public.tours t on t.id=ta.tour_id
  where ta.id=p_attempt_id
    and ta.user_id=v_uid;

  if v_tour.id is null then
    raise exception 'tour_attempt_not_found' using errcode='P0002';
  end if;

  if v_tour.end_date is null or v_today <= v_tour.end_date then
    raise exception 'tour_review_not_open' using errcode='55000';
  end if;

  return query
  select
    a.question_id,
    a.user_answer,
    a.answered,
    a.is_correct,
    a.time_spent,
    q.correct_answer,
    q.explanation,
    q.explanation_ru,
    q.explanation_uz,
    q.explanation_en,
    q.topic,
    q.subtopic,
    q.book_ref,
    q.difficulty,
    q.qtype,
    q.question_text,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.image_url
  from public.tour_answers a
  join public.questions q on q.id=a.question_id
  where a.attempt_id=p_attempt_id
  order by a.id;
end;
$function$;

revoke all on function public.get_tour_review_full_safe_v4(bigint) from public, anon;
grant execute on function public.get_tour_review_full_safe_v4(bigint) to authenticated, service_role;

comment on function public.get_tour_review_full_safe_v4(bigint) is
'P0-02 safe full Tour review. Returns answer key/explanation and full prompt metadata only to the authenticated owner after the tour is globally closed.';
