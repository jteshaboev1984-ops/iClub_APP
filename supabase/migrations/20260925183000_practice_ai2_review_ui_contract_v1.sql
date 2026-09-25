-- AI-2 Practice learner UI/read-context contract v1.
-- Additive and default-OFF. Exposes only booleans/question ids to the browser.
-- AI context itself remains service-role only and never contains correct_answer/private explanation.

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
    'diagnostic_mapped',false,
    'diagnostic',null
  )
  into v_result
  from public.practice_attempts pa
  join public.practice_answers a
    on a.attempt_id=pa.id and a.question_id=p_question_id
  join public.questions q
    on q.id=a.question_id and q.subject_id=pa.subject_id
  join public.subjects s
    on s.id=pa.subject_id
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

create or replace function public.get_practice_ai_ui_context_v1(
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
  v_uid uuid:=auth.uid();
  v_locale text:=lower(coalesce(p_locale,''));
  v_policy private.practice_ai_policy%rowtype;
  v_ent private.practice_ai_entitlements%rowtype;
  v_subject_id bigint;
  v_subject_key text;
  v_used integer:=0;
  v_result_enabled boolean:=false;
  v_question_ids jsonb:='[]'::jsonb;
begin
  if v_uid is null then
    raise exception 'practice_ai_auth_required';
  end if;

  if p_attempt_id is null or p_attempt_id<=0 or v_locale not in ('ru','uz','en') then
    return jsonb_build_object(
      'enabled',false,
      'result_summary_enabled',false,
      'explainable_question_ids','[]'::jsonb
    );
  end if;

  select pa.subject_id,s.subject_key
  into v_subject_id,v_subject_key
  from public.practice_attempts pa
  join public.subjects s on s.id=pa.subject_id
  where pa.id=p_attempt_id
    and pa.user_id=v_uid
    and coalesce(pa.is_lab,false)=false;

  if v_subject_id is null or v_subject_key is null then
    return jsonb_build_object(
      'enabled',false,
      'result_summary_enabled',false,
      'explainable_question_ids','[]'::jsonb
    );
  end if;

  select * into v_policy
  from private.practice_ai_policy
  where id=1;

  select * into v_ent
  from private.practice_ai_entitlements
  where user_id=v_uid
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  if v_policy.id is null
     or v_policy.kill_switch
     or v_policy.rollout_state='off'
     or not v_policy.enabled
     or not v_policy.generation_enabled
     or v_ent.user_id is null
     or private.practice_ai_has_active_protected_assessment_v1(v_uid) then
    return jsonb_build_object(
      'enabled',false,
      'result_summary_enabled',false,
      'explainable_question_ids','[]'::jsonb
    );
  end if;

  select coalesce(u.request_count,0)
  into v_used
  from private.practice_ai_daily_usage u
  where u.user_id=v_uid and u.usage_date=current_date;

  if coalesce(v_used,0)>=v_policy.max_daily_requests then
    return jsonb_build_object(
      'enabled',false,
      'result_summary_enabled',false,
      'explainable_question_ids','[]'::jsonb
    );
  end if;

  if coalesce(v_ent.result_summary_enabled,false) then
    select exists(
      select 1
      from private.practice_ai_source_cards c
      where c.subject_key=v_subject_key
        and c.locale=v_locale
        and c.card_type='result_context'
        and c.approval_status='approved'
        and c.is_runtime_allowed
        and c.rights_status in ('original_iclub','official_public_metadata','licensed')
        and c.question_id is null
        and c.topic is null
    )
    into v_result_enabled;
  end if;

  if coalesce(v_ent.post_answer_enabled,false) then
    select coalesce(jsonb_agg(x.question_id order by x.question_id),'[]'::jsonb)
    into v_question_ids
    from (
      select distinct a.question_id
      from public.practice_answers a
      join public.questions q
        on q.id=a.question_id and q.subject_id=v_subject_id
      where a.attempt_id=p_attempt_id
        and exists(
          select 1
          from private.practice_ai_source_cards c
          where c.subject_key=v_subject_key
            and c.locale=v_locale
            and c.card_type='answer_explanation'
            and c.approval_status='approved'
            and c.is_runtime_allowed
            and c.rights_status in ('original_iclub','official_public_metadata','licensed')
            and (
              c.question_id=q.id
              or (
                c.question_id is null
                and c.topic=q.topic
                and (c.subtopic is null or c.subtopic=q.subtopic)
              )
              or (
                c.question_id is null
                and c.topic is null
              )
            )
        )
    ) x;
  end if;

  return jsonb_build_object(
    'enabled',v_result_enabled or jsonb_array_length(v_question_ids)>0,
    'result_summary_enabled',v_result_enabled,
    'explainable_question_ids',v_question_ids
  );
end;
$$;

revoke all on function public.get_practice_ai_ui_context_v1(bigint,text)
  from public,anon;
grant execute on function public.get_practice_ai_ui_context_v1(bigint,text)
  to authenticated,service_role;
