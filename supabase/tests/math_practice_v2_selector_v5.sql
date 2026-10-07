-- Mathematics Practice v2 selector v5 regression
-- Run after metadata foundation + 20261007006000_math_practice_v2_selector_v5.sql.

do $$
declare
  v_oid oid;
  v_def text;
begin
  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='start_practice_session_auto_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_pool_id bigint, p_client_session_id text'
  limit 1;

  if v_oid is null then
    raise exception 'practice_selector_v5_missing';
  end if;

  if not has_function_privilege('authenticated',v_oid,'execute') then
    raise exception 'practice_selector_v5_not_executable_by_authenticated';
  end if;

  if has_function_privilege('anon',v_oid,'execute') then
    raise exception 'practice_selector_v5_exposed_to_anon';
  end if;

  v_def := pg_get_functiondef(v_oid);

  if position('practice_v2_question_meta' in v_def)=0
     or position('is_runtime_allowed' in v_def)=0
     or position('lifecycle_state' in v_def)=0
     or position('not v_is_math and m.question_id is null' in lower(v_def))=0
     or position('practice_v2_cutover_pending' in v_def)=0 then
    raise exception 'practice_selector_v5_missing_runtime_metadata_gate';
  end if;

  if position('wrong_skill' in v_def)=0
     or position('role_seen' in v_def)=0
     or position('exact_wrong_count' in v_def)=0 then
    raise exception 'practice_selector_v5_missing_learning_history_priority';
  end if;

  if position('row_number() over' in lower(v_def))=0
     or position('partition by skill_code' in lower(v_def))=0 then
    raise exception 'practice_selector_v5_missing_skill_round_robin';
  end if;

  if position('transfer_score' in v_def)=0 then
    raise exception 'practice_selector_v5_missing_transfer_priority';
  end if;

  if position('practice_pool_locked' in v_def)=0
     or position('practice_pool_not_published' in v_def)=0 then
    raise exception 'practice_selector_v5_missing_tour_lock_contract';
  end if;

  if position('pa.is_correct is true' in v_def)=0 then
    raise exception 'practice_selector_v5_missing_already_correct_exclusion';
  end if;
end;
$$;
