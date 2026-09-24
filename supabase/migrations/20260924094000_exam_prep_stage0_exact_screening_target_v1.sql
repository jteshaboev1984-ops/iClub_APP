begin;
set local lock_timeout='3s';
set local statement_timeout='120s';

create or replace function private.exam_prep_next_diagnostic_assessment_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns bigint
language sql
stable
security definer
set search_path=''
as $$
  with requirements as (
    select
      case when p_component_code='P1' then r.p1_broad_required_items else r.p5_broad_required_items end::int as required_items,
      case when p_component_code='P1' then r.p1_broad_required_areas else r.p5_broad_required_areas end::int as required_areas
    from private.exam_prep_placement_rule_versions r
    where r.program_version_id=p_program_version_id
      and r.status='active'
    order by r.activated_at desc nulls last,r.created_at desc
    limit 1
  ), answered as (
    select distinct si.question_id, n.official_syllabus_section
    from private.exam_prep_evidence_events e
    join private.exam_prep_sessions s
      on s.id=e.session_id and s.user_id=p_user_id and s.status='finalized'
    join private.exam_prep_responses r
      on r.id=e.response_id and r.session_id=s.id and r.user_id=p_user_id
    join private.exam_prep_session_items si
      on si.session_id=s.id and si.item_order=r.item_order and si.question_id is not null
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=p_program_version_id
     and n.component_code=p_component_code
     and n.skill_code=e.skill_code
    where e.user_id=p_user_id
      and e.component_code=p_component_code
      and e.evidence_type='diagnostic'
  ), answered_summary as (
    select
      count(distinct a.question_id)::int as answered_items,
      count(distinct a.official_syllabus_section)::int as answered_areas
    from answered a
  ), remaining as (
    select
      greatest(req.required_items-coalesce(s.answered_items,0),0)::int as remaining_items,
      greatest(req.required_areas-coalesce(s.answered_areas,0),0)::int as remaining_areas
    from requirements req
    cross join answered_summary s
  ), candidates as (
    select
      a.id,
      count(*)::int as total_items,
      count(*) filter(where an.question_id is null)::int as unanswered_items,
      count(distinct n.official_syllabus_section)
        filter(where not exists(
          select 1 from answered ax
          where ax.official_syllabus_section=n.official_syllabus_section
        ))::int as new_sections
    from private.exam_prep_assessments a
    join private.exam_prep_content_versions cv
      on cv.id=a.content_version_id
     and cv.program_version_id=p_program_version_id
     and cv.component_code=p_component_code
     and cv.status='published'
    join private.exam_prep_assessment_items ai
      on ai.assessment_id=a.id
     and ai.question_id is not null
     and ai.reserve_role='diagnostic'
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=p_program_version_id
     and n.component_code=p_component_code
     and n.skill_code=ai.primary_skill_code
    left join answered an on an.question_id=ai.question_id
    where a.component_code=p_component_code
      and a.assessment_type='diagnostic'
      and a.status='published'
      and not exists(
        select 1 from private.exam_prep_assessment_items bad
        where bad.assessment_id=a.id
          and (bad.question_id is null or bad.reserve_role<>'diagnostic')
      )
    group by a.id
    having count(*) filter(where an.question_id is null)>0
  )
  select c.id
  from candidates c
  cross join remaining r
  order by
    least(c.new_sections,r.remaining_areas) desc,
    case when c.unanswered_items=c.total_items then 0 else 1 end,
    case when c.total_items<=greatest(r.remaining_items,1) then 0 else 1 end,
    abs(c.total_items-greatest(r.remaining_items,1)) asc,
    c.unanswered_items desc,
    c.id
  limit 1;
$$;

revoke all on function private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)
  to service_role;

create or replace function public.get_exam_prep_diagnostic_progress_safe_v1(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_rule text;
  v_p private.exam_prep_component_placements%rowtype;
  v_g private.exam_prep_component_access_gates%rowtype;
  v_next bigint;
  v_next_json jsonb;
  v_active uuid;
  v_active_items smallint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_placement_invalid_component'; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_profile_program_missing'; end if;

  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);
  select rule_version into v_rule
  from private.exam_prep_placement_rule_versions
  where program_version_id=v_program and status='active';

  select * into v_p
  from private.exam_prep_component_placements
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code and rule_version=v_rule;
  select * into v_g
  from private.exam_prep_component_access_gates
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code and rule_version=v_rule;
  if v_p.user_id is null or v_g.user_id is null then raise exception 'exam_prep_placement_projection_missing'; end if;

  select id,total_items into v_active,v_active_items
  from private.exam_prep_sessions
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code
    and session_type='diagnostic' and status='active'
  order by started_at desc limit 1;

  if not v_p.stage0_complete and v_p.profile_complete and v_p.content_ready and v_active is null then
    v_next:=private.exam_prep_next_diagnostic_assessment_v1(v_uid,v_program,p_component_code);
  end if;

  if v_next is not null then
    select jsonb_build_object(
      'assessment_id',a.id,'assessment_key',a.assessment_key,'assessment_version',a.assessment_version,
      'title_en',a.title_en,'title_ru',a.title_ru,'title_uz',a.title_uz,
      'items',(select count(*) from private.exam_prep_assessment_items ai where ai.assessment_id=a.id),
      'sections',(select count(distinct n.official_syllabus_section)
        from private.exam_prep_assessment_items ai
        join private.exam_prep_syllabus_nodes n
          on n.program_version_id=v_program and n.component_code=p_component_code and n.skill_code=ai.primary_skill_code
        where ai.assessment_id=a.id)
    ) into v_next_json
    from private.exam_prep_assessments a where a.id=v_next;
  end if;

  return jsonb_build_object(
    'component_code',p_component_code,
    'placement_status',v_p.placement_status,
    'route',v_p.route,
    'profile_complete',v_p.profile_complete,
    'content_ready',v_p.content_ready,
    'stage0_complete',v_p.stage0_complete,
    'screening',jsonb_build_object(
      'required_items',v_p.screening_required_items,
      'required_areas',v_p.screening_required_areas,
      'answered_items',least(v_p.screening_answered_items,v_p.screening_required_items),
      'answered_areas',least(v_p.screening_answered_areas,v_p.screening_required_areas),
      'remaining_items',greatest(v_p.screening_required_items-v_p.screening_answered_items,0),
      'remaining_areas',greatest(v_p.screening_required_areas-v_p.screening_answered_areas,0),
      'accuracy_pct',v_p.screening_accuracy_pct
    ),
    'active_session',case when v_active is null then null else jsonb_build_object('session_id',v_active,'total_items',v_active_items) end,
    'next_assessment',v_next_json,
    'max_unlocked_stage',v_g.max_unlocked_stage,
    'foundation_learning_access',v_g.foundation_learning_access,
    'route_reason',v_p.route_reason
  );
end;
$$;

revoke execute on function public.get_exam_prep_diagnostic_progress_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_diagnostic_progress_safe_v1(text) to authenticated,service_role;

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
      'answered_items',least(v_place.screening_answered_items,v_place.screening_required_items),
      'answered_areas',least(v_place.screening_answered_areas,v_place.screening_required_areas),
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

revoke all on function private.exam_prep_placement_result_payload_v1(uuid,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_placement_result_payload_v1(uuid,text)
  to service_role;

do $postcheck$
begin
  if has_function_privilege('anon','public.get_exam_prep_diagnostic_progress_safe_v1(text)'::regprocedure,'EXECUTE') then
    raise exception 'Stage0 exact-target regression: anon diagnostic progress execute leak';
  end if;
  if not has_function_privilege('authenticated','public.get_exam_prep_diagnostic_progress_safe_v1(text)'::regprocedure,'EXECUTE') then
    raise exception 'Stage0 exact-target regression: authenticated diagnostic progress execute missing';
  end if;
  if to_regprocedure('private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)') is null then
    raise exception 'Stage0 exact-target regression: selector missing';
  end if;
end
$postcheck$;

commit;
