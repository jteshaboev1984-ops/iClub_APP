-- P1-03 Stage-5 Paper03 release guard.
-- Fail-closed governance lock only. Does NOT approve Stage 5, publish Paper03,
-- move learner stages, enable beta, or create learner evidence.
begin;

create table if not exists private.exam_prep_stage5_release_controls (
  control_version text primary key,
  status text not null check(status in ('draft','active','retired')),
  stage5_policy_status text not null default 'pending' check(stage5_policy_status in ('pending','approved','retired')),
  paper03_release_status text not null default 'pending' check(paper03_release_status in ('pending','approved','retired')),
  require_stage4_control_approved boolean not null default true,
  require_stage3_key_registry_approved boolean not null default true,
  require_stage5_readiness_evaluator boolean not null default true,
  min_paper03_stage smallint not null default 5 check(min_paper03_stage=5),
  source_note text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists exam_prep_stage5_release_controls_one_active_idx
  on private.exam_prep_stage5_release_controls((status)) where status='active';

insert into private.exam_prep_stage5_release_controls(
  control_version,status,stage5_policy_status,paper03_release_status,
  require_stage4_control_approved,require_stage3_key_registry_approved,
  require_stage5_readiness_evaluator,min_paper03_stage,source_note
) values (
  'stage5_paper03_release_guard_v1_2026_09_06','active','pending','pending',true,true,true,5,
  'Fail-closed pre-live release control. Paper03 remains unreleased until Stage-5 policy is explicitly approved, Stage-4 governance is approved/deployed, Stage-3 key registry is approved/non-empty per component, Stage-5 readiness evaluator exists, and the timed contract minimum operational stage is 5.'
)
on conflict(control_version) do update set
  status=excluded.status,
  stage5_policy_status=excluded.stage5_policy_status,
  paper03_release_status=excluded.paper03_release_status,
  require_stage4_control_approved=excluded.require_stage4_control_approved,
  require_stage3_key_registry_approved=excluded.require_stage3_key_registry_approved,
  require_stage5_readiness_evaluator=excluded.require_stage5_readiness_evaluator,
  min_paper03_stage=excluded.min_paper03_stage,
  source_note=excluded.source_note,
  updated_at=now();

create or replace function private.exam_prep_stage5_paper03_release_readiness_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_control private.exam_prep_stage5_release_controls%rowtype;
  v_stage4 private.exam_prep_stage4_release_controls%rowtype;
  v_stage3 private.exam_prep_stage3_exit_rules%rowtype;
  v_program bigint;
  v_key_count int:=0;
  v_assessment_id bigint;
  v_assessment_status text;
  v_contract_count int:=0;
  v_stage4_eval boolean:=false;
  v_stage5_raw boolean:=false;
  v_stage5_eval boolean:=false;
  v_override boolean:=false;
  v_ready boolean:=false;
  v_reason text:='control_missing';
  v_key text;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  v_key:=case p_component_code when 'P1' then 'p1_stage4_full_paper_03' else 'p5_stage4_full_paper_03' end;

  select * into v_control from private.exam_prep_stage5_release_controls where status='active' order by created_at desc limit 1;
  select * into v_stage4 from private.exam_prep_stage4_release_controls where status='active' order by created_at desc limit 1;
  select * into v_stage3 from private.exam_prep_stage3_exit_rules where status='active' order by created_at desc limit 1;
  select id into v_program from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';

  if v_stage3.rule_version is not null and v_program is not null then
    select count(*) into v_key_count from private.exam_prep_stage3_key_skills
      where rule_version=v_stage3.rule_version and program_version_id=v_program and component_code=p_component_code;
  end if;

  select id,status into v_assessment_id,v_assessment_status
  from private.exam_prep_assessments
  where assessment_key=v_key and assessment_version='av1'
  order by id desc limit 1;
  if v_assessment_id is not null then
    select count(*) into v_contract_count from private.exam_prep_timed_assessment_contracts where assessment_id=v_assessment_id;
  end if;

  v_stage4_eval:=to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null;
  v_stage5_raw:=to_regprocedure('private.exam_prep_stage5_raw_readiness_v1(uuid,bigint,text)') is not null;
  v_stage5_eval:=to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is not null;
  v_override:=to_regprocedure('private.exam_prep_timed_effective_min_stage_v1(text,integer)') is not null;

  if v_control.control_version is null then v_reason:='control_missing';
  elsif v_control.stage5_policy_status<>'approved' then v_reason:='stage5_policy_pending';
  elsif v_control.paper03_release_status<>'approved' then v_reason:='paper03_release_pending';
  elsif v_control.require_stage4_control_approved and (v_stage4.control_version is null or v_stage4.stage4_policy_status<>'approved' or v_stage4.paper02_release_status<>'approved') then v_reason:='stage4_governance_incomplete';
  elsif v_control.require_stage3_key_registry_approved and (v_stage3.rule_version is null or v_stage3.key_registry_status<>'approved') then v_reason:='stage3_key_registry_pending';
  elsif v_control.require_stage3_key_registry_approved and v_key_count=0 then v_reason:='stage3_key_registry_empty';
  elsif not v_stage4_eval then v_reason:='stage4_exit_evaluator_missing';
  elsif not v_stage5_raw then v_reason:='stage5_raw_reader_missing';
  elsif v_control.require_stage5_readiness_evaluator and not v_stage5_eval then v_reason:='stage5_readiness_evaluator_missing';
  elsif not v_override then v_reason:='stage_override_hardening_missing';
  elsif v_assessment_id is null then v_reason:='paper03_missing';
  elsif v_assessment_status='published' or v_contract_count>0 then v_reason:='paper03_already_released';
  elsif v_assessment_status<>'approved' then v_reason:='paper03_not_approved';
  else v_reason:='ready'; v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,'reason_code',v_reason,'component_code',p_component_code,
    'control_version',v_control.control_version,'stage5_policy_status',v_control.stage5_policy_status,
    'paper03_release_status',v_control.paper03_release_status,
    'stage4_policy_status',v_stage4.stage4_policy_status,'paper02_release_status',v_stage4.paper02_release_status,
    'stage3_key_registry_status',v_stage3.key_registry_status,'stage3_key_count',v_key_count,
    'stage4_exit_evaluator_deployed',v_stage4_eval,'stage5_raw_reader_deployed',v_stage5_raw,
    'stage5_readiness_evaluator_deployed',v_stage5_eval,'stage_override_hardening_deployed',v_override,
    'paper03_assessment_id',v_assessment_id,'paper03_assessment_status',v_assessment_status,
    'paper03_contract_count',v_contract_count,'required_min_stage',v_control.min_paper03_stage,
    'paper03_release_allowed',v_ready
  );
end;
$$;
revoke all on function private.exam_prep_stage5_paper03_release_readiness_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage5_paper03_release_readiness_v1(text) to service_role;

create or replace function private.exam_prep_assert_stage5_paper03_release_governance_v1(p_component_code text)
returns void
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_status jsonb;
begin
  v_status:=private.exam_prep_stage5_paper03_release_readiness_v1(p_component_code);
  if not coalesce((v_status->>'ready')::boolean,false) then
    raise exception 'exam_prep_stage5_paper03_release_blocked:%',v_status->>'reason_code';
  end if;
end;
$$;
revoke all on function private.exam_prep_assert_stage5_paper03_release_governance_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_assert_stage5_paper03_release_governance_v1(text) to service_role;

create or replace function private.exam_prep_guard_stage5_paper03_assessment_release_v1()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.assessment_key in ('p1_stage4_full_paper_03','p5_stage4_full_paper_03') and new.status='published' then
    perform private.exam_prep_assert_stage5_paper03_release_governance_v1(new.component_code);
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_guard_stage5_paper03_assessment_release_v1() from public,anon,authenticated;
drop trigger if exists exam_prep_guard_stage5_paper03_assessment_release_v1 on private.exam_prep_assessments;
create trigger exam_prep_guard_stage5_paper03_assessment_release_v1
before insert or update of status on private.exam_prep_assessments
for each row execute function private.exam_prep_guard_stage5_paper03_assessment_release_v1();

create or replace function private.exam_prep_guard_stage5_paper03_contract_release_v1()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_key text; v_component text; v_required smallint; v_effective smallint;
begin
  if new.status<>'published' then return new; end if;
  select assessment_key,component_code into v_key,v_component from private.exam_prep_assessments where id=new.assessment_id;
  if v_key not in ('p1_stage4_full_paper_03','p5_stage4_full_paper_03') then return new; end if;
  perform private.exam_prep_assert_stage5_paper03_release_governance_v1(v_component);
  select min_paper03_stage into v_required from private.exam_prep_stage5_release_controls where status='active';
  v_effective:=private.exam_prep_timed_effective_min_stage_v1(new.attempt_kind,new.min_operational_stage::integer);
  if new.min_operational_stage is null or v_effective<v_required then
    raise exception 'exam_prep_stage5_paper03_min_stage_too_low required=% actual=%',v_required,coalesce(v_effective,0);
  end if;
  return new;
end;
$$;
revoke all on function private.exam_prep_guard_stage5_paper03_contract_release_v1() from public,anon,authenticated;
drop trigger if exists exam_prep_guard_stage5_paper03_contract_release_v1 on private.exam_prep_timed_assessment_contracts;
create trigger exam_prep_guard_stage5_paper03_contract_release_v1
before insert or update of status,min_operational_stage,attempt_kind on private.exam_prep_timed_assessment_contracts
for each row execute function private.exam_prep_guard_stage5_paper03_contract_release_v1();

-- Deployment boundary: Stage 5 stays locked and Paper03 stays unreleased.
do $$
declare v_c private.exam_prep_stage5_release_controls%rowtype; v_forms int; v_contracts int; v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select * into v_c from private.exam_prep_stage5_release_controls where status='active';
  if v_c.stage5_policy_status<>'pending' or v_c.paper03_release_status<>'pending' or v_c.min_paper03_stage<>5 then raise exception 'P1-03 Stage5 Paper03 release control drift'; end if;
  select count(*) into v_forms from private.exam_prep_assessments where assessment_key in ('p1_stage4_full_paper_03','p5_stage4_full_paper_03') and assessment_version='av1' and status='approved';
  if v_forms<>2 then raise exception 'P1-03 Stage5 Paper03 guard requires both approved forms found=%',v_forms; end if;
  select count(*) into v_contracts from private.exam_prep_timed_assessment_contracts c join private.exam_prep_assessments a on a.id=c.assessment_id where a.assessment_key in ('p1_stage4_full_paper_03','p5_stage4_full_paper_03');
  if v_contracts<>0 then raise exception 'P1-03 Stage5 Paper03 guard requires zero Paper03 contracts found=%',v_contracts; end if;
  if to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is not null then raise exception 'P1-03 Stage5 Paper03 guard must deploy before Stage5 readiness policy'; end if;
  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then raise exception 'P1-03 Stage5 Paper03 guard must not move stage ceiling'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then raise exception 'P1-03 Stage5 Paper03 guard requires fail-closed feature state'; end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage5 Paper03 guard active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions) or exists(select 1 from private.exam_prep_evidence_events) or exists(select 1 from private.exam_prep_timed_attempt_results) then raise exception 'P1-03 Stage5 Paper03 guard must not create learner runtime evidence'; end if;
end $$;

commit;
