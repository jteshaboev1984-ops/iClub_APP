begin;

-- Fix only the new President Tech Award diagnostic RPC.
-- Existing legacy app flow is not touched.
-- The previous version could find input_tolerance/input_pattern diagnostics
-- but did not promote v_is_correct from the matched rule.

create or replace function public.submit_practice_answer_safe(
  p_attempt_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_time_spent integer default 0,
  p_picked_index integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid;
  v_subject_id bigint;
  v_question public.questions%rowtype;
  v_selected_answer text;
  v_selected_norm text;
  v_correct_norm text;
  v_is_correct boolean := false;
  v_practice_answer_id bigint;
  v_diag public.question_answer_diagnostics%rowtype;
  v_score integer := 0;
  v_answered integer := 0;
  v_percent numeric := 0;
begin
  v_uid := auth.uid();

  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select pa.subject_id
    into v_subject_id
  from public.practice_attempts pa
  where pa.id = p_attempt_id
    and pa.user_id = v_uid;

  if v_subject_id is null then
    raise exception 'Practice attempt not found or not owned by current user';
  end if;

  select q.*
    into v_question
  from public.questions q
  where q.id = p_question_id
    and q.is_active is true;

  if v_question.id is null then
    raise exception 'Question not found or inactive';
  end if;

  if v_question.subject_id <> v_subject_id then
    raise exception 'Question subject does not match practice attempt subject';
  end if;

  if v_question.qtype = 'mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected_answer := chr(65 + p_picked_index);
    else
      v_selected_answer := upper(trim(coalesce(p_user_answer, '')));
    end if;

    v_is_correct := (
      upper(trim(v_selected_answer)) = upper(trim(coalesce(v_question.correct_answer, '')))
      or public.iclub_normalize_answer(v_selected_answer) = public.iclub_normalize_answer(v_question.correct_answer)
    );

    select d.*
      into v_diag
    from public.question_answer_diagnostics d
    where d.question_id = p_question_id
      and d.answer_kind = 'mcq_option'
      and upper(trim(coalesce(d.answer_key, d.answer_value, ''))) = upper(trim(v_selected_answer))
      and d.quality_status = 'published'
    order by d.is_correct desc, d.id
    limit 1;

  else
    v_selected_answer := trim(coalesce(p_user_answer, ''));
    v_selected_norm := public.iclub_normalize_answer(v_selected_answer);
    v_correct_norm := public.iclub_normalize_answer(v_question.correct_answer);

    v_is_correct := exists (
      select 1
      from regexp_split_to_table(coalesce(v_question.correct_answer, ''), '\|') as accepted_answer
      where public.iclub_normalize_answer(accepted_answer) = v_selected_norm
    );

    if not v_is_correct
       and public.iclub_is_numeric(v_selected_answer)
       and public.iclub_is_numeric(v_question.correct_answer) then
      v_is_correct := (
        replace(v_selected_answer, ',', '.')::numeric = replace(v_question.correct_answer, ',', '.')::numeric
      );
    end if;

    select d.*
      into v_diag
    from public.question_answer_diagnostics d
    where d.question_id = p_question_id
      and d.answer_kind = 'input_exact'
      and d.quality_status = 'published'
      and public.iclub_normalize_answer(coalesce(d.answer_value, d.answer_key, '')) = v_selected_norm
    order by d.is_correct desc, d.id
    limit 1;

    if v_diag.id is not null then
      v_is_correct := coalesce(v_diag.is_correct, v_is_correct);
    end if;

    if v_diag.id is null and public.iclub_is_numeric(v_selected_answer) then
      select d.*
        into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = p_question_id
        and d.answer_kind = 'input_tolerance'
        and d.quality_status = 'published'
        and coalesce(d.rule_json->>'target', '') ~ '^-?[0-9]+([\.,][0-9]+)?$'
        and coalesce(d.rule_json->>'tolerance', '') ~ '^[0-9]+([\.,][0-9]+)?$'
        and abs(
          replace(v_selected_answer, ',', '.')::numeric
          - replace(d.rule_json->>'target', ',', '.')::numeric
        ) <= replace(d.rule_json->>'tolerance', ',', '.')::numeric
      order by d.is_correct desc, d.id
      limit 1;

      if v_diag.id is not null then
        v_is_correct := coalesce(v_diag.is_correct, v_is_correct);
      end if;
    end if;

    if v_diag.id is null then
      select d.*
        into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = p_question_id
        and d.answer_kind = 'input_pattern'
        and d.quality_status = 'published'
        and d.answer_value is not null
        and v_selected_answer ~* d.answer_value
      order by d.is_correct desc, d.id
      limit 1;

      if v_diag.id is not null then
        v_is_correct := coalesce(v_diag.is_correct, v_is_correct);
      end if;
    end if;

    if v_diag.id is null then
      select d.*
        into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = p_question_id
        and d.answer_kind = 'input_exact'
        and d.quality_status = 'published'
        and d.is_correct = v_is_correct
      order by d.is_correct desc, d.id
      limit 1;
    end if;
  end if;

  if v_diag.id is null then
    select d.*
      into v_diag
    from public.question_answer_diagnostics d
    where d.question_id = p_question_id
      and d.answer_kind = 'fallback'
      and d.quality_status = 'published'
    order by d.is_correct desc, d.id
    limit 1;
  end if;

  insert into public.practice_answers(
    attempt_id,
    question_id,
    user_answer,
    is_correct,
    time_spent
  )
  values (
    p_attempt_id,
    p_question_id,
    nullif(v_selected_answer, ''),
    v_is_correct,
    greatest(coalesce(p_time_spent, 0), 0)
  )
  on conflict (attempt_id, question_id)
  do update set
    user_answer = excluded.user_answer,
    is_correct = excluded.is_correct,
    time_spent = excluded.time_spent
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
  )
  values (
    v_uid,
    v_subject_id,
    'practice',
    p_attempt_id,
    v_practice_answer_id,
    p_question_id,
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

  select
    count(*)::integer,
    count(*) filter (where pa.is_correct is true)::integer
    into v_answered, v_score
  from public.practice_answers pa
  where pa.attempt_id = p_attempt_id;

  v_percent := case
    when v_answered > 0 then round((v_score::numeric / v_answered::numeric) * 100, 2)
    else 0
  end;

  update public.practice_attempts pa
  set
    score = v_score,
    percent = v_percent,
    time_seconds = greatest(coalesce(pa.time_seconds, 0), greatest(coalesce(p_time_spent, 0), 0))
  where pa.id = p_attempt_id
    and pa.user_id = v_uid;

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'practice_answer_id', v_practice_answer_id,
    'question_id', p_question_id,
    'selected_answer', nullif(v_selected_answer, ''),
    'is_correct', v_is_correct,
    'score', v_score,
    'answered', v_answered,
    'percent', v_percent,
    'diagnostic', jsonb_build_object(
      'diagnostic_id', v_diag.id,
      'mistake_type', v_diag.mistake_type,
      'weak_skill', v_diag.weak_skill,
      'feedback_ru', v_diag.feedback_ru,
      'feedback_uz', v_diag.feedback_uz,
      'feedback_en', v_diag.feedback_en,
      'next_action_ru', v_diag.next_action_ru,
      'next_action_uz', v_diag.next_action_uz,
      'next_action_en', v_diag.next_action_en,
      'recommended_topic', v_diag.recommended_topic,
      'recommended_subtopic', v_diag.recommended_subtopic,
      'recommended_lesson_id', v_diag.recommended_lesson_id
    )
  );
end;
$function$;

revoke all on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) from public;
revoke execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) from anon;
grant execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) to authenticated;

commit;
