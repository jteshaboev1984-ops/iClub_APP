-- #574 · three answer-pattern repairs, future-only in disposable PG17.
-- All learner/question contents are synthetic. Never execute on hosted Supabase.
-- Fixture and staged SQL generated exclusively at CI runtime, with QA=PENDING.
do $pattern_only$
declare
  v_release text:='math_p1_practice_v2_fix_20261120';
  v_pairs jsonb;
  v_first_new bigint;
  v_result jsonb;
  v_old_before jsonb;
  v_drill_before jsonb;
begin
  select jsonb_agg(jsonb_build_object('old_id',o.question_id,
    'new_id',n.question_id,
    'old_hash',o.content_hash,'new_hash',n.content_hash)
    order by o.question_id) into v_pairs
  from private.practice_v2_question_meta o
  join private.practice_v2_question_meta n
   on n.content_key=o.content_key||'-V20261120'
  where o.question_id in (7624,7797,7937)
    and n.release_version=v_release;
  if v_pairs is null or jsonb_array_length(v_pairs)<>3
    then raise exception 'unexpected_pattern_version_scope'; end if;
  if (select count(*) from private.practice_v2_question_meta n
    join public.questions q on q.id=n.question_id
    where n.release_version=v_release
      and q.quality_status='draft' and q.is_active=false
      and n.is_runtime_allowed=false
      and n.qa_math_status='pending'
      and n.qa_language_status='pending'
      and n.qa_technical_status='pending'
      and n.qa_tour_separation_status='pending')<>3
    then raise exception 'three_new_versions_not_fail_closed'; end if;
  if (select count(*) from public.practice_pool_questions ppq
    join private.practice_v2_question_meta n on n.question_id=ppq.question_id
    where n.release_version=v_release and ppq.is_active)<>0
    then raise exception 'draft_pool_membership_is_active'; end if;
  -- Check all three mathematics answers are the exact same semantic option
  -- across locales even though the displayed answer key is in a new slot.
  if exists (
    select 1
    from public.questions qold
    join private.practice_v2_question_meta mnew
      on mnew.content_key=(
       select mold.content_key||'-V20261120'
       from private.practice_v2_question_meta mold
       where mold.question_id=qold.id)
    join public.questions qnew on qnew.id=mnew.question_id
    where qold.id in (7624,7797,7937)
      and (
        qold.correct_answer=qnew.correct_answer
        or jsonb_array_length(qold.options_text_en::jsonb)<>4
        or jsonb_array_length(qnew.options_text_en::jsonb)<>4
        or qold.options_text_en::jsonb->>
          (ascii(qold.correct_answer)-ascii('A')) is distinct from
          qnew.options_text_en::jsonb->>
          (ascii(qnew.correct_answer)-ascii('A'))
        or qold.options_text_ru::jsonb->>
          (ascii(qold.correct_answer)-ascii('A')) is distinct from
          qnew.options_text_ru::jsonb->>
          (ascii(qnew.correct_answer)-ascii('A'))
        or qold.options_text_uz::jsonb->>
          (ascii(qold.correct_answer)-ascii('A')) is distinct from
          qnew.options_text_uz::jsonb->>
          (ascii(qnew.correct_answer)-ascii('A'))
      )
  ) then raise exception 'semantically_correct_choice_changed_in_version'; end if;
  -- Prevent a partial unreviewed release and catch accidental auto-publish.
  begin
    perform private.math_practice_future_only_activate_v1(v_release,v_pairs);
    raise exception 'bad_publication_allowed';
  exception when raise_exception then
    if SQLERRM='bad_publication_allowed' then raise;end if;
  end;
  if exists(select 1 from public.question_version_links)
   or exists(select 1 from public.practice_pool_questions ppq
      join private.practice_v2_question_meta m on m.question_id=ppq.question_id
      where m.release_version=v_release and ppq.is_active)
   then raise exception 'failed_activation_left_side_effects'; end if;
  select jsonb_agg(to_jsonb(a)) into v_old_before
    from public.practice_session_answers_v4 a where session_id=5001;
  select jsonb_agg(to_jsonb(a)) into v_drill_before
    from public.practice_drill_answers_v4 a where session_id=6001;
  -- ONLY in this private ephemeral test database.
  update private.practice_v2_question_meta
    set qa_math_status='passed',qa_language_status='passed',
        qa_technical_status='passed',qa_tour_separation_status='passed'
    where release_version=v_release;
  v_result:=private.math_practice_future_only_activate_v1(v_release,v_pairs);
  if (v_result->>'replaced')::int<>3
     or (select count(*) from public.question_version_links where reason=v_release)<>3
     or (select count(*) from public.practice_pool_questions ppq
      join private.practice_v2_question_meta m on m.question_id=ppq.question_id
      where m.release_version=v_release and ppq.is_active)<>3
     or (select count(*) from public.practice_pool_questions
       where question_id in (7624,7797,7937) and is_active)<>0
     then raise exception 'semantic_pattern_atomic_switch_failed'; end if;
  -- Simulate an answer to an already-issued new version before rollback.
  v_first_new:=(v_pairs->0->>'new_id')::bigint;
  insert into public.practice_sessions_v4
    (id,user_id,subject_id,question_ids,status)
    values(5002,'cccccccc-cccc-4ccc-8ccc-cccccccccccc',5,
       array[v_first_new],'in_progress');
  insert into public.practice_session_answers_v4
    (session_id,question_id,user_answer,is_correct)
    values(5002,v_first_new,'SYNTHETIC',true);
  v_result:=private.math_practice_future_only_rollback_v1(v_release,v_pairs);
  if (v_result->>'restored_old_memberships')::int<>3
     or (select count(*) from public.practice_pool_questions
        where question_id in (7624,7797,7937) and is_active)<>3
     or (select count(*) from public.practice_pool_questions ppq
      join private.practice_v2_question_meta m on m.question_id=ppq.question_id
      where m.release_version=v_release and ppq.is_active)<>0
     or (select count(*) from public.question_version_links where reason=v_release)<>3
     or (select count(*) from public.practice_session_answers_v4
       where session_id=5002 and question_id=v_first_new)<>1
     or (select jsonb_agg(to_jsonb(a)) from public.practice_session_answers_v4 a
       where session_id=5001) is distinct from v_old_before
     or (select jsonb_agg(to_jsonb(a)) from public.practice_drill_answers_v4 a
       where session_id=6001) is distinct from v_drill_before
     then raise exception 'semantic_pattern_rollback_history_corrupted';end if;
  raise notice 'MATH_PRACTICE_3_PATTERNED_KEYS_FUTURE_ONLY_PG17_PASS';
end $pattern_only$;
