-- Global iClub AI -> governed Mathematics provider adapter v1.
-- Adds one skill-scoped free-form interaction to the EXISTING Exam Prep AI provider.
-- This remains controlled by Global AI rollout/runtime + commercial generation entitlement.
-- No learner academic state is written or recalculated.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

update private.exam_prep_ai_policy
set allowed_interactions = case
      when 'skill_question'=any(allowed_interactions) then allowed_interactions
      else array_append(allowed_interactions,'skill_question')
    end,
    policy_version='exam_prep_ai_policy_v1_3_global_skill_question',
    prompt_version='exam_prep_ai_prompt_v1_3_global_skill_question',
    response_schema_version='exam_prep_ai_response_v1_2_global_skill_question',
    updated_at=now()
where id=1;

create or replace function public.get_exam_prep_ai_guard_v1(
  p_component_code text,
  p_interaction_type text,
  p_requested_locale text,
  p_user_text_length integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $guard$
declare
  v_uid uuid:=auth.uid();
  v_policy private.exam_prep_ai_policy%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_ent private.exam_prep_feature_entitlements%rowtype;
  v_runtime text:='not_deployed';
  v_used integer:=0;
  v_global_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_global_caps jsonb;
begin
  if v_uid is null then
    raise exception 'exam_prep_ai_auth_required';
  end if;

  if p_component_code not in ('P1','P5') then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','invalid_component');
  end if;

  select * into v_policy
  from private.exam_prep_ai_policy
  where id=1;

  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','policy_missing');
  end if;

  if p_interaction_type is null
     or not (p_interaction_type=any(v_policy.allowed_interactions)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','interaction_not_allowed');
  end if;

  if p_requested_locale is null
     or not (p_requested_locale=any(v_policy.allowed_locales)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','locale_not_allowed');
  end if;

  if coalesce(p_user_text_length,0)<0
     or coalesce(p_user_text_length,0)>v_policy.max_user_text_chars then
    return jsonb_build_object(
      'allowed',false,'mode','blocked','reason','input_too_long',
      'max_chars',v_policy.max_user_text_chars
    );
  end if;

  if p_interaction_type='mentor_report_draft' then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','mentor_actor_required');
  end if;

  select * into v_cfg
  from private.exam_prep_feature_config
  where id=1;

  select runtime_status into v_runtime
  from private.exam_prep_optional_capability_status
  where capability_code='ai_assist';
  v_runtime:=coalesce(v_runtime,'not_deployed');

  -- Global free-form skill questions are authorized by the commercial Global AI
  -- capability, not by the legacy per-user Exam Prep AI entitlement. This keeps
  -- the provider reusable for future Plus/Pro users without weakening any other
  -- existing Exam Prep AI interaction.
  if p_interaction_type='skill_question' then
    select * into v_global_runtime
    from private.iclub_global_ai_runtime_config
    where id=1;

    if not found
       or v_global_runtime.kill_switch
       or not v_global_runtime.gateway_enabled
       or not v_global_runtime.generation_enabled then
      return jsonb_build_object(
        'allowed',false,'mode','unavailable','reason','global_generation_disabled'
      );
    end if;

    if not private.iclub_rollout_allows_user_v1(
      v_uid,v_global_runtime.global_ai_rollout_mode
    ) then
      return jsonb_build_object(
        'allowed',false,'mode','unavailable','reason','rollout_unavailable'
      );
    end if;

    v_global_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);

    if coalesce((v_global_caps->>'resolved')::boolean,false) is not true
       or coalesce((v_global_caps->>'ai_generation_entitled')::boolean,false) is not true then
      return jsonb_build_object(
        'allowed',false,'mode','unavailable','reason','generation_upgrade_required'
      );
    end if;

    if v_cfg.id is null
       or v_cfg.kill_switch
       or v_cfg.rollout_state='off'
       or not v_cfg.core_enabled
       or not v_cfg.ai_enabled
       or v_runtime<>'ready'
       or not v_policy.generation_enabled then
      return jsonb_build_object(
        'allowed',false,
        'mode','unavailable',
        'reason','ai_disabled',
        'runtime_status',v_runtime,
        'policy_generation_enabled',v_policy.generation_enabled
      );
    end if;

    if private.exam_prep_has_active_protected_assessment_v1(v_uid) then
      return jsonb_build_object(
        'allowed',false,'mode','blocked','reason','active_assessment'
      );
    end if;

    select coalesce(u.request_count,0) into v_used
    from private.exam_prep_ai_daily_usage u
    where u.user_id=v_uid
      and u.usage_date=current_date;
    v_used:=coalesce(v_used,0);

    if v_used>=v_policy.max_daily_requests then
      return jsonb_build_object(
        'allowed',false,'mode','fallback','reason','daily_budget_exhausted'
      );
    end if;

    return jsonb_build_object(
      'allowed',true,
      'mode','ready',
      'component_code',p_component_code,
      'interaction_type',p_interaction_type,
      'requested_locale',p_requested_locale,
      'policy_version',v_policy.policy_version,
      'prompt_version',v_policy.prompt_version,
      'retrieval_policy_version',v_policy.retrieval_policy_version,
      'response_schema_version',v_policy.response_schema_version,
      'max_output_chars',v_policy.max_output_chars,
      'model_timeout_ms',v_policy.model_timeout_ms,
      'authorization_source','global_commercial_ai'
    );
  end if;

  -- Existing Exam Prep interactions keep their original independent entitlement.
  select * into v_ent
  from private.exam_prep_feature_entitlements
  where user_id=v_uid
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  if v_cfg.id is null
     or v_cfg.kill_switch
     or v_cfg.rollout_state='off'
     or not v_cfg.core_enabled
     or v_ent.user_id is null
     or not coalesce(v_ent.core_access,false) then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','core_not_available');
  end if;

  if not v_cfg.ai_enabled
     or not coalesce(v_ent.ai_assist,false)
     or v_runtime<>'ready'
     or not v_policy.generation_enabled then
    return jsonb_build_object(
      'allowed',false,
      'mode','unavailable',
      'reason','ai_disabled',
      'runtime_status',v_runtime,
      'policy_generation_enabled',v_policy.generation_enabled
    );
  end if;

  if private.exam_prep_has_active_protected_assessment_v1(v_uid) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment');
  end if;

  select coalesce(u.request_count,0) into v_used
  from private.exam_prep_ai_daily_usage u
  where u.user_id=v_uid
    and u.usage_date=current_date;
  v_used:=coalesce(v_used,0);

  if v_used>=v_policy.max_daily_requests then
    return jsonb_build_object('allowed',false,'mode','fallback','reason','daily_budget_exhausted');
  end if;

  return jsonb_build_object(
    'allowed',true,
    'mode','ready',
    'component_code',p_component_code,
    'interaction_type',p_interaction_type,
    'requested_locale',p_requested_locale,
    'policy_version',v_policy.policy_version,
    'prompt_version',v_policy.prompt_version,
    'retrieval_policy_version',v_policy.retrieval_policy_version,
    'response_schema_version',v_policy.response_schema_version,
    'max_output_chars',v_policy.max_output_chars,
    'model_timeout_ms',v_policy.model_timeout_ms
  );
end;
$guard$;

revoke all on function public.get_exam_prep_ai_guard_v1(text,text,text,integer)
  from public,anon;
grant execute on function public.get_exam_prep_ai_guard_v1(text,text,text,integer)
  to authenticated,service_role;

do $postcheck$
declare
  v_policy private.exam_prep_ai_policy%rowtype;
begin
  select * into v_policy
  from private.exam_prep_ai_policy
  where id=1;

  if not found
     or not ('skill_question'=any(v_policy.allowed_interactions)) then
    raise exception 'global_math_skill_question_policy_missing';
  end if;

  if to_regprocedure('private.iclub_rollout_allows_user_v1(uuid,text)') is null
     or to_regprocedure('public.get_iclub_subscription_capabilities_service_v1(uuid)') is null
     or to_regprocedure('private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)') is null then
    raise exception 'global_math_skill_question_dependency_missing';
  end if;
end
$postcheck$;

commit;
