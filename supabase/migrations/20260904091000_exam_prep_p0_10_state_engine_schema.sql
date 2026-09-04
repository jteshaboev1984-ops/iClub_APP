-- P0-10: conservative deterministic state-engine schema.
-- Additive only. Raw P0-09 evidence remains authoritative/immutable.
-- This layer stores rebuildable projections only; it never awards L4/L5 or Mentor Verified readiness.

begin;

create table if not exists private.exam_prep_state_engine_versions (
  engine_version text primary key,
  status text not null check(status in ('draft','active','retired')),
  policy_note text not null,
  created_at timestamptz not null default now(),
  activated_at timestamptz null
);

create table if not exists private.exam_prep_skill_contracts (
  program_version_id bigint not null,
  skill_code text not null,
  component_code text not null check(component_code in ('P1','P5')),
  contract_profile text not null check(contract_profile in ('routine_transfer','context_reasoning','model_selection','graph_construction')),
  min_first_coverage_correct smallint not null check(min_first_coverage_correct between 1 and 20),
  min_provisional_correct smallint not null check(min_provisional_correct >= min_first_coverage_correct and min_provisional_correct <= 20),
  min_accuracy_pct numeric(5,2) not null check(min_accuracy_pct between 0 and 100),
  requires_written_for_l2 boolean not null default true,
  requires_transfer_for_l3 boolean not null default true,
  requires_mixed_for_l3 boolean not null default false,
  requires_retest_for_l3 boolean not null default true,
  min_retest_delay_days smallint not null default 0 check(min_retest_delay_days between 0 and 60),
  source_contract_text text not null,
  policy_note text not null,
  created_at timestamptz not null default now(),
  primary key(program_version_id,skill_code),
  foreign key(program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code)
    on delete restrict
);

create table if not exists private.exam_prep_skill_states (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text not null,
  engine_version text not null references private.exam_prep_state_engine_versions(engine_version) on delete restrict,
  objective_level smallint not null default 0 check(objective_level between 0 and 3),
  coverage_confirmed boolean not null default false,
  evidence_total integer not null default 0 check(evidence_total >= 0),
  objective_evidence_count integer not null default 0 check(objective_evidence_count >= 0),
  correct_objective_count integer not null default 0 check(correct_objective_count >= 0),
  objective_accuracy_pct numeric(5,2) null check(objective_accuracy_pct is null or objective_accuracy_pct between 0 and 100),
  learning_count integer not null default 0 check(learning_count >= 0),
  diagnostic_count integer not null default 0 check(diagnostic_count >= 0),
  mixed_count integer not null default 0 check(mixed_count >= 0),
  timed_count integer not null default 0 check(timed_count >= 0),
  retest_count integer not null default 0 check(retest_count >= 0),
  written_count integer not null default 0 check(written_count >= 0),
  has_transfer_evidence boolean not null default false,
  has_successful_retest boolean not null default false,
  has_delayed_successful_retest boolean not null default false,
  has_written_evidence boolean not null default false,
  has_mentor_verified_evidence boolean not null default false,
  unresolved_correction_count integer not null default 0 check(unresolved_correction_count >= 0),
  hold_reason text null,
  source_evidence_through timestamptz null,
  derived_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code,skill_code,engine_version),
  foreign key(program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code)
    on delete restrict
);

create table if not exists private.exam_prep_stage_states (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  engine_version text not null references private.exam_prep_state_engine_versions(engine_version) on delete restrict,
  denominator_count smallint not null check(denominator_count > 0),
  l0_count smallint not null check(l0_count >= 0),
  l1_count smallint not null check(l1_count >= 0),
  l2_count smallint not null check(l2_count >= 0),
  l3_count smallint not null check(l3_count >= 0),
  coverage_count smallint not null check(coverage_count >= 0),
  coverage_pct numeric(5,2) not null check(coverage_pct between 0 and 100),
  open_correction_count integer not null default 0 check(open_correction_count >= 0),
  retest_due_count integer not null default 0 check(retest_due_count >= 0),
  evidence_stage_candidate smallint not null default 0 check(evidence_stage_candidate between 0 and 2),
  operational_stage smallint not null default 0 check(operational_stage between 0 and 6),
  stage_gate_status text not null default 'blocked_dependency'
    check(stage_gate_status in ('blocked_dependency','evidence_candidate','operational')),
  stage_hold_reason text null,
  app_readiness_estimate text not null default 'INSUFFICIENT_EVIDENCE'
    check(app_readiness_estimate in ('INSUFFICIENT_EVIDENCE','AT_RISK','ON_TRACK','STRONG_OBJECTIVE_EVIDENCE')),
  app_readiness_reason text not null,
  derived_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code,engine_version),
  check(l0_count + l1_count + l2_count + l3_count = denominator_count),
  check(coverage_count = l2_count + l3_count)
);

create index if not exists exam_prep_skill_states_user_component_idx
  on private.exam_prep_skill_states(user_id,component_code,engine_version);
create index if not exists exam_prep_stage_states_user_idx
  on private.exam_prep_stage_states(user_id,engine_version);

-- Projection tables are private. Learners will read them only through a safe RPC.
do $$ declare t text; begin
  foreach t in array array[
    'exam_prep_state_engine_versions','exam_prep_skill_contracts','exam_prep_skill_states','exam_prep_stage_states'
  ] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

insert into private.exam_prep_state_engine_versions(engine_version,status,policy_note,activated_at)
values (
  'objective_state_v1',
  'active',
  'Conservative deterministic projection from finalized P0-09 evidence. Automatic authority is capped at L3. L4/L5 and Mentor Verified readiness are never self-awarded. Stage 3+ remains blocked until machine-readable placement/prerequisite/key-skill/full-paper gates exist.',
  now()
)
on conflict(engine_version) do nothing;

-- Convert the four exact canonical evidence-contract families already present in the approved 81-skill map
-- into machine-readable conservative floors. These floors are intentionally strict and only drive L0-L3.
insert into private.exam_prep_skill_contracts(
  program_version_id,skill_code,component_code,contract_profile,
  min_first_coverage_correct,min_provisional_correct,min_accuracy_pct,
  requires_written_for_l2,requires_transfer_for_l3,requires_mixed_for_l3,
  requires_retest_for_l3,min_retest_delay_days,source_contract_text,policy_note
)
select
  s.program_version_id,
  s.skill_code,
  s.component_code,
  case
    when s.required_mastery_evidence like '4 независимых задания:%' then 'routine_transfer'
    when s.required_mastery_evidence like '2 контекстных сравнения/%' then 'context_reasoning'
    when s.required_mastery_evidence like '3 независимых случая:%' then 'model_selection'
    when s.required_mastery_evidence like '2 самостоятельных построения и 2 интерпретации%' then 'graph_construction'
    else null
  end,
  2,
  case
    when s.required_mastery_evidence like '4 независимых задания:%' then 4
    when s.required_mastery_evidence like '2 контекстных сравнения/%' then 3
    when s.required_mastery_evidence like '3 независимых случая:%' then 3
    when s.required_mastery_evidence like '2 самостоятельных построения и 2 интерпретации%' then 4
    else 99
  end,
  80.00,
  true,
  true,
  (s.required_mastery_evidence like '3 независимых случая:%'),
  true,
  case
    when s.required_mastery_evidence like '3 независимых случая:%' then 7
    when s.required_mastery_evidence like '2 самостоятельных построения и 2 интерпретации%' then 7
    else 0
  end,
  s.required_mastery_evidence,
  'L2 requires repeated objective evidence plus a written/self-review artefact; L3 additionally requires the full profile objective count, transfer/mixed evidence, successful retest, and no unresolved correction. This is deliberately conservative and does not claim L4/L5.'
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions pv on pv.id=s.program_version_id
where pv.program_key='math_as_p1_p5'
  and pv.version_key='p1_p5_canonical_v1_0'
  and s.component_code in ('P1','P5')
on conflict(program_version_id,skill_code) do nothing;

-- Hard acceptance: all 81 canonical denominator skills must map to one of the four approved contract families.
do $$
declare v_total int; v_a int; v_b int; v_c int; v_d int; begin
  select count(*) into v_total from private.exam_prep_skill_contracts c
  join private.exam_prep_program_versions pv on pv.id=c.program_version_id
  where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0';
  if v_total<>81 then raise exception 'P0-10 contract gate: expected 81 contracts, got %',v_total; end if;
  select count(*) filter(where contract_profile='routine_transfer'),
         count(*) filter(where contract_profile='context_reasoning'),
         count(*) filter(where contract_profile='model_selection'),
         count(*) filter(where contract_profile='graph_construction')
    into v_a,v_b,v_c,v_d
  from private.exam_prep_skill_contracts c
  join private.exam_prep_program_versions pv on pv.id=c.program_version_id
  where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0';
  if (v_a,v_b,v_c,v_d)<>(31,30,10,10) then
    raise exception 'P0-10 contract gate: profile counts mismatch %,%,%,%',v_a,v_b,v_c,v_d;
  end if;
end $$;

commit;
