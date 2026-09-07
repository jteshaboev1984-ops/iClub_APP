-- Exam Prep Stage-3 governed key-skill registry v1.
-- Product-governance decision: approve the previously CI-validated balanced-bottleneck proposal unchanged.
-- This release changes ONLY the Stage-3 key registry/governance status. It does not unlock Stage 4,
-- alter learner evidence, entitlements, legacy Tours/Practice, AI, Mentor Care, or feature rollout.

begin;

do $$
declare
  v_rule text;
  v_program bigint;
  v_key_status text;
  v_existing int;
  v_max_stage smallint;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  select rule_version,key_registry_status
    into v_rule,v_key_status
  from private.exam_prep_stage3_exit_rules
  where status='active';

  if v_rule is distinct from 'stage3_exit_v1_2026_09_05' then
    raise exception 'Stage3 key registry v1: unexpected active rule=%',v_rule;
  end if;
  if v_key_status is distinct from 'pending' then
    raise exception 'Stage3 key registry v1: expected pending registry, got=%',v_key_status;
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then
    raise exception 'Stage3 key registry v1: active canonical program version missing';
  end if;

  select count(*) into v_existing
  from private.exam_prep_stage3_key_skills
  where rule_version=v_rule;
  if v_existing<>0 then
    raise exception 'Stage3 key registry v1: registry must begin empty, rows=%',v_existing;
  end if;

  select max_automatic_stage into v_max_stage
  from private.exam_prep_operational_stage_rules
  where status='active';
  if v_max_stage<>3 then
    raise exception 'Stage3 key registry v1: Stage 4 must remain locked before registry approval, max=%',v_max_stage;
  end if;

  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null then
    raise exception 'Stage3 key registry v1: Stage4 evaluator must remain undeployed in this release';
  end if;

  select * into v_cfg
  from private.exam_prep_feature_config
  where program_key='math_as_p1_p5';

  -- This release is intentionally safe to apply during the current Core-only canary.
  if v_cfg.rollout_state<>'controlled_beta'
     or not v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or v_cfg.kill_switch then
    raise exception 'Stage3 key registry v1: expected live Core-only controlled beta boundary';
  end if;

  if exists(
    select 1 from private.exam_prep_stage_states
    where operational_stage>3
  ) then
    raise exception 'Stage3 key registry v1: unexpected learner stage above 3';
  end if;
end $$;

with active_context as (
  select
    (select rule_version from private.exam_prep_stage3_exit_rules where status='active') as rule_version,
    (select id from private.exam_prep_program_versions
      where program_key='math_as_p1_p5'
        and version_key='p1_p5_canonical_v1_0'
        and status='active') as program_version_id
), approved(component_code,skill_code,governance_basis) as (
  values
    ('P1','P1-QUA-03','Quadratic solving method choice is dependency-central and a cross-topic transfer bottleneck.'),
    ('P1','P1-FUN-01','Functions language and model selection govern domain, range, one-one, inverse and composition reasoning.'),
    ('P1','P1-COO-05','Line-circle work integrates algebraic and geometric reasoning rather than one isolated routine.'),
    ('P1','P1-CIR-03','Composite sector and segment problems require multi-step mathematical modelling and transfer.'),
    ('P1','P1-TRI-05','Trigonometric equations require interval-aware complete solution structure and error control.'),
    ('P1','P1-SER-02','Arithmetic-versus-geometric recognition is the model-choice bottleneck before progression formula execution.'),
    ('P1','P1-DIF-07','Stationary-point, nature, sketch and optimisation work requires derivative interpretation and decision-making.'),
    ('P1','P1-INT-04','Area between curves requires region interpretation, correct limits and decomposition.'),
    ('P5','P5-DAT-08','Dataset comparison requires contextual interpretation of location and spread.'),
    ('P5','P5-CNT-05','Mixed selection-arrangement problems require correct counting-model choice and integration.'),
    ('P5','P5-PRO-05','Conditional probability is a central sequential-probability interpretation and model bottleneck.'),
    ('P5','P5-DRV-01','Distribution validity and missing probability govern the structure of discrete random variables.'),
    ('P5','P5-BIN-01','Binomial recognition requires checking model assumptions before calculation.'),
    ('P5','P5-GEO-01','Geometric recognition requires identifying first-success structure and model assumptions.'),
    ('P5','P5-NOR-06','Normal approximation to Binomial combines approximation conditions, parameter conversion and continuity correction.')
)
insert into private.exam_prep_stage3_key_skills(
  rule_version,program_version_id,component_code,skill_code,governance_basis
)
select c.rule_version,c.program_version_id,a.component_code,a.skill_code,a.governance_basis
from active_context c
cross join approved a;

do $$
declare
  v_rule text;
  v_program bigint;
  v_p1 int;
  v_p5 int;
  v_bad int;
  v_p1_sections int;
  v_p5_sections int;
  v_p5_54 int;
begin
  select rule_version into v_rule
  from private.exam_prep_stage3_exit_rules where status='active';
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  select count(*) filter(where component_code='P1'),
         count(*) filter(where component_code='P5')
    into v_p1,v_p5
  from private.exam_prep_stage3_key_skills
  where rule_version=v_rule and program_version_id=v_program;
  if v_p1<>8 or v_p5<>7 then
    raise exception 'Stage3 key registry v1: exact membership count mismatch P1=% P5=%',v_p1,v_p5;
  end if;

  select count(*) into v_bad
  from private.exam_prep_stage3_key_skills k
  left join private.exam_prep_syllabus_nodes n
    on n.program_version_id=k.program_version_id
   and n.skill_code=k.skill_code
   and n.component_code=k.component_code
  where k.rule_version=v_rule
    and k.program_version_id=v_program
    and (n.skill_code is null or length(trim(k.governance_basis))=0);
  if v_bad<>0 then
    raise exception 'Stage3 key registry v1: invalid/noncanonical rows=%',v_bad;
  end if;

  select count(distinct n.official_syllabus_section)
    into v_p1_sections
  from private.exam_prep_stage3_key_skills k
  join private.exam_prep_syllabus_nodes n
    on n.program_version_id=k.program_version_id and n.skill_code=k.skill_code
  where k.rule_version=v_rule and k.program_version_id=v_program and k.component_code='P1';

  select count(distinct n.official_syllabus_section)
    into v_p5_sections
  from private.exam_prep_stage3_key_skills k
  join private.exam_prep_syllabus_nodes n
    on n.program_version_id=k.program_version_id and n.skill_code=k.skill_code
  where k.rule_version=v_rule and k.program_version_id=v_program and k.component_code='P5';

  if v_p1_sections<>8 or v_p5_sections<>5 then
    raise exception 'Stage3 key registry v1: official-section coverage mismatch P1=% P5=%',v_p1_sections,v_p5_sections;
  end if;

  select count(*) into v_p5_54
  from private.exam_prep_stage3_key_skills
  where rule_version=v_rule and program_version_id=v_program
    and component_code='P5'
    and skill_code in ('P5-DRV-01','P5-BIN-01','P5-GEO-01');
  if v_p5_54<>3 then
    raise exception 'Stage3 key registry v1: P5 5.4 DRV/BIN/GEO coverage mismatch=%',v_p5_54;
  end if;

  update private.exam_prep_stage3_exit_rules
  set key_registry_status='approved',
      source_note=source_note || ' Governance amendment 2026-09-07: iClub architect approved the previously CI-validated balanced-bottleneck registry proposal unchanged (8 P1 + 7 P5). This is an iClub operational governance set, not an official Cambridge key-skill list.'
  where rule_version=v_rule and status='active';

  if (select key_registry_status from private.exam_prep_stage3_exit_rules where rule_version=v_rule)<>'approved' then
    raise exception 'Stage3 key registry v1: approval state not persisted';
  end if;

  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'Stage3 key registry v1: registry approval must not unlock Stage 4';
  end if;
end $$;

commit;
