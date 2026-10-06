-- iClub Global AI generated Mathematics adapter v1.
-- Additive and dormant by default. No runtime flags are enabled here.
--
-- Reuses the already-governed Exam Prep provider budget pool through Global AI
-- wrappers so Math provider spend/concurrency cannot bypass the existing safety ceiling.
-- The Global gateway still owns tariff usage accounting separately.

begin;

alter table private.iclub_global_ai_gateway_audit
  add column if not exists source_card_keys text[] not null default '{}'::text[],
  add column if not exists safety_flags text[] not null default '{}'::text[],
  add column if not exists model_provider text null,
  add column if not exists model_id text null,
  add column if not exists input_tokens integer null
    check (input_tokens is null or input_tokens>=0),
  add column if not exists output_tokens integer null
    check (output_tokens is null or output_tokens>=0),
  add column if not exists estimated_cost_usd numeric(12,6) null
    check (estimated_cost_usd is null or estimated_cost_usd>=0);

create or replace function public.reserve_iclub_global_ai_provider_call_service_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_subject_key text,
  p_scope_code text,
  p_adapter_code text,
  p_estimated_cost_usd numeric
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $reserve$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_readiness private.iclub_ai_subject_readiness%rowtype;
  v_caps jsonb;
begin
  if p_request_id is null or p_user_id is null then
    return jsonb_build_object('allowed',false,'reason','invalid_reservation_identity');
  end if;

  if p_estimated_cost_usd is null or p_estimated_cost_usd<=0 then
    return jsonb_build_object('allowed',false,'reason','invalid_estimated_cost');
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or v_runtime.kill_switch
     or not v_runtime.gateway_enabled
     or not v_runtime.generation_enabled then
    return jsonb_build_object('allowed',false,'reason','generation_disabled');
  end if;

  if not private.iclub_rollout_allows_user_v1(
    p_user_id,v_runtime.global_ai_rollout_mode
  ) then
    return jsonb_build_object('allowed',false,'reason','rollout_unavailable');
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'allowed',false,
      'reason',coalesce(v_caps->>'reason','subscription_unavailable')
    );
  end if;

  if coalesce((v_caps->>'ai_generation_entitled')::boolean,false) is not true then
    return jsonb_build_object('allowed',false,'reason','generation_upgrade_required');
  end if;

  -- Defense in depth: no provider lease exists while a protected assessment is active.
  if private.iclub_ai_has_active_protected_assessment_v1(p_user_id) then
    return jsonb_build_object('allowed',false,'reason','active_assessment');
  end if;

  select * into v_readiness
  from private.iclub_ai_subject_readiness
  where subject_key=p_subject_key
    and scope_code=p_scope_code;

  if not found
     or v_readiness.readiness<>'full'
     or not v_readiness.generation_allowed
     or coalesce(v_readiness.adapter_code,'')<>coalesce(p_adapter_code,'') then
    return jsonb_build_object('allowed',false,'reason','subject_generation_not_ready');
  end if;

  -- v1 generated route is deliberately limited to the existing governed
  -- Mathematics Exam Prep adapter. Future subjects require their own reviewed adapter.
  if p_subject_key<>'mathematics'
     or p_scope_code<>'exam_prep'
     or p_adapter_code<>'math_exam_prep_v1' then
    return jsonb_build_object('allowed',false,'reason','generation_adapter_not_promoted');
  end if;

  return public.reserve_exam_prep_ai_provider_call_service_v1(
    p_request_id,p_user_id,p_estimated_cost_usd
  );
end;
$reserve$;

revoke all on function public.reserve_iclub_global_ai_provider_call_service_v1(
  uuid,uuid,text,text,text,numeric
) from public,anon,authenticated;
grant execute on function public.reserve_iclub_global_ai_provider_call_service_v1(
  uuid,uuid,text,text,text,numeric
) to service_role;

create or replace function public.finalize_iclub_global_ai_provider_call_service_v1(
  p_request_id uuid,
  p_status text,
  p_actual_cost_usd numeric default 0
)
returns jsonb
language sql
volatile
security definer
set search_path=''
as $finalize$
  select public.finalize_exam_prep_ai_provider_call_service_v1(
    p_request_id,
    case when p_status='completed' then 'completed' else 'released' end,
    greatest(coalesce(p_actual_cost_usd,0),0)
  );
$finalize$;

revoke all on function public.finalize_iclub_global_ai_provider_call_service_v1(
  uuid,text,numeric
) from public,anon,authenticated;
grant execute on function public.finalize_iclub_global_ai_provider_call_service_v1(
  uuid,text,numeric
) to service_role;

create or replace function public.record_iclub_global_ai_gateway_audit_service_v2(
  p_request_id uuid,
  p_user_id uuid,
  p_subject_key text,
  p_scope_code text,
  p_interaction_type text,
  p_route_class text,
  p_mode text,
  p_reason text,
  p_adapter_code text,
  p_policy_version text,
  p_latency_ms integer,
  p_output_hash text default null,
  p_source_card_keys text[] default '{}'::text[],
  p_safety_flags text[] default '{}'::text[],
  p_model_provider text default null,
  p_model_id text default null,
  p_input_tokens integer default null,
  p_output_tokens integer default null,
  p_estimated_cost_usd numeric default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path=''
as $audit$
declare
  v_inserted uuid;
begin
  if p_request_id is null
     or p_subject_key is null
     or p_scope_code is null
     or p_interaction_type is null
     or p_policy_version is null then
    return false;
  end if;

  if p_route_class is not null and p_route_class not in ('prepared','generated') then
    return false;
  end if;

  if p_mode not in ('prepared','generated','blocked','unavailable','no_source','failed') then
    return false;
  end if;

  insert into private.iclub_global_ai_gateway_audit(
    request_id,user_id,subject_key,scope_code,interaction_type,route_class,
    mode,reason,adapter_code,policy_version,latency_ms,output_hash,
    source_card_keys,safety_flags,model_provider,model_id,input_tokens,
    output_tokens,estimated_cost_usd
  ) values (
    p_request_id,p_user_id,p_subject_key,p_scope_code,p_interaction_type,p_route_class,
    p_mode,p_reason,p_adapter_code,p_policy_version,
    case when p_latency_ms is null then null else greatest(0,p_latency_ms) end,
    p_output_hash,
    coalesce(p_source_card_keys,'{}'::text[]),
    coalesce(p_safety_flags,'{}'::text[]),
    p_model_provider,p_model_id,
    case when p_input_tokens is null then null else greatest(0,p_input_tokens) end,
    case when p_output_tokens is null then null else greatest(0,p_output_tokens) end,
    case when p_estimated_cost_usd is null then null else greatest(0,p_estimated_cost_usd) end
  )
  on conflict(request_id) do nothing
  returning request_id into v_inserted;

  return v_inserted is not null;
end;
$audit$;

revoke all on function public.record_iclub_global_ai_gateway_audit_service_v2(
  uuid,uuid,text,text,text,text,text,text,text,text,integer,text,text[],text[],text,text,integer,integer,numeric
) from public,anon,authenticated;
grant execute on function public.record_iclub_global_ai_gateway_audit_service_v2(
  uuid,uuid,text,text,text,text,text,text,text,text,integer,text,text[],text[],text,text,integer,integer,numeric
) to service_role;

commit;
