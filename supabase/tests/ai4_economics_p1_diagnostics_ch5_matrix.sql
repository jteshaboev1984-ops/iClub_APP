\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_bad integer;
  v_sentinel integer;
BEGIN
  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id=1090
    and quality_status='published';
  if v_bad<>4 then
    raise exception 'AI-4 Chapter 5 q1090 mapping count incorrect: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id=1090
    and quality_status='published'
    and is_correct=true;
  if v_bad<>1 then
    raise exception 'AI-4 Chapter 5 q1090 correct mapping count incorrect: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id=1090
    and quality_status='published'
    and is_correct=false
    and (
      nullif(mistake_type,'') is null
      or nullif(weak_skill,'') is null
      or nullif(feedback_ru,'') is null
      or nullif(feedback_uz,'') is null
      or nullif(feedback_en,'') is null
      or nullif(next_action_ru,'') is null
      or nullif(next_action_uz,'') is null
      or nullif(next_action_en,'') is null
    );
  if v_bad<>0 then
    raise exception 'AI-4 Chapter 5 q1090 localized wrong mapping contract failed: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id=1116
    and quality_status='published'
    and answer_kind='input_exact'
    and answer_value='2'
    and is_correct=true;
  if v_bad<>1 then
    raise exception 'AI-4 Chapter 5 q1116 exact correct mapping missing: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id=1116
    and quality_status='published'
    and answer_kind='fallback'
    and is_correct=false
    and mistake_type='opportunity_cost_ratio_error'
    and nullif(feedback_ru,'') is not null
    and nullif(feedback_uz,'') is not null
    and nullif(feedback_en,'') is not null
    and nullif(next_action_ru,'') is not null
    and nullif(next_action_uz,'') is not null
    and nullif(next_action_en,'') is not null;
  if v_bad<>1 then
    raise exception 'AI-4 Chapter 5 q1116 fallback mapping incomplete: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics d
  join public.questions q on q.id=d.question_id
  where q.id=1090
    and d.quality_status='published'
    and (upper(trim(d.answer_key))=upper(trim(q.correct_answer))) is distinct from d.is_correct;
  if v_bad<>0 then
    raise exception 'AI-4 Chapter 5 q1090 correctness disagrees with server answer key: %',v_bad;
  end if;

  select count(*) into v_sentinel
  from public.question_answer_diagnostics
  where question_id=1102
    and quality_status='published'
    and feedback_en='existing sentinel en';
  if v_sentinel<>1 then
    raise exception 'AI-4 Chapter 5 batch mutated existing Chapter 4 diagnostics: %',v_sentinel;
  end if;
END
$$;

ROLLBACK;

\echo 'AI-4 Economics Practice 1 Chapter 5 diagnostic matrix: GREEN'
