-- iClub Practice topic catalog v1: read-only, learner-scoped navigation metadata.
-- No historical data changes, no new answer access, no Tour state changes.
-- Mirrors the eligibility gate of start_practice_topic_drill_safe_v5.
create or replace function public.get_practice_available_topics_safe_v1(p_subject_key text)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_subject_id bigint;
  v_is_math boolean := false;
  v_allow_legacy_math boolean := false;
  v_season_id bigint;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
  v_current_tour integer := 1;
  v_active_tour integer;
  v_total_tours integer := 0;
  v_closed_count integer := 0;
  v_max_pool_tour integer := 1;
  v_topics jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  if nullif(trim(coalesce(p_subject_key,'')),'') is null then
    raise exception 'invalid_subject_key' using errcode='22023';
  end if;

  select s.id,(s.subject_key='mathematics')
    into v_subject_id,v_is_math
    from public.subjects s
   where s.subject_key=trim(p_subject_key)
     and s.is_active is true
   limit 1;

  if v_subject_id is null then
    raise exception 'subject_not_found' using errcode='P0002';
  end if;

  -- Respect the existing one-time Mathematics Practice v2 publication/rollback.
  -- Do not display metadata-less legacy Mathematics items before cutover.
  if v_is_math then
    select exists(
      select 1 from private.practice_v2_question_meta m
      join public.questions q on q.id=m.question_id
      where q.subject_id=v_subject_id
        and m.release_version='math_p1_practice_v2_2026_10_07'
        and m.lifecycle_state='published'
        and m.is_runtime_allowed is false
    ) into v_allow_legacy_math;
  end if;

  select s.id into v_season_id from public.seasons s
   where s.status='current' order by s.season_no desc limit 1;
  if v_season_id is null then
    select s.id into v_season_id from public.seasons s
     where s.season_no=1 order by s.id limit 1;
  end if;
  if v_season_id is null then
    raise exception 'season_not_found' using errcode='P0002';
  end if;

  select greatest(1,coalesce(max(p.tour_no),1))
    into v_max_pool_tour from public.practice_pools p
   where p.subject_id=v_subject_id and p.is_active is true;

  select count(*)::integer,
         count(*) filter(where t.end_date is not null and t.end_date < v_today)::integer
    into v_total_tours,v_closed_count
    from public.tours t
   where t.subject_id=v_subject_id and t.season_id=v_season_id;

  select t.tour_no into v_active_tour from public.tours t
   where t.subject_id=v_subject_id and t.season_id=v_season_id
     and t.is_active is true and t.start_date is not null
     and t.end_date is not null
     and v_today between t.start_date and t.end_date
   order by t.tour_no limit 1;

  if v_active_tour is not null then
    v_current_tour := v_active_tour;
  elsif v_total_tours > 0 and v_closed_count >= v_total_tours then
    v_current_tour := least(v_max_pool_tour,v_total_tours);
  else
    v_current_tour := least(v_max_pool_tour,greatest(1,v_closed_count+1));
  end if;

  with eligible as (
    select distinct q.id,trim(q.topic) as topic
    from public.practice_pools p
    join public.practice_pool_questions ppq
      on ppq.pool_id=p.id and ppq.is_active is true
    join public.questions q
      on q.id=ppq.question_id and q.is_active is true
       and q.subject_id=v_subject_id
    left join public.tours t
      on t.subject_id=v_subject_id and t.season_id=v_season_id
       and t.tour_no=p.tour_no
    left join private.practice_v2_question_meta m on m.question_id=q.id
    where p.subject_id=v_subject_id and p.is_active is true
      and nullif(trim(q.topic),'') is not null
      and length(q.topic)<=200
      and (
        (t.id is not null and t.is_active is true
         and t.start_date is not null and t.end_date is not null
         and t.start_date <= v_today)
        or (t.id is null and p.tour_no<=v_current_tour)
      )
      and (
        ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
        or (m.lifecycle_state='published' and m.is_runtime_allowed is true)
      )
      and not public.iclub_practice_drill_question_protected_v4(q.id)
  ), grouped as (
    select e.topic,count(*)::integer as question_count
      from eligible e group by e.topic
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'topic',g.topic,'question_count',g.question_count
  ) order by lower(g.topic),g.topic),'[]'::jsonb)
    into v_topics from grouped g;

  return jsonb_build_object('ok',true,'subject_key',trim(p_subject_key),
                             'topics',v_topics);
end;
$function$;

revoke all on function public.get_practice_available_topics_safe_v1(text) from public;
revoke all on function public.get_practice_available_topics_safe_v1(text) from anon;
grant execute on function public.get_practice_available_topics_safe_v1(text)
  to authenticated,service_role;
