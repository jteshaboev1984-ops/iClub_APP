-- Isolate AI lab app_events from normal practice progress surfaces.
-- No rows are deleted. Lab telemetry events are renamed with ai_lab_ prefix so normal UI code
-- that reads practice_attempt_finished / practice_db_save_result does not count them.

begin;

update public.app_events ae
set event_type = 'ai_lab_' || ae.event_type,
    payload = coalesce(ae.payload, '{}'::jsonb) || jsonb_build_object('_is_lab', true, '_lab_source', 'ai_diagnostic_lab')
where ae.created_at >= timestamp with time zone '2026-07-08 09:00:00+00'
  and ae.created_at <  timestamp with time zone '2026-07-08 13:00:00+00'
  and ae.event_type in (
    'practice_attempt_started',
    'practice_attempt_finished',
    'practice_db_save_result',
    'practice_review_opened',
    'recommendation_opened'
  )
  and coalesce(ae.payload->>'subject_id', ae.payload->>'subject_key') = 'economics'
  and ae.user_id in (
    select distinct lr.user_id
    from public.learning_roadmaps lr
    where lr.source_type = 'practice_ai_diagnosis'
      and lr.created_at >= timestamp with time zone '2026-07-08 09:00:00+00'
      and lr.created_at <  timestamp with time zone '2026-07-08 13:00:00+00'
  );

create or replace function public.mark_latest_practice_attempt_as_lab()
returns bigint
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_attempt_id bigint;
  v_attempt_subject_id bigint;
  v_attempt_created_at timestamptz;
  v_subject_key text;
begin
  if v_auth_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select pa.id, pa.subject_id, pa.created_at, s.subject_key
  into v_attempt_id, v_attempt_subject_id, v_attempt_created_at, v_subject_key
  from public.practice_attempts pa
  left join public.subjects s on s.id = pa.subject_id
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

  update public.app_events ae
  set event_type = 'ai_lab_' || ae.event_type,
      payload = coalesce(ae.payload, '{}'::jsonb) || jsonb_build_object('_is_lab', true, '_lab_source', 'ai_diagnostic_lab')
  where ae.user_id = v_auth_user
    and ae.event_type in (
      'practice_attempt_started',
      'practice_attempt_finished',
      'practice_db_save_result',
      'practice_review_opened',
      'recommendation_opened'
    )
    and ae.created_at >= (v_attempt_created_at - interval '20 minutes')
    and ae.created_at <= (v_attempt_created_at + interval '20 minutes')
    and (
      coalesce(ae.payload->>'subject_key', '') = coalesce(v_subject_key, '')
      or coalesce(ae.payload->>'subject_id', '') = coalesce(v_subject_key, '')
      or coalesce(ae.payload->>'subject_id_db', '') = v_attempt_subject_id::text
    );

  return v_attempt_id;
end;
$$;

revoke all on function public.mark_latest_practice_attempt_as_lab() from public, anon;
grant execute on function public.mark_latest_practice_attempt_as_lab() to authenticated;

comment on function public.mark_latest_practice_attempt_as_lab() is
'AI lab-only helper: marks latest practice attempt and matching app_events as lab so they do not enter normal practice stats.';

create or replace function public.create_latest_lab_practice_ai_diagnosis()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_attempt_id bigint;
begin
  v_attempt_id := public.mark_latest_practice_attempt_as_lab();
  return public.create_practice_ai_diagnosis(v_attempt_id);
end;
$$;

revoke all on function public.create_latest_lab_practice_ai_diagnosis() from public, anon;
grant execute on function public.create_latest_lab_practice_ai_diagnosis() to authenticated;

comment on function public.create_latest_lab_practice_ai_diagnosis() is
'AI lab-only RPC: marks latest practice attempt/events as lab and creates/returns its AI diagnosis snapshot.';

commit;
