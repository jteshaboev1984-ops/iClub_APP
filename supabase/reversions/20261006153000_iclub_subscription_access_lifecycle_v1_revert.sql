-- Safe pre-activation reversion for iClub subscription/access lifecycle v1.
-- Refuses to remove lifecycle/access contracts after any commercial state was used.

begin;

do $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
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

  select
    (select count(*) from private.iclub_subscription_events)
    + (select count(*) from private.iclub_commercial_migration_state)
    + (select count(*) from private.iclub_legacy_subject_snapshot)
    + (select count(*) from private.iclub_subject_slot_selections)
    + (select count(*) from private.iclub_subject_slot_events)
  into v_count;

  if v_count<>0 then
    raise exception 'Subscription/access reversion refused: commercial lifecycle rows exist=%',v_count;
  end if;
end
$$;

drop function if exists public.finalize_iclub_subject_selection_service_v1(uuid,text);
drop function if exists public.set_iclub_subject_slot_service_v1(uuid,uuid,text,boolean,boolean,text);
drop function if exists public.get_iclub_subject_access_guard_service_v1(uuid,text,text);
drop function if exists public.capture_iclub_legacy_access_baseline_service_v1(text);
drop function if exists public.apply_iclub_subscription_event_service_v1(
  uuid,uuid,text,text,timestamptz,timestamptz,timestamptz,text
);

drop table if exists private.iclub_subject_slot_events;
drop table if exists private.iclub_subject_slot_selections;
drop table if exists private.iclub_legacy_subject_snapshot;
drop table if exists private.iclub_commercial_migration_state;
drop table if exists private.iclub_commercial_access_config;
drop table if exists private.iclub_subscription_events;

alter table private.iclub_subscription_entitlements
  drop constraint if exists iclub_subscription_scheduled_change_check,
  drop constraint if exists iclub_subscription_period_order_check,
  drop column if exists last_event_id,
  drop column if exists scheduled_change_at,
  drop column if exists scheduled_plan_code,
  drop column if exists cancel_at_period_end,
  drop column if exists current_period_end,
  drop column if exists current_period_start;

commit;
