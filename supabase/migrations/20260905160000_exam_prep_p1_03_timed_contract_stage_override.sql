-- P1-03 hardening: allow an individual timed/paper contract to require a later
-- operational stage than the attempt-kind default. Overrides can only RAISE access.
-- Existing contracts remain backward-compatible through NULL => default mapping.
-- No learner state, entitlement, beta state or paper release is changed here.
begin;

alter table private.exam_prep_timed_assessment_contracts
  add column if not exists min_operational_stage smallint null;

alter table private.exam_prep_timed_assessment_contracts
  drop constraint if exists exam_prep_timed_contract_min_operational_stage_check;
alter table private.exam_prep_timed_assessment_contracts
  add constraint exam_prep_timed_contract_min_operational_stage_check
  check(min_operational_stage is null or min_operational_stage between 1 and 5);

create or replace function private.exam_prep_timed_effective_min_stage_v1(
  p_attempt_kind text,
  p_min_operational_stage integer default null
)
returns smallint
language plpgsql
immutable
set search_path to ''
as $$
declare
  v_base smallint;
begin
  v_base:=private.exam_prep_timed_min_stage_v1(p_attempt_kind);
  if v_base is null then return null; end if;
  if p_min_operational_stage is null then return v_base; end if;
  if p_min_operational_stage not between 1 and 5 then
    raise exception 'exam_prep_timed_stage_override_out_of_range override=%',p_min_operational_stage;
  end if;
  if p_min_operational_stage<v_base then
    raise exception 'exam_prep_timed_stage_override_below_base base=% override=%',v_base,p_min_operational_stage;
  end if;
  return p_min_operational_stage::smallint;
end;
$$;
revoke all on function private.exam_prep_timed_effective_min_stage_v1(text,integer) from public,anon,authenticated;
grant execute on function private.exam_prep_timed_effective_min_stage_v1(text,integer) to service_role;

create or replace function private.exam_prep_validate_timed_stage_override_v1()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare v_effective smallint;
begin
  v_effective:=private.exam_prep_timed_effective_min_stage_v1(new.attempt_kind,new.min_operational_stage::integer);
  if v_effective is null then raise exception 'exam_prep_bad_timed_attempt_kind'; end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_validate_timed_stage_override_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_validate_timed_stage_override_v1 on private.exam_prep_timed_assessment_contracts;
create trigger exam_prep_validate_timed_stage_override_v1
before insert or update of attempt_kind,min_operational_stage
on private.exam_prep_timed_assessment_contracts
for each row execute function private.exam_prep_validate_timed_stage_override_v1();

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
    'min_operational_stage',private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage::integer),
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
    and private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage::integer) is not null
    and ss.operational_stage>=private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage::integer);

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

  v_min_stage:=private.exam_prep_timed_effective_min_stage_v1(v_c.attempt_kind,v_c.min_operational_stage::integer);
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

  if v_stage is null then raise exception 'exam_prep_timed_stage_state_missing'; end if;
  if v_stage<v_min_stage then
    raise exception 'exam_prep_timed_stage_gate_not_met required=% current=%',v_min_stage,v_stage;
  end if;

  v_limit:=private.exam_prep_timed_time_limit_v1(
    v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec
  );

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    v_uid,v_a.id,v_a.component_code,v_a.assessment_type,'issued',now()+interval '1 hour',
    'P1-03 governed timed/paper session; operational stage '||v_stage::text||'; minimum stage '||v_min_stage::text
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

-- Existing contracts must retain their old effective stage when no override is set.
do $$
declare
  v_bad int;
  v_p1_fp1 smallint;
  v_p5_fp1 smallint;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select count(*) into v_bad
  from private.exam_prep_timed_assessment_contracts c
  where c.min_operational_stage is not null
    and c.min_operational_stage<private.exam_prep_timed_min_stage_v1(c.attempt_kind);
  if v_bad<>0 then raise exception 'P1-03 timed stage override found below-base contracts=%',v_bad; end if;

  select private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage::integer)
  into v_p1_fp1
  from private.exam_prep_timed_assessment_contracts c
  join private.exam_prep_assessments a on a.id=c.assessment_id
  where a.assessment_key='p1_stage3_full_paper_01' and a.assessment_version='av1' and c.status='published';
  select private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage::integer)
  into v_p5_fp1
  from private.exam_prep_timed_assessment_contracts c
  join private.exam_prep_assessments a on a.id=c.assessment_id
  where a.assessment_key='p5_stage3_full_paper_01' and a.assessment_version='av1' and c.status='published';
  if v_p1_fp1<>3 or v_p5_fp1<>3 then
    raise exception 'P1-03 timed stage override changed Paper01 defaults P1=% P5=%',v_p1_fp1,v_p5_fp1;
  end if;

  if private.exam_prep_timed_effective_min_stage_v1('full_paper',4)<>4
     or private.exam_prep_timed_effective_min_stage_v1('timed_section',3)<>3 then
    raise exception 'P1-03 timed stage override effective mapping incorrect';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 timed stage override deployment requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 timed stage override active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 timed stage override deployment must not create learner runtime evidence';
  end if;
end $$;

commit;
