-- #574 · PREVIEW CANDIDATE ONLY, not installed on production.
-- New visible Practice period at Season 2, preserving all history.
-- Different from bank_generation: fresh progress is NOT bank republishing.
-- Read-only summary for owned attempts and finalized topic sessions across all 5 subjects.
-- Cutover is the published season's calendar start, midnight Asia/Tashkent.
-- Draft/undated/future season never triggers an artificial progress reset.
-- No UPDATE, DELETE, INSERT, truncation, key access or scoring changes.
begin;

create or replace function public.get_practice_season2_progress_safe_v1(
  p_subject_key text
) returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $practice_season2$
declare
  v_uid uuid := auth.uid();
  v_key text := lower(trim(coalesce(p_subject_key,'')));
  v_subject bigint;
  v_start date;
  v_cutoff timestamptz;
  v_prior_main integer := 0;
  v_current_main integer := 0;
  v_prior_topic integer := 0;
  v_current_topic integer := 0;
  v_best jsonb;
  v_recent jsonb := '[]'::jsonb;
  v_archived_recent jsonb := '[]'::jsonb;
  v_topic_recent jsonb := '[]'::jsonb;
  v_topic_archive jsonb := '[]'::jsonb;
  v_topic_correct integer := 0;
  v_topic_answered integer := 0;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  select id into v_subject
  from public.subjects
  where subject_key=v_key and is_active is true
  limit 1;
  if v_subject is null then
    raise exception 'subject_not_found' using errcode='P0002';
  end if;

  select start_date into v_start
  from public.seasons
  where season_no=2
    and status in ('current','closed')
    and start_date is not null
  limit 1;
  if v_start is null then
    return jsonb_build_object(
      'ok',true,'subject_key',v_key,'season_no',2,
      'period_active',false,'reason','season_not_started'
    );
  end if;

  -- Explicit local season boundary, including cross-midnight Tashkent cases.
  v_cutoff := v_start::timestamp at time zone 'Asia/Tashkent';
  if statement_timestamp() < v_cutoff then
    return jsonb_build_object(
      'ok',true,'subject_key',v_key,'season_no',2,
      'period_active',false,'reason','season_not_started'
    );
  end if;

  select count(*) filter(where created_at < v_cutoff)::integer,
         count(*) filter(where created_at >= v_cutoff)::integer
  into v_prior_main,v_current_main
  from public.practice_attempts
  where subject_id=v_subject and user_id=v_uid
    and coalesce(is_lab,false) is false;

  select to_jsonb(t.*) into v_best from (
    select id,score,percent,time_seconds,created_at
    from public.practice_attempts
    where subject_id=v_subject and user_id=v_uid
      and coalesce(is_lab,false) is false and created_at>=v_cutoff
    order by percent desc nulls last, time_seconds asc nulls last,
             created_at desc,id desc
    limit 1
  ) t;

  select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
  into v_recent
  from (
    select id,score,percent,time_seconds,created_at
    from public.practice_attempts
    where subject_id=v_subject and user_id=v_uid
      and coalesce(is_lab,false) is false and created_at>=v_cutoff
    order by created_at desc,id desc limit 20
  ) t;

  select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
  into v_archived_recent
  from (
    select id,score,percent,time_seconds,created_at
    from public.practice_attempts
    where subject_id=v_subject and user_id=v_uid
      and coalesce(is_lab,false) is false and created_at<v_cutoff
    order by created_at desc,id desc limit 20
  ) t;

  select count(*) filter(where created_at < v_cutoff)::integer,
         count(*) filter(where created_at >= v_cutoff)::integer
  into v_prior_topic,v_current_topic
  from public.practice_drill_sessions_v4
  where subject_id=v_subject and user_id=v_uid
    and status='finalized' and drill_type='rec_topic'
    and left(client_session_id,22)='practice_topic_choice_';

  select coalesce(sum(case when a.is_correct is true then 1 else 0 end),0)::integer,
         count(a.id)::integer
  into v_topic_correct,v_topic_answered
  from public.practice_drill_sessions_v4 s
  join public.practice_drill_answers_v4 a on a.session_id=s.id
  where s.subject_id=v_subject and s.user_id=v_uid and s.created_at>=v_cutoff
    and s.status='finalized' and s.drill_type='rec_topic'
    and left(s.client_session_id,22)='practice_topic_choice_';

  -- Read-only, bounded records for the same 3+5 disclosure used in Exam Prep.
  -- They are samples of at most 20, NOT cursor pagination or full archive.
  select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
  into v_topic_recent
  from (
    select s.id,s.topic,s.created_at,
           count(a.session_id)::integer as total,
           count(a.session_id) filter(where a.is_correct is true)::integer as correct
    from (
      select id,topic,created_at
      from public.practice_drill_sessions_v4
      where subject_id=v_subject and user_id=v_uid and created_at>=v_cutoff
        and status='finalized' and drill_type='rec_topic'
        and left(client_session_id,22)='practice_topic_choice_'
      order by created_at desc,id desc limit 20
    ) s
    left join public.practice_drill_answers_v4 a on a.session_id=s.id
    group by s.id,s.topic,s.created_at
    order by s.created_at desc,s.id desc
  ) t;

  select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
  into v_topic_archive
  from (
    select s.id,s.topic,s.created_at,
           count(a.session_id)::integer as total,
           count(a.session_id) filter(where a.is_correct is true)::integer as correct
    from (
      select id,topic,created_at
      from public.practice_drill_sessions_v4
      where subject_id=v_subject and user_id=v_uid and created_at<v_cutoff
        and status='finalized' and drill_type='rec_topic'
        and left(client_session_id,22)='practice_topic_choice_'
      order by created_at desc,id desc limit 20
    ) s
    left join public.practice_drill_answers_v4 a on a.session_id=s.id
    group by s.id,s.topic,s.created_at
    order by s.created_at desc,s.id desc
  ) t;

  return jsonb_build_object(
    'ok',true,'subject_key',v_key,'season_no',2,'period_active',true,
    'period_starts_at',v_cutoff,
    'main',jsonb_build_object(
      'attempts_count',coalesce(v_current_main,0),
      'archived_attempts_count',coalesce(v_prior_main,0),
      'best',v_best,'recent',v_recent,'archived_recent',v_archived_recent
    ),
    'topic',jsonb_build_object(
      'sessions_count',coalesce(v_current_topic,0),
      'archived_sessions_count',coalesce(v_prior_topic,0),
      'correct',coalesce(v_topic_correct,0),
      'answered',coalesce(v_topic_answered,0),
      'recent',v_topic_recent,'archived_recent',v_topic_archive
    )
  );
end
$practice_season2$;

revoke all on function public.get_practice_season2_progress_safe_v1(text)
  from public,anon;
grant execute on function public.get_practice_season2_progress_safe_v1(text)
  to authenticated;

comment on function public.get_practice_season2_progress_safe_v1(text) is
'Read-only user-owned Season 2 Practice progress. Season 1 and legacy records are retained, not reset. Bank generations and Tour results are independent.';

commit;
