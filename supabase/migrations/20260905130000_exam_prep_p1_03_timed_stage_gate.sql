-- P1-03 hardening: timed/paper catalog and authorization must obey operational stage.
-- Fail closed when stage state is absent. Preserve existing Core/content/timing semantics.
-- No learner state/evidence/entitlement mutation.
begin;

create or replace function private.exam_prep_timed_min_stage_v1(p_attempt_kind text)
returns smallint
language plpgsql
immutable
strict
set search_path to ''
as $$
begin
  return case p_attempt_kind
    when 'timed_section' then 2
    when 'modified_paper' then 2
    when 'diagnostic_full' then 2
    when 'full_paper' then 3
    else null
  end;
end;
$$;

create or replace function public.get_exam_prep_timed_catalog_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  v_uid uuid;
  v_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'assessment_id',a.id,
    'assessment_key',a.assessment_key,
    'assessment_version',a.assessment_version,
    'title_en',a.title_en,
    'title_ru',a.title_ru,
    'title_uz',a.title_uz,
    'assessment_type',a.assessment_type,
    'attempt_kind',c.attempt_kind,
    'timing_rule',c.timing_rule,
    'marks_available',c.marks_available,
    'time_limit_sec',private.exam_prep_timed_time_limit_v1(c.paper_profile_id,c.timing_rule,c.marks_available,c.fixed_time_limit_sec),
    'comparison_scope',c.comparison_scope,
    'comparability_key',c.comparability_key,
    'strict_timing',c.strict_timing,
    'min_operational_stage',private.exam_prep_timed_min_stage_v1(c.attempt_kind),
    'current_operational_stage',ss.operational_stage
  ) order by a.id),'[]'::jsonb)
  into v_result
  from private.exam_prep_assessments a
  join private.exam_prep_content_versions cv
    on cv.id=a.content_version_id and cv.status='published' and cv.component_code=a.component_code
  join private.exam_prep_timed_assessment_contracts c
    on c.assessment_id=a.id and c.status='published'
  join lateral (
    select s.operational_stage
    from private.exam_prep_stage_states s
    join private.exam_prep_state_engine_versions ev
      on ev.engine_version=s.engine_version and ev.status='active'
    where s.user_id=v_uid
      and s.program_version_id=cv.program_version_id
      and s.component_code=a.component_code
    order by s.derived_at desc
    limit 1
  ) ss on true
  where a.component_code=p_component_code
    and a.status='published'
    and a.assessment_type in ('timed','paper')
    and private.exam_prep_timed_min_stage_v1(c.attempt_kind) is not null
    and ss.operational_stage>=private.exam_prep_timed_min_stage_v1(c.attempt_kind);

  return jsonb_build_object('component_code',p_component_code,'assessments',v_result);
end;
$$;

create or replace function public.authorize_exam_prep_timed_safe_v1(p_assessment_id bigint)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid uuid;
  v_a private.exam_prep_assessments%rowtype;
  v_cv private.exam_prep_content_versions%rowtype;
  v_c private.exam_prep_timed_assessment_contracts%rowtype;
  v_limit integer;
  v_items integer;
  v_specs integer;
  v_marks integer;
  v_auth uuid;
  v_stage smallint;
  v_min_stage smallint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  select * into v_a
  from private.exam_prep_assessments
  where id=p_assessment_id and status='published';
  if v_a.id is null or v_a.assessment_type not in ('timed','paper') then
    raise exception 'exam_prep_timed_assessment_not_published';
  end if;

  select * into v_cv
  from private.exam_prep_content_versions
  where id=v_a.content_version_id and status='published';
  if v_cv.id is null or v_cv.component_code<>v_a.component_code then
    raise exception 'exam_prep_timed_content_not_published';
  end if;

  select * into v_c
  from private.exam_prep_timed_assessment_contracts
  where assessment_id=v_a.id and status='published';
  if v_c.assessment_id is null then
    raise exception 'exam_prep_timed_contract_not_published';
  end if;

  -- Preserve the pre-existing P1-03 governed content floor exactly.
  select count(*) into v_items
  from private.exam_prep_assessment_items
  where assessment_id=v_a.id;

  select count(*),coalesce(sum(max_marks),0)
  into v_specs,v_marks
  from private.exam_prep_timed_assessment_items
  where assessment_id=v_a.id;

  if v_items<1 or v_specs<>v_items or v_marks<>v_c.marks_available then
    raise exception 'exam_prep_timed_content_floor_not_met';
  end if;

  if exists(
    select 1
    from private.exam_prep_assessment_items ai
    where ai.assessment_id=v_a.id and (
      (ai.question_id is not null and ai.reserve_role<>'timed') or
      (ai.written_task_id is not null and ai.reserve_role<>'written')
    )
  ) then
    raise exception 'exam_prep_timed_reserve_role_mismatch';
  end if;

  -- New fail-closed operational-stage gate.
  v_min_stage:=private.exam_prep_timed_min_stage_v1(v_c.attempt_kind);
  if v_min_stage is null then raise exception 'exam_prep_bad_timed_attempt_kind'; end if;

  select s.operational_stage
  into v_stage
  from private.exam_prep_stage_states s
  join private.exam_prep_state_engine_versions ev
    on ev.engine_version=s.engine_version and ev.status='active'
  where s.user_id=v_uid
    and s.program_version_id=v_cv.program_version_id
    and s.component_code=v_a.component_code
  order by s.derived_at desc
  limit 1;

  if v_stage is null then
    raise exception 'exam_prep_timed_stage_state_missing';
  end if;
  if v_stage<v_min_stage then
    raise exception 'exam_prep_timed_stage_gate_not_met required=% current=%',v_min_stage,v_stage;
  end if;

  v_limit:=private.exam_prep_timed_time_limit_v1(
    v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec
  );

  -- Preserve the pre-existing one-hour authorization semantics and purpose value.
  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    v_uid,v_a.id,v_a.component_code,v_a.assessment_type,'issued',now()+interval '1 hour',
    'P1-03 governed timed/paper session; operational stage '||v_stage::text
  ) returning id into v_auth;

  return jsonb_build_object(
    'authorization_id',v_auth,
    'assessment_id',v_a.id,
    'component_code',v_a.component_code,
    'purpose',v_a.assessment_type,
    'attempt_kind',v_c.attempt_kind,
    'timing_rule',v_c.timing_rule,
    'marks_available',v_c.marks_available,
    'time_limit_sec',v_limit,
    'comparison_scope',v_c.comparison_scope,
    'comparability_key',v_c.comparability_key,
    'strict_timing',v_c.strict_timing,
    'current_operational_stage',v_stage,
    'min_operational_stage',v_min_stage
  );
end;
$$;

-- Hardening itself must never activate controlled beta.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_cfg
  from private.exam_prep_feature_config
  where program_key='math_as_p1_p5';

  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P1-03 stage-gate hardening requires fail-closed feature state';
  end if;

  select count(*) into v_active
  from private.exam_prep_feature_entitlements
  where entitlement_status='active';
  if v_active<>0 then
    raise exception 'P1-03 stage-gate hardening found active entitlements=%',v_active;
  end if;
end $$;

commit;
