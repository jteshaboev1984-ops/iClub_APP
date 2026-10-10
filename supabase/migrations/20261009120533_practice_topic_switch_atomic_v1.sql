-- iClub Mathematics Practice topic-switch foundation.
-- STAGING ONLY until UI pending-transition recovery and isolated SQL regressions pass.
-- No legacy row/answer deletion; use one transaction, a stable request key and an owned old session.
create or replace function public.replace_practice_topic_drill_choice_safe_v1(
  p_subject_key text,
  p_topic text,
  p_expected_old_session_id bigint,
  p_expected_old_client_session_id text,
  p_new_client_session_id text
) returns jsonb
language plpgsql
security definer
set search_path = public, private, auth, pg_temp
as $function$
declare
  v_uid uuid := auth.uid();
  v_subject_id bigint;
  v_topic text := trim(coalesce(p_topic,''));
  v_old public.practice_drill_sessions_v4%rowtype;
  v_new public.practice_drill_sessions_v4%rowtype;
  v_start jsonb;
  v_rows integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  if p_expected_old_session_id is null or p_expected_old_session_id<=0
     or length(trim(coalesce(p_expected_old_client_session_id,''))) not between 8 and 128
     or length(trim(coalesce(p_new_client_session_id,''))) not between 8 and 128
     or left(trim(coalesce(p_new_client_session_id,'')),22)<>'practice_topic_choice_'
     or v_topic='' then
    raise exception 'invalid_topic_switch_request' using errcode='22023';
  end if;

  -- Serialize competing switch requests from the same account, including two tabs.
  perform pg_advisory_xact_lock(hashtextextended('iclub_topic_switch:'||v_uid::text,0));

  select s.id into v_subject_id
    from public.subjects s
    where s.subject_key=trim(coalesce(p_subject_key,''))
      and s.is_active is true
    limit 1;
  if v_subject_id is null then
    raise exception 'subject_not_found' using errcode='P0002';
  end if;

  select s.* into v_old
    from public.practice_drill_sessions_v4 s
    where s.id=p_expected_old_session_id
      and s.user_id=v_uid
      and s.subject_id=v_subject_id
      and s.client_session_id=trim(p_expected_old_client_session_id)
      and s.drill_type='rec_topic'
      and left(s.client_session_id,22)='practice_topic_choice_'
    for update;
  if v_old.id is null then
    raise exception 'old_topic_session_not_owned_or_not_found' using errcode='P0002';
  end if;
  if v_old.topic=v_topic then
    raise exception 'same_topic_requires_resume' using errcode='22023';
  end if;

  -- A retry after an unknown network outcome must rejoin the SAME new session.
  if v_old.status='abandoned' then
    select s.* into v_new from public.practice_drill_sessions_v4 s
      where s.user_id=v_uid
        and s.subject_id=v_subject_id
        and s.client_session_id=trim(p_new_client_session_id)
        and s.drill_type='rec_topic'
        and s.topic=v_topic
        and s.status='in_progress'
      limit 1;
    if v_new.id is null or v_new.id=v_old.id then
      raise exception 'topic_switch_request_mismatch' using errcode='55000';
    end if;
    return jsonb_build_object(
      'session_id',v_new.id,'status',v_new.status,
      'question_count',cardinality(v_new.question_ids),
      'drill_type',v_new.drill_type,'resumed',true,
      'old_session_id',v_old.id,'old_session_abandoned',true);
  end if;

  if v_old.status<>'in_progress' then
    raise exception 'old_topic_session_not_active' using errcode='55000';
  end if;

  -- The nested start and old-session state change either both commit or both roll back.
  v_start:=public.start_practice_topic_drill_choice_safe_v1(
    p_subject_key,v_topic,null,trim(p_new_client_session_id));
  select s.* into v_new from public.practice_drill_sessions_v4 s
    where s.id=(v_start->>'session_id')::bigint
      and s.user_id=v_uid
      and s.subject_id=v_subject_id
      and s.client_session_id=trim(p_new_client_session_id)
      and s.drill_type='rec_topic'
      and s.topic=v_topic
      and s.status='in_progress'
    for update;
  if v_new.id is null or v_new.id=v_old.id then
    raise exception 'new_topic_session_validation_failed' using errcode='55000';
  end if;

  update public.practice_drill_sessions_v4 s
    set status='abandoned'
    where s.id=v_old.id and s.user_id=v_uid and s.status='in_progress';
  get diagnostics v_rows=row_count;
  if v_rows<>1 then
    raise exception 'topic_switch_concurrency_conflict' using errcode='40001';
  end if;
  return v_start || jsonb_build_object(
    'old_session_id',v_old.id,'old_session_abandoned',true);
end;
$function$;

revoke all on function public.replace_practice_topic_drill_choice_safe_v1(text,text,bigint,text,text) from public;
revoke all on function public.replace_practice_topic_drill_choice_safe_v1(text,text,bigint,text,text) from anon;
grant execute on function public.replace_practice_topic_drill_choice_safe_v1(text,text,bigint,text,text) to authenticated;
