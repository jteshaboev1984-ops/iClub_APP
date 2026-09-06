-- P1-03 Stage-4 Paper02 release guard.
-- Adds a fail-closed governance lock only. It does NOT approve Stage 4, publish Paper02,
-- change learner stages, enable beta, or create learner runtime evidence.
begin;

create table if not exists private.exam_prep_stage4_release_controls (
  control_version text primary key,
  status text not null check (status in ('draft','active','retired')),
  stage4_policy_status text not null default 'pending' check (stage4_policy_status in ('pending','approved','retired')),
  paper02_release_status text not null default 'pending' check (paper02_release_status in ('pending','approved','retired')),
  require_stage3_key_registry_approved boolean not null default true,
  min_paper02_stage smallint not null default 4 check (min_paper02_stage between 4 and 5),
  source_note text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists exam_prep_stage4_release_controls_one_active_idx
  on private.exam_prep_stage4_release_controls ((status)) where status='active';

insert into private.exam_prep_stage4_release_controls(
  control_version,status,stage4_policy_status,paper02_release_status,
  require_stage3_key_registry_approved,min_paper02_stage,source_note
) values (
  'stage4_paper02_release_guard_v1_2026_09_06','active','pending','pending',true,4,
  'Fail-closed pre-live release control. Paper02 cannot be published/released until Stage-4 policy is explicitly approved and deployed, the Stage-3 key-skill registry is approved/non-empty for the component, and the per-contract minimum stage is at least 4.'
)
on conflict(control_version) do update set
  status=excluded.status,
  stage4_policy_status=excluded.stage4_policy_status,
  paper02_release_status=excluded.paper02_release_status,
  require_stage3_key_registry_approved=excluded.require_stage3_key_registry_approved,
  min_paper02_stage=excluded.min_paper02_stage,
  source_note=excluded.source_note,
  updated_at=now();

create or replace function private.exam_prep_stage4_paper02_release_readiness_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_control private.exam_prep_stage4_release_controls%rowtype;
  v_stage3 private.exam_prep_stage3_exit_rules%rowtype;
  v_program bigint;
  v_key_count int:=0;
  v_assessment_id bigint;
  v_assessment_status text;
  v_contract_count int:=0;
  v_exit_evaluator boolean:=false;
  v_override_helper boolean:=false;
  v_ready boolean:=false;
  v_reason text:='control_missing';
  v_key text;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  v_key:=case p_component_code when 'P1' then 'p1_stage4_full_paper_02' else 'p5_stage4_full_paper_02' end;

  select * into v_control
  from private.exam_prep_stage4_release_controls
  where status='active'
  order by created_at desc
  limit 1;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';

  select * into v_stage3
  from private.exam_prep_stage3_exit_rules
  where status='active'
  order by created_at desc
  limit 1;

  if v_stage3.rule_version is not null and v_program is not null then
    select count(*) into v_key_count
    from private.exam_prep_stage3_key_skills
    where rule_version=v_stage3.rule_version
      and program_version_id=v_program
      and component_code=p_component_code;
  end if;

  select a.id,a.status into v_assessment_id,v_assessment_status
  from private.exam_prep_assessments a
  where a.assessment_key=v_key and a.assessment_version='av1'
  order by a.id desc
  limit 1;

  if v_assessment_id is not null then
    select count(*) into v_contract_count
    from private.exam_prep_timed_assessment_contracts
    where assessment_id=v_assessment_id;
  end if;

  v_exit_evaluator:=to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null;
  v_override_helper:=to_regprocedure('private.exam_prep_timed_effective_min_stage_v1(text,integer)') is not null;

  if v_control.control_version is null then
    v_reason:='control_missing';
  elsif v_control.stage4_policy_status<>'approved' then
    v_reason:='stage4_policy_pending';
  elsif v_control.paper02_release_status<>'approved' then
    v_reason:='paper02_release_pending';
  elsif v_control.require_stage3_key_registry_approved and (v_stage3.rule_version is null or v_stage3.key_registry_status<>'approved') then
    v_reason:='stage3_key_registry_pending';
  elsif v_control.require_stage3_key_registry_approved and v_key_count=0 then
    v_reason:='stage3_key_registry_empty';
  elsif not v_exit_evaluator then
    v_reason:='stage4_exit_evaluator_missing';
  elsif not v_override_helper then
    v_reason:='stage_override_hardening_missing';
  elsif v_assessment_id is null then
    v_reason:='paper02_missing';
  elsif v_assessment_status='published' or v_contract_count>0 then
    v_reason:='paper02_already_released';
  elsif v_assessment_status<>'approved' then
    v_reason:='paper02_not_approved';
  else
    v_reason:='ready';
    v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,
    'reason_code',v_reason,
    'control_version',v_control.control_version,
    'stage4_policy_status',v_control.stage4_policy_status,
    'paper02_release_status',v_control.paper02_release_status,
    'component_code',p_component_code,
    'stage3_key_registry_status',v_stage3.key_registry_status,
    'stage3_key_count',v_key_count,
    'stage4_exit_evaluator_deployed',v_exit_evaluator,
    'stage_override_hardening_deployed',v_override_helper,
    'paper02_assessment_id',v_assessment_id,
    'paper02_assessment_status',v_assessment_status,
    'paper02_contract_count',v_contract_count,
    'required_min_stage',v_control.min_paper02_stage,
    'paper02_release_allowed',v_ready
  );
end;
$$;

revoke all on function private.exam_prep_stage4_paper02_release_readiness_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage4_paper02_release_readiness_v1(text) to service_role;

create or replace function private.exam_prep_assert_stage4_paper02_release_governance_v1(p_component_code text)
returns void
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_control private.exam_prep_stage4_release_controls%rowtype;
  v_stage3 private.exam_prep_stage3_exit_rules%rowtype;
  v_program bigint;
  v_keys int:=0;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_control
  from private.exam_prep_stage4_release_controls
  where status='active'
  order by created_at desc
  limit 1;
  if v_control.control_version is null then raise exception 'exam_prep_stage4_release_control_missing'; end if;
  if v_control.stage4_policy_status<>'approved' then raise exception 'exam_prep_stage4_policy_not_approved'; end if;
  if v_control.paper02_release_status<>'approved' then raise exception 'exam_prep_stage4_paper02_release_not_approved'; end if;

  select * into v_stage3
  from private.exam_prep_stage3_exit_rules
  where status='active'
  order by created_at desc
  limit 1;
  if v_control.require_stage3_key_registry_approved and (v_stage3.rule_version is null or v_stage3.key_registry_status<>'approved') then
    raise exception 'exam_prep_stage3_key_registry_not_approved';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_control.require_stage3_key_registry_approved then
    select count(*) into v_keys
    from private.exam_prep_stage3_key_skills
    where rule_version=v_stage3.rule_version
      and program_version_id=v_program
      and component_code=p_component_code;
    if v_keys=0 then raise exception 'exam_prep_stage3_key_registry_empty'; end if;
  end if;

  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is null then
    raise exception 'exam_prep_stage4_exit_policy_not_deployed';
  end if;
  if to_regprocedure('private.exam_prep_timed_effective_min_stage_v1(text,integer)') is null then
    raise exception 'exam_prep_stage4_stage_override_hardening_missing';
  end if;
end;
$$;

revoke all on function private.exam_prep_assert_stage4_paper02_release_governance_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_assert_stage4_paper02_release_governance_v1(text) to service_role;

create or replace function private.exam_prep_guard_stage4_paper02_assessment_release_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if new.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02')
     and new.status='published' then
    perform private.exam_prep_assert_stage4_paper02_release_governance_v1(new.component_code);
  end if;
  return new;
end;
$$;

revoke all on function private.exam_prep_guard_stage4_paper02_assessment_release_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_guard_stage4_paper02_assessment_release_v1 on private.exam_prep_assessments;
create trigger exam_prep_guard_stage4_paper02_assessment_release_v1
before insert or update of status on private.exam_prep_assessments
for each row execute function private.exam_prep_guard_stage4_paper02_assessment_release_v1();

create or replace function private.exam_prep_guard_stage4_paper02_contract_release_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_key text;
  v_component text;
  v_min_stage smallint;
  v_required smallint;
begin
  if new.status<>'published' then return new; end if;

  select assessment_key,component_code into v_key,v_component
  from private.exam_prep_assessments
  where id=new.assessment_id;

  if v_key not in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') then return new; end if;

  perform private.exam_prep_assert_stage4_paper02_release_governance_v1(v_component);
  select min_paper02_stage into v_required
  from private.exam_prep_stage4_release_controls
  where status='active';
  v_min_stage:=private.exam_prep_timed_effective_min_stage_v1(new.attempt_kind,new.min_operational_stage::integer);
  if new.min_operational_stage is null or v_min_stage<v_required then
    raise exception 'exam_prep_stage4_paper02_min_stage_too_low required=% actual=%',v_required,coalesce(v_min_stage,0);
  end if;
  return new;
end;
$$;

revoke all on function private.exam_prep_guard_stage4_paper02_contract_release_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_guard_stage4_paper02_contract_release_v1 on private.exam_prep_timed_assessment_contracts;
create trigger exam_prep_guard_stage4_paper02_contract_release_v1
before insert or update of status,min_operational_stage,attempt_kind on private.exam_prep_timed_assessment_contracts
for each row execute function private.exam_prep_guard_stage4_paper02_contract_release_v1();

-- Deployment must be fail-closed: controls pending, Paper02 still approved/unreleased,
-- Stage4 evaluator absent, beta off, and learner runtime empty.
do $$
declare
  v_control private.exam_prep_stage4_release_controls%rowtype;
  v_p2 int;
  v_contracts int;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_control from private.exam_prep_stage4_release_controls where status='active';
  if v_control.control_version<>'stage4_paper02_release_guard_v1_2026_09_06'
     or v_control.stage4_policy_status<>'pending'
     or v_control.paper02_release_status<>'pending'
     or not v_control.require_stage3_key_registry_approved
     or v_control.min_paper02_stage<>4 then
    raise exception 'P1-03 Stage4 Paper02 release control drift';
  end if;

  select count(*) into v_p2
  from private.exam_prep_assessments
  where assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') and assessment_version='av1' and status='approved';
  if v_p2<>2 then raise exception 'P1-03 Stage4 Paper02 release guard requires both approved pre-positioned forms found=%',v_p2; end if;

  select count(*) into v_contracts
  from private.exam_prep_timed_assessment_contracts c
  join private.exam_prep_assessments a on a.id=c.assessment_id
  where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02');
  if v_contracts<>0 then raise exception 'P1-03 Stage4 Paper02 release guard requires zero Paper02 contracts found=%',v_contracts; end if;

  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null then
    raise exception 'P1-03 Stage4 Paper02 release guard must deploy before Stage4 exit policy';
  end if;
  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage4 Paper02 release guard must not move automatic stage ceiling';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage4 Paper02 release guard requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage4 Paper02 release guard active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 Stage4 Paper02 release guard must not create learner runtime evidence';
  end if;
end $$;

commit;
