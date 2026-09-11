begin;

-- P2-33: delayed retest timing is re-derived at authorization time.
-- A corrupted/early stored due date must never burn fresh reserve or close a correction early.
-- This preserves the source-backed delayed-evidence law without changing learner history.

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_retest_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_correction_case_id uuid';
  if v_oid is null then raise exception 'P2-33 correction retest authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_ass bigint;'||chr(10)||'  v_auth uuid;';
  v_new:='  v_ass bigint;'||chr(10)||'  v_auth uuid;'||chr(10)||'  v_contract private.exam_prep_skill_contracts%rowtype;'||chr(10)||'  v_required_due timestamptz;';
  if position(v_old in v_def)=0 then raise exception 'P2-33 correction declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  if v_rt.id is null then raise exception ''exam_prep_retest_event_not_found''; end if;'||chr(10)||
         '  if v_rt.due_not_before is not null and v_rt.due_not_before>now() then raise exception ''exam_prep_retest_too_early''; end if;';
  v_new:='  if v_rt.id is null then raise exception ''exam_prep_retest_event_not_found''; end if;'||chr(10)||
         '  select * into v_contract from private.exam_prep_skill_contracts c'||chr(10)||
         '  where c.program_version_id=(select program_version_id from private.exam_prep_exam_profiles where user_id=v_uid)'||chr(10)||
         '    and c.component_code=v_case.component_code and c.skill_code=v_case.skill_code;'||chr(10)||
         '  if v_contract.skill_code is null then raise exception ''exam_prep_retest_contract_missing''; end if;'||chr(10)||
         '  v_required_due:=greatest('||chr(10)||
         '    v_rt.created_at+interval ''2 days'','||chr(10)||
         '    v_case.opened_at+(coalesce(v_contract.min_retest_delay_days,0)*interval ''1 day'')'||chr(10)||
         '  );'||chr(10)||
         '  if now()<v_required_due then raise exception ''exam_prep_retest_too_early''; end if;'||chr(10)||
         '  if v_rt.due_not_before is not null and v_rt.due_not_before>now() then raise exception ''exam_prep_retest_too_early''; end if;';
  if position(v_old in v_def)=0 then raise exception 'P2-33 correction timing anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);
  execute v_def;

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_plan_item_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_plan_id uuid, p_priority_order integer';
  if v_oid is null then raise exception 'P2-33 plan authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_contract private.exam_prep_skill_contracts%rowtype;'||chr(10)||'  v_has_mixed boolean:=false;';
  v_new:='  v_contract private.exam_prep_skill_contracts%rowtype;'||chr(10)||'  v_has_mixed boolean:=false;'||chr(10)||'  v_first_non_retest_at timestamptz;'||chr(10)||'  v_required_due timestamptz;';
  if position(v_old in v_def)=0 then raise exception 'P2-33 retention declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='      if v_item.due_at is null then raise exception ''exam_prep_retention_retest_due_required''; end if;'||chr(10)||
         '      if v_item.due_at>now() then raise exception ''exam_prep_retest_too_early''; end if;'||chr(10)||chr(10)||
         '      perform private.rebuild_exam_prep_state_v1(v_uid,v_plan.component_code);';
  v_new:='      if v_item.due_at is null then raise exception ''exam_prep_retention_retest_due_required''; end if;'||chr(10)||chr(10)||
         '      perform private.rebuild_exam_prep_state_v1(v_uid,v_plan.component_code);';
  if position(v_old in v_def)=0 then raise exception 'P2-33 early plan due anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='      if v_state.skill_code is null or v_contract.skill_code is null then raise exception ''exam_prep_retention_retest_state_missing''; end if;'||chr(10)||
         '      if v_state.objective_level<2 then raise exception ''exam_prep_retention_retest_coverage_required''; end if;';
  v_new:='      if v_state.skill_code is null or v_contract.skill_code is null then raise exception ''exam_prep_retention_retest_state_missing''; end if;'||chr(10)||
         '      select min(e.created_at) into v_first_non_retest_at'||chr(10)||
         '      from private.exam_prep_evidence_events e'||chr(10)||
         '      join private.exam_prep_sessions ses on ses.id=e.session_id and ses.user_id=v_uid and ses.status=''finalized'''||chr(10)||
         '      join private.exam_prep_session_authorizations sa on sa.id=ses.authorization_id and sa.user_id=v_uid and sa.academic_credit=true'||chr(10)||
         '      where e.user_id=v_uid and e.component_code=v_plan.component_code and e.skill_code=v_item.skill_code'||chr(10)||
         '        and e.evidence_type<>''retest'';'||chr(10)||
         '      if v_first_non_retest_at is null then raise exception ''exam_prep_retention_retest_anchor_missing''; end if;'||chr(10)||
         '      v_required_due:=greatest('||chr(10)||
         '        v_first_non_retest_at+(coalesce(v_contract.min_retest_delay_days,0)*interval ''1 day''),'||chr(10)||
         '        v_first_non_retest_at+interval ''2 days'''||chr(10)||
         '      );'||chr(10)||
         '      if v_item.due_at<v_required_due then raise exception ''exam_prep_retention_retest_due_integrity_error''; end if;'||chr(10)||
         '      if now()<v_required_due or v_item.due_at>now() then raise exception ''exam_prep_retest_too_early''; end if;'||chr(10)||
         '      if v_state.objective_level<2 then raise exception ''exam_prep_retention_retest_coverage_required''; end if;';
  if position(v_old in v_def)=0 then raise exception 'P2-33 retention timing anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.authorize_exam_prep_retest_safe_v1(uuid) from public,anon;
grant execute on function public.authorize_exam_prep_retest_safe_v1(uuid) to authenticated,service_role;
revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;

commit;
