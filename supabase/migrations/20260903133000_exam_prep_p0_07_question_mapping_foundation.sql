-- P0-07: additive P1 question -> canonical skill mapping foundation.
-- Existing public.questions rows are referenced only; this migration never mutates them.
-- Exam Prep eligibility is fail-closed: only an APPROVED row in an ACTIVE mapping version may be used later.

begin;

create table if not exists private.exam_prep_question_mapping_versions (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  mapping_version text not null,
  component_code text not null check (component_code in ('P1','P5')),
  status text not null default 'draft' check (status in ('draft','active','retired')),
  source_note text null,
  created_at timestamptz not null default now(),
  created_by uuid null,
  activated_at timestamptz null,
  activated_by uuid null,
  retired_at timestamptz null,
  retired_by uuid null,
  unique(program_version_id,mapping_version)
);
create unique index if not exists exam_prep_question_mapping_versions_one_active_component_idx
  on private.exam_prep_question_mapping_versions(program_version_id,component_code)
  where status='active';

create table if not exists private.exam_prep_question_skill_map (
  id bigint generated always as identity primary key,
  mapping_version_id bigint not null references private.exam_prep_question_mapping_versions(id) on delete restrict,
  question_id bigint not null references public.questions(id) on delete restrict,
  skill_code text not null,
  mapping_role text not null default 'primary' check (mapping_role in ('primary','secondary','prerequisite','mixed')),
  approval_status text not null default 'candidate' check (approval_status in ('candidate','approved','rejected','retired')),
  mapping_basis text not null,
  question_snapshot_md5 text not null check (char_length(question_snapshot_md5)=32),
  qa_scope_status text not null default 'pending' check (qa_scope_status in ('pending','pass','fail')),
  qa_math_status text not null default 'pending' check (qa_math_status in ('pending','pass','fail')),
  qa_language_status text not null default 'pending' check (qa_language_status in ('pending','pass','fail')),
  qa_technical_status text not null default 'pending' check (qa_technical_status in ('pending','pass','fail')),
  approved_at timestamptz null,
  approved_by uuid null,
  rejection_reason text null,
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  unique(mapping_version_id,question_id,skill_code,mapping_role),
  check (
    approval_status <> 'approved'
    or (qa_scope_status='pass' and qa_math_status='pass' and qa_language_status='pass' and qa_technical_status='pass')
  )
);

create unique index if not exists exam_prep_question_skill_map_one_primary_idx
  on private.exam_prep_question_skill_map(mapping_version_id,question_id)
  where mapping_role='primary' and approval_status in ('candidate','approved');
create index if not exists exam_prep_question_skill_map_skill_idx
  on private.exam_prep_question_skill_map(mapping_version_id,skill_code,approval_status);
create index if not exists exam_prep_question_skill_map_question_idx
  on private.exam_prep_question_skill_map(question_id);

-- Every mapped canonical skill must exist in the same program version and component.
create or replace function private.exam_prep_validate_question_skill_map_v1()
returns trigger
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_program_version_id bigint;
  v_component_code text;
begin
  select mv.program_version_id,mv.component_code
  into v_program_version_id,v_component_code
  from private.exam_prep_question_mapping_versions mv
  where mv.id=new.mapping_version_id;

  if not exists (
    select 1 from private.exam_prep_syllabus_nodes s
    where s.program_version_id=v_program_version_id
      and s.skill_code=new.skill_code
      and s.component_code=v_component_code
  ) then
    raise exception 'Question mapping skill % does not belong to mapping component %',new.skill_code,v_component_code;
  end if;

  if not exists (
    select 1 from public.questions q
    where q.id=new.question_id and q.subject_id=5
  ) then
    raise exception 'Question % is not a Mathematics subject_id=5 question',new.question_id;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_validate_question_skill_map_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_validate_question_skill_map_v1 on private.exam_prep_question_skill_map;
create trigger exam_prep_validate_question_skill_map_v1
before insert or update of mapping_version_id,question_id,skill_code
on private.exam_prep_question_skill_map
for each row execute function private.exam_prep_validate_question_skill_map_v1();

alter table private.exam_prep_question_mapping_versions enable row level security;
alter table private.exam_prep_question_skill_map enable row level security;
revoke all on private.exam_prep_question_mapping_versions from public,anon,authenticated;
revoke all on private.exam_prep_question_skill_map from public,anon,authenticated;
grant all on private.exam_prep_question_mapping_versions to service_role;
grant all on private.exam_prep_question_skill_map to service_role;
grant usage,select on sequence private.exam_prep_question_mapping_versions_id_seq to service_role;
grant usage,select on sequence private.exam_prep_question_skill_map_id_seq to service_role;

-- Audit changes through the existing private P0-05 audit ledger.
drop trigger if exists exam_prep_question_mapping_versions_audit_v1 on private.exam_prep_question_mapping_versions;
create trigger exam_prep_question_mapping_versions_audit_v1
after insert or update or delete on private.exam_prep_question_mapping_versions
for each row execute function private.exam_prep_audit_row_change_v1();
drop trigger if exists exam_prep_question_skill_map_audit_v1 on private.exam_prep_question_skill_map;
create trigger exam_prep_question_skill_map_audit_v1
after insert or update or delete on private.exam_prep_question_skill_map
for each row execute function private.exam_prep_audit_row_change_v1();

-- Draft mapping version only. No learner eligibility is enabled.
insert into private.exam_prep_question_mapping_versions(program_version_id,mapping_version,component_code,status,source_note)
select pv.id,'p1_existing_bank_v1','P1','draft','Conservative mapping of existing QA-reviewed Mathematics questions; no legacy question mutation.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,mapping_version) do nothing;

commit;
