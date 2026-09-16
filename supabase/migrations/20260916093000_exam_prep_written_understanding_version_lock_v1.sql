begin;

-- Version-lock learner understanding answers without changing the public RPC
-- signatures. check_version is safe metadata; answer keys and rationales remain
-- private. Old clients that omit check_version continue to use the current
-- published version.

create or replace function private.exam_prep_written_understanding_payload_v1(
  p_written_task_id bigint,
  p_language text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_lang text; v_rows jsonb;
begin
  v_lang:=lower(coalesce(p_language,'en'));
  if v_lang not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;
  if p_written_task_id is null then return '[]'::jsonb; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'check_order',c.check_order,
    'check_version',c.check_version,
    'check_kind',c.check_kind,
    'prompt',case v_lang when 'ru' then c.prompt_ru when 'uz' then c.prompt_uz else c.prompt_en end,
    'options',case v_lang when 'ru' then c.options_ru when 'uz' then c.options_uz else c.options_en end
  ) order by c.check_order),'[]'::jsonb)
  into v_rows
  from private.exam_prep_written_understanding_checks c
  where c.written_task_id=p_written_task_id and c.lifecycle_state='published';

  return v_rows;
end;
$$;

create or replace function private.exam_prep_evaluate_written_understanding_v1(
  p_written_task_id bigint,
  p_answers jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_total int:=0;
  v_correct int:=0;
  v_expected record;
  v_rule record;
  v_answer jsonb;
  v_picked int;
  v_requested_version text;
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

  for v_expected in
    select c.check_order
    from private.exam_prep_written_understanding_checks c
    where c.written_task_id=p_written_task_id and c.lifecycle_state='published'
    order by c.check_order
  loop
    v_answer:=null;
    select e.value into v_answer
    from jsonb_array_elements(p_answers) e(value)
    where coalesce(e.value->>'check_order','')=v_expected.check_order::text;

    if v_answer is null then
      raise exception 'exam_prep_written_understanding_answer_missing order=%',v_expected.check_order;
    end if;
    if (
      select count(*)
      from jsonb_array_elements(p_answers) e(value)
      where coalesce(e.value->>'check_order','')=v_expected.check_order::text
    )<>1 then
      raise exception 'exam_prep_written_understanding_answer_duplicate order=%',v_expected.check_order;
    end if;

    if coalesce(v_answer->>'picked_index','') !~ '^[0-9]+$' then
      raise exception 'exam_prep_written_understanding_bad_picked_index';
    end if;
    v_picked:=(v_answer->>'picked_index')::int;
    v_requested_version:=nullif(btrim(coalesce(v_answer->>'check_version','')),'');

    if v_requested_version is null then
      select c.check_order,c.check_version,c.correct_index,jsonb_array_length(c.options_en) as option_count
      into v_rule
      from private.exam_prep_written_understanding_checks c
      where c.written_task_id=p_written_task_id
        and c.check_order=v_expected.check_order
        and c.lifecycle_state='published'
      limit 1;
    else
      select c.check_order,c.check_version,c.correct_index,jsonb_array_length(c.options_en) as option_count
      into v_rule
      from private.exam_prep_written_understanding_checks c
      where c.written_task_id=p_written_task_id
        and c.check_order=v_expected.check_order
        and c.check_version=v_requested_version
        and c.lifecycle_state in ('published','retired')
        and c.qa_math_status='pass'
        and c.qa_language_status='pass'
        and c.qa_technical_status='pass'
      order by case when c.lifecycle_state='published' then 0 else 1 end,c.id desc
      limit 1;
    end if;

    if not found or v_rule.check_order is null then
      raise exception 'exam_prep_written_understanding_bad_check_version order=% version=%',v_expected.check_order,coalesce(v_requested_version,'<current>');
    end if;
    if v_picked<0 or v_picked>=v_rule.option_count then
      raise exception 'exam_prep_written_understanding_bad_picked_index';
    end if;

    if v_picked=v_rule.correct_index then v_correct:=v_correct+1; end if;
    v_results:=v_results||jsonb_build_array(jsonb_build_object(
      'check_order',v_rule.check_order,
      'check_version',v_rule.check_version,
      'picked_index',v_picked,
      'is_correct',(v_picked=v_rule.correct_index)
    ));
  end loop;

  return jsonb_build_object(
    'configured',true,
    'submitted',true,
    'total',v_total,
    'correct',v_correct,
    'all_correct',(v_correct=v_total),
    'results',v_results
  );
end;
$$;

create or replace function private.exam_prep_written_understanding_feedback_v1(
  p_response_id uuid,
  p_language text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
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
  v_version text;
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
    v_version:=nullif(btrim(coalesce(v_row->>'check_version','')),'');

    if v_version is null then
      select c.check_order,c.check_version,
        case v_lang when 'ru' then c.rationale_ru when 'uz' then c.rationale_uz else c.rationale_en end as rationale
      into v_rule
      from private.exam_prep_written_understanding_checks c
      where c.written_task_id=v_i.written_task_id
        and c.check_order=v_order
        and c.lifecycle_state='published'
      limit 1;
    else
      select c.check_order,c.check_version,
        case v_lang when 'ru' then c.rationale_ru when 'uz' then c.rationale_uz else c.rationale_en end as rationale
      into v_rule
      from private.exam_prep_written_understanding_checks c
      where c.written_task_id=v_i.written_task_id
        and c.check_order=v_order
        and c.check_version=v_version
        and c.lifecycle_state in ('published','retired')
        and c.qa_math_status='pass'
        and c.qa_language_status='pass'
        and c.qa_technical_status='pass'
      order by case when c.lifecycle_state='published' then 0 else 1 end,c.id desc
      limit 1;
    end if;

    if found and v_rule.check_order is not null then
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
end;
$$;

revoke all on function private.exam_prep_written_understanding_payload_v1(bigint,text) from public,anon,authenticated;
revoke all on function private.exam_prep_evaluate_written_understanding_v1(bigint,jsonb) from public,anon,authenticated;
revoke all on function private.exam_prep_written_understanding_feedback_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_written_understanding_payload_v1(bigint,text) to service_role;
grant execute on function private.exam_prep_evaluate_written_understanding_v1(bigint,jsonb) to service_role;
grant execute on function private.exam_prep_written_understanding_feedback_v1(uuid,text) to service_role;

-- Migration acceptance: version metadata is learner-safe, deterministic evaluation
-- is version-aware, and legacy unversioned answers remain accepted.
do $$
declare
  v_task bigint;
  v_payload jsonb;
  v_eval jsonb;
begin
  select id into v_task
  from private.exam_prep_written_tasks
  where task_key='P1CIR01-W01' and component_code='P1' and lifecycle_state='published'
  order by id limit 1;
  if v_task is null then raise exception 'written-understanding-version-lock: reference task missing'; end if;

  v_payload:=private.exam_prep_written_understanding_payload_v1(v_task,'en');
  if jsonb_array_length(v_payload)<>3
     or exists (
       select 1 from jsonb_array_elements(v_payload) e(value)
       where coalesce(e.value->>'check_version','')=''
     ) then
    raise exception 'written-understanding-version-lock: safe payload version metadata missing';
  end if;
  if v_payload::text ~ 'correct_index|rationale|all_correct|is_correct' then
    raise exception 'written-understanding-version-lock: private metadata leaked';
  end if;

  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"check_version":"v1","picked_index":1},{"check_order":2,"check_version":"v1","picked_index":2},{"check_order":3,"check_version":"v1","picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3
     or exists (
       select 1 from jsonb_array_elements(v_eval->'results') e(value)
       where e.value->>'check_version'<>'v1'
     ) then
    raise exception 'written-understanding-version-lock: versioned evaluation failed: %',v_eval;
  end if;

  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"picked_index":1},{"check_order":2,"picked_index":2},{"check_order":3,"picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3 then
    raise exception 'written-understanding-version-lock: legacy unversioned evaluation failed: %',v_eval;
  end if;
end $$;

commit;
