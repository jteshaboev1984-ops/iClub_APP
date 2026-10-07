-- READ-ONLY schema compatibility preflight for Mathematics Practice v2.
-- Safe to run before any Practice v2 migration. It proves the current production schema
-- still matches the assumptions used by staging, v5 runtime and atomic membership switch.

begin;
set transaction read only;
set local statement_timeout='20s';

do $schema_compat$
declare
  v_count integer;
begin
  if to_regclass('public.questions') is null
     or to_regclass('public.practice_pools') is null
     or to_regclass('public.practice_pool_questions') is null
     or to_regclass('public.practice_attempts') is null
     or to_regclass('public.practice_answers') is null
     or to_regclass('public.practice_sessions_v4') is null
     or to_regclass('public.practice_session_answers_v4') is null
     or to_regclass('public.practice_drill_sessions_v4') is null
     or to_regclass('public.practice_drill_answers_v4') is null
     or to_regclass('public.question_answer_diagnostics') is null
     or to_regclass('public.user_answer_diagnosis') is null
  then
    raise exception 'practice_v2_required_table_missing';
  end if;

  select count(*) into v_count
  from information_schema.columns
  where table_schema='public'
    and table_name='questions'
    and column_name in (
      'id','subject_id','topic','subtopic','difficulty','qtype',
      'question_text','question_text_ru','question_text_uz','question_text_en',
      'options_text','options_text_ru','options_text_uz','options_text_en',
      'correct_answer','explanation','explanation_ru','explanation_uz','explanation_en',
      'book_ref','time_limit_sec','is_active','quality_status'
    );

  if v_count<>22 then
    raise exception 'practice_v2_questions_column_contract_drift_%',v_count;
  end if;

  if not exists(
    select 1 from pg_constraint
    where conrelid='public.practice_pool_questions'::regclass
      and contype='u'
      and pg_get_constraintdef(oid)='UNIQUE (pool_id, question_id)'
  ) then
    raise exception 'practice_v2_pool_question_uniqueness_missing';
  end if;

  if exists(
    select 1 from pg_constraint
    where conrelid='public.practice_pool_questions'::regclass
      and contype='u'
      and pg_get_constraintdef(oid) ilike '%order_no%'
  ) then
    raise exception 'practice_v2_pool_order_no_unexpected_unique_constraint';
  end if;

  if not exists(
    select 1 from pg_constraint
    where conrelid='public.questions'::regclass
      and conname='questions_qtype_check'
      and pg_get_constraintdef(oid) ilike '%mcq%'
      and pg_get_constraintdef(oid) ilike '%input%'
  ) then
    raise exception 'practice_v2_questions_qtype_contract_drift';
  end if;

  if not exists(
    select 1 from pg_constraint
    where conrelid='public.questions'::regclass
      and conname='questions_quality_status_check'
      and pg_get_constraintdef(oid) ilike '%draft%'
      and pg_get_constraintdef(oid) ilike '%published%'
  ) then
    raise exception 'practice_v2_questions_quality_status_contract_drift';
  end if;

  if not exists(
    select 1 from pg_constraint
    where conrelid='public.question_answer_diagnostics'::regclass
      and conname='question_answer_diagnostics_answer_kind_check'
      and pg_get_constraintdef(oid) ilike '%mcq_option%'
      and pg_get_constraintdef(oid) ilike '%input_exact%'
  ) then
    raise exception 'practice_v2_diagnostic_answer_kind_contract_drift';
  end if;

  if to_regprocedure('public.iclub_eval_practice_question_safe_v4(bigint,text,integer)') is null
     or to_regprocedure('public.get_practice_session_resume_safe_v4(bigint)') is null
     or to_regprocedure('public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer)') is null
     or to_regprocedure('public.finalize_practice_session_safe_v4(bigint,integer)') is null
     or to_regprocedure('public.get_practice_drill_resume_safe_v4(bigint)') is null
     or to_regprocedure('public.submit_practice_drill_answer_safe_v4(bigint,bigint,text,integer,integer)') is null
  then
    raise exception 'practice_v2_required_v4_compatibility_function_missing';
  end if;

  select count(*) into v_count
  from public.subjects
  where subject_key='mathematics'
    and is_active is true;

  if v_count<>1 then
    raise exception 'practice_v2_expected_one_active_mathematics_subject_found_%',v_count;
  end if;

  select count(*) into v_count
  from public.practice_pools p
  join public.subjects s on s.id=p.subject_id
  where s.subject_key='mathematics'
    and s.is_active is true
    and p.is_active is true
    and p.tour_no between 1 and 7;

  if v_count<>7 then
    raise exception 'practice_v2_expected_seven_active_math_pools_found_%',v_count;
  end if;
end;
$schema_compat$;

select
  'schema_compatible'::text as status,
  now() as checked_at;

rollback;
