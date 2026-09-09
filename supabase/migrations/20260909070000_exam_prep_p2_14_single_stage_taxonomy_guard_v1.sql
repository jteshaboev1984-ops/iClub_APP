-- P2-14 / Annual Roadmap C25: Stages 0-6 are the only progression taxonomy.
-- Placement status/route remain local Stage-0 state and may never become a parallel progression ladder.
-- Additive guard only: no learner evidence, mastery, stage, legacy attempt, answer or certificate row is rewritten.
begin;

create or replace function private.exam_prep_single_stage_taxonomy_contract_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_rule text;
  v_stages jsonb;
begin
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_program_version_missing'; end if;

  select r.rule_version into v_rule
  from private.exam_prep_placement_rule_versions r
  where r.program_version_id=v_program and r.status='active'
  order by r.activated_at desc nulls last,r.created_at desc
  limit 1;
  if v_rule is null then raise exception 'exam_prep_placement_rule_missing'; end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'stage_no',g.stage_no,
        'stage_name',g.stage_name,
        'dependency_state',g.dependency_state
      ) order by g.stage_no
    ),
    '[]'::jsonb
  ) into v_stages
  from private.exam_prep_stage_gate_catalog g
  where g.rule_version=v_rule;

  if jsonb_array_length(v_stages)<>7
     or (v_stages->0->>'stage_no')::int<>0
     or (v_stages->6->>'stage_no')::int<>6 then
    raise exception 'exam_prep_c25_stage_catalog_invalid';
  end if;

  return jsonb_build_object(
    'contract_version','p2_14_c25_v1',
    'component_code',p_component_code,
    'progression_taxonomy','stages_0_6',
    'progression_scope','component_specific',
    'authoritative_progression_field','exam_prep_stage_states.operational_stage',
    'placement_scope','stage_0_local_state',
    'placement_status_role','local_state_only',
    'placement_route_role','local_direction_only',
    'placement_labels_are_progression',false,
    'placement_labels_can_set_operational_stage',false,
    'active_week_can_set_operational_stage',false,
    'p1_p5_separate',true,
    'stages',v_stages
  );
end;
$$;

revoke all on function private.exam_prep_single_stage_taxonomy_contract_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_single_stage_taxonomy_contract_v1(text) to service_role;

create or replace function private.exam_prep_assert_single_stage_taxonomy_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text,
  p_proposed_operational_stage smallint
)
returns void
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_stage0_complete boolean := false;
begin
  if p_user_id is null or p_program_version_id is null then
    raise exception 'exam_prep_c25_identity_required';
  end if;
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;
  if p_proposed_operational_stage is null or p_proposed_operational_stage<0 or p_proposed_operational_stage>6 then
    raise exception 'exam_prep_c25_bad_operational_stage';
  end if;

  -- Stage 0 is always a valid hold state. Placement labels/statuses remain local inside it.
  if p_proposed_operational_stage=0 then
    return;
  end if;

  select coalesce(p.stage0_complete,false) into v_stage0_complete
  from private.exam_prep_component_placements p
  join private.exam_prep_placement_rule_versions r
    on r.rule_version=p.rule_version
   and r.program_version_id=p.program_version_id
   and r.status='active'
  where p.user_id=p_user_id
    and p.program_version_id=p_program_version_id
    and p.component_code=p_component_code
  order by p.derived_at desc
  limit 1;

  if coalesce(v_stage0_complete,false) is false then
    raise exception 'exam_prep_c25_stage_requires_completed_stage0';
  end if;
end;
$$;

revoke all on function private.exam_prep_assert_single_stage_taxonomy_v1(uuid,bigint,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_assert_single_stage_taxonomy_v1(uuid,bigint,text,smallint) to service_role;

create or replace function private.exam_prep_c25_access_stage_guard_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  perform private.exam_prep_assert_single_stage_taxonomy_v1(
    new.user_id,new.program_version_id,new.component_code,new.current_operational_stage
  );
  perform private.exam_prep_assert_single_stage_taxonomy_v1(
    new.user_id,new.program_version_id,new.component_code,new.max_unlocked_stage
  );
  return new;
end;
$$;
revoke all on function private.exam_prep_c25_access_stage_guard_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_c25_access_stage_guard_v1() to service_role;

drop trigger if exists zz_exam_prep_c25_access_stage_guard_v1 on private.exam_prep_component_access_gates;
create trigger zz_exam_prep_c25_access_stage_guard_v1
before insert or update of current_operational_stage,max_unlocked_stage
on private.exam_prep_component_access_gates
for each row execute function private.exam_prep_c25_access_stage_guard_v1();

create or replace function private.exam_prep_c25_stage_state_guard_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  perform private.exam_prep_assert_single_stage_taxonomy_v1(
    new.user_id,new.program_version_id,new.component_code,new.operational_stage
  );
  return new;
end;
$$;
revoke all on function private.exam_prep_c25_stage_state_guard_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_c25_stage_state_guard_v1() to service_role;

-- PostgreSQL executes same-kind triggers alphabetically. The zz_ prefix deliberately lets the
-- existing evidence/stage projection finish first, then validates the resulting operational stage.
drop trigger if exists zz_exam_prep_c25_stage_state_guard_v1 on private.exam_prep_stage_states;
create trigger zz_exam_prep_c25_stage_state_guard_v1
before insert or update of operational_stage
on private.exam_prep_stage_states
for each row execute function private.exam_prep_c25_stage_state_guard_v1();

-- Deployment invariants. They inspect existing state only and do not recalculate or rewrite it.
do $$
declare
  v_program bigint;
  v_rule text;
  v_p1 jsonb;
  v_p5 jsonb;
  v_stage_count int;
begin
  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'P2-14 C25 active program missing'; end if;

  select r.rule_version into v_rule
  from private.exam_prep_placement_rule_versions r
  where r.program_version_id=v_program and r.status='active'
  order by r.activated_at desc nulls last,r.created_at desc
  limit 1;
  if v_rule is null then raise exception 'P2-14 C25 active placement rule missing'; end if;

  select count(*) into v_stage_count
  from private.exam_prep_stage_gate_catalog g
  where g.rule_version=v_rule and g.stage_no between 0 and 6;
  if v_stage_count<>7 then raise exception 'P2-14 C25 stage catalog must contain exactly Stages 0-6'; end if;

  v_p1:=private.exam_prep_single_stage_taxonomy_contract_v1('P1');
  v_p5:=private.exam_prep_single_stage_taxonomy_contract_v1('P5');
  if v_p1->>'progression_taxonomy'<>'stages_0_6'
     or v_p5->>'progression_taxonomy'<>'stages_0_6'
     or v_p1->>'placement_scope'<>'stage_0_local_state'
     or v_p5->>'placement_scope'<>'stage_0_local_state'
     or (v_p1->>'placement_labels_are_progression')::boolean is distinct from false
     or (v_p5->>'placement_labels_are_progression')::boolean is distinct from false
     or (v_p1->>'placement_labels_can_set_operational_stage')::boolean is distinct from false
     or (v_p5->>'placement_labels_can_set_operational_stage')::boolean is distinct from false then
    raise exception 'P2-14 C25 single-stage taxonomy contract drift';
  end if;

  if exists(
    select 1
    from private.exam_prep_component_access_gates g
    where g.program_version_id=v_program
      and greatest(g.current_operational_stage,g.max_unlocked_stage)>0
      and not exists(
        select 1
        from private.exam_prep_component_placements p
        join private.exam_prep_placement_rule_versions r
          on r.rule_version=p.rule_version and r.program_version_id=p.program_version_id and r.status='active'
        where p.user_id=g.user_id
          and p.program_version_id=g.program_version_id
          and p.component_code=g.component_code
          and p.stage0_complete
      )
  ) then
    raise exception 'P2-14 C25 existing access stage bypasses Stage 0';
  end if;

  if exists(
    select 1
    from private.exam_prep_stage_states s
    where s.program_version_id=v_program
      and s.operational_stage>0
      and not exists(
        select 1
        from private.exam_prep_component_placements p
        join private.exam_prep_placement_rule_versions r
          on r.rule_version=p.rule_version and r.program_version_id=p.program_version_id and r.status='active'
        where p.user_id=s.user_id
          and p.program_version_id=s.program_version_id
          and p.component_code=s.component_code
          and p.stage0_complete
      )
  ) then
    raise exception 'P2-14 C25 existing stage state bypasses Stage 0';
  end if;

  if has_function_privilege('authenticated','private.exam_prep_single_stage_taxonomy_contract_v1(text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_assert_single_stage_taxonomy_v1(uuid,bigint,text,smallint)','EXECUTE') then
    raise exception 'P2-14 C25 private taxonomy guard leaked to authenticated';
  end if;
end
$$;

commit;
