\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_bad integer;
  v_sentinel integer;
BEGIN
  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id in (1074,1075,1086,1088,1096,1097,1117)
    and quality_status='published';

  if v_bad<>28 then
    raise exception 'AI-4 Chapter 10 MCQ row count incorrect: %',v_bad;
  end if;

  select count(*) into v_bad
  from (
    select q.id,
           count(d.*) mapping_count,
           count(*) filter (where d.is_correct=true) correct_count,
           count(*) filter (
             where d.is_correct=false
               and nullif(d.mistake_type,'') is not null
               and nullif(d.weak_skill,'') is not null
               and nullif(d.feedback_ru,'') is not null
               and nullif(d.feedback_uz,'') is not null
               and nullif(d.feedback_en,'') is not null
               and nullif(d.next_action_ru,'') is not null
               and nullif(d.next_action_uz,'') is not null
               and nullif(d.next_action_en,'') is not null
           ) localized_wrong_count
    from public.questions q
    join public.question_answer_diagnostics d
      on d.question_id=q.id and d.quality_status='published'
    where q.id in (1074,1075,1086,1088,1096,1097,1117)
    group by q.id
  ) x
  where mapping_count<>4 or correct_count<>1 or localized_wrong_count<>3;

  if v_bad<>0 then
    raise exception 'AI-4 Chapter 10 MCQ diagnostics incomplete: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics d
  join public.questions q on q.id=d.question_id
  where q.id in (1074,1075,1086,1088,1096,1097,1117)
    and d.quality_status='published'
    and (upper(trim(d.answer_key))=upper(trim(q.correct_answer))) is distinct from d.is_correct;

  if v_bad<>0 then
    raise exception 'AI-4 Chapter 10 MCQ correctness disagrees with server answer key: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id in (1032,1076)
    and quality_status='published'
    and answer_kind='input_exact'
    and is_correct=true;

  if v_bad<>2 then
    raise exception 'AI-4 Chapter 10 exact input mappings missing: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id in (1032,1076)
    and quality_status='published'
    and answer_kind='fallback'
    and is_correct=false
    and nullif(mistake_type,'') is not null
    and nullif(weak_skill,'') is not null
    and nullif(feedback_ru,'') is not null
    and nullif(feedback_uz,'') is not null
    and nullif(feedback_en,'') is not null
    and nullif(next_action_ru,'') is not null
    and nullif(next_action_uz,'') is not null
    and nullif(next_action_en,'') is not null;

  if v_bad<>2 then
    raise exception 'AI-4 Chapter 10 fallback input mappings incomplete: %',v_bad;
  end if;

  select count(*) into v_sentinel
  from public.question_answer_diagnostics
  where question_id=1087
    and quality_status='published'
    and feedback_en='existing sentinel en';

  if v_sentinel<>1 then
    raise exception 'AI-4 Chapter 10 batch mutated Chapter 9 sentinel: %',v_sentinel;
  end if;
END
$$;

ROLLBACK;

\echo 'AI-4 Economics Practice 1 Chapter 10 diagnostic matrix: GREEN'
