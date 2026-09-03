-- FINAL PRODUCTION CUTOVER HARDENING
-- ==================================
-- DO NOT APPLY while production main still loads the legacy assessment/credential frontend.
-- This file intentionally lives outside supabase/migrations so it cannot be picked up
-- accidentally by a migration runner.
--
-- Required frontend preconditions before execution:
--   1) production index.html loads security/legacy-assessment-safe-api.js;
--   2) production app.js has no direct .from("questions") reads;
--   3) production Ratings uses ratings_cache_safe_v4 and tour_attempts_leaderboard_safe_v4;
--   4) active Practice/Tour writes use safe-v4 RPCs;
--   5) credential sync uses sync_user_credentials_safe_v1 instead of direct user_credentials writes;
--   6) production browser regression is green on the exact deployed revision.

begin;

-- DB-side preconditions: fail before changing privileges if the safe boundary is absent.
do $$
begin
  if to_regprocedure('public.start_practice_session_auto_safe_v4(bigint,text)') is null then
    raise exception 'cutover_precondition_failed: start_practice_session_auto_safe_v4 missing';
  end if;
  if to_regprocedure('public.finalize_practice_session_safe_v4(bigint,integer)') is null then
    raise exception 'cutover_precondition_failed: finalize_practice_session_safe_v4 missing';
  end if;
  if to_regprocedure('public.start_tour_attempt_safe_v4(bigint,text)') is null then
    raise exception 'cutover_precondition_failed: start_tour_attempt_safe_v4 missing';
  end if;
  if to_regprocedure('public.submit_tour_answer_safe_v4(bigint,bigint,text,integer,integer,boolean,text)') is null then
    raise exception 'cutover_precondition_failed: submit_tour_answer_safe_v4 missing';
  end if;
  if to_regprocedure('public.finalize_tour_attempt_safe_v4(bigint,integer,text)') is null then
    raise exception 'cutover_precondition_failed: finalize_tour_attempt_safe_v4 missing';
  end if;
  if to_regprocedure('public.sync_user_credentials_safe_v1(jsonb)') is null then
    raise exception 'cutover_precondition_failed: sync_user_credentials_safe_v1 missing';
  end if;
  if to_regclass('public.ratings_cache_safe_v4') is null then
    raise exception 'cutover_precondition_failed: ratings_cache_safe_v4 missing';
  end if;
  if to_regclass('public.tour_attempts_leaderboard_safe_v4') is null then
    raise exception 'cutover_precondition_failed: tour_attempts_leaderboard_safe_v4 missing';
  end if;
end
$$;

-- 1) Canonical question bank: no direct client access.
drop policy if exists questions_public_read on public.questions;
revoke all privileges on table public.questions from anon, authenticated;

-- 2) Ratings/profile privacy: remove broad direct cross-user reads.
drop policy if exists users_select_all_auth on public.users;
drop policy if exists tour_attempts_select_all_auth on public.tour_attempts;
drop policy if exists ratings_cache_public_read on public.ratings_cache;
revoke all privileges on table public.ratings_cache from public, anon, authenticated;

-- Keep profile table privileges required for authenticated own-row registration/settings.
revoke all privileges on table public.users from anon, authenticated;
grant select on table public.users to anon;
grant select, insert, update on table public.users to authenticated;

-- 3) Tour canonical progress: direct client writes disabled; owner-read only.
drop policy if exists tour_attempts_rw_own on public.tour_attempts;
drop policy if exists tour_attempts_insert_own on public.tour_attempts;
drop policy if exists tour_attempts_update_own on public.tour_attempts;
drop policy if exists tour_attempts_delete_own on public.tour_attempts;
drop policy if exists tour_attempts_select_own on public.tour_attempts;
create policy tour_attempts_select_own
on public.tour_attempts
for select
to authenticated
using (user_id = auth.uid());

revoke all privileges on table public.tour_attempts from anon, authenticated;
grant select on table public.tour_attempts to authenticated;

drop policy if exists tour_answers_insert_own on public.tour_answers;
drop policy if exists tour_answers_insert_owner on public.tour_answers;
drop policy if exists tour_answers_update_own on public.tour_answers;
drop policy if exists tour_answers_update_owner on public.tour_answers;
drop policy if exists tour_answers_delete_owner on public.tour_answers;
drop policy if exists tour_answers_select_own on public.tour_answers;
drop policy if exists tour_answers_select_owner on public.tour_answers;
create policy tour_answers_select_owner
on public.tour_answers
for select
to authenticated
using (
  exists (
    select 1
    from public.tour_attempts ta
    where ta.id = tour_answers.attempt_id
      and ta.user_id = auth.uid()
  )
);

revoke all privileges on table public.tour_answers from anon, authenticated;
grant select on table public.tour_answers to authenticated;

-- 4) Credentials: canonical status/evidence is server-authoritative.
-- The client may read its own credential rows, but may not self-award/update/delete them.
drop policy if exists user_credentials_rw_own on public.user_credentials;
drop policy if exists user_credentials_select_own on public.user_credentials;
create policy user_credentials_select_own
on public.user_credentials
for select
to authenticated
using (user_id = auth.uid());

revoke all privileges on table public.user_credentials from anon, authenticated;
grant select on table public.user_credentials to authenticated;
revoke all privileges on sequence public.user_credentials_id_seq from anon, authenticated;

comment on table public.questions is
'Canonical assessment question bank. Direct client access disabled after production safe-v4 frontend cutover.';
comment on table public.user_credentials is
'Credential state is server-authoritative. Authenticated clients can read only their own rows; writes occur through validated server RPCs.';

commit;

-- POST-CUTOVER verification checklist (run separately):
--   * anon/authenticated have no privileges on questions;
--   * authenticated can only SELECT tour_attempts/tour_answers directly;
--   * authenticated can only SELECT its own user_credentials directly;
--   * users_select_all_auth / tour_attempts_select_all_auth / ratings_cache_public_read do not exist;
--   * authenticated own profile/history/credential reads still work;
--   * safe Practice/Tour review RPCs return real rows;
--   * sync_user_credentials_safe_v1 rejects unsupported/self-awarded active credentials;
--   * production browser regression remains green.
