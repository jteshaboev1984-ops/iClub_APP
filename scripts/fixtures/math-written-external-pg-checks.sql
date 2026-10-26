-- Run on disposable PG17 after fixtures + migration. Never production.
\set ON_ERROR_STOP on
do $pg$
declare v jsonb; n integer;
begin
  if has_function_privilege('anon','public.advance_exam_prep_written_step_safe_v1(uuid,integer,text)','execute')
     or has_function_privilege('anon','public.get_exam_prep_written_criteria_safe_v1(uuid,integer,text)','execute')
  then raise exception 'anonymous_can_access_written_rpcs'; end if;
  if not has_function_privilege('authenticated','public.advance_exam_prep_written_step_safe_v1(uuid,integer,text)','execute')
  then raise exception 'authenticated_cannot_access_written_rpc'; end if;
  if has_table_privilege('authenticated','private.exam_prep_written_step_advances_v1','select')
  then raise exception 'learner_has_direct_ledger_access'; end if;

  perform set_config('iclub.test_uid','00000000-0000-4000-8000-000000000001',true);
  v:=public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000101','en');
  if v->'items'->3->>'written_external'<>'false'
    then raise exception 'new_mode_must_start_off'; end if;
  begin
    perform public.advance_exam_prep_written_step_safe_v1('00000000-0000-4000-8000-000000000101',4,'step-request-0001');
    raise exception 'security_gate_not_enforced';
  exception when insufficient_privilege then null; end;
  select count(*) into n from private.exam_prep_written_step_advances_v1;
  if n<>0 then raise exception 'off_mode_wrote_advancement';end if;
  v:=public.get_exam_prep_written_step_status_safe_v1(
    '00000000-0000-4000-8000-000000000101',4);
  if v->>'can_advance'<>'false' then
    raise exception 'off_mode_status_must_deny_advance';end if;

  insert into private.exam_prep_written_learning_config_v1(component_code,enabled)
    values('P1',true),('P5',false);
  insert into private.exam_prep_written_learning_allowlist_v1(user_id,component_code)
    values('00000000-0000-4000-8000-000000000001','P1');

  v:=public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000101','en');
  if v->'items'->3->>'written_external'<>'true' or
     v->'items'->3->>'is_complete'<>'false' then
    raise exception 'eligible_current_written_missing';end if;
  v:=public.get_exam_prep_written_step_status_safe_v1(
    '00000000-0000-4000-8000-000000000101',4);
  if v->>'can_advance'<>'true' then
    raise exception 'eligible_status_must_allow_advance';end if;

  v:=public.get_exam_prep_written_criteria_safe_v1('00000000-0000-4000-8000-000000000101',4,'en');
  if v->>'available'<>'true' or v->'requirements'->>0<>'Power rule'
  then raise exception 'criteria_mismatch';end if;

  v:=public.advance_exam_prep_written_step_safe_v1('00000000-0000-4000-8000-000000000101',4,'step-request-0001');
  if v->>'status'<>'advanced' or v->>'replayed'<>'false' then
    raise exception 'advance_failed';end if;
  v:=public.advance_exam_prep_written_step_safe_v1('00000000-0000-4000-8000-000000000101',4,'step-request-0001');
  if v->>'status'<>'advanced' or v->>'replayed'<>'true' then
    raise exception 'idempotent_replay_failed';end if;
  v:=public.get_exam_prep_written_step_status_safe_v1('00000000-0000-4000-8000-000000000101',4);
  if v->>'status'<>'advanced' then raise exception 'status_not_confirmed';end if;
  v:=public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000101','en');
  if v->'items'->3->>'is_complete'<>'true' or
     v->'items'->3->>'completion_status'<>'advanced_in_plan_only' then
    raise exception 'reader_did_not_merge_navigation';end if;
  begin
    insert into private.exam_prep_responses(session_id,item_order,user_id,response_kind,is_correct)
    values('00000000-0000-4000-8000-000000000101',4,
      '00000000-0000-4000-8000-000000000001','written',null);
    raise exception 'legacy_answer_conflict_not_rejected';
  exception when raise_exception then
    if sqlerrm='legacy_answer_conflict_not_rejected' then raise;end if;
    -- A trigger-denied legacy response is expected, not a fabricated written record.
    if exists (select 1 from private.exam_prep_responses
      where session_id='00000000-0000-4000-8000-000000000101' and item_order=4)
    then raise exception 'invalid_legacy_row';end if;
  end;
  begin
    perform public.finalize_exam_prep_session_safe_v1('00000000-0000-4000-8000-000000000101','old-finalize-0001');
    raise exception 'old_finalizer_accepted_3_of_4';
  exception when raise_exception then
    if sqlerrm='old_finalizer_accepted_3_of_4' then raise;end if;
  end;

  v:=public.finalize_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000101','new-finalize-0001');
  if v->>'status'<>'finalized' or v->>'written_advanced'<>'1'
  then raise exception 'new_finalizer_failed';end if;
  v:=public.get_exam_prep_session_review_written_v1('00000000-0000-4000-8000-000000000101','en');
  if v->'summary'->>'written_advanced'<>'1' or
     v->'summary'->>'written_submitted'<>'0' or
     v->'summary'->>'machine_total'<>'3' then
    raise exception 'grade_or_history_not_separate';end if;
  v:=public.get_exam_prep_recent_results_written_v1('P1',10);
  if v->'results'->0->>'written_advanced'<>'1' then
    raise exception 'recent_results_missing_navigation';end if;

  select count(*) into n from private.exam_prep_responses where session_id='00000000-0000-4000-8000-000000000101';
  if n<>3 then raise exception 'response_rows_mutated';end if;
  select count(*) into n from private.exam_prep_evidence_events;
  if n<>0 then raise exception 'fabricated_mastery_evidence';end if;

  -- Emergency OFF must preserve read-after-commit for the existing learner.
  update private.exam_prep_written_learning_config_v1 set enabled=false where component_code='P1';
  v:=public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000101','en');
  if v->'items'->3->>'written_external'<>'true' then
    raise exception 'emergency_off_hides_existing_progress';end if;

  -- Other learner cannot read or advance someone else's session.
  perform set_config('iclub.test_uid','00000000-0000-4000-8000-000000000002',true);
  -- Ownership failures deliberately raise SQLSTATE P0002 (no_data_found).
  -- Do not accept arbitrary errors or accidentally catch our own failure sentinel.
  begin
    perform public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000101','en');
    raise exception 'cross_learner_read_allowed';
  exception when no_data_found then null;
  end;
  begin
    perform public.advance_exam_prep_written_step_safe_v1('00000000-0000-4000-8000-000000000101',4,'unauth-step-0001');
    raise exception 'cross_learner_write_allowed';
  exception when no_data_found then null;
  end;
  perform set_config('iclub.test_uid','00000000-0000-4000-8000-000000000001',true);
  v:=public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000103','en');
  if v->'items'->0->>'written_external'<>'false' then
    raise exception 'P5_must_remain_separately_disabled';end if;
  -- After independent P5 enablement, the same paper-based contract must
  -- advance and finalize P5 without changing any P1 evidence or response.
  update private.exam_prep_written_learning_config_v1
    set enabled=true where component_code='P5';
  insert into private.exam_prep_written_learning_allowlist_v1(user_id,component_code)
    values('00000000-0000-4000-8000-000000000001','P5');
  v:=public.get_exam_prep_session_written_v1('00000000-0000-4000-8000-000000000103','en');
  if v->'items'->0->>'written_external'<>'true' then
    raise exception 'P5_independent_enable_missing';end if;
  v:=public.advance_exam_prep_written_step_safe_v1(
    '00000000-0000-4000-8000-000000000103',1,'P5-next-step-0001');
  if v->>'status'<>'advanced' then raise exception 'P5_advance_failed';end if;
  v:=public.finalize_exam_prep_session_written_v1(
    '00000000-0000-4000-8000-000000000103','P5-finalize-0001');
  if v->>'status'<>'finalized' or v->>'written_advanced'<>'1' then
    raise exception 'P5_finalize_failed';end if;
  select count(*) into n from private.exam_prep_responses
    where session_id in ('00000000-0000-4000-8000-000000000101',
                         '00000000-0000-4000-8000-000000000103');
  if n<>3 then raise exception 'P1_P5_original_response_rows_changed';end if;
  select count(*) into n from private.exam_prep_evidence_events;
  if n<>0 then raise exception 'P1_P5_fabricated_evidence';end if;
  raise notice 'PG17 ISOLATED WRITTEN CONTRACT GREEN: P1/P5, auth, OFF gate, criteria, replay, history, original responses intact';
end $pg$;
