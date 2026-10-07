-- Safe pre-activation reversion for iClub subscription/access lifecycle v1.
-- Refuses to remove lifecycle/access contracts after any commercial state was used.

begin;

do $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_count integer;
begin
  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if found and (
    v_cfg.lifecycle_enabled
    or v_cfg.subject_limits_mode<>'off'
    or v_cfg.grandfather_snapshot_completed_at is not null
  ) then
    raise exception 'Subscription/access reversion refused: commercial access config is not dormant';
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if found and (
    v_runtime.global_ai_rollout_mode<>'off'
    or v_runtime.plans_rollout_mode<>'off'
  ) then
    raise exception 'Subscription/access reversion refused: canary/public rollout is active';
  end if;

  select
    (select count(*) from private.iclub_subscription_events)
    + (select count(*) from private.iclub_commercial_migration_state)
    + (select count(*) from private.iclub_legacy_subject_snapshot)
    + (select count(*) from private.iclub_subject_slot_selections)
    + (select count(*) from private.iclub_subject_slot_events)
    + (select count(*) from private.iclub_product_canary_users)
  into v_count;

  if v_count<>0 then
    raise exception 'Subscription/access reversion refused: commercial lifecycle rows exist=%',v_count;
  end if;
end
$$;

drop function if exists public.set_iclub_product_canary_service_v1(uuid,boolean,text,text);
drop function if exists private.iclub_rollout_allows_user_v1(uuid,text);
drop function if exists private.iclub_is_product_canary_v1(uuid);

-- Drop the trigger dependency before removing its function.
drop trigger if exists trg_iclub_product_canary_limit_v1
  on private.iclub_product_canary_users;
drop function if exists private.iclub_product_canary_limit_v1();

drop function if exists public.finalize_iclub_subject_selection_service_v1(uuid,text);
drop function if exists public.set_iclub_subject_slot_service_v1(uuid,uuid,text,boolean,boolean,text);
drop function if exists public.get_iclub_subject_access_guard_service_v1(uuid,text,text);
drop function if exists public.capture_iclub_legacy_access_baseline_service_v1(text);
drop function if exists public.get_iclub_my_subscription_status_v1();
drop function if exists public.apply_iclub_subscription_event_service_v1(
  uuid,uuid,text,text,timestamptz,timestamptz,timestamptz,text
);

drop table if exists private.iclub_product_canary_users;
drop table if exists private.iclub_subject_slot_events;
drop table if exists private.iclub_subject_slot_selections;
drop table if exists private.iclub_legacy_subject_snapshot;
drop table if exists private.iclub_commercial_migration_state;
drop table if exists private.iclub_commercial_access_config;
drop table if exists private.iclub_subscription_events;

alter table private.iclub_global_ai_runtime_config
  drop column if exists plans_rollout_mode,
  drop column if exists global_ai_rollout_mode;

alter table private.iclub_subscription_entitlements
  drop constraint if exists iclub_subscription_scheduled_change_check,
  drop constraint if exists iclub_subscription_period_order_check,
  drop column if exists last_event_id,
  drop column if exists scheduled_change_at,
  drop column if exists scheduled_plan_code,
  drop column if exists cancel_at_period_end,
  drop column if exists current_period_end,
  drop column if exists current_period_start;


-- Restore parent-branch capability/UI contracts after removing lifecycle rollout state.

create or replace function public.get_iclub_subscription_capabilities_service_v1(
  p_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $caps$
declare
  v_ent private.iclub_subscription_entitlements%rowtype;
  v_plan private.iclub_plan_policies%rowtype;
begin
  if p_user_id is null then
    return jsonb_build_object('resolved',false,'reason','invalid_user');
  end if;

  select * into v_ent
  from private.iclub_subscription_entitlements
  where user_id=p_user_id
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  if not found then
    return jsonb_build_object('resolved',false,'reason','subscription_unassigned');
  end if;

  select * into v_plan
  from private.iclub_plan_policies
  where plan_code=v_ent.plan_code
    and is_active;

  if not found then
    return jsonb_build_object('resolved',false,'reason','plan_unavailable');
  end if;

  return jsonb_build_object(
    'resolved',true,
    'plan_code',v_plan.plan_code,
    'study_subject_limit',v_plan.study_subject_limit,
    'all_available_subjects',v_plan.study_subject_limit is null,
    'competitive_subject_limit',v_plan.competitive_subject_limit,
    'ai_generation_entitled',v_plan.ai_generation_entitled,
    'ai_usage_policy_code',v_plan.ai_usage_policy_code,
    'priority_support',v_plan.priority_support,
    'early_access_entitled',v_plan.early_access_entitled
  );
end;
$caps$;

revoke all on function public.get_iclub_subscription_capabilities_service_v1(uuid)
  from public,anon,authenticated;
grant execute on function public.get_iclub_subscription_capabilities_service_v1(uuid)
  to service_role;

create or replace function public.get_iclub_global_ai_guard_service_v1(
  p_user_id uuid,
  p_subject_key text,
  p_scope_code text,
  p_interaction_type text,
  p_route_class text,
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
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_policy private.iclub_global_ai_gateway_policy%rowtype;
  v_readiness private.iclub_ai_subject_readiness%rowtype;
  v_caps jsonb;
  v_is_academic boolean;
begin
  if p_user_id is null then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','auth_required');
  end if;

  select * into v_policy
  from private.iclub_global_ai_gateway_policy
  where id=1;

  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','gateway_policy_missing');
  end if;

  if p_interaction_type is null
     or not (p_interaction_type=any(v_policy.allowed_interactions)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','interaction_not_allowed');
  end if;

  if p_route_class not in ('prepared','generated') then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','invalid_route_class');
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

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or v_runtime.kill_switch
     or not v_runtime.gateway_enabled then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','gateway_disabled');
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'allowed',false,'mode','unavailable',
      'reason',coalesce(v_caps->>'reason','subscription_unavailable')
    );
  end if;

  if private.iclub_ai_has_active_protected_assessment_v1(p_user_id) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment');
  end if;

  select * into v_readiness
  from private.iclub_ai_subject_readiness
  where subject_key=p_subject_key
    and scope_code=p_scope_code;

  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','subject_not_ready');
  end if;

  if v_readiness.readiness='blocked' then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','subject_blocked');
  end if;

  v_is_academic:=p_interaction_type in ('topic_explanation','freeform_question');

  if v_is_academic and v_readiness.readiness<>'full' then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','subject_not_ready');
  end if;

  if p_route_class='generated' then
    if not v_runtime.generation_enabled then
      return jsonb_build_object('allowed',false,'mode','unavailable','reason','generation_disabled');
    end if;

    if coalesce((v_caps->>'ai_generation_entitled')::boolean,false) is not true then
      return jsonb_build_object('allowed',false,'mode','unavailable','reason','generation_upgrade_required');
    end if;

    if v_readiness.readiness<>'full'
       or not v_readiness.generation_allowed then
      return jsonb_build_object('allowed',false,'mode','unavailable','reason','subject_generation_not_ready');
    end if;
  end if;

  return jsonb_build_object(
    'allowed',true,
    'mode','ready',
    'interaction_type',p_interaction_type,
    'route_class',p_route_class,
    'requested_locale',p_requested_locale,
    'policy_version',v_policy.policy_version,
    'plan_code',v_caps->>'plan_code',
    'ai_usage_policy_code',v_caps->>'ai_usage_policy_code',
    'adapter_code',v_readiness.adapter_code,
    'subject_key',v_readiness.subject_key,
    'scope_code',v_readiness.scope_code
  );
end;
$guard$;

revoke all on function public.get_iclub_global_ai_guard_service_v1(
  uuid,text,text,text,text,text,integer
) from public,anon,authenticated;
grant execute on function public.get_iclub_global_ai_guard_service_v1(
  uuid,text,text,text,text,text,integer
) to service_role;

create or replace function public.get_iclub_ai_ui_bootstrap_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $aiui$
declare
  v_uid uuid:=auth.uid();
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_blocked boolean:=true;
  v_locale text:='ru';
  v_exhausted boolean:=false;
  v_reset_at timestamptz:=null;
begin
  if v_uid is null then
    return jsonb_build_object(
      'visible',false,'assessment_blocked',false,'usage_exhausted',false,
      'reset_at',null,'reason','auth_required','ui_version','global_ai_conversations_v1'
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or v_runtime.kill_switch
     or not v_runtime.ui_enabled
     or not v_runtime.gateway_enabled then
    return jsonb_build_object(
      'visible',false,'assessment_blocked',false,'usage_exhausted',false,
      'reset_at',null,'reason','ui_disabled','ui_version','global_ai_conversations_v1'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'visible',false,'assessment_blocked',false,'usage_exhausted',false,
      'reset_at',null,'reason','access_unresolved','ui_version','global_ai_conversations_v1'
    );
  end if;

  select case
    when u.language_code in ('ru','uz','en') then u.language_code
    else 'ru'
  end
  into v_locale
  from public.users u
  where u.id=v_uid;

  v_blocked:=private.iclub_ai_has_active_protected_assessment_v1(v_uid);

  select coalesce(p.exhausted,false),p.reset_at
  into v_exhausted,v_reset_at
  from private.iclub_ai_usage_periods p
  where p.user_id=v_uid
    and p.status='active'
    and p.reset_at>now()
  order by p.created_at desc
  limit 1;

  v_exhausted:=coalesce(v_exhausted,false);
  if not v_exhausted then
    v_reset_at:=null;
  end if;

  return jsonb_build_object(
    'visible',true,
    'assessment_blocked',coalesce(v_blocked,true),
    'usage_exhausted',v_exhausted,
    'reset_at',v_reset_at,
    'reason',case
      when coalesce(v_blocked,true) then 'active_assessment'
      when v_exhausted then 'usage_exhausted'
      else null
    end,
    'locale',coalesce(v_locale,'ru'),
    'ui_version','global_ai_conversations_v1'
  );
end;
$aiui$;

revoke all on function public.get_iclub_ai_ui_bootstrap_v1() from public,anon;
grant execute on function public.get_iclub_ai_ui_bootstrap_v1()
  to authenticated,service_role;

create or replace function public.get_iclub_plan_ui_bootstrap_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $plans$
declare
  v_uid uuid:=auth.uid();
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_plans jsonb;
begin
  if v_uid is null then
    return jsonb_build_object(
      'visible',false,'reason','auth_required','checkout_enabled',false,
      'ui_version','iclub_plans_v1'
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found or not coalesce(v_runtime.plans_ui_enabled,false) then
    return jsonb_build_object(
      'visible',false,'reason','plans_ui_disabled','checkout_enabled',false,
      'ui_version','iclub_plans_v1'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'visible',false,'reason','access_unresolved','checkout_enabled',false,
      'ui_version','iclub_plans_v1'
    );
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'plan_code',p.plan_code,
      'monthly_price_uzs',p.monthly_price_uzs,
      'study_subject_limit',p.study_subject_limit,
      'all_available_subjects',p.study_subject_limit is null,
      'competitive_subject_limit',p.competitive_subject_limit,
      'ai_generation_entitled',p.ai_generation_entitled
    )
    order by case p.plan_code when 'free' then 1 when 'plus' then 2 else 3 end
  ),'[]'::jsonb)
  into v_plans
  from private.iclub_plan_policies p
  where p.is_active;

  return jsonb_build_object(
    'visible',true,
    'reason',null,
    'current_plan_code',v_caps->>'plan_code',
    'checkout_enabled',coalesce(v_runtime.checkout_enabled,false),
    'plans',v_plans,
    'ui_version','iclub_plans_v1'
  );
end;
$plans$;

revoke all on function public.get_iclub_plan_ui_bootstrap_v1() from public,anon;
grant execute on function public.get_iclub_plan_ui_bootstrap_v1()
  to authenticated,service_role;

commit;