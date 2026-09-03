-- Production-applied Supabase migration 20260903050138 / add_full_practice_review_safe_v4.
-- Safe post-attempt Practice review for the authenticated owner of a persisted Practice attempt.

create or replace function public.get_practice_review_full_safe_v4(p_attempt_id bigint)
returns table(
  question_id bigint,
  user_answer text,
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
language sql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
  select
    a.question_id,
    a.user_answer,
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
  from public.practice_attempts pa
  join public.practice_answers a on a.attempt_id=pa.id
  join public.questions q on q.id=a.question_id
  where pa.id=p_attempt_id
    and pa.user_id=auth.uid()
  order by a.id;
$function$;

revoke all on function public.get_practice_review_full_safe_v4(bigint) from public, anon;
grant execute on function public.get_practice_review_full_safe_v4(bigint) to authenticated, service_role;

comment on function public.get_practice_review_full_safe_v4(bigint) is
'P0-02 safe post-attempt Practice review. Returns answer key/explanation only for an authenticated user-owned persisted Practice attempt.';
