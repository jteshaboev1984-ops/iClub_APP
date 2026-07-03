begin;

-- Read-only evaluator for President Tech Award hidden/demo path.
-- Limited to the selected 7 Economics pilot questions.
-- Does not write to practice_answers, tour_answers, attempts, scores or ratings.
-- Does not return correct_answer or explanations from questions.

create or replace function public.evaluate_diagnostic_demo_answer(
  p_question_id bigint,
  p_user_answer text default null,
  p_picked_index integer default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_allowed_questions constant bigint[] := array[1081,1071,1115,1135,2548,1018,1022]::bigint[];
  v_question public.questions%rowtype;
  v_selected_answer text;
  v_selected_norm text;
  v_is_correct boolean := false;
  v_diag public.question_answer_diagnostics%rowtype;
begin
  if not (p_question_id = any(v_allowed_questions)) then
    raise exception 'Question is not part of the diagnostic demo set';
  end if;

  select q.*
    into v_question
  from public.questions q
  where q.id = p_question_id
    and q.is_active is true;

  if v_question.id is null then
    raise exception 'Question not found or inactive';
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
        and d.answer_kind = 'fallback'
        and d.quality_status = 'published'
      order by d.is_correct desc, d.id
      limit 1;
    end if;
  end if;

  return jsonb_build_object(
    'question_id', p_question_id,
    'selected_answer', nullif(v_selected_answer, ''),
    'is_correct', v_is_correct,
    'feedback_ru', v_diag.feedback_ru,
    'feedback_uz', v_diag.feedback_uz,
    'feedback_en', v_diag.feedback_en,
    'weak_skill', v_diag.weak_skill,
    'mistake_type', v_diag.mistake_type,
    'next_action_ru', v_diag.next_action_ru,
    'next_action_uz', v_diag.next_action_uz,
    'next_action_en', v_diag.next_action_en,
    'recommended_topic', v_diag.recommended_topic,
    'recommended_subtopic', v_diag.recommended_subtopic
  );
end;
$function$;

revoke all on function public.evaluate_diagnostic_demo_answer(bigint, text, integer) from public;
grant execute on function public.evaluate_diagnostic_demo_answer(bigint, text, integer) to anon;
grant execute on function public.evaluate_diagnostic_demo_answer(bigint, text, integer) to authenticated;

commit;
