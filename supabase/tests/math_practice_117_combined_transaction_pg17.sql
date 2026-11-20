-- #574: 117 = 81+31+3+2 distinct author corrections staged as draft in
-- a DISPOSABLE PG17 database. Simulates one operator transaction with four
-- pre-existing <=81-item private functions, never widens the production limit.
-- Outputs aggregate PASS notices only. DO NOT RUN AGAINST HOSTED SUPABASE.
do $verify_combined_117$
declare
  v_release constant text:='math_p1_practice_v2_fix_20261120';
  v_group text;
  v_count integer;
  v_pairs jsonb;
  v_batches jsonb:='{}'::jsonb;
  v_result jsonb;
  v_err text;
  v_new_id bigint;
  v_old_session jsonb;
  v_old_drill jsonb;
begin
  -- Separate stage SQL transactions are completed, but absolutely nothing
  -- is selectable for new students before release authorization.
  select count(*) into v_count
    from private.practice_v2_question_meta
    where release_version=v_release;
  if v_count<>117 then raise exception 'combined_new_meta_count_not_117';end if;
  if (select count(*) from private.math_practice_117_group_fixture)<>117
      or (select count(distinct old_id) from private.math_practice_117_group_fixture)<>117
      or (select count(*) from public.question_version_links)<>0
      or (select count(*) from private.practice_v2_question_meta n
            join public.questions q on q.id=n.question_id
           where n.release_version=v_release
             and n.lifecycle_state='approved' and n.is_runtime_allowed=false
             and n.qa_math_status='pending'
             and n.qa_language_status='pending'
             and n.qa_technical_status='pending'
             and n.qa_tour_separation_status='pending'
             and q.is_active=false and q.quality_status='draft')<>117
      or (select count(*) from public.practice_pool_questions ppq
            join private.practice_v2_question_meta m on ppq.question_id=m.question_id
           where m.release_version=v_release and ppq.is_active)<>0
      or (select count(*) from public.questions q
            join private.practice_v2_question_meta m on m.question_id=q.id
            join private.math_practice_117_group_fixture f on f.old_id=q.id
           where q.is_active=true and q.quality_status='published'
             and m.is_runtime_allowed=true and m.lifecycle_state='published')<>117
   then raise exception 'combined_staging_or_original_history_not_fail_closed';end if;
  for v_group in select * from unnest(array['81','31','3','2']) loop
    select jsonb_agg(jsonb_build_object(
      'old_id',original.question_id,'new_id',staged.question_id,
      'old_hash',original.content_hash,'new_hash',staged.content_hash)
      order by original.question_id) into v_pairs
    from private.math_practice_117_group_fixture f
    join private.practice_v2_question_meta original on original.question_id=f.old_id
    join private.practice_v2_question_meta staged
      on staged.content_key=original.content_key||'-V20261120'
    where f.group_name=v_group and staged.release_version=v_release;
    if v_pairs is null
       or jsonb_array_length(v_pairs) <>
         (jsonb_build_object('81',81,'31',31,'3',3,'2',2)->>v_group)::int
       then raise exception 'missing_or_wrong_staged_group_%',v_group;end if;
    v_batches:=jsonb_set(v_batches,array[v_group],v_pairs,true);
  end loop;
  if (select count(*) from (
    select (pair.value->>'new_id')::bigint id
      from jsonb_each(v_batches) batch
     cross join lateral jsonb_array_elements(batch.value) pair
  ) versions)<>117
  then raise exception 'not_117_version_ids';end if;

  -- Add synthetic issued old-version session/answers in multiple groups,
  -- including the three known historically answered editorial corrections.
  insert into public.practice_sessions_v4(id,user_id,subject_id,question_ids,status)
   values(5117,'a1111111-1111-4111-8111-111111111117',5,
     array[7710,7714,7754,7937,7791,7970]::bigint[],'in_progress');
  insert into public.practice_session_answers_v4
     (session_id,question_id,user_answer,is_correct)
   values(5117,7714,'SYNTHETIC_OLD',true),
         (5117,7754,'SYNTHETIC_OLD',false),
         (5117,7970,'SYNTHETIC_OLD',true);
  insert into public.practice_drill_sessions_v4(id,user_id,subject_id,question_ids,status)
   values(6117,'b2222222-2222-4222-8222-222222222227',5,
     array[7710,7937,7791]::bigint[],'in_progress');
  insert into public.practice_drill_answers_v4
    (session_id,question_id,user_answer,is_correct)
   values(6117,7710,'SYNTHETIC_OLD',true),
         (6117,7937,'SYNTHETIC_OLD',false);
  select jsonb_agg(to_jsonb(a) order by a.question_id)
    into v_old_session from public.practice_session_answers_v4 a
    where a.session_id=5117;
  select jsonb_agg(to_jsonb(a) order by a.question_id)
    into v_old_drill from public.practice_drill_answers_v4 a
    where a.session_id=6117;

  -- All stage QA flags are PENDING. A first immediate publication attempt
  -- MUST be refused even for the smallest group, and without any writes.
  begin
    perform private.math_practice_future_only_activate_v1(
      v_release,v_batches->'2');
    raise exception 'pending_qa_2_item_release_wrongly_accepted';
  exception when raise_exception then
    get stacked diagnostics v_err=message_text;
    if v_err<>'future_only_version_identity_or_hash_mismatch' then
      raise exception 'unexpected_qa_gate_failure_category';end if;
  end;

  -- The one intended pass-only approval is a TEST FIXTURE change.
  -- On hosted Supabase QA statuses MUST remain pending until real approval.
  update private.practice_v2_question_meta
     set qa_math_status='passed',qa_language_status='passed',
         qa_technical_status='passed',qa_tour_separation_status='passed'
   where release_version=v_release;
  if (select count(*) from private.practice_v2_question_meta
       where release_version=v_release and qa_math_status='passed'
         and qa_language_status='passed' and qa_technical_status='passed'
         and qa_tour_separation_status='passed')<>117
    then raise exception 'test_fixture_qa_statuses_incomplete';end if;

  -- Injection failure in *LAST* group: first three groups would otherwise
  -- have switched 115 questions. One nested transaction must undo ALL 115.
  begin
    perform private.math_practice_future_only_activate_v1(v_release,v_batches->'81');
    perform private.math_practice_future_only_activate_v1(v_release,v_batches->'31');
    perform private.math_practice_future_only_activate_v1(v_release,v_batches->'3');
    perform private.math_practice_future_only_activate_v1(v_release,
      jsonb_set(v_batches->'2',array['0','old_hash'],
        to_jsonb(repeat('0',64)),false));
    raise exception 'corrupted_last_group_accepted';
  exception when raise_exception then
    get stacked diagnostics v_err=message_text;
    if v_err<>'future_only_version_identity_or_hash_mismatch' then
      raise exception 'unexpected_bundled_failure_category';end if;
  end;
  if (select count(*) from public.question_version_links)<>0
     or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=true)<>0
     or (select count(*) from public.practice_pool_questions ppq
       join private.math_practice_117_group_fixture f on f.old_id=ppq.question_id
       where ppq.is_active=true)<>117
     or (select count(*) from public.questions q
       join private.practice_v2_question_meta m on m.question_id=q.id
       where m.release_version=v_release and q.is_active=true)<>0
    then raise exception 'failed_final_group_did_not_undo_previous_115';end if;

  -- RELEASE REHEARSAL: the existing 4 calls run INSIDE ONE PG statement and
  -- transaction. The production 81-pair safety limit is UNCHANGED.
  for v_group in select * from unnest(array['81','31','3','2']) loop
    v_result:=private.math_practice_future_only_activate_v1(
      v_release,v_batches->v_group);
    if coalesce((v_result->>'replaced')::int,-1) <>
       (jsonb_build_object('81',81,'31',31,'3',3,'2',2)->>v_group)::int
      then raise exception 'combined_117_batch_partial';end if;
  end loop;
  if (select count(*) from public.question_version_links
      where reason=v_release and link_type='replacement')<>117
     or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=true)<>117
     or (select count(*) from public.practice_pool_questions ppq
       join private.math_practice_117_group_fixture f on f.old_id=ppq.question_id
       where ppq.is_active=true)<>0
     or (select count(*) from public.questions q
       join private.math_practice_117_group_fixture f on f.old_id=q.id
       where q.quality_status='published' and q.is_active=true)<>117
    then raise exception 'full_117_cutover_integrity_failed';end if;

  -- Synthetic answer to a NEW version, issued before rollback.
  select (pair.value->>'new_id')::bigint into v_new_id
    from jsonb_array_elements(v_batches->'2') pair
    order by (pair.value->>'old_id')::bigint limit 1;
  insert into public.practice_sessions_v4(id,user_id,subject_id,question_ids,status)
    values(5118,'a1111111-1111-4111-8111-111111111118',5,
     array[v_new_id],'in_progress');
  insert into public.practice_session_answers_v4
    (session_id,question_id,user_answer,is_correct)
    values(5118,v_new_id,'SYNTHETIC_NEW',true);

  -- Reverse ALL four version groups inside ONE rollback transaction.
  for v_group in select * from unnest(array['2','3','31','81']) loop
    v_result:=private.math_practice_future_only_rollback_v1(
      v_release,v_batches->v_group);
    if coalesce((v_result->>'restored_old_memberships')::int,-1) <>
       (jsonb_build_object('81',81,'31',31,'3',3,'2',2)->>v_group)::int
      then raise exception 'combined_117_rollback_partial';end if;
  end loop;
  if (select count(*) from public.practice_pool_questions ppq
       join private.math_practice_117_group_fixture f on f.old_id=ppq.question_id
       where ppq.is_active=true)<>117
     or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=true)<>0
     or (select count(*) from public.question_version_links
       where reason=v_release and link_type='replacement')<>117
     or (select count(*) from public.practice_session_answers_v4
       where session_id=5118 and question_id=v_new_id)<>1
     or (select jsonb_agg(to_jsonb(a) order by a.question_id)
       from public.practice_session_answers_v4 a
       where a.session_id=5117) is distinct from v_old_session
     or (select jsonb_agg(to_jsonb(a) order by a.question_id)
       from public.practice_drill_answers_v4 a
       where a.session_id=6117) is distinct from v_old_drill
    then raise exception '117_rollback_lost_prior_or_new_answer_history';end if;
  raise notice 'MATH_PRACTICE_117_COMBINED_TRANSACTION_PG17_PASS: 81+31+3+2, failed-last-group zero partial writes, full activation/rollback preserves answers';
end $verify_combined_117$;
