-- P0-08: governed P5 opening-slice content schema.
-- Additive only. No existing question/history row is mutated.
-- All learner-facing content remains fail-closed until explicit PUBLISHED transition and later P0-09 membership APIs.

begin;

create table if not exists private.exam_prep_content_versions (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  content_version text not null,
  component_code text not null check(component_code in ('P1','P5')),
  release_label text not null,
  status text not null default 'draft' check(status in ('draft','approved','published','retired')),
  source_policy text not null,
  created_at timestamptz not null default now(),
  approved_at timestamptz null,
  published_at timestamptz null,
  retired_at timestamptz null,
  unique(program_version_id,content_version)
);

create table if not exists private.exam_prep_question_content_meta (
  id bigint generated always as identity primary key,
  content_version_id bigint not null references private.exam_prep_content_versions(id) on delete restrict,
  content_key text not null,
  question_id bigint not null unique references public.questions(id) on delete restrict,
  primary_skill_code text not null,
  secondary_skill_codes text[] not null default '{}'::text[],
  reserve_role text not null check(reserve_role in ('diagnostic','learning','retest','mixed','timed','unseen')),
  exposure_state text not null default 'withheld' check(exposure_state in ('withheld','released','retired')),
  lifecycle_state text not null default 'draft' check(lifecycle_state in ('draft','mathematical_review','language_review','technical_validation','approved','published','reserve','rejected','retired')),
  originality_attestation text not null,
  provenance_note text not null,
  official_scope_ref text not null,
  coursebook_mapping_ref text null,
  copyright_status text not null default 'pending' check(copyright_status in ('pending','pass','fail')),
  qa_scope_status text not null default 'pending' check(qa_scope_status in ('pending','pass','fail')),
  qa_math_status text not null default 'pending' check(qa_math_status in ('pending','pass','fail')),
  qa_language_status text not null default 'pending' check(qa_language_status in ('pending','pass','fail')),
  qa_technical_status text not null default 'pending' check(qa_technical_status in ('pending','pass','fail')),
  diagnostic_rule_status text not null default 'not_applicable' check(diagnostic_rule_status in ('not_applicable','pending','approved')),
  question_snapshot_md5 text not null check(char_length(question_snapshot_md5)=32),
  approved_at timestamptz null,
  published_at timestamptz null,
  rejection_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(content_version_id,content_key),
  check(lifecycle_state not in ('approved','published','reserve') or
    (copyright_status='pass' and qa_scope_status='pass' and qa_math_status='pass' and qa_language_status='pass' and qa_technical_status='pass')),
  check(reserve_role<>'diagnostic' or lifecycle_state not in ('approved','published','reserve') or diagnostic_rule_status='approved')
);

create table if not exists private.exam_prep_written_tasks (
  id bigint generated always as identity primary key,
  content_version_id bigint not null references private.exam_prep_content_versions(id) on delete restrict,
  task_key text not null,
  component_code text not null check(component_code in ('P1','P5')),
  primary_skill_code text not null,
  secondary_skill_codes text[] not null default '{}'::text[],
  task_version text not null,
  prompt_en text not null,
  prompt_ru text not null,
  prompt_uz text not null,
  rubric_json jsonb not null,
  self_review_en text not null,
  self_review_ru text not null,
  self_review_uz text not null,
  lifecycle_state text not null default 'draft' check(lifecycle_state in ('draft','mathematical_review','language_review','technical_validation','approved','published','retired')),
  copyright_status text not null default 'pending' check(copyright_status in ('pending','pass','fail')),
  qa_math_status text not null default 'pending' check(qa_math_status in ('pending','pass','fail')),
  qa_language_status text not null default 'pending' check(qa_language_status in ('pending','pass','fail')),
  qa_technical_status text not null default 'pending' check(qa_technical_status in ('pending','pass','fail')),
  created_at timestamptz not null default now(),
  approved_at timestamptz null,
  unique(content_version_id,task_key,task_version),
  check(lifecycle_state not in ('approved','published') or
    (copyright_status='pass' and qa_math_status='pass' and qa_language_status='pass' and qa_technical_status='pass'))
);

create table if not exists private.exam_prep_assessments (
  id bigint generated always as identity primary key,
  content_version_id bigint not null references private.exam_prep_content_versions(id) on delete restrict,
  assessment_key text not null,
  assessment_version text not null,
  component_code text not null check(component_code in ('P1','P5')),
  assessment_type text not null check(assessment_type in ('diagnostic','learning','retest','mixed','timed')),
  status text not null default 'draft' check(status in ('draft','approved','published','retired')),
  title_en text not null,
  title_ru text not null,
  title_uz text not null,
  created_at timestamptz not null default now(),
  approved_at timestamptz null,
  unique(content_version_id,assessment_key,assessment_version)
);

create table if not exists private.exam_prep_assessment_items (
  assessment_id bigint not null references private.exam_prep_assessments(id) on delete cascade,
  item_order smallint not null,
  question_id bigint null references public.questions(id) on delete restrict,
  written_task_id bigint null references private.exam_prep_written_tasks(id) on delete restrict,
  primary_skill_code text not null,
  reserve_role text not null check(reserve_role in ('diagnostic','learning','retest','mixed','timed','written')),
  is_holdout boolean not null default false,
  created_at timestamptz not null default now(),
  primary key(assessment_id,item_order),
  check((question_id is not null)::int + (written_task_id is not null)::int = 1)
);

-- Validate canonical skill ownership for all P5 content metadata and tasks.
create or replace function private.exam_prep_validate_content_skill_v1()
returns trigger language plpgsql security invoker set search_path='' as $$
declare v_program bigint; v_component text;
begin
  if tg_table_name='exam_prep_question_content_meta' then
    select cv.program_version_id,cv.component_code into v_program,v_component
    from private.exam_prep_content_versions cv where cv.id=new.content_version_id;
  elsif tg_table_name='exam_prep_written_tasks' then
    select cv.program_version_id,new.component_code into v_program,v_component
    from private.exam_prep_content_versions cv where cv.id=new.content_version_id;
  else
    return new;
  end if;
  if not exists(select 1 from private.exam_prep_syllabus_nodes s where s.program_version_id=v_program and s.skill_code=new.primary_skill_code and s.component_code=v_component) then
    raise exception 'Content primary skill % is not owned by component %',new.primary_skill_code,v_component;
  end if;
  return new;
end; $$;
revoke all on function private.exam_prep_validate_content_skill_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_question_content_skill_v1 on private.exam_prep_question_content_meta;
create trigger exam_prep_question_content_skill_v1 before insert or update of content_version_id,primary_skill_code on private.exam_prep_question_content_meta for each row execute function private.exam_prep_validate_content_skill_v1();
drop trigger if exists exam_prep_written_task_skill_v1 on private.exam_prep_written_tasks;
create trigger exam_prep_written_task_skill_v1 before insert or update of content_version_id,component_code,primary_skill_code on private.exam_prep_written_tasks for each row execute function private.exam_prep_validate_content_skill_v1();

-- Private/admin-only until P0-09 safe delivery APIs exist.
do $$ declare t text; begin
  foreach t in array array['exam_prep_content_versions','exam_prep_question_content_meta','exam_prep_written_tasks','exam_prep_assessments','exam_prep_assessment_items'] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

grant usage,select on sequence private.exam_prep_content_versions_id_seq to service_role;
grant usage,select on sequence private.exam_prep_question_content_meta_id_seq to service_role;
grant usage,select on sequence private.exam_prep_written_tasks_id_seq to service_role;
grant usage,select on sequence private.exam_prep_assessments_id_seq to service_role;

-- Audit all governance transitions.
do $$ begin
  execute 'create trigger exam_prep_content_versions_audit_v1 after insert or update or delete on private.exam_prep_content_versions for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_question_content_meta_audit_v1 after insert or update or delete on private.exam_prep_question_content_meta for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_written_tasks_audit_v1 after insert or update or delete on private.exam_prep_written_tasks for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_assessments_audit_v1 after insert or update or delete on private.exam_prep_assessments for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;

insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
select pv.id,'p5_repr_beta_v1','P5','P5 Representation of Data controlled-beta opening slice','draft',
       'Original iClub content only; official Cambridge syllabus defines scope; Complete Probability & Statistics 1 used only for teaching/source mapping; no source question/diagram/answer text copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

commit;
