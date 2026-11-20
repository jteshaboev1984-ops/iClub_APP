-- Math Practice #574 · exactly 31 editorial equal-key edits become NEW question
-- versions. DISPOSABLE PostgreSQL 17 only; never run hosted without owner GO.
-- Source content/options/answer keys are generated into ephemeral, private SQL.
do $editorial31$
declare
 v_release text:='math_p1_practice_v2_fix_20261120';
 v_pairs jsonb;
 v_answer_history jsonb;
 v_old_session jsonb;
 v_new_id bigint;
 v_result jsonb;
begin
 select jsonb_agg(jsonb_build_object(
    'old_id',o.question_id,'new_id',n.question_id,
    'old_hash',o.content_hash,'new_hash',n.content_hash)
    order by o.question_id) into v_pairs
 from private.practice_v2_question_meta o
 join private.practice_v2_question_meta n
   on n.content_key=o.content_key||'-V20261120'
 where n.release_version=v_release;
 if v_pairs is null or jsonb_array_length(v_pairs)<>31
   then raise exception 'editorial31_stage_scope_mismatch';end if;
 if (select count(*) from public.questions q
      join private.practice_v2_question_meta m on m.question_id=q.id
      where m.release_version=v_release
        and q.quality_status='draft' and q.is_active=false
        and m.is_runtime_allowed=false and m.lifecycle_state='approved'
        and m.qa_math_status='pending' and m.qa_language_status='pending'
        and m.qa_technical_status='pending' and m.qa_tour_separation_status='pending')<>31
    or (select count(*) from public.questions q
      join private.practice_v2_question_meta m on m.question_id=q.id
      where m.release_version=v_release and q.qtype='mcq')<>19
    or (select count(*) from public.questions q
      join private.practice_v2_question_meta m on m.question_id=q.id
      where m.release_version=v_release and q.qtype='input')<>12
   then raise exception 'incorrect_editorial_qa_types_or_lifecycle';end if;
 if (select count(*) from public.practice_pool_questions ppq
   join private.practice_v2_question_meta m on m.question_id=ppq.question_id
   where m.release_version=v_release and ppq.is_active)<>0
   then raise exception 'unapproved_editorial_pool_is_active';end if;
 if (select count(*) from public.questions
   where id in (7710,7714,7754) and quality_status='published' and is_active=true)<>3
   then raise exception 'protected_history_questions_modified';end if;
 -- Seed synthetic history BEFORE the release, including a started and later
 -- finalized old version, to assert versioned publication never rewrites it.
 insert into public.practice_sessions_v4
   (id,user_id,subject_id,question_ids,status)
   values (5031,'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
     5,array[7710,7714,7754]::bigint[],'in_progress');
 insert into public.practice_session_answers_v4
   (session_id,question_id,user_answer,is_correct)
   values(5031,7714,'SYNTHETIC_OLD',true),(5031,7754,'SYNTHETIC_OLD',false);
 insert into public.practice_drill_sessions_v4
   (id,user_id,subject_id,question_ids,status)
   values(6031,'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      5,array[7710]::bigint[],'in_progress');
 insert into public.practice_drill_answers_v4
   (session_id,question_id,user_answer,is_correct)
   values(6031,7710,'SYNTHETIC_OLD',true);
 select jsonb_agg(to_jsonb(a) order by a.question_id) into v_answer_history
  from public.practice_session_answers_v4 a where session_id=5031;
 select jsonb_agg(to_jsonb(a) order by a.question_id) into v_old_session
  from public.practice_drill_answers_v4 a where session_id=6031;
 -- A release MUST be refused while academic QA for new rows is pending.
 begin
   perform private.math_practice_future_only_activate_v1(v_release,v_pairs);
   raise exception 'unapproved_31_editorial_versions_published';
 exception when raise_exception then
   if SQLERRM='unapproved_31_editorial_versions_published' then raise;end if;
 end;
 if exists(select 1 from public.question_version_links)
   or exists(select 1 from public.practice_pool_questions ppq
      join private.practice_v2_question_meta m on m.question_id=ppq.question_id
      where m.release_version=v_release and ppq.is_active)
   then raise exception 'failed_31_editorial_activation_wrote_partial_data';end if;
 -- Simulated approvals exclusively in the synthetic disposable CI database.
 update private.practice_v2_question_meta
    set qa_math_status='passed',qa_language_status='passed',
        qa_technical_status='passed',qa_tour_separation_status='passed'
    where release_version=v_release;
 v_result:=private.math_practice_future_only_activate_v1(v_release,v_pairs);
 if (v_result->>'replaced')::int<>31
    or (select count(*) from public.question_version_links
      where reason=v_release)<>31
    or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active)<>31
    or (select count(*) from public.practice_pool_questions ppq
       join public.questions old on old.id=ppq.question_id
       join private.practice_v2_question_meta m on m.question_id=old.id
       where m.release_version='math_p1_practice_v2_2026_10_07'
         and ppq.is_active)<>0
    or (select count(*) from public.questions
       where id in (7710,7714,7754) and quality_status='published'
         and is_active=true)<>3
   then raise exception 'atomic_editorial31_cutover_or_old_version_integrity_failed';end if;
 v_new_id:=(v_pairs->0->>'new_id')::bigint;
 insert into public.practice_sessions_v4
   (id,user_id,subject_id,question_ids,status)
   values(5032,'ffffffff-ffff-4fff-8fff-ffffffffffff',
     5,array[v_new_id],'in_progress');
 insert into public.practice_session_answers_v4
   (session_id,question_id,user_answer,is_correct)
   values(5032,v_new_id,'SYNTHETIC_NEW',true);
 v_result:=private.math_practice_future_only_rollback_v1(v_release,v_pairs);
 if (v_result->>'restored_old_memberships')::int<>31
    or (select count(*) from public.practice_pool_questions ppq
       join private.practice_v2_question_meta m on m.question_id=ppq.question_id
       where m.release_version=v_release and ppq.is_active)<>0
    or (select count(*) from public.question_version_links where reason=v_release)<>31
    or (select count(*) from public.practice_session_answers_v4
       where session_id=5032 and question_id=v_new_id)<>1
    or (select jsonb_agg(to_jsonb(a) order by a.question_id)
        from public.practice_session_answers_v4 a where session_id=5031)
      is distinct from v_answer_history
    or (select jsonb_agg(to_jsonb(a) order by a.question_id)
        from public.practice_drill_answers_v4 a where session_id=6031)
      is distinct from v_old_session
   then raise exception 'editorial31_rollback_destroyed_historical_answers';end if;
 raise notice 'MATH_PRACTICE_31_EDITORIAL_FUTURE_ONLY_PG17_PASS';
end $editorial31$;
