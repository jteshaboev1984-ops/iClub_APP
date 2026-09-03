-- Production-applied Supabase migration 20260902140216 / add_practice_resume_safe_v4.
-- Resume exposes answer feedback only for questions already answered in this user's in-progress session.

create or replace function public.get_practice_session_resume_safe_v4(p_session_id bigint)
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
  book_ref text,
  input_kind text,
  was_answered boolean,
  saved_user_answer text,
  saved_picked_index integer,
  saved_is_correct boolean,
  correct_answer text,
  explanation text,
  explanation_ru text,
  explanation_uz text,
  explanation_en text
)
language sql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
  select
    x.ord::integer,
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
    q.book_ref,
    case
      when lower(coalesce(q.qtype,'mcq')) <> 'input' then null
      when split_part(trim(coalesce(q.correct_answer,'')),'|',1) ~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$' then 'numeric'
      when split_part(trim(coalesce(q.correct_answer,'')),'|',1) ~ '^[A-Za-z][A-Za-z0-9]*$' then 'token'
      else 'text'
    end as input_kind,
    (a.session_id is not null) as was_answered,
    a.user_answer as saved_user_answer,
    a.picked_index as saved_picked_index,
    case when a.session_id is not null then a.is_correct else null end as saved_is_correct,
    case when a.session_id is not null then q.correct_answer else null end as correct_answer,
    case when a.session_id is not null then q.explanation else null end as explanation,
    case when a.session_id is not null then q.explanation_ru else null end as explanation_ru,
    case when a.session_id is not null then q.explanation_uz else null end as explanation_uz,
    case when a.session_id is not null then q.explanation_en else null end as explanation_en
  from public.practice_sessions_v4 s
  cross join lateral unnest(s.question_ids) with ordinality x(qid,ord)
  join public.questions q on q.id=x.qid and q.is_active is true
  left join public.practice_session_answers_v4 a on a.session_id=s.id and a.question_id=q.id
  where s.id=p_session_id and s.user_id=auth.uid()
  order by x.ord;
$function$;

revoke all on function public.get_practice_session_resume_safe_v4(bigint) from public, anon;
grant execute on function public.get_practice_session_resume_safe_v4(bigint) to authenticated, service_role;
