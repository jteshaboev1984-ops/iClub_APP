\set ON_ERROR_STOP on
BEGIN;
DO $$
DECLARE v_total integer; v_bad integer; v_sentinel integer;
BEGIN
  select count(*) into v_total from public.question_answer_diagnostics
  where question_id in (1100,1111,1123,1124) and quality_status='published';
  if v_total<>16 then raise exception 'AI-4 Chapter 6 diagnostic row count incorrect: %',v_total; end if;

  select count(*) into v_bad from (
    select q.id,count(d.*) mapping_count,
      count(*) filter (where d.is_correct) correct_count,
      count(*) filter (where not d.is_correct
        and nullif(d.mistake_type,'') is not null and nullif(d.weak_skill,'') is not null
        and nullif(d.feedback_ru,'') is not null and nullif(d.feedback_uz,'') is not null and nullif(d.feedback_en,'') is not null
        and nullif(d.next_action_ru,'') is not null and nullif(d.next_action_uz,'') is not null and nullif(d.next_action_en,'') is not null
      ) wrong_localized
    from public.questions q join public.question_answer_diagnostics d on d.question_id=q.id and d.quality_status='published'
    where q.id in (1100,1111,1123,1124) group by q.id
  ) x where mapping_count<>4 or correct_count<>1 or wrong_localized<>3;
  if v_bad<>0 then raise exception 'AI-4 Chapter 6 diagnostics incomplete: %',v_bad; end if;

  select count(*) into v_bad
  from public.question_answer_diagnostics d join public.questions q on q.id=d.question_id
  where q.id in (1100,1111,1123,1124) and d.quality_status='published'
    and (upper(trim(d.answer_key))=upper(trim(q.correct_answer))) is distinct from d.is_correct;
  if v_bad<>0 then raise exception 'AI-4 Chapter 6 correctness disagrees with server answer key: %',v_bad; end if;

  select count(*) into v_sentinel from public.question_answer_diagnostics
  where question_id=1090 and quality_status='published' and feedback_en='existing sentinel en';
  if v_sentinel<>1 then raise exception 'AI-4 Chapter 6 mutated Chapter 5 sentinel: %',v_sentinel; end if;
END $$;
ROLLBACK;
\echo 'AI-4 Economics Practice 1 Chapter 6 diagnostic matrix: GREEN'
