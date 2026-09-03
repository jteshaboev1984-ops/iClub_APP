-- Production-compatible grant hardening for public/owner-readable and server-only tables.

begin;

revoke all privileges on table public.certificates from anon, authenticated;
grant select on table public.certificates to anon, authenticated;

revoke all privileges on table public.notifications from anon, authenticated;
grant select on table public.notifications to anon, authenticated;

revoke all privileges on table public.team_people from anon, authenticated;
grant select on table public.team_people to anon, authenticated;

revoke all privileges on table public.telegram_links from anon, authenticated;
revoke all privileges on table public.telegram_profile_recoveries from anon, authenticated;

commit;
