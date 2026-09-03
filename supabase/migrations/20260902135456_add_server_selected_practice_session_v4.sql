-- Production-applied Supabase migration 20260902135456 / add_server_selected_practice_session_v4.
-- Server selects the same Practice mix as legacy UI: up to 10 unanswered questions, target 3 easy / 5 medium / 2 hard.
-- Correctly answered questions are excluded; future/unpublished Practice stages remain locked.

create or replace function public.start_practice_session_auto_safe_v4(
  p_pool_id bigint,
  p_client_session_id text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_pool public.practice_pools%rowtype;
  v_s public.practice_sessions_v4%rowtype;
  v_season_id bigint;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
  v_total_tours integer := 0;
  v_closed_count integer := 0;
  v_max_pool_tour integer := 1;
  v_current_tour integer := 1;
  v_active_tour integer;
  v_target_tour public.tours%rowtype;
  v_easy bigint[] := '{}'::bigint[];
  v_medium bigint[] := '{}'::bigint[];
  v_hard bigint[] := '{}'::bigint[];
  v_qids bigint[] := '{}'::bigint[];
  v_needed integer := 0;
  v_open_count integer := 0;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  if p_pool_id is null or p_pool_id <= 0 then raise exception 'invalid_pool_id' using errcode='22023'; end if;
  if p_client_session_id is null or length(trim(p_client_session_id)) not between 8 and 128 then raise exception 'invalid_client_session_id' using errcode='22023'; end if;

  select * into v_s from public.practice_sessions_v4 s where s.user_id=v_uid and s.client_session_id=trim(p_client_session_id) limit 1;
  if v_s.id is not null then
    if v_s.pool_id <> p_pool_id then raise exception 'client_session_scope_mismatch' using errcode='22023'; end if;
    return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'question_count',cardinality(v_s.question_ids),'legacy_attempt_id',v_s.legacy_attempt_id,'resumed',true);
  end if;

  select * into v_pool from public.practice_pools p where p.id=p_pool_id and p.is_active is true;
  if v_pool.id is null then raise exception 'pool_not_found_or_inactive' using errcode='P0002'; end if;

  select s.id into v_season_id from public.seasons s where s.status='current' order by s.season_no desc limit 1;
  if v_season_id is null then select s.id into v_season_id from public.seasons s where s.season_no=1 order by s.id limit 1; end if;
  if v_season_id is null then raise exception 'season_not_found' using errcode='P0002'; end if;

  select greatest(1,coalesce(max(p.tour_no),1)) into v_max_pool_tour from public.practice_pools p where p.subject_id=v_pool.subject_id and p.is_active is true;

  select count(*)::integer,
         count(*) filter(where t.end_date is not null and t.end_date < v_today)::integer
    into v_total_tours,v_closed_count
  from public.tours t
  where t.subject_id=v_pool.subject_id and t.season_id=v_season_id;

  select t.tour_no into v_active_tour
  from public.tours t
  where t.subject_id=v_pool.subject_id and t.season_id=v_season_id and t.is_active is true
    and t.start_date is not null and t.end_date is not null and v_today between t.start_date and t.end_date
  order by t.tour_no limit 1;

  if v_active_tour is not null then
    v_current_tour := v_active_tour;
  elsif v_total_tours > 0 and v_closed_count >= v_total_tours then
    v_current_tour := least(v_max_pool_tour,v_total_tours);
  else
    v_current_tour := least(v_max_pool_tour,greatest(1,v_closed_count+1));
  end if;

  select * into v_target_tour
  from public.tours t
  where t.subject_id=v_pool.subject_id and t.season_id=v_season_id and t.tour_no=v_pool.tour_no
  order by t.id limit 1;

  if v_target_tour.id is not null then
    if v_target_tour.start_date is null or v_target_tour.end_date is null then raise exception 'practice_pool_not_published' using errcode='55000'; end if;
    if v_target_tour.start_date > v_today then raise exception 'practice_pool_locked' using errcode='55000'; end if;
  elsif v_pool.tour_no > v_current_tour then
    raise exception 'practice_pool_locked' using errcode='55000';
  end if;

  with open_questions as (
    select q.id,
           case lower(coalesce(q.difficulty,'medium')) when 'easy' then 'easy' when 'hard' then 'hard' else 'medium' end as diff
    from public.practice_pool_questions ppq
    join public.questions q on q.id=ppq.question_id and q.is_active is true and q.subject_id=v_pool.subject_id
    where ppq.pool_id=v_pool.id and ppq.is_active is true
      and not exists (
        select 1 from public.practice_answers pa
        join public.practice_attempts pat on pat.id=pa.attempt_id and pat.user_id=v_uid and pat.subject_id=v_pool.subject_id
        where pa.question_id=q.id and pa.is_correct is true
      )
  )
  select count(*)::integer into v_open_count from open_questions;

  if v_open_count <= 0 then raise exception 'practice_no_open_questions' using errcode='55000'; end if;

  select coalesce(array_agg(id),'{}'::bigint[]) into v_easy from (
    select q.id
    from public.practice_pool_questions ppq
    join public.questions q on q.id=ppq.question_id and q.is_active is true and q.subject_id=v_pool.subject_id
    where ppq.pool_id=v_pool.id and ppq.is_active is true and lower(coalesce(q.difficulty,'medium'))='easy'
      and not exists (select 1 from public.practice_answers pa join public.practice_attempts pat on pat.id=pa.attempt_id and pat.user_id=v_uid and pat.subject_id=v_pool.subject_id where pa.question_id=q.id and pa.is_correct is true)
    order by random() limit 3
  ) s;

  select coalesce(array_agg(id),'{}'::bigint[]) into v_medium from (
    select q.id
    from public.practice_pool_questions ppq
    join public.questions q on q.id=ppq.question_id and q.is_active is true and q.subject_id=v_pool.subject_id
    where ppq.pool_id=v_pool.id and ppq.is_active is true and lower(coalesce(q.difficulty,'medium')) not in ('easy','hard')
      and not exists (select 1 from public.practice_answers pa join public.practice_attempts pat on pat.id=pa.attempt_id and pat.user_id=v_uid and pat.subject_id=v_pool.subject_id where pa.question_id=q.id and pa.is_correct is true)
    order by random() limit 5
  ) s;

  select coalesce(array_agg(id),'{}'::bigint[]) into v_hard from (
    select q.id
    from public.practice_pool_questions ppq
    join public.questions q on q.id=ppq.question_id and q.is_active is true and q.subject_id=v_pool.subject_id
    where ppq.pool_id=v_pool.id and ppq.is_active is true and lower(coalesce(q.difficulty,'medium'))='hard'
      and not exists (select 1 from public.practice_answers pa join public.practice_attempts pat on pat.id=pa.attempt_id and pat.user_id=v_uid and pat.subject_id=v_pool.subject_id where pa.question_id=q.id and pa.is_correct is true)
    order by random() limit 2
  ) s;

  v_qids := coalesce(v_easy,'{}'::bigint[]) || coalesce(v_medium,'{}'::bigint[]) || coalesce(v_hard,'{}'::bigint[]);
  v_needed := least(10,v_open_count) - coalesce(cardinality(v_qids),0);

  if v_needed > 0 then
    v_qids := v_qids || coalesce((
      select array_agg(id) from (
        select q.id
        from public.practice_pool_questions ppq
        join public.questions q on q.id=ppq.question_id and q.is_active is true and q.subject_id=v_pool.subject_id
        where ppq.pool_id=v_pool.id and ppq.is_active is true and not (q.id=any(v_qids))
          and not exists (select 1 from public.practice_answers pa join public.practice_attempts pat on pat.id=pa.attempt_id and pat.user_id=v_uid and pat.subject_id=v_pool.subject_id where pa.question_id=q.id and pa.is_correct is true)
        order by random() limit v_needed
      ) r
    ),'{}'::bigint[]);
  end if;

  select coalesce(array_agg(x.qid order by case lower(coalesce(q.difficulty,'medium')) when 'easy' then 1 when 'hard' then 3 else 2 end, x.ord),'{}'::bigint[])
    into v_qids
  from unnest(v_qids) with ordinality x(qid,ord)
  join public.questions q on q.id=x.qid;

  if coalesce(cardinality(v_qids),0) not between 1 and 10 then raise exception 'practice_question_selection_failed' using errcode='55000'; end if;

  insert into public.practice_sessions_v4(user_id,subject_id,pool_id,client_session_id,question_ids)
  values(v_uid,v_pool.subject_id,v_pool.id,trim(p_client_session_id),v_qids)
  returning * into v_s;

  return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'question_count',cardinality(v_s.question_ids),'legacy_attempt_id',null,'resumed',false);
exception when unique_violation then
  select * into v_s from public.practice_sessions_v4 s where s.user_id=v_uid and s.client_session_id=trim(p_client_session_id) limit 1;
  if v_s.id is null then raise; end if;
  if v_s.pool_id <> p_pool_id then raise exception 'client_session_scope_mismatch' using errcode='22023'; end if;
  return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'question_count',cardinality(v_s.question_ids),'legacy_attempt_id',v_s.legacy_attempt_id,'resumed',true);
end;
$function$;

revoke all on function public.start_practice_session_auto_safe_v4(bigint,text) from public, anon;
grant execute on function public.start_practice_session_auto_safe_v4(bigint,text) to authenticated, service_role;
revoke all on function public.start_practice_session_safe_v4(bigint,text,bigint[]) from public, anon, authenticated;
grant execute on function public.start_practice_session_safe_v4(bigint,text,bigint[]) to service_role;
