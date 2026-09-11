begin;

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
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_policy private.exam_prep_ai_policy%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_ent private.exam_prep_feature_entitlements%rowtype;
  v_runtime text := 'not_deployed';
  v_active_protected boolean := false;
  v_used integer := 0;
begin
  if v_uid is null then
    raise exception 'exam_prep_ai_auth_required';
  end if;

  if p_component_code not in ('P1','P5') then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','invalid_component');
  end if;

  select * into v_policy from private.exam_prep_ai_policy where id=1;
  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','policy_missing');
  end if;

  if p_interaction_type is null or not (p_interaction_type = any(v_policy.allowed_interactions)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','interaction_not_allowed');
  end if;

  if p_requested_locale is null or not (p_requested_locale = any(v_policy.allowed_locales)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','locale_not_allowed');
  end if;

  if coalesce(p_user_text_length,0) < 0 or coalesce(p_user_text_length,0) > v_policy.max_user_text_chars then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','input_too_long','max_chars',v_policy.max_user_text_chars);
  end if;

  if p_interaction_type = 'mentor_report_draft' then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','mentor_actor_required');
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  select * into v_ent
  from private.exam_prep_feature_entitlements
  where user_id=v_uid
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  select runtime_status into v_runtime
  from private.exam_prep_optional_capability_status
  where capability_code='ai_assist';
  v_runtime := coalesce(v_runtime,'not_deployed');

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
     or v_runtime <> 'ready'
     or not v_policy.generation_enabled then
    return jsonb_build_object(
      'allowed',false,
      'mode','unavailable',
      'reason','ai_disabled',
      'runtime_status',v_runtime,
      'policy_generation_enabled',v_policy.generation_enabled
    );
  end if;

  select exists(
    select 1
    from private.exam_prep_sessions s
    where s.user_id=v_uid
      and s.component_code=p_component_code
      and s.status='active'
      and (
        s.session_type in ('diagnostic','retest','mixed','timed','paper')
        or exists(
          select 1
          from private.exam_prep_session_items si
          where si.session_id=s.id
            and coalesce(si.reserve_role,'') in ('diagnostic','retest','mixed','timed','unseen')
        )
      )
  ) into v_active_protected;

  if v_active_protected then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment');
  end if;

  select coalesce(u.request_count,0) into v_used
  from private.exam_prep_ai_daily_usage u
  where u.user_id=v_uid and u.usage_date=current_date;
  v_used := coalesce(v_used,0);

  if v_used >= v_policy.max_daily_requests then
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
$$;

revoke all on function public.get_exam_prep_ai_guard_v1(text,text,text,integer) from public, anon;
grant execute on function public.get_exam_prep_ai_guard_v1(text,text,text,integer) to authenticated, service_role;

commit;