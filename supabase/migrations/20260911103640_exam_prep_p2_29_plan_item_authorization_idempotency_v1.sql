begin;

alter table private.exam_prep_session_authorizations
  add column if not exists plan_id uuid null,
  add column if not exists plan_priority_order smallint null;

do $$ begin
  if not exists(select 1 from pg_constraint where conname='exam_prep_session_authorizations_plan_id_fkey') then
    alter table private.exam_prep_session_authorizations
      add constraint exam_prep_session_authorizations_plan_id_fkey
      foreign key(plan_id) references private.exam_prep_weekly_plans(id) on delete restrict;
  end if;
  if not exists(select 1 from pg_constraint where conname='exam_prep_session_authorizations_plan_priority_check') then
    alter table private.exam_prep_session_authorizations
      add constraint exam_prep_session_authorizations_plan_priority_check
      check(plan_priority_order is null or plan_priority_order between 1 and 3);
  end if;
  if not exists(select 1 from pg_constraint where conname='exam_prep_session_authorizations_plan_binding_pair_check') then
    alter table private.exam_prep_session_authorizations
      add constraint exam_prep_session_authorizations_plan_binding_pair_check
      check((plan_id is null)=(plan_priority_order is null));
  end if;
end $$;

create unique index if not exists exam_prep_live_plan_authorization_one_v1
  on private.exam_prep_session_authorizations(user_id,plan_id,plan_priority_order)
  where plan_id is not null and status in ('issued','consumed');

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_plan_item_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_plan_id uuid, p_priority_order integer';
  if v_oid is null then raise exception 'P2-29 plan authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_result jsonb;'||chr(10)||'  v_state private.exam_prep_skill_states%rowtype;';
  v_new:='  v_result jsonb;'||chr(10)||'  v_existing private.exam_prep_session_authorizations%rowtype;'||chr(10)||'  v_state private.exam_prep_skill_states%rowtype;';
  if position(v_old in v_def)=0 then raise exception 'P2-29 declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  if v_item.plan_id is null then raise exception ''exam_prep_pending_plan_item_not_found'' using errcode=''P0002''; end if;'||chr(10)||chr(10)||'  if v_item.item_type=''correction'' then';
  v_new='  if v_item.plan_id is null then raise exception ''exam_prep_pending_plan_item_not_found'' using errcode=''P0002''; end if;'||chr(10)||chr(10)||
    '  perform pg_advisory_xact_lock(hashtextextended(v_uid::text||'':''||v_plan.id::text||'':''||v_item.priority_order::text,0));'||chr(10)||
    '  update private.exam_prep_session_authorizations'||chr(10)||
    '  set status=''expired'''||chr(10)||
    '  where user_id=v_uid and plan_id=v_plan.id and plan_priority_order=v_item.priority_order'||chr(10)||
    '    and status=''issued'' and valid_until is not null and valid_until<=now();'||chr(10)||chr(10)||
    '  select * into v_existing'||chr(10)||
    '  from private.exam_prep_session_authorizations'||chr(10)||
    '  where user_id=v_uid and plan_id=v_plan.id and plan_priority_order=v_item.priority_order'||chr(10)||
    '    and status in (''issued'',''consumed'')'||chr(10)||
    '  order by issued_at desc limit 1;'||chr(10)||
    '  if v_existing.id is not null then'||chr(10)||
    '    return jsonb_build_object('||chr(10)||
    '      ''authorization_id'',v_existing.id,''plan_id'',v_plan.id,''priority_order'',v_item.priority_order,'||chr(10)||
    '      ''item_type'',v_item.item_type,''action_code'',v_item.action_code,''component_code'',v_plan.component_code,'||chr(10)||
    '      ''purpose'',v_existing.purpose,''authorization_status'',v_existing.status,'||chr(10)||
    '      ''consumed_session_id'',v_existing.consumed_session_id,''replayed'',true'||chr(10)||
    '    );'||chr(10)||
    '  end if;'||chr(10)||chr(10)||
    '  if v_item.item_type=''correction'' then';
  if position(v_old in v_def)=0 then raise exception 'P2-29 plan-item anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  return v_result || jsonb_build_object('||chr(10)||
         '    ''plan_id'',v_plan.id,''priority_order'',v_item.priority_order,'||chr(10)||
         '    ''item_type'',v_item.item_type,''action_code'',v_item.action_code'||chr(10)||
         '  );';
  v_new:='  v_auth:=coalesce(v_auth,nullif(v_result->>''authorization_id'','''')::uuid);'||chr(10)||
    '  if v_auth is null then raise exception ''exam_prep_plan_authorization_missing''; end if;'||chr(10)||
    '  update private.exam_prep_session_authorizations'||chr(10)||
    '  set plan_id=v_plan.id,plan_priority_order=v_item.priority_order'||chr(10)||
    '  where id=v_auth and user_id=v_uid and plan_id is null;'||chr(10)||
    '  if not found and not exists('||chr(10)||
    '    select 1 from private.exam_prep_session_authorizations a'||chr(10)||
    '    where a.id=v_auth and a.user_id=v_uid and a.plan_id=v_plan.id and a.plan_priority_order=v_item.priority_order'||chr(10)||
    '  ) then raise exception ''exam_prep_plan_authorization_bind_failed''; end if;'||chr(10)||chr(10)||
    '  return v_result || jsonb_build_object('||chr(10)||
    '    ''plan_id'',v_plan.id,''priority_order'',v_item.priority_order,'||chr(10)||
    '    ''item_type'',v_item.item_type,''action_code'',v_item.action_code,''replayed'',false'||chr(10)||
    '  );';
  if position(v_old in v_def)=0 then raise exception 'P2-29 return anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);
  execute v_def;

  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='start_exam_prep_session_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_authorization_id uuid, p_idempotency_key text';
  if v_oid is null then raise exception 'P2-29 session starter missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='  if v_auth.id is null or v_auth.user_id<>v_uid then raise exception ''exam_prep_authorization_not_found'' using errcode=''P0002''; end if;'||chr(10)||
         '  if v_auth.status<>''issued'' then raise exception ''exam_prep_authorization_not_usable''; end if;';
  v_new:='  if v_auth.id is null or v_auth.user_id<>v_uid then raise exception ''exam_prep_authorization_not_found'' using errcode=''P0002''; end if;'||chr(10)||
    '  if v_auth.status=''consumed'' and v_auth.consumed_session_id is not null then'||chr(10)||
    '    select * into v_s from private.exam_prep_sessions'||chr(10)||
    '    where id=v_auth.consumed_session_id and user_id=v_uid and authorization_id=v_auth.id;'||chr(10)||
    '    if v_s.id is not null then'||chr(10)||
    '      return jsonb_build_object(''session_id'',v_s.id,''status'',v_s.status,''component_code'',v_s.component_code,'||chr(10)||
    '        ''session_type'',v_s.session_type,''total_items'',v_s.total_items,''resumed'',true,''authorization_replayed'',true);'||chr(10)||
    '    end if;'||chr(10)||
    '  end if;'||chr(10)||
    '  if v_auth.status<>''issued'' then raise exception ''exam_prep_authorization_not_usable''; end if;';
  if position(v_old in v_def)=0 then raise exception 'P2-29 starter anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;
revoke execute on function public.start_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.start_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

commit;