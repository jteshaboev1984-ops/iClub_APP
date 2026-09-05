-- P1-03 hardening: timed/paper catalog and authorization must obey operational stage.
-- Fail closed when stage state is absent. No learner state/evidence/entitlement mutation.
begin;

create or replace function private.exam_prep_timed_min_stage_v1(p_attempt_kind text)
returns smallint
language plpgsql
immutable
strict
set search_path = private, public, pg_temp
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

create or replace function public.get_exam_prep_timed_catalog_safe_v1(p_component_code text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_items jsonb;
begin
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_core_access_v1(v_uid) then raise exception 'exam_prep_core_access_required'; end if;
  if p_component_code is not null and upper(p_component_code) not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'assessment_id',x.assessment_id,
    'assessment_key',x.assessment_key,
    'assessment_version',x.assessment_version,
    'component_code',x.component_code,
    'assessment_type',x.assessment_type,
    'attempt_kind',x.attempt_kind,
    'comparison_scope',x.comparison_scope,
    'comparability_key',x.comparability_key,
    'marks_available',x.marks_available,
    'strict_timing',x.strict_timing,
    'time_limit_sec',x.time_limit_sec,
    'min_operational_stage',x.min_operational_stage,
    'current_operational_stage',x.current_operational_stage,
    'title',jsonb_build_object('en',x.title_en,'ru',x.title_ru,'uz',x.title_uz)
  ) order by x.component_code,x.assessment_id),'[]'::jsonb)
  into v_items
  from (
    select a.id assessment_id,a.assessment_key,a.assessment_version,a.component_code,a.assessment_type,
           a.title_en,a.title_ru,a.title_uz,
           tc.attempt_kind,tc.comparison_scope,tc.comparability_key,tc.marks_available,tc.strict_timing,
           private.exam_prep_timed_time_limit_v1(tc.paper_profile_id,tc.timing_rule,tc.marks_available,tc.fixed_time_limit_sec) time_limit_sec,
           private.exam_prep_timed_min_stage_v1(tc.attempt_kind) min_operational_stage,
           ss.operational_stage current_operational_stage
    from private.exam_prep_timed_assessment_contracts tc
    join private.exam_prep_assessments a on a.id=tc.assessment_id
    join private.exam_prep_content_versions cv on cv.id=a.content_version_id
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
    where tc.status='published' and a.status='published' and cv.status='published'
      and (p_component_code is null or a.component_code=upper(p_component_code))
      and private.exam_prep_timed_min_stage_v1(tc.attempt_kind) is not null
      and ss.operational_stage >= private.exam_prep_timed_min_stage_v1(tc.attempt_kind)
  ) x;

  return jsonb_build_object('component',case when p_component_code is null then null else upper(p_component_code) end,'assessments',v_items);
end;
$$;

create or replace function public.authorize_exam_prep_timed_safe_v1(p_assessment_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_ass private.exam_prep_assessments%rowtype;
  v_cv private.exam_prep_content_versions%rowtype;
  v_tc private.exam_prep_timed_assessment_contracts%rowtype;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_limit int;
  v_stage smallint;
  v_min_stage smallint;
begin
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_core_access_v1(v_uid) then raise exception 'exam_prep_core_access_required'; end if;

  select * into v_ass from private.exam_prep_assessments where id=p_assessment_id and status='published';
  if not found or v_ass.assessment_type not in ('timed','paper') then raise exception 'exam_prep_timed_assessment_unavailable'; end if;
  select * into v_cv from private.exam_prep_content_versions where id=v_ass.content_version_id and status='published';
  if not found then raise exception 'exam_prep_content_version_unavailable'; end if;
  select * into v_tc from private.exam_prep_timed_assessment_contracts where assessment_id=v_ass.id and status='published';
  if not found then raise exception 'exam_prep_timed_contract_unavailable'; end if;

  v_min_stage := private.exam_prep_timed_min_stage_v1(v_tc.attempt_kind);
  if v_min_stage is null then raise exception 'exam_prep_bad_timed_attempt_kind'; end if;

  select s.operational_stage into v_stage
  from private.exam_prep_stage_states s
  join private.exam_prep_state_engine_versions ev
    on ev.engine_version=s.engine_version and ev.status='active'
  where s.user_id=v_uid
    and s.program_version_id=v_cv.program_version_id
    and s.component_code=v_ass.component_code
  order by s.derived_at desc
  limit 1;

  if v_stage is null then
    raise exception 'exam_prep_timed_stage_state_missing';
  end if;
  if v_stage < v_min_stage then
    raise exception 'exam_prep_timed_stage_gate_not_met required=% current=%',v_min_stage,v_stage;
  end if;

  perform private.exam_prep_validate_timed_contract_v1(v_ass.id);
  v_limit:=private.exam_prep_timed_time_limit_v1(v_tc.paper_profile_id,v_tc.timing_rule,v_tc.marks_available,v_tc.fixed_time_limit_sec);

  update private.exam_prep_session_authorizations
    set status='expired'
  where user_id=v_uid and assessment_id=v_ass.id and status='issued' and valid_until<=now();

  select * into v_auth
  from private.exam_prep_session_authorizations
  where user_id=v_uid and assessment_id=v_ass.id and status='issued' and valid_until>now()
  order by authorized_at desc
  limit 1;

  if not found then
    insert into private.exam_prep_session_authorizations(
      user_id,assessment_id,component_code,purpose,status,valid_until,reason
    ) values(v_uid,v_ass.id,v_ass.component_code,'timed','issued',now()+interval '30 minutes',
      'Authorized governed timed/paper assessment at operational stage '||v_stage::text)
    returning * into v_auth;
  end if;

  return jsonb_build_object(
    'authorization_id',v_auth.id,
    'assessment_id',v_ass.id,
    'component_code',v_ass.component_code,
    'purpose','timed',
    'attempt_kind',v_tc.attempt_kind,
    'comparison_scope',v_tc.comparison_scope,
    'comparability_key',v_tc.comparability_key,
    'marks_available',v_tc.marks_available,
    'time_limit_sec',v_limit,
    'strict_timing',v_tc.strict_timing,
    'current_operational_stage',v_stage,
    'min_operational_stage',v_min_stage,
    'valid_until',v_auth.valid_until
  );
end;
$$;

-- Publication/auth hardening itself must not activate Exam Prep.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 stage-gate hardening requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 stage-gate hardening found active entitlements=%',v_active; end if;
end $$;

commit;
