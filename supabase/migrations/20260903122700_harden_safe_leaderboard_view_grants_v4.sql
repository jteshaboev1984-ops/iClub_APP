-- Tighten grants created by Supabase default table/view privileges.
-- Leaderboard views are read-only client surfaces.

revoke all privileges on table public.ratings_cache_safe_v4 from public, anon, authenticated;
grant select on table public.ratings_cache_safe_v4 to authenticated, service_role;

revoke all privileges on table public.tour_attempts_leaderboard_safe_v4 from public, anon, authenticated;
grant select on table public.tour_attempts_leaderboard_safe_v4 to authenticated, service_role;
