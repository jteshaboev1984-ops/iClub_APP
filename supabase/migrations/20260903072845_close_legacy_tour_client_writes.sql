-- P0 hardening: active Tour writes are server-authoritative via safe v4 RPCs.
-- Keep only owner-scoped read access needed by personal history/status UI.

begin;

drop policy if exists tour_attempts_rw_own on public.tour_attempts;
drop policy if exists tour_attempts_insert_own on public.tour_attempts;
drop policy if exists tour_attempts_update_own on public.tour_attempts;
drop policy if exists tour_attempts_delete_own on public.tour_attempts;

drop policy if exists tour_answers_insert_own on public.tour_answers;
drop policy if exists tour_answers_insert_owner on public.tour_answers;
drop policy if exists tour_answers_update_own on public.tour_answers;
drop policy if exists tour_answers_update_owner on public.tour_answers;
drop policy if exists tour_answers_delete_owner on public.tour_answers;
drop policy if exists tour_answers_select_own on public.tour_answers;

drop policy if exists tour_attempts_select_own on public.tour_attempts;
create policy tour_attempts_select_own
on public.tour_attempts
for select
to authenticated
using (user_id = auth.uid());

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

revoke all privileges on table public.tour_attempts from anon, authenticated;
revoke all privileges on table public.tour_answers from anon, authenticated;

grant select on table public.tour_attempts to authenticated;
grant select on table public.tour_answers to authenticated;

commit;
