-- P1-05: optional read-only legacy evidence reference adapter.
-- Existing Practice/Tour/history/rating/certificate rows are read only and are never updated.
-- Legacy references are explicitly non-crediting: they cannot create Exam Prep evidence, mastery, stage or readiness.

begin;

create table if not exists private.exam_prep_legacy_reference_configs (
  id bigint generated always as identity primary key,
  mapping_version_id bigint not null unique references private.exam_prep_question_mapping_versions(id) on delete restrict,
  adapter_status text not null default 'shadow' check (adapter_status in ('shadow','active','paused')),
  source_type text not null default 'legacy_readonly' check (source_type='legacy_readonly'),
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

create table if not exists private.exam_prep_legacy_evidence_references (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  mapping_version_id bigint not null references private.exam_prep_question_mapping_versions(id) on delete restrict,
  mapping_version text not null,
  user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check (component_code in ('P1','P5')),
  skill_code text not null,
  question_id bigint not null references public.questions(id) on delete restrict,
  legacy_source text not null check (legacy_source in ('practice_answers','tour_answers')),
  legacy_row_id bigint not null,
  legacy_attempt_id bigint not null,
  is_correct boolean not null,
  time_spent_sec integer not null check (time_spent_sec>=0),
  occurred_at timestamptz not null,
  source_type text not null default 'legacy_readonly' check (source_type='legacy_readonly'),
  academic_credit boolean not null default false check (academic_credit=false),
  verification_claim text not null default 'none' check (verification_claim='none'),
  legacy_snapshot_md5 text not null check (char_length(legacy_snapshot_md5)=32),
  created_at timestamptz not null default now(),
  created_by uuid null,
  unique(mapping_version_id,legacy_source,legacy_row_id)
);

create index if not exists exam_prep_legacy_refs_user_component_idx
  on private.exam_prep_legacy_evidence_references(user_id,component_code,occurred_at desc);
create index if not exists exam_prep_legacy_refs_skill_idx
  on private.exam_prep_legacy_evidence_references(mapping_version_id,skill_code,user_id);
create index if not exists exam_prep_legacy_refs_question_idx
  on private.exam_prep_legacy_evidence_references(question_id);

create or replace function private.exam_prep_validate_legacy_reference_v1()
returns trigger
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_program bigint;
  v_component text;
  v_mapping text;
begin
  if new.source_type<>'legacy_readonly' or new.academic_credit or new.verification_claim<>'none' then
    raise exception 'exam_prep_legacy_reference_must_be_non_crediting';
  end if;

  select mv.program_version_id,mv.component_code,mv.mapping_version
  into v_program,v_component,v_mapping
  from private.exam_prep_question_mapping_versions mv
  where mv.id=new.mapping_version_id and mv.status='active';

  if v_program is null then
    raise exception 'exam_prep_legacy_reference_active_mapping_required';
  end if;
  if new.program_version_id<>v_program or new.component_code<>v_component or new.mapping_version<>v_mapping then
    raise exception 'exam_prep_legacy_reference_mapping_mismatch';
  end if;

  if not exists(
    select 1
    from private.exam_prep_question_skill_map m
    where m.mapping_version_id=new.mapping_version_id
      and m.question_id=new.question_id
      and m.skill_code=new.skill_code
      and m.mapping_role='primary'
      and m.approval_status='approved'
  ) then
    raise exception 'exam_prep_legacy_reference_unapproved_question_mapping';
  end if;

  return new;
end;
$$;
revoke all on function private.exam_prep_validate_legacy_reference_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_validate_legacy_reference_v1 on private.exam_prep_legacy_evidence_references;
create trigger exam_prep_validate_legacy_reference_v1
before insert or update of program_version_id,mapping_version_id,mapping_version,component_code,skill_code,question_id,source_type,academic_credit,verification_claim
on private.exam_prep_legacy_evidence_references
for each row execute function private.exam_prep_validate_legacy_reference_v1();

alter table private.exam_prep_legacy_reference_configs enable row level security;
alter table private.exam_prep_legacy_evidence_references enable row level security;
revoke all on private.exam_prep_legacy_reference_configs from public,anon,authenticated;
revoke all on private.exam_prep_legacy_evidence_references from public,anon,authenticated;
grant all on private.exam_prep_legacy_reference_configs to service_role;
grant all on private.exam_prep_legacy_evidence_references to service_role;
grant usage,select on sequence private.exam_prep_legacy_reference_configs_id_seq to service_role;
grant usage,select on sequence private.exam_prep_legacy_evidence_references_id_seq to service_role;

drop trigger if exists exam_prep_legacy_reference_configs_audit_v1 on private.exam_prep_legacy_reference_configs;
create trigger exam_prep_legacy_reference_configs_audit_v1
after insert or update or delete on private.exam_prep_legacy_reference_configs
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_legacy_evidence_references_audit_v1 on private.exam_prep_legacy_evidence_references;
create trigger exam_prep_legacy_evidence_references_audit_v1
after insert or update or delete on private.exam_prep_legacy_evidence_references
for each row execute function private.exam_prep_audit_row_change_v1();

-- Service-only snapshot builder. It reads legacy rows but writes only the additive reference table.
create or replace function public.sync_exam_prep_legacy_references_v1(p_mapping_version text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_mv private.exam_prep_question_mapping_versions%rowtype;
  v_practice int:=0;
  v_tour int:=0;
begin
  select * into v_mv
  from private.exam_prep_question_mapping_versions mv
  where mv.mapping_version=p_mapping_version and mv.status='active';
  if not found then raise exception 'exam_prep_active_mapping_not_found'; end if;

  insert into private.exam_prep_legacy_reference_configs(mapping_version_id,adapter_status,source_type)
  values(v_mv.id,'shadow','legacy_readonly')
  on conflict(mapping_version_id) do nothing;

  with ins as (
    insert into private.exam_prep_legacy_evidence_references(
      program_version_id,mapping_version_id,mapping_version,user_id,component_code,skill_code,question_id,
      legacy_source,legacy_row_id,legacy_attempt_id,is_correct,time_spent_sec,occurred_at,
      source_type,academic_credit,verification_claim,legacy_snapshot_md5
    )
    select
      v_mv.program_version_id,v_mv.id,v_mv.mapping_version,a.user_id,v_mv.component_code,m.skill_code,pa.question_id,
      'practice_answers',pa.id,pa.attempt_id,pa.is_correct,greatest(pa.time_spent,0),pa.created_at,
      'legacy_readonly',false,'none',
      md5(concat_ws('|',pa.id::text,pa.attempt_id::text,pa.question_id::text,coalesce(pa.user_answer,''),pa.is_correct::text,pa.time_spent::text,pa.created_at::text))
    from public.practice_answers pa
    join public.practice_attempts a on a.id=pa.attempt_id
    join private.exam_prep_question_skill_map m
      on m.mapping_version_id=v_mv.id and m.question_id=pa.question_id
     and m.mapping_role='primary' and m.approval_status='approved'
    where a.subject_id=5 and coalesce(a.is_lab,false)=false
    on conflict(mapping_version_id,legacy_source,legacy_row_id) do nothing
    returning 1
  ) select count(*) into v_practice from ins;

  with ins as (
    insert into private.exam_prep_legacy_evidence_references(
      program_version_id,mapping_version_id,mapping_version,user_id,component_code,skill_code,question_id,
      legacy_source,legacy_row_id,legacy_attempt_id,is_correct,time_spent_sec,occurred_at,
      source_type,academic_credit,verification_claim,legacy_snapshot_md5
    )
    select
      v_mv.program_version_id,v_mv.id,v_mv.mapping_version,a.user_id,v_mv.component_code,m.skill_code,ta.question_id,
      'tour_answers',ta.id,ta.attempt_id,ta.is_correct,greatest(ta.time_spent,0),ta.created_at,
      'legacy_readonly',false,'none',
      md5(concat_ws('|',ta.id::text,ta.attempt_id::text,ta.question_id::text,coalesce(ta.user_answer,''),ta.answered::text,ta.is_correct::text,ta.time_spent::text,coalesce(ta.finish_reason,''),ta.created_at::text))
    from public.tour_answers ta
    join public.tour_attempts a on a.id=ta.attempt_id
    join public.tours t on t.id=a.tour_id
    join private.exam_prep_question_skill_map m
      on m.mapping_version_id=v_mv.id and m.question_id=ta.question_id
     and m.mapping_role='primary' and m.approval_status='approved'
    where t.subject_id=5 and ta.answered=true
    on conflict(mapping_version_id,legacy_source,legacy_row_id) do nothing
    returning 1
  ) select count(*) into v_tour from ins;

  return jsonb_build_object(
    'mapping_version',v_mv.mapping_version,
    'component_code',v_mv.component_code,
    'source_type','legacy_readonly',
    'academic_credit',false,
    'practice_inserted',v_practice,
    'tour_inserted',v_tour,
    'inserted_total',v_practice+v_tour
  );
end;
$$;
revoke all on function public.sync_exam_prep_legacy_references_v1(text) from public,anon,authenticated;
grant execute on function public.sync_exam_prep_legacy_references_v1(text) to service_role;

create or replace function public.set_exam_prep_legacy_reference_adapter_v1(p_mapping_version text,p_status text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_id bigint;
  v_component text;
begin
  if p_status not in ('shadow','active','paused') then raise exception 'exam_prep_invalid_legacy_adapter_status'; end if;
  select mv.id,mv.component_code into v_id,v_component
  from private.exam_prep_question_mapping_versions mv
  where mv.mapping_version=p_mapping_version and mv.status='active';
  if v_id is null then raise exception 'exam_prep_active_mapping_not_found'; end if;

  insert into private.exam_prep_legacy_reference_configs(mapping_version_id,adapter_status,source_type,updated_at)
  values(v_id,p_status,'legacy_readonly',now())
  on conflict(mapping_version_id) do update set adapter_status=excluded.adapter_status,updated_at=now();

  return jsonb_build_object('mapping_version',p_mapping_version,'component_code',v_component,'adapter_status',p_status);
end;
$$;
revoke all on function public.set_exam_prep_legacy_reference_adapter_v1(text,text) from public,anon,authenticated;
grant execute on function public.set_exam_prep_legacy_reference_adapter_v1(text,text) to service_role;

-- Learner-safe summary. It exposes no answer text, question key, score recalculation or mastery credit.
create or replace function public.get_exam_prep_legacy_reference_summary_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_component text:=upper(coalesce(p_component_code,''));
  v_cfg record;
  v_rows jsonb;
  v_total int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if v_component not in ('P1','P5') then raise exception 'exam_prep_invalid_component'; end if;

  select mv.id,mv.mapping_version,c.adapter_status
  into v_cfg
  from private.exam_prep_question_mapping_versions mv
  join private.exam_prep_legacy_reference_configs c on c.mapping_version_id=mv.id
  where mv.component_code=v_component and mv.status='active'
  order by mv.id desc limit 1;

  if not found or v_cfg.adapter_status<>'active' then
    return jsonb_build_object(
      'component_code',v_component,
      'available',false,
      'source_type','legacy_readonly',
      'academic_credit',false,
      'mastery_effect','none',
      'mapping_version',null,
      'reference_count',0,
      'skills','[]'::jsonb
    );
  end if;

  select count(*) into v_total
  from private.exam_prep_legacy_evidence_references r
  where r.user_id=v_uid and r.component_code=v_component and r.mapping_version_id=v_cfg.id;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.skill_code),'[]'::jsonb)
  into v_rows
  from (
    select
      r.skill_code,
      count(*)::int as reference_count,
      count(*) filter(where r.is_correct)::int as correct_count,
      count(*) filter(where not r.is_correct)::int as needs_review_count,
      max(r.occurred_at) as latest_reference_at,
      array_agg(distinct r.legacy_source order by r.legacy_source) as sources
    from private.exam_prep_legacy_evidence_references r
    where r.user_id=v_uid and r.component_code=v_component and r.mapping_version_id=v_cfg.id
    group by r.skill_code
  ) x;

  return jsonb_build_object(
    'component_code',v_component,
    'available',true,
    'source_type','legacy_readonly',
    'academic_credit',false,
    'mastery_effect','none',
    'mapping_version',v_cfg.mapping_version,
    'reference_count',v_total,
    'skills',v_rows
  );
end;
$$;
revoke all on function public.get_exam_prep_legacy_reference_summary_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_legacy_reference_summary_safe_v1(text) to authenticated,service_role;

commit;
