begin;

-- P2-35: academic-facing overview/tracker/detail payloads must describe the same
-- finalized, academic-credit evidence universe used by the state engine.
-- Recovery revalidation remains visible through the recovery payload only.

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  -- Overview: last academic evidence only.
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_overview_payload_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text';
  if v_oid is null then raise exception 'P2-35 overview payload missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='  select * into v_latest'||chr(10)||
         '  from private.exam_prep_evidence_events e'||chr(10)||
         '  where e.user_id=p_user_id and e.component_code=p_component_code'||chr(10)||
         '  order by e.created_at desc,e.id desc'||chr(10)||
         '  limit 1;';
  v_new:='  select e.* into v_latest'||chr(10)||
         '  from private.exam_prep_evidence_events e'||chr(10)||
         '  join private.exam_prep_sessions s on s.id=e.session_id and s.user_id=p_user_id and s.status=''finalized'''||chr(10)||
         '  join private.exam_prep_session_authorizations sa on sa.id=s.authorization_id and sa.user_id=p_user_id and sa.academic_credit=true'||chr(10)||
         '  where e.user_id=p_user_id and e.component_code=p_component_code'||chr(10)||
         '  order by e.created_at desc,e.id desc'||chr(10)||
         '  limit 1;';
  if position(v_old in v_def)=0 then raise exception 'P2-35 overview evidence anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  -- Skill detail: evidence history is academic/finalized only.
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_skill_detail_payload_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text, p_skill_code text';
  if v_oid is null then raise exception 'P2-35 skill detail payload missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='    from private.exam_prep_evidence_events e'||chr(10)||
         '    join private.exam_prep_sessions s on s.id=e.session_id and s.user_id=p_user_id'||chr(10)||
         '    where e.user_id=p_user_id';
  v_new:='    from private.exam_prep_evidence_events e'||chr(10)||
         '    join private.exam_prep_sessions s on s.id=e.session_id and s.user_id=p_user_id and s.status=''finalized'''||chr(10)||
         '    join private.exam_prep_session_authorizations sa on sa.id=s.authorization_id and sa.user_id=p_user_id and sa.academic_credit=true'||chr(10)||
         '    where e.user_id=p_user_id';
  if position(v_old in v_def)=0 then raise exception 'P2-35 skill detail evidence anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  -- Syllabus tracker: latest evidence per skill is academic/finalized only.
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_syllabus_tracker_payload_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text';
  if v_oid is null then raise exception 'P2-35 syllabus tracker payload missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='      select e.evidence_type,e.verification_status,e.is_correct,e.created_at'||chr(10)||
         '      from private.exam_prep_evidence_events e'||chr(10)||
         '      where e.user_id=p_user_id'||chr(10)||
         '        and e.component_code=p_component_code'||chr(10)||
         '        and e.skill_code=n.skill_code';
  v_new:='      select e.evidence_type,e.verification_status,e.is_correct,e.created_at'||chr(10)||
         '      from private.exam_prep_evidence_events e'||chr(10)||
         '      join private.exam_prep_sessions s on s.id=e.session_id and s.user_id=p_user_id and s.status=''finalized'''||chr(10)||
         '      join private.exam_prep_session_authorizations sa on sa.id=s.authorization_id and sa.user_id=p_user_id and sa.academic_credit=true'||chr(10)||
         '      where e.user_id=p_user_id'||chr(10)||
         '        and e.component_code=p_component_code'||chr(10)||
         '        and e.skill_code=n.skill_code';
  if position(v_old in v_def)=0 then raise exception 'P2-35 tracker evidence anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke all on function private.exam_prep_overview_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_overview_payload_v1(uuid,text) to service_role;
revoke all on function private.exam_prep_skill_detail_payload_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_detail_payload_v1(uuid,text,text) to service_role;
revoke all on function private.exam_prep_syllabus_tracker_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_syllabus_tracker_payload_v1(uuid,text) to service_role;

commit;
