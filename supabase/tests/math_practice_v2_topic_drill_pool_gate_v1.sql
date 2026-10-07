-- Mathematics Practice v2 topic-drill pool gate regression
-- Run after metadata foundation + 20261007005000_math_practice_v2_topic_drill_pool_gate_v1.sql.

do $$
declare
  v_oid oid;
  v_def text;
begin
  select p.oid
  into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='start_practice_topic_drill_safe_v5'
    and pg_get_function_identity_arguments(p.oid)='p_subject_key text, p_topic text, p_subtopic text, p_client_session_id text'
  limit 1;

  if v_oid is null then
    raise exception 'topic_drill_v5_missing';
  end if;

  if not has_function_privilege('authenticated',v_oid,'execute') then
    raise exception 'topic_drill_v5_not_executable_by_authenticated';
  end if;

  if has_function_privilege('anon',v_oid,'execute') then
    raise exception 'topic_drill_v5_exposed_to_anon';
  end if;

  v_def := pg_get_functiondef(v_oid);

  if position('practice_pool_questions' in v_def)=0
     or position('practice_pools' in v_def)=0 then
    raise exception 'topic_drill_v5_missing_pool_membership_gate';
  end if;

  if position('practice_v2_question_meta' in v_def)=0
     or position('is_runtime_allowed' in v_def)=0
     or position('lifecycle_state' in v_def)=0
     or position('(not v_is_math or v_allow_legacy_math) and m.question_id is null' in lower(v_def))=0
     or position('v_allow_legacy_math' in v_def)=0
     or position('math_p1_practice_v2_2026_10_07' in v_def)=0 then
    raise exception 'topic_drill_v5_missing_v2_runtime_gate';
  end if;

  if position('iclub_practice_drill_question_protected_v4' in v_def)=0 then
    raise exception 'topic_drill_v5_missing_tour_protection_gate';
  end if;
end;
$$;
