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

  -- Learner payload contains prompts/options only, never the answer key or private rationale.
  v_payload:=private.exam_prep_written_understanding_payload_v1(v_task,'en');
  if jsonb_array_length(v_payload)<>3 then raise exception 'written-understanding: EN payload count mismatch'; end if;
  if v_payload::text ~ 'correct_index|rationale|all_correct|is_correct' then
    raise exception 'written-understanding: private evaluation metadata leaked in learner payload';
  end if;
  if jsonb_array_length(private.exam_prep_written_understanding_payload_v1(v_task,'ru'))<>3
     or jsonb_array_length(private.exam_prep_written_understanding_payload_v1(v_task,'uz'))<>3 then
    raise exception 'written-understanding: trilingual payload incomplete';
  end if;

  -- Correct and incorrect structured responses are deterministic.
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"picked_index":1},{"check_order":2,"picked_index":2},{"check_order":3,"picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>3 or coalesce((v_eval->>'all_correct')::boolean,false) is not true then
    raise exception 'written-understanding: correct reference answers not accepted: %',v_eval;
  end if;

  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,
    '[{"check_order":1,"picked_index":0},{"check_order":2,"picked_index":2},{"check_order":3,"picked_index":0}]'::jsonb);
  if (v_eval->>'correct')::int<>2 or coalesce((v_eval->>'all_correct')::boolean,true) is not false then
    raise exception 'written-understanding: incorrect reference answer not detected: %',v_eval;
  end if;

  -- Old clients remain safe during rollout: absence of structured answers does
  -- not fabricate correctness and remains explicitly unsubmitted/non-crediting.
  v_eval:=private.exam_prep_evaluate_written_understanding_v1(v_task,null);
  if coalesce((v_eval->>'configured')::boolean,false) is not true
     or coalesce((v_eval->>'submitted')::boolean,true) is not false
     or (v_eval->>'correct')::int<>0 then
    raise exception 'written-understanding: old-client compatibility state invalid: %',v_eval;
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

  if position('understanding_authority' in v_submit)=0
     or position('app_checked_noncredit' in v_submit)=0 then
    raise exception 'written-understanding: non-crediting authority marker missing from submit RPC';
  end if;
  if position('understanding_checks' in pg_get_functiondef('public.get_exam_prep_session_safe_v1(uuid,text)'::regprocedure))=0 then
    raise exception 'written-understanding: safe session payload bridge missing';
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

rollback;

select 'WRITTEN_UNDERSTANDING_CHECKS_V1_GREEN' as result;
