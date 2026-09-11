begin;

-- P2-24 makes the canonical mixed mapping explicit about what the current
-- objective-only runtime can and cannot claim. The 21 materialized sets are
-- useful same-component transfer evidence, but they contain no governed
-- written item and therefore must never be interpreted as canonical L4/L5
-- mixed mastery or Mentor Verified evidence.

alter table private.exam_prep_assessment_mixed_nodes
  add column if not exists evidence_scope text not null default 'objective_transfer_only',
  add column if not exists written_mastery_ready boolean not null default false,
  add column if not exists human_verification_required boolean not null default true;

do $$
begin
  if not exists(
    select 1 from pg_constraint
    where conrelid='private.exam_prep_assessment_mixed_nodes'::regclass
      and conname='exam_prep_assessment_mixed_nodes_evidence_scope_check'
  ) then
    alter table private.exam_prep_assessment_mixed_nodes
      add constraint exam_prep_assessment_mixed_nodes_evidence_scope_check
      check(evidence_scope in ('objective_transfer_only','canonical_written_mastery_ready'));
  end if;
  if not exists(
    select 1 from pg_constraint
    where conrelid='private.exam_prep_assessment_mixed_nodes'::regclass
      and conname='exam_prep_assessment_mixed_nodes_written_scope_check'
  ) then
    alter table private.exam_prep_assessment_mixed_nodes
      add constraint exam_prep_assessment_mixed_nodes_written_scope_check
      check((not written_mastery_ready) or evidence_scope='canonical_written_mastery_ready');
  end if;
end $$;

update private.exam_prep_assessment_mixed_nodes amn
set evidence_scope='objective_transfer_only',
    written_mastery_ready=false,
    human_verification_required=true
where not exists(
  select 1
  from private.exam_prep_assessment_items ai
  where ai.assessment_id=amn.assessment_id
    and ai.written_task_id is not null
);

create or replace function private.exam_prep_canonical_mixed_written_mastery_ready_v1(
  p_assessment_id bigint,
  p_component_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_assessment_mixed_nodes amn
    join private.exam_prep_assessments a on a.id=amn.assessment_id
    where amn.assessment_id=p_assessment_id
      and amn.component_code=p_component_code
      and a.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and amn.evidence_scope='canonical_written_mastery_ready'
      and amn.written_mastery_ready is true
      and amn.human_verification_required is true
      and exists(
        select 1 from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id and ai.written_task_id is not null
      )
  );
$$;
revoke all on function private.exam_prep_canonical_mixed_written_mastery_ready_v1(bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_canonical_mixed_written_mastery_ready_v1(bigint,text) to service_role;
comment on function private.exam_prep_canonical_mixed_written_mastery_ready_v1(bigint,text) is
'Fail-closed canonical mixed mastery-content gate. Current P2-21 objective transfer sets return false until governed written mixed content exists and is explicitly approved.';

comment on column private.exam_prep_assessment_mixed_nodes.evidence_scope is
'Academic claim scope of this assessment-to-canonical-mixed mapping. objective_transfer_only cannot award canonical L4/L5 mastery.';
comment on column private.exam_prep_assessment_mixed_nodes.written_mastery_ready is
'Explicit governance flag. False until the canonical mixed node has governed written mixed evidence content suitable for the node mastery rule.';
comment on column private.exam_prep_assessment_mixed_nodes.human_verification_required is
'Canonical mixed mastery requires human verification where the signed map requires written judgement; this flag does not create a Mentor Care entitlement.';

do $$
declare v_total int; v_bad int; begin
  select count(*),count(*) filter(where evidence_scope<>'objective_transfer_only' or written_mastery_ready)
    into v_total,v_bad
  from private.exam_prep_assessment_mixed_nodes;
  if v_total<>21 then raise exception 'P2-24 expected 21 canonical owner-component mappings, got %',v_total; end if;
  if v_bad<>0 then raise exception 'P2-24 current canonical mixed mapping claim scope is not fail-closed'; end if;
end $$;

commit;