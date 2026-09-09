-- P2-14 / C25 single Stage 0-6 taxonomy matrix.
-- Rollback-only synthetic proof: placement labels remain Stage-0-local and cannot promote a component.
\set ON_ERROR_STOP on

begin;

create temp table p214_user(user_id uuid primary key) on commit drop;
insert into p214_user values(gen_random_uuid());

insert into auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
select user_id,'authenticated','authenticated','p214-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
from p214_user;

insert into public.users(id,first_name,last_name,language_code,created_at,must_change_password)
select user_id,'P214','Single Taxonomy','en',now(),false from p214_user;

do $$
declare
  v_program bigint;
  v_rule text;
  v_user uuid;
  v_p1 jsonb;
  v_p5 jsonb;
  v_rejected boolean;
begin
  select user_id into v_user from p214_user;
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select rule_version into v_rule
  from private.exam_prep_placement_rule_versions
  where program_version_id=v_program and status='active'
  order by activated_at desc nulls last,created_at desc
  limit 1;

  if v_program is null or v_rule is null then
    raise exception 'P2-14 C25 baseline missing';
  end if;

  v_p1:=private.exam_prep_single_stage_taxonomy_contract_v1('P1');
  v_p5:=private.exam_prep_single_stage_taxonomy_contract_v1('P5');

  if v_p1->>'contract_version'<>'p2_14_c25_v1'
     or v_p5->>'contract_version'<>'p2_14_c25_v1'
     or v_p1->>'progression_taxonomy'<>'stages_0_6'
     or v_p5->>'progression_taxonomy'<>'stages_0_6'
     or v_p1->>'progression_scope'<>'component_specific'
     or v_p5->>'progression_scope'<>'component_specific'
     or v_p1->>'authoritative_progression_field'<>'exam_prep_stage_states.operational_stage'
     or v_p5->>'authoritative_progression_field'<>'exam_prep_stage_states.operational_stage' then
    raise exception 'P2-14 C25 progression contract mismatch P1=% P5=%',v_p1,v_p5;
  end if;

  if v_p1->>'placement_scope'<>'stage_0_local_state'
     or v_p5->>'placement_scope'<>'stage_0_local_state'
     or v_p1->>'placement_status_role'<>'local_state_only'
     or v_p5->>'placement_status_role'<>'local_state_only'
     or v_p1->>'placement_route_role'<>'local_direction_only'
     or v_p5->>'placement_route_role'<>'local_direction_only'
     or (v_p1->>'placement_labels_are_progression')::boolean is distinct from false
     or (v_p5->>'placement_labels_are_progression')::boolean is distinct from false
     or (v_p1->>'placement_labels_can_set_operational_stage')::boolean is distinct from false
     or (v_p5->>'placement_labels_can_set_operational_stage')::boolean is distinct from false
     or (v_p1->>'active_week_can_set_operational_stage')::boolean is distinct from false
     or (v_p5->>'active_week_can_set_operational_stage')::boolean is distinct from false
     or (v_p1->>'p1_p5_separate')::boolean is distinct from true
     or (v_p5->>'p1_p5_separate')::boolean is distinct from true then
    raise exception 'P2-14 C25 placement/local-state contract drift';
  end if;

  if jsonb_array_length(v_p1->'stages')<>7
     or (v_p1->'stages'->0->>'stage_no')::int<>0
     or (v_p1->'stages'->6->>'stage_no')::int<>6 then
    raise exception 'P2-14 C25 Stage 0-6 catalog drift';
  end if;

  -- P1 is still inside Stage 0: local placement status/route must not unlock Stage 1.
  insert into private.exam_prep_component_placements(
    user_id,program_version_id,component_code,rule_version,placement_status,route,
    profile_complete,content_ready,screening_required_items,screening_required_areas,
    screening_available_items,screening_available_areas,screening_answered_items,screening_answered_areas,
    screening_objective_items,screening_correct_items,screening_accuracy_pct,
    prerequisite_unknown_count,prerequisite_blocker_count,ambiguity,advanced_skip_requires_human,
    stage0_complete,route_reason,evidence_summary
  ) values (
    v_user,v_program,'P1',v_rule,'screening_incomplete','pending_evidence',
    true,true,24,8,24,8,3,2,3,3,100,
    0,0,true,true,false,'P2-14 Stage-0-local placement fixture','{}'::jsonb
  );

  v_rejected:=false;
  begin
    insert into private.exam_prep_component_access_gates(
      user_id,program_version_id,component_code,rule_version,current_operational_stage,max_unlocked_stage,
      placement_access,foundation_learning_access,advanced_route_access,mentor_required_for_core,
      gate_status,gate_reason
    ) values (
      v_user,v_program,'P1',v_rule,1,1,true,true,false,false,'screening_required','parallel ladder must be rejected'
    );
  exception when others then
    if position('exam_prep_c25_stage_requires_completed_stage0' in sqlerrm)>0 then
      v_rejected:=true;
    else
      raise;
    end if;
  end;
  if not v_rejected then raise exception 'P2-14 C25 access gate accepted Stage 1 before Stage 0 completion'; end if;

  -- Stage 0 itself remains valid while placement is incomplete.
  insert into private.exam_prep_component_access_gates(
    user_id,program_version_id,component_code,rule_version,current_operational_stage,max_unlocked_stage,
    placement_access,foundation_learning_access,advanced_route_access,mentor_required_for_core,
    gate_status,gate_reason
  ) values (
    v_user,v_program,'P1',v_rule,0,0,true,false,false,false,'screening_required','P2-14 valid Stage 0 hold'
  );

  v_rejected:=false;
  begin
    perform private.exam_prep_assert_single_stage_taxonomy_v1(v_user,v_program,'P1',1::smallint);
  exception when others then
    if position('exam_prep_c25_stage_requires_completed_stage0' in sqlerrm)>0 then
      v_rejected:=true;
    else
      raise;
    end if;
  end;
  if not v_rejected then raise exception 'P2-14 C25 helper accepted Stage 1 before Stage 0 completion'; end if;

  -- Once Stage 0 is genuinely complete, the Stage taxonomy may advance through the existing evidence gates.
  update private.exam_prep_component_placements
  set placement_status='confirmed',route='foundation',stage0_complete=true,ambiguity=false,
      route_reason='P2-14 completed Stage 0 fixture',derived_at=now()
  where user_id=v_user and program_version_id=v_program and component_code='P1' and rule_version=v_rule;

  perform private.exam_prep_assert_single_stage_taxonomy_v1(v_user,v_program,'P1',1::smallint);
  update private.exam_prep_component_access_gates
  set current_operational_stage=1,max_unlocked_stage=1,foundation_learning_access=true,
      gate_status='stage0_complete',gate_reason='P2-14 valid Stage 1 after Stage 0',updated_at=now()
  where user_id=v_user and program_version_id=v_program and component_code='P1' and rule_version=v_rule;

  -- P1 completion must not lift P5: each component owns its own Stage 0 instance.
  insert into private.exam_prep_component_placements(
    user_id,program_version_id,component_code,rule_version,placement_status,route,
    profile_complete,content_ready,screening_required_items,screening_required_areas,
    screening_available_items,screening_available_areas,screening_answered_items,screening_answered_areas,
    screening_objective_items,screening_correct_items,screening_accuracy_pct,
    prerequisite_unknown_count,prerequisite_blocker_count,ambiguity,advanced_skip_requires_human,
    stage0_complete,route_reason,evidence_summary
  ) values (
    v_user,v_program,'P5',v_rule,'screening_incomplete','pending_evidence',
    true,true,15,5,15,5,2,1,2,2,100,
    0,0,true,true,false,'P2-14 P5 separate Stage-0 fixture','{}'::jsonb
  );

  v_rejected:=false;
  begin
    perform private.exam_prep_assert_single_stage_taxonomy_v1(v_user,v_program,'P5',1::smallint);
  exception when others then
    if position('exam_prep_c25_stage_requires_completed_stage0' in sqlerrm)>0 then
      v_rejected:=true;
    else
      raise;
    end if;
  end;
  if not v_rejected then raise exception 'P2-14 C25 P1 completion leaked Stage 1 into P5'; end if;

  if has_function_privilege('authenticated','private.exam_prep_single_stage_taxonomy_contract_v1(text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_assert_single_stage_taxonomy_v1(uuid,bigint,text,smallint)','EXECUTE') then
    raise exception 'P2-14 C25 private guard exposed to authenticated';
  end if;
end
$$;

rollback;

do $$
begin
  if exists(select 1 from auth.users where email like 'p214-%@invalid.example') then
    raise exception 'P2-14 C25 synthetic auth residue found';
  end if;
  if exists(select 1 from public.users where first_name='P214' and last_name='Single Taxonomy') then
    raise exception 'P2-14 C25 synthetic public user residue found';
  end if;
end
$$;

\echo 'P2-14 C25 single Stage 0-6 taxonomy matrix: GREEN'
