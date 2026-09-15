begin;

-- Privacy hardening for written companion checks.
-- Server-evaluated understanding results stay in private evidence metadata only.
-- The learner_artifact remains exactly the learner's own written artifact, so an
-- active protected assessment can never reveal correctness through session reads.

create or replace function private.exam_prep_written_understanding_feedback_v1(
  p_response_id uuid,
  p_language text default 'en'
) returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare
  v_lang text;
  v_r private.exam_prep_responses%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_summary jsonb;
  v_results jsonb;
  v_feedback jsonb:='[]'::jsonb;
  v_row jsonb;
  v_order int;
  v_rule record;
begin
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  select * into v_r
  from private.exam_prep_responses
  where id=p_response_id;
  if v_r.id is null or v_r.response_kind<>'written' then return null; end if;

  select * into v_i
  from private.exam_prep_session_items
  where session_id=v_r.session_id and item_order=v_r.item_order;
  if v_i.written_task_id is null then return null; end if;

  select e.evidence_payload->'understanding_check'
  into v_summary
  from private.exam_prep_evidence_events e
  where e.response_id=v_r.id
    and e.evidence_type='written'
    and e.verification_status='self_reviewed'
  limit 1;

  if v_summary is null or coalesce((v_summary->>'submitted')::boolean,false) is not true then return null; end if;
  v_results:=coalesce(v_summary->'results','[]'::jsonb);

  for v_row in select value from jsonb_array_elements(v_results) loop
    v_order:=nullif(v_row->>'check_order','')::int;
    select c.check_order,
      case v_lang when 'ru' then c.rationale_ru when 'uz' then c.rationale_uz else c.rationale_en end as rationale
      into v_rule
    from private.exam_prep_written_understanding_checks c
    where c.written_task_id=v_i.written_task_id
      and c.check_order=v_order
      and c.lifecycle_state='published';

    if v_rule.check_order is not null then
      v_feedback:=v_feedback||jsonb_build_array(jsonb_build_object(
        'check_order',v_order,
        'is_correct',coalesce((v_row->>'is_correct')::boolean,false),
        'rationale',v_rule.rationale
      ));
    end if;
  end loop;

  return jsonb_build_object(
    'submitted',true,
    'total',coalesce((v_summary->>'total')::int,0),
    'correct',coalesce((v_summary->>'correct')::int,0),
    'all_correct',coalesce((v_summary->>'all_correct')::boolean,false),
    'results',v_feedback
  );
end; $$;
revoke all on function private.exam_prep_written_understanding_feedback_v1(uuid,text) from public,anon,authenticated;

create or replace function public.submit_exam_prep_response_safe_v1(
  p_session_id uuid,
  p_item_order integer,
  p_payload jsonb,
  p_idempotency_key text,
  p_elapsed_ms integer default null,
  p_language text default 'en'
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_r private.exam_prep_responses%rowtype;
  v_eval jsonb;
  v_answer text;
  v_picked integer;
  v_artifact jsonb;
  v_evidence_type text;
  v_lang text;
  v_understanding jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  if p_item_order is null or p_item_order<1 or p_item_order>32767 then raise exception 'exam_prep_bad_item_order'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  if p_elapsed_ms is not null and p_elapsed_ms<0 then raise exception 'exam_prep_bad_elapsed_ms'; end if;
  if p_payload is null or jsonb_typeof(p_payload)<>'object' then raise exception 'exam_prep_payload_must_be_object'; end if;
  if p_payload ?| array['is_correct','correct_answer','mastery','skill_state','verification_status'] then
    raise exception 'exam_prep_server_owned_field_rejected' using errcode='42501';
  end if;

  select * into v_s
  from private.exam_prep_sessions
  where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;

  select * into v_r
  from private.exam_prep_responses
  where session_id=v_s.id and client_idempotency_key=p_idempotency_key;
  if v_r.id is not null then
    if v_r.item_order<>p_item_order then raise exception 'exam_prep_idempotency_conflict'; end if;
    return private.exam_prep_safe_response_payload_v1(v_r.id,v_lang,true);
  end if;

  if v_s.status<>'active' then raise exception 'exam_prep_session_not_active'; end if;
  if exists(select 1 from private.exam_prep_responses where session_id=v_s.id and item_order=p_item_order) then
    raise exception 'exam_prep_item_already_answered';
  end if;

  select * into v_i
  from private.exam_prep_session_items
  where session_id=v_s.id and item_order=p_item_order::smallint;
  if v_i.session_id is null then raise exception 'exam_prep_item_not_in_session' using errcode='P0002'; end if;

  if v_i.item_kind='question' then
    v_answer:=p_payload->>'answer';
    if p_payload ? 'picked_index' then
      if coalesce(p_payload->>'picked_index','') !~ '^[0-9]+$' then raise exception 'exam_prep_bad_picked_index'; end if;
      v_picked:=(p_payload->>'picked_index')::integer;
    end if;
    v_eval:=private.exam_prep_eval_session_question_v1(v_s.id,v_i.item_order,v_answer,v_picked);
    insert into private.exam_prep_responses(
      session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,picked_index,
      selected_answer,is_correct,evaluator_version,elapsed_ms
    ) values(
      v_s.id,v_i.item_order,v_uid,p_idempotency_key,'machine',v_answer,v_picked,
      v_eval->>'selected_answer',(v_eval->>'is_correct')::boolean,'exam_prep_eval_session_question_v1',p_elapsed_ms
    ) returning * into v_r;

    v_evidence_type:=case when v_i.reserve_role in ('diagnostic','learning','retest','mixed','timed') then v_i.reserve_role else 'learning' end;
    insert into private.exam_prep_evidence_events(
      user_id,component_code,skill_code,session_id,response_id,evidence_type,verification_status,
      is_correct,evidence_payload,source_version
    ) values(
      v_uid,v_s.component_code,v_i.primary_skill_code,v_s.id,v_r.id,v_evidence_type,'app_verified',
      v_r.is_correct,jsonb_build_object('item_order',v_i.item_order,'reserve_role',v_i.reserve_role,'evaluator_version',v_r.evaluator_version),
      v_s.assessment_version||'|'||v_i.item_version
    );
  else
    v_artifact:=p_payload->'artifact';
    if v_artifact is null or v_artifact='null'::jsonb or v_artifact='{}'::jsonb or v_artifact='[]'::jsonb then
      raise exception 'exam_prep_written_artifact_required';
    end if;

    v_understanding:=private.exam_prep_evaluate_written_understanding_v1(v_i.written_task_id,p_payload->'understanding_checks');

    insert into private.exam_prep_responses(
      session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,is_correct,evaluator_version,elapsed_ms
    ) values(
      v_s.id,v_i.item_order,v_uid,p_idempotency_key,'written',v_artifact,null,'written_self_review_v1',p_elapsed_ms
    ) returning * into v_r;

    insert into private.exam_prep_evidence_events(
      user_id,component_code,skill_code,session_id,response_id,evidence_type,verification_status,
      is_correct,evidence_payload,source_version
    ) values(
      v_uid,v_s.component_code,v_i.primary_skill_code,v_s.id,v_r.id,'written','self_reviewed',null,
      jsonb_build_object(
        'item_order',v_i.item_order,
        'artifact_present',true,
        'human_review_recommended',true,
        'understanding_check',v_understanding,
        'understanding_authority','app_checked_noncredit'
      ),
      v_s.assessment_version||'|'||v_i.item_version
    );
  end if;

  update private.exam_prep_sessions set last_activity_at=now() where id=v_s.id;
  return private.exam_prep_safe_response_payload_v1(v_r.id,v_lang,false);
end; $$;
revoke execute on function public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text) from public,anon;
grant execute on function public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text) to authenticated,service_role;

-- Guard the intended boundary in the migration itself.
do $$ declare v_submit text; v_feedback text; begin
  v_submit:=pg_get_functiondef('public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)'::regprocedure);
  v_feedback:=pg_get_functiondef('private.exam_prep_written_understanding_feedback_v1(uuid,text)'::regprocedure);
  if position('understanding_summary' in v_submit)>0 or position('understanding_summary' in v_feedback)>0 then
    raise exception 'written understanding privacy hardening failed: evaluation summary still stored/read via learner artifact';
  end if;
  if position('evidence_payload' in v_feedback)=0 then
    raise exception 'written understanding privacy hardening failed: feedback is not evidence-backed';
  end if;
end $$;

commit;
