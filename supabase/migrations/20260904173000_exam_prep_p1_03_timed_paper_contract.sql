-- P1-03: server-authoritative timed / modified-paper contract.
-- Additive and fail-closed. No legacy Practice/Tour/paper history is read or rewritten.
-- Official 9709 2026-2027 component structure: P1 75 marks / 110 min; P5 50 marks / 75 min.

begin;

-- Paper is already a valid session/authorization purpose; make it a valid governed assessment type too.
alter table private.exam_prep_assessments drop constraint if exists exam_prep_assessments_assessment_type_check;
alter table private.exam_prep_assessments add constraint exam_prep_assessments_assessment_type_check
  check(assessment_type in ('diagnostic','learning','retest','mixed','timed','paper'));

create table if not exists private.exam_prep_component_paper_profiles (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  profile_version text not null,
  official_total_marks integer not null check(official_total_marks>0),
  official_duration_sec integer not null check(official_duration_sec>0),
  source_ref text not null,
  status text not null default 'draft' check(status in ('draft','published','retired')),
  created_at timestamptz not null default now(),
  published_at timestamptz null,
  unique(program_version_id,component_code,profile_version)
);

create table if not exists private.exam_prep_timed_assessment_contracts (
  assessment_id bigint primary key references private.exam_prep_assessments(id) on delete cascade,
  paper_profile_id bigint not null references private.exam_prep_component_paper_profiles(id) on delete restrict,
  contract_version text not null,
  attempt_kind text not null check(attempt_kind in ('timed_section','modified_paper','full_paper','diagnostic_full')),
  timing_rule text not null check(timing_rule in ('fixed_section','proportional_marks','official_full')),
  marks_available integer not null check(marks_available>0),
  fixed_time_limit_sec integer null check(fixed_time_limit_sec is null or fixed_time_limit_sec>0),
  strict_timing boolean not null default true,
  comparison_scope text not null check(comparison_scope in ('section','modified','full','diagnostic')),
  comparability_key text not null,
  status text not null default 'draft' check(status in ('draft','published','retired')),
  created_at timestamptz not null default now(),
  published_at timestamptz null,
  check(
    (timing_rule='fixed_section' and fixed_time_limit_sec is not null)
    or (timing_rule in ('proportional_marks','official_full') and fixed_time_limit_sec is null)
  )
);

create table if not exists private.exam_prep_timed_assessment_items (
  assessment_id bigint not null,
  item_order smallint not null,
  max_marks integer not null check(max_marks>0),
  created_at timestamptz not null default now(),
  primary key(assessment_id,item_order),
  foreign key(assessment_id,item_order) references private.exam_prep_assessment_items(assessment_id,item_order) on delete cascade
);

-- Immutable timing snapshot. Written marks may be supplied later as separate self-review facts.
create table if not exists private.exam_prep_timed_attempt_results (
  session_id uuid primary key references private.exam_prep_sessions(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check(component_code in ('P1','P5')),
  assessment_id bigint not null references private.exam_prep_assessments(id) on delete restrict,
  attempt_kind text not null check(attempt_kind in ('timed_section','modified_paper','full_paper','diagnostic_full')),
  timing_rule text not null check(timing_rule in ('fixed_section','proportional_marks','official_full')),
  comparison_scope text not null check(comparison_scope in ('section','modified','full','diagnostic')),
  comparability_key text not null,
  strict_timing boolean not null,
  marks_available integer not null check(marks_available>0),
  time_limit_sec integer not null check(time_limit_sec>0),
  server_elapsed_sec integer not null check(server_elapsed_sec>=0),
  answered_items integer not null check(answered_items>=0),
  unattempted_items integer not null check(unattempted_items>=0),
  objective_marks_in_time integer not null default 0 check(objective_marks_in_time>=0),
  objective_marks_after_time integer not null default 0 check(objective_marks_after_time>=0),
  objective_lost_in_time_marks integer not null default 0 check(objective_lost_in_time_marks>=0),
  objective_lost_after_time_marks integer not null default 0 check(objective_lost_after_time_marks>=0),
  pending_review_in_time_marks integer not null default 0 check(pending_review_in_time_marks>=0),
  pending_review_after_time_marks integer not null default 0 check(pending_review_after_time_marks>=0),
  unattempted_marks integer not null default 0 check(unattempted_marks>=0),
  completion_reason text not null check(completion_reason in ('submitted','time_expired','administrative_stop')),
  timing_comparable boolean not null,
  base_score_comparable boolean not null,
  finalized_at timestamptz not null,
  created_at timestamptz not null default now(),
  check(
    objective_marks_in_time + objective_marks_after_time +
    objective_lost_in_time_marks + objective_lost_after_time_marks +
    pending_review_in_time_marks + pending_review_after_time_marks +
    unattempted_marks = marks_available
  )
);

create table if not exists private.exam_prep_timed_written_self_marks (
  session_id uuid not null references private.exam_prep_timed_attempt_results(session_id) on delete restrict,
  item_order smallint not null,
  user_id uuid not null references public.users(id) on delete cascade,
  marks_awarded integer not null check(marks_awarded>=0),
  max_marks integer not null check(max_marks>0),
  was_in_time boolean not null,
  idempotency_key text not null check(char_length(idempotency_key) between 8 and 160),
  review_note text null,
  created_at timestamptz not null default now(),
  primary key(session_id,item_order),
  unique(session_id,idempotency_key),
  foreign key(session_id,item_order) references private.exam_prep_session_items(session_id,item_order) on delete restrict,
  check(marks_awarded<=max_marks)
);

create index if not exists exam_prep_paper_profiles_component_idx
  on private.exam_prep_component_paper_profiles(program_version_id,component_code,status);
create index if not exists exam_prep_timed_contract_profile_idx
  on private.exam_prep_timed_assessment_contracts(paper_profile_id,status);
create index if not exists exam_prep_timed_attempt_user_component_idx
  on private.exam_prep_timed_attempt_results(user_id,component_code,finalized_at desc);
create index if not exists exam_prep_timed_attempt_comparability_idx
  on private.exam_prep_timed_attempt_results(user_id,component_code,comparability_key,finalized_at desc)
  where timing_comparable;

-- Private/service-only data plane.
do $$ declare t text; begin
  foreach t in array array[
    'exam_prep_component_paper_profiles','exam_prep_timed_assessment_contracts',
    'exam_prep_timed_assessment_items','exam_prep_timed_attempt_results','exam_prep_timed_written_self_marks'
  ] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;
grant usage,select on sequence private.exam_prep_component_paper_profiles_id_seq to service_role;

-- Config tables are audited; attempt/result facts are immutable.
do $$ begin execute 'create trigger exam_prep_component_paper_profiles_audit_v1 after insert or update or delete on private.exam_prep_component_paper_profiles for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;
do $$ begin execute 'create trigger exam_prep_timed_assessment_contracts_audit_v1 after insert or update or delete on private.exam_prep_timed_assessment_contracts for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;
do $$ begin execute 'create trigger exam_prep_timed_assessment_items_audit_v1 after insert or update or delete on private.exam_prep_timed_assessment_items for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;

drop trigger if exists exam_prep_timed_attempt_results_immutable_v1 on private.exam_prep_timed_attempt_results;
create trigger exam_prep_timed_attempt_results_immutable_v1
before update or delete on private.exam_prep_timed_attempt_results
for each row execute function private.exam_prep_block_immutable_mutation_v1();

drop trigger if exists exam_prep_timed_written_self_marks_immutable_v1 on private.exam_prep_timed_written_self_marks;
create trigger exam_prep_timed_written_self_marks_immutable_v1
before update or delete on private.exam_prep_timed_written_self_marks
for each row execute function private.exam_prep_block_immutable_mutation_v1();

-- Versioned official component profiles. This is structure metadata only; no Cambridge question content is stored.
with pv as (
  select id from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_component_paper_profiles(
  program_version_id,component_code,profile_version,official_total_marks,official_duration_sec,source_ref,status,published_at
)
select pv.id,'P1','9709_2026_2027_v1',75,6600,'Cambridge 9709 syllabus 2026-2027: Paper 1 Pure Mathematics 1, 75 marks, 1h50m','published',now() from pv
union all
select pv.id,'P5','9709_2026_2027_v1',50,4500,'Cambridge 9709 syllabus 2026-2027: Paper 5 Probability & Statistics 1, 50 marks, 1h15m','published',now() from pv
on conflict(program_version_id,component_code,profile_version) do nothing;

create or replace function private.exam_prep_timed_time_limit_v1(
  p_paper_profile_id bigint,
  p_timing_rule text,
  p_marks_available integer,
  p_fixed_time_limit_sec integer default null
)
returns integer
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_p private.exam_prep_component_paper_profiles%rowtype; v_sec integer;
begin
  select * into v_p from private.exam_prep_component_paper_profiles where id=p_paper_profile_id and status='published';
  if v_p.id is null then raise exception 'exam_prep_paper_profile_not_published'; end if;
  if p_marks_available is null or p_marks_available<1 then raise exception 'exam_prep_bad_marks_available'; end if;
  if p_timing_rule='official_full' then
    if p_marks_available<>v_p.official_total_marks then raise exception 'exam_prep_full_paper_marks_mismatch'; end if;
    v_sec:=v_p.official_duration_sec;
  elsif p_timing_rule='proportional_marks' then
    if p_marks_available>v_p.official_total_marks then raise exception 'exam_prep_modified_marks_exceed_official'; end if;
    v_sec:=ceil((v_p.official_duration_sec::numeric*p_marks_available)/v_p.official_total_marks)::integer;
  elsif p_timing_rule='fixed_section' then
    if p_fixed_time_limit_sec is null or p_fixed_time_limit_sec<60 or p_fixed_time_limit_sec>v_p.official_duration_sec then
      raise exception 'exam_prep_bad_fixed_section_time';
    end if;
    v_sec:=p_fixed_time_limit_sec;
  else
    raise exception 'exam_prep_bad_timing_rule';
  end if;
  return v_sec;
end;
$$;
revoke all on function private.exam_prep_timed_time_limit_v1(bigint,text,integer,integer) from public,anon,authenticated;
grant execute on function private.exam_prep_timed_time_limit_v1(bigint,text,integer,integer) to service_role;

create or replace function private.exam_prep_validate_timed_contract_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare v_a private.exam_prep_assessments%rowtype; v_p private.exam_prep_component_paper_profiles%rowtype; v_sum integer; v_count integer; v_ass_count integer; v_limit integer;
begin
  select * into v_a from private.exam_prep_assessments where id=new.assessment_id;
  if v_a.id is null or v_a.assessment_type not in ('timed','paper') then raise exception 'exam_prep_timed_contract_requires_timed_or_paper_assessment'; end if;
  select * into v_p from private.exam_prep_component_paper_profiles where id=new.paper_profile_id;
  if v_p.id is null or v_p.status<>'published' or v_p.component_code<>v_a.component_code then raise exception 'exam_prep_timed_contract_profile_scope_mismatch'; end if;
  if new.attempt_kind='full_paper' and (new.timing_rule<>'official_full' or new.comparison_scope<>'full') then raise exception 'exam_prep_full_paper_contract_invalid'; end if;
  if new.attempt_kind='modified_paper' and (new.timing_rule<>'proportional_marks' or new.comparison_scope<>'modified') then raise exception 'exam_prep_modified_paper_contract_invalid'; end if;
  if new.attempt_kind='diagnostic_full' and new.comparison_scope<>'diagnostic' then raise exception 'exam_prep_diagnostic_full_scope_invalid'; end if;
  if new.attempt_kind='timed_section' and new.comparison_scope<>'section' then raise exception 'exam_prep_timed_section_scope_invalid'; end if;
  v_limit:=private.exam_prep_timed_time_limit_v1(new.paper_profile_id,new.timing_rule,new.marks_available,new.fixed_time_limit_sec);
  if new.status='published' then
    select count(*),coalesce(sum(i.max_marks),0) into v_count,v_sum from private.exam_prep_timed_assessment_items i where i.assessment_id=new.assessment_id;
    select count(*) into v_ass_count from private.exam_prep_assessment_items ai where ai.assessment_id=new.assessment_id;
    if v_count=0 or v_count<>v_ass_count or v_sum<>new.marks_available then
      raise exception 'exam_prep_timed_item_mark_floor_not_met items=% assessment_items=% marks=% expected=%',v_count,v_ass_count,v_sum,new.marks_available;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_validate_timed_contract_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_validate_timed_contract_v1 on private.exam_prep_timed_assessment_contracts;
create trigger exam_prep_validate_timed_contract_v1
before insert or update on private.exam_prep_timed_assessment_contracts
for each row execute function private.exam_prep_validate_timed_contract_v1();

-- A timed/paper session receives one immutable server timing snapshot at INSERT time.
create or replace function private.exam_prep_attach_timing_contract_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare v_c private.exam_prep_timed_assessment_contracts%rowtype; v_p private.exam_prep_component_paper_profiles%rowtype; v_limit integer; v_deadline timestamptz;
begin
  if new.session_type not in ('timed','paper') then return new; end if;
  select * into v_c from private.exam_prep_timed_assessment_contracts where assessment_id=new.assessment_id and status='published';
  if v_c.assessment_id is null then raise exception 'exam_prep_timed_contract_not_published'; end if;
  select * into v_p from private.exam_prep_component_paper_profiles where id=v_c.paper_profile_id and status='published';
  if v_p.id is null or v_p.component_code<>new.component_code then raise exception 'exam_prep_timed_session_profile_scope_mismatch'; end if;
  v_limit:=private.exam_prep_timed_time_limit_v1(v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec);
  v_deadline:=coalesce(new.started_at,now()) + make_interval(secs=>v_limit);
  new.timing_contract:=jsonb_build_object(
    'contract_version',v_c.contract_version,'attempt_kind',v_c.attempt_kind,'timing_rule',v_c.timing_rule,
    'comparison_scope',v_c.comparison_scope,'comparability_key',v_c.comparability_key,'strict_timing',v_c.strict_timing,
    'marks_available',v_c.marks_available,'time_limit_sec',v_limit,'deadline_at',v_deadline,
    'official_total_marks',v_p.official_total_marks,'official_duration_sec',v_p.official_duration_sec,
    'paper_profile_version',v_p.profile_version,'component_code',new.component_code
  );
  return new;
end;
$$;
revoke all on function private.exam_prep_attach_timing_contract_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_attach_timing_contract_v1 on private.exam_prep_sessions;
create trigger exam_prep_attach_timing_contract_v1
before insert on private.exam_prep_sessions
for each row execute function private.exam_prep_attach_timing_contract_v1();

create or replace function private.exam_prep_block_timing_contract_mutation_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$ begin
  if old.timing_contract is distinct from new.timing_contract then raise exception 'exam_prep_timing_contract_immutable'; end if;
  return new;
end; $$;
revoke all on function private.exam_prep_block_timing_contract_mutation_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_timing_contract_immutable_v1 on private.exam_prep_sessions;
create trigger exam_prep_timing_contract_immutable_v1
before update of timing_contract on private.exam_prep_sessions
for each row execute function private.exam_prep_block_timing_contract_mutation_v1();

-- Static acceptance: official ratios, no client grants, fail-closed feature state.
do $$ declare v_p1 bigint; v_p5 bigint; begin
  select id into v_p1 from private.exam_prep_component_paper_profiles where component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  select id into v_p5 from private.exam_prep_component_paper_profiles where component_code='P5' and profile_version='9709_2026_2027_v1' and status='published';
  if private.exam_prep_timed_time_limit_v1(v_p1,'proportional_marks',20,null)<>1760 then raise exception 'P1-03 P1 proportional timing failed'; end if;
  if private.exam_prep_timed_time_limit_v1(v_p5,'proportional_marks',20,null)<>1800 then raise exception 'P1-03 P5 proportional timing failed'; end if;
  if exists(select 1 from information_schema.role_table_grants where table_schema='private' and table_name in ('exam_prep_component_paper_profiles','exam_prep_timed_assessment_contracts','exam_prep_timed_assessment_items','exam_prep_timed_attempt_results','exam_prep_timed_written_self_marks') and grantee in ('anon','authenticated')) then
    raise exception 'P1-03 private timed table grants exposed';
  end if;
  if exists(select 1 from private.exam_prep_feature_config where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)) then
    raise exception 'P1-03 contract must remain fail-closed';
  end if;
end $$;

commit;
