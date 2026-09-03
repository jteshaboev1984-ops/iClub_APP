-- User-approved invariants:
-- user_notifications: authenticated users may only read/update their own rows.
-- video_events: append-only client analytics.

revoke all on table public.user_notifications from anon, authenticated;
grant select, update on table public.user_notifications to authenticated;

drop policy if exists user_notifications_rw_own on public.user_notifications;
drop policy if exists user_notifications_update_own_deleted_at on public.user_notifications;
drop policy if exists user_notifications_select_own on public.user_notifications;
drop policy if exists user_notifications_update_own on public.user_notifications;

create policy user_notifications_select_own
on public.user_notifications
for select
to authenticated
using (auth.uid() = user_id);

create policy user_notifications_update_own
on public.user_notifications
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

revoke all on table public.video_events from anon, authenticated;
grant insert on table public.video_events to authenticated;

drop policy if exists video_events_rw_own on public.video_events;
drop policy if exists video_events_insert_own on public.video_events;

create policy video_events_insert_own
on public.video_events
for insert
to authenticated
with check (auth.uid() = user_id);
