-- Safe pre-activation reversion for iClub Global AI + tariffs foundation v1.
-- Refuses to drop the foundation if runtime was enabled or if any real
-- subscription/usage rows exist.

begin;

do $$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_count integer;
begin
  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if found and (
    v_runtime.ui_enabled
    or v_runtime.gateway_enabled
    or v_runtime.generation_enabled
    or not v_runtime.kill_switch
  ) then
    raise exception 'Global AI foundation reversion refused: runtime is not fully dormant';
  end if;

  select count(*) into v_count
  from private.iclub_subscription_entitlements;
  if v_count<>0 then
    raise exception 'Global AI foundation reversion refused: subscription entitlements exist=%',v_count;
  end if;

  select count(*) into v_count
  from private.iclub_ai_usage_periods;
  if v_count<>0 then
    raise exception 'Global AI foundation reversion refused: usage periods exist=%',v_count;
  end if;

  select count(*) into v_count
  from private.iclub_ai_usage_reservations;
  if v_count<>0 then
    raise exception 'Global AI foundation reversion refused: usage reservations exist=%',v_count;
  end if;
end
$$;

drop function if exists public.get_iclub_global_ai_foundation_snapshot_v1();
drop function if exists public.finalize_iclub_ai_usage_service_v1(uuid,text,text);
drop function if exists public.reserve_iclub_ai_usage_service_v1(uuid,uuid,text,text);
drop function if exists public.get_iclub_public_plan_catalog_v1();

drop table if exists private.iclub_ai_usage_reservations;
drop table if exists private.iclub_ai_usage_periods;
drop table if exists private.iclub_ai_subject_readiness;
drop table if exists private.iclub_global_ai_runtime_config;
drop table if exists private.iclub_subscription_entitlements;
drop table if exists private.iclub_plan_policies;
drop table if exists private.iclub_ai_usage_policies;

commit;
