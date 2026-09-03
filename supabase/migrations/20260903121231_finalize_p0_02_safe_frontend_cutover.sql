begin;

do $$
begin
  if to_regprocedure('public.start_practice_session_auto_safe_v4(bigint,text)') is null then
    raise exception 'p0_02_cutover_precondition_failed: start_practice_session_auto_safe_v4 missing';
  end if;
  if to_regprocedure('public.finalize_practice_session_safe_v4(bigint,integer)') is null then
    raise exception 'p0_02_cutover_precondition_failed: finalize_practice_session_safe_v4 missing';
  end if;
  if to_regprocedure('public.start_tour_attempt_safe_v4(bigint,text)') is null then
    raise exception 'p0_02_cutover_precondition_failed: start_tour_attempt_safe_v4 missing';
  end if;
  if to_regprocedure('public.submit_tour_answer_safe_v4(bigint,bigint,text,integer,integer,boolean,text)') is null then
    raise exception 'p0_02_cutover_precondition_failed: submit_tour_answer_safe_v4 missing';
  end if;
  if to_regprocedure('public.finalize_tour_attempt_safe_v4(bigint,integer,text)') is null then
    raise exception 'p0_02_cutover_precondition_failed: finalize_tour_attempt_safe_v4 missing';
  end if;
  if to_regclass('public.ratings_cache_safe_v4') is null then
    raise exception 'p0_02_cutover_precondition_failed: ratings_cache_safe_v4 missing';
  end if;
  if to_regclass('public.tour_attempts_leaderboard_safe_v4') is null then
    raise exception 'p0_02_cutover_precondition_failed: tour_attempts_leaderboard_safe_v4 missing';
  end if;
end
$$;

drop policy if exists questions_public_read on public.questions;
revoke all privileges on table public.questions from public, anon, authenticated;

drop policy if exists users_select_all_auth on public.users;
drop policy if exists tour_attempts_select_all_auth on public.tour_attempts;
drop policy if exists ratings_cache_public_read on public.ratings_cache;
revoke all privileges on table public.ratings_cache from public, anon, authenticated;

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
drop policy if exists tour_answers_delete_own on public.tour_answers;
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

comment on table public.questions is
'Canonical assessment question bank. Direct client access disabled after P0-02 production safe-v4 frontend cutover.';

commit;
