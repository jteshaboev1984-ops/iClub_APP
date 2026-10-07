-- Safe pre-activation reversion for Global AI learner-shell bootstrap v1.

begin;

do $$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
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
    raise exception 'Global AI shell bootstrap reversion refused: runtime is not fully dormant';
  end if;
end
$$;

drop function if exists public.get_iclub_ai_ui_bootstrap_v1();

commit;
