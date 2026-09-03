drop policy if exists users_select_all_auth on public.users;
drop policy if exists tour_attempts_select_all_auth on public.tour_attempts;
drop policy if exists ratings_cache_public_read on public.ratings_cache;
revoke all privileges on table public.ratings_cache from public, anon, authenticated;
