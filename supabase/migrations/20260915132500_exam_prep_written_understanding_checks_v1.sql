begin;

-- Additive companion checks for written Exam Prep tasks.
-- They support honest deterministic checking of narrow mathematical ideas while
-- leaving the learner's written artefact self-reviewed / mentor-verifiable.
-- Existing written tasks, assessment membership, responses and evidence rows are
-- never rewritten by this migration.

create table if not exists private.exam_prep_written_understanding_checks (
  id bigint generated always as identity primary key,
  written_task_id bigint not null references private.exam_prep_written_tasks(id) on delete restrict,
  check_order smallint not null check(check_order between 1 and 20),
  check_version text not null default 'v1',
  check_kind text not null default 'mcq' check(check_kind in ('mcq')),
  prompt_en text not null,
  prompt_ru text not null,
  prompt_uz text not null,
  options_en jsonb not null,
  options_ru jsonb not null,
  options_uz jsonb not null,
  correct_index smallint not null,
  rationale_en text not null,
  rationale_ru text not null,
  rationale_uz text not null,
  lifecycle_state text not null default 'draft' check(lifecycle_state in ('draft','approved','published','retired')),
  qa_math_status text not null default 'pending' check(qa_math_status in ('pending','pass','fail')),
  qa_language_status text not null default 'pending' check(qa_language_status in ('pending','pass','fail')),
  qa_technical_status text not null default 'pending' check(qa_technical_status in ('pending','pass','fail')),
  created_at timestamptz not null default now(),
  approved_at timestamptz null,
  unique(written_task_id,check_order,check_version),
  check(jsonb_typeof(options_en)='array' and jsonb_typeof(options_ru)='array' and jsonb_typeof(options_uz)='array'),
  check(jsonb_array_length(options_en)>=2),
  check(jsonb_array_length(options_en)=jsonb_array_length(options_ru)),
  check(jsonb_array_length(options_en)=jsonb_array_length(options_uz)),
  check(correct_index>=0 and correct_index<jsonb_array_length(options_en)),
  check(lifecycle_state not in ('approved','published') or
    (qa_math_status='pass' and qa_language_status='pass' and qa_technical_status='pass'))
);

create unique index if not exists exam_prep_written_understanding_one_published_v1
  on private.exam_prep_written_understanding_checks(written_task_id,check_order)
  where lifecycle_state='published';

create index if not exists exam_prep_written_understanding_task_idx_v1
  on private.exam_prep_written_understanding_checks(written_task_id,lifecycle_state,check_order);

alter table private.exam_prep_written_understanding_checks enable row level security;
revoke all on private.exam_prep_written_understanding_checks from public,anon,authenticated;
grant all on private.exam_prep_written_understanding_checks to service_role;
grant usage,select on sequence private.exam_prep_written_understanding_checks_id_seq to service_role;

do $$ begin
  execute 'create trigger exam_prep_written_understanding_audit_v1 after insert or update or delete on private.exam_prep_written_understanding_checks for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;

create or replace function private.exam_prep_written_understanding_payload_v1(
  p_written_task_id bigint,
  p_language text default 'en'
) returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare v_lang text; v_rows jsonb;
begin
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  if p_written_task_id is null then return '[]'::jsonb; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'check_order',c.check_order,
    'check_kind',c.check_kind,
    'prompt',case v_lang when 'ru' then c.prompt_ru when 'uz' then c.prompt_uz else c.prompt_en end,
    'options',case v_lang when 'ru' then c.options_ru when 'uz' then c.options_uz else c.options_en end
  ) order by c.check_order),'[]'::jsonb)
  into v_rows
  from private.exam_prep_written_understanding_checks c
  where c.written_task_id=p_written_task_id and c.lifecycle_state='published';

  return v_rows;
end; $$;
revoke all on function private.exam_prep_written_understanding_payload_v1(bigint,text) from public,anon,authenticated;

create or replace function private.exam_prep_evaluate_written_understanding_v1(
  p_written_task_id bigint,
  p_answers jsonb
) returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare
  v_total int:=0; v_correct int:=0; v_check record; v_answer jsonb; v_picked int;
  v_results jsonb:='[]'::jsonb;
begin
  select count(*) into v_total
  from private.exam_prep_written_understanding_checks c
  where c.written_task_id=p_written_task_id and c.lifecycle_state='published';

  if v_total=0 then
    return jsonb_build_object('configured',false,'submitted',false,'total',0,'correct',0,'all_correct',false,'results','[]'::jsonb);
  end if;
  if p_answers is null or p_answers='null'::jsonb then
    return jsonb_build_object('configured',true,'submitted',false,'total',v_total,'correct',0,'all_correct',false,'results','[]'::jsonb);
  end if;
  if jsonb_typeof(p_answers)<>'array' then raise exception 'exam_prep_written_understanding_answers_must_be_array'; end if;
  if jsonb_array_length(p_answers)<>v_total then raise exception 'exam_prep_written_understanding_answers_incomplete'; end if;

  for v_check in
    select c.check_order,c.correct_index,jsonb_array_length(c.options_en) as option_count
    from private.exam_prep_written_understanding_checks c
    where c.written_task_id=p_written_task_id and c.lifecycle_state='published'
    order by c.check_order
  loop
    select e.value into v_answer
    from jsonb_array_elements(p_answers) e(value)
    where coalesce(e.value->>'check_order','')=v_check.check_order::text;
    if v_answer is null then raise exception 'exam_prep_written_understanding_answer_missing order=%',v_check.check_order; end if;
    if (select count(*) from jsonb_array_elements(p_answers) e(value) where coalesce(e.value->>'check_order','')=v_check.check_order::text)<>1 then
      raise exception 'exam_prep_written_understanding_answer_duplicate order=%',v_check.check_order;
    end if;
    if coalesce(v_answer->>'picked_index','') !~ '^[0-9]+$' then raise exception 'exam_prep_written_understanding_bad_picked_index'; end if;
    v_picked:=(v_answer->>'picked_index')::int;
    if v_picked<0 or v_picked>=v_check.option_count then raise exception 'exam_prep_written_understanding_bad_picked_index'; end if;
    if v_picked=v_check.correct_index then v_correct:=v_correct+1; end if;
    v_results:=v_results||jsonb_build_array(jsonb_build_object(
      'check_order',v_check.check_order,
      'picked_index',v_picked,
      'is_correct',(v_picked=v_check.correct_index)
    ));
  end loop;

  return jsonb_build_object(
    'configured',true,'submitted',true,'total',v_total,'correct',v_correct,
    'all_correct',(v_correct=v_total),'results',v_results
  );
end; $$;
revoke all on function private.exam_prep_evaluate_written_understanding_v1(bigint,jsonb) from public,anon,authenticated;

create or replace function private.exam_prep_written_understanding_feedback_v1(
  p_response_id uuid,
  p_language text default 'en'
) returns jsonb
language plpgsql stable security definer set search_path=''
as $$
declare
  v_lang text; v_r private.exam_prep_responses%rowtype; v_i private.exam_prep_session_items%rowtype;
  v_summary jsonb; v_results jsonb; v_feedback jsonb:='[]'::jsonb; v_row jsonb; v_order int; v_rule record;
begin
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_r from private.exam_prep_responses where id=p_response_id;
  if v_r.id is null or v_r.response_kind<>'written' then return null; end if;
  select * into v_i from private.exam_prep_session_items where session_id=v_r.session_id and item_order=v_r.item_order;
  if v_i.written_task_id is null then return null; end if;
  v_summary:=v_r.learner_artifact->'understanding_summary';
  if v_summary is null or coalesce((v_summary->>'submitted')::boolean,false) is not true then return null; end if;
  v_results:=coalesce(v_summary->'results','[]'::jsonb);

  for v_row in select value from jsonb_array_elements(v_results) loop
    v_order:=nullif(v_row->>'check_order','')::int;
    select c.check_order,
      case v_lang when 'ru' then c.rationale_ru when 'uz' then c.rationale_uz else c.rationale_en end as rationale
      into v_rule
    from private.exam_prep_written_understanding_checks c
    where c.written_task_id=v_i.written_task_id and c.check_order=v_order and c.lifecycle_state='published';
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

-- Safe session delivery: published prompts/options only. Correct indices and
-- rationales remain private and never enter an active question payload.
create or replace function public.get_exam_prep_session_safe_v1(p_session_id uuid, p_language text default 'en')
returns jsonb language plpgsql stable security definer set search_path='' as $$
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
        'written_max_marks',case when si.item_kind='written' then nullif(wt.rubric_json->>'max_marks','')::int else null end,
        'understanding_checks',case when si.item_kind='written' then private.exam_prep_written_understanding_payload_v1(si.written_task_id,v_lang) else null end
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
end; $$;
revoke execute on function public.get_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

-- Written submission remains self-reviewed. The companion result is stored only
-- as non-crediting server-checked metadata inside the written evidence payload.
create or replace function public.submit_exam_prep_response_safe_v1(
  p_session_id uuid,
  p_item_order integer,
  p_payload jsonb,
  p_idempotency_key text,
  p_elapsed_ms integer default null,
  p_language text default 'en'
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid; v_s private.exam_prep_sessions%rowtype; v_i private.exam_prep_session_items%rowtype;
  v_r private.exam_prep_responses%rowtype; v_eval jsonb; v_answer text; v_picked integer; v_artifact jsonb;
  v_evidence_type text; v_lang text; v_understanding jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1(); v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  if p_item_order is null or p_item_order<1 or p_item_order>32767 then raise exception 'exam_prep_bad_item_order'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;
  if p_elapsed_ms is not null and p_elapsed_ms<0 then raise exception 'exam_prep_bad_elapsed_ms'; end if;
  if p_payload is null or jsonb_typeof(p_payload)<>'object' then raise exception 'exam_prep_payload_must_be_object'; end if;
  if p_payload ?| array['is_correct','correct_answer','mastery','skill_state','verification_status'] then raise exception 'exam_prep_server_owned_field_rejected' using errcode='42501'; end if;
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid; if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  select * into v_r from private.exam_prep_responses where session_id=v_s.id and client_idempotency_key=p_idempotency_key;
  if v_r.id is not null then if v_r.item_order<>p_item_order then raise exception 'exam_prep_idempotency_conflict'; end if; return private.exam_prep_safe_response_payload_v1(v_r.id,v_lang,true); end if;
  if v_s.status<>'active' then raise exception 'exam_prep_session_not_active'; end if;
  if exists(select 1 from private.exam_prep_responses where session_id=v_s.id and item_order=p_item_order) then raise exception 'exam_prep_item_already_answered'; end if;
  select * into v_i from private.exam_prep_session_items where session_id=v_s.id and item_order=p_item_order::smallint; if v_i.session_id is null then raise exception 'exam_prep_item_not_in_session' using errcode='P0002'; end if;
  if v_i.item_kind='question' then
    v_answer:=p_payload->>'answer'; if p_payload ? 'picked_index' then if coalesce(p_payload->>'picked_index','') !~ '^[0-9]+$' then raise exception 'exam_prep_bad_picked_index'; end if; v_picked:=(p_payload->>'picked_index')::integer; end if;
    v_eval:=private.exam_prep_eval_session_question_v1(v_s.id,v_i.item_order,v_answer,v_picked);
    insert into private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,picked_index,selected_answer,is_correct,evaluator_version,elapsed_ms) values(v_s.id,v_i.item_order,v_uid,p_idempotency_key,'machine',v_answer,v_picked,v_eval->>'selected_answer',(v_eval->>'is_correct')::boolean,'exam_prep_eval_session_question_v1',p_elapsed_ms) returning * into v_r;
    v_evidence_type:=case when v_i.reserve_role in ('diagnostic','learning','retest','mixed','timed') then v_i.reserve_role else 'learning' end;
    insert into private.exam_prep_evidence_events(user_id,component_code,skill_code,session_id,response_id,evidence_type,verification_status,is_correct,evidence_payload,source_version) values(v_uid,v_s.component_code,v_i.primary_skill_code,v_s.id,v_r.id,v_evidence_type,'app_verified',v_r.is_correct,jsonb_build_object('item_order',v_i.item_order,'reserve_role',v_i.reserve_role,'evaluator_version',v_r.evaluator_version),v_s.assessment_version||'|'||v_i.item_version);
  else
    v_artifact:=p_payload->'artifact'; if v_artifact is null or v_artifact='null'::jsonb or v_artifact='{}'::jsonb or v_artifact='[]'::jsonb then raise exception 'exam_prep_written_artifact_required'; end if;
    v_understanding:=private.exam_prep_evaluate_written_understanding_v1(v_i.written_task_id,p_payload->'understanding_checks');
    v_artifact:=v_artifact||jsonb_build_object('understanding_summary',v_understanding);
    insert into private.exam_prep_responses(session_id,item_order,user_id,client_idempotency_key,response_kind,learner_artifact,is_correct,evaluator_version,elapsed_ms) values(v_s.id,v_i.item_order,v_uid,p_idempotency_key,'written',v_artifact,null,'written_self_review_v1',p_elapsed_ms) returning * into v_r;
    insert into private.exam_prep_evidence_events(user_id,component_code,skill_code,session_id,response_id,evidence_type,verification_status,is_correct,evidence_payload,source_version) values(v_uid,v_s.component_code,v_i.primary_skill_code,v_s.id,v_r.id,'written','self_reviewed',null,jsonb_build_object('item_order',v_i.item_order,'artifact_present',true,'human_review_recommended',true,'understanding_check',v_understanding,'understanding_authority','app_checked_noncredit'),v_s.assessment_version||'|'||v_i.item_version);
  end if;
  update private.exam_prep_sessions set last_activity_at=now() where id=v_s.id;
  return private.exam_prep_safe_response_payload_v1(v_r.id,v_lang,false);
end; $$;
revoke execute on function public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text) from public,anon;
grant execute on function public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text) to authenticated,service_role;

create or replace function private.exam_prep_safe_response_payload_v1(p_response_id uuid, p_language text, p_replayed boolean)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare
  v_r private.exam_prep_responses%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_lang text;
  v_explanation text;
  v_feedback text;
  v_next text;
  v_rule private.exam_prep_diagnostic_rules%rowtype;
  v_feedback_allowed boolean := false;
  v_understanding jsonb;
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
  elsif v_r.response_kind='written' and v_feedback_allowed then
    v_understanding:=private.exam_prep_written_understanding_feedback_v1(v_r.id,v_lang);
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
    'understanding_check',v_understanding,
    'replayed',p_replayed
  ));
end; $$;
revoke all on function private.exam_prep_safe_response_payload_v1(uuid,text,boolean) from public,anon,authenticated;

-- Reference implementation for the first live history-bearing explanation task.
-- Existing P1CIR01-W01 prompt/rubric/assessment rows are intentionally untouched.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'v1','mcq',
  'Which equality correctly links degrees and radians?',
  'Какое равенство правильно связывает градусы и радианы?',
  'Gradus va radianlarni qaysi tenglik to‘g‘ri bog‘laydi?',
  '["90° = π rad","180° = π rad","180° = 2π rad","360° = π rad"]'::jsonb,
  '["90° = π рад","180° = π рад","180° = 2π рад","360° = π рад"]'::jsonb,
  '["90° = π rad","180° = π rad","180° = 2π rad","360° = π rad"]'::jsonb,
  1,
  '180° and π radians represent the same half-turn.',
  '180° и π радиан задают один и тот же развёрнутый угол.',
  '180° va π radian bir xil yarim aylanishni ifodalaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1CIR01-W01' and wt.component_code='P1' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,2,'v1','mcq',
  'What is (π/180) × (180/π)?',
  'Чему равно (π/180) × (180/π)?',
  '(π/180) × (180/π) nimaga teng?',
  '["π","180","1","π/180"]'::jsonb,
  '["π","180","1","π/180"]'::jsonb,
  '["π","180","1","π/180"]'::jsonb,
  2,
  'π and 180 cancel, so the product is 1.',
  'π и 180 сокращаются, поэтому произведение равно 1.',
  'π va 180 qisqaradi, shuning uchun ko‘paytma 1 ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1CIR01-W01' and wt.component_code='P1' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,3,'v1','mcq',
  'What happens if you convert degrees to radians and then convert the result back to degrees?',
  'Что произойдёт, если перевести градусы в радианы, а затем результат обратно в градусы?',
  'Gradusni radianga, keyin natijani yana gradusga o‘tkazsangiz nima bo‘ladi?',
  '["The original degree value is recovered","The value doubles","The value is divided by 180","The value becomes π times larger"]'::jsonb,
  '["Исходное значение в градусах восстановится","Значение удвоится","Значение разделится на 180","Значение станет в π раз больше"]'::jsonb,
  '["Boshlang‘ich gradus qiymati qayta tiklanadi","Qiymat ikki baravar bo‘ladi","Qiymat 180 ga bo‘linadi","Qiymat π marta kattalashadi"]'::jsonb,
  0,
  'The two conversion factors are reciprocals, so the second conversion reverses the first.',
  'Множители взаимно обратны, поэтому второй перевод отменяет действие первого.',
  'Ko‘paytuvchilar o‘zaro teskari, shuning uchun ikkinchi o‘girish birinchisini bekor qiladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1CIR01-W01' and wt.component_code='P1' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

do $$ declare v_task bigint; v_count int; v_payload jsonb; v_eval jsonb; begin
  select id into v_task from private.exam_prep_written_tasks
  where task_key='P1CIR01-W01' and component_code='P1' and lifecycle_state='published'
  order by id limit 1;
  if v_task is null then raise exception 'written understanding reference task missing'; end if;
  select count(*) into v_count from private.exam_prep_written_understanding_checks
  where written_task_id=v_task and lifecycle_state='published';
  if v_count<>3 then raise exception 'written understanding reference check count expected 3 got %',v_count; end if;
  v_payload:=private.exam_prep_written_understanding_payload_v1(v_task,'ru');
  if jsonb_array_length(v_payload)<>3 or v_payload::text ~ 'correct_index|rationale' then
    raise exception 'written understanding safe payload leaked private evaluation metadata';
  end if;
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"picked_index":1},{"check_order":2,"picked_index":2},{"check_order":3,"picked_index":0}]'::jsonb);
  if coalesce((v_eval->>'all_correct')::boolean,false) is not true or (v_eval->>'correct')::int<>3 then
    raise exception 'written understanding deterministic evaluator failed reference answers: %',v_eval;
  end if;
end $$;

commit;
