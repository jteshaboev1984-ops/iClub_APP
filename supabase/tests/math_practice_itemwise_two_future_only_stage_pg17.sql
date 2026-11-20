-- #574 / exactly two itemwise authored corrections after 495-review.
-- DISPOSABLE PostgreSQL 17 ONLY; stage.sql generated privately at CI runtime.
-- Requires synthetic 2-question fixture, generated staging SQL and #599
-- private future-only activate/rollback candidate installed locally.
do $review_two$
declare
  v_release text:='math_p1_practice_v2_fix_20261120';
  v_pairs jsonb;
  v_new_id bigint;
  v_old_before jsonb;
  v_drill_before jsonb;
  v_response jsonb;
begin
  select jsonb_agg(jsonb_build_object('old_id',o.question_id,'new_id',n.question_id,
    'old_hash',o.content_hash,'new_hash',n.content_hash) order by o.question_id)
    into v_pairs
  from private.practice_v2_question_meta o
  join private.practice_v2_question_meta n
    on n.content_key=o.content_key||'-V20261120'
  where o.question_id in (7791,7881) and n.release_version=v_release;
  if jsonb_array_length(v_pairs)<>2 then
    raise exception 'two_item_source_versions_not_staged';end if;

  if (select count(*) from private.practice_v2_question_meta m
       join public.questions q on q.id=m.question_id
       where m.release_version=v_release
         and m.lifecycle_state='approved'
         and m.is_runtime_allowed=false
         and m.qa_math_status='pending'
         and m.qa_language_status='pending'
         and m.qa_technical_status='pending'
         and m.qa_tour_separation_status='pending'
         and q.is_active=false and q.quality_status='draft')<>2
     or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active=true)<>0
  then raise exception 'new_versions_not_fail_closed_pending_qa';end if;

  select jsonb_agg(to_jsonb(a)) into v_old_before
    from public.practice_session_answers_v4 a where session_id=5001;
  select jsonb_agg(to_jsonb(a)) into v_drill_before
    from public.practice_drill_answers_v4 a where session_id=6001;
  -- Publication must be refused before all four approvals, even in a sandbox.
  begin
    perform private.math_practice_future_only_activate_v1(v_release,v_pairs);
    raise exception 'unreviewed_two_questions_were_published';
  exception when raise_exception then
    if SQLERRM='unreviewed_two_questions_were_published' then raise; end if;
  end;
  if (select count(*) from public.question_version_links)<>0
     or (select count(*) from public.questions q
       join private.practice_v2_question_meta m on m.question_id=q.id
       where m.release_version=v_release and q.is_active)<>0
  then raise exception 'failed_validation_made_partial_release';end if;

  -- Artificial signoff ONLY inside the disposable CI fixture, never in staging.
  update private.practice_v2_question_meta set
    qa_math_status='passed',qa_language_status='passed',
    qa_technical_status='passed',qa_tour_separation_status='passed'
    where release_version=v_release;

  v_response:=private.math_practice_future_only_activate_v1(v_release,v_pairs);
  if (v_response->>'replaced')::integer<>2
     or (select count(*) from public.question_version_links
         where reason=v_release)<>2
     or (select count(*) from public.practice_pool_questions ppq
         join private.practice_v2_question_meta m on m.question_id=ppq.question_id
         where m.release_version=v_release and ppq.is_active=true)<>2
     or (select count(*) from public.practice_pool_questions ppq
         where ppq.question_id in (7791,7881) and ppq.is_active=true)<>0
     or (select count(*) from public.questions
         where id in (7791,7881) and is_active=true and quality_status='published')<>2
  then raise exception 'two_item_activation_or_old_version_protection_failed';end if;

  -- A new active learner session may have been issued the new ID before
  -- rollback: preserve its question ID and objectively recorded answer.
  v_new_id:=(v_pairs->0->>'new_id')::bigint;
  insert into public.practice_sessions_v4(id,user_id,subject_id,question_ids,status)
   values(5002,'cccccccc-cccc-4ccc-8ccc-cccccccccccc',5,array[v_new_id],'in_progress');
  insert into public.practice_session_answers_v4
   (session_id,question_id,user_answer,is_correct)
   values(5002,v_new_id,'SYNTHETIC',true);

  v_response:=private.math_practice_future_only_rollback_v1(v_release,v_pairs);
  if (v_response->>'restored_old_memberships')::integer<>2
     or (select count(*) from public.practice_pool_questions ppq
         where ppq.question_id in (7791,7881) and ppq.is_active=true)<>2
     or (select count(*) from public.practice_pool_questions ppq
         join private.practice_v2_question_meta m on m.question_id=ppq.question_id
         where m.release_version=v_release and ppq.is_active=true)<>0
     or (select count(*) from public.practice_session_answers_v4
         where session_id=5002 and question_id=v_new_id)<>1
     or (select count(*) from public.question_version_links where reason=v_release)<>2
     or (select jsonb_agg(to_jsonb(a)) from public.practice_session_answers_v4 a
         where session_id=5001) is distinct from v_old_before
     or (select jsonb_agg(to_jsonb(a)) from public.practice_drill_answers_v4 a
         where session_id=6001) is distinct from v_drill_before
  then raise exception 'two_item_rollback_damaged_old_or_new_answer_history';end if;
  raise notice 'PASS 2 ITEMWISE correction versions: fail-closed QA, atomic publish, preserved old history and rollback';
end $review_two$;
