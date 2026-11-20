-- AI-3 additive, DORMANT candidate: consistency check for legacy Practice answer diagnoses.
-- Existing public.review_question context has an academic inconsistency:
-- the saved answer can be wrong while an unrelated/misflagged diagnosis row
-- reports is_correct=true. AI must not treat that row as an approved error.
-- Changes only whether an existing stored diagnosis is exposed to AI.
-- No score, answer, diagnostic history or Core writes; no active deployment.
-- Full function is repeated here because PostgreSQL CREATE OR REPLACE FUNCTION
-- does not support patching the body safely. Original signature/ACL preserved.

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
      and d.is_correct is false
      and d.diagnostic_id is not null
      and d.mistake_type is not null
    ),
    'diagnostic',
      case
        when a.is_correct is false
          and d.is_correct is false
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

