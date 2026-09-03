-- User-approved default-deny rule for future public tables/sequences.
-- Current public objects are owned by postgres; explicit grants must be added by each migration.
alter default privileges for role postgres in schema public revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated;

-- Existing sequences aligned to current insert behavior.
revoke all on sequence public.user_notifications_id_seq from anon, authenticated;

revoke all on sequence public.video_events_id_seq from anon, authenticated;
grant usage on sequence public.video_events_id_seq to authenticated;

revoke all on sequence public.support_tickets_id_seq from anon;
revoke all on sequence public.user_subjects_history_id_seq from anon;
