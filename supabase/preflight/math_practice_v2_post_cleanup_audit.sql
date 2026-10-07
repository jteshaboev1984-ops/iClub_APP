-- READ-ONLY audit after optional legacy Mathematics Practice question cleanup.
-- Confirms that the retired Practice bank is removed only where safe and that Tours remain protected.

begin;
set transaction read only;
set local statement_timeout='20s';

do $practice_v2_post_cleanup$
declare
  v_subject_id bigint;
  v_audit private.practice_v2_release_switch_audit%rowtype;
  v_count integer;
  v_deleted integer;
  v_retained integer;
begin
  select id into v_subject_id
  from public.subjects
  where subject_key='mathematics' and is_active is true
  limit 1;

  if v_subject_id is null then
    raise exception 'post_cleanup_math_subject_missing';
  end if;

  select * into v_audit
  from private.practice_v2_release_switch_audit
  where release_version='math_p1_practice_v2_2026_10_07'
  limit 1;

  if v_audit.id is null or v_audit.status<>'published' then
    raise exception 'post_cleanup_release_not_published';
  end if;

  if not (v_audit.notes ? 'legacy_cleanup_completed_at') then
    raise exception 'post_cleanup_marker_missing';
  end if;

  if (v_audit.notes->'legacy_cleanup_tour_snapshot_before')
     <> (v_audit.notes->'legacy_cleanup_tour_snapshot_after') then
    raise exception 'post_cleanup_tour_invariant_not_proven';
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions
  where id=any(v_audit.old_active_membership_ids);

  if v_count<>0 then
    raise exception 'post_cleanup_legacy_memberships_still_present_%',v_count;
  end if;

  select count(*)::integer into v_count
  from public.practice_pool_questions ppq
  join public.practice_pools p on p.id=ppq.pool_id
  join private.practice_v2_question_meta m on m.question_id=ppq.question_id
  where p.subject_id=v_subject_id
    and p.tour_no between 1 and 7
    and p.is_active is true
    and ppq.is_active is true
    and m.release_version='math_p1_practice_v2_2026_10_07'
    and m.lifecycle_state='published'
    and m.is_runtime_allowed is true;

  if v_count<>495 then
    raise exception 'post_cleanup_active_v2_bank_expected_495_found_%',v_count;
  end if;

  v_deleted:=coalesce((v_audit.notes->>'legacy_questions_deleted')::integer,0);
  v_retained:=coalesce((v_audit.notes->>'legacy_questions_retained')::integer,0);

  if v_deleted+v_retained<>coalesce(cardinality(v_audit.old_question_ids),0) then
    raise exception 'post_cleanup_legacy_question_accounting_invalid';
  end if;

  select count(*)::integer into v_count
  from public.questions q
  where q.id=any(v_audit.old_question_ids);

  if v_count<>v_retained then
    raise exception 'post_cleanup_retained_question_count_expected_%_found_%',
      v_retained,v_count;
  end if;

  -- Every retained legacy question must have a reason outside retired Practice.
  select count(*)::integer into v_count
  from public.questions q
  where q.id=any(v_audit.old_question_ids)
    and not exists(select 1 from public.tour_questions tq where tq.question_id=q.id)
    and not exists(select 1 from public.tour_answers ta where ta.question_id=q.id)
    and not exists(select 1 from public.tour_session_answers_v4 tsa where tsa.question_id=q.id)
    and not exists(select 1 from private.exam_prep_assessment_items x where x.question_id=q.id)
    and not exists(select 1 from private.exam_prep_session_items x where x.question_id=q.id)
    and not exists(select 1 from private.exam_prep_question_content_meta x where x.question_id=q.id)
    and not exists(select 1 from public.question_version_links x where x.old_question_id=q.id or x.new_question_id=q.id)
    and not exists(select 1 from private.exam_prep_legacy_evidence_references x where x.question_id=q.id);

  if v_count<>0 then
    raise exception 'post_cleanup_unprotected_legacy_questions_remain_%',v_count;
  end if;

  -- Tour-linked legacy questions must still exist.
  select count(*)::integer into v_count
  from public.tour_questions tq
  where tq.question_id=any(v_audit.old_question_ids)
    and not exists(select 1 from public.questions q where q.id=tq.question_id);

  if v_count<>0 then
    raise exception 'post_cleanup_tour_linked_question_missing_%',v_count;
  end if;
end;
$practice_v2_post_cleanup$;

select
  coalesce((a.notes->>'legacy_questions_deleted')::integer,0) as legacy_questions_deleted,
  coalesce((a.notes->>'legacy_questions_retained')::integer,0) as legacy_questions_retained,
  (a.notes->'legacy_cleanup_tour_snapshot_before')
    = (a.notes->'legacy_cleanup_tour_snapshot_after') as tour_invariant_unchanged
from private.practice_v2_release_switch_audit a
where a.release_version='math_p1_practice_v2_2026_10_07';

rollback;
