-- Disposable isolated PostgreSQL 17 only. Executes transactions against synthetic IDs.
-- Source expected: fixture, then candidate definition, then this test.
do $test$
declare
  v_release text := 'math_p1_practice_v2_fix_20261120';
  v_pairs jsonb := jsonb_build_array(
    jsonb_build_object('old_id',1001,'new_id',2001,'old_hash',repeat('a',64),'new_hash',repeat('c',64)),
    jsonb_build_object('old_id',1002,'new_id',2002,'old_hash',repeat('b',64),'new_hash',repeat('d',64))
  );
  v_bad jsonb;
  v_result jsonb;
  v_old_text text;
  v_old_key text;
  v_old_session bigint[];
  v_old_answers jsonb;
  v_old_drill_answers jsonb;
begin
  if has_function_privilege('authenticated',
    'private.math_practice_future_only_activate_v1(text,jsonb)'::regprocedure,'execute')
   or has_function_privilege('anon',
    'private.math_practice_future_only_activate_v1(text,jsonb)'::regprocedure,'execute')
   or has_function_privilege('authenticated',
    'private.math_practice_future_only_rollback_v1(text,jsonb)'::regprocedure,'execute')
   or has_function_privilege('anon',
    'private.math_practice_future_only_rollback_v1(text,jsonb)'::regprocedure,'execute')
  then raise exception 'student_has_patch_access'; end if;

  select question_text,correct_answer into v_old_text,v_old_key
    from public.questions where id=1001;
  select question_ids into v_old_session from public.practice_sessions_v4 where id=7001;
  select jsonb_agg(to_jsonb(a)) into v_old_answers
    from public.practice_session_answers_v4 a where session_id=7001;
  select jsonb_agg(to_jsonb(a)) into v_old_drill_answers
    from public.practice_drill_answers_v4 a where session_id=7101;

  -- Second item hash drift must roll back the first item's attempted changes.
  v_bad:=jsonb_build_array(v_pairs->0,
    jsonb_set(v_pairs->1,'{old_hash}',to_jsonb(repeat('e',64))));
  begin
    perform private.math_practice_future_only_activate_v1(v_release,v_bad);
    raise exception 'stale_old_hash_was_not_rejected';
  exception
    when raise_exception then
      if SQLERRM='stale_old_hash_was_not_rejected' then raise; end if;
  end;
  if (select count(*) from public.practice_pool_questions
      where is_active=true and question_id in (1001,1002))<>2
     or (select count(*) from public.practice_pool_questions
      where is_active=true and question_id in (2001,2002))<>0
     or (select count(*) from public.question_version_links)<>0
     or (select count(*) from public.questions where id in (2001,2002)
       and is_active=false and quality_status='draft')<>2
  then raise exception 'partial_publish_after_rejected_second_item'; end if;

  v_result:=private.math_practice_future_only_activate_v1(v_release,v_pairs);
  if v_result->>'ok'<>'true' or (v_result->>'replaced')::int<>2
   then raise exception 'activate_result_mismatch'; end if;
  if (select count(*) from public.practice_pool_questions
      where is_active and question_id in (1001,1002))<>0
     or (select count(*) from public.practice_pool_questions
      where is_active and question_id in (2001,2002))<>2
     or (select count(*) from public.questions
      where id in (1001,1002,2001,2002) and is_active=true)<>4
     or (select count(*) from private.practice_v2_question_meta
      where question_id in (2001,2002) and is_runtime_allowed=true
        and lifecycle_state='published')<>2
     or (select count(*) from public.question_version_links
      where link_type='replacement' and reason=v_release)<>2
     or (select count(*) from public.question_answer_diagnostics
      where question_id=2002 and quality_status='published')<>1
     or (select count(*) from public.practice_pool_questions
      where question_id=3001 and is_active=true)<>1
     or (select count(*) from public.tour_questions where question_id=4001)<>1
  then raise exception 'post_activation_visibility_or_scope_failed'; end if;

  -- An authenticated learner can still finish an OLD issued question:
  -- q.is_active and original answer/historical session remain unchanged.
  if (select question_text from public.questions where id=1001)<>v_old_text
    or (select correct_answer from public.questions where id=1001)<>v_old_key
    or (select question_ids from public.practice_sessions_v4 where id=7001)<>v_old_session
    or (select jsonb_agg(to_jsonb(a)) from public.practice_session_answers_v4 a
        where session_id=7001) is distinct from v_old_answers
    or (select jsonb_agg(to_jsonb(a)) from public.practice_drill_answers_v4 a
        where session_id=7101) is distinct from v_old_drill_answers
  then raise exception 'old_session_or_answer_history_mutated'; end if;

  -- New session after publication can get only the new active pool members.
  insert into public.practice_sessions_v4 values
    (7002,'cccccccc-cccc-4ccc-8ccc-cccccccccccc',5,array[2001,2002],'in_progress');
  insert into public.practice_session_answers_v4(session_id,question_id,user_answer,is_correct)
    values(7002,2001,'4',true);
  if not exists(select 1 from public.practice_session_answers_v4
    where session_id=7002 and question_id=2001) then
    raise exception 'new_session_answer_not_recorded'; end if;

  -- Reapplying an already linked transition is not idempotent and must reject.
  begin
    perform private.math_practice_future_only_activate_v1(v_release,v_pairs);
    raise exception 'duplicate_activation_was_accepted';
  exception
    when raise_exception then
      if SQLERRM='duplicate_activation_was_accepted' then raise; end if;
  end;

  -- Wrong rollback fingerprint must not partially restore old membership.
  begin
    perform private.math_practice_future_only_rollback_v1(v_release,
      jsonb_build_array(v_pairs->0,
        jsonb_set(v_pairs->1,'{new_hash}',to_jsonb(repeat('e',64)))));
    raise exception 'stale_rollback_hash_was_accepted';
  exception
    when raise_exception then
      if SQLERRM='stale_rollback_hash_was_accepted' then raise; end if;
  end;
  if (select count(*) from public.practice_pool_questions
       where question_id in (2001,2002) and is_active)<>2 then
    raise exception 'partial_rollback_after_rejected_second_item'; end if;

  v_result:=private.math_practice_future_only_rollback_v1(v_release,v_pairs);
  if v_result->>'ok'<>'true'
    or (v_result->>'restored_old_memberships')::int<>2
    or (select count(*) from public.practice_pool_questions
        where question_id in (1001,1002) and is_active)<>2
    or (select count(*) from public.practice_pool_questions
        where question_id in (2001,2002) and is_active)<>0
    or (select count(*) from public.questions
        where id in (1001,1002,2001,2002) and is_active)<>4
    or (select count(*) from public.question_version_links)<>2
    or (select count(*) from public.practice_session_answers_v4
        where session_id=7002 and question_id=2001)<>1
    or (select jsonb_agg(to_jsonb(a)) from public.practice_session_answers_v4 a
        where session_id=7001) is distinct from v_old_answers
    or (select jsonb_agg(to_jsonb(a)) from public.practice_drill_answers_v4 a
        where session_id=7101) is distinct from v_old_drill_answers
    or (select count(*) from public.tour_questions where question_id=4001)<>1
    or (select count(*) from public.practice_pool_questions
        where question_id=3001 and is_active)<>1
  then raise exception 'non_destructive_rollback_invariant_failed'; end if;

  raise notice 'PASS future-only PG17: 2 distinct paired versions, atomic stale-hash abort, publish, old/new sessions, non-destructive rollback, protected Tours and chemistry';
end $test$;
