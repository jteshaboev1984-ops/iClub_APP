-- Align table grants only with operations already permitted by current RLS.
-- No user-visible capability is removed because the revoked operations are already blocked by RLS.

revoke update, delete on table public.app_events from anon, authenticated;

revoke all privileges on table public.support_tickets from anon;
revoke update, delete on table public.support_tickets from authenticated;

revoke all privileges on table public.user_subjects_history from anon;
revoke update, delete on table public.user_subjects_history from authenticated;
