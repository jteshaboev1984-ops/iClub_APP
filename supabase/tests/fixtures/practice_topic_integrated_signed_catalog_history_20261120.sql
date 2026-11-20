-- #574 · ISO PG17 test ONLY. Source snapshots SELECT-only from hosted DB on 2026-11-20.
-- NOT a production migration. Never bundle private questions, JWTs or user records.
-- Catalog pg_get_functiondef MD5: 565cd971127d5389a5850b92ad439efa
-- Topic History pg_get_functiondef MD5: 571dc19981df240e38c53401a22809d6
-- The original production functions remain untouched. Fixture uses synthetic tables.

-- get_practice_available_topics_safe_v1
CREATE OR REPLACE FUNCTION public.get_practice_available_topics_safe_v1(p_subject_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_subject_id bigint;
  v_is_math boolean := false;
  v_allow_legacy_math boolean := false;
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

  with eligible as (
    select distinct q.id,q.topic as topic
    from public.practice_pools p
    join public.practice_pool_questions ppq
      on ppq.pool_id=p.id and ppq.is_active is true
    join public.questions q
      on q.id=ppq.question_id and q.is_active is true
       and q.subject_id=v_subject_id
    left join private.practice_v2_question_meta m on m.question_id=q.id
    where p.subject_id=v_subject_id and p.is_active is true
      and nullif(trim(q.topic),'') is not null
      and length(q.topic)<=200
      and (
        ((not v_is_math or v_allow_legacy_math) and m.question_id is null)
        or (m.lifecycle_state='published' and m.is_runtime_allowed is true)
      )
      and not public.iclub_practice_drill_question_protected_v4(q.id)
        -- Even archived or future Tour questions are excluded from free topic choice.
        and not exists (
          select 1 from public.tour_questions tq where tq.question_id=q.id
        )
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

-- get_practice_topic_history_safe_v1
CREATE OR REPLACE FUNCTION public.get_practice_topic_history_safe_v1(p_subject_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
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
        'finished_at',finished_at,'session_id',id,'mistakes',total-correct,'review',(select coalesce(jsonb_agg(jsonb_build_object('question_id',q.id,'question_en',q.question_text_en,'question_ru',q.question_text_ru,'question_uz',q.question_text_uz,'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,'user_answer',a.user_answer,'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,'feedback_en',dg.d->>'feedback_en','feedback_ru',dg.d->>'feedback_ru','feedback_uz',dg.d->>'feedback_uz')),'[]'::jsonb) from public.practice_drill_answers_v4 a join public.questions q on q.id=a.question_id left join lateral (select private.practice_match_answer_diagnostic_v5(q.id,a.user_answer) as d) dg on true where a.session_id=ranked.id and a.is_correct=false
 and not public.iclub_practice_drill_question_protected_v4(q.id))
      ) order by finished_at desc,id desc)
      filter(where recent_no=1)
    )->0,
    'best',(
      jsonb_agg(jsonb_build_object(
        'topic',topic,'correct',correct,'total',total,
        'percent',round(100.0*correct/nullif(total,0))::integer,
        'finished_at',finished_at,'session_id',id,'mistakes',total-correct,'review',(select coalesce(jsonb_agg(jsonb_build_object('question_id',q.id,'question_en',q.question_text_en,'question_ru',q.question_text_ru,'question_uz',q.question_text_uz,'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,'user_answer',a.user_answer,'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,'feedback_en',dg.d->>'feedback_en','feedback_ru',dg.d->>'feedback_ru','feedback_uz',dg.d->>'feedback_uz')),'[]'::jsonb) from public.practice_drill_answers_v4 a join public.questions q on q.id=a.question_id left join lateral (select private.practice_match_answer_diagnostic_v5(q.id,a.user_answer) as d) dg on true where a.session_id=ranked.id and a.is_correct=false
 and not public.iclub_practice_drill_question_protected_v4(q.id))
      ) order by finished_at desc,id desc)
      filter(where best_no=1)
    )->0,
    'recent',coalesce(
      jsonb_agg(jsonb_build_object(
        'topic',topic,'correct',correct,'total',total,
        'percent',round(100.0*correct/nullif(total,0))::integer,
        'finished_at',finished_at,'session_id',id,'mistakes',total-correct,'review',(select coalesce(jsonb_agg(jsonb_build_object('question_id',q.id,'question_en',q.question_text_en,'question_ru',q.question_text_ru,'question_uz',q.question_text_uz,'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,'user_answer',a.user_answer,'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,'feedback_en',dg.d->>'feedback_en','feedback_ru',dg.d->>'feedback_ru','feedback_uz',dg.d->>'feedback_uz')),'[]'::jsonb) from public.practice_drill_answers_v4 a join public.questions q on q.id=a.question_id left join lateral (select private.practice_match_answer_diagnostic_v5(q.id,a.user_answer) as d) dg on true where a.session_id=ranked.id and a.is_correct=false
 and not public.iclub_practice_drill_question_protected_v4(q.id))
      ) order by finished_at desc,id desc)
      filter(where recent_no<=5),'[]'::jsonb)
  ) into v_result from ranked;

  return v_result;
end;
$function$;
