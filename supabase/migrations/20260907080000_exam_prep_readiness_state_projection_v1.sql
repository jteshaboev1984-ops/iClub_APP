-- Project the deployed Stage-5 App Readiness evaluator into the existing component state row.
-- No new readiness thresholds are created; missing configuration remains fail-closed.

begin;

create or replace function private.exam_prep_apply_readiness_projection_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_ready jsonb;
  v_reason text;
begin
  if new.component_code not in ('P1','P5') then return new; end if;

  if to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is null then
    new.app_readiness_estimate:='INSUFFICIENT_EVIDENCE';
    new.app_readiness_reason:='Readiness evaluation is not available yet.';
    return new;
  end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(new.user_id,new.program_version_id,new.component_code);
  v_reason:=coalesce(v_ready->>'reason_code','insufficient_evidence');

  if coalesce((v_ready->>'ready')::boolean,false) then
    new.app_readiness_estimate:='STRONG_OBJECTIVE_EVIDENCE';
    new.app_readiness_reason:='The component has the required comparable full-paper, timing, skill-stability and corrective-closure evidence for the current configured target.';
  else
    new.app_readiness_estimate:='INSUFFICIENT_EVIDENCE';
    new.app_readiness_reason:=case v_reason
      when 'stage4_exit_incomplete' then 'Timed consolidation evidence is not complete yet.'
      when 'three_comparable_attempts_incomplete' then 'Three comparable strict full-paper attempts are required for readiness.'
      when 'threshold_configuration_pending' then 'The readiness threshold for this exam series and target grade has not been configured yet.'
      when 'objective_skill_stability_incomplete' then 'Some component skills still need stable objective evidence.'
      when 'corrective_cycles_open' then 'One or more corrective cycles still need to be closed.'
      when 'last_three_below_individual_threshold' then 'The latest three comparable papers do not all meet the configured individual threshold.'
      when 'unattempted_marks_not_minimal' then 'Unattempted marks are still above the configured readiness limit.'
      when 'after_time_dependency_not_closed' then 'Too much of the latest paper evidence still depends on work completed after time.'
      else 'More component-specific evidence is required before readiness can be confirmed.'
    end;
  end if;
  return new;
end;
$$;

revoke all on function private.exam_prep_apply_readiness_projection_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_apply_readiness_projection_v1() to service_role;

drop trigger if exists exam_prep_readiness_projection_v1 on private.exam_prep_stage_states;
create trigger exam_prep_readiness_projection_v1
before insert or update on private.exam_prep_stage_states
for each row execute function private.exam_prep_apply_readiness_projection_v1();

do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_thresholds int;
begin
  select count(*) into v_thresholds from private.exam_prep_stage5_thresholds where status='approved';
  if v_thresholds<>0 then raise exception 'Readiness projection release must not fabricate threshold rows'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then
    raise exception 'Readiness projection: Core-only canary boundary drift';
  end if;
end $$;

commit;
