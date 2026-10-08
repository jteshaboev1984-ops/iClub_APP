-- Safe reversion for the canary activation-control functions only.
-- No canary, subject-selection, subscription or learner/history row is deleted.
-- Refuse to remove rollback controls while this phase is active.

begin;

do $guard$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_cfg private.iclub_commercial_access_config%rowtype;
begin
  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if found and (
    coalesce(v_runtime.plans_ui_enabled,false)
    or coalesce(v_runtime.plans_rollout_mode,'off')<>'off'
    or coalesce(v_runtime.checkout_enabled,false)
  ) then
    raise exception 'Canary activation-control reversion refused: Plans phase is active';
  end if;

  if v_cfg.id is not null and (
    coalesce(v_cfg.subject_selection_ui_enabled,false)
    or coalesce(v_cfg.subject_limits_mode,'off')<>'off'
  ) then
    raise exception 'Canary activation-control reversion refused: subject-selection phase is active';
  end if;
end;
$guard$;

drop function if exists public.deactivate_iclub_plans_subject_canary_service_v1(text);
drop function if exists public.activate_iclub_plans_subject_canary_service_v1(
  uuid,uuid,uuid,text,text
);
drop function if exists public.get_iclub_product_canary_activation_snapshot_service_v1();

commit;
