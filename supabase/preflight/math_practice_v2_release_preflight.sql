-- READ-ONLY preflight for Mathematics P1 Practice v2 controlled release
-- Expected phase: all Practice v2 foundation migrations + staging package applied,
-- but release switch NOT yet published.
--
-- This script must not modify production. It aborts on drift that could endanger
-- protected Tours or publish a partial/incorrect Practice bank.

begin;
set transaction read only;
set local statement_timeout='20s';

do $practice_v2_preflight$
declare
  v_subject_id bigint;
  v_count bigint;
  v_overlap bigint;
  v_expected jsonb := '{"1":68,"2":80,"3":68,"4":77,"5":66,"6":70,"7":66}'::jsonb;
  v_tour_no integer;
  v_expected_n integer;
  v_actual_n integer;
begin
  select s.id into v_subject_id
  from public.subjects s
  where s.subject_key='mathematics'
    and s.is_active is true
  limit 1;

  if v_subject_id is null then
    raise exception 'preflight_math_subject_missing';
  end if;

  select count(*) into v_count
  from public.practice_pools p
  where p.subject_id=v_subject_id
    and p.is_active is true
    and p.tour_no between 1 and 7;

  if v_count<>7 then
    raise exception 'preflight_expected_7_active_math_pools_found_%',v_count;
  end if;

  -- Existing learner-facing bank must still be the known 490-membership baseline.
  select count(*) into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  where p.subject_id=v_subject_id
    and p.is_active is true
    and ppq.is_active is true;

  if v_count<>490 then
    raise exception 'preflight_active_legacy_membership_drift_expected_490_found_%',v_count;
  end if;

  -- No currently active Practice question may also be a Tour question.
  select count(*) into v_overlap
  from (
    select distinct ppq.question_id
    from public.practice_pool_questions ppq
    join public.practice_pools p on p.id=ppq.pool_id
    where p.subject_id=v_subject_id
      and p.is_active is true
      and ppq.is_active is true
  ) ap
  join public.tour_questions tq
    on tq.question_id=ap.question_id
   and tq.is_active is true
  join public.tours t
    on t.id=tq.tour_id
   and t.subject_id=v_subject_id;

  if v_overlap<>0 then
    raise exception 'preflight_active_practice_tour_overlap_found_%',v_overlap;
  end if;

  -- The complete staged release must exist exactly once.
  select count(*) into v_count
  from private.practice_v2_question_meta m
  where m.release_version='math_p1_practice_v2_2026_10_07';

  if v_count<>495 then
    raise exception 'preflight_staged_meta_expected_495_found_%',v_count;
  end if;

  if (
    select count(distinct m.content_key)
    from private.practice_v2_question_meta m
    where m.release_version='math_p1_practice_v2_2026_10_07'
  )<>495 then
    raise exception 'preflight_staged_content_keys_not_unique_495';
  end if;

  -- Staged questions must still be invisible before cutover.
  select count(*) into v_count
  from public.questions q
  join private.practice_v2_question_meta m on m.question_id=q.id
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and (
      q.is_active is true
      or q.quality_status<>'draft'
      or m.is_runtime_allowed is true
      or m.lifecycle_state<>'approved'
    );

  if v_count<>0 then
    raise exception 'preflight_staged_questions_not_safely_inactive_count_%',v_count;
  end if;

  select count(*) into v_count
  from public.practice_pool_questions ppq
  join private.practice_v2_question_meta m on m.question_id=ppq.question_id
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and ppq.is_active is true;

  if v_count<>0 then
    raise exception 'preflight_staged_memberships_already_active_count_%',v_count;
  end if;

  -- Staged Practice questions must never be Tour members.
  select count(*) into v_count
  from public.tour_questions tq
  join private.practice_v2_question_meta m on m.question_id=tq.question_id
  where m.release_version='math_p1_practice_v2_2026_10_07';

  if v_count<>0 then
    raise exception 'preflight_staged_practice_questions_linked_to_tours_%',v_count;
  end if;

  -- All four QA gates must be passed before publication.
  select count(*) into v_count
  from private.practice_v2_question_meta m
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and (
      m.qa_math_status<>'passed'
      or m.qa_language_status<>'passed'
      or m.qa_technical_status<>'passed'
      or m.qa_tour_separation_status<>'passed'
    );

  if v_count<>0 then
    raise exception 'preflight_question_qa_not_passed_count_%',v_count;
  end if;

  -- Exact per-Practice staged sizes.
  for v_tour_no in 1..7 loop
    v_expected_n:=(v_expected->>v_tour_no::text)::integer;

    select count(*)::integer into v_actual_n
    from private.practice_v2_question_meta m
    where m.release_version='math_p1_practice_v2_2026_10_07'
      and m.practice_no=v_tour_no;

    if v_actual_n<>v_expected_n then
      raise exception 'preflight_practice_%_expected_%_found_%',
        v_tour_no,v_expected_n,v_actual_n;
    end if;

    select count(*)::integer into v_actual_n
    from public.practice_pool_questions ppq
    join public.practice_pools p on p.id=ppq.pool_id
    join private.practice_v2_question_meta m on m.question_id=ppq.question_id
    where m.release_version='math_p1_practice_v2_2026_10_07'
      and m.practice_no=v_tour_no
      and p.subject_id=v_subject_id
      and p.tour_no=v_tour_no;

    if v_actual_n<>v_expected_n then
      raise exception 'preflight_practice_%_membership_expected_%_found_%',
        v_tour_no,v_expected_n,v_actual_n;
    end if;
  end loop;

  -- New bank must not reuse any current active legacy membership question id.
  select count(*) into v_count
  from private.practice_v2_question_meta m
  join public.practice_pool_questions old_ppq
    on old_ppq.question_id=m.question_id
   and old_ppq.is_active is true
  join public.practice_pools old_p
    on old_p.id=old_ppq.pool_id
   and old_p.subject_id=v_subject_id
  where m.release_version='math_p1_practice_v2_2026_10_07';

  if v_count<>0 then
    raise exception 'preflight_new_bank_reuses_current_active_question_ids_%',v_count;
  end if;

  -- Diagnostic catalog must remain runtime-disabled until the same atomic cutover.
  select count(*) into v_count
  from private.practice_v2_diagnostic_catalog d
  where d.release_version='math_p1_practice_v2_2026_10_07'
    and (
      d.approval_status<>'approved'
      or d.is_runtime_allowed is true
    );

  if v_count<>0 then
    raise exception 'preflight_diagnostic_catalog_not_safely_staged_count_%',v_count;
  end if;

  -- Protected Tour snapshot function must be available and non-empty.
  if private.practice_v2_tour_invariant_snapshot_v1(v_subject_id) is null then
    raise exception 'preflight_tour_snapshot_unavailable';
  end if;
end;
$practice_v2_preflight$;

-- Human-readable read-only evidence after all assertions.
select
  private.practice_v2_tour_invariant_snapshot_v1(s.id) as protected_tour_snapshot
from public.subjects s
where s.subject_key='mathematics'
  and s.is_active is true;

select
  p.tour_no as practice_no,
  count(*) filter(where ppq.is_active) as active_before_release,
  count(*) filter(
    where m.release_version='math_p1_practice_v2_2026_10_07'
  ) as staged_v2_memberships
from public.practice_pools p
left join public.practice_pool_questions ppq on ppq.pool_id=p.id
left join private.practice_v2_question_meta m on m.question_id=ppq.question_id
where p.subject_id=(
  select id from public.subjects where subject_key='mathematics' and is_active is true limit 1
)
  and p.tour_no between 1 and 7
group by p.tour_no
order by p.tour_no;

rollback;
