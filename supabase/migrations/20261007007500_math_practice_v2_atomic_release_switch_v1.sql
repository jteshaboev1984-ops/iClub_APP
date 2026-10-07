-- Mathematics Practice v2 — reset + atomic publish + optional legacy question cleanup
-- Branch-only migration. Defining these private functions does NOT publish or delete anything.
--
-- Owner policy:
-- - Mathematics Tour data is protected and must not change.
-- - Legacy Mathematics Practice progress/history may be reset.
-- - Legacy Practice questions may be removed after the new bank passes post-publish smoke QA.
-- - Any legacy question referenced by Tour or another protected/non-Practice system is retained.
--
-- Controlled release:
-- 1) stage 495 v2 questions inactive;
-- 2) deploy v5 runtime;
-- 3) run read-only preflight;
-- 4) call private.publish_math_practice_v2_release_v1(...);
-- 5) run post-publish/reset audit + learner smoke;
-- 6) only then call private.cleanup_math_practice_v1_questions_v1(...).

create or replace function private.publish_math_practice_v2_release_v1(
  p_release_version text default 'math_p1_practice_v2_2026_10_07'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','pg_temp'
as $function$
declare
  v_subject_id bigint;
  v_before jsonb;
  v_after jsonb;
  v_old_ids bigint[];
  v_old_question_ids bigint[];
  v_new_membership_ids bigint[];
  v_new_question_ids bigint[];
  v_old_count integer;
  v_new_count integer;
  v_count integer;
  v_subject_count integer;
  v_pool_count integer;
  v_distinct_pool_count integer;
  v_audit_id bigint;
  v_existing_status text;
  v_reset_attempts integer := 0;
  v_reset_answers integer := 0;
  v_reset_sessions integer := 0;
  v_reset_drills integer := 0;
  v_reset_diagnoses integer := 0;
  v_reset_recommendations integer := 0;
  v_reset_legacy_evidence integer := 0;
  v_expected jsonb := '{"1":68,"2":80,"3":68,"4":77,"5":66,"6":70,"7":66}'::jsonb;
  v_tour_no integer;
begin
  if nullif(trim(coalesce(p_release_version,'')),'') is null then
    raise exception 'release_version_required';
  end if;

  perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);

  select count(*)::integer,min(s.id)
  into v_subject_count,v_subject_id
  from public.subjects s
  where s.subject_key='mathematics'
    and s.is_active is true;

  if v_subject_count<>1 or v_subject_id is null then
    raise exception 'expected_one_active_math_subject_found_%',v_subject_count;
  end if;

  select count(*)::integer,count(distinct p.tour_no)::integer
  into v_pool_count,v_distinct_pool_count
  from public.practice_pools p
  where p.subject_id=v_subject_id
    and p.is_active is true
    and p.tour_no between 1 and 7;

  if v_pool_count<>7 or v_distinct_pool_count<>7 then
    raise exception 'release_expected_exactly_one_active_pool_per_practice_found_%_rows_%_tour_nos',
      v_pool_count,v_distinct_pool_count;
  end if;

  if has_function_privilege(
       'authenticated',
       'public.submit_practice_attempt(bigint,integer,numeric,integer,jsonb)',
       'execute'
     )
     or has_function_privilege(
       'authenticated',
       'public.submit_practice_answer_safe(bigint,bigint,text,integer,integer)',
       'execute'
     ) then
    raise exception 'legacy_answer_oracle_still_exposed';
  end if;

  if to_regprocedure('public.start_practice_session_auto_safe_v5(bigint,text)') is null
     or to_regprocedure('public.start_practice_topic_drill_safe_v5(text,text,text,text)') is null
     or to_regprocedure('public.get_recent_practice_mistakes_safe_v5(text,text,text,integer)') is null
     or to_regprocedure('public.start_practice_mistakes_drill_safe_v5(text,bigint[],text)') is null
     or to_regprocedure('public.submit_practice_session_answer_safe_v5(bigint,bigint,text,integer,integer)') is null
     or to_regprocedure('public.submit_practice_drill_answer_safe_v5(bigint,bigint,text,integer,integer)') is null
     or to_regprocedure('public.finalize_practice_session_safe_v5(bigint,integer)') is null
     or to_regprocedure('public.get_practice_review_full_safe_v5(bigint)') is null then
    raise exception 'practice_v5_runtime_incomplete';
  end if;

  select status into v_existing_status
  from private.practice_v2_release_switch_audit
  where release_version=p_release_version;

  if v_existing_status='published' then
    return jsonb_build_object(
      'ok',true,
      'release_version',p_release_version,
      'status','published',
      'idempotent',true
    );
  end if;

  select count(*)::integer into v_count
  from private.practice_v2_question_meta m
  where m.release_version=p_release_version;

  if v_count<>495 then
    raise exception 'release_expected_495_staged_questions_found_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.questions q
  join private.practice_v2_question_meta m on m.question_id=q.id
  where m.release_version=p_release_version
    and (
      m.qa_math_status<>'passed'
      or m.qa_language_status<>'passed'
      or m.qa_technical_status<>'passed'
      or m.qa_tour_separation_status<>'passed'
      or m.lifecycle_state<>'approved'
      or m.is_runtime_allowed is true
      or q.is_active is true
      or q.quality_status<>'draft'
    );

  if v_count<>0 then
    raise exception 'release_staged_question_gate_failed_count_%',v_count;
  end if;

  select array_agg(m.question_id order by m.practice_no,m.content_key)
  into v_new_question_ids
  from private.practice_v2_question_meta m
  where m.release_version=p_release_version;

  select array_agg(ppq.id order by p.tour_no,ppq.order_no,ppq.id)
  into v_new_membership_ids
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  join private.practice_v2_question_meta m on m.question_id=ppq.question_id
  where p.subject_id=v_subject_id
    and p.is_active is true
    and p.tour_no between 1 and 7
    and p.tour_no=m.practice_no
    and m.release_version=p_release_version
    and ppq.is_active is false;

  v_new_count:=coalesce(cardinality(v_new_membership_ids),0);
  if v_new_count<>495 then
    raise exception 'release_expected_495_inactive_new_memberships_found_%',v_new_count;
  end if;

  for v_tour_no in 1..7 loop
    select count(*)::integer into v_count
    from public.practice_pool_questions ppq
    join public.practice_pools p on p.id=ppq.pool_id
    join private.practice_v2_question_meta m on m.question_id=ppq.question_id
    where p.subject_id=v_subject_id
      and p.is_active is true
      and p.tour_no=v_tour_no
      and m.practice_no=v_tour_no
      and m.release_version=p_release_version
      and ppq.is_active is false;

    if v_count<>(v_expected->>v_tour_no::text)::integer then
      raise exception 'release_staged_practice_%_expected_%_found_%',
        v_tour_no,(v_expected->>v_tour_no::text)::integer,v_count;
    end if;

    if exists(
      select 1
      from public.practice_pool_questions ppq
      join public.practice_pools p on p.id=ppq.pool_id
      join private.practice_v2_question_meta m on m.question_id=ppq.question_id
      where p.subject_id=v_subject_id
        and p.is_active is true
        and p.tour_no=v_tour_no
        and m.practice_no=v_tour_no
        and m.release_version=p_release_version
        and ppq.is_active is false
      group by p.id
      having min(ppq.order_no)<>1
         or max(ppq.order_no)<>count(*)::integer
         or count(distinct ppq.order_no)<>count(*)
    ) then
      raise exception 'release_staged_practice_%_order_not_contiguous',v_tour_no;
    end if;
  end loop;

  select count(*)::integer into v_count
  from private.practice_v2_diagnostic_catalog d
  where d.release_version=p_release_version
    and d.approval_status='approved'
    and d.is_runtime_allowed is false;

  if v_count<>201 then
    raise exception 'release_expected_201_staged_diagnostics_found_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.question_answer_diagnostics d
  join private.practice_v2_question_meta m on m.question_id=d.question_id
  where m.release_version=p_release_version
    and d.quality_status='draft';

  if v_count<>868 then
    raise exception 'release_expected_868_staged_diagnostic_mappings_found_%',v_count;
  end if;

  select array_agg(ppq.id order by p.tour_no,ppq.order_no,ppq.id)
  into v_old_ids
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=v_subject_id
    and p.tour_no between 1 and 7
    and p.is_active is true
    and ppq.is_active is true
    and not (ppq.question_id=any(v_new_question_ids));

  v_old_count:=coalesce(cardinality(v_old_ids),0);
  if v_old_count<>490 then
    raise exception 'release_legacy_active_membership_drift_expected_490_found_%',v_old_count;
  end if;

  select array_agg(x.question_id order by x.question_id)
  into v_old_question_ids
  from (
    select distinct ppq.question_id
    from public.practice_pool_questions ppq
    where ppq.id=any(v_old_ids)
  ) x;

  if coalesce(cardinality(v_old_question_ids),0)<>490 then
    raise exception 'release_legacy_question_set_expected_490_found_%',
      coalesce(cardinality(v_old_question_ids),0);
  end if;

  select count(*)::integer into v_count
  from public.tour_questions tq
  join private.practice_v2_question_meta m on m.question_id=tq.question_id
  join public.tours t on t.id=tq.tour_id
  where m.release_version=p_release_version
    and t.subject_id=v_subject_id;

  if v_count<>0 then
    raise exception 'release_practice_v2_tour_overlap_%',v_count;
  end if;

  v_before:=private.practice_v2_tour_invariant_snapshot_v1(v_subject_id);

  select count(*)::integer into v_reset_attempts
  from public.practice_attempts
  where subject_id=v_subject_id;

  select count(*)::integer into v_reset_answers
  from public.practice_answers a
  join public.practice_attempts pa on pa.id=a.attempt_id
  where pa.subject_id=v_subject_id;

  select count(*)::integer into v_reset_sessions
  from public.practice_sessions_v4
  where subject_id=v_subject_id;

  select count(*)::integer into v_reset_drills
  from public.practice_drill_sessions_v4
  where subject_id=v_subject_id;

  select count(*)::integer into v_reset_diagnoses
  from public.user_answer_diagnosis d
  where d.subject_id=v_subject_id
    and (
      d.practice_answer_id is not null
      or lower(coalesce(d.attempt_type,'')) like 'practice%'
    );

  select count(*)::integer into v_reset_recommendations
  from public.recommendations r
  where r.subject_id=v_subject_id
    and r.source_type='practice';

  select count(*)::integer into v_reset_legacy_evidence
  from private.exam_prep_legacy_evidence_references e
  where e.legacy_source='practice_answers'
    and (
      e.question_id=any(v_old_question_ids)
      or e.legacy_attempt_id in (
        select pa.id
        from public.practice_attempts pa
        where pa.subject_id=v_subject_id
      )
    );

  insert into private.practice_v2_release_switch_audit(
    release_version,
    subject_id,
    status,
    old_active_membership_ids,
    old_question_ids,
    new_membership_ids,
    new_question_ids,
    old_active_membership_count,
    new_membership_count,
    tour_snapshot_before,
    tour_snapshot_after,
    rollback_tour_snapshot_before,
    rollback_tour_snapshot_after,
    notes
  ) values(
    p_release_version,
    v_subject_id,
    'prepared',
    coalesce(v_old_ids,'{}'::bigint[]),
    coalesce(v_old_question_ids,'{}'::bigint[]),
    coalesce(v_new_membership_ids,'{}'::bigint[]),
    coalesce(v_new_question_ids,'{}'::bigint[]),
    v_old_count,
    v_new_count,
    v_before,
    null,
    null,
    null,
    jsonb_build_object(
      'strategy','practice_reset_then_v2_publish',
      'prepared_at',now(),
      'legacy_questions_before',coalesce(cardinality(v_old_question_ids),0),
      'practice_attempts_to_reset',v_reset_attempts,
      'practice_answers_to_reset',v_reset_answers,
      'practice_sessions_to_reset',v_reset_sessions,
      'practice_drills_to_reset',v_reset_drills,
      'practice_diagnoses_to_reset',v_reset_diagnoses,
      'practice_recommendations_to_reset',v_reset_recommendations,
      'legacy_practice_evidence_to_reset',v_reset_legacy_evidence
    )
  )
  on conflict(release_version) do update
  set subject_id=excluded.subject_id,
      status='prepared',
      started_at=now(),
      completed_at=null,
      rollback_at=null,
      old_active_membership_ids=excluded.old_active_membership_ids,
      old_question_ids=excluded.old_question_ids,
      new_membership_ids=excluded.new_membership_ids,
      new_question_ids=excluded.new_question_ids,
      old_active_membership_count=excluded.old_active_membership_count,
      new_membership_count=excluded.new_membership_count,
      tour_snapshot_before=excluded.tour_snapshot_before,
      tour_snapshot_after=null,
      rollback_tour_snapshot_before=null,
      rollback_tour_snapshot_after=null,
      notes=excluded.notes
  returning id into v_audit_id;

  -- After cutover, old Practice sessions are intentionally invalid.
  execute 'revoke execute on function public.start_practice_session_auto_safe_v4(bigint,text) from authenticated';
  execute 'revoke execute on function public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer) from authenticated';
  execute 'revoke execute on function public.finalize_practice_session_safe_v4(bigint,integer) from authenticated';
  execute 'revoke execute on function public.start_practice_topic_drill_safe_v4(text,text,text,text) from authenticated';
  execute 'revoke execute on function public.submit_practice_drill_answer_safe_v4(bigint,bigint,text,integer,integer) from authenticated';
  execute 'revoke execute on function public.get_recent_practice_mistakes_safe_v4(text,text,text,integer) from authenticated';
  execute 'revoke execute on function public.start_practice_mistakes_drill_safe_v4(text,bigint[],text) from authenticated';

  -- Intentional Mathematics Practice reset. Tour tables are not touched.
  delete from public.practice_sessions_v4
  where subject_id=v_subject_id;

  delete from public.practice_drill_sessions_v4
  where subject_id=v_subject_id;

  delete from public.user_answer_diagnosis d
  where d.subject_id=v_subject_id
    and (
      d.practice_answer_id is not null
      or lower(coalesce(d.attempt_type,'')) like 'practice%'
    );

  delete from private.exam_prep_legacy_evidence_references e
  where e.legacy_source='practice_answers'
    and (
      e.question_id=any(v_old_question_ids)
      or e.legacy_attempt_id in (
        select pa.id
        from public.practice_attempts pa
        where pa.subject_id=v_subject_id
      )
    );

  delete from public.recommendations r
  where r.subject_id=v_subject_id
    and r.source_type='practice';

  delete from public.practice_attempts
  where subject_id=v_subject_id;

  update public.practice_pool_questions ppq
  set is_active=false
  where ppq.id=any(v_old_ids);

  update public.questions q
  set is_active=true,
      quality_status='published'
  from private.practice_v2_question_meta m
  where m.question_id=q.id
    and m.release_version=p_release_version;

  update public.question_answer_diagnostics d
  set quality_status='published'
  from private.practice_v2_question_meta m
  where m.question_id=d.question_id
    and m.release_version=p_release_version;

  update private.practice_v2_diagnostic_catalog d
  set approval_status='approved',
      is_runtime_allowed=true,
      approved_at=coalesce(d.approved_at,now()),
      updated_at=now()
  where d.release_version=p_release_version;

  update private.practice_v2_question_meta m
  set lifecycle_state='published',
      is_runtime_allowed=true,
      published_at=coalesce(m.published_at,now()),
      updated_at=now()
  where m.release_version=p_release_version;

  update public.practice_pool_questions ppq
  set is_active=true
  where ppq.id=any(v_new_membership_ids);

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=v_subject_id
    and p.tour_no between 1 and 7
    and p.is_active is true
    and ppq.is_active is true;

  if v_count<>495 then
    raise exception 'release_active_bank_expected_495_found_%',v_count;
  end if;

  for v_tour_no in 1..7 loop
    select count(*)::integer into v_count
    from public.practice_pool_questions ppq
    join public.practice_pools p on p.id=ppq.pool_id
    join private.practice_v2_question_meta m on m.question_id=ppq.question_id
    where p.subject_id=v_subject_id
      and p.tour_no=v_tour_no
      and p.is_active is true
      and ppq.is_active is true
      and m.release_version=p_release_version;

    if v_count<>(v_expected->>v_tour_no::text)::integer then
      raise exception 'release_practice_%_count_expected_%_found_%',
        v_tour_no,(v_expected->>v_tour_no::text)::integer,v_count;
    end if;
  end loop;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  left join private.practice_v2_question_meta m
    on m.question_id=ppq.question_id
   and m.release_version=p_release_version
  where p.subject_id=v_subject_id
    and p.tour_no between 1 and 7
    and p.is_active is true
    and ppq.is_active is true
    and m.question_id is null;

  if v_count<>0 then
    raise exception 'release_non_v2_active_memberships_remaining_%',v_count;
  end if;

  if exists(select 1 from public.practice_attempts where subject_id=v_subject_id) then
    raise exception 'release_practice_attempt_reset_incomplete';
  end if;

  if exists(select 1 from public.practice_sessions_v4 where subject_id=v_subject_id) then
    raise exception 'release_practice_session_reset_incomplete';
  end if;

  if exists(select 1 from public.practice_drill_sessions_v4 where subject_id=v_subject_id) then
    raise exception 'release_practice_drill_reset_incomplete';
  end if;

  if exists(
    select 1
    from public.user_answer_diagnosis d
    where d.subject_id=v_subject_id
      and (
        d.practice_answer_id is not null
        or lower(coalesce(d.attempt_type,'')) like 'practice%'
      )
  ) then
    raise exception 'release_practice_diagnosis_reset_incomplete';
  end if;

  if exists(
    select 1
    from public.recommendations r
    where r.subject_id=v_subject_id
      and r.source_type='practice'
  ) then
    raise exception 'release_practice_recommendation_reset_incomplete';
  end if;

  v_after:=private.practice_v2_tour_invariant_snapshot_v1(v_subject_id);

  if v_before<>v_after then
    raise exception 'protected_tour_invariant_changed_during_release';
  end if;

  update private.practice_v2_release_switch_audit
  set status='published',
      completed_at=now(),
      tour_snapshot_after=v_after,
      notes=notes||jsonb_build_object(
        'published_at',now(),
        'active_memberships_after',495,
        'practice_progress_reset',true
      )
  where id=v_audit_id;

  return jsonb_build_object(
    'ok',true,
    'release_version',p_release_version,
    'status','published',
    'practice_progress_reset',true,
    'old_memberships_disabled',v_old_count,
    'new_memberships_enabled',v_new_count,
    'active_bank',495,
    'tour_invariant_unchanged',true,
    'audit_id',v_audit_id,
    'idempotent',false
  );
end;
$function$;

revoke all on function private.publish_math_practice_v2_release_v1(text)
from public,anon,authenticated;


create or replace function private.rollback_math_practice_v2_release_v1(
  p_release_version text default 'math_p1_practice_v2_2026_10_07'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','pg_temp'
as $function$
declare
  v_audit private.practice_v2_release_switch_audit%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_count integer;
begin
  perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);

  select * into v_audit
  from private.practice_v2_release_switch_audit a
  where a.release_version=p_release_version
  for update;

  if v_audit.id is null then
    raise exception 'release_audit_not_found_%',p_release_version;
  end if;

  if v_audit.status='rolled_back' then
    return jsonb_build_object(
      'ok',true,
      'release_version',p_release_version,
      'status','rolled_back',
      'idempotent',true
    );
  end if;

  if v_audit.status<>'published' then
    raise exception 'release_not_in_published_state_%',v_audit.status;
  end if;

  if v_audit.notes ? 'legacy_cleanup_completed_at' then
    raise exception 'rollback_not_available_after_legacy_question_cleanup';
  end if;

  v_before:=private.practice_v2_tour_invariant_snapshot_v1(v_audit.subject_id);

  update public.practice_pool_questions
  set is_active=false
  where id=any(v_audit.new_membership_ids);

  update private.practice_v2_question_meta
  set is_runtime_allowed=false,
      updated_at=now()
  where release_version=p_release_version;

  update private.practice_v2_diagnostic_catalog
  set is_runtime_allowed=false,
      updated_at=now()
  where release_version=p_release_version;

  update public.practice_pool_questions
  set is_active=true
  where id=any(v_audit.old_active_membership_ids);

  -- Rollback restores the old bank only. Old Practice progress intentionally stays reset.
  execute 'grant execute on function public.start_practice_session_auto_safe_v4(bigint,text) to authenticated';
  execute 'grant execute on function public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer) to authenticated';
  execute 'grant execute on function public.finalize_practice_session_safe_v4(bigint,integer) to authenticated';
  execute 'grant execute on function public.start_practice_topic_drill_safe_v4(text,text,text,text) to authenticated';
  execute 'grant execute on function public.submit_practice_drill_answer_safe_v4(bigint,bigint,text,integer,integer) to authenticated';
  execute 'grant execute on function public.get_recent_practice_mistakes_safe_v4(text,text,text,integer) to authenticated';
  execute 'grant execute on function public.start_practice_mistakes_drill_safe_v4(text,bigint[],text) to authenticated';

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=v_audit.subject_id
    and p.tour_no between 1 and 7
    and p.is_active is true
    and ppq.is_active is true;

  if v_count<>v_audit.old_active_membership_count then
    raise exception 'rollback_active_bank_expected_%_found_%',
      v_audit.old_active_membership_count,v_count;
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  where ppq.id=any(v_audit.new_membership_ids)
    and ppq.is_active is true;

  if v_count<>0 then
    raise exception 'rollback_new_memberships_still_active_%',v_count;
  end if;

  v_after:=private.practice_v2_tour_invariant_snapshot_v1(v_audit.subject_id);

  if v_before<>v_after then
    raise exception 'protected_tour_invariant_changed_during_rollback';
  end if;

  update private.practice_v2_release_switch_audit
  set status='rolled_back',
      rollback_at=now(),
      rollback_tour_snapshot_before=v_before,
      rollback_tour_snapshot_after=v_after,
      notes=notes||jsonb_build_object(
        'rolled_back_at',now(),
        'strategy','restore_legacy_bank_keep_practice_progress_reset'
      )
  where id=v_audit.id;

  return jsonb_build_object(
    'ok',true,
    'release_version',p_release_version,
    'status','rolled_back',
    'restored_memberships',v_audit.old_active_membership_count,
    'new_memberships_disabled',v_audit.new_membership_count,
    'practice_progress_restored',false,
    'tour_invariant_unchanged',true,
    'audit_id',v_audit.id,
    'idempotent',false
  );
end;
$function$;

revoke all on function private.rollback_math_practice_v2_release_v1(text)
from public,anon,authenticated;


create or replace function private.cleanup_math_practice_v1_questions_v1(
  p_release_version text default 'math_p1_practice_v2_2026_10_07'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','pg_temp'
as $function$
declare
  v_audit private.practice_v2_release_switch_audit%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_old_question_ids bigint[];
  v_deletable_question_ids bigint[];
  v_old_question_count integer := 0;
  v_deleted_membership_count integer := 0;
  v_deleted_question_count integer := 0;
  v_retained_question_count integer := 0;
begin
  perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);

  select * into v_audit
  from private.practice_v2_release_switch_audit a
  where a.release_version=p_release_version
  for update;

  if v_audit.id is null then
    raise exception 'cleanup_release_audit_not_found_%',p_release_version;
  end if;

  if v_audit.status<>'published' then
    raise exception 'cleanup_release_not_published_%',v_audit.status;
  end if;

  if v_audit.notes ? 'legacy_cleanup_completed_at' then
    return jsonb_build_object(
      'ok',true,
      'release_version',p_release_version,
      'status','cleaned',
      'idempotent',true,
      'deleted_legacy_questions',coalesce((v_audit.notes->>'legacy_questions_deleted')::integer,0),
      'retained_protected_questions',coalesce((v_audit.notes->>'legacy_questions_retained')::integer,0)
    );
  end if;

  v_old_question_ids:=v_audit.old_question_ids;
  v_old_question_count:=coalesce(cardinality(v_old_question_ids),0);

  if v_old_question_count<>v_audit.old_active_membership_count then
    raise exception 'cleanup_old_question_archive_expected_%_found_%',
      v_audit.old_active_membership_count,v_old_question_count;
  end if;

  if (
    select count(*)
    from public.practice_pool_questions ppq
    where ppq.id=any(v_audit.old_active_membership_ids)
  )<>v_audit.old_active_membership_count then
    raise exception 'cleanup_legacy_membership_archive_incomplete';
  end if;

  v_before:=private.practice_v2_tour_invariant_snapshot_v1(v_audit.subject_id);

  -- Remove only Practice-owned legacy evidence. Tour evidence is never selected here.
  delete from private.exam_prep_legacy_evidence_references e
  where e.legacy_source='practice_answers'
    and e.question_id=any(v_old_question_ids);

  -- A legacy question is physically deletable only if nothing outside the retired
  -- Practice bank needs it.
  select array_agg(q.id order by q.id)
  into v_deletable_question_ids
  from public.questions q
  where q.id=any(v_old_question_ids)
    and not exists(select 1 from public.tour_questions tq where tq.question_id=q.id)
    and not exists(select 1 from public.tour_answers ta where ta.question_id=q.id)
    and not exists(select 1 from public.tour_session_answers_v4 tsa where tsa.question_id=q.id)
    and not exists(select 1 from private.exam_prep_assessment_items x where x.question_id=q.id)
    and not exists(select 1 from private.exam_prep_session_items x where x.question_id=q.id)
    and not exists(select 1 from private.exam_prep_question_content_meta x where x.question_id=q.id)
    and not exists(select 1 from public.question_version_links x where x.old_question_id=q.id or x.new_question_id=q.id)
    and not exists(select 1 from private.exam_prep_legacy_evidence_references x where x.question_id=q.id)
    and not exists(
      select 1
      from public.practice_pool_questions x
      join public.practice_pools p on p.id=x.pool_id
      where x.question_id=q.id
        and not (
          p.subject_id=v_audit.subject_id
          and p.tour_no between 1 and 7
        )
    );

  if coalesce(cardinality(v_deletable_question_ids),0)>0 then
    delete from private.exam_prep_question_skill_map x
    where x.question_id=any(v_deletable_question_ids);
  end if;

  delete from public.practice_pool_questions ppq
  using public.practice_pools p
  where p.id=ppq.pool_id
    and p.subject_id=v_audit.subject_id
    and p.tour_no between 1 and 7
    and ppq.question_id=any(v_old_question_ids);

  get diagnostics v_deleted_membership_count = row_count;

  if v_deleted_membership_count<v_audit.old_active_membership_count then
    raise exception 'cleanup_legacy_memberships_deleted_expected_at_least_%_found_%',
      v_audit.old_active_membership_count,v_deleted_membership_count;
  end if;

  if coalesce(cardinality(v_deletable_question_ids),0)>0 then
    delete from public.questions q
    where q.id=any(v_deletable_question_ids);

    get diagnostics v_deleted_question_count = row_count;
  end if;

  v_retained_question_count:=v_old_question_count-v_deleted_question_count;

  v_after:=private.practice_v2_tour_invariant_snapshot_v1(v_audit.subject_id);

  if v_before<>v_after then
    raise exception 'protected_tour_invariant_changed_during_legacy_cleanup';
  end if;

  update private.practice_v2_release_switch_audit
  set notes=notes||jsonb_build_object(
        'legacy_cleanup_completed_at',now(),
        'legacy_questions_before',v_old_question_count,
        'legacy_questions_deleted',v_deleted_question_count,
        'legacy_questions_retained',v_retained_question_count,
        'legacy_memberships_deleted',v_deleted_membership_count,
        'legacy_cleanup_tour_snapshot_before',v_before,
        'legacy_cleanup_tour_snapshot_after',v_after
      )
  where id=v_audit.id;

  return jsonb_build_object(
    'ok',true,
    'release_version',p_release_version,
    'status','cleaned',
    'deleted_legacy_memberships',v_deleted_membership_count,
    'deleted_legacy_questions',v_deleted_question_count,
    'retained_protected_questions',v_retained_question_count,
    'tour_invariant_unchanged',true,
    'idempotent',false
  );
end;
$function$;

revoke all on function private.cleanup_math_practice_v1_questions_v1(text)
from public,anon,authenticated;
