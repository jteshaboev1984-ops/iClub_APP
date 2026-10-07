-- Mathematics Practice v2 deterministic feedback/finalization regression
-- Run after 20261007006700_math_practice_v2_deterministic_feedback_v5.sql.

do $$
declare
  v_oid oid;
  v_def text;
begin
  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='submit_practice_session_answer_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_session_id bigint, p_question_id bigint, p_user_answer text, p_picked_index integer, p_time_spent integer'
  limit 1;

  if v_oid is null then
    raise exception 'practice_submit_v5_missing';
  end if;
  if not has_function_privilege('authenticated',v_oid,'execute') then
    raise exception 'practice_submit_v5_not_executable_by_authenticated';
  end if;
  if has_function_privilege('anon',v_oid,'execute') then
    raise exception 'practice_submit_v5_exposed_to_anon';
  end if;

  v_def:=pg_get_functiondef(v_oid);
  if position('question_not_in_session' in v_def)=0
     or position('iclub_eval_practice_question_safe_v4' in v_def)=0
     or position('practice_match_answer_diagnostic_v5' in v_def)=0
     or position('diagnostic_status' in v_def)=0 then
    raise exception 'practice_submit_v5_missing_deterministic_contract';
  end if;

  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='submit_practice_drill_answer_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_session_id bigint, p_question_id bigint, p_user_answer text, p_picked_index integer, p_time_spent integer'
  limit 1;

  if v_oid is null then
    raise exception 'practice_drill_submit_v5_missing';
  end if;
  if has_function_privilege('anon',v_oid,'execute') then
    raise exception 'practice_drill_submit_v5_exposed_to_anon';
  end if;

  v_def:=pg_get_functiondef(v_oid);
  if position('question_not_in_drill_session' in v_def)=0
     or position('practice_match_answer_diagnostic_v5' in v_def)=0 then
    raise exception 'practice_drill_submit_v5_missing_deterministic_contract';
  end if;

  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='finalize_practice_session_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_session_id bigint, p_total_time integer'
  limit 1;

  if v_oid is null then
    raise exception 'practice_finalize_v5_missing';
  end if;
  if not has_function_privilege('authenticated',v_oid,'execute') then
    raise exception 'practice_finalize_v5_not_executable_by_authenticated';
  end if;
  if has_function_privilege('anon',v_oid,'execute') then
    raise exception 'practice_finalize_v5_exposed_to_anon';
  end if;

  v_def:=pg_get_functiondef(v_oid);
  if position('practice_session_answers_v4' in v_def)=0
     or position('insert into public.practice_attempts' in lower(v_def))=0
     or position('insert into public.practice_answers' in lower(v_def))=0
     or position('insert into public.user_answer_diagnosis' in lower(v_def))=0 then
    raise exception 'practice_finalize_v5_missing_server_evidence_persistence';
  end if;

  if position('submit_practice_attempt' in v_def)>0 then
    raise exception 'practice_finalize_v5_must_not_re_evaluate_through_legacy_submit';
  end if;

  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='get_practice_review_full_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_attempt_id bigint'
  limit 1;

  if v_oid is null then
    raise exception 'practice_review_v5_missing';
  end if;
  if not has_function_privilege('authenticated',v_oid,'execute') then
    raise exception 'practice_review_v5_not_executable_by_authenticated';
  end if;
  if has_function_privilege('anon',v_oid,'execute') then
    raise exception 'practice_review_v5_exposed_to_anon';
  end if;

  v_def:=pg_get_functiondef(v_oid);
  if position('pa.user_id=auth.uid()' in replace(v_def,' ',''))=0
     or position('user_answer_diagnosis' in v_def)=0
     or position('diagnostic_status' in v_def)=0
     or position('iclub_practice_drill_question_protected_v4' in v_def)=0 then
    raise exception 'practice_review_v5_missing_owned_diagnostic_review_contract';
  end if;

  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='get_practice_session_diagnostic_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_session_id bigint, p_question_id bigint'
  limit 1;

  if v_oid is null then
    raise exception 'practice_session_diagnostic_v5_missing';
  end if;

  v_def:=pg_get_functiondef(v_oid);
  if position('practice_session_answers_v4' in v_def)=0
     or position('s.user_id=v_uid' in replace(v_def,' ',''))=0
     or position('practice_match_answer_diagnostic_v5' in v_def)=0 then
    raise exception 'practice_session_diagnostic_v5_missing_answered_owned_gate';
  end if;
end;
$$;
