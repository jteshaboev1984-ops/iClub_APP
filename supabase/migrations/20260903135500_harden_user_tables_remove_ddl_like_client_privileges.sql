-- Compatible hardening only: no CRUD behavior changes.
-- Keeps SELECT/INSERT/UPDATE/DELETE grants untouched; removes privileges that the web client does not use.

revoke references, trigger, truncate on table public.app_events from anon, authenticated;
revoke references, trigger, truncate on table public.support_tickets from anon, authenticated;
revoke references, trigger, truncate on table public.recommendations from anon, authenticated;
revoke references, trigger, truncate on table public.user_credentials from anon, authenticated;
revoke references, trigger, truncate on table public.user_notifications from anon, authenticated;
revoke references, trigger, truncate on table public.user_subjects from anon, authenticated;
revoke references, trigger, truncate on table public.user_subjects_history from anon, authenticated;
revoke references, trigger, truncate on table public.video_events from anon, authenticated;
