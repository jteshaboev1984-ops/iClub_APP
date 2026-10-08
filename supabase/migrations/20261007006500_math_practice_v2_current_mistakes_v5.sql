-- Mathematics Practice v2 — current-bank mistake review/drill v5
-- Branch-only migration. v4 remains available until controlled cutover.
--
-- Goal:
-- After Practice v2 pool membership switches, old Practice history stays preserved
-- but weak legacy questions must not re-enter the learner flow through "recent mistakes".
--
-- v5 therefore requires every surfaced/retried question to belong to a currently active
-- Practice pool membership for the same subject. Practice v2 rows must additionally be
-- published/runtime-allowed in private.practice_v2_question_meta.

create or replace function public.get_recent_practice_mistakes_safe_v5(
  p_subject_key text,
  p_topic text default null,
  p_subtopic text default null,
  p_limit integer default 10
)
returns table(
  attempt_id bigint,
  question_id bigint,
  user_answer text,
  is_correct boolean,
  time_spent integer,
  created_at timestamptz,
  topic text,
  subtopic text,
  difficulty text,
  qtype text,
  question_text text,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  correct_answer text,
  explanation text,
  explanation_ru text,
  explanation_uz text,
  explanation_en text,
  image_url text,
  book_ref text
)
language plpgsql
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_subject_id bigint;
  v_is_math boolean := false;
  v_allow_legacy_math boolean := false;
  v_topic text := nullif(trim(coalesce(p_topic,'')),'');
  v_subtopic text := nullif(trim(coalesce(p_subtopic,'')),'');
  v_limit integer := least(10,greatest(1,coalesce(p_limit,10)));
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  select s.id,(s.subject_key='mathematics')
  into v_subject_id,v_is_math
  from public.subjects s
  where s.subject_key=trim(coalesce(p_subject_key,''))
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

  return query
  select
    pa.attempt_id,
    pa.question_id,
    pa.user_answer,
    pa.is_correct,
    pa.time_spent,
    pa.created_at,
    q.topic,
    q.subtopic,
    q.difficulty,
    q.qtype,
    q.question_text,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.correct_answer,
    q.explanation,
    q.explanation_ru,
    q.explanation_uz,
    q.explanation_en,
    q.image_url,
    q.book_ref
  from public.practice_answers pa
  join public.practice_attempts pat
    on pat.id=pa.attempt_id
   and pat.user_id=v_uid
   and pat.subject_id=v_subject_id
  join public.questions q
    on q.id=pa.question_id
   and q.subject_id=v_subject_id
   and q.is_active is true
  left join private.practice_v2_question_meta m
    on m.question_id=q.id
  where pa.is_correct is false
    and exists(
      select 1
      from public.practice_pool_questions ppq
      join public.practice_pools p
        on p.id=ppq.pool_id
       and p.subject_id=v_subject_id
       and p.is_active is true
      where ppq.question_id=q.id
        and ppq.is_active is true
    )
    and (
      ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
      or (m.lifecycle_state='published' and m.is_runtime_allowed is true)
    )
    and not public.iclub_practice_drill_question_protected_v4(q.id)
    and (v_topic is null or lower(trim(coalesce(q.topic,'')))=lower(v_topic))
    and (v_subtopic is null or lower(trim(coalesce(q.subtopic,'')))=lower(v_subtopic))
  order by pa.created_at desc,pa.id desc
  limit v_limit;

  if v_subtopic is not null and not found then
    return query
    select
      pa.attempt_id,
      pa.question_id,
      pa.user_answer,
      pa.is_correct,
      pa.time_spent,
      pa.created_at,
      q.topic,
      q.subtopic,
      q.difficulty,
      q.qtype,
      q.question_text,
      q.question_text_ru,
      q.question_text_uz,
      q.question_text_en,
      q.options_text,
      q.options_text_ru,
      q.options_text_uz,
      q.options_text_en,
      q.correct_answer,
      q.explanation,
      q.explanation_ru,
      q.explanation_uz,
      q.explanation_en,
      q.image_url,
      q.book_ref
    from public.practice_answers pa
    join public.practice_attempts pat
      on pat.id=pa.attempt_id
     and pat.user_id=v_uid
     and pat.subject_id=v_subject_id
    join public.questions q
      on q.id=pa.question_id
     and q.subject_id=v_subject_id
     and q.is_active is true
    left join private.practice_v2_question_meta m
      on m.question_id=q.id
    where pa.is_correct is false
      and exists(
        select 1
        from public.practice_pool_questions ppq
        join public.practice_pools p
          on p.id=ppq.pool_id
         and p.subject_id=v_subject_id
         and p.is_active is true
        where ppq.question_id=q.id
          and ppq.is_active is true
      )
      and (
        ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
        or (m.lifecycle_state='published' and m.is_runtime_allowed is true)
      )
      and not public.iclub_practice_drill_question_protected_v4(q.id)
      and (v_topic is null or lower(trim(coalesce(q.topic,'')))=lower(v_topic))
    order by pa.created_at desc,pa.id desc
    limit v_limit;
  end if;
end;
$function$;

revoke all on function public.get_recent_practice_mistakes_safe_v5(text,text,text,integer) from public,anon;
grant execute on function public.get_recent_practice_mistakes_safe_v5(text,text,text,integer) to authenticated,service_role;


create or replace function public.start_practice_mistakes_drill_safe_v5(
  p_subject_key text,
  p_question_ids bigint[],
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
  v_qids bigint[];
  v_total integer;
  v_allowed integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  if trim(coalesce(p_subject_key,''))='' then
    raise exception 'invalid_subject_key' using errcode='22023';
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
    if v_s.drill_type<>'rec_mistakes' then
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

  if p_question_ids is null
     or cardinality(p_question_ids) not between 1 and 10 then
    raise exception 'practice_drill_question_selection_must_have_1_to_10' using errcode='22023';
  end if;

  select array_agg(x.qid order by x.ord) into v_qids
  from unnest(p_question_ids) with ordinality x(qid,ord)
  where x.qid is not null;

  v_total:=coalesce(cardinality(v_qids),0);

  if v_total not between 1 and 10 then
    raise exception 'practice_drill_question_selection_must_have_1_to_10' using errcode='22023';
  end if;

  if (select count(distinct qid) from unnest(v_qids) q(qid))<>v_total then
    raise exception 'duplicate_question_ids' using errcode='22023';
  end if;

  select count(*)::integer into v_allowed
  from unnest(v_qids) requested(qid)
  join public.questions q
    on q.id=requested.qid
   and q.is_active is true
   and q.subject_id=v_subject_id
  left join private.practice_v2_question_meta m
    on m.question_id=q.id
  where exists(
      select 1
      from public.practice_pool_questions ppq
      join public.practice_pools p
        on p.id=ppq.pool_id
       and p.subject_id=v_subject_id
       and p.is_active is true
      where ppq.question_id=q.id
        and ppq.is_active is true
    )
    and (
      ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
      or (m.lifecycle_state='published' and m.is_runtime_allowed is true)
    )
    and not public.iclub_practice_drill_question_protected_v4(q.id)
    and exists(
      select 1
      from public.practice_answers pa
      join public.practice_attempts pat
        on pat.id=pa.attempt_id
       and pat.user_id=v_uid
       and pat.subject_id=v_subject_id
      where pa.question_id=q.id
        and pa.is_correct is false
    );

  if v_allowed<>v_total then
    raise exception 'practice_drill_question_not_current_owned_mistake_or_protected' using errcode='22023';
  end if;

  insert into public.practice_drill_sessions_v4(
    user_id,subject_id,client_session_id,drill_type,question_ids
  ) values(
    v_uid,v_subject_id,trim(p_client_session_id),'rec_mistakes',v_qids
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
    if v_s.drill_type<>'rec_mistakes' then
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

revoke all on function public.start_practice_mistakes_drill_safe_v5(text,bigint[],text) from public,anon;
grant execute on function public.start_practice_mistakes_drill_safe_v5(text,bigint[],text) to authenticated,service_role;
