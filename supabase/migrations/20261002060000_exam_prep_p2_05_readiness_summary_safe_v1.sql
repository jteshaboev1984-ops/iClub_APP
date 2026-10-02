-- P2-05: learner-safe Stage 5 App Readiness summary.
-- Keeps App Readiness separate from optional Mentor Verified readiness.
-- Does not approve a future-series threshold, create a mentor assignment, or mutate learner evidence.

begin;

create or replace function public.get_exam_prep_readiness_summary_safe_v1(
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_target_grade text;
  v_ready jsonb;
  v_reference jsonb;
  v_human jsonb;
  v_reason text;
  v_human_reason text;
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select program_version_id,target_grade
  into v_program,v_target_grade
  from private.exam_prep_exam_profiles
  where user_id=v_uid;

  if v_program is null then
    raise exception 'exam_prep_profile_required';
  end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,p_component_code);
  v_reference:=private.exam_prep_latest_threshold_reference_v1(v_program,p_component_code,v_target_grade);
  v_human:=private.exam_prep_mentor_verified_readiness_status_v1(v_uid,v_program,p_component_code);
  v_reason:=coalesce(v_ready->>'reason_code','evidence_incomplete');
  v_human_reason:=coalesce(v_human->>'reason_code','mentor_care_not_active');

  return jsonb_build_object(
    'component_code',p_component_code,
    'ready',coalesce((v_ready->>'ready')::boolean,false),
    'estimate_code',coalesce(v_ready->>'app_readiness_estimate','INSUFFICIENT_EVIDENCE'),
    'reason_code',v_reason,

    'comparable_full_attempts',coalesce((v_ready->>'last_three_count')::int,0),
    'comparable_full_required',3,
    'topics_needing_stability',coalesce((v_ready->>'below_l3_count')::int,0),
    'open_corrections',coalesce((v_ready->>'unresolved_correction_case_count')::int,0),
    'score_window_ready',coalesce((v_ready->>'score_window_ready')::boolean,false),
    'unattempted_ready',coalesce((v_ready->>'unattempted_gate_ready')::boolean,false),
    'after_time_ready',coalesce((v_ready->>'after_time_gate_ready')::boolean,false),
    'threshold_gate_configured',coalesce((v_ready->>'threshold_configured')::boolean,false),

    'latest_official_reference',case
      when coalesce((v_reference->>'available')::boolean,false)
           and coalesce((v_reference->>'reference_only')::boolean,false)
      then jsonb_build_object(
        'available',true,
        'component_code',v_reference->>'component_code',
        'paper_code',v_reference->>'paper_code',
        'exam_series',v_reference->>'exam_series',
        'target_grade',v_reference->>'target_grade',
        'raw_threshold_mark',v_reference->'raw_threshold_mark',
        'maximum_raw_mark',v_reference->'maximum_raw_mark',
        'threshold_pct',v_reference->'threshold_pct',
        'source_url',v_reference->>'source_url',
        'reference_only',true,
        'readiness_gate_active',false
      )
      else jsonb_build_object(
        'available',false,
        'component_code',p_component_code,
        'target_grade',nullif(upper(trim(coalesce(v_target_grade,''))),''),
        'reference_only',true,
        'readiness_gate_active',false
      )
    end,

    'mentor_care_active',coalesce((v_human->>'service_available')::boolean,false),
    'mentor_verified',coalesce((v_human->>'mentor_verified')::boolean,false),
    'mentor_verified_confirmed_at',v_human->'confirmed_at',
    'mentor_verification_state',case
      when coalesce((v_human->>'mentor_verified')::boolean,false) then 'verified'
      when v_human_reason='human_confirmation_pending' then 'pending'
      when v_human_reason='app_readiness_not_ready' then 'not_ready'
      else 'not_active'
    end,

    'next_action_code',case v_reason
      when 'stage4_exit_incomplete' then 'complete_timed_consolidation'
      when 'three_comparable_attempts_incomplete' then 'complete_full_papers'
      when 'threshold_configuration_pending' then 'continue_exam_practice'
      when 'objective_skill_stability_incomplete' then 'strengthen_topics'
      when 'corrective_cycles_open' then 'close_corrections'
      when 'last_three_below_individual_threshold' then 'improve_full_paper_results'
      when 'unattempted_marks_not_minimal' then 'reduce_unattempted'
      when 'after_time_dependency_not_closed' then 'finish_within_time'
      when 'ready' then 'continue_final_calibration'
      else 'continue_evidence'
    end,

    'not_official_cambridge_grade',true,
    'mentor_verification_optional_for_core',true,
    'p1_p5_separate',true
  );
end;
$$;

revoke all on function public.get_exam_prep_readiness_summary_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_readiness_summary_safe_v1(text) to authenticated,service_role;

do $$
declare
  v_rules int;
  v_approved_thresholds int;
  v_refs int;
  v_rls boolean;
  v_def text;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  if to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_mentor_verified_readiness_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_latest_threshold_reference_v1(bigint,text,text)') is null
     or to_regprocedure('public.get_exam_prep_readiness_summary_safe_v1(text)') is null then
    raise exception 'P2-05 readiness dependency missing';
  end if;

  select count(*) into v_rules
  from private.exam_prep_stage5_readiness_rules
  where status='active'
    and min_comparable_full_attempts=3
    and require_stage4_exit
    and require_all_skills_l3
    and require_all_corrections_closed
    and require_last_three_above_threshold;
  if v_rules<>1 then
    raise exception 'P2-05 active Stage-5 readiness rule mismatch=%',v_rules;
  end if;

  -- Future-series readiness must stay fail-closed until a separately governed
  -- target/series-aware readiness threshold is approved. Historical Cambridge
  -- threshold references are learner context only and cannot be promoted here.
  select count(*) into v_approved_thresholds
  from private.exam_prep_stage5_thresholds
  where status='approved';
  if v_approved_thresholds<>0 then
    raise exception 'P2-05 this release must not approve or silently adopt Stage-5 thresholds=%',v_approved_thresholds;
  end if;

  select count(*) into v_refs
  from private.exam_prep_threshold_references
  where status='active';
  if v_refs<>10 then
    raise exception 'P2-05 expected ten current reference-only P1/P5 grade rows, got %',v_refs;
  end if;

  select c.relrowsecurity into v_rls
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='private' and c.relname='exam_prep_readiness_signoffs';
  if not coalesce(v_rls,false) then
    raise exception 'P2-05 readiness signoff RLS missing';
  end if;

  select pg_get_functiondef('private.exam_prep_materialize_readiness_signoff_v1()'::regprocedure)
  into v_def;
  if position('exam_prep_second_check_must_be_independent' in v_def)=0
     or position('exam_prep_readiness_evidence_changed' in v_def)=0
     or position('lead_mentor' in v_def)=0
     or position('academic_moderator' in v_def)=0 then
    raise exception 'P2-05 independent second-check/stale-evidence guard missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_readiness_summary_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_readiness_summary_safe_v1(text)','EXECUTE') then
    raise exception 'P2-05 readiness summary RPC privilege boundary drift';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'controlled_beta'
     or not v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or v_cfg.kill_switch then
    raise exception 'P2-05 Core-only controlled-beta boundary drift';
  end if;
end
$$;

commit;
