begin;

-- P2-31: timed/paper launch is retry-safe and resumes an already-active
-- attempt of the same assessment instead of creating a parallel attempt.
-- A finalized/abandoned attempt does not block a later legitimate retake.

create unique index if not exists exam_prep_one_issued_timed_auth_v1
  on private.exam_prep_session_authorizations(user_id,assessment_id)
  where status='issued' and purpose in ('timed','paper');

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_timed_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_assessment_id bigint';
  if v_oid is null then raise exception 'P2-31 timed authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_auth uuid;'||chr(10)||'  v_stage smallint;';
  v_new:='  v_auth uuid;'||chr(10)||'  v_existing_auth uuid;'||chr(10)||'  v_existing_session uuid;'||chr(10)||'  v_stage smallint;';
  if position(v_old in v_def)=0 then raise exception 'P2-31 declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  v_limit:=private.exam_prep_timed_time_limit_v1('||chr(10)||
         '    v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec'||chr(10)||
         '  );'||chr(10)||chr(10)||
         '  insert into private.exam_prep_session_authorizations(';
  v_new:='  v_limit:=private.exam_prep_timed_time_limit_v1('||chr(10)||
         '    v_c.paper_profile_id,v_c.timing_rule,v_c.marks_available,v_c.fixed_time_limit_sec'||chr(10)||
         '  );'||chr(10)||chr(10)||
         '  perform pg_advisory_xact_lock(hashtextextended(v_uid::text||'':timed:''||v_a.id::text,0));'||chr(10)||
         '  update private.exam_prep_session_authorizations'||chr(10)||
         '  set status=''expired'''||chr(10)||
         '  where user_id=v_uid and assessment_id=v_a.id and purpose=v_a.assessment_type'||chr(10)||
         '    and status=''issued'' and valid_until is not null and valid_until<=now();'||chr(10)||chr(10)||
         '  select s.id,a.id into v_existing_session,v_existing_auth'||chr(10)||
         '  from private.exam_prep_sessions s'||chr(10)||
         '  join private.exam_prep_session_authorizations a on a.id=s.authorization_id'||chr(10)||
         '  where s.user_id=v_uid and s.assessment_id=v_a.id and s.session_type=v_a.assessment_type'||chr(10)||
         '    and s.status=''active'' and a.user_id=v_uid'||chr(10)||
         '  order by s.started_at desc,s.id limit 1;'||chr(10)||
         '  if v_existing_session is not null then'||chr(10)||
         '    return jsonb_build_object('||chr(10)||
         '      ''authorization_id'',v_existing_auth,''assessment_id'',v_a.id,''component_code'',v_a.component_code,'||chr(10)||
         '      ''purpose'',v_a.assessment_type,''attempt_kind'',v_c.attempt_kind,''timing_rule'',v_c.timing_rule,'||chr(10)||
         '      ''marks_available'',v_c.marks_available,''time_limit_sec'',v_limit,''comparison_scope'',v_c.comparison_scope,'||chr(10)||
         '      ''comparability_key'',v_c.comparability_key,''strict_timing'',v_c.strict_timing,'||chr(10)||
         '      ''current_operational_stage'',v_stage,''min_operational_stage'',v_min_stage,'||chr(10)||
         '      ''active_session_id'',v_existing_session,''replayed'',true'||chr(10)||
         '    );'||chr(10)||
         '  end if;'||chr(10)||chr(10)||
         '  select a.id into v_existing_auth'||chr(10)||
         '  from private.exam_prep_session_authorizations a'||chr(10)||
         '  where a.user_id=v_uid and a.assessment_id=v_a.id and a.purpose=v_a.assessment_type'||chr(10)||
         '    and a.status=''issued'' and (a.valid_until is null or a.valid_until>now())'||chr(10)||
         '  order by a.issued_at desc,a.id limit 1;'||chr(10)||
         '  if v_existing_auth is not null then'||chr(10)||
         '    return jsonb_build_object('||chr(10)||
         '      ''authorization_id'',v_existing_auth,''assessment_id'',v_a.id,''component_code'',v_a.component_code,'||chr(10)||
         '      ''purpose'',v_a.assessment_type,''attempt_kind'',v_c.attempt_kind,''timing_rule'',v_c.timing_rule,'||chr(10)||
         '      ''marks_available'',v_c.marks_available,''time_limit_sec'',v_limit,''comparison_scope'',v_c.comparison_scope,'||chr(10)||
         '      ''comparability_key'',v_c.comparability_key,''strict_timing'',v_c.strict_timing,'||chr(10)||
         '      ''current_operational_stage'',v_stage,''min_operational_stage'',v_min_stage,''replayed'',true'||chr(10)||
         '    );'||chr(10)||
         '  end if;'||chr(10)||chr(10)||
         '  insert into private.exam_prep_session_authorizations(';
  if position(v_old in v_def)=0 then raise exception 'P2-31 launch anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='    ''min_operational_stage'',v_min_stage'||chr(10)||'  );';
  v_new:='    ''min_operational_stage'',v_min_stage,'||chr(10)||'    ''replayed'',false'||chr(10)||'  );';
  if position(v_old in v_def)=0 then raise exception 'P2-31 return anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.authorize_exam_prep_timed_safe_v1(bigint) from public,anon;
grant execute on function public.authorize_exam_prep_timed_safe_v1(bigint) to authenticated,service_role;

commit;