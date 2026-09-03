create or replace function public.iclub_preview_credential_evidence_v1(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_now timestamptz := now();
  v_consistent_days integer := 0;
  v_latest_subject text := null;
  v_focused_streak integer := 0;
  v_video_decided integer := 0;
  v_video_completed integer := 0;
  v_video_rate numeric := 0;
  v_research_opens integer := 0;
  v_research_days integer := 0;
  v_tours integer := 0;
  v_critical boolean := false;
  v_mastery jsonb := '{}'::jsonb;
  v_error_existing jsonb := null;
begin
  if p_user_id is null then
    raise exception 'invalid_user_id' using errcode='22023';
  end if;

  select count(distinct (ae.created_at at time zone 'Asia/Tashkent')::date)::integer
    into v_consistent_days
  from public.app_events ae
  where ae.user_id=p_user_id
    and ae.created_at >= v_now - interval '14 days'
    and ae.event_type in (
      'video_opened','video_completed','video_skipped',
      'practice_attempt_finished','tour_attempt_finished',
      'resource_opened','recommendation_opened'
    );

  with e as (
    select ae.id, ae.created_at, nullif(ae.payload->>'subject_id','') as subject_id,
           row_number() over(order by ae.created_at desc, ae.id desc) as rn
    from public.app_events ae
    where ae.user_id=p_user_id
      and ae.event_type in ('video_completed','practice_attempt_finished','tour_attempt_finished')
      and nullif(ae.payload->>'subject_id','') is not null
  ), latest as (
    select subject_id from e where rn=1
  ), boundary as (
    select min(e.rn) as first_other
    from e cross join latest l
    where e.subject_id is distinct from l.subject_id
  )
  select l.subject_id,
         case
           when l.subject_id is null then 0
           when b.first_other is null then (select count(*) from e)
           else greatest(0,b.first_other-1)
         end::integer
    into v_latest_subject, v_focused_streak
  from (select (select subject_id from latest) as subject_id) l
  cross join (select (select first_other from boundary) as first_other) b;

  with d as (
    select distinct on (nullif(ae.payload->>'lesson_id',''))
           nullif(ae.payload->>'lesson_id','') as lesson_id,
           ae.event_type
    from public.app_events ae
    where ae.user_id=p_user_id
      and ae.event_type in ('video_completed','video_skipped')
      and nullif(ae.payload->>'lesson_id','') is not null
    order by nullif(ae.payload->>'lesson_id',''), ae.created_at desc, ae.id desc
  )
  select count(*)::integer,
         count(*) filter (where event_type='video_completed')::integer
    into v_video_decided, v_video_completed
  from d;
  v_video_rate := case when v_video_decided>0 then v_video_completed::numeric/v_video_decided else 0 end;

  with ranked as (
    select pa.subject_id, pa.percent,
           row_number() over(partition by pa.subject_id order by pa.created_at desc, pa.id desc) as rn
    from public.practice_attempts pa
    where pa.user_id=p_user_id
      and coalesce(pa.is_lab,false)=false
  ), a as (
    select subject_id,
           count(*)::integer as attempts_count,
           max(percent)::numeric as best_percent,
           percentile_cont(0.5) within group(order by percent)::numeric as median_percent
    from ranked
    where rn<=30
    group by subject_id
  )
  select coalesce(jsonb_object_agg(subject_id::text,
    jsonb_build_object(
      'attempts_count',attempts_count,
      'best_percent',coalesce(best_percent,0),
      'median_percent',coalesce(median_percent,0),
      'active',(attempts_count>=8 and best_percent>=80 and median_percent>=70)
    )), '{}'::jsonb)
    into v_mastery
  from a;

  select count(*)::integer,
         count(distinct (ae.created_at at time zone 'Asia/Tashkent')::date)::integer
    into v_research_opens, v_research_days
  from public.app_events ae
  where ae.user_id=p_user_id
    and ae.event_type in ('resource_opened','recommendation_opened');

  select count(*)::integer into v_tours
  from public.tour_attempts ta
  where ta.user_id=p_user_id;

  select exists(
    select 1 from public.app_events ae
    where ae.user_id=p_user_id
      and ae.event_type='anti_cheat_event'
      and lower(coalesce(ae.payload->>'severity',''))='critical'
  ) into v_critical;

  select uc.evidence_snapshot into v_error_existing
  from public.user_credentials uc
  join public.credential_definitions cd on cd.id=uc.credential_id
  where uc.user_id=p_user_id and cd.code='error_driven_learner'
  limit 1;

  return jsonb_build_object(
    'computed_at',v_now,
    'consistent_learner',jsonb_build_object('active_days_14d',v_consistent_days,'rule_active',v_consistent_days>=7),
    'focused_study_streak',jsonb_build_object('current_subject_id',v_latest_subject,'focused_sessions_in_row',v_focused_streak,'rule_active',v_focused_streak>=5),
    'active_video_learner',jsonb_build_object('videos_decided',v_video_decided,'videos_completed',v_video_completed,'completion_rate',round(v_video_rate,3),'rule_active',(v_video_decided>=10 and v_video_rate>=0.70),'canonical_signal_present',v_video_decided>0),
    'practice_mastery_subject',jsonb_build_object('by_subject',v_mastery),
    'error_driven_learner',jsonb_build_object('canonical_ready',false,'reason','historical_review_events_missing_db_attempt_id','existing_evidence',coalesce(v_error_existing,'{}'::jsonb)),
    'research_oriented_learner',jsonb_build_object('resource_opens_total',v_research_opens,'distinct_return_days',v_research_days,'rule_active',(v_research_opens>=3 and v_research_days>=2)),
    'fair_play_participant',jsonb_build_object('tours_participated',v_tours,'has_critical_violation',v_critical,'rule_status',case when v_critical then 'revoked' when v_tours>=1 then 'active' else 'inactive' end)
  );
end;
$function$;

revoke all on function public.iclub_preview_credential_evidence_v1(uuid) from public, anon, authenticated;
grant execute on function public.iclub_preview_credential_evidence_v1(uuid) to service_role;

comment on function public.iclub_preview_credential_evidence_v1(uuid) is
'Internal read-only credential evidence preview. Does not mutate user_credentials and is not client-executable.';
