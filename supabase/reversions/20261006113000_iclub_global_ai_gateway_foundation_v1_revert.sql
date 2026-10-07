-- Safe pre-activation reversion for Global AI gateway foundation v1.
-- Refuses to remove gateway contracts after activation/audit evidence exists.

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
    raise exception 'Global AI gateway reversion refused: runtime is not fully dormant';
  end if;

  select count(*) into v_count
  from private.iclub_global_ai_gateway_audit;
  if v_count<>0 then
    raise exception 'Global AI gateway reversion refused: audit rows exist=%',v_count;
  end if;
end
$$;

drop function if exists public.get_iclub_global_ai_gateway_snapshot_v1();
drop function if exists public.record_iclub_global_ai_gateway_audit_service_v1(
  uuid,uuid,text,text,text,text,text,text,text,text,integer,text
);
drop function if exists public.get_iclub_global_ai_guard_service_v1(
  uuid,text,text,text,text,text,integer
);
drop function if exists public.get_iclub_subscription_capabilities_service_v1(uuid);
drop function if exists private.iclub_ai_has_active_protected_assessment_v1(uuid);

drop table if exists private.iclub_global_ai_gateway_audit;
drop table if exists private.iclub_global_ai_gateway_policy;

alter table private.iclub_ai_subject_readiness
  drop constraint if exists iclub_ai_subject_readiness_full_adapter_check;

alter table private.iclub_ai_subject_readiness
  drop column if exists adapter_code;

commit;
