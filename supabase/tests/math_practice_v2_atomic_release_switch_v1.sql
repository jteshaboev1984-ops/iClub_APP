-- Mathematics Practice v2 reset / publish / cleanup regression.
-- Run after 20261007007500_math_practice_v2_atomic_release_switch_v1.sql.
-- Definition-only test: it does not publish, reset, roll back or clean learner data.

do $$
declare
  v_publish oid;
  v_rollback oid;
  v_cleanup oid;
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
     or position('old_question_ids' in v_def)=0
     or position('new_membership_ids' in v_def)=0
     or position('practice_reset_then_v2_publish' in v_def)=0
     or position('delete from public.practice_sessions_v4' in lower(v_def))=0
     or position('delete from public.practice_drill_sessions_v4' in lower(v_def))=0
     or position('delete from public.user_answer_diagnosis' in lower(v_def))=0
     or position('delete from public.practice_review_events_v1' in lower(v_def))=0
     or position('delete from public.recommendations' in lower(v_def))=0
     or position('delete from public.learning_roadmaps' in lower(v_def))=0
     or position('source_type=''practice''' in lower(v_def))=0
     or position('practice_ai_diagnosis' in lower(v_def))=0
     or position('delete from public.practice_attempts' in lower(v_def))=0
     or position('release_expected_exactly_one_active_pool_per_practice' in v_def)=0
     or position('release_expected_201_staged_diagnostics' in v_def)=0
     or position('release_expected_868_staged_diagnostic_mappings' in v_def)=0
     or position('release_staged_practice_' in v_def)=0
     or position('order_not_contiguous' in v_def)=0 then
    raise exception 'practice_v2_publish_missing_reset_or_atomic_publish_gate';
  end if;

  if lower(v_def) ~ '\m(insert[[:space:]]+into|update|delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(tours|tour_questions|tour_attempts|tour_answers|tour_session_answers_v4|certificates|ratings_cache)\M' then
    raise exception 'practice_v2_publish_contains_tour_dml';
  end if;

  if position('revoke execute on function public.get_practice_session_resume_safe_v4' in lower(v_def))>0
     or position('revoke execute on function public.get_practice_drill_resume_safe_v4' in lower(v_def))>0 then
    raise exception 'practice_v2_publish_breaks_required_resume_readers';
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

  if position('rollback_not_available_after_legacy_question_cleanup' in v_def)=0
     or position('practice_progress_restored' in v_def)=0
     or position('protected_tour_invariant_changed_during_rollback' in v_def)=0
     or position('old_active_membership_ids' in v_def)=0
     or position('new_membership_ids' in v_def)=0
     or position('set is_runtime_allowed=false' in lower(v_def))=0
     or position('where release_version=p_release_version' in lower(v_def))=0 then
    raise exception 'practice_v2_rollback_missing_reset-aware_bank_restore_gate';
  end if;

  if lower(v_def) ~ '\m(insert[[:space:]]+into|update|delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(tours|tour_questions|tour_attempts|tour_answers|tour_session_answers_v4|certificates|ratings_cache)\M' then
    raise exception 'practice_v2_rollback_contains_tour_dml';
  end if;

  select p.oid into v_cleanup
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private'
    and p.proname='cleanup_math_practice_v1_questions_v1'
    and pg_get_function_identity_arguments(p.oid)='p_release_version text'
  limit 1;

  if v_cleanup is null then
    raise exception 'practice_v2_cleanup_function_missing';
  end if;

  if has_function_privilege('authenticated',v_cleanup,'execute')
     or has_function_privilege('anon',v_cleanup,'execute') then
    raise exception 'practice_v2_cleanup_function_exposed_to_learner';
  end if;

  v_def:=pg_get_functiondef(v_cleanup);

  if position('not exists(select 1 from public.tour_questions' in lower(v_def))=0
     or position('not exists(select 1 from public.tour_answers' in lower(v_def))=0
     or position('not exists(select 1 from public.tour_session_answers_v4' in lower(v_def))=0
     or position('protected_tour_invariant_changed_during_legacy_cleanup' in v_def)=0 then
    raise exception 'practice_v2_cleanup_missing_protected_reference_or_tour_gate';
  end if;

  if lower(v_def) ~ '\m(insert[[:space:]]+into|update|delete[[:space:]]+from|truncate)[[:space:]]+(public\.)?(tours|tour_questions|tour_attempts|tour_answers|tour_session_answers_v4|certificates|ratings_cache)\M' then
    raise exception 'practice_v2_cleanup_contains_tour_dml';
  end if;
end;
$$;
