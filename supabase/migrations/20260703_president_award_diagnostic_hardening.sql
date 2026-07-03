begin;

-- iClub President Tech Award Diagnostic Hardening
-- Safe follow-up after advisor review.
-- Does not remove legacy app flow.

create or replace view public.safe_questions_public
with (security_invoker = true)
as
select
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
from public.questions q
where q.is_active is true;

comment on view public.safe_questions_public is
'Safe public question payload for frontend delivery. Security invoker view; intentionally excludes correct_answer and all explanation fields.';

revoke all on public.safe_questions_public from anon;
revoke all on public.safe_questions_public from authenticated;
grant select on public.safe_questions_public to anon;
grant select on public.safe_questions_public to authenticated;

create or replace function public.iclub_normalize_answer(p_answer text)
returns text
language sql
immutable
set search_path to 'public'
as $function$
  select lower(
    regexp_replace(
      trim(replace(coalesce(p_answer, ''), ',', '.')),
      '\s+',
      ' ',
      'g'
    )
  );
$function$;

create or replace function public.iclub_is_numeric(p_answer text)
returns boolean
language sql
immutable
set search_path to 'public'
as $function$
  select coalesce(trim(p_answer), '') ~ '^-?[0-9]+([\.,][0-9]+)?$';
$function$;

create or replace function public.iclub_touch_updated_at()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

-- Internal helpers: only callable from server-side RPC/trigger code.
revoke execute on function public.iclub_normalize_answer(text) from anon;
revoke execute on function public.iclub_normalize_answer(text) from authenticated;
revoke execute on function public.iclub_normalize_answer(text) from public;

revoke execute on function public.iclub_is_numeric(text) from anon;
revoke execute on function public.iclub_is_numeric(text) from authenticated;
revoke execute on function public.iclub_is_numeric(text) from public;

revoke execute on function public.iclub_touch_updated_at() from anon;
revoke execute on function public.iclub_touch_updated_at() from authenticated;
revoke execute on function public.iclub_touch_updated_at() from public;

-- Safe submit must never be callable by anon.
revoke execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) from anon;
revoke execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) from public;
grant execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) to authenticated;

-- Audit is an internal/authenticated tool, not a public endpoint.
revoke execute on function public.get_diagnostic_pilot_audit(bigint) from anon;
revoke execute on function public.get_diagnostic_pilot_audit(bigint) from public;
grant execute on function public.get_diagnostic_pilot_audit(bigint) to authenticated;

-- get_safe_questions_by_ids remains callable by anon intentionally for the current public/Telegram read flow.
-- It returns only safe question payload and no answer keys / explanations.
comment on function public.get_safe_questions_by_ids(bigint[]) is
'Public-safe question delivery RPC. Intentionally callable by anon/authenticated while legacy public question flow is being migrated; returns no correct_answer or explanation fields.';

commit;
