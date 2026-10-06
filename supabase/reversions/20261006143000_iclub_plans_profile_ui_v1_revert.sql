-- Safe pre-activation reversion for iClub plan/profile presentation v1.

begin;

do $$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
begin
  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if found and (
    coalesce(v_runtime.plans_ui_enabled,false)
    or coalesce(v_runtime.checkout_enabled,false)
  ) then
    raise exception 'Plan/profile UI reversion refused: commercial UI is active';
  end if;
end
$$;

drop function if exists public.get_iclub_plan_ui_bootstrap_v1();

alter table private.iclub_global_ai_runtime_config
  drop column if exists checkout_enabled,
  drop column if exists plans_ui_enabled;

commit;
