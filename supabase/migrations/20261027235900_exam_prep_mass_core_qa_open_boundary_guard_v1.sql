-- Core mass-release decision boundary hardening (2026-10-27).
-- ADDITIVE / no learner mutations / no feature flag or enrollment changes.
-- Technical QA-open overrides are intentionally LEFT AS-IS to preserve current users.
-- The reviewer must explicitly close them using a separate governed transition.
begin;
set local lock_timeout='4s';
set local statement_timeout='30s';

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
  v_qa_access_closed boolean:=false;
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
      'mentor_scale_independent',true,
      'automatic_rollout_permitted',false,
      'learner_state_mutated',false,
      'legacy_state_mutated',false
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

  -- A QA-open environment cannot be eligible for a *mass* Core decision.
  -- This is advisory-only; do not revoke anyone's current beta access here.
  v_qa_access_closed :=
    v_cfg.id is not null
    and coalesce(v_cfg.qa_open_all_core,false)=false
    and coalesce(v_cfg.qa_open_all_weekly,false)=false;

  v_ready :=
    coalesce((v_expansion->>'ready')::boolean,false)
    and v_content_complete
    and v_p205
    and v_p206
    and v_core_security
    and v_qa_access_closed;

  v_reason:=case
    when not v_content_complete then 'product_content_complete_missing'
    when not v_p205 then 'stage5_readiness_surface_missing'
    when not v_p206 then 'stage6_final_calibration_missing'
    when not v_core_security then 'controlled_beta_core_boundary_not_green'
    when coalesce((v_expansion->>'ready')::boolean,false) is not true
      then coalesce(v_expansion->>'reason_code','expanded_beta_evidence_incomplete')
    when not v_qa_access_closed then 'temporary_qa_access_still_open'
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
    'temporary_qa_access_closed',v_qa_access_closed,
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


revoke all on function private.exam_prep_p3_01_mass_core_rollout_gate_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_p3_01_mass_core_rollout_gate_v1(text) to service_role;

do $check$
begin
  if has_function_privilege('anon','private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)','EXECUTE') then
    raise exception 'P3 Core mass-release private decision leaked to learners';
  end if;
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='private' and p.proname='exam_prep_p3_01_mass_core_rollout_gate_v1'
      and p.prosecdef and p.provolatile='s') then
    raise exception 'P3 Core mass-release authority contract missing';
  end if;
end $check$;
commit;
