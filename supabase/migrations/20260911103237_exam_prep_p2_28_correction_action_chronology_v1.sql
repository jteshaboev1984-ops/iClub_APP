begin;

create or replace function private.exam_prep_correction_action_rank_v1(p_action_type text)
returns smallint
language sql
immutable
security definer
set search_path=''
as $$
  select case p_action_type
    when 'case_closed' then 90::smallint
    when 'case_reopened' then 90::smallint
    when 'retest_passed' then 80::smallint
    when 'retest_failed' then 80::smallint
    when 'retest_scheduled' then 70::smallint
    when 'retest_authorized' then 60::smallint
    when 'remediation_completed' then 50::smallint
    when 'remediation_incomplete' then 50::smallint
    when 'remediation_authorized' then 40::smallint
    when 'error_observed' then 30::smallint
    else 10::smallint
  end;
$$;
revoke all on function private.exam_prep_correction_action_rank_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_action_rank_v1(text) to service_role;

create or replace function private.exam_prep_log_correction_action_v1(
  p_case_id uuid,
  p_action_type text,
  p_session_id uuid default null,
  p_evidence_id uuid default null,
  p_retest_event_id uuid default null,
  p_payload jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare v_case private.exam_prep_correction_cases%rowtype; v_id uuid;
begin
  select * into v_case from private.exam_prep_correction_cases where id=p_case_id;
  if v_case.id is null then raise exception 'exam_prep_correction_case_not_found'; end if;
  insert into private.exam_prep_correction_actions(
    correction_case_id,user_id,component_code,skill_code,action_type,
    session_id,evidence_id,retest_event_id,payload,created_at
  ) values(
    v_case.id,v_case.user_id,v_case.component_code,v_case.skill_code,p_action_type,
    p_session_id,p_evidence_id,p_retest_event_id,coalesce(p_payload,'{}'::jsonb),clock_timestamp()
  ) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function private.exam_prep_log_correction_action_v1(uuid,text,uuid,uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function private.exam_prep_log_correction_action_v1(uuid,text,uuid,uuid,uuid,jsonb) to service_role;

do $$
declare
  v_oid oid;
  v_def text;
  v_old text:='order by a.created_at desc,a.id desc';
  v_new text:='order by a.created_at desc,private.exam_prep_correction_action_rank_v1(a.action_type) desc,a.id desc';
begin
  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_correction_queue_payload_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text';
  if v_oid is null then raise exception 'P2-28 correction queue function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  if position(v_old in v_def)=0 then raise exception 'P2-28 correction queue chronology anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_skill_detail_payload_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text, p_skill_code text';
  if v_oid is null then raise exception 'P2-28 skill detail function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  if position(v_old in v_def)=0 then raise exception 'P2-28 skill detail chronology anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke all on function private.exam_prep_correction_queue_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_queue_payload_v1(uuid,text) to service_role;
revoke all on function private.exam_prep_skill_detail_payload_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_detail_payload_v1(uuid,text,text) to service_role;

commit;