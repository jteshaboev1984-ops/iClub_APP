-- Production-compatible users grant hardening.
-- Legacy leaderboard still needs authenticated cross-user SELECT;
-- profile registration/settings need authenticated INSERT+UPDATE.
-- DDL-like and DELETE privileges are not required by the frontend.

begin;
revoke all privileges on table public.users from anon, authenticated;
grant select on table public.users to anon;
grant select, insert, update on table public.users to authenticated;
commit;
