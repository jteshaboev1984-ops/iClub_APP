begin;

create or replace function private.exam_prep_active_feedback_allowed_v1(
  p_session_id uuid,
  p_item_order smallint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select case
    when s.id is null or si.session_id is null then false
    when s.status <> 'active' then true
    when s.session_type in ('diagnostic','retest','mixed','timed','paper') then false
    when coalesce(si.reserve_role,'') in ('diagnostic','retest','mixed','timed','unseen') then false
    else true
  end
  from private.exam_prep_sessions s
  join private.exam_prep_session_items si
    on si.session_id=s.id and si.item_order=p_item_order
  where s.id=p_session_id;
$$;
revoke all on function private.exam_prep_active_feedback_allowed_v1(uuid,smallint) from public,anon,authenticated;

create or replace function private.exam_prep_safe_response_payload_v1(
  p_response_id uuid,
  p_language text,
  p_replayed boolean
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_r private.exam_prep_responses%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_lang text;
  v_explanation text;
  v_feedback text;
  v_next text;
  v_rule private.exam_prep_diagnostic_rules%rowtype;
  v_feedback_allowed boolean := false;
begin
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  select * into v_r from private.exam_prep_responses where id=p_response_id;
  if v_r.id is null then raise exception 'exam_prep_response_not_found' using errcode='P0002'; end if;

  select * into v_i from private.exam_prep_session_items
  where session_id=v_r.session_id and item_order=v_r.item_order;
  if v_i.session_id is null then raise exception 'exam_prep_response_item_missing'; end if;

  v_feedback_allowed:=coalesce(private.exam_prep_active_feedback_allowed_v1(v_r.session_id,v_r.item_order),false);

  if v_r.response_kind='machine' and v_feedback_allowed then
    select case v_lang when 'ru' then q.explanation_ru when 'uz' then q.explanation_uz else q.explanation_en end
      into v_explanation
    from public.questions q where q.id=v_i.question_id;

    if v_i.reserve_role='diagnostic' and not v_r.is_correct then
      select * into v_rule
      from private.exam_prep_diagnostic_rules
      where content_meta_id=v_i.content_meta_id
        and status='approved'
        and answer_match=v_r.selected_answer
      order by approved_at desc nulls last,id desc
      limit 1;
      if v_rule.id is not null then
        v_feedback:=case v_lang when 'ru' then v_rule.feedback_ru when 'uz' then v_rule.feedback_uz else v_rule.feedback_en end;
        v_next:=case v_lang when 'ru' then v_rule.next_action_ru when 'uz' then v_rule.next_action_uz else v_rule.next_action_en end;
      end if;
    end if;
  end if;

  return jsonb_strip_nulls(jsonb_build_object(
    'response_id',v_r.id,
    'item_order',v_r.item_order,
    'selected_answer',v_r.selected_answer,
    'is_correct',case when v_feedback_allowed then v_r.is_correct else null end,
    'verification_status',case when v_r.response_kind='machine' then 'app_verified' else 'self_reviewed' end,
    'feedback_deferred',case when v_r.response_kind='machine' and not v_feedback_allowed then true else null end,
    'explanation',v_explanation,
    'diagnostic_feedback',v_feedback,
    'next_action',v_next,
    'replayed',p_replayed
  ));
end;
$$;
revoke all on function private.exam_prep_safe_response_payload_v1(uuid,text,boolean) from public,anon,authenticated;

create or replace function public.get_exam_prep_session_safe_v1(
  p_session_id uuid,
  p_language text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_lang text;
  v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  select * into v_s
  from private.exam_prep_sessions
  where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;

  select coalesce(jsonb_agg(item_payload order by item_order),'[]'::jsonb) into v_items
  from (
    select si.item_order,
      jsonb_strip_nulls(jsonb_build_object(
        'item_order',si.item_order,
        'item_kind',si.item_kind,
        'primary_skill_code',si.primary_skill_code,
        'reserve_role',si.reserve_role,
        'answered',(r.id is not null),
        'response_id',r.id,
        'selected_answer',r.selected_answer,
        'is_correct',case
          when r.id is not null and private.exam_prep_active_feedback_allowed_v1(v_s.id,si.item_order) then r.is_correct
          else null
        end,
        'feedback_deferred',case
          when r.id is not null and r.response_kind='machine' and not private.exam_prep_active_feedback_allowed_v1(v_s.id,si.item_order) then true
          else null
        end,
        'learner_artifact',case when si.item_kind='written' then r.learner_artifact else null end,
        'qtype',case when si.item_kind='question' then q.qtype else null end,
        'difficulty',case when si.item_kind='question' then q.difficulty else null end,
        'time_limit_sec',case when si.item_kind='question' then q.time_limit_sec else null end,
        'text',case when si.item_kind='question' then case v_lang when 'ru' then q.question_text_ru when 'uz' then q.question_text_uz else q.question_text_en end else null end,
        'options',case when si.item_kind='question' and q.qtype='mcq' then coalesce(nullif(case v_lang when 'ru' then q.options_text_ru when 'uz' then q.options_text_uz else q.options_text_en end,''),'[]')::jsonb else null end,
        'written_prompt',case when si.item_kind='written' then case v_lang when 'ru' then wt.prompt_ru when 'uz' then wt.prompt_uz else wt.prompt_en end else null end,
        'written_max_marks',case when si.item_kind='written' then nullif(wt.rubric_json->>'max_marks','')::int else null end
      )) as item_payload
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    left join private.exam_prep_written_tasks wt on wt.id=si.written_task_id
    left join private.exam_prep_responses r on r.session_id=si.session_id and r.item_order=si.item_order
    where si.session_id=v_s.id
  ) x;

  return jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'component_code',v_s.component_code,
    'session_type',v_s.session_type,
    'assessment_version',v_s.assessment_version,
    'total_items',v_s.total_items,
    'started_at',v_s.started_at,
    'finalized_at',v_s.finalized_at,
    'items',v_items
  );
end;
$$;
revoke execute on function public.get_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

commit;