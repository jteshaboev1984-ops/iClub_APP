\set ON_ERROR_STOP on

-- P2-44 browser/private-schema boundary matrix.
-- Read-only assertions against the fully replayed schema.

do $$
declare
  v_count integer;
  v_profile_definer boolean;
  v_profile_auth boolean;
  v_profile_anon boolean;
  v_caps_definer boolean;
begin
  if has_schema_privilege('anon','private','USAGE') then
    raise exception 'P2-44: anon still has USAGE on private schema';
  end if;
  if has_schema_privilege('authenticated','private','USAGE') then
    raise exception 'P2-44: authenticated still has USAGE on private schema';
  end if;
  if not has_schema_privilege('service_role','private','USAGE') then
    raise exception 'P2-44: service_role lost USAGE on private schema';
  end if;

  select count(*) into v_count
  from information_schema.role_table_grants g
  where g.table_schema='private'
    and g.table_name like 'exam_prep_%'
    and g.grantee in ('anon','authenticated');
  if v_count<>0 then
    raise exception 'P2-44: browser roles still have % direct private Exam Prep table grants',v_count;
  end if;

  select count(*) into v_count
  from information_schema.role_usage_grants g
  where g.object_schema='private'
    and g.grantee in ('anon','authenticated');
  if v_count<>0 then
    raise exception 'P2-44: browser roles still have % private sequence/usage grants',v_count;
  end if;

  select count(*) into v_count
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private'
    and p.proname like 'exam_prep_%'
    and (
      has_function_privilege('anon',p.oid,'EXECUTE')
      or has_function_privilege('authenticated',p.oid,'EXECUTE')
    );
  if v_count<>0 then
    raise exception 'P2-44: browser roles can still execute % private Exam Prep functions',v_count;
  end if;

  select p.prosecdef,
         has_function_privilege('authenticated',p.oid,'EXECUTE'),
         has_function_privilege('anon',p.oid,'EXECUTE')
  into v_profile_definer,v_profile_auth,v_profile_anon
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='get_exam_prep_exam_profile_v1'
    and pg_get_function_identity_arguments(p.oid)='';

  if coalesce(v_profile_definer,false) is not true then
    raise exception 'P2-44: exam profile reader must be SECURITY DEFINER';
  end if;
  if coalesce(v_profile_auth,false) is not true then
    raise exception 'P2-44: authenticated lost exam profile RPC execute';
  end if;
  if coalesce(v_profile_anon,false) is true then
    raise exception 'P2-44: anon must not execute exam profile RPC';
  end if;

  select p.prosecdef into v_caps_definer
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='get_exam_prep_capabilities_v1'
    and pg_get_function_identity_arguments(p.oid)='';
  if coalesce(v_caps_definer,false) is not true then
    raise exception 'P2-44: capability reader must remain SECURITY DEFINER';
  end if;

  -- If a browser-executable public function reads private Exam Prep state,
  -- it must cross the boundary as SECURITY DEFINER rather than relying on
  -- direct browser table/schema privileges.
  select count(*) into v_count
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname like '%exam_prep%'
    and has_function_privilege('authenticated',p.oid,'EXECUTE')
    and not p.prosecdef
    and pg_get_functiondef(p.oid) ilike '%private.exam_prep_%';
  if v_count<>0 then
    raise exception 'P2-44: found % browser-executable SECURITY INVOKER RPCs reading private Exam Prep state',v_count;
  end if;
end $$;

select 'P2-44 browser/private-schema boundary: GREEN' as result;
