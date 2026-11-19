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
  v_archive_seasons jsonb := '[]'::jsonb;
  -- Closed/current Season 1 History preview while Season 2 has no approved
  -- Tour1 opening. NO S2 fresh-progress cutoff is applied for this snapshot.
  v_s1_start date;
  v_s1_status text;
  v_s1_cutoff timestamptz;
  v_s1_main integer := 0;
  v_s1_early_main integer := 0;
  v_s1_topic integer := 0;
  v_s1_early_topic integer := 0;
  v_s1_main_recent jsonb := '[]'::jsonb;
  v_s1_early_main_recent jsonb := '[]'::jsonb;
  v_s1_topic_recent jsonb := '[]'::jsonb;
  v_s1_early_topic_recent jsonb := '[]'::jsonb;
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

  -- Owner-approved season boundary: this SUBJECT'S officially scheduled Tour 1,
  -- NOT seasons.start_date and NOT Mathematics Tour 1 for other subjects.
  select t.start_date into v_start
  from public.seasons sn
  join public.tours t on t.season_id=sn.id
                     and t.subject_id=v_subject and t.tour_no=1
  where sn.season_no=2
    and sn.status in ('current','closed')
    and t.start_date is not null and t.end_date is not null
    and t.start_date <= t.end_date
  limit 1;
  -- In the Season 2 draft/future state, expose only the subject-owner's
  -- actual Season 1 and verifiably pre-Season1 records as a read-only
  -- History snapshot. The top-level period remains INACTIVE, so the
  -- original Practice stats and progress never inherit an S1 cutoff.
  if v_start is null or
     statement_timestamp() < (v_start::timestamp at time zone 'Asia/Tashkent')
  then
    select t.start_date,sn.status
      into v_s1_start,v_s1_status
    from public.seasons sn
    join public.tours t on t.season_id=sn.id
      and t.subject_id=v_subject and t.tour_no=1
    where sn.season_no=1 and sn.status in ('current','closed')
      and t.start_date is not null and t.end_date is not null
      and t.start_date<=t.end_date
    order by t.start_date asc limit 1;
    if v_s1_start is null or
       statement_timestamp() <
         (v_s1_start::timestamp at time zone 'Asia/Tashkent')
    then
      return jsonb_build_object(
        'ok',true,'subject_key',v_key,'season_no',2,
        'period_active',false,'reason','season_not_started'
      );
    end if;
    v_s1_cutoff := v_s1_start::timestamp at time zone 'Asia/Tashkent';

    select count(*) filter(where created_at>=v_s1_cutoff)::integer,
           count(*) filter(where created_at<v_s1_cutoff)::integer
      into v_s1_main,v_s1_early_main
    from public.practice_attempts
    where subject_id=v_subject and user_id=v_uid
      and coalesce(is_lab,false) is false;

    select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at desc,a.id desc),'[]'::jsonb)
      into v_s1_main_recent
    from (select id,score,percent,time_seconds,created_at
      from public.practice_attempts
      where subject_id=v_subject and user_id=v_uid
        and coalesce(is_lab,false) is false
        and created_at>=v_s1_cutoff
      order by created_at desc,id desc limit 20) a;

    select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at desc,a.id desc),'[]'::jsonb)
      into v_s1_early_main_recent
    from (select id,score,percent,time_seconds,created_at
      from public.practice_attempts
      where subject_id=v_subject and user_id=v_uid
        and coalesce(is_lab,false) is false
        and created_at<v_s1_cutoff
      order by created_at desc,id desc limit 20) a;

    select count(*) filter(where created_at>=v_s1_cutoff)::integer,
           count(*) filter(where created_at<v_s1_cutoff)::integer
      into v_s1_topic,v_s1_early_topic
    from public.practice_drill_sessions_v4
    where subject_id=v_subject and user_id=v_uid
      and status='finalized' and drill_type='rec_topic'
      and left(client_session_id,22)='practice_topic_choice_';

    select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
      into v_s1_topic_recent
    from (
      select q.id,q.topic,q.created_at,
             count(a.session_id)::integer as total,
             count(a.session_id) filter(where a.is_correct is true)::integer as correct
      from (
        select id,topic,created_at
        from public.practice_drill_sessions_v4
        where subject_id=v_subject and user_id=v_uid
          and status='finalized' and drill_type='rec_topic'
          and left(client_session_id,22)='practice_topic_choice_'
          and created_at>=v_s1_cutoff
        order by created_at desc,id desc limit 20
      ) q
      left join public.practice_drill_answers_v4 a on a.session_id=q.id
      group by q.id,q.topic,q.created_at
    ) t;

    select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
      into v_s1_early_topic_recent
    from (
      select q.id,q.topic,q.created_at,
             count(a.session_id)::integer as total,
             count(a.session_id) filter(where a.is_correct is true)::integer as correct
      from (
        select id,topic,created_at
        from public.practice_drill_sessions_v4
        where subject_id=v_subject and user_id=v_uid
          and status='finalized' and drill_type='rec_topic'
          and left(client_session_id,22)='practice_topic_choice_'
          and created_at<v_s1_cutoff
        order by created_at desc,id desc limit 20
      ) q
      left join public.practice_drill_answers_v4 a on a.session_id=q.id
      group by q.id,q.topic,q.created_at
    ) t;

    return jsonb_build_object(
      'ok',true,'subject_key',v_key,'season_no',2,
      'period_active',false,'reason','season_not_started',
      -- Subject-specific Practice stays in Season 1 despite Tour season
      -- being closed; only this subject's official S2 Tour1 start cuts it over.
      'practice_access',jsonb_build_object(
        'open_season_no',1,
        'season1_new_attempts_open',true,
        'season2_new_attempts_open',false
      ),
      'history_snapshot',jsonb_build_object(
        'ok',true,'subject_key',v_key,'season_no',1,
        'period_active',true,'period_status',v_s1_status,
        'practice_open',true,
        'period_starts_at',v_s1_cutoff,
        'main',jsonb_build_object(
          'attempts_count',v_s1_main,
          'archived_attempts_count',v_s1_early_main,
          'recent',v_s1_main_recent,'archived_recent',v_s1_early_main_recent
        ),
        'topic',jsonb_build_object(
          'sessions_count',v_s1_topic,
          'archived_sessions_count',v_s1_early_topic,
          'recent',v_s1_topic_recent,'archived_recent',v_s1_early_topic_recent
        ),
        'archive_seasons',case when v_s1_early_main+v_s1_early_topic>0
        then jsonb_build_array(jsonb_build_object(
          'key','legacy',
          'main',jsonb_build_object(
            'attempts_count',v_s1_early_main,'recent',v_s1_early_main_recent),
          'topic',jsonb_build_object(
            'sessions_count',v_s1_early_topic,'recent',v_s1_early_topic_recent)
        )) else '[]'::jsonb end
      )
    );
  end if;

  -- Valid Season 2 period exists only after its official Tour1 boundary.
  -- Tour1 can be closed; do not retroactively unset its verified cutoff.
  v_cutoff := v_start::timestamp at time zone 'Asia/Tashkent';

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


  -- Verified per-subject prior periods for a compact Season swipe control.
  -- Only published/closed Tour1 calendar boundaries may establish a season.
  -- Pre-first-season attempts use an explicitly labeled legacy bucket; never
  -- pretend they belonged to Season 1. Empty buckets are not swipe choices.
  -- This preserves the existing archive totals and owner read-only scope.
  with recognized as (
    select distinct on (sn.season_no)
      sn.season_no,
      (t.start_date::timestamp at time zone 'Asia/Tashkent') as lower_cutoff
    from public.seasons sn
    join public.tours t on t.season_id=sn.id
      and t.subject_id=v_subject and t.tour_no=1
    where sn.season_no < 2
      and sn.status in ('current','closed')
      and t.start_date is not null and t.end_date is not null
      and t.start_date<=t.end_date and t.start_date<v_start
    order by sn.season_no,t.start_date asc
  ), boundaries as (
    select ('season-'||r.season_no)::text as bucket_key,
           r.season_no, r.lower_cutoff,
           lead(r.lower_cutoff,1,v_cutoff) over (order by r.lower_cutoff,r.season_no)
             as upper_cutoff
    from recognized r
  ), buckets as (
    select bucket_key,season_no,lower_cutoff,upper_cutoff from boundaries
    union all
    select 'legacy'::text,null::integer,null::timestamptz,min(lower_cutoff)
    from recognized having min(lower_cutoff) is not null
    union all
    select 'previous'::text,null::integer,null::timestamptz,v_cutoff
    where not exists (select 1 from recognized)
  ), summarized as (
    select b.*,
      (select count(*)::integer from public.practice_attempts pa
        where pa.user_id=v_uid and pa.subject_id=v_subject
          and coalesce(pa.is_lab,false) is false
          and pa.created_at < b.upper_cutoff
          and (b.lower_cutoff is null or pa.created_at>=b.lower_cutoff)) as main_count,
      (select coalesce(jsonb_agg(to_jsonb(m.*) order by m.created_at desc,m.id desc),'[]'::jsonb)
        from (select pa.id,pa.score,pa.percent,pa.time_seconds,pa.created_at
          from public.practice_attempts pa
          where pa.user_id=v_uid and pa.subject_id=v_subject
            and coalesce(pa.is_lab,false) is false
            and pa.created_at < b.upper_cutoff
            and (b.lower_cutoff is null or pa.created_at>=b.lower_cutoff)
          order by pa.created_at desc,pa.id desc limit 20) m) as main_recent,
      (select count(*)::integer from public.practice_drill_sessions_v4 sd
        where sd.user_id=v_uid and sd.subject_id=v_subject
          and sd.status='finalized' and sd.drill_type='rec_topic'
          and left(sd.client_session_id,22)='practice_topic_choice_'
          and sd.created_at < b.upper_cutoff
          and (b.lower_cutoff is null or sd.created_at>=b.lower_cutoff)) as topic_count,
      (select coalesce(jsonb_agg(to_jsonb(t.*) order by t.created_at desc,t.id desc),'[]'::jsonb)
        from (
          select sd.id,sd.topic,sd.created_at,
            count(a.session_id)::integer as total,
            count(a.session_id) filter(where a.is_correct is true)::integer as correct
          from (
            select ss.id,ss.topic,ss.created_at
            from public.practice_drill_sessions_v4 ss
            where ss.user_id=v_uid and ss.subject_id=v_subject
              and ss.status='finalized' and ss.drill_type='rec_topic'
              and left(ss.client_session_id,22)='practice_topic_choice_'
              and ss.created_at < b.upper_cutoff
              and (b.lower_cutoff is null or ss.created_at>=b.lower_cutoff)
            order by ss.created_at desc,ss.id desc limit 20
          ) sd
          left join public.practice_drill_answers_v4 a on a.session_id=sd.id
          group by sd.id,sd.topic,sd.created_at
          order by sd.created_at desc,sd.id desc
        ) t) as topic_recent
    from buckets b
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'key',z.bucket_key,'season_no',z.season_no,
    'main',jsonb_build_object('attempts_count',z.main_count,'recent',z.main_recent),
    'topic',jsonb_build_object('sessions_count',z.topic_count,'recent',z.topic_recent)
  ) order by z.lower_cutoff desc nulls last),'[]'::jsonb)
  into v_archive_seasons
  from summarized z where z.main_count+z.topic_count>0;

  return jsonb_build_object(
    'ok',true,'subject_key',v_key,'season_no',2,'period_active',true,
    -- S1 is now historical only. Same published question pool may be
    -- served in S2, but all NEW attempts belong to the fresh S2 period.
    'practice_access',jsonb_build_object(
      'open_season_no',2,
      'season1_new_attempts_open',false,
      'season2_new_attempts_open',true
    ),
    'period_starts_at',v_cutoff,
    'archive_seasons',v_archive_seasons,
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
