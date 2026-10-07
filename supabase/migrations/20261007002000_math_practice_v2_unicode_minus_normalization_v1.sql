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


create or replace function public.iclub_numeric_value(p_answer text)
returns numeric
language sql
immutable
set search_path to 'public'
as $function$
  select case
    when public.iclub_is_numeric(p_answer) then
      replace(
        trim(translate(coalesce(p_answer,''), '−–—', '---')),
        ',',
        '.'
      )::numeric
    else null
  end;
$function$;

comment on function public.iclub_numeric_value(text)
is 'Parses a governed scalar Practice numeric answer after Unicode-minus and comma-decimal normalization; returns NULL for non-numeric input.';


create or replace function public.iclub_eval_practice_question_safe_v4(
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_q public.questions%rowtype;
  v_selected text;
  v_selected_norm text;
  v_correct boolean := false;
begin
  select q.* into v_q
  from public.questions q
  where q.id=p_question_id
    and q.is_active is true;

  if v_q.id is null then
    raise exception 'question_not_found_or_inactive' using errcode='P0002';
  end if;

  if lower(coalesce(v_q.qtype,''))='mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected:=chr(65+p_picked_index);
    elsif trim(coalesce(p_user_answer,'')) ~ '^[0-9]+$'
          and trim(p_user_answer)::integer between 0 and 25 then
      v_selected:=chr(65+trim(p_user_answer)::integer);
    else
      v_selected:=upper(trim(coalesce(p_user_answer,'')));
    end if;

    v_correct:=(
      upper(trim(coalesce(v_selected,'')))=upper(trim(coalesce(v_q.correct_answer,'')))
      or public.iclub_normalize_answer(v_selected)=public.iclub_normalize_answer(v_q.correct_answer)
    );
  else
    v_selected:=trim(coalesce(p_user_answer,''));
    v_selected_norm:=public.iclub_normalize_answer(v_selected);

    v_correct:=exists(
      select 1
      from regexp_split_to_table(coalesce(v_q.correct_answer,''), '\\|') accepted_answer
      where public.iclub_normalize_answer(accepted_answer)=v_selected_norm
    );

    if not v_correct
       and public.iclub_is_numeric(v_selected)
       and public.iclub_is_numeric(v_q.correct_answer) then
      v_correct:=public.iclub_numeric_value(v_selected)
                 =public.iclub_numeric_value(v_q.correct_answer);
    end if;
  end if;

  return jsonb_build_object(
    'selected_answer',nullif(v_selected,''),
    'is_correct',v_correct
  );
end;
$function$;
