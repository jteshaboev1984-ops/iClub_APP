-- iClub AI Layer v2.1 — NEVER APPLY IN PRODUCTION.
-- UNAPPLIED draft to run ONLY in isolated local PostgreSQL after review.
-- No existing v1 tariff, user progress or subscription values updated.
-- TEMPORARY MIX: prepared=1, generated=3; Free=3, Plus=9, Pro=14; 5h.

-- Independent guard: refuse direct execution on production even outside runner.
DO $iclub_ai_v21_scratch_only$
BEGIN
  IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$' THEN
    RAISE EXCEPTION 'BLOCKED: QA AI v2.1 SQL cannot run on database %',current_database();
  END IF;
  IF inet_server_addr() IS NOT NULL
     AND (inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet) AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
    RAISE EXCEPTION 'BLOCKED: QA AI v2.1 SQL requires local PostgreSQL';
  END IF;
END
$iclub_ai_v21_scratch_only$;
alter table private.iclub_ai_usage_reservations
 add column if not exists request_fingerprint text;

insert into private.iclub_ai_usage_policies(
 usage_policy_code,policy_version,period_seconds,allowance_units,
 prepared_weight,generation_weight,generation_enabled,reservation_ttl_seconds,is_active
) values
 ('free_qa_v2','ai_layer_preview_v21',18000,3,1,3,false,90,true),
 ('plus_qa_v2','ai_layer_preview_v21',18000,9,1,3,true,90,true),
 ('pro_qa_v2','ai_layer_preview_v21',18000,14,1,3,true,90,true)
on conflict (usage_policy_code) do nothing;

create or replace function public.reserve_iclub_ai_usage_service_v2(
  p_request_id uuid,
  p_user_id uuid,
  p_usage_policy_code text,
  p_route_class text,
  p_request_fingerprint text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_policy private.iclub_ai_usage_policies%rowtype;
  v_period private.iclub_ai_usage_periods%rowtype;
  v_existing private.iclub_ai_usage_reservations%rowtype;
  v_weight integer;
  v_remaining integer;
  v_without_reservations integer;
begin
  if p_request_id is null or p_user_id is null or p_request_fingerprint is null or p_request_fingerprint !~ '^[0-9a-f]{64}$' then
    return jsonb_build_object('allowed',false,'reason','invalid_identity');
  end if;

  if p_route_class not in ('prepared','generated') then
    return jsonb_build_object('allowed',false,'reason','invalid_route_class');
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));

  select * into v_policy
  from private.iclub_ai_usage_policies
  where usage_policy_code=p_usage_policy_code
    and is_active;

  if not found then
    return jsonb_build_object('allowed',false,'reason','usage_policy_unavailable');
  end if;

  if p_route_class='generated' and not v_policy.generation_enabled then
    return jsonb_build_object('allowed',false,'reason','generation_not_entitled');
  end if;

  v_weight:=case when p_route_class='generated' then v_policy.generation_weight else v_policy.prepared_weight end;

  select * into v_existing
  from private.iclub_ai_usage_reservations
  where request_id=p_request_id
  for update;

  if found then
    if v_existing.user_id<>p_user_id
       or v_existing.route_class<>p_route_class
       or v_existing.request_fingerprint is distinct from p_request_fingerprint
       or not exists (
         select 1 from private.iclub_ai_usage_periods p
         where p.id=v_existing.period_id
           and p.usage_policy_code=p_usage_policy_code
       ) then
      return jsonb_build_object('allowed',false,'reason','request_identity_mismatch');
    end if;
    return jsonb_build_object(
      'allowed',false,
      'reason',case when v_existing.status='reserved' then 'request_in_progress' when v_existing.status='completed' then 'request_already_completed' else coalesce(v_existing.release_reason,'request_released') end,
      'duplicate',true,
      'reservation_status',v_existing.status,
      'request_id',v_existing.request_id
    );
  end if;

  with released as (
    update private.iclub_ai_usage_reservations r
    set status='released',
        release_reason='reservation_expired',
        finished_at=coalesce(r.finished_at,now())
    where r.user_id=p_user_id
      and r.status='reserved'
      and r.expires_at<=now()
    returning r.period_id,r.weight_units
  ), totals as (
    select period_id,sum(weight_units)::integer released_units
    from released
    group by period_id
  )
  update private.iclub_ai_usage_periods p
  set reserved_units=greatest(0,p.reserved_units-t.released_units),
      updated_at=now()
  from totals t
  where p.id=t.period_id;

  select * into v_period
  from private.iclub_ai_usage_periods
  where user_id=p_user_id
    and status in ('provisional','active')
  order by created_at desc
  limit 1
  for update;

  if found and v_period.status='active' and v_period.reset_at<=now() then
    if v_period.reserved_units>0 then
      return jsonb_build_object(
        'allowed',false,
        'reason','usage_busy',
        'reset_at',v_period.reset_at
      );
    end if;

    update private.iclub_ai_usage_periods
    set status='closed',
        close_reason='period_elapsed',
        exhausted=false,
        updated_at=now()
    where id=v_period.id;
    v_period.id:=null;
  end if;

  if v_period.id is null then
    insert into private.iclub_ai_usage_periods(
      user_id,usage_policy_code,status,committed_units,reserved_units,exhausted
    ) values (
      p_user_id,v_policy.usage_policy_code,'provisional',0,0,false
    )
    returning * into v_period;
  elsif v_period.usage_policy_code<>v_policy.usage_policy_code then
    return jsonb_build_object(
      'allowed',false,
      'reason','usage_policy_transition_required',
      'current_usage_policy_code',v_period.usage_policy_code
    );
  end if;

  if v_period.status='active' and v_period.exhausted then
    return jsonb_build_object(
      'allowed',false,
      'reason','usage_exhausted',
      'reset_at',v_period.reset_at
    );
  end if;

  v_remaining:=v_policy.allowance_units-v_period.committed_units-v_period.reserved_units;
  v_without_reservations:=v_policy.allowance_units-v_period.committed_units;

  if v_weight>v_remaining then
    if v_period.reserved_units>0 and v_weight<=v_without_reservations then
      return jsonb_build_object(
        'allowed',false,
        'reason','usage_busy',
        'reset_at',v_period.reset_at
      );
    end if;

    if v_period.status='active' then
      -- Preserve cheap routes when expensive request cannot fit.
      return jsonb_build_object('allowed',false,'reason','route_insufficient','reset_at',v_period.reset_at);
    end if;

    return jsonb_build_object('allowed',false,'reason','route_insufficient');
  end if;

  insert into private.iclub_ai_usage_reservations(
    request_id,period_id,user_id,route_class,weight_units,status,created_at,expires_at,request_fingerprint
  ) values (
    p_request_id,v_period.id,p_user_id,p_route_class,v_weight,'reserved',now(),
    now()+make_interval(secs=>v_policy.reservation_ttl_seconds),p_request_fingerprint
  );

  update private.iclub_ai_usage_periods
  set reserved_units=reserved_units+v_weight,
      updated_at=now()
  where id=v_period.id;

  return jsonb_build_object(
    'allowed',true,
    'reason',null,
    'duplicate',false,
    'request_id',p_request_id,
    'reservation_status','reserved'
  );
end;
$$;


revoke all on function public.reserve_iclub_ai_usage_service_v2(uuid,uuid,text,text,text)
 from public,anon,authenticated;
grant execute on function public.reserve_iclub_ai_usage_service_v2(uuid,uuid,text,text,text)
 to service_role;

-- v2 completion validates ownership/fingerprint and reservation lifetime
-- before delegating the committed/reserved-unit accounting to existing v1.
-- This is a QA draft only; the v1 deployed function remains untouched.
create or replace function public.finalize_iclub_ai_usage_service_v2(
 p_request_id uuid,
 p_user_id uuid,
 p_request_fingerprint text,
 p_outcome text,
 p_release_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
 v_res private.iclub_ai_usage_reservations%rowtype;
 v_done jsonb;
begin
 if p_request_id is null or p_user_id is null
    or p_request_fingerprint is null
    or p_request_fingerprint !~ '^[0-9a-f]{64}$' then
   return jsonb_build_object('ok',false,'reason','invalid_identity');
 end if;
 if p_outcome is null or p_outcome not in ('completed','released') then
   return jsonb_build_object('ok',false,'reason','invalid_outcome');
 end if;
 perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));
 select * into v_res from private.iclub_ai_usage_reservations
 where request_id=p_request_id for update;
 if not found then
   return jsonb_build_object('ok',false,'reason','reservation_missing');
 end if;
 if v_res.user_id<>p_user_id
    or v_res.request_fingerprint is distinct from p_request_fingerprint
    or not exists (
      select 1 from private.iclub_ai_usage_periods p
      where p.id=v_res.period_id and p.user_id=p_user_id
    ) then
   return jsonb_build_object('ok',false,'reason','request_identity_mismatch');
 end if;
 if v_res.status='completed' then
   return jsonb_build_object(
     'ok',p_outcome='completed','duplicate',true,'status','completed'
   );
 end if;
 if v_res.status='released' then
   return jsonb_build_object(
     'ok',p_outcome='released','duplicate',true,'status','released'
   );
 end if;
 if v_res.expires_at<=now() then
   v_done:=public.finalize_iclub_ai_usage_service_v1(
      p_request_id,'released','reservation_expired'
   );
   if v_done->>'ok' is distinct from 'true' then
     return jsonb_build_object('ok',false,'reason','expiry_release_failed');
   end if;
   return jsonb_build_object(
     'ok',false,'reason','reservation_expired','status','released'
   );
 end if;
 return public.finalize_iclub_ai_usage_service_v1(
   p_request_id,p_outcome,p_release_reason
 );
end;
$$;
revoke all on function public.finalize_iclub_ai_usage_service_v2(uuid,uuid,text,text,text)
 from public,anon,authenticated;
grant execute on function public.finalize_iclub_ai_usage_service_v2(uuid,uuid,text,text,text)
 to service_role;
-- OPEN GATES: duplicate request reply replay, local PG transaction tests,
-- time-of-check protected assessment race, reauthorization before model call,
-- route/version fingerprint hashing and quota migration MUST pass before use.
-- No deployed Global AI Edge references these QA-only v2 policy codes.
