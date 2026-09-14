begin;

-- P2-59 periodic safety re-audit: a pre-beta cleanup must never erase a
-- learner-created session merely because the cohort is still marked synthetic.
-- Only explicitly tagged internal beta-scenario sessions are eligible for the
-- one-time governed cleanup path. Any other session provenance blocks cleanup.

create or replace function private.exam_prep_beta_cleanup_provenance_v1(p_cohort_id bigint)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_total int:=0;
  v_explicit_synthetic int:=0;
  v_ambiguous int:=0;
  v_authenticated_ambiguous int:=0;
begin
  if not exists(select 1 from private.exam_prep_beta_cohorts c where c.id=p_cohort_id) then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select
    count(*)::int,
    count(*) filter(where s.client_idempotency_key like 'beta-scenario-%')::int,
    count(*) filter(where s.client_idempotency_key not like 'beta-scenario-%')::int
  into v_total,v_explicit_synthetic,v_ambiguous
  from private.exam_prep_sessions s
  join private.exam_prep_beta_members bm
    on bm.user_id=s.user_id
   and bm.cohort_id=p_cohort_id
   and bm.member_status='active';

  select count(distinct s.id)::int
  into v_authenticated_ambiguous
  from private.exam_prep_sessions s
  join private.exam_prep_beta_members bm
    on bm.user_id=s.user_id
   and bm.cohort_id=p_cohort_id
   and bm.member_status='active'
  join private.exam_prep_audit_events a
    on a.object_type='private.exam_prep_sessions'
   and a.event_type='insert'
   and a.object_id=s.id::text
   and a.actor_role='authenticated'
  where s.client_idempotency_key not like 'beta-scenario-%';

  return jsonb_build_object(
    'total_sessions',v_total,
    'explicit_synthetic_sessions',v_explicit_synthetic,
    'ambiguous_sessions',v_ambiguous,
    'authenticated_ambiguous_sessions',v_authenticated_ambiguous,
    'eligible',v_ambiguous=0
  );
end;
$$;

revoke all on function private.exam_prep_beta_cleanup_provenance_v1(bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_cleanup_provenance_v1(bigint) to service_role;

create or replace function public.cleanup_exam_prep_beta_synthetic_progress_v2(
  p_cohort_key text,
  p_expected_blocking_rows integer,
  p_cleanup_evidence_ref text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_cohort_id bigint;
  v_provenance jsonb;
  v_result jsonb;
begin
  select id into v_cohort_id
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key;

  if v_cohort_id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  v_provenance:=private.exam_prep_beta_cleanup_provenance_v1(v_cohort_id);
  if coalesce((v_provenance->>'ambiguous_sessions')::int,0)>0 then
    raise exception 'exam_prep_cleanup_ambiguous_session_provenance count=% authenticated=%',
      v_provenance->>'ambiguous_sessions',
      v_provenance->>'authenticated_ambiguous_sessions';
  end if;

  v_result:=public.cleanup_exam_prep_beta_synthetic_progress_v1(
    p_cohort_key,
    p_expected_blocking_rows,
    p_cleanup_evidence_ref,
    p_acknowledgement
  );

  return v_result || jsonb_build_object('cleanup_provenance',v_provenance);
end;
$$;

-- Remove the direct service-role path so the provenance guard cannot be bypassed
-- accidentally. The v1 implementation remains as the internal transactional
-- primitive called only by the security-definer v2 wrapper.
revoke all on function public.cleanup_exam_prep_beta_synthetic_progress_v1(text,integer,text,text) from public,anon,authenticated,service_role;
revoke all on function public.cleanup_exam_prep_beta_synthetic_progress_v2(text,integer,text,text) from public,anon,authenticated;
grant execute on function public.cleanup_exam_prep_beta_synthetic_progress_v2(text,integer,text,text) to service_role;

commit;
