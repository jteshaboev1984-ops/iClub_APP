-- Lab helper: mark latest practice attempt as hidden lab attempt without creating AI diagnosis.
-- Safe: no deletion, no score/history recalculation.

create or replace function public.mark_latest_practice_attempt_as_lab()
returns bigint
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

  return v_attempt_id;
end;
$$;

revoke all on function public.mark_latest_practice_attempt_as_lab() from public, anon;
grant execute on function public.mark_latest_practice_attempt_as_lab() to authenticated;

comment on function public.mark_latest_practice_attempt_as_lab() is
'AI lab-only helper: marks the authenticated user latest practice attempt as is_lab=true so it does not enter normal practice stats.';
