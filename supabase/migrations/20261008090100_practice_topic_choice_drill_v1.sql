-- Independent topic choice for any published ACTIVE Practice pool; Tours remain protected.
-- Same server-owned question evaluation and session idempotency as v5.
-- Used only by voluntary topic choice, not by scheduled Tour or recommendation drills.
create or replace function public.start_practice_topic_drill_choice_safe_v1(
  p_subject_key text,
  p_topic text,
  p_subtopic text,
  p_client_session_id text
)
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
  v_s public.practice_drill_sessions_v4%rowtype;
  v_topic text := trim(coalesce(p_topic,''));
  v_subtopic text := nullif(trim(coalesce(p_subtopic,'')),'');
  v_use_subtopic boolean := false;
  v_easy bigint[] := '{}'::bigint[];
  v_medium bigint[] := '{}'::bigint[];
  v_hard bigint[] := '{}'::bigint[];
  v_qids bigint[] := '{}'::bigint[];
  v_needed integer := 0;
  v_total integer := 0;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  if trim(coalesce(p_subject_key,''))='' then
    raise exception 'invalid_subject_key' using errcode='22023';
  end if;
  if v_topic='' then
    raise exception 'invalid_topic' using errcode='22023';
  end if;
  if p_client_session_id is null
     or length(trim(p_client_session_id)) not between 8 and 128 then
    raise exception 'invalid_client_session_id' using errcode='22023';
  end if;

  select * into v_s
  from public.practice_drill_sessions_v4 s
  where s.user_id=v_uid
    and s.client_session_id=trim(p_client_session_id)
  limit 1;

  if v_s.id is not null then
    if v_s.drill_type<>'rec_topic' then
      raise exception 'client_session_scope_mismatch' using errcode='22023';
    end if;
    return jsonb_build_object(
      'session_id',v_s.id,
      'status',v_s.status,
      'question_count',cardinality(v_s.question_ids),
      'drill_type',v_s.drill_type,
      'resumed',true
    );
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

  if v_is_math then
    select exists(
      select 1
      from private.practice_v2_question_meta m
      join public.questions q on q.id=m.question_id
      where q.subject_id=v_subject_id
        and m.release_version='math_p1_practice_v2_2026_10_07'
        and m.lifecycle_state='published'
        and m.is_runtime_allowed is false
    )
    into v_allow_legacy_math;
  end if;

  -- If a requested subtopic has at least one eligible question, keep it narrow.
  if v_subtopic is not null then
    select exists(
      select 1
      from public.practice_pools p
      join public.practice_pool_questions ppq
        on ppq.pool_id=p.id and ppq.is_active is true
      join public.questions q
        on q.id=ppq.question_id
       and q.is_active is true
       and q.subject_id=v_subject_id
      left join private.practice_v2_question_meta m
        on m.question_id=q.id
      where p.subject_id=v_subject_id
        and p.is_active is true
        and q.topic=v_topic
        and q.subtopic=v_subtopic
        and (
          ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
          or (
            m.lifecycle_state='published'
            and m.is_runtime_allowed is true
          )
        )
        and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
    ) into v_use_subtopic;
  end if;

  with candidates as (
    select distinct q.id,
      case lower(coalesce(q.difficulty,'medium'))
        when 'easy' then 'easy'
        when 'hard' then 'hard'
        else 'medium'
      end as diff
    from public.practice_pools p
    join public.practice_pool_questions ppq
      on ppq.pool_id=p.id and ppq.is_active is true
    join public.questions q
      on q.id=ppq.question_id
     and q.is_active is true
     and q.subject_id=v_subject_id
    left join private.practice_v2_question_meta m
      on m.question_id=q.id
    where p.subject_id=v_subject_id
      and p.is_active is true
      and q.topic=v_topic
      and (not v_use_subtopic or q.subtopic=v_subtopic)
      and (
        ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
        or (
          m.lifecycle_state='published'
          and m.is_runtime_allowed is true
        )
      )
      and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
  )
  select count(*)::integer into v_total
  from candidates;

  if v_total<=0 then
    raise exception 'practice_drill_no_questions' using errcode='55000';
  end if;

  with candidates as (
    select q.id
    from public.practice_pools p
    join public.practice_pool_questions ppq
      on ppq.pool_id=p.id and ppq.is_active is true
    join public.questions q
      on q.id=ppq.question_id
     and q.is_active is true
     and q.subject_id=v_subject_id
    left join private.practice_v2_question_meta m
      on m.question_id=q.id
    where p.subject_id=v_subject_id
      and p.is_active is true
      and q.topic=v_topic
      and (not v_use_subtopic or q.subtopic=v_subtopic)
      and lower(coalesce(q.difficulty,'medium'))='easy'
      and (((not v_is_math or v_allow_legacy_math) and m.question_id is null) or (m.lifecycle_state='published' and m.is_runtime_allowed is true))
      and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
    group by q.id
    order by random()
    limit 3
  )
  select coalesce(array_agg(id),'{}'::bigint[]) into v_easy
  from candidates;

  with candidates as (
    select q.id
    from public.practice_pools p
    join public.practice_pool_questions ppq
      on ppq.pool_id=p.id and ppq.is_active is true
    join public.questions q
      on q.id=ppq.question_id
     and q.is_active is true
     and q.subject_id=v_subject_id
    left join private.practice_v2_question_meta m
      on m.question_id=q.id
    where p.subject_id=v_subject_id
      and p.is_active is true
      and q.topic=v_topic
      and (not v_use_subtopic or q.subtopic=v_subtopic)
      and lower(coalesce(q.difficulty,'medium')) not in ('easy','hard')
      and (((not v_is_math or v_allow_legacy_math) and m.question_id is null) or (m.lifecycle_state='published' and m.is_runtime_allowed is true))
      and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
    group by q.id
    order by random()
    limit 5
  )
  select coalesce(array_agg(id),'{}'::bigint[]) into v_medium
  from candidates;

  with candidates as (
    select q.id
    from public.practice_pools p
    join public.practice_pool_questions ppq
      on ppq.pool_id=p.id and ppq.is_active is true
    join public.questions q
      on q.id=ppq.question_id
     and q.is_active is true
     and q.subject_id=v_subject_id
    left join private.practice_v2_question_meta m
      on m.question_id=q.id
    where p.subject_id=v_subject_id
      and p.is_active is true
      and q.topic=v_topic
      and (not v_use_subtopic or q.subtopic=v_subtopic)
      and lower(coalesce(q.difficulty,'medium'))='hard'
      and (((not v_is_math or v_allow_legacy_math) and m.question_id is null) or (m.lifecycle_state='published' and m.is_runtime_allowed is true))
      and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
    group by q.id
    order by random()
    limit 2
  )
  select coalesce(array_agg(id),'{}'::bigint[]) into v_hard
  from candidates;

  v_qids := coalesce(v_easy,'{}'::bigint[])
          || coalesce(v_medium,'{}'::bigint[])
          || coalesce(v_hard,'{}'::bigint[]);
  v_needed := least(10,v_total)-coalesce(cardinality(v_qids),0);

  if v_needed>0 then
    with candidates as (
      select q.id
      from public.practice_pools p
      join public.practice_pool_questions ppq
        on ppq.pool_id=p.id and ppq.is_active is true
      join public.questions q
        on q.id=ppq.question_id
       and q.is_active is true
       and q.subject_id=v_subject_id
      left join private.practice_v2_question_meta m
        on m.question_id=q.id
      where p.subject_id=v_subject_id
        and p.is_active is true
        and q.topic=v_topic
        and (not v_use_subtopic or q.subtopic=v_subtopic)
        and not (q.id=any(v_qids))
        and (((not v_is_math or v_allow_legacy_math) and m.question_id is null) or (m.lifecycle_state='published' and m.is_runtime_allowed is true))
        and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
      group by q.id
      order by random()
      limit v_needed
    )
    select v_qids || coalesce(array_agg(id),'{}'::bigint[])
    into v_qids
    from candidates;
  end if;

  select coalesce(array_agg(x.qid order by
    case lower(coalesce(q.difficulty,'medium'))
      when 'easy' then 1
      when 'hard' then 3
      else 2
    end,
    x.ord
  ),'{}'::bigint[])
  into v_qids
  from unnest(v_qids) with ordinality x(qid,ord)
  join public.questions q on q.id=x.qid;

  if coalesce(cardinality(v_qids),0) not between 1 and 10 then
    raise exception 'practice_drill_selection_failed' using errcode='55000';
  end if;

  insert into public.practice_drill_sessions_v4(
    user_id,subject_id,client_session_id,drill_type,topic,subtopic,question_ids
  ) values(
    v_uid,v_subject_id,trim(p_client_session_id),'rec_topic',v_topic,
    case when v_use_subtopic then v_subtopic else null end,v_qids
  )
  returning * into v_s;

  return jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'question_count',cardinality(v_s.question_ids),
    'drill_type',v_s.drill_type,
    'resumed',false
  );
exception
  when unique_violation then
    select * into v_s
    from public.practice_drill_sessions_v4 s
    where s.user_id=v_uid
      and s.client_session_id=trim(p_client_session_id)
    limit 1;

    if v_s.id is null then raise; end if;
    if v_s.drill_type<>'rec_topic' then
      raise exception 'client_session_scope_mismatch' using errcode='22023';
    end if;

    return jsonb_build_object(
      'session_id',v_s.id,
      'status',v_s.status,
      'question_count',cardinality(v_s.question_ids),
      'drill_type',v_s.drill_type,
      'resumed',true
    );
end;
$function$;

revoke all on function public.start_practice_topic_drill_choice_safe_v1(text,text,text,text) from public;
revoke all on function public.start_practice_topic_drill_choice_safe_v1(text,text,text,text) from anon;
grant execute on function public.start_practice_topic_drill_choice_safe_v1(text,text,text,text) to authenticated, service_role;
