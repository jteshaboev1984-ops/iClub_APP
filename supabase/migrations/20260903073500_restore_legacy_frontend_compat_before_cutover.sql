-- TEMPORARY COMPATIBILITY BRIDGE.
-- Production main still uses the legacy frontend. Keep safe-v4 RPCs/views in place,
-- but restore only the direct privileges/policies required by that frontend until
-- the production frontend is cut over and independently verified.

begin;

-- questions: legacy runtime needs active question rows, including answer material.
drop policy if exists questions_public_read on public.questions;
create policy questions_public_read
on public.questions
for select
to public
using (coalesce(is_active, true) = true);
revoke all privileges on table public.questions from anon, authenticated;
grant select on table public.questions to anon, authenticated;

-- users: legacy leaderboard joins require authenticated cross-user reads.
drop policy if exists users_select_all_auth on public.users;
create policy users_select_all_auth
on public.users
for select
to authenticated
using (true);

-- tour attempts: legacy Tour runtime writes own rows; legacy Ratings reads all rows.
drop policy if exists tour_attempts_select_own on public.tour_attempts;
drop policy if exists tour_attempts_select_all_auth on public.tour_attempts;
drop policy if exists tour_attempts_insert_own on public.tour_attempts;
drop policy if exists tour_attempts_update_own on public.tour_attempts;
drop policy if exists tour_attempts_delete_own on public.tour_attempts;
create policy tour_attempts_select_all_auth
on public.tour_attempts for select to authenticated using (true);
create policy tour_attempts_insert_own
on public.tour_attempts for insert to authenticated with check (user_id = auth.uid());
create policy tour_attempts_update_own
on public.tour_attempts for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy tour_attempts_delete_own
on public.tour_attempts for delete to authenticated using (user_id = auth.uid());
revoke all privileges on table public.tour_attempts from anon, authenticated;
grant select, insert, update, delete on table public.tour_attempts to authenticated;

-- tour answers: legacy runtime writes/reads only answers belonging to own attempt.
drop policy if exists tour_answers_select_owner on public.tour_answers;
drop policy if exists tour_answers_insert_owner on public.tour_answers;
drop policy if exists tour_answers_update_owner on public.tour_answers;
drop policy if exists tour_answers_delete_owner on public.tour_answers;
create policy tour_answers_select_owner
on public.tour_answers for select to authenticated
using (exists (select 1 from public.tour_attempts ta where ta.id=tour_answers.attempt_id and ta.user_id=auth.uid()));
create policy tour_answers_insert_owner
on public.tour_answers for insert to authenticated
with check (exists (select 1 from public.tour_attempts ta where ta.id=tour_answers.attempt_id and ta.user_id=auth.uid()));
create policy tour_answers_update_owner
on public.tour_answers for update to authenticated
using (exists (select 1 from public.tour_attempts ta where ta.id=tour_answers.attempt_id and ta.user_id=auth.uid()))
with check (exists (select 1 from public.tour_attempts ta where ta.id=tour_answers.attempt_id and ta.user_id=auth.uid()));
create policy tour_answers_delete_owner
on public.tour_answers for delete to authenticated
using (exists (select 1 from public.tour_attempts ta where ta.id=tour_answers.attempt_id and ta.user_id=auth.uid()));
revoke all privileges on table public.tour_answers from anon, authenticated;
grant select, insert, update, delete on table public.tour_answers to authenticated;

-- ratings cache: legacy leaderboard reads it directly.
drop policy if exists ratings_cache_public_read on public.ratings_cache;
create policy ratings_cache_public_read
on public.ratings_cache for select to public using (true);
revoke all privileges on table public.ratings_cache from public, anon, authenticated;
grant select on table public.ratings_cache to anon, authenticated;

comment on table public.questions is
'Canonical assessment question bank. Temporary legacy production read compatibility restored pending production safe-v4 frontend cutover.';

commit;
