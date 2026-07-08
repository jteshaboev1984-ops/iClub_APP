-- Isolate AI lab practice attempts from normal user-facing practice statistics.
-- Safe intent:
-- - do not delete attempts;
-- - mark lab attempts as is_lab=true;
-- - hide lab attempts from normal SELECT/RLS surfaces;
-- - keep lab AI diagnosis possible through a dedicated RPC.

begin;

alter table public.practice_attempts
  add column if not exists is_lab boolean not null default false;

create index if not exists idx_practice_attempts_user_subject_time_non_lab
on public.practice_attempts(user_id, subject_id, created_at desc)
where is_lab is false;

-- Hide already-created AI-lab attempts that produced AI diagnosis snapshots.
-- At the moment, practice_ai_diagnosis is used only by the hidden AI lab flow.
update public.practice_attempts pa
set is_lab = true
where exists (
  select 1
  from public.learning_roadmaps lr
  where lr.source_type = 'practice_ai_diagnosis'
    and lr.source_id = pa.id
)
and coalesce(pa.is_lab, false) is false;

-- Rebuild SELECT policies so normal app screens do not see lab attempts.
drop policy if exists practice_attempts_select_own on public.practice_attempts;
drop policy if exists practice_attempts_rw_own on public.practice_attempts;
drop policy if exists practice_attempts_insert_own on public.practice_attempts;
drop policy if exists practice_attempts_update_own on public.practice_attempts;
drop policy if exists practice_attempts_delete_own on public.practice_attempts;

create policy practice_attempts_select_own
on public.practice_attempts
for select
to authenticated
using (
  user_id = auth.uid()
  and coalesce(is_lab, false) is false
);

drop policy if exists practice_answers_select_own on public.practice_answers;
drop policy if exists practice_answers_select_owner on public.practice_answers;
drop policy if exists practice_answers_insert_own on public.practice_answers;
drop policy if exists practice_answers_insert_owner on public.practice_answers;
drop policy if exists practice_answers_update_own on public.practice_answers;
drop policy if exists practice_answers_update_owner on public.practice_answers;
drop policy if exists practice_answers_delete_owner on public.practice_answers;

create policy practice_answers_select_own
on public.practice_answers
for select
to authenticated
using (
  exists (
    select 1
    from public.practice_attempts pa
    where pa.id = practice_answers.attempt_id
      and pa.user_id = auth.uid()
      and coalesce(pa.is_lab, false) is false
  )
);

-- Hide lab-generated per-answer diagnosis from normal recommendation surfaces.
drop policy if exists uad_user_read_own on public.user_answer_diagnosis;

create policy uad_user_read_own
on public.user_answer_diagnosis
for select
to authenticated
using (
  auth.uid() = user_id
  and (
    attempt_type <> 'practice'
    or exists (
      select 1
      from public.practice_attempts pa
      where pa.id = user_answer_diagnosis.attempt_id
        and pa.user_id = auth.uid()
        and coalesce(pa.is_lab, false) is false
    )
  )
);

create or replace function public.create_latest_lab_practice_ai_diagnosis()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_attempt_id bigint;
begin
  if v_auth_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select pa.id
  into v_attempt_id
  from public.practice_attempts pa
  where pa.user_id = v_auth_user
  order by pa.id desc
  limit 1;

  if v_attempt_id is null then
    raise exception 'no_practice_attempt_found' using errcode = 'P0002';
  end if;

  update public.practice_attempts
  set is_lab = true
  where id = v_attempt_id
    and user_id = v_auth_user;

  return public.create_practice_ai_diagnosis(v_attempt_id);
end;
$$;

revoke all on function public.create_latest_lab_practice_ai_diagnosis() from public, anon;
grant execute on function public.create_latest_lab_practice_ai_diagnosis() to authenticated;

comment on column public.practice_attempts.is_lab is
'Hidden lab/test attempt flag. Normal app SELECT policies exclude is_lab=true attempts from user-facing practice history and metrics.';

comment on function public.create_latest_lab_practice_ai_diagnosis() is
'AI lab-only RPC: marks the authenticated user latest practice attempt as lab and creates/returns its AI diagnosis snapshot.';

commit;
