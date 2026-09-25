-- AI-3 deterministic Practice diagnosis context v1.
-- Read-only AI context enrichment. Uses only diagnosis already written by the
-- deterministic Practice engine; it never derives or invents a misconception.

create or replace function public.get_practice_ai_review_question_context_service_v1(
  p_user_id uuid,
  p_attempt_id bigint,
  p_question_id bigint,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_locale text:=case when lower(coalesce(p_locale,'')) in ('ru','uz','en')
    then lower(p_locale) else 'en' end;
  v_result jsonb;
begin
  if p_user_id is null or p_attempt_id is null or p_question_id is null then
    return null;
  end if;

  select jsonb_build_object(
    'context_type','practice_review_answer_v1',
    'attempt_id',pa.id,
    'subject_id',pa.subject_id,
    'subject_key',s.subject_key,
    'subject_title',s.title,
    'question_id',q.id,
    'topic',q.topic,
    'subtopic',q.subtopic,
    'qtype',q.qtype,
    'is_correct',a.is_correct,
    'user_answer',a.user_answer,
    'time_spent',a.time_spent,
    'diagnostic_mapped',(
      a.is_correct is false
      and d.diagnostic_id is not null
      and d.mistake_type is not null
    ),
    'diagnostic',
      case
        when a.is_correct is false
          and d.diagnostic_id is not null
          and d.mistake_type is not null
        then jsonb_strip_nulls(jsonb_build_object(
          'mistake_type',d.mistake_type,
          'weak_skill',d.weak_skill,
          'feedback',case v_locale
            when 'ru' then d.feedback_ru
            when 'uz' then d.feedback_uz
            else d.feedback_en
          end,
          'next_action',case v_locale
            when 'ru' then d.next_action_ru
            when 'uz' then d.next_action_uz
            else d.next_action_en
          end
        ))
        else null
      end
  )
  into v_result
  from public.practice_attempts pa
  join public.practice_answers a
    on a.attempt_id=pa.id and a.question_id=p_question_id
  join public.questions q
    on q.id=a.question_id and q.subject_id=pa.subject_id
  join public.subjects s
    on s.id=pa.subject_id
  left join public.user_answer_diagnosis d
    on d.user_id=pa.user_id
   and d.attempt_type='practice'
   and d.attempt_id=pa.id
   and d.question_id=a.question_id
   and d.practice_answer_id=a.id
  where pa.id=p_attempt_id
    and pa.user_id=p_user_id
    and coalesce(pa.is_lab,false)=false;

  return v_result;
end;
$$;

revoke all on function public.get_practice_ai_review_question_context_service_v1(uuid,bigint,bigint,text)
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_review_question_context_service_v1(uuid,bigint,bigint,text)
  to service_role;

create or replace function public.get_practice_ai_result_context_service_v1(
  p_user_id uuid,
  p_attempt_id bigint,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_locale text:=case when lower(coalesce(p_locale,'')) in ('ru','uz','en')
    then lower(p_locale) else 'en' end;
  v_result jsonb;
begin
  if p_user_id is null or p_attempt_id is null then return null; end if;

  with owned as (
    select pa.id,pa.subject_id,pa.score,pa.percent,pa.time_seconds,pa.created_at
    from public.practice_attempts pa
    where pa.id=p_attempt_id
      and pa.user_id=p_user_id
      and coalesce(pa.is_lab,false)=false
  ),
  answers as (
    select a.id as practice_answer_id,a.question_id,a.is_correct,a.time_spent,q.topic,q.subtopic
    from owned o
    join public.practice_answers a on a.attempt_id=o.id
    join public.questions q on q.id=a.question_id and q.subject_id=o.subject_id
  ),
  weak_topics as (
    select topic,subtopic,count(*)::int as wrong_count
    from answers
    where is_correct=false
    group by topic,subtopic
    order by count(*) desc,topic,subtopic
    limit 8
  ),
  diag_base as (
    select
      d.mistake_type,
      d.weak_skill,
      case v_locale
        when 'ru' then d.feedback_ru
        when 'uz' then d.feedback_uz
        else d.feedback_en
      end as feedback,
      case v_locale
        when 'ru' then d.next_action_ru
        when 'uz' then d.next_action_uz
        else d.next_action_en
      end as next_action
    from owned o
    join answers a on true
    join public.user_answer_diagnosis d
      on d.user_id=p_user_id
     and d.attempt_type='practice'
     and d.attempt_id=o.id
     and d.question_id=a.question_id
     and d.practice_answer_id=a.practice_answer_id
    where a.is_correct=false
      and d.is_correct=false
      and d.diagnostic_id is not null
      and d.mistake_type is not null
  ),
  diag as (
    select
      mistake_type,
      weak_skill,
      feedback,
      next_action,
      count(*)::int as occurrence_count
    from diag_base
    group by mistake_type,weak_skill,feedback,next_action
    order by count(*) desc,mistake_type,weak_skill
    limit 8
  )
  select jsonb_build_object(
    'context_type','practice_result_v1',
    'attempt_id',o.id,
    'subject_id',o.subject_id,
    'subject_key',s.subject_key,
    'subject_title',s.title,
    'score',o.score,
    'percent',o.percent,
    'time_seconds',o.time_seconds,
    'question_count',(select count(*) from answers),
    'wrong_count',(select count(*) from answers where is_correct=false),
    'weak_topics',coalesce((select jsonb_agg(jsonb_build_object(
      'topic',w.topic,
      'subtopic',w.subtopic,
      'wrong_count',w.wrong_count
    )) from weak_topics w),'[]'::jsonb),
    'diagnostic_patterns',coalesce((select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
      'mistake_type',d.mistake_type,
      'weak_skill',d.weak_skill,
      'feedback',d.feedback,
      'next_action',d.next_action,
      'occurrence_count',d.occurrence_count
    ))) from diag d),'[]'::jsonb)
  )
  into v_result
  from owned o
  join public.subjects s on s.id=o.subject_id;

  return v_result;
end;
$$;

revoke all on function public.get_practice_ai_result_context_service_v1(uuid,bigint,text)
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_result_context_service_v1(uuid,bigint,text)
  to service_role;
