-- P0-09: safe membership-bound Exam Prep session APIs.
-- No client answer keys. No client correctness/mastery writes. No legacy Practice/Tour writes.
-- Reserve access requires a server-issued single-use authorization; knowing assessment_key is insufficient.

begin;

create or replace function private.exam_prep_require_core_access_v1()
returns uuid
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required' using errcode='28000'; end if;
  if not exists(select 1 from public.users u where u.id=v_uid) then
    raise exception 'exam_prep_user_not_found' using errcode='P0002';
  end if;
  if not exists(
    select 1
    from private.exam_prep_feature_config c
    join private.exam_prep_feature_entitlements e on e.user_id=v_uid
    where c.program_key='math_as_p1_p5'
      and c.rollout_state<>'off'
      and c.core_enabled
      and not c.kill_switch
      and e.entitlement_status='active'
      and e.core_access
      and (e.valid_from is null or e.valid_from<=now())
      and (e.valid_until is null or e.valid_until>now())
  ) then
    raise exception 'exam_prep_core_unavailable' using errcode='42501';
  end if;
  return v_uid;
end; $$;
revoke all on function private.exam_prep_require_core_access_v1() from public,anon,authenticated;

create or replace function private.exam_prep_eval_session_question_v1(
  p_session_id uuid,
  p_item_order smallint,
  p_user_answer text,
  p_picked_index integer default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_q public.questions%rowtype;
  v_item private.exam_prep_session_items%rowtype;
  v_selected text;
  v_selected_norm text;
  v_correct boolean := false;
  v_current_md5 text;
begin
  select * into v_item from private.exam_prep_session_items
  where session_id=p_session_id and item_order=p_item_order and item_kind='question';
  if v_item.session_id is null then raise exception 'exam_prep_question_item_not_found' using errcode='P0002'; end if;

  select * into v_q from public.questions where id=v_item.question_id;
  if v_q.id is null then raise exception 'exam_prep_question_missing' using errcode='P0002'; end if;

  v_current_md5 := md5(concat_ws(chr(31),v_q.id::text,v_q.subject_id::text,coalesce(v_q.topic,''),coalesce(v_q.subtopic,''),
    coalesce(v_q.difficulty,''),coalesce(v_q.qtype,''),coalesce(v_q.question_text,''),coalesce(v_q.options_text,''),
    coalesce(v_q.correct_answer,''),coalesce(v_q.explanation,''),coalesce(v_q.image_url,''),coalesce(v_q.is_active::text,''),
    coalesce(v_q.question_text_ru,''),coalesce(v_q.question_text_uz,''),coalesce(v_q.question_text_en,''),
    coalesce(v_q.options_text_ru,''),coalesce(v_q.options_text_uz,''),coalesce(v_q.options_text_en,''),
    coalesce(v_q.explanation_ru,''),coalesce(v_q.explanation_uz,''),coalesce(v_q.explanation_en,''),
    coalesce(v_q.book_ref,''),coalesce(v_q.time_limit_sec::text,''),coalesce(v_q.quality_flag,''),coalesce(v_q.quality_status,'')));
  if v_current_md5<>v_item.question_snapshot_md5 then
    raise exception 'exam_prep_question_snapshot_drift' using errcode='55000';
  end if;

  if lower(coalesce(v_q.qtype,''))='mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected := chr(65+p_picked_index);
    elsif trim(coalesce(p_user_answer,'')) ~ '^[0-9]+$' and trim(p_user_answer)::integer between 0 and 25 then
      v_selected := chr(65+trim(p_user_answer)::integer);
    else
      v_selected := upper(trim(coalesce(p_user_answer,'')));
    end if;
    v_correct := upper(trim(coalesce(v_selected,'')))=upper(trim(coalesce(v_q.correct_answer,'')))
      or public.iclub_normalize_answer(v_selected)=public.iclub_normalize_answer(v_q.correct_answer);
  else
    v_selected := trim(coalesce(p_user_answer,''));
    v_selected_norm := public.iclub_normalize_answer(v_selected);
    v_correct := exists(
      select 1 from regexp_split_to_table(coalesce(v_q.correct_answer,''), E'\\|') accepted
      where public.iclub_normalize_answer(accepted)=v_selected_norm
    );
    if not v_correct and public.iclub_is_numeric(v_selected) and public.iclub_is_numeric(v_q.correct_answer) then
      v_correct := replace(v_selected,',','.')::numeric=replace(v_q.correct_answer,',','.')::numeric;
    end if;
  end if;

  return jsonb_build_object('selected_answer',nullif(v_selected,''),'is_correct',v_correct);
end; $$;
revoke all on function private.exam_prep_eval_session_question_v1(uuid,smallint,text,integer) from public,anon,authenticated;

create or replace function public.start_exam_prep_session_safe_v1(
  p_authorization_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_s private.exam_prep_sessions%rowtype;
  v_ass private.exam_prep_assessments%rowtype;
  v_cv private.exam_prep_content_versions%rowtype;
  v_program bigint;
  v_total int;
  v_inserted int;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_authorization_id is null then raise exception 'exam_prep_authorization_required'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;

  select * into v_s from private.exam_prep_sessions where user_id=v_uid and client_idempotency_key=p_idempotency_key;
  if v_s.id is not null then
    if v_s.authorization_id<>p_authorization_id then raise exception 'exam_prep_idempotency_conflict'; end if;
    return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'component_code',v_s.component_code,'session_type',v_s.session_type,'total_items',v_s.total_items,'resumed',true);
  end if;

  select * into v_auth from private.exam_prep_session_authorizations where id=p_authorization_id for update;
  if v_auth.id is null or v_auth.user_id<>v_uid then raise exception 'exam_prep_authorization_not_found' using errcode='P0002'; end if;
  if v_auth.status<>'issued' then raise exception 'exam_prep_authorization_not_usable'; end if;
  if v_auth.valid_until is not null and v_auth.valid_until<=now() then
    update private.exam_prep_session_authorizations set status='expired' where id=v_auth.id;
    raise exception 'exam_prep_authorization_expired';
  end if;

  select * into v_ass from private.exam_prep_assessments where id=v_auth.assessment_id and status='published';
  if v_ass.id is null then raise exception 'exam_prep_assessment_not_published'; end if;
  if v_ass.component_code<>v_auth.component_code or v_ass.assessment_type<>v_auth.purpose then raise exception 'exam_prep_authorization_scope_mismatch'; end if;

  select * into v_cv from private.exam_prep_content_versions where id=v_ass.content_version_id and status='published';
  if v_cv.id is null or v_cv.component_code<>v_ass.component_code then raise exception 'exam_prep_content_version_not_published'; end if;
  select program_version_id into v_program from private.exam_prep_content_versions where id=v_cv.id;

  select count(*) into v_total from private.exam_prep_assessment_items where assessment_id=v_ass.id;
  if v_total<1 or v_total>32767 then raise exception 'exam_prep_empty_or_invalid_assessment'; end if;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract
  ) values(
    v_auth.id,v_uid,v_program,v_cv.id,v_ass.id,v_ass.assessment_version,
    v_ass.component_code,v_ass.assessment_type,'active',p_idempotency_key,v_total::smallint,
    jsonb_build_object('assessment_type',v_ass.assessment_type)
  )
  on conflict(user_id,client_idempotency_key) do nothing
  returning * into v_s;

  if v_s.id is null then
    select * into v_s from private.exam_prep_sessions where user_id=v_uid and client_idempotency_key=p_idempotency_key;
    if v_s.id is null or v_s.authorization_id<>v_auth.id then raise exception 'exam_prep_idempotency_conflict'; end if;
    return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'component_code',v_s.component_code,'session_type',v_s.session_type,'total_items',v_s.total_items,'resumed',true);
  end if;

  insert into private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,
    content_meta_id,question_snapshot_md5,item_version
  )
  select v_s.id,ai.item_order,
         case when ai.question_id is not null then 'question' else 'written' end,
         ai.question_id,ai.written_task_id,ai.primary_skill_code,ai.reserve_role,ai.is_holdout,
         m.id,m.question_snapshot_md5,
         case when ai.question_id is not null then 'qmd5:'||m.question_snapshot_md5 else 'written:'||wt.task_version end
  from private.exam_prep_assessment_items ai
  left join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id and m.content_version_id=v_cv.id
  left join private.exam_prep_written_tasks wt
    on wt.id=ai.written_task_id and wt.content_version_id=v_cv.id and wt.lifecycle_state='published'
  where ai.assessment_id=v_ass.id
    and (
      (ai.question_id is not null and m.id is not null and ai.primary_skill_code=m.primary_skill_code and (
         (m.lifecycle_state='published' and m.exposure_state='released' and m.reserve_role='learning')
         or (m.lifecycle_state='reserve' and m.exposure_state='withheld' and m.reserve_role in ('diagnostic','retest','mixed','timed','unseen'))
      ))
      or (ai.written_task_id is not null and wt.id is not null and ai.primary_skill_code=wt.primary_skill_code)
    );
  get diagnostics v_inserted=row_count;
  if v_inserted<>v_total then raise exception 'exam_prep_membership_freeze_failed expected %, inserted %',v_total,v_inserted; end if;

  update private.exam_prep_session_authorizations
  set status='consumed',consumed_at=now(),consumed_session_id=v_s.id
  where id=v_auth.id and status='issued';
  if not found then raise exception 'exam_prep_authorization_consume_failed'; end if;

  return jsonb_build_object('session_id',v_s.id,'status','active','component_code',v_s.component_code,'session_type',v_s.session_type,'total_items',v_s.total_items,'resumed',false);
end; $$;
revoke execute on function public.start_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.start_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

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
  v_uid := private.exam_prep_require_core_access_v1();
  v_lang := lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;

  select coalesce(jsonb_agg(item_payload order by item_order),'[]'::jsonb) into v_items
  from (
    select si.item_order,
      jsonb_strip_nulls(jsonb_build_object(
        'item_order',si.item_order,'item_kind',si.item_kind,'primary_skill_code',si.primary_skill_code,
        'reserve_role',si.reserve_role,'answered',(r.id is not null),'response_id',r.id,
        'selected_answer',r.selected_answer,'is_correct',r.is_correct,'learner_artifact',case when si.item_kind='written' then r.learner_artifact else null end,
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
    'session_id',v_s.id,'status',v_s.status,'component_code',v_s.component_code,'session_type',v_s.session_type,
    'assessment_version',v_s.assessment_version,'total_items',v_s.total_items,'started_at',v_s.started_at,'finalized_at',v_s.finalized_at,
    'items',v_items
  );
end; $$;
revoke execute on function public.get_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

create or replace function public.submit_exam_prep_response_safe_v1(
  p_session_id uuid,
  p_item_order integer,
  p_payload jsonb,
  p_idempotency_key text,
  p_elapsed_ms integer default null,
  p_language text default 'en'
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
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
  v_explanation text;
  v_feedback text;
  v_next text;
  v_rule private.exam_prep_diagnostic_rules%rowtype;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  v_lang := lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  if p_item_order is null or p_item_order<1 or p_item_order>32767 then raise exception 'exam_prep_bad_item_order'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  if p_elapsed_ms is not null and p_elapsed_ms<0 then raise exception 'exam_prep_bad_elapsed_ms'; end if;
  if p_payload is null or jsonb_typeof(p_payload)<>'object' then raise exception 'exam_prep_payload_must_be_object'; end if;
  if p_payload ?| array['is_correct','correct_answer','mastery','skill_state','verification_status'] then
    raise exception 'exam_prep_server_owned_field_rejected' using errcode='42501';
  end if;

  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.status<>'active' then raise exception 'exam_prep_session_not_active'; end if;

  select * into v_r from private.exam_prep_responses where session_id=v_s.id and client_idempotency_key=p_idempotency_key;
  if v_r.id is not null then
    if v_r.item_order<>p_item_order then raise exception 'exam_prep_idempotency_conflict'; end if;
    return jsonb_build_object('response_id',v_r.id,'item_order',v_r.item_order,'is_correct',v_r.is_correct,'selected_answer',v_r.selected_answer,'verification_status',case when v_r.response_kind='machine' then 'app_verified' else 'self_reviewed' end,'replayed',true);
  end if;
  if exists(select 1 from private.exam_prep_responses where session_id=v_s.id and item_order=p_item_order) then raise exception 'exam_prep_item_already_answered'; end if;

  select * into v_i from private.exam_prep_session_items where session_id=v_s.id and item_order=p_item_order::smallint;
  if v_i.session_id is null then raise exception 'exam_prep_item_not_in_session' using errcode='P0002'; end if;

  if v_i.item_kind='question' then
    v_answer := p_payload->>'answer';
    if p_payload ? 'picked_index' then
      if coalesce(p_payload->>'picked_index','') !~ '^[0-9]+$' then raise exception 'exam_prep_bad_picked_index'; end if;
      v_picked := (p_payload->>'picked_index')::integer;
    end if;
    v_eval := private.exam_prep_eval_session_question_v1(v_s.id,v_i.item_order,v_answer,v_picked);

    insert into private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,picked_index,selected_answer,is_correct,evaluator_version,elapsed_ms)
    values(v_s.id,v_i.item_order,v_uid,p_idempotency_key,'machine',v_answer,v_picked,v_eval->>'selected_answer',(v_eval->>'is_correct')::boolean,'exam_prep_eval_session_question_v1',p_elapsed_ms)
    returning * into v_r;

    v_evidence_type := case when v_i.reserve_role in ('diagnostic','learning','retest','mixed','timed') then v_i.reserve_role else 'learning' end;
    insert into private.exam_prep_evidence_events(user_id,component_code,skill_code,session_id,response_id,evidence_type,verification_status,is_correct,evidence_payload,source_version)
    values(v_uid,v_s.component_code,v_i.primary_skill_code,v_s.id,v_r.id,v_evidence_type,'app_verified',v_r.is_correct,
           jsonb_build_object('item_order',v_i.item_order,'reserve_role',v_i.reserve_role,'evaluator_version',v_r.evaluator_version),
           v_s.assessment_version||'|'||v_i.item_version);

    select case v_lang when 'ru' then q.explanation_ru when 'uz' then q.explanation_uz else q.explanation_en end
    into v_explanation from public.questions q where q.id=v_i.question_id;

    if v_i.reserve_role='diagnostic' and not v_r.is_correct then
      select * into v_rule from private.exam_prep_diagnostic_rules
      where content_meta_id=v_i.content_meta_id and status='approved' and answer_match=v_r.selected_answer
      order by approved_at desc nulls last,id desc limit 1;
      if v_rule.id is not null then
        v_feedback := case v_lang when 'ru' then v_rule.feedback_ru when 'uz' then v_rule.feedback_uz else v_rule.feedback_en end;
        v_next := case v_lang when 'ru' then v_rule.next_action_ru when 'uz' then v_rule.next_action_uz else v_rule.next_action_en end;
      end if;
    end if;
  else
    v_artifact := p_payload->'artifact';
    if v_artifact is null or v_artifact='null'::jsonb or v_artifact='{}'::jsonb or v_artifact='[]'::jsonb then raise exception 'exam_prep_written_artifact_required'; end if;

    insert into private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,is_correct,evaluator_version,elapsed_ms)
    values(v_s.id,v_i.item_order,v_uid,p_idempotency_key,'written',v_artifact,null,'written_self_review_v1',p_elapsed_ms)
    returning * into v_r;

    insert into private.exam_prep_evidence_events(user_id,component_code,skill_code,session_id,response_id,evidence_type,verification_status,is_correct,evidence_payload,source_version)
    values(v_uid,v_s.component_code,v_i.primary_skill_code,v_s.id,v_r.id,'written','self_reviewed',null,
           jsonb_build_object('item_order',v_i.item_order,'artifact_present',true,'human_review_recommended',true),
           v_s.assessment_version||'|'||v_i.item_version);
  end if;

  update private.exam_prep_sessions set last_activity_at=now() where id=v_s.id;

  return jsonb_strip_nulls(jsonb_build_object(
    'response_id',v_r.id,'item_order',v_r.item_order,'is_correct',v_r.is_correct,'selected_answer',v_r.selected_answer,
    'verification_status',case when v_r.response_kind='machine' then 'app_verified' else 'self_reviewed' end,
    'explanation',v_explanation,'diagnostic_feedback',v_feedback,'next_action',v_next,'replayed',false
  ));
end; $$;
revoke execute on function public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text) from public,anon;
grant execute on function public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text) to authenticated,service_role;

create or replace function public.finalize_exam_prep_session_safe_v1(
  p_session_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_answered int;
  v_machine int;
  v_correct int;
  v_written int;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid for update;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.status='abandoned' then raise exception 'exam_prep_session_abandoned'; end if;

  select count(*),count(*) filter(where response_kind='machine'),count(*) filter(where response_kind='machine' and is_correct),count(*) filter(where response_kind='written')
  into v_answered,v_machine,v_correct,v_written
  from private.exam_prep_responses where session_id=v_s.id;

  if v_s.status='finalized' then
    return jsonb_build_object('session_id',v_s.id,'status','finalized','answered',v_answered,'total_items',v_s.total_items,'machine_correct',v_correct,'machine_total',v_machine,'written_submitted',v_written,'replayed',true);
  end if;
  if v_answered<>v_s.total_items then raise exception 'exam_prep_session_incomplete answered %, expected %',v_answered,v_s.total_items; end if;

  update private.exam_prep_sessions
  set status='finalized',finalized_at=now(),last_activity_at=now(),finalize_idempotency_key=p_idempotency_key
  where id=v_s.id;

  return jsonb_build_object('session_id',v_s.id,'status','finalized','answered',v_answered,'total_items',v_s.total_items,'machine_correct',v_correct,'machine_total',v_machine,'written_submitted',v_written,'replayed',false);
end; $$;
revoke execute on function public.finalize_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.finalize_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

commit;
