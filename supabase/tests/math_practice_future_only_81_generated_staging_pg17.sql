-- Full 81-item generated-staging integration. DISPOSABLE PG17 ONLY.
-- Source steps: temp full fixture => temp real 81 staging SQL => candidate functions.
do $all81$
declare
  v_release text:='math_p1_practice_v2_fix_20261120';
  v_pairs jsonb;
  v_n integer;
  v_result jsonb;
  v_first_old bigint;
  v_first_new bigint;
  v_old_answer jsonb;
  v_old_drill jsonb;
begin
  select jsonb_agg(jsonb_build_object(
    'old_id',old_m.question_id,'new_id',new_m.question_id,
    'old_hash',old_m.content_hash,'new_hash',new_m.content_hash)
    order by old_m.question_id)
  into v_pairs
  from private.practice_v2_question_meta old_m
  join private.practice_v2_question_meta new_m
    on new_m.content_key=old_m.content_key||'-V20261120'
  where old_m.release_version='math_p1_practice_v2_2026_10_07'
    and new_m.release_version=v_release;
  v_n:=jsonb_array_length(v_pairs);
  if v_n<>81 then raise exception 'not_all_81_staged'; end if;

  if (select count(*) from private.practice_v2_question_meta
      where release_version=v_release
        and lifecycle_state='approved'
        and is_runtime_allowed=false
        and qa_math_status='pending'
        and qa_language_status='pending'
        and qa_technical_status='pending'
        and qa_tour_separation_status='pending')<>81
   or (select count(*) from public.questions q
       join private.practice_v2_question_meta m on m.question_id=q.id
       where m.release_version=v_release and q.is_active=false
         and q.quality_status='draft')<>81
   or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=false)<>81
  then raise exception 'generated_staging_not_fail_closed'; end if;

  select jsonb_agg(to_jsonb(x)) into v_old_answer
    from public.practice_session_answers_v4 x where x.session_id=5001;
  select jsonb_agg(to_jsonb(x)) into v_old_drill
    from public.practice_drill_answers_v4 x where x.session_id=6001;

  -- Student's old session must not become unavailable.
  if (select count(*) from public.questions q
      join private.practice_v2_question_meta m on m.question_id=q.id
      where m.release_version='math_p1_practice_v2_2026_10_07'
        and q.is_active=true and q.quality_status='published')<>81
  then raise exception 'old_version_invalid_before_switch'; end if;

  -- Stage is NOT approval; reject any premature attempt to publish all 81.
  begin
    perform private.math_practice_future_only_activate_v1(v_release,v_pairs);
    raise exception 'unreviewed_81_staging_was_published';
  exception when raise_exception then
    if SQLERRM='unreviewed_81_staging_was_published' then raise; end if;
  end;
  if (select count(*) from public.question_version_links)<>0
    or (select count(*) from public.practice_pool_questions ppq
      join private.practice_v2_question_meta m on m.question_id=ppq.question_id
      where m.release_version=v_release and ppq.is_active=true)<>0
  then raise exception 'premature_activation_changed_state'; end if;

  -- Synthetic signoff ONLY in disposable PostgreSQL, never in authored staging.
  update private.practice_v2_question_meta
    set qa_math_status='passed',qa_language_status='passed',
        qa_technical_status='passed',qa_tour_separation_status='passed'
    where release_version=v_release;
  if (select count(*) from private.practice_v2_question_meta
    where release_version=v_release and qa_math_status='passed'
      and qa_language_status='passed' and qa_technical_status='passed'
      and qa_tour_separation_status='passed')<>81
  then raise exception 'synthetic_fixture_signoff_missing'; end if;

  v_result:=private.math_practice_future_only_activate_v1(v_release,v_pairs);
  if (v_result->>'replaced')::int<>81
    or (select count(*) from public.question_version_links
       where reason=v_release)<>81
    or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=true)<>81
    or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version='math_p1_practice_v2_2026_10_07'
         and ppq.is_active=true)<>0
    or (select count(*) from public.questions q
       join private.practice_v2_question_meta m on m.question_id=q.id
       where m.release_version='math_p1_practice_v2_2026_10_07'
         and q.is_active=true and q.quality_status='published')<>81
    or (select jsonb_agg(to_jsonb(x)) from public.practice_session_answers_v4 x
         where x.session_id=5001) is distinct from v_old_answer
    or (select jsonb_agg(to_jsonb(x)) from public.practice_drill_answers_v4 x
         where x.session_id=6001) is distinct from v_old_drill
  then raise exception 'all_81_activation_history_or_selector_failed'; end if;

  v_first_new:=(v_pairs->0->>'new_id')::bigint;
  v_first_old:=(v_pairs->0->>'old_id')::bigint;
  insert into public.practice_sessions_v4
    values(5002,'cccccccc-cccc-4ccc-8ccc-cccccccccccc',5,array[v_first_new],'in_progress');
  insert into public.practice_session_answers_v4(session_id,question_id,user_answer,is_correct)
    values(5002,v_first_new,'synthetic',true);

  -- The rollback must preserve BOTH pre-cutover and post-cutover session IDs.
  v_result:=private.math_practice_future_only_rollback_v1(v_release,v_pairs);
  if (v_result->>'restored_old_memberships')::int<>81
    or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version='math_p1_practice_v2_2026_10_07'
         and ppq.is_active=true)<>81
    or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=true)<>0
    or (select count(*) from public.questions q
       join private.practice_v2_question_meta m on m.question_id=q.id
       where m.release_version=v_release and q.is_active=true)<>81
    or (select count(*) from public.question_version_links)<>81
    or (select count(*) from public.practice_session_answers_v4
       where session_id=5002 and question_id=v_first_new)<>1
    or (select jsonb_agg(to_jsonb(x)) from public.practice_session_answers_v4 x
       where x.session_id=5001) is distinct from v_old_answer
    or (select jsonb_agg(to_jsonb(x)) from public.practice_drill_answers_v4 x
       where x.session_id=6001) is distinct from v_old_drill
  then raise exception 'all_81_rollback_changed_history'; end if;

  raise notice 'PASS 81 actual-source staged versions PG17, approval fails closed, atomic swap, unchanged old sessions/answers, new session, non-destructive rollback';
end $all81$;
