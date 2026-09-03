-- Safe leaderboard read surface for the legacy Ratings UI.
-- These views intentionally expose only leaderboard/public-profile fields.
-- They are owner-executed so callers do not need broad SELECT on users/tour_attempts.

create or replace view public.ratings_cache_safe_v4
with (security_barrier=true, security_invoker=false)
as
select
  rc.tour_id,
  rc.user_id,
  rc.score,
  rc.total_time,
  rc.rank_type,
  rc.rank_no,
  rc.updated_at,
  jsonb_build_object(
    'first_name', u.first_name,
    'last_name', u.last_name,
    'school', u.school,
    'class', u.class,
    'region', u.region,
    'district', u.district,
    'region_id', u.region_id,
    'district_id', u.district_id
  ) as users
from public.ratings_cache rc
join public.users u on u.id=rc.user_id;

revoke all privileges on table public.ratings_cache_safe_v4 from public, anon;
grant select on table public.ratings_cache_safe_v4 to authenticated, service_role;

comment on view public.ratings_cache_safe_v4 is
'P0 safe Ratings cache surface. Exposes ranking plus limited public leaderboard profile fields only; hides users auth/Telegram/login fields.';

create or replace view public.tour_attempts_leaderboard_safe_v4
with (security_barrier=true, security_invoker=false)
as
select
  ta.user_id,
  ta.tour_id,
  ta.score,
  ta.total_time,
  ta.status,
  jsonb_build_object(
    'first_name', u.first_name,
    'last_name', u.last_name,
    'school', u.school,
    'class', u.class,
    'region', u.region,
    'district', u.district,
    'region_id', u.region_id,
    'district_id', u.district_id
  ) as users
from public.tour_attempts ta
join public.users u on u.id=ta.user_id
where ta.status in ('submitted','time_expired','anti_cheat');

revoke all privileges on table public.tour_attempts_leaderboard_safe_v4 from public, anon;
grant select on table public.tour_attempts_leaderboard_safe_v4 to authenticated, service_role;

comment on view public.tour_attempts_leaderboard_safe_v4 is
'P0 safe live leaderboard surface. Exposes completed Tour score/time plus limited public leaderboard profile fields only; hides attempt metadata and users auth/Telegram/login fields.';
