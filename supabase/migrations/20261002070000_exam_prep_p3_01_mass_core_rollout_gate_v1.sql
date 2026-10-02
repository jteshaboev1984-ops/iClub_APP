-- P3-01 Mass Core rollout decision gate v1.
-- READ-ONLY DECISION TOOLING ONLY.
-- This migration does NOT expand entitlement scope, does NOT change rollout_state,
-- and does NOT enable AI Assist or Mentor Care.
--
-- P3-01 requires expanded-beta evidence. Product Content-Complete alone is insufficient.

begin;

create or replace function private.exam_prep_p3_01_mass_core_rollout_gate_v1(
  p_cohort_key text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_expansion jsonb;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_cohort private.exam_prep_beta_cohorts%rowtype;
  v_content_complete boolean:=false;
  v_p205 boolean:=false;
  v_p206 boolean:=false;
  v_core_security boolean:=false;
  v_ready boolean:=false;
  v_reason text;
begin
  if nullif(btrim(p_cohort_key),'') is null then
    raise exception 'exam_prep_p3_01_cohort_key_required';
  end if;

  select * into v_cohort
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key;

  if v_cohort.id is null then
    return jsonb_build_object(
      'ready',false,
      'decision','NO_GO',
      'reason_code','cohort_not_found',
      'cohort_key',p_cohort_key,
      'core_only_decision',true,
      'ai_scale_independent',true,
      'mentor_scale_independent',true
    );
  end if;

  v_expansion:=private.exam_prep_beta_expansion_gate_v1(p_cohort_key);

  select exists(
    select 1
    from private.exam_prep_product_roadmap_milestones
    where milestone_key='product_content_complete'
      and milestone_kind='product_content_complete'
      and product_label='Product Content-Complete'
      and milestone_status='met'
      and can_force_learner_stage=false
      and can_raise_learner_mastery=false
      and can_label_learner_exam_ready=false
  ) into v_content_complete;

  v_p205:=to_regprocedure('public.get_exam_prep_readiness_summary_safe_v1(text)') is not null;
  v_p206:=to_regprocedure('public.get_exam_prep_final_calibration_safe_v1(text)') is not null;

  select * into v_cfg
  from private.exam_prep_feature_config
  where id=1;

  v_core_security :=
    v_cfg.id is not null
    and v_cfg.rollout_state='controlled_beta'
    and v_cfg.core_enabled
    and not v_cfg.kill_switch;

  v_ready :=
    coalesce((v_expansion->>'ready')::boolean,false)
    and v_content_complete
    and v_p205
    and v_p206
    and v_core_security;

  v_reason:=case
    when not v_content_complete then 'product_content_complete_missing'
    when not v_p205 then 'stage5_readiness_surface_missing'
    when not v_p206 then 'stage6_final_calibration_missing'
    when not v_core_security then 'controlled_beta_core_boundary_not_green'
    when coalesce((v_expansion->>'ready')::boolean,false) is not true
      then coalesce(v_expansion->>'reason_code','expanded_beta_evidence_incomplete')
    else 'ready'
  end;

  return jsonb_build_object(
    'ready',v_ready,
    'decision',case when v_ready then 'ELIGIBLE_FOR_EXPLICIT_MASS_CORE_DECISION' else 'NO_GO' end,
    'reason_code',v_reason,
    'cohort_key',p_cohort_key,
    'cohort_status',v_cohort.cohort_status,
    'current_wave',v_cohort.current_wave,
    'planned_size',v_cohort.planned_size,
    'product_content_complete',v_content_complete,
    'stage5_readiness_surface_present',v_p205,
    'stage6_final_calibration_present',v_p206,
    'controlled_beta_core_boundary_green',v_core_security,
    'expanded_beta_gate',v_expansion,
    'core_only_decision',true,
    'ai_scale_independent',true,
    'mentor_scale_independent',true,
    'automatic_rollout_permitted',false,
    'learner_state_mutated',false,
    'legacy_state_mutated',false
  );
end;
$$;

revoke all on function private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)
  to service_role;

do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  if to_regprocedure('private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)') is null then
    raise exception 'P3-01 mass Core rollout gate missing';
  end if;

  if has_function_privilege('anon','private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)','EXECUTE')
  then
    raise exception 'P3-01 rollout decision gate exposed to learner roles';
  end if;

  select * into v_cfg
  from private.exam_prep_feature_config
  where id=1;

  if v_cfg.rollout_state<>'controlled_beta'
     or not v_cfg.core_enabled
     or v_cfg.kill_switch then
    raise exception 'P3-01 migration must not change current controlled-beta Core boundary';
  end if;
end
$$;

commit;
