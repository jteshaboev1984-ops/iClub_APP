-- iClub APP — P0-03 question security cutover DRAFT
-- DO NOT APPLY until:
--   1) P0-02 v3 RPC contract is applied and smoke-tested;
--   2) production frontend Practice/Tours no longer read questions.correct_answer/explanation directly;
--   3) Practice/Tour review uses safe review RPCs;
--   4) integrity/hash regression is green.
--
-- This file intentionally lives OUTSIDE supabase/migrations so an ordinary migration run cannot apply it early.

begin;

drop policy if exists questions_public_read on public.questions;
drop policy if exists tour_questions_public_read on public.tour_questions;

drop policy if exists tour_attempts_rw_own on public.tour_attempts;
drop policy if exists tour_attempts_insert_own on public.tour_attempts;
drop policy if exists tour_attempts_update_own on public.tour_attempts;
drop policy if exists tour_attempts_delete_own on public.tour_attempts;

drop policy if exists tour_answers_insert_own on public.tour_answers;
drop policy if exists tour_answers_insert_owner on public.tour_answers;
drop policy if exists tour_answers_update_own on public.tour_answers;
drop policy if exists tour_answers_update_owner on public.tour_answers;
drop policy if exists tour_answers_delete_owner on public.tour_answers;
drop policy if exists tour_answers_select_own on public.tour_answers;
drop policy if exists tour_answers_select_owner on public.tour_answers;

create or replace view public.safe_questions_public as
select
  q.id,q.subject_id,q.topic,q.subtopic,q.difficulty,q.qtype,
  q.question_text,q.options_text,q.image_url,q.is_active,q.created_at,
  q.question_text_ru,q.question_text_uz,q.question_text_en,
  q.options_text_ru,q.options_text_uz,q.options_text_en,
  q.book_ref,q.time_limit_sec,q.quality_status
from public.questions q
where q.is_active is true
  and not exists (
    select 1
    from public.tour_questions tq
    join public.tours t on t.id=tq.tour_id
    where tq.question_id=q.id
      and tq.is_active is true
      and t.is_active is true
      and (t.end_date is null or (now() at time zone 'Asia/Tashkent')::date <= t.end_date)
  );

create or replace function public.get_safe_questions_by_ids(p_question_ids bigint[])
returns table(
  request_order integer,
  id bigint,
  subject_id bigint,
  topic text,
  subtopic text,
  difficulty text,
  qtype text,
  question_text text,
  options_text text,
  image_url text,
  is_active boolean,
  created_at timestamptz,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  book_ref text,
  time_limit_sec integer,
  quality_status text
)
language sql
stable
security definer
set search_path=public,pg_temp
as $$
  select
    requested.ord::integer,
    q.id,q.subject_id,q.topic,q.subtopic,q.difficulty,q.qtype,
    q.question_text,q.options_text,q.image_url,q.is_active,q.created_at,
    q.question_text_ru,q.question_text_uz,q.question_text_en,
    q.options_text_ru,q.options_text_uz,q.options_text_en,
    q.book_ref,q.time_limit_sec,q.quality_status
  from unnest(coalesce(p_question_ids,'{}'::bigint[])) with ordinality requested(question_id,ord)
  join public.questions q on q.id=requested.question_id and q.is_active is true
  where not exists (
    select 1
    from public.tour_questions tq
    join public.tours t on t.id=tq.tour_id
    where tq.question_id=q.id
      and tq.is_active is true
      and t.is_active is true
      and (t.end_date is null or (now() at time zone 'Asia/Tashkent')::date <= t.end_date)
  )
  order by requested.ord;
$$;

comment on function public.get_safe_questions_by_ids(bigint[]) is
'Public-safe generic delivery. No answer keys/explanations and protected active/upcoming Tour questions are excluded. Tour delivery must use session-authorized RPC.';

commit;
