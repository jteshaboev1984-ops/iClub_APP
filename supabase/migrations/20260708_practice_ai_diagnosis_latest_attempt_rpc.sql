-- Create AI diagnosis for the latest practice attempt of the authenticated user.
-- Safe: does not modify attempts, answers, ratings, certificates, or tours.

create or replace function public.create_latest_practice_ai_diagnosis()
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

  return public.create_practice_ai_diagnosis(v_attempt_id);
end;
$$;

revoke all on function public.create_latest_practice_ai_diagnosis() from public, anon;
grant execute on function public.create_latest_practice_ai_diagnosis() to authenticated;

comment on function public.create_latest_practice_ai_diagnosis() is
'Creates or returns a saved AI diagnosis snapshot for the authenticated user''s latest practice attempt. Does not modify score/history.';
