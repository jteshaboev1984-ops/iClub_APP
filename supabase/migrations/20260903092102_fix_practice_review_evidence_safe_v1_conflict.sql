create or replace function public.record_practice_review_opened_safe_v1(p_attempt_id bigint)
returns table(attempt_id bigint, recorded boolean, first_opened_at timestamptz, last_opened_at timestamptz, open_count integer)
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_row public.practice_review_events_v1%rowtype;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  if p_attempt_id is null or p_attempt_id <= 0 then
    raise exception 'invalid_attempt_id' using errcode='22023';
  end if;

  if not exists(
    select 1 from public.practice_attempts pa
    where pa.id=p_attempt_id
      and pa.user_id=v_uid
      and coalesce(pa.is_lab,false)=false
  ) then
    raise exception 'practice_attempt_not_found' using errcode='P0002';
  end if;

  insert into public.practice_review_events_v1(user_id,attempt_id)
  values(v_uid,p_attempt_id)
  on conflict on constraint practice_review_events_v1_user_id_attempt_id_key do update
    set last_opened_at=now(),
        open_count=public.practice_review_events_v1.open_count+1
  returning * into v_row;

  return query select v_row.attempt_id, true, v_row.first_opened_at, v_row.last_opened_at, v_row.open_count;
end;
$function$;

revoke all on function public.record_practice_review_opened_safe_v1(bigint) from public, anon;
grant execute on function public.record_practice_review_opened_safe_v1(bigint) to authenticated, service_role;
