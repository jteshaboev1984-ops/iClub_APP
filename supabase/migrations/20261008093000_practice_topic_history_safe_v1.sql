-- iClub: per-learner, per-subject topic Practice results v1.
-- READ ONLY. No Tour history/certificates/rating/progress changes.
-- Only voluntarily selected topic drills created with practice_topic_choice_.
create or replace function public.get_practice_topic_history_safe_v1(p_subject_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_subject_id bigint;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  if nullif(trim(coalesce(p_subject_key,'')),'') is null then
    raise exception 'invalid_subject_key' using errcode='22023';
  end if;

  select s.id into v_subject_id
  from public.subjects s
  where s.subject_key=trim(p_subject_key)
    and s.is_active is true
  limit 1;

  if v_subject_id is null then
    raise exception 'subject_not_found' using errcode='P0002';
  end if;

  with completed as (
    select s.id, s.topic,
      coalesce(s.finalized_at,s.created_at) as finished_at,
      cardinality(s.question_ids)::integer as total,
      count(a.question_id)::integer as answered,
      count(a.question_id) filter(where a.is_correct is true)::integer as correct
    from public.practice_drill_sessions_v4 s
    left join public.practice_drill_answers_v4 a on a.session_id=s.id
    where s.user_id=v_uid
      and s.subject_id=v_subject_id
      and s.status='finalized'
      and s.drill_type='rec_topic'
      and left(s.client_session_id,22)='practice_topic_choice_'
    group by s.id
  ),
  valid as (
    select * from completed
    where total>0 and answered=total
  ),
  ranked as (
    select v.*,
      row_number() over(order by finished_at desc,id desc) as recent_no,
      row_number() over(order by correct::numeric/nullif(total,0) desc,
        correct desc,finished_at desc,id desc) as best_no
    from valid v
  )
  select jsonb_build_object(
    'ok',true,
    'subject_key',trim(p_subject_key),
    'completed_sessions',count(*)::integer,
    'total_correct_answers',coalesce(sum(correct),0)::integer,
    'total_answered',coalesce(sum(answered),0)::integer,
    'last',(
      jsonb_agg(jsonb_build_object(
        'topic',topic,'correct',correct,'total',total,
        'percent',round(100.0*correct/nullif(total,0))::integer,
        'finished_at',finished_at
      ) order by finished_at desc,id desc)
      filter(where recent_no=1)
    )->0,
    'best',(
      jsonb_agg(jsonb_build_object(
        'topic',topic,'correct',correct,'total',total,
        'percent',round(100.0*correct/nullif(total,0))::integer,
        'finished_at',finished_at
      ) order by finished_at desc,id desc)
      filter(where best_no=1)
    )->0,
    'recent',coalesce(
      jsonb_agg(jsonb_build_object(
        'topic',topic,'correct',correct,'total',total,
        'percent',round(100.0*correct/nullif(total,0))::integer,
        'finished_at',finished_at
      ) order by finished_at desc,id desc)
      filter(where recent_no<=5),'[]'::jsonb)
  ) into v_result from ranked;

  return v_result;
end;
$function$;

revoke all on function public.get_practice_topic_history_safe_v1(text) from public;
revoke all on function public.get_practice_topic_history_safe_v1(text) from anon;
grant execute on function public.get_practice_topic_history_safe_v1(text) to authenticated,service_role;
