-- P1-03: safe timed/paper authorizer, feedback firewall, special finalizer and result ledger.
-- Core-only authority: no branch depends on AI Assist or Mentor Care entitlement/state.

begin;

-- During an active timed/paper attempt never reveal correctness, explanation or diagnostic feedback.
create or replace function private.exam_prep_safe_response_payload_v1(p_response_id uuid,p_language text,p_replayed boolean)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_r private.exam_prep_responses%rowtype; v_i private.exam_prep_session_items%rowtype; v_s private.exam_prep_sessions%rowtype;
  v_lang text; v_explanation text; v_feedback text; v_next text; v_rule private.exam_prep_diagnostic_rules%rowtype;
begin
  v_lang:=lower(coalesce(p_language,'en')); if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_r from private.exam_prep_responses where id=p_response_id; if v_r.id is null then raise exception 'exam_prep_response_not_found' using errcode='P0002'; end if;
  select * into v_i from private.exam_prep_session_items where session_id=v_r.session_id and item_order=v_r.item_order; if v_i.session_id is null then raise exception 'exam_prep_response_item_missing'; end if;
  select * into v_s from private.exam_prep_sessions where id=v_r.session_id; if v_s.id is null then raise exception 'exam_prep_response_session_missing'; end if;

  if v_s.session_type in ('timed','paper') and v_s.status='active' then
    return jsonb_build_object('response_id',v_r.id,'item_order',v_r.item_order,'recorded',true,'replayed',p_replayed);
  end if;

  if v_r.response_kind='machine' then
    select case v_lang when 'ru' then q.explanation_ru when 'uz' then q.explanation_uz else q.explanation_en end
      into v_explanation from public.questions q where q.id=v_i.question_id;
    if v_i.reserve_role='diagnostic' and not v_r.is_correct then
      select * into v_rule from private.exam_prep_diagnostic_rules
      where content_meta_id=v_i.content_meta_id and status='approved' and answer_match=v_r.selected_answer
      order by approved_at desc nulls last,id desc limit 1;
      if v_rule.id is not null then
        v_feedback:=case v_lang when 'ru' then v_rule.feedback_ru when 'uz' then v_rule.feedback_uz else v_rule.feedback_en end;
        v_next:=case v_lang when 'ru' then v_rule.next_action_ru when 'uz' then v_rule.next_action_uz else v_rule.next_action_en end;
      end if;
    end if;
  end if;
  return jsonb_strip_nulls(jsonb_build_object(
    'response_id',v_r.id,'item_order',v_r.item_order,'is_correct',v_r.is_correct,'selected_answer',v_r.selected_answer,
    'verification_status',case when v_r.response_kind='machine' then 'app_verified' else 'self_reviewed' end,
    'explanation',v_explanation,'diagnostic_feedback',v_feedback,'next_action',v_next,'replayed',p_replayed
  ));
end;
$$;
revoke all on function private.exam_prep_safe_response_payload_v1(uuid,text,boolean) from public,anon,authenticated;

-- Active timed/paper session projection hides correctness until finalization.
create or replace function public.get_exam_prep_session_safe_v1(p_session_id uuid,p_language text default 'en')
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid; v_s private.exam_prep_sessions%rowtype; v_lang text; v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en')); if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;

  select coalesce(jsonb_agg(item_payload order by item_order),'[]'::jsonb) into v_items
  from (
    select si.item_order,
      jsonb_strip_nulls(jsonb_build_object(
        'item_order',si.item_order,'item_kind',si.item_kind,'primary_skill_code',si.primary_skill_code,
        'reserve_role',si.reserve_role,'answered',(r.id is not null),'response_id',r.id,
        'selected_answer',case when v_s.session_type in ('timed','paper') and v_s.status='active' then null else r.selected_answer end,
        'is_correct',case when v_s.session_type in ('timed','paper') and v_s.status='active' then null else r.is_correct end,
        'learner_artifact',case when si.item_kind='written' then r.learner_artifact else null end,
        'qtype',case when si.item_kind='question' then q.qtype else null end,
        'difficulty',case when si.item_kind='question' then q.difficulty else null end,
        'time_limit_sec',case when si.item_kind='question' then q.time_limit_sec else null end,
        'text',case when si.item_kind='question' then case v_lang when 'ru' then q.question_text_ru when 'uz' then q.question_text_uz else q.question_text_en end else null end,
        'options',case when si.item_kind='question' and q.qtype='mcq' then coalesce(nullif(case v_lang when 'ru' then q.options_text_ru when 'uz' then q.options_text_uz else q.options_text_en end,''),'[]')::jsonb else null end,
        'written_prompt',case when si.item_kind='written' then case v_lang when 'ru' then wt.prompt_ru when 'uz' then wt.prompt_uz else wt.prompt_en end else null end,
        'written_max_marks',case when si.item_kind='written' then nullif(wt.rubric_json->>'max_marks','')::int else null end
      )) item_payload
    from private.exam_prep_session_items si
    left join public.questions q on q.id=si.question_id
    left join private.exam_prep_written_tasks wt on wt.id=si.written_task_id
    left join private.exam_prep_responses r on r.session_id=si.session_id and r.item_order=si.item_order
    where si.session_id=v_s.id
  ) x;

  return jsonb_build_object(
    'session_id',v_s.id,'status',v_s.status,'component_code',v_s.component_code,'session_type',v_s.session_type,
    'assessment_version',v_s.assessment_version,'total_items',v_s.total_items,'started_at',v_s.started_at,'finalized_at',v_s.finalized_at,
    'timing_contract',case when v_s.session_type in ('timed','paper') then v_s.timing_contract else null end,
    'items',v_items
  );
end;
$$;
revoke execute on function public.get_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

-- Generic finalizer is deliberately forbidden for timed/paper attempts: only the special finalizer may classify unattempted/after-time marks.
create or replace function public.finalize_exam_prep_session_safe_v1(p_session_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_s private.exam_prep_sessions%rowtype; v_answered int; v_machine int; v_correct int; v_written int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid for update;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type in ('timed','paper') then raise exception 'exam_prep_timed_requires_special_finalizer'; end if;
  if v_s.status='abandoned' then raise exception 'exam_prep_session_abandoned'; end if;
  select count(*),count(*) filter(where response_kind='machine'),count(*) filter(where response_kind='machine' and is_correct),count(*) filter(where response_kind='written')
    into v_answered,v_machine,v_correct,v_written from private.exam_prep_responses where session_id=v_s.id;
  if v_s.status='finalized' then
    return jsonb_build_object('session_id',v_s.id,'status','finalized','answered',v_answered,'total_items',v_s.total_items,'machine_correct',v_correct,'machine_total',v_machine,'written_submitted',v_written,'replayed',true);
  end if;
  if v_answered<>v_s.total_items then raise exception 'exam_prep_session_incomplete answered %, expected %',v_answered,v_s.total_items; end if;
  update private.exam_prep_sessions set status='finalized',finalized_at=now(),last_activity_at=now(),finalize_idempotency_key=p_idempotency_key where id=v_s.id;
  return jsonb_build_object('session_id',v_s.id,'status','finalized','answered',v_answered,'total_items',v_s.total_items,'machine_correct',v_correct,'machine_total',v_machine,'written_submitted',v_written,'replayed',false);
end;
$$;
revoke execute on function public.finalize_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.finalize_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

create or replace function public.authorize_exam_prep_timed_safe_v1(p_assessment_id bigint)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid; v_a private.exam_prep_assessments%rowtype; v_cv private.exam_prep_content_versions%rowtype;
  v_c private.exam_prep_timed_assessment_contracts%rowtype; v_limit integer; v_items integer; v_specs integer; v_marks integer; v_auth uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_a from private.exam_prep_assessments where id=p_assessment_id and status='published';
  if v_a.id is null or v_a.assessment_type not in ('timed','paper') then raise exception 'exam_prep_timed_assessment_not_published'; end if;
  select * into v_cv from private.exam_prep_content_versions where id=v_a.content_version_id and status='published';
  if v_cv.id is null or v_cv.component_code<>v_a.component_code then raise exception 'exam_prep_timed_content_not_published'; end if;
  select * into v_c from private.exam_prep_timed_assessment_contracts where assessment_id=v_a.id and status='published';
  if v_c.assessment_id is null then raise exception 'exam_prep_timed_contract_not_published'; end if;
  select count(*) into v_items from private.exam_prep_assessment_items where assessment_id=v_a.id;
  select count(*),coalesce(sum(max_marks),0) into v_specs,v_marks from private.exam_prep_timed_assessment_items where assessment_id=v_a.id;
  if v_items<1 or v_specs<>v_items or v_marks<>v_c.marks_available then raise exception 'exam_prep_timed_content_floor_not_met'; end if;
  if exists(
    select 1 from private.exam_prep_assessment_items ai
    where ai.assessment_id=v_a.id and (
      (ai.question_id is not null and ai.reserve_role<>'timed') or
      (ai.written_task_id is not null and ai.reserve_role<>'written')
    )
  ) then raise exception 'exam_prep_timed_reserve_role_mismatch'; end if;
  v_limit:=private.exam_prep_timed_time_limit_v1(v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec);
  insert into private.exam_prep_session_authorizations(user_id,assessment_id,component_code,purpose,status,valid_until,reason)
  values(v_uid,v_a.id,v_a.component_code,v_a.assessment_type,'issued',now()+interval '1 hour','P1-03 governed timed/paper session')
  returning id into v_auth;
  return jsonb_build_object(
    'authorization_id',v_auth,'assessment_id',v_a.id,'component_code',v_a.component_code,'purpose',v_a.assessment_type,
    'attempt_kind',v_c.attempt_kind,'timing_rule',v_c.timing_rule,'marks_available',v_c.marks_available,
    'time_limit_sec',v_limit,'comparison_scope',v_c.comparison_scope,'comparability_key',v_c.comparability_key,'strict_timing',v_c.strict_timing
  );
end;
$$;
revoke execute on function public.authorize_exam_prep_timed_safe_v1(bigint) from public,anon;
grant execute on function public.authorize_exam_prep_timed_safe_v1(bigint) to authenticated,service_role;

create or replace function public.finalize_exam_prep_timed_safe_v1(
  p_session_id uuid,p_idempotency_key text,p_completion_reason text default 'submitted'
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid; v_s private.exam_prep_sessions%rowtype; v_existing private.exam_prep_timed_attempt_results%rowtype;
  v_deadline timestamptz; v_limit integer; v_marks integer; v_kind text; v_rule text; v_scope text; v_key text; v_strict boolean;
  v_answered integer; v_unattempted integer; v_obj_in integer; v_obj_after integer; v_lost_in integer; v_lost_after integer;
  v_pending_in integer; v_pending_after integer; v_unattempted_marks integer; v_elapsed integer; v_timing_comp boolean; v_score_comp boolean;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  if p_completion_reason not in ('submitted','time_expired','administrative_stop') then raise exception 'exam_prep_bad_completion_reason'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid for update;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type not in ('timed','paper') then raise exception 'exam_prep_not_timed_session'; end if;
  if v_s.status='abandoned' then raise exception 'exam_prep_session_abandoned'; end if;
  select * into v_existing from private.exam_prep_timed_attempt_results where session_id=v_s.id;
  if v_s.status='finalized' then
    if v_existing.session_id is null then raise exception 'exam_prep_timed_result_missing'; end if;
    return public.get_exam_prep_timed_result_safe_v1(v_s.id) || jsonb_build_object('replayed',true);
  end if;

  v_deadline:=nullif(v_s.timing_contract->>'deadline_at','')::timestamptz;
  v_limit:=nullif(v_s.timing_contract->>'time_limit_sec','')::integer;
  v_marks:=nullif(v_s.timing_contract->>'marks_available','')::integer;
  v_kind:=v_s.timing_contract->>'attempt_kind'; v_rule:=v_s.timing_contract->>'timing_rule';
  v_scope:=v_s.timing_contract->>'comparison_scope'; v_key:=v_s.timing_contract->>'comparability_key';
  v_strict:=coalesce((v_s.timing_contract->>'strict_timing')::boolean,false);
  if v_deadline is null or v_limit is null or v_marks is null or v_kind is null or v_rule is null or v_scope is null or v_key is null then
    raise exception 'exam_prep_timing_snapshot_incomplete';
  end if;
  if p_completion_reason='time_expired' and now()<v_deadline then raise exception 'exam_prep_timer_not_expired'; end if;

  select
    count(*) filter(where r.id is not null),
    count(*) filter(where r.id is null),
    coalesce(sum(case when r.response_kind='machine' and r.is_correct and r.answered_at<=v_deadline then ti.max_marks else 0 end),0),
    coalesce(sum(case when r.response_kind='machine' and r.is_correct and r.answered_at>v_deadline then ti.max_marks else 0 end),0),
    coalesce(sum(case when r.response_kind='machine' and not r.is_correct and r.answered_at<=v_deadline then ti.max_marks else 0 end),0),
    coalesce(sum(case when r.response_kind='machine' and not r.is_correct and r.answered_at>v_deadline then ti.max_marks else 0 end),0),
    coalesce(sum(case when r.response_kind='written' and r.answered_at<=v_deadline then ti.max_marks else 0 end),0),
    coalesce(sum(case when r.response_kind='written' and r.answered_at>v_deadline then ti.max_marks else 0 end),0),
    coalesce(sum(case when r.id is null then ti.max_marks else 0 end),0)
  into v_answered,v_unattempted,v_obj_in,v_obj_after,v_lost_in,v_lost_after,v_pending_in,v_pending_after,v_unattempted_marks
  from private.exam_prep_session_items si
  join private.exam_prep_timed_assessment_items ti on ti.assessment_id=v_s.assessment_id and ti.item_order=si.item_order
  left join private.exam_prep_responses r on r.session_id=si.session_id and r.item_order=si.item_order
  where si.session_id=v_s.id;

  if v_obj_in+v_obj_after+v_lost_in+v_lost_after+v_pending_in+v_pending_after+v_unattempted_marks<>v_marks then
    raise exception 'exam_prep_timed_mark_decomposition_mismatch';
  end if;
  v_elapsed:=greatest(0,floor(extract(epoch from (now()-v_s.started_at)))::integer);
  v_timing_comp:=v_strict and p_completion_reason<>'administrative_stop';
  v_score_comp:=v_timing_comp and v_pending_in=0 and v_pending_after=0 and v_kind<>'diagnostic_full';

  update private.exam_prep_sessions
    set status='finalized',finalized_at=now(),last_activity_at=now(),finalize_idempotency_key=p_idempotency_key
    where id=v_s.id;

  insert into private.exam_prep_timed_attempt_results(
    session_id,user_id,component_code,assessment_id,attempt_kind,timing_rule,comparison_scope,comparability_key,strict_timing,
    marks_available,time_limit_sec,server_elapsed_sec,answered_items,unattempted_items,
    objective_marks_in_time,objective_marks_after_time,objective_lost_in_time_marks,objective_lost_after_time_marks,
    pending_review_in_time_marks,pending_review_after_time_marks,unattempted_marks,completion_reason,timing_comparable,base_score_comparable,finalized_at
  ) values(
    v_s.id,v_uid,v_s.component_code,v_s.assessment_id,v_kind,v_rule,v_scope,v_key,v_strict,
    v_marks,v_limit,v_elapsed,v_answered,v_unattempted,
    v_obj_in,v_obj_after,v_lost_in,v_lost_after,v_pending_in,v_pending_after,v_unattempted_marks,
    p_completion_reason,v_timing_comp,v_score_comp,now()
  );

  return public.get_exam_prep_timed_result_safe_v1(v_s.id) || jsonb_build_object('replayed',false);
end;
$$;
revoke execute on function public.finalize_exam_prep_timed_safe_v1(uuid,text,text) from public,anon;
grant execute on function public.finalize_exam_prep_timed_safe_v1(uuid,text,text) to authenticated,service_role;

-- Post-attempt rubric exposure for Core self-review; never available while the session is active.
create or replace function public.get_exam_prep_timed_review_pack_safe_v1(p_session_id uuid,p_language text default 'en')
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid; v_s private.exam_prep_sessions%rowtype; v_lang text; v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1(); v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid and session_type in ('timed','paper');
  if v_s.id is null then raise exception 'exam_prep_timed_session_not_found' using errcode='P0002'; end if;
  if v_s.status<>'finalized' or not exists(select 1 from private.exam_prep_timed_attempt_results where session_id=v_s.id) then raise exception 'exam_prep_review_pack_requires_finalized_attempt'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'item_order',si.item_order,'primary_skill_code',si.primary_skill_code,
    'prompt',case v_lang when 'ru' then wt.prompt_ru when 'uz' then wt.prompt_uz else wt.prompt_en end,
    'learner_artifact',r.learner_artifact,'max_marks',ti.max_marks,'rubric',wt.rubric_json,
    'self_review',case v_lang when 'ru' then wt.self_review_ru when 'uz' then wt.self_review_uz else wt.self_review_en end,
    'submitted_in_time',(r.answered_at<=nullif(v_s.timing_contract->>'deadline_at','')::timestamptz),
    'self_marked',(sm.session_id is not null),'self_marks_awarded',sm.marks_awarded
  ) order by si.item_order),'[]'::jsonb) into v_items
  from private.exam_prep_session_items si
  join private.exam_prep_timed_assessment_items ti on ti.assessment_id=v_s.assessment_id and ti.item_order=si.item_order
  join private.exam_prep_written_tasks wt on wt.id=si.written_task_id
  join private.exam_prep_responses r on r.session_id=si.session_id and r.item_order=si.item_order and r.response_kind='written'
  left join private.exam_prep_timed_written_self_marks sm on sm.session_id=si.session_id and sm.item_order=si.item_order
  where si.session_id=v_s.id and si.item_kind='written';
  return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'items',v_items);
end;
$$;
revoke execute on function public.get_exam_prep_timed_review_pack_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_timed_review_pack_safe_v1(uuid,text) to authenticated,service_role;

create or replace function public.submit_exam_prep_timed_written_self_mark_safe_v1(
  p_session_id uuid,p_item_order integer,p_marks_awarded integer,p_idempotency_key text,p_review_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid; v_s private.exam_prep_sessions%rowtype; v_si private.exam_prep_session_items%rowtype; v_r private.exam_prep_responses%rowtype;
  v_ti private.exam_prep_timed_assessment_items%rowtype; v_existing private.exam_prep_timed_written_self_marks%rowtype; v_deadline timestamptz;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_item_order is null or p_item_order<1 or p_item_order>32767 then raise exception 'exam_prep_bad_item_order'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid and status='finalized' and session_type in ('timed','paper');
  if v_s.id is null or not exists(select 1 from private.exam_prep_timed_attempt_results where session_id=v_s.id) then raise exception 'exam_prep_timed_finalized_attempt_required'; end if;
  select * into v_existing from private.exam_prep_timed_written_self_marks where session_id=v_s.id and idempotency_key=p_idempotency_key;
  if v_existing.session_id is not null then
    if v_existing.item_order<>p_item_order then raise exception 'exam_prep_idempotency_conflict'; end if;
    return public.get_exam_prep_timed_result_safe_v1(v_s.id) || jsonb_build_object('replayed',true);
  end if;
  if exists(select 1 from private.exam_prep_timed_written_self_marks where session_id=v_s.id and item_order=p_item_order) then raise exception 'exam_prep_written_item_already_self_marked'; end if;
  select * into v_si from private.exam_prep_session_items where session_id=v_s.id and item_order=p_item_order::smallint and item_kind='written';
  if v_si.session_id is null then raise exception 'exam_prep_written_item_not_found'; end if;
  select * into v_r from private.exam_prep_responses where session_id=v_s.id and item_order=v_si.item_order and response_kind='written';
  if v_r.id is null then raise exception 'exam_prep_unattempted_written_item_cannot_be_self_marked'; end if;
  select * into v_ti from private.exam_prep_timed_assessment_items where assessment_id=v_s.assessment_id and item_order=v_si.item_order;
  if v_ti.assessment_id is null then raise exception 'exam_prep_timed_mark_spec_missing'; end if;
  if p_marks_awarded is null or p_marks_awarded<0 or p_marks_awarded>v_ti.max_marks then raise exception 'exam_prep_bad_marks_awarded'; end if;
  v_deadline:=nullif(v_s.timing_contract->>'deadline_at','')::timestamptz;
  insert into private.exam_prep_timed_written_self_marks(session_id,item_order,user_id,marks_awarded,max_marks,was_in_time,idempotency_key,review_note)
  values(v_s.id,v_si.item_order,v_uid,p_marks_awarded,v_ti.max_marks,v_r.answered_at<=v_deadline,p_idempotency_key,nullif(trim(coalesce(p_review_note,'')),''));
  return public.get_exam_prep_timed_result_safe_v1(v_s.id) || jsonb_build_object('replayed',false);
end;
$$;
revoke execute on function public.submit_exam_prep_timed_written_self_mark_safe_v1(uuid,integer,integer,text,text) from public,anon;
grant execute on function public.submit_exam_prep_timed_written_self_mark_safe_v1(uuid,integer,integer,text,text) to authenticated,service_role;

create or replace function public.get_exam_prep_timed_result_safe_v1(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid; v_b private.exam_prep_timed_attempt_results%rowtype;
  v_self_in integer:=0; v_self_after integer:=0; v_self_in_max integer:=0; v_self_after_max integer:=0;
  v_pending_in integer; v_pending_after integer; v_earned_in integer; v_earned_after integer; v_lost_in integer; v_lost_after integer; v_score_comp boolean;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_b from private.exam_prep_timed_attempt_results where session_id=p_session_id and user_id=v_uid;
  if v_b.session_id is null then raise exception 'exam_prep_timed_result_not_found' using errcode='P0002'; end if;
  select
    coalesce(sum(marks_awarded) filter(where was_in_time),0),coalesce(sum(marks_awarded) filter(where not was_in_time),0),
    coalesce(sum(max_marks) filter(where was_in_time),0),coalesce(sum(max_marks) filter(where not was_in_time),0)
    into v_self_in,v_self_after,v_self_in_max,v_self_after_max
  from private.exam_prep_timed_written_self_marks where session_id=v_b.session_id and user_id=v_uid;
  v_pending_in:=greatest(0,v_b.pending_review_in_time_marks-v_self_in_max);
  v_pending_after:=greatest(0,v_b.pending_review_after_time_marks-v_self_after_max);
  v_earned_in:=v_b.objective_marks_in_time+v_self_in;
  v_earned_after:=v_b.objective_marks_after_time+v_self_after;
  v_lost_in:=v_b.objective_lost_in_time_marks+(v_self_in_max-v_self_in);
  v_lost_after:=v_b.objective_lost_after_time_marks+(v_self_after_max-v_self_after);
  v_score_comp:=v_b.timing_comparable and v_pending_in=0 and v_pending_after=0 and v_b.attempt_kind<>'diagnostic_full';
  return jsonb_build_object(
    'session_id',v_b.session_id,'component_code',v_b.component_code,'attempt_kind',v_b.attempt_kind,'timing_rule',v_b.timing_rule,
    'comparison_scope',v_b.comparison_scope,'comparability_key',v_b.comparability_key,'strict_timing',v_b.strict_timing,
    'marks_available',v_b.marks_available,'time_limit_sec',v_b.time_limit_sec,'server_elapsed_sec',v_b.server_elapsed_sec,
    'answered_items',v_b.answered_items,'unattempted_items',v_b.unattempted_items,
    'marks_in_time',v_earned_in,'marks_after_time',v_earned_after,
    'lost_answered_marks_in_time',v_lost_in,'lost_answered_marks_after_time',v_lost_after,
    'pending_review_in_time_marks',v_pending_in,'pending_review_after_time_marks',v_pending_after,
    'unattempted_marks',v_b.unattempted_marks,'completion_reason',v_b.completion_reason,
    'timing_comparable',v_b.timing_comparable,'score_comparable',v_score_comp,
    'in_time_percent',round((100.0*v_earned_in/v_b.marks_available)::numeric,1),
    'score_status',case when v_pending_in+v_pending_after>0 then 'pending_self_review' when v_score_comp then 'provisional_comparable' else 'non_comparable' end,
    'readiness_claim',false,'finalized_at',v_b.finalized_at
  );
end;
$$;
revoke execute on function public.get_exam_prep_timed_result_safe_v1(uuid) from public,anon;
grant execute on function public.get_exam_prep_timed_result_safe_v1(uuid) to authenticated,service_role;

create or replace function public.get_exam_prep_timed_catalog_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid; v_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'assessment_id',a.id,'assessment_key',a.assessment_key,'assessment_version',a.assessment_version,
    'title_en',a.title_en,'title_ru',a.title_ru,'title_uz',a.title_uz,'assessment_type',a.assessment_type,
    'attempt_kind',c.attempt_kind,'timing_rule',c.timing_rule,'marks_available',c.marks_available,
    'time_limit_sec',private.exam_prep_timed_time_limit_v1(c.paper_profile_id,c.timing_rule,c.marks_available,c.fixed_time_limit_sec),
    'comparison_scope',c.comparison_scope,'comparability_key',c.comparability_key,'strict_timing',c.strict_timing
  ) order by a.id),'[]'::jsonb) into v_result
  from private.exam_prep_assessments a join private.exam_prep_timed_assessment_contracts c on c.assessment_id=a.id and c.status='published'
  where a.component_code=p_component_code and a.status='published' and a.assessment_type in ('timed','paper');
  return jsonb_build_object('component_code',p_component_code,'assessments',v_result);
end;
$$;
revoke execute on function public.get_exam_prep_timed_catalog_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_timed_catalog_safe_v1(text) to authenticated,service_role;

-- Static access/safety acceptance. No timed/paper endpoint may be anon-readable and feature remains OFF.
do $$ begin
  if has_function_privilege('anon','public.authorize_exam_prep_timed_safe_v1(bigint)','EXECUTE')
     or has_function_privilege('anon','public.finalize_exam_prep_timed_safe_v1(uuid,text,text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_timed_result_safe_v1(uuid)','EXECUTE') then
    raise exception 'P1-03 timed RPC exposed to anon';
  end if;
  if exists(select 1 from private.exam_prep_feature_config where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)) then
    raise exception 'P1-03 RPC migration must remain fail-closed';
  end if;
end $$;

commit;
