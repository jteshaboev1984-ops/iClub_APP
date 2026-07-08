-- Server-side practice checking hardening.
-- Safe intent:
-- - keep the existing frontend RPC name submit_practice_attempt;
-- - ignore client-sent p_score, p_percent and p_answers[].is_correct;
-- - compute correctness on the server from private questions.correct_answer;
-- - keep old attempts/results unchanged;
-- - block direct client DML into practice_attempts/practice_answers so console users cannot forge scores.

begin;

create or replace function public.submit_practice_attempt(
  p_subject_id bigint,
  p_score integer,
  p_percent numeric,
  p_time_seconds integer,
  p_answers jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt_id bigint;
  v_answer jsonb;
  v_question public.questions%rowtype;
  v_question_id bigint;
  v_user_answer text;
  v_selected_answer text;
  v_selected_norm text;
  v_picked_index integer;
  v_time_spent integer;
  v_is_correct boolean;
  v_practice_answer_id bigint;
  v_diag public.question_answer_diagnostics%rowtype;
  v_score integer := 0;
  v_answered integer := 0;
  v_percent numeric := 0;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if p_subject_id is null or p_subject_id <= 0 then
    raise exception 'invalid_subject_id' using errcode = '22023';
  end if;

  if p_answers is null or jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) = 0 then
    raise exception 'empty_answers' using errcode = '22023';
  end if;

  insert into public.practice_attempts(user_id, subject_id, score, percent, time_seconds)
  values (v_uid, p_subject_id, 0, 0, greatest(coalesce(p_time_seconds, 0), 0))
  returning id into v_attempt_id;

  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    v_question_id := nullif(v_answer->>'question_id', '')::bigint;
    v_user_answer := coalesce(v_answer->>'user_answer', '');
    v_time_spent := greatest(coalesce(nullif(v_answer->>'time_spent', '')::integer, 0), 0);
    v_picked_index := null;

    begin
      if v_answer ? 'picked_index' and nullif(v_answer->>'picked_index', '') is not null then
        v_picked_index := (v_answer->>'picked_index')::integer;
      end if;
    exception when others then
      v_picked_index := null;
    end;

    if v_question_id is null or v_question_id <= 0 then
      raise exception 'invalid_question_id' using errcode = '22023';
    end if;

    select q.* into v_question
    from public.questions q
    where q.id = v_question_id
      and q.is_active is true;

    if v_question.id is null then
      raise exception 'question_not_found_or_inactive' using errcode = 'P0002';
    end if;

    if v_question.subject_id <> p_subject_id then
      raise exception 'question_subject_mismatch' using errcode = '22023';
    end if;

    v_diag := null;
    v_selected_answer := null;
    v_selected_norm := null;
    v_is_correct := false;

    if lower(coalesce(v_question.qtype, '')) = 'mcq' then
      if v_picked_index is not null and v_picked_index between 0 and 25 then
        v_selected_answer := chr(65 + v_picked_index);
      elsif trim(v_user_answer) ~ '^[0-9]+$' and trim(v_user_answer)::integer between 0 and 25 then
        v_selected_answer := chr(65 + trim(v_user_answer)::integer);
      else
        v_selected_answer := upper(trim(coalesce(v_user_answer, '')));
      end if;

      v_is_correct := (
        upper(trim(coalesce(v_selected_answer, ''))) = upper(trim(coalesce(v_question.correct_answer, '')))
        or public.iclub_normalize_answer(v_selected_answer) = public.iclub_normalize_answer(v_question.correct_answer)
      );

      select d.* into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = v_question_id
        and d.answer_kind = 'mcq_option'
        and upper(trim(coalesce(d.answer_key, d.answer_value, ''))) = upper(trim(coalesce(v_selected_answer, '')))
        and d.quality_status = 'published'
      order by d.is_correct desc, d.id
      limit 1;
    else
      v_selected_answer := trim(coalesce(v_user_answer, ''));
      v_selected_norm := public.iclub_normalize_answer(v_selected_answer);

      v_is_correct := exists (
        select 1
        from regexp_split_to_table(coalesce(v_question.correct_answer, ''), '\|') as accepted_answer
        where public.iclub_normalize_answer(accepted_answer) = v_selected_norm
      );

      if not v_is_correct and public.iclub_is_numeric(v_selected_answer) and public.iclub_is_numeric(v_question.correct_answer) then
        v_is_correct := replace(v_selected_answer, ',', '.')::numeric = replace(v_question.correct_answer, ',', '.')::numeric;
      end if;

      select d.* into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = v_question_id
        and d.answer_kind = 'input_exact'
        and d.quality_status = 'published'
        and (
          public.iclub_normalize_answer(coalesce(d.answer_value, d.answer_key, '')) = v_selected_norm
          or d.is_correct = v_is_correct
        )
      order by d.is_correct desc, d.id
      limit 1;

      if v_diag.id is null and public.iclub_is_numeric(v_selected_answer) then
        select d.* into v_diag
        from public.question_answer_diagnostics d
        where d.question_id = v_question_id
          and d.answer_kind = 'input_tolerance'
          and d.quality_status = 'published'
          and coalesce(d.rule_json->>'target', '') ~ '^-?[0-9]+([\.,][0-9]+)?$'
          and coalesce(d.rule_json->>'tolerance', '') ~ '^[0-9]+([\.,][0-9]+)?$'
          and abs(replace(v_selected_answer, ',', '.')::numeric - replace(d.rule_json->>'target', ',', '.')::numeric)
              <= replace(d.rule_json->>'tolerance', ',', '.')::numeric
        order by d.is_correct desc, d.id
        limit 1;
      end if;

      if v_diag.id is null then
        select d.* into v_diag
        from public.question_answer_diagnostics d
        where d.question_id = v_question_id
          and d.answer_kind = 'input_pattern'
          and d.quality_status = 'published'
          and d.answer_value is not null
          and v_selected_answer ~* d.answer_value
        order by d.is_correct desc, d.id
        limit 1;
      end if;
    end if;

    if v_diag.id is null then
      select d.* into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = v_question_id
        and d.answer_kind = 'fallback'
        and d.quality_status = 'published'
      order by d.is_correct desc, d.id
      limit 1;
    end if;

    insert into public.practice_answers(attempt_id, question_id, user_answer, is_correct, time_spent)
    values (v_attempt_id, v_question_id, nullif(v_selected_answer, ''), v_is_correct, v_time_spent)
    returning id into v_practice_answer_id;

    insert into public.user_answer_diagnosis(
      user_id,
      subject_id,
      attempt_type,
      attempt_id,
      practice_answer_id,
      question_id,
      selected_answer,
      is_correct,
      diagnostic_id,
      mistake_type,
      weak_skill,
      feedback_ru,
      feedback_uz,
      feedback_en,
      next_action_ru,
      next_action_uz,
      next_action_en
    ) values (
      v_uid,
      p_subject_id,
      'practice',
      v_attempt_id,
      v_practice_answer_id,
      v_question_id,
      nullif(v_selected_answer, ''),
      v_is_correct,
      v_diag.id,
      v_diag.mistake_type,
      v_diag.weak_skill,
      v_diag.feedback_ru,
      v_diag.feedback_uz,
      v_diag.feedback_en,
      v_diag.next_action_ru,
      v_diag.next_action_uz,
      v_diag.next_action_en
    )
    on conflict (practice_answer_id) where practice_answer_id is not null
    do update set
      selected_answer = excluded.selected_answer,
      is_correct = excluded.is_correct,
      diagnostic_id = excluded.diagnostic_id,
      mistake_type = excluded.mistake_type,
      weak_skill = excluded.weak_skill,
      feedback_ru = excluded.feedback_ru,
      feedback_uz = excluded.feedback_uz,
      feedback_en = excluded.feedback_en,
      next_action_ru = excluded.next_action_ru,
      next_action_uz = excluded.next_action_uz,
      next_action_en = excluded.next_action_en;
  end loop;

  select
    count(*)::integer,
    count(*) filter (where pa.is_correct is true)::integer
  into v_answered, v_score
  from public.practice_answers pa
  where pa.attempt_id = v_attempt_id;

  v_percent := case when v_answered > 0 then round((v_score::numeric / v_answered::numeric) * 100, 2) else 0 end;

  update public.practice_attempts pa
  set score = v_score,
      percent = v_percent,
      time_seconds = greatest(coalesce(p_time_seconds, 0), 0)
  where pa.id = v_attempt_id
    and pa.user_id = v_uid;

  return v_attempt_id;
end;
$$;

comment on function public.submit_practice_attempt(bigint, integer, numeric, integer, jsonb) is
'Server-side checked practice attempt submission. Keeps legacy frontend signature but ignores client score/percent/is_correct and computes correctness from private questions.correct_answer.';

revoke all on function public.submit_practice_attempt(bigint, integer, numeric, integer, jsonb) from public, anon;
grant execute on function public.submit_practice_attempt(bigint, integer, numeric, integer, jsonb) to authenticated;

-- Close direct client writes. Practice saves must go through RPC so scores/is_correct are server-computed.
revoke insert, update, delete, truncate on public.practice_attempts from anon, authenticated;
revoke insert, update, delete, truncate on public.practice_answers from anon, authenticated;

drop policy if exists practice_attempts_rw_own on public.practice_attempts;
drop policy if exists practice_attempts_insert_own on public.practice_attempts;
drop policy if exists practice_attempts_update_own on public.practice_attempts;
drop policy if exists practice_attempts_delete_own on public.practice_attempts;

drop policy if exists practice_answers_insert_own on public.practice_answers;
drop policy if exists practice_answers_insert_owner on public.practice_answers;
drop policy if exists practice_answers_update_own on public.practice_answers;
drop policy if exists practice_answers_update_owner on public.practice_answers;
drop policy if exists practice_answers_delete_owner on public.practice_answers;

-- Keep read access to own practice history for profile, recommendations and metrics.
grant select on public.practice_attempts to authenticated;
grant select on public.practice_answers to authenticated;

commit;
