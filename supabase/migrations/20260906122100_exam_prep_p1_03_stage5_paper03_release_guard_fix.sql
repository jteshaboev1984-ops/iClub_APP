-- Fix Stage-5 Paper03 release readiness sequencing.
-- A published assessment is an expected intermediate state before the first timed contract.
-- A pre-existing timed contract still means the form has already been released.
begin;

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
  elsif v_contract_count>0 then v_reason:='paper03_already_released';
  elsif v_assessment_status not in ('approved','published') then v_reason:='paper03_not_releaseable';
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

commit;
