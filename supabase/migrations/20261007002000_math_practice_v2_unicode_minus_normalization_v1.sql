-- Mathematics Practice v2 — Unicode minus normalization hardening
-- Branch-only migration. Do not apply to production until the Practice v2 release gate is approved.
--
-- Purpose:
-- 1) accept visually identical Unicode minus/dash characters in scalar numeric answers;
-- 2) keep existing comma-decimal and whitespace behavior unchanged;
-- 3) avoid changing legacy question semantics or Tour evidence/history.
--
-- Supported minus variants: U+2212 (−), U+2013 (–), U+2014 (—) -> ASCII '-'.

create or replace function public.iclub_normalize_answer(p_answer text)
returns text
language sql
immutable
set search_path to 'public'
as $function$
  select lower(
    regexp_replace(
      trim(
        replace(
          translate(coalesce(p_answer, ''), '−–—', '---'),
          ',',
          '.'
        )
      ),
      '[[:space:]]+',
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
  select coalesce(
    trim(translate(coalesce(p_answer, ''), '−–—', '---')),
    ''
  ) ~ '^-?[0-9]+([\.,][0-9]+)?$';
$function$;

comment on function public.iclub_normalize_answer(text)
is 'Normalizes Practice answers: Unicode minus variants to ASCII hyphen-minus, comma decimal to dot, whitespace collapse, lowercase.';

comment on function public.iclub_is_numeric(text)
is 'Returns true for scalar integer/decimal Practice answers after Unicode-minus normalization.';
