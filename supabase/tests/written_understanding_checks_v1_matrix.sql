\set ON_ERROR_STOP on

begin;

-- This matrix runs only in the disposable CI database after the complete Exam
-- Prep migration stack has been applied. It deliberately does not create learner
-- evidence or alter established written-task rows.

do $$
declare
  v_task bigint;
  v_payload jsonb;
  v_eval jsonb;
  v_bad int;
  v_prompt_en text;
  v_rubric jsonb;
begin
  select id,prompt_en,rubric_json into v_task,v_prompt_en,v_rubric
  from private.exam_prep_written_tasks
  where task_key='P1CIR01-W01' and component_code='P1' and lifecycle_state='published'
  order by id limit 1;
  if v_task is null then raise exception 'written-understanding: P1CIR01 reference task missing'; end if;

  -- The original history-bearing task remains semantically untouched.
  if v_prompt_en <> 'An angle is 210°. (a) Convert it to radians in exact form. (b) A second angle is 5π/9 radians; convert it to degrees. (c) Explain why multiplying degrees by π/180 and radians by 180/π are inverse operations.' then
    raise exception 'written-understanding: reference prompt changed';
  end if;
  if coalesce((v_rubric->>'max_marks')::int,-1)<>7 then
    raise exception 'written-understanding: reference rubric changed';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks
  where written_task_id=v_task and lifecycle_state='published';
  if v_bad<>3 then raise exception 'written-understanding: expected 3 published companion checks, got %',v_bad; end if;

  -- Learner payload contains prompts/options/version identity only, never the answer key or private rationale.
  v_payload:=private.exam_prep_written_understanding_payload_v1(v_task,'en');
  if jsonb_array_length(v_payload)<>3 then raise exception 'written-understanding: EN payload count mismatch'; end if;
  if v_payload::text ~ 'correct_index|rationale|all_correct|is_correct' then
    raise exception 'written-understanding: private evaluation metadata leaked in learner payload';
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_payload) e(value)
    where coalesce(e.value->>'check_version','')<>'v1'
  ) then
    raise exception 'written-understanding: P1CIR01 safe payload must expose exact v1 version identity';
  end if;
  if jsonb_array_length(private.exam_prep_written_understanding_payload_v1(v_task,'ru'))<>3
     or jsonb_array_length(private.exam_prep_written_understanding_payload_v1(v_task,'uz'))<>3 then
    raise exception 'written-understanding: trilingual payload incomplete';
  end if;

  -- Correct and incorrect structured responses are deterministic and version-bound.
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"check_version":"v1","picked_index":1},{"check_order":2,"check_version":"v1","picked_index":2},{"check_order":3,"check_version":"v1","picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3 or coalesce((v_eval->>'all_correct')::boolean,false) is not true then
    raise exception 'written-understanding: correct versioned reference answers not accepted: %',v_eval;
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_eval->'results') e(value)
    where coalesce(e.value->>'check_version','')<>'v1'
  ) then
    raise exception 'written-understanding: evaluation did not preserve exact check version: %',v_eval;
  end if;

  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"check_version":"v1","picked_index":0},{"check_order":2,"check_version":"v1","picked_index":2},{"check_order":3,"check_version":"v1","picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>2 or coalesce((v_eval->>'all_correct')::boolean,true) is not false then
    raise exception 'written-understanding: incorrect versioned reference answer not detected: %',v_eval;
  end if;

  -- Legacy clients remain safe during rollout. Unversioned submitted answers use
  -- the current published version, while a missing structured answer stays
  -- explicitly unsubmitted/non-crediting.
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"picked_index":1},{"check_order":2,"picked_index":2},{"check_order":3,"picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3 then
    raise exception 'written-understanding: legacy unversioned answers not accepted: %',v_eval;
  end if;

  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,null);
  if coalesce((v_eval->>'configured')::boolean,false) is not true
     or coalesce((v_eval->>'submitted')::boolean,true) is not false
     or (v_eval->>'correct')::int<>0 then
    raise exception 'written-understanding: old-client compatibility state invalid: %',v_eval;
  end if;
end $$;

-- Prove the reason version identity exists: in the disposable database retire one
-- published rule, publish a reordered successor, and confirm an already-open v1
-- page is still graded against v1 while an unversioned legacy page follows the
-- current published successor. Everything rolls back at the end of this matrix.
do $$
declare
  v_task bigint;
  v_eval jsonb;
  v_payload jsonb;
begin
  select id into v_task
  from private.exam_prep_written_tasks
  where task_key='P1CIR01-W01' and component_code='P1' and lifecycle_state='published'
  order by id limit 1;

  update private.exam_prep_written_understanding_checks
  set lifecycle_state='retired'
  where written_task_id=v_task and check_order=1 and check_version='v1' and lifecycle_state='published';

  if not found then raise exception 'written-understanding: failed to retire disposable v1 reference'; end if;

  insert into private.exam_prep_written_understanding_checks(
    written_task_id,check_order,check_version,check_kind,
    prompt_en,prompt_ru,prompt_uz,
    options_en,options_ru,options_uz,correct_index,
    rationale_en,rationale_ru,rationale_uz,
    lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
  )
  select
    c.written_task_id,c.check_order,'ci-v2',c.check_kind,
    c.prompt_en,c.prompt_ru,c.prompt_uz,
    jsonb_build_array(c.options_en->1,c.options_en->0,c.options_en->2,c.options_en->3),
    jsonb_build_array(c.options_ru->1,c.options_ru->0,c.options_ru->2,c.options_ru->3),
    jsonb_build_array(c.options_uz->1,c.options_uz->0,c.options_uz->2,c.options_uz->3),
    0,
    c.rationale_en,c.rationale_ru,c.rationale_uz,
    'published','pass','pass','pass',now()
  from private.exam_prep_written_understanding_checks c
  where c.written_task_id=v_task and c.check_order=1 and c.check_version='v1' and c.lifecycle_state='retired';

  if not found then raise exception 'written-understanding: failed to publish disposable ci-v2 successor'; end if;

  -- The old page carries v1, so its original picked index must remain correct.
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"check_version":"v1","picked_index":1},{"check_order":2,"check_version":"v1","picked_index":2},{"check_order":3,"check_version":"v1","picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3
     or (v_eval->'results'->0->>'check_version')<>'v1' then
    raise exception 'written-understanding: retired v1 page was not evaluated against v1: %',v_eval;
  end if;

  -- An unversioned legacy page intentionally follows the current published rule.
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"picked_index":0},{"check_order":2,"picked_index":2},{"check_order":3,"picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3
     or (v_eval->'results'->0->>'check_version')<>'ci-v2' then
    raise exception 'written-understanding: current successor evaluation failed: %',v_eval;
  end if;

  v_payload:=private.exam_prep_written_understanding_payload_v1(v_task,'en');
  if (v_payload->0->>'check_version')<>'ci-v2'
     or (v_payload->0->'options'->>0)<>'180° = π rad' then
    raise exception 'written-understanding: current safe payload did not move to ci-v2 successor: %',v_payload;
  end if;
  if v_payload::text ~ 'correct_index|rationale|all_correct|is_correct' then
    raise exception 'written-understanding: successor safe payload leaked private metadata';
  end if;
end $$;

-- Browser roles may use only the guarded public RPCs; the private answer-key
-- table/helpers stay unreachable directly.
do $$ begin
  if has_table_privilege('anon','private.exam_prep_written_understanding_checks','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_written_understanding_checks','SELECT') then
    raise exception 'written-understanding: private check table directly readable by browser role';
  end if;
  if has_function_privilege('anon','private.exam_prep_written_understanding_payload_v1(bigint,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_written_understanding_payload_v1(bigint,text)','EXECUTE')
     or has_function_privilege('anon','private.exam_prep_evaluate_written_understanding_v1(bigint,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_evaluate_written_understanding_v1(bigint,jsonb)','EXECUTE')
     or has_function_privilege('anon','private.exam_prep_written_understanding_feedback_v1(uuid,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_written_understanding_feedback_v1(uuid,text)','EXECUTE') then
    raise exception 'written-understanding: private helper executable by browser role';
  end if;
  if has_function_privilege('anon','public.get_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
     or has_function_privilege('anon','public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)','EXECUTE') then
    raise exception 'written-understanding: anon can execute learner session RPCs';
  end if;
  if not has_function_privilege('authenticated','public.get_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)','EXECUTE') then
    raise exception 'written-understanding: authenticated learner RPC grant missing';
  end if;
end $$;

-- The evidence contract remains unchanged: written correctness is still nullable
-- and the only verification authority added here is metadata labelled
-- app_checked_noncredit inside the existing self_reviewed evidence payload.
do $$
declare
  v_submit text;
  v_feedback text;
  v_eval_def text;
  v_payload_def text;
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid='private.exam_prep_evidence_events'::regclass
      and pg_get_constraintdef(oid) like '%self_reviewed%'
  ) then
    raise exception 'written-understanding: established self-reviewed evidence contract missing';
  end if;

  v_submit:=pg_get_functiondef('public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)'::regprocedure);
  v_feedback:=pg_get_functiondef('private.exam_prep_written_understanding_feedback_v1(uuid,text)'::regprocedure);
  v_eval_def:=pg_get_functiondef('private.exam_prep_evaluate_written_understanding_v1(bigint,jsonb)'::regprocedure);
  v_payload_def:=pg_get_functiondef('private.exam_prep_written_understanding_payload_v1(bigint,text)'::regprocedure);

  if position('understanding_authority' in v_submit)=0
     or position('app_checked_noncredit' in v_submit)=0 then
    raise exception 'written-understanding: non-crediting authority marker missing from submit RPC';
  end if;
  if position('understanding_checks' in pg_get_functiondef('public.get_exam_prep_session_safe_v1(uuid,text)'::regprocedure))=0 then
    raise exception 'written-understanding: safe session payload bridge missing';
  end if;

  -- Version identity must survive payload -> evaluation -> evidence -> feedback so
  -- later additive content versions cannot reinterpret an already-seen option index.
  if position('check_version' in v_payload_def)=0
     or position('check_version' in v_eval_def)=0
     or position('check_version' in v_feedback)=0 then
    raise exception 'written-understanding: version identity is not preserved end-to-end';
  end if;

  -- Server correctness must never be merged into learner_artifact because that
  -- artifact is readable back through the session payload during active work.
  if position('understanding_summary' in v_submit)>0
     or position('understanding_summary' in v_feedback)>0 then
    raise exception 'written-understanding: server evaluation leaked through learner artifact contract';
  end if;
  if position('evidence_payload' in v_feedback)=0 then
    raise exception 'written-understanding: feedback must read private evidence metadata';
  end if;
end $$;

-- Final curated-scope contract. These counts are intentionally explicit: adding,
-- removing or re-versioning a published learner check must be reviewed together
-- with this matrix instead of silently expanding the production surface.
do $$
declare
  v_checks int;
  v_tasks int;
  v_p1_checks int;
  v_p1_tasks int;
  v_p5_checks int;
  v_p5_tasks int;
  v_single int;
  v_multi int;
  v_max int;
  v_bad int;
begin
  select count(*)::int, count(distinct c.written_task_id)::int
    into v_checks,v_tasks
  from private.exam_prep_written_understanding_checks c
  where c.lifecycle_state='published';

  if v_checks<>39 or v_tasks<>36 then
    raise exception 'written-understanding: curated scope changed; expected 39 checks across 36 tasks, got % across %',v_checks,v_tasks;
  end if;

  select count(c.id)::int,count(distinct wt.id)::int
    into v_p1_checks,v_p1_tasks
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published' and wt.lifecycle_state='published' and wt.component_code='P1';

  select count(c.id)::int,count(distinct wt.id)::int
    into v_p5_checks,v_p5_tasks
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published' and wt.lifecycle_state='published' and wt.component_code='P5';

  if v_p1_checks<>20 or v_p1_tasks<>17 or v_p5_checks<>19 or v_p5_tasks<>19 then
    raise exception 'written-understanding: component scope changed; P1 checks/tasks=%/%, P5=%/%',v_p1_checks,v_p1_tasks,v_p5_checks,v_p5_tasks;
  end if;

  select
    count(*) filter (where check_count=1)::int,
    count(*) filter (where check_count>1)::int,
    max(check_count)::int
    into v_single,v_multi,v_max
  from (
    select c.written_task_id,count(*)::int as check_count
    from private.exam_prep_written_understanding_checks c
    where c.lifecycle_state='published'
    group by c.written_task_id
  ) q;

  if v_single<>34 or v_multi<>2 or v_max<>3 then
    raise exception 'written-understanding: per-task cardinality changed; single=%, multi=%, max=%',v_single,v_multi,v_max;
  end if;

  -- Every published companion must belong to an active P1/P5 written task.
  select count(*)::int into v_bad
  from private.exam_prep_written_understanding_checks c
  left join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published'
    and (wt.id is null or wt.lifecycle_state<>'published' or wt.component_code not in ('P1','P5'));
  if v_bad<>0 then raise exception 'written-understanding: published check attached outside published P1/P5 scope: %',v_bad; end if;

  -- All three learner languages must have complete, shape-consistent content.
  select count(*)::int into v_bad
  from private.exam_prep_written_understanding_checks c
  where c.lifecycle_state='published'
    and (
      coalesce(btrim(c.prompt_en),'')='' or coalesce(btrim(c.prompt_ru),'')='' or coalesce(btrim(c.prompt_uz),'')=''
      or coalesce(btrim(c.rationale_en),'')='' or coalesce(btrim(c.rationale_ru),'')='' or coalesce(btrim(c.rationale_uz),'')=''
      or coalesce(btrim(c.check_version),'')=''
      or jsonb_typeof(c.options_en)<>'array' or jsonb_typeof(c.options_ru)<>'array' or jsonb_typeof(c.options_uz)<>'array'
      or jsonb_array_length(c.options_en)<2
      or jsonb_array_length(c.options_en)<>jsonb_array_length(c.options_ru)
      or jsonb_array_length(c.options_en)<>jsonb_array_length(c.options_uz)
      or c.correct_index<0
      or c.correct_index>=jsonb_array_length(c.options_en)
      or c.check_kind<>'mcq'
      or c.check_order<1
      or c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass'
    );
  if v_bad<>0 then raise exception 'written-understanding: published content/QA invariant failed for % rows',v_bad; end if;

  -- The privacy guarantee is checked over the entire published surface and all
  -- learner languages, not only the original P1CIR01 reference task. A version
  -- identifier is required but never rendered by the browser UI.
  select count(*)::int into v_bad
  from (
    select c.written_task_id,count(*)::int as expected_count
    from private.exam_prep_written_understanding_checks c
    where c.lifecycle_state='published'
    group by c.written_task_id
  ) t
  cross join (values('en'),('ru'),('uz')) as l(lang)
  cross join lateral (select private.exam_prep_written_understanding_payload_v1(t.written_task_id,l.lang) as payload) p
  where jsonb_array_length(p.payload)<>t.expected_count
     or p.payload::text ~ 'correct_index|rationale|all_correct|is_correct'
     or exists (
       select 1 from jsonb_array_elements(p.payload) e(value)
       where coalesce(e.value->>'check_version','')=''
     );
  if v_bad<>0 then raise exception 'written-understanding: full-scope learner payload/version invariant failed for % task/language pairs',v_bad; end if;
end $$;

rollback;

select 'WRITTEN_UNDERSTANDING_CHECKS_V1_GREEN' as result;
