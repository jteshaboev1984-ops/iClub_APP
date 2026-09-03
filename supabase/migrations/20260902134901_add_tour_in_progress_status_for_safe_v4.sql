-- Production-applied Supabase migration 20260902134901 / add_tour_in_progress_status_for_safe_v4.
-- Prevents an unfinished safe Tour attempt from appearing as a submitted 0-score attempt.

alter table public.tour_attempts drop constraint if exists tour_attempts_status_check;
alter table public.tour_attempts add constraint tour_attempts_status_check
check (status = any (array['in_progress'::text,'submitted'::text,'time_expired'::text,'anti_cheat'::text,'abandoned'::text]));

create or replace function public.start_tour_attempt_safe_v4(
  p_tour_id bigint,
  p_client_session_id text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_tour public.tours%rowtype;
  v_attempt public.tour_attempts%rowtype;
  v_rt public.tour_session_runtime_v4%rowtype;
  v_qids bigint[];
  v_attempt_id bigint;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  if p_tour_id is null or p_tour_id <= 0 then raise exception 'invalid_tour_id' using errcode='22023'; end if;
  if p_client_session_id is null or length(trim(p_client_session_id)) not between 8 and 128 then raise exception 'invalid_client_session_id' using errcode='22023'; end if;

  select * into v_rt
  from public.tour_session_runtime_v4 r
  where r.user_id=v_uid and r.client_session_id=trim(p_client_session_id)
  limit 1;

  if v_rt.attempt_id is not null then
    if v_rt.tour_id <> p_tour_id then raise exception 'client_session_scope_mismatch' using errcode='22023'; end if;
    return jsonb_build_object('attempt_id',v_rt.attempt_id,'question_count',cardinality(v_rt.question_ids),'finalized',v_rt.finalized_at is not null,'resumed',true);
  end if;

  select * into v_tour from public.tours t where t.id=p_tour_id and t.is_active is true;
  if v_tour.id is null then raise exception 'tour_not_found_or_inactive' using errcode='P0002'; end if;
  if v_tour.start_date is null or v_tour.end_date is null or v_today < v_tour.start_date or v_today > v_tour.end_date then raise exception 'tour_not_open' using errcode='55000'; end if;
  if not exists(select 1 from public.users u where u.id=v_uid and coalesce(u.is_school_student,false) is true) then raise exception 'tour_requires_school_student' using errcode='42501'; end if;
  if not exists(select 1 from public.user_subjects us where us.user_id=v_uid and us.subject_id=v_tour.subject_id and us.mode='competitive') then raise exception 'tour_subject_not_competitive_for_user' using errcode='42501'; end if;

  select * into v_attempt from public.tour_attempts a where a.user_id=v_uid and a.tour_id=p_tour_id limit 1;
  if v_attempt.id is not null then
    select * into v_rt from public.tour_session_runtime_v4 r where r.attempt_id=v_attempt.id and r.user_id=v_uid;
    if v_rt.attempt_id is not null and v_rt.finalized_at is null and v_attempt.status='in_progress' then
      return jsonb_build_object('attempt_id',v_rt.attempt_id,'question_count',cardinality(v_rt.question_ids),'finalized',false,'resumed',true);
    end if;
    raise exception 'already_attempted' using errcode='23505';
  end if;

  select array_agg(tq.question_id order by tq.order_no,tq.id) into v_qids
  from public.tour_questions tq
  join public.questions q on q.id=tq.question_id and q.is_active is true
  where tq.tour_id=p_tour_id and tq.is_active is true and q.subject_id=v_tour.subject_id;

  if coalesce(cardinality(v_qids),0) <> 20 then raise exception 'tour_question_count_not_20' using errcode='55000'; end if;

  insert into public.tour_attempts(user_id,tour_id,score,percent,total_time,status)
  values(v_uid,p_tour_id,0,0,0,'in_progress')
  returning id into v_attempt_id;

  insert into public.tour_session_runtime_v4(attempt_id,user_id,tour_id,client_session_id,question_ids)
  values(v_attempt_id,v_uid,p_tour_id,trim(p_client_session_id),v_qids);

  return jsonb_build_object('attempt_id',v_attempt_id,'question_count',20,'finalized',false,'resumed',false);
exception when unique_violation then
  select * into v_attempt from public.tour_attempts a where a.user_id=v_uid and a.tour_id=p_tour_id limit 1;
  if v_attempt.id is null then raise; end if;
  select * into v_rt from public.tour_session_runtime_v4 r where r.attempt_id=v_attempt.id and r.user_id=v_uid;
  if v_rt.attempt_id is null or v_rt.finalized_at is not null or v_attempt.status <> 'in_progress' then raise exception 'already_attempted' using errcode='23505'; end if;
  return jsonb_build_object('attempt_id',v_rt.attempt_id,'question_count',cardinality(v_rt.question_ids),'finalized',false,'resumed',true);
end;
$function$;

revoke all on function public.start_tour_attempt_safe_v4(bigint,text) from public, anon;
grant execute on function public.start_tour_attempt_safe_v4(bigint,text) to authenticated, service_role;
