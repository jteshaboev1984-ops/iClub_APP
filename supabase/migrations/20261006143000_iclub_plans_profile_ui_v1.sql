-- iClub Free / Plus / Pro profile presentation foundation v1.
-- Commercial UI remains dormant by default. No checkout provider is connected.

begin;

alter table private.iclub_global_ai_runtime_config
  add column if not exists plans_ui_enabled boolean not null default false,
  add column if not exists checkout_enabled boolean not null default false;

create or replace function public.get_iclub_plan_ui_bootstrap_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_plans jsonb;
begin
  if v_uid is null then
    return jsonb_build_object(
      'visible',false,
      'reason','auth_required',
      'checkout_enabled',false,
      'ui_version','iclub_plans_v1'
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found or not coalesce(v_runtime.plans_ui_enabled,false) then
    return jsonb_build_object(
      'visible',false,
      'reason','plans_ui_disabled',
      'checkout_enabled',false,
      'ui_version','iclub_plans_v1'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'visible',false,
      'reason','access_unresolved',
      'checkout_enabled',false,
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
      'ai_generation_entitled',p.ai_generation_entitled,
      'priority_support',p.priority_support,
      'early_access_entitled',p.early_access_entitled
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
$$;

revoke all on function public.get_iclub_plan_ui_bootstrap_v1() from public,anon;
grant execute on function public.get_iclub_plan_ui_bootstrap_v1()
  to authenticated,service_role;

commit;
