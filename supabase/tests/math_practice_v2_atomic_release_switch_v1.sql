-- Mathematics Practice v2 atomic release switch regression
-- Run after 20261007007500_math_practice_v2_atomic_release_switch_v1.sql.
-- This test inspects definitions only; it does not publish or roll back the bank.

do $$
declare
  v_publish oid;
  v_rollback oid;
  v_def text;
begin
  select p.oid into v_publish
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private'
    and p.proname='publish_math_practice_v2_release_v1'
    and pg_get_function_identity_arguments(p.oid)='p_release_version text'
  limit 1;

  if v_publish is null then
    raise exception 'practice_v2_publish_function_missing';
  end if;

  if has_function_privilege('authenticated',v_publish,'execute')
     or has_function_privilege('anon',v_publish,'execute') then
    raise exception 'practice_v2_publish_function_exposed_to_learner';
  end if;

  v_def:=pg_get_functiondef(v_publish);

  if position('practice_v2_tour_invariant_snapshot_v1' in v_def)=0
     or position('protected_tour_invariant_changed_during_release' in v_def)=0
     or position('old_active_membership_ids' in v_def)=0
     or position('new_membership_ids' in v_def)=0
     or position('set is_active=false' in replace(lower(v_def),' ',' '))=0
     or position('set is_active=true' in replace(lower(v_def),' ',' '))=0 then
    raise exception 'practice_v2_publish_missing_atomic_membership_or_tour_gate';
  end if;

  if lower(v_def) ~ '\m(insert[[:space:]]+into|update|delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(tours|tour_questions|tour_attempts|tour_answers|tour_session_answers_v4)\M' then
    raise exception 'practice_v2_publish_contains_tour_dml';
  end if;

  if lower(v_def) ~ '\m(delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(practice_attempts|practice_answers|practice_sessions_v4|practice_session_answers_v4|practice_drill_sessions_v4|practice_drill_answers_v4|user_answer_diagnosis)\M' then
    raise exception 'practice_v2_publish_contains_practice_history_delete';
  end if;

  select p.oid into v_rollback
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private'
    and p.proname='rollback_math_practice_v2_release_v1'
    and pg_get_function_identity_arguments(p.oid)='p_release_version text'
  limit 1;

  if v_rollback is null then
    raise exception 'practice_v2_rollback_function_missing';
  end if;

  if has_function_privilege('authenticated',v_rollback,'execute')
     or has_function_privilege('anon',v_rollback,'execute') then
    raise exception 'practice_v2_rollback_function_exposed_to_learner';
  end if;

  v_def:=pg_get_functiondef(v_rollback);

  if position('rollback_tour_snapshot_before' in v_def)=0
     or position('rollback_tour_snapshot_after' in v_def)=0
     or position('protected_tour_invariant_changed_during_rollback' in v_def)=0
     or position('old_active_membership_ids' in v_def)=0
     or position('new_membership_ids' in v_def)=0 then
    raise exception 'practice_v2_rollback_missing_membership_or_tour_gate';
  end if;

  if lower(v_def) ~ '\m(insert[[:space:]]+into|update|delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(tours|tour_questions|tour_attempts|tour_answers|tour_session_answers_v4)\M' then
    raise exception 'practice_v2_rollback_contains_tour_dml';
  end if;

  if lower(v_def) ~ '\m(delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(practice_attempts|practice_answers|practice_sessions_v4|practice_session_answers_v4|practice_drill_sessions_v4|practice_drill_answers_v4|user_answer_diagnosis)\M' then
    raise exception 'practice_v2_rollback_contains_practice_history_delete';
  end if;
end;
$$;
