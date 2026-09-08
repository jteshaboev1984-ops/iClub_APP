-- P2-13 / Annual Roadmap C24: distinguish broad diagnostic screening from full Stage-0 placement.
-- No invented single-session duration is introduced. Full placement is component-specific and may span sessions.
-- This migration is read-contract only: it does not change placement thresholds, learner evidence, mastery or legacy history.
begin;

create or replace function private.exam_prep_stage0_workflow_contract_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_rule private.exam_prep_placement_rule_versions%rowtype;
  v_required_items smallint;
  v_required_areas smallint;
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

  select * into v_rule
  from private.exam_prep_placement_rule_versions r
  where r.program_version_id=v_program and r.status='active'
  order by r.activated_at desc nulls last,r.created_at desc
  limit 1;
  if v_rule.rule_version is null then raise exception 'exam_prep_placement_rule_missing'; end if;

  v_required_items:=case when p_component_code='P1' then v_rule.p1_broad_required_items else v_rule.p5_broad_required_items end;
  v_required_areas:=case when p_component_code='P1' then v_rule.p1_broad_required_areas else v_rule.p5_broad_required_areas end;

  return jsonb_build_object(
    'contract_version','p2_13_c24_v1',
    'component_code',p_component_code,
    'workflow_type','component_specific_full_placement',
    'placement_model','multi_session',
    'single_session_completion_required',false,
    'time_based_stage_completion',false,
    'broad_screening',jsonb_build_object(
      'phase_key','broad_screening',
      'required_items',v_required_items,
      'required_areas',v_required_areas,
      'delivery_model','governed_short_packages',
      'can_span_sessions',true,
      'fixed_duration_minutes',null,
      'duration_policy','not_fixed_by_current_governance'
    ),
    'targeted_confirmation',jsonb_build_object(
      'phase_key','targeted_confirmation_if_needed',
      'usage','only_if_needed',
      'min_items',v_rule.targeted_min_items,
      'max_items',v_rule.targeted_max_items,
      'focus','strong_weak_or_ambiguous_areas',
      'duplicated_broad_testing_allowed',false
    ),
    'human_confirmation',jsonb_build_object(
      'mentor_required_for_core',false,
      'core_conservative_route_allowed',true,
      'purpose','ambiguity_or_high_impact_advanced_skip'
    ),
    'safeguards',jsonb_build_object(
      'p1_p5_separate',true,
      'calendar_cannot_complete_placement',true,
      'duration_cannot_complete_placement',true,
      'advanced_route_auto_awarded',false
    )
  );
end;
$$;

revoke all on function private.exam_prep_stage0_workflow_contract_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage0_workflow_contract_v1(text) to service_role;

create or replace function public.get_exam_prep_stage0_workflow_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
begin
  perform private.exam_prep_require_core_access_v1();
  return private.exam_prep_stage0_workflow_contract_v1(p_component_code);
end;
$$;

revoke all on function public.get_exam_prep_stage0_workflow_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_stage0_workflow_safe_v1(text) to authenticated,service_role;

-- C24 deployment invariants: keep the already-approved broad screen and targeted confirmation sizes.
-- This explicitly prevents a future migration from silently turning placement into one arbitrary timed sitting.
do $$
declare
  v_rule private.exam_prep_placement_rule_versions%rowtype;
  v_p1 jsonb;
  v_p5 jsonb;
begin
  select * into v_rule
  from private.exam_prep_placement_rule_versions r
  join private.exam_prep_program_versions pv on pv.id=r.program_version_id
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active'
    and r.status='active'
  order by r.activated_at desc nulls last,r.created_at desc
  limit 1;

  if v_rule.rule_version is null then raise exception 'P2-13 C24 active placement rule missing'; end if;
  if v_rule.p1_broad_required_items<>24 or v_rule.p1_broad_required_areas<>8 then
    raise exception 'P2-13 C24 P1 broad-screen contract drift';
  end if;
  if v_rule.p5_broad_required_items<>15 or v_rule.p5_broad_required_areas<>5 then
    raise exception 'P2-13 C24 P5 broad-screen contract drift';
  end if;
  if v_rule.targeted_min_items<>3 or v_rule.targeted_max_items<>5 then
    raise exception 'P2-13 C24 targeted confirmation contract drift';
  end if;

  v_p1:=private.exam_prep_stage0_workflow_contract_v1('P1');
  v_p5:=private.exam_prep_stage0_workflow_contract_v1('P5');
  if v_p1->>'placement_model'<>'multi_session'
     or v_p5->>'placement_model'<>'multi_session'
     or (v_p1->>'single_session_completion_required')::boolean is distinct from false
     or (v_p5->>'single_session_completion_required')::boolean is distinct from false
     or v_p1->'broad_screening'->>'fixed_duration_minutes' is not null
     or v_p5->'broad_screening'->>'fixed_duration_minutes' is not null then
    raise exception 'P2-13 C24 placement duration contract invalid';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_stage0_workflow_safe_v1(text)','EXECUTE') then
    raise exception 'P2-13 C24 anon workflow API leak';
  end if;
end
$$;

commit;
