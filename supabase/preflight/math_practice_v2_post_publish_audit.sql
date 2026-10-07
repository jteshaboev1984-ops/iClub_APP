-- READ-ONLY post-publish audit for Mathematics P1 Practice v2
-- Run immediately after private.publish_math_practice_v2_release_v1(...).
-- No learner/Tour/Practice data is modified.

begin;
set transaction read only;
set local statement_timeout='20s';

do $practice_v2_post_publish$
declare
  v_subject_id bigint;
  v_audit private.practice_v2_release_switch_audit%rowtype;
  v_count integer;
  v_expected jsonb := '{"1":68,"2":80,"3":68,"4":77,"5":66,"6":70,"7":66}'::jsonb;
  v_tour_no integer;
begin
  select s.id into v_subject_id
  from public.subjects s
  where s.subject_key='mathematics'
    and s.is_active is true
  limit 1;

  if v_subject_id is null then
    raise exception 'post_publish_math_subject_missing';
  end if;

  select * into v_audit
  from private.practice_v2_release_switch_audit a
  where a.release_version='math_p1_practice_v2_2026_10_07'
  limit 1;

  if v_audit.id is null or v_audit.status<>'published' then
    raise exception 'post_publish_release_audit_not_published';
  end if;

  if v_audit.tour_snapshot_before is null
     or v_audit.tour_snapshot_after is null
     or v_audit.tour_snapshot_before<>v_audit.tour_snapshot_after then
    raise exception 'post_publish_release_tour_invariant_not_proven';
  end if;

  if v_audit.old_active_membership_count<>490
     or v_audit.new_membership_count<>495 then
    raise exception 'post_publish_release_membership_archive_counts_invalid';
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  where ppq.id=any(v_audit.old_active_membership_ids)
    and ppq.is_active is true;

  if v_count<>0 then
    raise exception 'post_publish_old_memberships_still_active_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  where ppq.id=any(v_audit.new_membership_ids)
    and ppq.is_active is true;

  if v_count<>495 then
    raise exception 'post_publish_new_memberships_expected_495_found_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=v_subject_id
    and p.tour_no between 1 and 7
    and p.is_active is true
    and ppq.is_active is true;

  if v_count<>495 then
    raise exception 'post_publish_active_bank_expected_495_found_%',v_count;
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
      and m.release_version='math_p1_practice_v2_2026_10_07'
      and m.lifecycle_state='published'
      and m.is_runtime_allowed is true;

    if v_count<>(v_expected->>v_tour_no::text)::integer then
      raise exception 'post_publish_practice_%_expected_%_found_%',
        v_tour_no,(v_expected->>v_tour_no::text)::integer,v_count;
    end if;
  end loop;

  select count(*)::integer into v_count
  from public.questions q
  join private.practice_v2_question_meta m on m.question_id=q.id
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and (
      q.is_active is not true
      or q.quality_status<>'published'
      or m.lifecycle_state<>'published'
      or m.is_runtime_allowed is not true
    );

  if v_count<>0 then
    raise exception 'post_publish_question_runtime_gate_invalid_count_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.question_answer_diagnostics d
  join private.practice_v2_question_meta m on m.question_id=d.question_id
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and d.quality_status<>'published';

  if v_count<>0 then
    raise exception 'post_publish_diagnostics_not_published_count_%',v_count;
  end if;

  select count(*)::integer into v_count
  from private.practice_v2_diagnostic_catalog d
  where d.release_version='math_p1_practice_v2_2026_10_07'
    and (
      d.approval_status<>'approved'
      or d.is_runtime_allowed is not true
    );

  if v_count<>0 then
    raise exception 'post_publish_diagnostic_catalog_runtime_gate_invalid_count_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.tour_questions tq
  join private.practice_v2_question_meta m on m.question_id=tq.question_id
  join public.tours t on t.id=tq.tour_id
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and t.subject_id=v_subject_id;

  if v_count<>0 then
    raise exception 'post_publish_practice_v2_tour_overlap_%',v_count;
  end if;

  -- Unsafe/bypass learner entrypoints must be closed after cutover.
  if has_function_privilege(
       'authenticated',
       'public.submit_practice_attempt(bigint,integer,numeric,integer,jsonb)',
       'execute'
     )
     or has_function_privilege(
       'authenticated',
       'public.submit_practice_answer_safe(bigint,bigint,text,integer,integer)',
       'execute'
     )
     or has_function_privilege(
       'authenticated',
       'public.start_practice_session_auto_safe_v4(bigint,text)',
       'execute'
     )
     or has_function_privilege(
       'authenticated',
       'public.start_practice_topic_drill_safe_v4(text,text,text,text)',
       'execute'
     )
     or has_function_privilege(
       'authenticated',
       'public.get_recent_practice_mistakes_safe_v4(text,text,text,integer)',
       'execute'
     )
     or has_function_privilege(
       'authenticated',
       'public.start_practice_mistakes_drill_safe_v4(text,bigint[],text)',
       'execute'
     ) then
    raise exception 'post_publish_superseded_oracle_or_selector_rpc_still_exposed';
  end if;

  if not has_function_privilege(
       'authenticated',
       'public.start_practice_session_auto_safe_v5(bigint,text)',
       'execute'
     )
     or not has_function_privilege(
       'authenticated',
       'public.submit_practice_session_answer_safe_v5(bigint,bigint,text,integer,integer)',
       'execute'
     )
     or not has_function_privilege(
       'authenticated',
       'public.finalize_practice_session_safe_v5(bigint,integer)',
       'execute'
     )
     or not has_function_privilege(
       'authenticated',
       'public.get_practice_review_full_safe_v5(bigint)',
       'execute'
     ) then
    raise exception 'post_publish_required_v5_rpc_not_exposed';
  end if;
end;
$practice_v2_post_publish$;

select
  p.tour_no as practice_no,
  count(*) filter(where ppq.is_active) as active_questions
from public.practice_pools p
left join public.practice_pool_questions ppq on ppq.pool_id=p.id
where p.subject_id=(
  select id
  from public.subjects
  where subject_key='mathematics' and is_active is true
  limit 1
)
  and p.tour_no between 1 and 7
group by p.tour_no
order by p.tour_no;

select
  release_version,
  status,
  old_active_membership_count,
  new_membership_count,
  tour_snapshot_before=tour_snapshot_after as tour_invariant_unchanged,
  started_at,
  completed_at
from private.practice_v2_release_switch_audit
where release_version='math_p1_practice_v2_2026_10_07';

rollback;
