-- Mathematics Practice v2 — atomic publish / rollback switch
-- Branch-only migration. It defines private release functions; it does NOT publish by itself.
--
-- Controlled release sequence:
-- 1) deploy v5 frontend + additive DB migrations;
-- 2) stage 495 questions inactive;
-- 3) run read-only preflight;
-- 4) call private.publish_math_practice_v2_release_v1(...) manually;
-- 5) run post-publish audit.
--
-- Protected rule: no Tour row is written by either function.

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
  v_new_membership_ids bigint[];
  v_new_question_ids bigint[];
  v_old_count integer;
  v_new_count integer;
  v_count integer;
  v_audit_id bigint;
  v_existing_status text;
  v_expected jsonb := '{"1":68,"2":80,"3":68,"4":77,"5":66,"6":70,"7":66}'::jsonb;
  v_tour_no integer;
begin
  if nullif(trim(coalesce(p_release_version,'')),'') is null then
    raise exception 'release_version_required';
  end if;

  perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);

  select s.id into v_subject_id
  from public.subjects s
  where s.subject_key='mathematics'
    and s.is_active is true
  limit 1;

  if v_subject_id is null then
    raise exception 'math_subject_not_found';
  end if;

  -- Unsafe legacy answer-oracle RPCs must already be closed by migration 03000.
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

  -- Required v5 learner entrypoints must exist before cutover.
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

  -- Staged release must be complete and still hidden.
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
    and p.tour_no between 1 and 7
    and m.release_version=p_release_version
    and ppq.is_active is false;

  v_new_count:=coalesce(cardinality(v_new_membership_ids),0);
  if v_new_count<>495 then
    raise exception 'release_expected_495_inactive_new_memberships_found_%',v_new_count;
  end if;

  -- Current learner-facing bank is archived by membership IDs, never by deleting questions/history.
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

  -- No release question may be a Tour question.
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

  insert into private.practice_v2_release_switch_audit(
    release_version,
    subject_id,
    status,
    old_active_membership_ids,
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
    coalesce(v_new_membership_ids,'{}'::bigint[]),
    coalesce(v_new_question_ids,'{}'::bigint[]),
    v_old_count,
    v_new_count,
    v_before,
    null,
    null,
    null,
    jsonb_build_object(
      'strategy','membership_switch_no_history_delete',
      'prepared_at',now()
    )
  )
  on conflict(release_version) do update
  set subject_id=excluded.subject_id,
      status='prepared',
      started_at=now(),
      completed_at=null,
      rollback_at=null,
      old_active_membership_ids=excluded.old_active_membership_ids,
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

  -- Prevent new sessions from entering superseded selector paths after cutover.
  execute 'revoke execute on function public.start_practice_session_auto_safe_v4(bigint,text) from authenticated';
  execute 'revoke execute on function public.start_practice_topic_drill_safe_v4(text,text,text,text) from authenticated';
  execute 'revoke execute on function public.get_recent_practice_mistakes_safe_v4(text,text,text,integer) from authenticated';
  execute 'revoke execute on function public.start_practice_mistakes_drill_safe_v4(text,bigint[],text) from authenticated';

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

  -- Exact post-switch membership totals.
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

  -- Every active membership in the seven Mathematics pools must now be from this release.
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
        'active_memberships_after',495
      )
  where id=v_audit_id;

  return jsonb_build_object(
    'ok',true,
    'release_version',p_release_version,
    'status','published',
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

  v_before:=private.practice_v2_tour_invariant_snapshot_v1(v_audit.subject_id);

  -- Stop new v2 selection, but keep question rows published/active so already-started
  -- v2 sessions and historical reviews can still finish safely.
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
        'strategy','membership_restore_keep_question_history'
      )
  where id=v_audit.id;

  return jsonb_build_object(
    'ok',true,
    'release_version',p_release_version,
    'status','rolled_back',
    'restored_memberships',v_audit.old_active_membership_count,
    'new_memberships_disabled',v_audit.new_membership_count,
    'tour_invariant_unchanged',true,
    'audit_id',v_audit.id,
    'idempotent',false
  );
end;
$function$;

revoke all on function private.rollback_math_practice_v2_release_v1(text)
from public,anon,authenticated;
