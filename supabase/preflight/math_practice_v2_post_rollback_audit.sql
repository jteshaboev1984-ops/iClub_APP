-- READ-ONLY rollback audit for Mathematics P1 Practice v2
-- Run only after private.rollback_math_practice_v2_release_v1(...).

begin;
set transaction read only;
set local statement_timeout='20s';

do $practice_v2_rollback_audit$
declare
  v_audit private.practice_v2_release_switch_audit%rowtype;
  v_count integer;
begin
  select * into v_audit
  from private.practice_v2_release_switch_audit a
  where a.release_version='math_p1_practice_v2_2026_10_07'
  limit 1;

  if v_audit.id is null or v_audit.status<>'rolled_back' then
    raise exception 'rollback_audit_release_not_rolled_back';
  end if;

  if v_audit.rollback_tour_snapshot_before is null
     or v_audit.rollback_tour_snapshot_after is null
     or v_audit.rollback_tour_snapshot_before<>v_audit.rollback_tour_snapshot_after then
    raise exception 'rollback_audit_tour_invariant_not_proven';
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  where ppq.id=any(v_audit.old_active_membership_ids)
    and ppq.is_active is true;

  if v_count<>v_audit.old_active_membership_count then
    raise exception 'rollback_audit_old_memberships_expected_%_found_%',
      v_audit.old_active_membership_count,v_count;
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  where ppq.id=any(v_audit.new_membership_ids)
    and ppq.is_active is true;

  if v_count<>0 then
    raise exception 'rollback_audit_new_memberships_still_active_%',v_count;
  end if;

  select count(*)::integer into v_count
  from private.practice_v2_question_meta m
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and m.is_runtime_allowed is true;

  if v_count<>0 then
    raise exception 'rollback_audit_question_metadata_runtime_still_enabled_%',v_count;
  end if;

  select count(*)::integer into v_count
  from private.practice_v2_diagnostic_catalog d
  where d.release_version='math_p1_practice_v2_2026_10_07'
    and d.is_runtime_allowed is true;

  if v_count<>0 then
    raise exception 'rollback_audit_diagnostic_runtime_still_enabled_%',v_count;
  end if;

  -- Published question rows intentionally remain physically present/active so
  -- an already-started v2 session can finish and historical v2 review remains readable.
  select count(*)::integer into v_count
  from public.questions q
  join private.practice_v2_question_meta m on m.question_id=q.id
  where m.release_version='math_p1_practice_v2_2026_10_07'
    and q.is_active is true
    and q.quality_status='published';

  if v_count<>495 then
    raise exception 'rollback_audit_v2_history_rows_expected_495_found_%',v_count;
  end if;
end;
$practice_v2_rollback_audit$;

select
  release_version,
  status,
  old_active_membership_count,
  new_membership_count,
  rollback_tour_snapshot_before=rollback_tour_snapshot_after as rollback_tour_invariant_unchanged,
  completed_at,
  rollback_at
from private.practice_v2_release_switch_audit
where release_version='math_p1_practice_v2_2026_10_07';

rollback;
