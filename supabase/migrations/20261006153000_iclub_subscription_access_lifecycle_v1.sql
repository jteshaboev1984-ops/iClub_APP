-- iClub subscription lifecycle + commercial access schema v1.
-- Additive and dormant by design.
--
-- Safety laws:
-- - every authenticated learner resolves to Free by default without mass-writing entitlement rows;
-- - only an explicit active entitlement or service-managed canary override can change that plan;
-- - no legacy learner/content/progress row is updated or deleted;
-- - browser roles cannot mutate subscription or canary authority;
-- - commercial subject enforcement remains OFF by default.

begin;

alter table private.iclub_subscription_entitlements
  add column if not exists current_period_start timestamptz null,
  add column if not exists current_period_end timestamptz null,
  add column if not exists cancel_at_period_end boolean not null default false,
  add column if not exists scheduled_plan_code text null
    references private.iclub_plan_policies(plan_code),
  add column if not exists scheduled_change_at timestamptz null,
  add column if not exists last_event_id uuid null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid='private.iclub_subscription_entitlements'::regclass
      and conname='iclub_subscription_period_order_check'
  ) then
    alter table private.iclub_subscription_entitlements
      add constraint iclub_subscription_period_order_check
      check (
        current_period_end is null
        or current_period_start is null
        or current_period_end > current_period_start
      );
  end if;

  if not exists (
    select 1
    from pg_constraint