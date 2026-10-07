-- Mathematics Practice v2 current-bank mistake flow regression
-- Run after 20261007006500_math_practice_v2_current_mistakes_v5.sql.

do $$
declare
  v_recent oid;
  v_drill oid;
  v_def text;
begin
  select p.oid into v_recent
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='get_recent_practice_mistakes_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_subject_key text, p_topic text, p_subtopic text, p_limit integer'
  limit 1;

  if v_recent is null then
    raise exception 'recent_mistakes_v5_missing';
  end if;
  if not has_function_privilege('authenticated',v_recent,'execute') then
    raise exception 'recent_mistakes_v5_not_executable_by_authenticated';
  end if;
  if has_function_privilege('anon',v_recent,'execute') then
    raise exception 'recent_mistakes_v5_exposed_to_anon';
  end if;

  v_def:=pg_get_functiondef(v_recent);
  if position('practice_pool_questions' in v_def)=0
     or position('ppq.is_active is true' in v_def)=0
     or position('practice_v2_question_meta' in v_def)=0
     or position('is_runtime_allowed' in v_def)=0
     or position('not v_is_math and m.question_id is null' in lower(v_def))=0 then
    raise exception 'recent_mistakes_v5_missing_current_bank_gate';
  end if;

  select p.oid into v_drill
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='start_practice_mistakes_drill_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_subject_key text, p_question_ids bigint[], p_client_session_id text'
  limit 1;

  if v_drill is null then
    raise exception 'mistakes_drill_v5_missing';
  end if;
  if not has_function_privilege('authenticated',v_drill,'execute') then
    raise exception 'mistakes_drill_v5_not_executable_by_authenticated';
  end if;
  if has_function_privilege('anon',v_drill,'execute') then
    raise exception 'mistakes_drill_v5_exposed_to_anon';
  end if;

  v_def:=pg_get_functiondef(v_drill);
  if position('practice_pool_questions' in v_def)=0
     or position('ppq.is_active is true' in v_def)=0
     or position('practice_v2_question_meta' in v_def)=0
     or position('is_runtime_allowed' in v_def)=0
     or position('pa.is_correct is false' in v_def)=0
     or position('iclub_practice_drill_question_protected_v4' in v_def)=0
     or position('not v_is_math and m.question_id is null' in lower(v_def))=0 then
    raise exception 'mistakes_drill_v5_missing_current_owned_mistake_gate';
  end if;
end;
$$;
