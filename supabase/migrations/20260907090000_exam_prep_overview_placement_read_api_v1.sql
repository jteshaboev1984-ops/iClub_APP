-- Exam Prep EP-00 / EP-04 learner read surfaces v1.
-- Additive, read-only and component-scoped. No placement rebuild, no learner evidence write,
-- no legacy Practice/Tour/history mutation.

begin;

create or replace function private.exam_prep_overview_payload_v1(
  p_user_id uuid,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_engine text;
  v_rule text;
  v_stage private.exam_prep_stage_states%rowtype;
  v_place private.exam_prep_component_placements%rowtype;
  v_latest private.exam_prep_evidence_events%rowtype;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_item private.exam_prep_weekly_plan_items%rowtype;
  v_open_corrections int:=0;
  v_next_action text;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_overview_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_overview_program_missing'; end if;

  select ev.engine_version into v_engine
  from private.exam_prep_state_engine_versions ev
  where ev.status='active'
  order by ev.activated_at desc nulls last,ev.created_at desc
  limit 1;
  if v_engine is null then raise exception 'exam_prep_overview_engine_missing'; end if;

  select r.rule_version into v_rule
  from private.exam_prep_placement_rule_versions r
  where r.program_version_id=v_program and r.status='active'
  order by r.activated_at desc nulls last,r.created_at desc
  limit 1;

  select * into v_stage
  from private.exam_prep_stage_states s
  where s.user_id=p_user_id
    and s.program_version_id=v_program
    and s.component_code=p_component_code
    and s.engine_version=v_engine
  order by s.derived_at desc
  limit 1;

  if v_rule is not null then
    select * into v_place
    from private.exam_prep_component_placements p
    where p.user_id=p_user_id
      and p.program_version_id=v_program
      and p.component_code=p_component_code
      and p.rule_version=v_rule;
  end if;

  select * into v_latest
  from private.exam_prep_evidence_events e
  where e.user_id=p_user_id and e.component_code=p_component_code
  order by e.created_at desc,e.id desc
  limit 1;

  select count(*) into v_open_corrections
  from private.exam_prep_correction_cases c
  where c.user_id=p_user_id
    and c.component_code=p_component_code
    and c.status in ('open','remediating','retest_due','reopened');

  select * into v_plan
  from private.exam_prep_weekly_plans wp
  where wp.user_id=p_user_id
    and wp.program_version_id=v_program
    and wp.component_code=p_component_code
    and wp.status='active'
  order by wp.active_week_no desc,wp.plan_version desc,wp.generated_at desc
  limit 1;

  if v_plan.id is not null then
    select * into v_item
    from private.exam_prep_weekly_plan_items i
    where i.plan_id=v_plan.id and i.status='pending'
    order by i.priority_order
    limit 1;
  end if;

  if not coalesce(v_place.stage0_complete,false) then
    v_next_action:='continue_entry_check';
  elsif v_item.plan_id is not null then
    v_next_action:=case v_item.item_type
      when 'retest' then 'delayed_retest'
      when 'correction' then 'work_correction'
      when 'mixed_transfer' then 'mixed_practice'
      when 'learning' then 'learning'
      when 'prerequisite' then 'foundation_prerequisite'
      when 'rebaseline' then 'update_plan'
      else 'open_weekly_plan'
    end;
  elsif coalesce(v_stage.operational_stage,0)>=6 then
    v_next_action:='final_calibration';
  elsif coalesce(v_stage.operational_stage,0)>=5 then
    v_next_action:='view_readiness';
  elsif v_open_corrections>0 then
    v_next_action:='work_correction';
  else
    v_next_action:='open_weekly_plan';
  end if;

  return jsonb_build_object(
    'component_code',p_component_code,
    'program_version_id',v_program,
    'operational_stage',coalesce(v_stage.operational_stage,0),
    'coverage_count',coalesce(v_stage.coverage_count,0),
    'denominator_count',case when p_component_code='P1' then 45 else 36 end,
    'coverage_pct',coalesce(v_stage.coverage_pct,0),
    'stage0_complete',coalesce(v_place.stage0_complete,false),
    'open_correction_count',v_open_corrections,
    'last_evidence',case when v_latest.id is null then null else jsonb_build_object(
      'evidence_type',v_latest.evidence_type,
      'verification_status',v_latest.verification_status,
      'is_correct',v_latest.is_correct,
      'created_at',v_latest.created_at
    ) end,
    'next_action',jsonb_build_object(
      'action_code',v_next_action,
      'plan_id',v_plan.id,
      'priority_order',v_item.priority_order,
      'item_type',v_item.item_type,
      'due_at',v_item.due_at
    )
  );
end;
$$;

revoke all on function private.exam_prep_overview_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_overview_payload_v1(uuid,text) to service_role;

create or replace function public.get_exam_prep_overview_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_overview_payload_v1(v_uid,p_component_code);
end;
$$;
revoke all on function public.get_exam_prep_overview_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_overview_safe_v1(text) to authenticated,service_role;

create or replace function private.exam_prep_placement_result_payload_v1(
  p_user_id uuid,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_rule text;
  v_place private.exam_prep_component_placements%rowtype;
  v_gate private.exam_prep_component_access_gates%rowtype;
  v_next_action text;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_placement_result_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_placement_result_program_missing'; end if;

  select r.rule_version into v_rule
  from private.exam_prep_placement_rule_versions r
  where r.program_version_id=v_program and r.status='active'
  order by r.activated_at desc nulls last,r.created_at desc
  limit 1;
  if v_rule is null then raise exception 'exam_prep_placement_result_rule_missing'; end if;

  select * into v_place
  from private.exam_prep_component_placements p
  where p.user_id=p_user_id
    and p.program_version_id=v_program
    and p.component_code=p_component_code
    and p.rule_version=v_rule;

  select * into v_gate
  from private.exam_prep_component_access_gates g
  where g.user_id=p_user_id
    and g.program_version_id=v_program
    and g.component_code=p_component_code
    and g.rule_version=v_rule;

  if v_place.user_id is null or v_gate.user_id is null then
    return jsonb_build_object(
      'component_code',p_component_code,
      'available',false,
      'placement_status','not_started',
      'stage0_complete',false,
      'next_action_code','continue_entry_check'
    );
  end if;

  v_next_action:=case when v_place.stage0_complete then 'open_weekly_plan' else 'continue_entry_check' end;

  return jsonb_build_object(
    'component_code',p_component_code,
    'available',true,
    'placement_status',v_place.placement_status,
    'provisional_route',v_place.route,
    'stage0_complete',v_place.stage0_complete,
    'profile_complete',v_place.profile_complete,
    'content_ready',v_place.content_ready,
    'ambiguity',v_place.ambiguity,
    'advanced_skip_requires_human',v_place.advanced_skip_requires_human,
    'screening',jsonb_build_object(
      'required_items',v_place.screening_required_items,
      'required_areas',v_place.screening_required_areas,
      'answered_items',v_place.screening_answered_items,
      'answered_areas',v_place.screening_answered_areas,
      'remaining_items',greatest(v_place.screening_required_items-v_place.screening_answered_items,0),
      'remaining_areas',greatest(v_place.screening_required_areas-v_place.screening_answered_areas,0),
      'accuracy_pct',v_place.screening_accuracy_pct
    ),
    'prerequisites',jsonb_build_object(
      'unknown_count',v_place.prerequisite_unknown_count,
      'blocker_count',v_place.prerequisite_blocker_count
    ),
    'access',jsonb_build_object(
      'max_unlocked_stage',v_gate.max_unlocked_stage,
      'foundation_learning_access',v_gate.foundation_learning_access,
      'advanced_route_access',v_gate.advanced_route_access
    ),
    'next_action_code',v_next_action
  );
end;
$$;

revoke all on function private.exam_prep_placement_result_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_placement_result_payload_v1(uuid,text) to service_role;

create or replace function public.get_exam_prep_placement_result_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_placement_result_payload_v1(v_uid,p_component_code);
end;
$$;
revoke all on function public.get_exam_prep_placement_result_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_placement_result_safe_v1(text) to authenticated,service_role;

-- Deployment invariants: read-only surfaces must exist, remain component-scoped, and anon stays blocked.
do $$
begin
  if to_regprocedure('public.get_exam_prep_overview_safe_v1(text)') is null
     or to_regprocedure('public.get_exam_prep_placement_result_safe_v1(text)') is null then
    raise exception 'Exam Prep overview/placement read API missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_overview_safe_v1(text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_placement_result_safe_v1(text)','EXECUTE') then
    raise exception 'Exam Prep overview/placement read API anon execute leak';
  end if;
end $$;

commit;
