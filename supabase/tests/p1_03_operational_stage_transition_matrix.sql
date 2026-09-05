\set ON_ERROR_STOP on
\echo 'P1-03 operational Stage 1-3 transition matrix'

begin;

do $$
declare
  v_program bigint;
  v_rule text;
  v_user uuid := '00000000-0000-4000-8000-000000001041'::uuid;
  v_stage smallint;
  v_gate_stage smallint;
  v_reason text;
  v_policy private.exam_prep_operational_stage_rules%rowtype;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';

  select rule_version into v_rule
  from private.exam_prep_placement_rule_versions
  where program_version_id=v_program and status='active'
  order by created_at desc
  limit 1;

  select * into v_policy
  from private.exam_prep_operational_stage_rules
  where status='active';

  if v_program is null or v_rule is null then
    raise exception 'P1-03 stage matrix: baseline program/placement rule missing';
  end if;
  if v_policy.rule_version is null
     or v_policy.stage1_to_2_min_coverage_pct<>15.00
     or v_policy.stage2_to_3_min_coverage_pct<>80.00
     or not v_policy.fast_track_to_stage2
     or v_policy.max_automatic_stage<>3 then
    raise exception 'P1-03 stage matrix: operational-stage policy drift';
  end if;

  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','StageTransition','en');

  -- P1 normal Foundation route: Stage 0 has completed and no explicit prerequisite blocker remains.
  insert into private.exam_prep_component_placements(
    user_id,program_version_id,component_code,rule_version,placement_status,route,
    profile_complete,content_ready,screening_required_items,screening_required_areas,
    screening_available_items,screening_available_areas,screening_answered_items,screening_answered_areas,
    screening_objective_items,screening_correct_items,screening_accuracy_pct,
    prerequisite_unknown_count,prerequisite_blocker_count,ambiguity,advanced_skip_requires_human,
    stage0_complete,route_reason,evidence_summary
  ) values (
    v_user,v_program,'P1',v_rule,'confirmed','foundation',true,true,1,1,1,1,1,1,1,1,100,
    0,0,false,true,true,'P1-03 stage transition fixture','{}'::jsonb
  );

  insert into private.exam_prep_component_access_gates(
    user_id,program_version_id,component_code,rule_version,current_operational_stage,max_unlocked_stage,
    placement_access,foundation_learning_access,advanced_route_access,mentor_required_for_core,
    gate_status,gate_reason
  ) values (
    v_user,v_program,'P1',v_rule,1,1,true,true,false,false,'stage0_complete','P1-03 stage transition fixture'
  );

  -- Below 15%: remain Stage 1.
  insert into private.exam_prep_stage_states(
    user_id,program_version_id,component_code,engine_version,
    denominator_count,l0_count,l1_count,l2_count,l3_count,coverage_count,coverage_pct,
    open_correction_count,retest_due_count,evidence_stage_candidate,operational_stage,
    stage_gate_status,stage_hold_reason,app_readiness_estimate,app_readiness_reason
  ) values (
    v_user,v_program,'P1','objective_state_v1',45,39,0,6,0,6,13.33,0,0,1,0,
    'blocked_dependency',null,'INSUFFICIENT_EVIDENCE','P1-03 rollback-only transition fixture'
  );

  select operational_stage,stage_hold_reason into v_stage,v_reason
  from private.exam_prep_stage_states
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  if v_stage<>1 or position('Stage 1 Foundation' in coalesce(v_reason,''))=0 then
    raise exception 'P1-03 stage matrix: 13.33%% did not remain Stage 1, stage=% reason=%',v_stage,v_reason;
  end if;

  -- Conservative 15% threshold: 7/45 = 15.56%, Stage 2.
  update private.exam_prep_stage_states
  set l0_count=38,l2_count=7,coverage_count=7,coverage_pct=15.56,evidence_stage_candidate=2,derived_at=now()
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';

  select operational_stage into v_stage
  from private.exam_prep_stage_states where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select current_operational_stage into v_gate_stage
  from private.exam_prep_component_access_gates where user_id=v_user and component_code='P1' and rule_version=v_rule;
  if v_stage<>2 or v_gate_stage<>2 then
    raise exception 'P1-03 stage matrix: 15%% gate did not unlock Stage 2, stage=% access=%',v_stage,v_gate_stage;
  end if;

  -- 77.78% is still Stage 2; calendar/time alone never advances the learner.
  update private.exam_prep_stage_states
  set l0_count=10,l2_count=35,coverage_count=35,coverage_pct=77.78,evidence_stage_candidate=2,derived_at=now()
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  if v_stage<>2 then raise exception 'P1-03 stage matrix: 77.78%% incorrectly unlocked Stage 3, stage=%',v_stage; end if;

  -- Conservative final Syllabus-Building checkpoint: 36/45 = 80%, Stage 3.
  update private.exam_prep_stage_states
  set l0_count=9,l2_count=36,coverage_count=36,coverage_pct=80.00,evidence_stage_candidate=2,derived_at=now()
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select current_operational_stage into v_gate_stage from private.exam_prep_component_access_gates
  where user_id=v_user and component_code='P1' and rule_version=v_rule;
  if v_stage<>3 or v_gate_stage<>3 then
    raise exception 'P1-03 stage matrix: 80%% gate did not unlock Stage 3, stage=% access=%',v_stage,v_gate_stage;
  end if;

  -- Adverse prerequisite evidence reopens the learner conservatively.
  update private.exam_prep_component_placements
  set prerequisite_blocker_count=1,derived_at=now()
  where user_id=v_user and component_code='P1' and rule_version=v_rule;
  update private.exam_prep_stage_states set derived_at=now()
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  if v_stage<>1 then raise exception 'P1-03 stage matrix: prerequisite blocker did not fail closed to Stage 1, stage=%',v_stage; end if;

  update private.exam_prep_component_placements
  set prerequisite_blocker_count=0,derived_at=now()
  where user_id=v_user and component_code='P1' and rule_version=v_rule;
  update private.exam_prep_stage_states set derived_at=now()
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  if v_stage<>3 then raise exception 'P1-03 stage matrix: cleared blocker did not restore evidence-derived Stage 3, stage=%',v_stage; end if;

  -- Even 100% coverage and L2/L3-looking counts cannot auto-award Stage 4 in v1.
  update private.exam_prep_stage_states
  set l0_count=0,l2_count=40,l3_count=5,coverage_count=45,coverage_pct=100.00,evidence_stage_candidate=2,derived_at=now()
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P1' and engine_version='objective_state_v1';
  if v_stage<>3 then raise exception 'P1-03 stage matrix: Stage 4 was auto-awarded, stage=%',v_stage; end if;

  -- P5 governed fast-track may enter Stage 2 below 15%; Stage 3 still requires 80% confirmed coverage.
  insert into private.exam_prep_component_placements(
    user_id,program_version_id,component_code,rule_version,placement_status,route,
    profile_complete,content_ready,screening_required_items,screening_required_areas,
    screening_available_items,screening_available_areas,screening_answered_items,screening_answered_areas,
    screening_objective_items,screening_correct_items,screening_accuracy_pct,
    prerequisite_unknown_count,prerequisite_blocker_count,ambiguity,advanced_skip_requires_human,
    stage0_complete,route_reason,evidence_summary
  ) values (
    v_user,v_program,'P5',v_rule,'confirmed','accelerated_coverage',true,true,1,1,1,1,1,1,1,1,100,
    0,0,false,false,true,'P1-03 governed fast-track fixture','{}'::jsonb
  );

  insert into private.exam_prep_component_access_gates(
    user_id,program_version_id,component_code,rule_version,current_operational_stage,max_unlocked_stage,
    placement_access,foundation_learning_access,advanced_route_access,mentor_required_for_core,
    gate_status,gate_reason
  ) values (
    v_user,v_program,'P5',v_rule,1,1,true,true,true,false,'stage0_complete','P1-03 governed fast-track fixture'
  );

  insert into private.exam_prep_stage_states(
    user_id,program_version_id,component_code,engine_version,
    denominator_count,l0_count,l1_count,l2_count,l3_count,coverage_count,coverage_pct,
    open_correction_count,retest_due_count,evidence_stage_candidate,operational_stage,
    stage_gate_status,stage_hold_reason,app_readiness_estimate,app_readiness_reason
  ) values (
    v_user,v_program,'P5','objective_state_v1',36,36,0,0,0,0,0,0,0,0,0,
    'blocked_dependency',null,'INSUFFICIENT_EVIDENCE','P1-03 rollback-only fast-track fixture'
  );

  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P5' and engine_version='objective_state_v1';
  if v_stage<>2 then raise exception 'P1-03 stage matrix: governed fast-track did not unlock Stage 2, stage=%',v_stage; end if;

  update private.exam_prep_stage_states
  set l0_count=7,l2_count=29,coverage_count=29,coverage_pct=80.56,evidence_stage_candidate=2,derived_at=now()
  where user_id=v_user and component_code='P5' and engine_version='objective_state_v1';
  select operational_stage into v_stage from private.exam_prep_stage_states
  where user_id=v_user and component_code='P5' and engine_version='objective_state_v1';
  if v_stage<>3 then raise exception 'P1-03 stage matrix: fast-track route did not still require 80%% for Stage 3, stage=%',v_stage; end if;

  raise notice 'P1-03 operational Stage 1-3 transition matrix: GREEN';
end $$;

rollback;