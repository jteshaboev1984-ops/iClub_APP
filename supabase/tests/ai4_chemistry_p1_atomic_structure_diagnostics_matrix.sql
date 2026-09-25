\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_bad integer;
BEGIN
  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id in (1909,1914,1916,1921,1925,1929,1933,1943,1959,3041,3044)
    and quality_status='published';

  if v_bad<>44 then
    raise exception 'AI-4 Chemistry Atomic MCQ mapping count incorrect: %',v_bad;
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
    where q.id in (1909,1914,1916,1921,1925,1929,1933,1943,1959,3041,3044)
    group by q.id
  ) x
  where mapping_count<>4 or correct_count<>1 or localized_wrong_count<>3;

  if v_bad<>0 then
    raise exception 'AI-4 Chemistry Atomic MCQ diagnostics incomplete: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics d
  join public.questions q on q.id=d.question_id
  where q.id in (1909,1914,1916,1921,1925,1929,1933,1943,1959,3041,3044)
    and d.quality_status='published'
    and (upper(trim(d.answer_key))=upper(trim(q.correct_answer))) is distinct from d.is_correct;

  if v_bad<>0 then
    raise exception 'AI-4 Chemistry Atomic MCQ correctness disagrees with server answer key: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id in (1944,1954,1964,3043)
    and quality_status='published'
    and answer_kind='input_exact'
    and is_correct=true;

  if v_bad<>4 then
    raise exception 'AI-4 Chemistry Atomic exact input mappings missing: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics d
  join public.questions q on q.id=d.question_id
  where q.id in (1944,1954,1964,3043)
    and d.quality_status='published'
    and d.answer_kind='input_exact'
    and public.iclub_normalize_answer(d.answer_value)=public.iclub_normalize_answer(q.correct_answer);

  if v_bad<>4 then
    raise exception 'AI-4 Chemistry Atomic exact input values disagree with server answers: %',v_bad;
  end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics
  where question_id in (1944,1954,1964,3043)
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

  if v_bad<>4 then
    raise exception 'AI-4 Chemistry Atomic fallback input mappings incomplete: %',v_bad;
  end if;
END
$$;

SET LOCAL ROLE service_role;

DO $$
DECLARE
  v jsonb;
  s jsonb;
  p jsonb;
BEGIN
  v:=public.get_practice_ai_coverage_snapshot_service_v1('chemistry');

  if jsonb_array_length(v->'subjects')<>1 or jsonb_array_length(v->'pools')<>1 then
    raise exception 'AI-4 Chemistry Atomic diagnostic coverage shape incorrect: %',v;
  end if;

  s:=v->'subjects'->0;
  p:=v->'pools'->0;

  if (s->>'total_questions')::int<>15
     or (s->>'source_any_all_locales_questions')::int<>15
     or (s->>'source_precise_all_locales_questions')::int<>15
     or (s->>'deterministic_diagnosis_questions')::int<>15
     or (s->>'diagnostic_any_source_ready_questions')::int<>15
     or (s->>'diagnostic_precise_source_ready_questions')::int<>15 then
    raise exception 'AI-4 Chemistry Atomic diagnostic coverage incorrect: %',s;
  end if;

  if (p->>'total_questions')::int<>15
     or (p->>'deterministic_diagnosis_questions')::int<>15
     or (p->>'diagnostic_precise_source_ready_questions')::int<>15 then
    raise exception 'AI-4 Chemistry Atomic diagnostic pool coverage incorrect: %',p;
  end if;
END
$$;

RESET ROLE;

ROLLBACK;

\echo 'AI-4 Chemistry Practice 1 Atomic structure diagnostic matrix: GREEN'
