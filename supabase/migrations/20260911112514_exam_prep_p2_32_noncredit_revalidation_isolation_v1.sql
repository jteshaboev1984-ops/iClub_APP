begin;

-- P2-32: progress revalidation is explicitly non-crediting. Its sessions may be
-- stored for audit/recovery decisions, but they must not mutate objective skill
-- state, mastery, stage gates, or become stale/reused revalidation content.

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='rebuild_exam_prep_state_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text';
  if v_oid is null then raise exception 'P2-32 state rebuild missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='    from private.exam_prep_evidence_events e'||chr(10)||
         '    join private.exam_prep_sessions s on s.id=e.session_id'||chr(10)||
         '    where e.user_id=p_user_id';
  v_new:='    from private.exam_prep_evidence_events e'||chr(10)||
         '    join private.exam_prep_sessions s on s.id=e.session_id'||chr(10)||
         '    join private.exam_prep_session_authorizations sa'||chr(10)||
         '      on sa.id=s.authorization_id and sa.user_id=p_user_id and sa.academic_credit=true'||chr(10)||
         '    where e.user_id=p_user_id';
  if position(v_old in v_def)=0 then raise exception 'P2-32 state evidence anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_revalidation_item_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_case_id uuid, p_item_order integer';
  if v_oid is null then raise exception 'P2-32 revalidation authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='  select a.id into v_ass'||chr(10)||
         '  from private.exam_prep_assessments a'||chr(10)||
         '  where a.component_code=v_case.component_code and a.assessment_type=''retest'' and a.status=''published'''||chr(10)||
         '    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)'||chr(10)||
         '    and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)'||chr(10)||
         '  order by a.id limit 1;';
  v_new:='  v_ass:=private.exam_prep_select_fresh_retest_assessment_v1('||chr(10)||
         '    v_uid,v_case.component_code,v_item.skill_code'||chr(10)||
         '  );';
  if position(v_old in v_def)=0 then raise exception 'P2-32 revalidation content selector anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='record_my_exam_prep_interruption_v2'
    and pg_get_function_identity_arguments(p.oid)='p_interruption_started_on date, p_resumed_on date, p_interruption_kind text';
  if v_oid is null then raise exception 'P2-32 interruption v2 missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='            and exists('||chr(10)||
         '              select 1'||chr(10)||
         '              from private.exam_prep_assessments a'||chr(10)||
         '              join private.exam_prep_assessment_items ai on ai.assessment_id=a.id'||chr(10)||
         '              where a.component_code=v_component and a.assessment_type=''retest'' and a.status=''published'''||chr(10)||
         '                and ai.primary_skill_code=s.skill_code'||chr(10)||
         '            )';
  v_new:='            and private.exam_prep_fresh_retest_content_ready_v1('||chr(10)||
         '              v_uid,v_component,s.skill_code'||chr(10)||
         '            )';
  if position(v_old in v_def)=0 then raise exception 'P2-32 interruption selection anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke all on function private.rebuild_exam_prep_state_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.rebuild_exam_prep_state_v1(uuid,text) to service_role;
revoke execute on function public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer) to authenticated,service_role;
revoke execute on function public.record_my_exam_prep_interruption_v2(date,date,text) from public,anon;
grant execute on function public.record_my_exam_prep_interruption_v2(date,date,text) to authenticated,service_role;

commit;