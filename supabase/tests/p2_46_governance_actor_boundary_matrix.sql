\set ON_ERROR_STOP on

-- P2-46 governance actor boundary matrix.
-- Read-only assertions against the fully replayed current schema.

do $$
declare
  v_proc regprocedure;
  v_bad integer;
begin
  v_proc:=to_regprocedure('public.record_exam_prep_beta_weekly_review_v2(text,smallint,timestamp with time zone,text,text,text,text,text,text,text,text,uuid)');
  if v_proc is null then
    raise exception 'P2-46 weekly review v2 RPC missing';
  end if;

  if has_function_privilege('anon',v_proc,'EXECUTE') then
    raise exception 'P2-46 anon can execute weekly beta governance review';
  end if;
  if has_function_privilege('authenticated',v_proc,'EXECUTE') then
    raise exception 'P2-46 authenticated browser can execute weekly beta governance review';
  end if;
  if not has_function_privilege('service_role',v_proc,'EXECUTE') then
    raise exception 'P2-46 service_role lost weekly beta governance review execution';
  end if;

  -- Browser beta functions are limited to the learner's own invitation and
  -- consent lifecycle. Operational/governance functions remain service-only.
  select count(*) into v_bad
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname like '%exam_prep%'
    and (
      p.proname ilike '%beta%'
      or p.proname ilike '%controlled%'
      or p.proname ilike '%expansion%'
    )
    and has_function_privilege('authenticated',p.oid,'EXECUTE')
    and p.proname not in (
      'get_my_exam_prep_beta_invitation_v1',
      'grant_my_exam_prep_beta_consent_v1',
      'revoke_my_exam_prep_beta_consent_v1'
    );
  if v_bad<>0 then
    raise exception 'P2-46 found % browser-executable beta governance/operations functions',v_bad;
  end if;
end $$;

select 'P2-46 governance actor boundary: GREEN' as result;
