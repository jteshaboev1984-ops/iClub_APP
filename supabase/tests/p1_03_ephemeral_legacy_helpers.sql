-- P1-03 ephemeral CI only.
-- Mirrors pre-existing production helpers used by P0-09 evaluator but not present
-- in the intentionally minimal p0_15_contract_bootstrap.sql.

\set ON_ERROR_STOP on

create or replace function public.iclub_normalize_answer(p_answer text)
returns text
language sql
immutable
set search_path to 'public'
as $$
  select lower(
    regexp_replace(
      trim(replace(coalesce(p_answer, ''), ',', '.')),
      '\s+',
      ' ',
      'g'
    )
  );
$$;

create or replace function public.iclub_is_numeric(p_answer text)
returns boolean
language sql
immutable
set search_path to 'public'
as $$
  select coalesce(trim(p_answer), '') ~ '^-?[0-9]+([\.,][0-9]+)?$';
$$;
