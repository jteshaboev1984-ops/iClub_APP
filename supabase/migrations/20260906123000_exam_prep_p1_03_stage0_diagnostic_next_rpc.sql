-- P1-03 pre-live blocker: learner-safe Stage-0 diagnostic progression.
-- Reuses already-published governed diagnostic assessments; no diagnostic content is copied.
-- Selection prioritizes still-unseen syllabus sections, then unanswered item count.
begin;

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
  with answered as (
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
  order by c.new_sections desc,c.unanswered_items desc,c.total_items desc,c.id
  limit 1;
$$;
revoke all on function private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text) to service_role;

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
      'answered_items',v_p.screening_answered_items,
      'answered_areas',v_p.screening_answered_areas,
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

create or replace function public.start_exam_prep_next_diagnostic_safe_v1(
  p_component_code text,
  p_idempotency_key text
)
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
  v_active private.exam_prep_sessions%rowtype;
  v_ass private.exam_prep_assessments%rowtype;
  v_auth uuid;
  v_start jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_placement_invalid_component'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_profile_program_missing'; end if;

  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);
  select rule_version into v_rule from private.exam_prep_placement_rule_versions where program_version_id=v_program and status='active';
  select * into v_p from private.exam_prep_component_placements
    where user_id=v_uid and program_version_id=v_program and component_code=p_component_code and rule_version=v_rule;
  if v_p.user_id is null then raise exception 'exam_prep_placement_projection_missing'; end if;
  if not v_p.profile_complete then raise exception 'exam_prep_diagnostic_profile_required'; end if;
  if not v_p.content_ready then raise exception 'exam_prep_diagnostic_content_not_ready'; end if;
  if v_p.stage0_complete then raise exception 'exam_prep_diagnostic_already_complete'; end if;

  -- Page reload/network recovery: one active diagnostic per learner/component is resumed,
  -- never duplicated merely because the client generated a new key.
  select * into v_active
  from private.exam_prep_sessions
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code
    and session_type='diagnostic' and status='active'
  order by started_at desc limit 1;
  if v_active.id is not null then
    return jsonb_build_object(
      'session_id',v_active.id,'status','active','component_code',p_component_code,
      'session_type','diagnostic','total_items',v_active.total_items,'resumed',true
    );
  end if;

  select * into v_ass
  from private.exam_prep_assessments
  where id=private.exam_prep_next_diagnostic_assessment_v1(v_uid,v_program,p_component_code)
    and status='published' and assessment_type='diagnostic' and component_code=p_component_code;
  if v_ass.id is null then raise exception 'exam_prep_diagnostic_no_next_assessment'; end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    v_uid,v_ass.id,p_component_code,'diagnostic','issued',now()+interval '1 hour',
    'Stage-0 broad diagnostic next governed package'
  ) returning id into v_auth;

  v_start:=public.start_exam_prep_session_safe_v1(v_auth,p_idempotency_key);
  return v_start || jsonb_build_object(
    'assessment_id',v_ass.id,'assessment_key',v_ass.assessment_key,
    'title_en',v_ass.title_en,'title_ru',v_ass.title_ru,'title_uz',v_ass.title_uz
  );
end;
$$;
revoke execute on function public.start_exam_prep_next_diagnostic_safe_v1(text,text) from public,anon;
grant execute on function public.start_exam_prep_next_diagnostic_safe_v1(text,text) to authenticated,service_role;

-- Static/deployment guard: the existing governed diagnostics must be sufficient for the placement law.
do $$
declare
  v_program bigint;
  v_p1_items int; v_p1_areas int; v_p5_items int; v_p5_areas int;
  v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select id into v_program from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select count(distinct ai.question_id),count(distinct n.official_syllabus_section)
    into v_p1_items,v_p1_areas
  from private.exam_prep_assessments a
  join private.exam_prep_assessment_items ai on ai.assessment_id=a.id and ai.question_id is not null and ai.reserve_role='diagnostic'
  join private.exam_prep_syllabus_nodes n on n.program_version_id=v_program and n.component_code='P1' and n.skill_code=ai.primary_skill_code
  where a.component_code='P1' and a.assessment_type='diagnostic' and a.status='published';
  select count(distinct ai.question_id),count(distinct n.official_syllabus_section)
    into v_p5_items,v_p5_areas
  from private.exam_prep_assessments a
  join private.exam_prep_assessment_items ai on ai.assessment_id=a.id and ai.question_id is not null and ai.reserve_role='diagnostic'
  join private.exam_prep_syllabus_nodes n on n.program_version_id=v_program and n.component_code='P5' and n.skill_code=ai.primary_skill_code
  where a.component_code='P5' and a.assessment_type='diagnostic' and a.status='published';
  if v_p1_items<24 or v_p1_areas<8 then raise exception 'P1-03 Stage0 diagnostic P1 content insufficient items=% areas=%',v_p1_items,v_p1_areas; end if;
  if v_p5_items<15 or v_p5_areas<5 then raise exception 'P1-03 Stage0 diagnostic P5 content insufficient items=% areas=%',v_p5_items,v_p5_areas; end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage0 diagnostic RPC deployment requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage0 diagnostic RPC deployment active entitlement residue=%',v_active; end if;
end $$;

commit;
