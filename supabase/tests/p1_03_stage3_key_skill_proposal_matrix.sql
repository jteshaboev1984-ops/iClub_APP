-- P1-03 rollback-only validation for the non-authoritative Stage-3 key-skill proposal.
-- This test MUST NOT approve or populate the production key-skill registry.
begin;

create temporary table stage3_key_skill_proposal_v0(
  component_code text not null,
  skill_code text not null,
  governance_basis text not null,
  primary key(component_code,skill_code)
) on commit drop;

insert into stage3_key_skill_proposal_v0(component_code,skill_code,governance_basis) values
  ('P1','P1-QUA-03','Quadratic solving method choice is dependency-central and transferable.'),
  ('P1','P1-FUN-01','Functions language/model selection is the central Functions bottleneck.'),
  ('P1','P1-COO-05','Line-circle problems integrate algebra and geometry.'),
  ('P1','P1-CIR-03','Composite sector/segment problems require multi-step modelling.'),
  ('P1','P1-TRI-05','Trig equations require interval-aware solution structure.'),
  ('P1','P1-SER-02','AP/GP recognition is the model-choice bottleneck before execution.'),
  ('P1','P1-DIF-07','Stationary points/nature/optimisation require derivative interpretation.'),
  ('P1','P1-INT-04','Area between curves requires region interpretation and correct limits.'),
  ('P5','P5-DAT-08','Dataset comparison requires interpretation of location/spread in context.'),
  ('P5','P5-CNT-05','Mixed selection-arrangement problems require counting-model choice.'),
  ('P5','P5-PRO-05','Conditional probability is a central interpretation/model bottleneck.'),
  ('P5','P5-DRV-01','Distribution validity and missing probability govern discrete-RV structure.'),
  ('P5','P5-BIN-01','Binomial recognition requires checking model assumptions.'),
  ('P5','P5-GEO-01','Geometric recognition requires identifying first-success structure.'),
  ('P5','P5-NOR-06','Normal approximation to Binomial combines conditions and continuity correction.');

do $$
declare
  v_program_version_id bigint;
  v_p1_count int;
  v_p5_count int;
  v_bad int;
  v_p1_sections int;
  v_p5_sections int;
  v_all_p1_sections int;
  v_all_p5_sections int;
  v_p5_drv_family int;
  v_signal_bad int;
  v_registry_rows int;
  v_max_stage int;
  v_rule_status text;
  v_state text;
begin
  select id into v_program_version_id
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  if v_program_version_id is null then
    raise exception 'P1-03 proposal validation: active canonical program version missing';
  end if;

  select count(*) filter(where component_code='P1'),
         count(*) filter(where component_code='P5')
    into v_p1_count,v_p5_count
  from stage3_key_skill_proposal_v0;

  if v_p1_count<>8 or v_p5_count<>7 then
    raise exception 'P1-03 proposal validation: expected P1=8/P5=7 got P1=% P5=%',v_p1_count,v_p5_count;
  end if;

  select count(*) into v_bad
  from stage3_key_skill_proposal_v0 p
  left join private.exam_prep_syllabus_nodes n
    on n.program_version_id=v_program_version_id
   and n.skill_code=p.skill_code
   and n.component_code=p.component_code
  where n.skill_code is null;

  if v_bad<>0 then
    raise exception 'P1-03 proposal validation: non-canonical or component-mismatched proposal rows=%',v_bad;
  end if;

  select count(distinct n.official_syllabus_section)
    into v_p1_sections
  from stage3_key_skill_proposal_v0 p
  join private.exam_prep_syllabus_nodes n
    on n.program_version_id=v_program_version_id
   and n.skill_code=p.skill_code
   and n.component_code=p.component_code
  where p.component_code='P1';

  select count(distinct n.official_syllabus_section)
    into v_p5_sections
  from stage3_key_skill_proposal_v0 p
  join private.exam_prep_syllabus_nodes n
    on n.program_version_id=v_program_version_id
   and n.skill_code=p.skill_code
   and n.component_code=p.component_code
  where p.component_code='P5';

  select count(distinct official_syllabus_section) into v_all_p1_sections
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program_version_id and component_code='P1';

  select count(distinct official_syllabus_section) into v_all_p5_sections
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program_version_id and component_code='P5';

  if v_p1_sections<>v_all_p1_sections or v_p1_sections<>8 then
    raise exception 'P1-03 proposal validation: P1 section coverage mismatch proposal=% canonical=%',v_p1_sections,v_all_p1_sections;
  end if;
  if v_p5_sections<>v_all_p5_sections or v_p5_sections<>5 then
    raise exception 'P1-03 proposal validation: P5 section coverage mismatch proposal=% canonical=%',v_p5_sections,v_all_p5_sections;
  end if;

  select count(*) into v_p5_drv_family
  from stage3_key_skill_proposal_v0
  where component_code='P5'
    and skill_code in ('P5-DRV-01','P5-BIN-01','P5-GEO-01');
  if v_p5_drv_family<>3 then
    raise exception 'P1-03 proposal validation: P5 5.4 model-family coverage drift=%',v_p5_drv_family;
  end if;

  -- Every proposal row must have at least one governed support signal:
  -- mixed-L3 requirement, model/context/graph profile, >=3 direct downstream dependencies,
  -- or presence in the first official full paper.
  with downstream as (
    select p.component_code,p.skill_code,
           count(*) filter(where d.prerequisites_text like '%'||p.skill_code||'%')::int as direct_downstream
    from stage3_key_skill_proposal_v0 p
    join private.exam_prep_syllabus_nodes d
      on d.program_version_id=v_program_version_id
     and d.component_code=p.component_code
    group by p.component_code,p.skill_code
  ), fullpaper as (
    select distinct a.component_code,ai.primary_skill_code as skill_code
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.status='published'
      and a.assessment_key in ('p1_stage3_full_paper_01','p5_stage3_full_paper_01')
  )
  select count(*) into v_signal_bad
  from stage3_key_skill_proposal_v0 p
  join private.exam_prep_skill_contracts c
    on c.program_version_id=v_program_version_id and c.skill_code=p.skill_code
  join downstream d using(component_code,skill_code)
  where not (
    c.requires_mixed_for_l3
    or c.contract_profile in ('model_selection','context_reasoning','graph_construction')
    or d.direct_downstream>=3
    or exists(select 1 from fullpaper f where f.component_code=p.component_code and f.skill_code=p.skill_code)
  );

  if v_signal_bad<>0 then
    raise exception 'P1-03 proposal validation: proposal rows without governed support signal=%',v_signal_bad;
  end if;

  select key_registry_status into v_rule_status
  from private.exam_prep_stage3_exit_rules
  where status='active' and rule_version='stage3_exit_v1_2026_09_05';
  if v_rule_status<>'pending' then
    raise exception 'P1-03 proposal validation: proposal test must run against pending registry, got=%',v_rule_status;
  end if;

  select count(*) into v_registry_rows
  from private.exam_prep_stage3_key_skills
  where rule_version='stage3_exit_v1_2026_09_05';
  if v_registry_rows<>0 then
    raise exception 'P1-03 proposal validation: production-like registry must remain empty rows=%',v_registry_rows;
  end if;

  select max_automatic_stage into v_max_stage
  from private.exam_prep_operational_stage_rules
  where status='active';
  if v_max_stage<>3 then
    raise exception 'P1-03 proposal validation: Stage 4 must remain locked max_auto_stage=%',v_max_stage;
  end if;

  select rollout_state||'|'||core_enabled||'|'||ai_enabled||'|'||mentor_enabled||'|'||kill_switch
    into v_state
  from private.exam_prep_feature_config
  where program_key='math_as_p1_p5';
  if v_state<>'off|false|false|false|true' then
    raise exception 'P1-03 proposal validation: fail-closed feature state drift=%',v_state;
  end if;

  raise notice 'P1-03 Stage-3 key-skill proposal v0 validation: GREEN (P1=8, P5=7, all sections covered, registry unchanged)';
end $$;

rollback;
