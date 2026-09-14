begin;

-- P2-60: the project architect confirmed that the two 2026-09-07 browser-shaped
-- diagnostic sessions in the current canary cohort were internal tests and may
-- be removed before real monitoring. Preserve that decision as explicit
-- provenance instead of rewriting historical session keys.

create table if not exists private.exam_prep_beta_synthetic_session_overrides(
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete cascade,
  client_idempotency_key text not null,
  provenance_status text not null default 'confirmed_synthetic'
    check (provenance_status='confirmed_synthetic'),
  evidence_ref text not null check (char_length(trim(evidence_ref))>=8),
  confirmation_note text not null check (char_length(trim(confirmation_note))>=8),
  confirmed_at timestamptz not null default now(),
  primary key(cohort_id,client_idempotency_key)
);

alter table private.exam_prep_beta_synthetic_session_overrides enable row level security;
revoke all on table private.exam_prep_beta_synthetic_session_overrides from public,anon,authenticated;
grant select on table private.exam_prep_beta_synthetic_session_overrides to service_role;

-- Exact one-time production test provenance confirmed by the project architect.
-- The INSERT is cohort-scoped and becomes a no-op in isolated databases where
-- this production cohort is absent.
insert into private.exam_prep_beta_synthetic_session_overrides(
  cohort_id,client_idempotency_key,provenance_status,evidence_ref,confirmation_note
)
select
  c.id,
  v.client_idempotency_key,
  'confirmed_synthetic',
  'architect-confirmation-2026-09-14',
  'Project architect confirmed this 2026-09-07 diagnostic was an internal test and may be removed before real monitoring.'
from private.exam_prep_beta_cohorts c
cross join (values
  ('ep-diag-p1-1788760400390-605msqb'::text),
  ('ep-diag-p5-1788760476446-bohmcpy'::text)
) as v(client_idempotency_key)
where c.cohort_key='math_as_p1_p5_beta_2026_09_01'
on conflict(cohort_id,client_idempotency_key) do nothing;

create or replace function private.exam_prep_beta_cleanup_provenance_v1(p_cohort_id bigint)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_total int:=0;
  v_tagged_synthetic int:=0;
  v_confirmed_synthetic int:=0;
  v_ambiguous int:=0;
  v_authenticated_ambiguous int:=0;
begin
  if not exists(select 1 from private.exam_prep_beta_cohorts c where c.id=p_cohort_id) then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select
    count(*)::int,
    count(*) filter(where s.client_idempotency_key like 'beta-scenario-%')::int,
    count(*) filter(
      where s.client_idempotency_key not like 'beta-scenario-%'
        and exists(
          select 1
          from private.exam_prep_beta_synthetic_session_overrides o
          where o.cohort_id=p_cohort_id
            and o.client_idempotency_key=s.client_idempotency_key
            and o.provenance_status='confirmed_synthetic'
        )
    )::int,
    count(*) filter(
      where s.client_idempotency_key not like 'beta-scenario-%'
        and not exists(
          select 1
          from private.exam_prep_beta_synthetic_session_overrides o
          where o.cohort_id=p_cohort_id
            and o.client_idempotency_key=s.client_idempotency_key
            and o.provenance_status='confirmed_synthetic'
        )
    )::int
  into v_total,v_tagged_synthetic,v_confirmed_synthetic,v_ambiguous
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
  where s.client_idempotency_key not like 'beta-scenario-%'
    and not exists(
      select 1
      from private.exam_prep_beta_synthetic_session_overrides o
      where o.cohort_id=p_cohort_id
        and o.client_idempotency_key=s.client_idempotency_key
        and o.provenance_status='confirmed_synthetic'
    );

  return jsonb_build_object(
    'total_sessions',v_total,
    'explicit_synthetic_sessions',v_tagged_synthetic,
    'confirmed_synthetic_sessions',v_confirmed_synthetic,
    'synthetic_sessions',v_tagged_synthetic+v_confirmed_synthetic,
    'ambiguous_sessions',v_ambiguous,
    'authenticated_ambiguous_sessions',v_authenticated_ambiguous,
    'eligible',v_ambiguous=0
  );
end;
$$;

revoke all on function private.exam_prep_beta_cleanup_provenance_v1(bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_cleanup_provenance_v1(bigint) to service_role;

commit;
