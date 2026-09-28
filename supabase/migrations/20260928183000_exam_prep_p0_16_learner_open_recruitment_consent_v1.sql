-- P0-16 controlled-beta amendment: capped open Core recruitment.
--
-- Architect decision 2026-09-28:
-- * show the Exam Prep test opportunity to authenticated Mathematics users while seats remain;
-- * preserve the existing controlled-beta cap of 12 (within the requested 10-15 range);
-- * every learner explicitly opts in before access;
-- * new learners receive Core only; AI Assist and Mentor Care remain OFF;
-- * seat claiming is atomic and fail-closed at capacity;
-- * a self-recruited learner may withdraw without pausing other learners;
-- * expanded-beta evidence gates are unchanged.
--
-- No legacy Practice/Tours/history/localStorage rows are touched.

begin;

create table if not exists private.exam_prep_beta_open_recruitment_v1 (
  cohort_id bigint primary key references private.exam_prep_beta_cohorts(id) on delete cascade,
  enabled boolean not null default false,
  max_active_members smallint not null check(max_active_members between 3 and 12),
  service_mode text not null default 'core' check(service_mode='core'),
  consent_copy_version text not null default 'controlled_beta_v1_2026_09_04',
  opened_at timestamptz,
  closed_at timestamptz,
  opened_by uuid references public.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.users(id) on delete set null,
  check((enabled and opened_at is not null and closed_at is null) or not enabled)
);

create table if not exists private.exam_prep_beta_open_recruitment_members_v1 (
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key(cohort_id,user_id)
);

alter table private.exam_prep_beta_open_recruitment_v1 enable row level security;
alter table private.exam_prep_beta_open_recruitment_v1 force row level security;
alter table private.exam_prep_beta_open_recruitment_members_v1 enable row level security;
alter table private.exam_prep_beta_open_recruitment_members_v1 force row level security;
revoke all on private.exam_prep_beta_open_recruitment_v1 from public,anon,authenticated;
revoke all on private.exam_prep_beta_open_recruitment_members_v1 from public,anon,authenticated;

create or replace function public.get_my_exam_prep_beta_invitation_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_role text;
  v_items jsonb;
  v_offer jsonb;
begin
  v_uid := auth.uid();
  v_role := auth.role();

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'cohort_key', c.cohort_key,
    'cohort_status', c.cohort_status,
    'capacity', c.planned_size,
    'monitoring_hours', c.monitoring_hours,
    'service_mode', m.service_mode,
    'activation_wave', m.activation_wave,
    'member_status', m.member_status,
    'consent_status', coalesce(cs.consent_status, 'missing'),
    'consented_at', cs.consented_at,
    'revoked_at', cs.revoked_at,
    'consent_scope', 'exam_prep_controlled_beta_v1',
    'consent_copy_version', 'controlled_beta_v1_2026_09_04',
    'open_recruitment', false,
    'remaining_slots', greatest(0,c.planned_size - (
      select count(*) from private.exam_prep_beta_members mx
      where mx.cohort_id=c.id and mx.member_status<>'removed'
    ))
  ) order by c.id), '[]'::jsonb)
  into v_items
  from private.exam_prep_beta_members m
  join private.exam_prep_beta_cohorts c on c.id = m.cohort_id
  left join private.exam_prep_beta_consents cs
    on cs.cohort_id = m.cohort_id and cs.user_id = m.user_id
  where m.user_id = v_uid
    and m.member_status <> 'removed';

  if jsonb_array_length(v_items)=0
     and exists(select 1 from public.users u where u.id=v_uid)
     and not private.is_exam_prep_synthetic_identity_v1(v_uid) then

    select jsonb_build_object(
      'cohort_key',c.cohort_key,
      'cohort_status',c.cohort_status,
      'capacity',least(c.planned_size,r.max_active_members),
      'monitoring_hours',c.monitoring_hours,
      'service_mode','core',
      'activation_wave',least(20,c.current_wave+1),
      'member_status','open',
      'consent_status','missing',
      'consented_at',null,
      'revoked_at',null,
      'consent_scope','exam_prep_controlled_beta_v1',
      'consent_copy_version',r.consent_copy_version,
      'open_recruitment',true,
      'remaining_slots',greatest(0,least(c.planned_size,r.max_active_members)-count(m.id))
    )
    into v_offer
    from private.exam_prep_beta_open_recruitment_v1 r
    join private.exam_prep_beta_cohorts c on c.id=r.cohort_id
    join private.exam_prep_feature_config f on f.id=1
    left join private.exam_prep_beta_members m on m.cohort_id=c.id and m.member_status<>'removed'
    where r.enabled
      and c.cohort_status in ('canary','active')
      and c.current_wave<20
      and f.rollout_state='controlled_beta'
      and f.core_enabled
      and not f.kill_switch
      and not f.ai_enabled
      and not f.mentor_enabled
      and not exists(
        select 1 from private.exam_prep_beta_members own
        where own.cohort_id=c.id and own.user_id=v_uid
      )
      and not exists(
        select 1 from private.exam_prep_beta_ops_incidents i
        where i.cohort_id=c.id
          and i.severity in ('sev0','sev1')
          and i.status in ('open','mitigating')
      )
    group by c.id,r.max_active_members,r.consent_copy_version
    having count(m.id)<least(c.planned_size,r.max_active_members)
    order by c.id
    limit 1;

    if v_offer is not null then
      v_items:=jsonb_build_array(v_offer);
    end if;
  end if;

  return jsonb_build_object(
    'invited',jsonb_array_length(v_items)>0,
    'user_id',v_uid,
    'consent_scope','exam_prep_controlled_beta_v1',
    'consent_copy_version','controlled_beta_v1_2026_09_04',
    'invitations',v_items
  );
end;
$function$;

revoke all on function public.get_my_exam_prep_beta_invitation_v1()
from public,anon,service_role;
grant execute on function public.get_my_exam_prep_beta_invitation_v1()
to authenticated;

create or replace function public.claim_my_exam_prep_beta_core_seat_v1(
  p_cohort_key text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_uid uuid;
  v_role text;
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_r private.exam_prep_beta_open_recruitment_v1%rowtype;
  v_existing private.exam_prep_beta_members%rowtype;
  v_occupied int;
  v_active int;
  v_cap int;
  v_wave smallint;
  v_week smallint;
  v_epoch timestamptz;
  v_runway jsonb;
begin
  v_uid:=auth.uid();
  v_role:=auth.role();

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_open_recruitment_auth_required';
  end if;
  if p_acknowledgement is distinct from 'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1' then
    raise exception 'exam_prep_beta_open_recruitment_acknowledgement_required';
  end if;
  if private.is_exam_prep_synthetic_identity_v1(v_uid) then
    raise exception 'exam_prep_beta_open_recruitment_real_learner_required';
  end if;
  if not exists(select 1 from public.users where id=v_uid) then
    raise exception 'exam_prep_beta_user_not_found' using errcode='P0002';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_r
  from private.exam_prep_beta_open_recruitment_v1
  where cohort_id=v_c.id;
  if v_r.cohort_id is null or not v_r.enabled then
    raise exception 'exam_prep_beta_open_recruitment_closed';
  end if;

  v_cap:=least(v_c.planned_size,v_r.max_active_members);
  if v_c.cohort_status not in ('canary','active') or v_c.current_wave>=20 then
    raise exception 'exam_prep_beta_open_recruitment_cohort_not_open';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1 for update;
  if v_cfg.rollout_state<>'controlled_beta' or v_cfg.kill_switch or not v_cfg.core_enabled
     or v_cfg.ai_enabled or v_cfg.mentor_enabled then
    raise exception 'exam_prep_beta_open_recruitment_core_only_gate_red';
  end if;

  if exists(
    select 1 from private.exam_prep_beta_ops_incidents i
    where i.cohort_id=v_c.id and i.severity in ('sev0','sev1')
      and i.status in ('open','mitigating')
  ) then
    raise exception 'exam_prep_beta_open_recruitment_incident_gate_red';
  end if;

  select coalesce(x.real_review_epoch_started_at,v_c.started_at,now())
  into v_epoch
  from private.exam_prep_beta_expansion_controls x
  where x.cohort_id=v_c.id;
  v_epoch:=coalesce(v_epoch,v_c.started_at,now());
  v_week:=least(36,greatest(1,floor(extract(epoch from (now()-v_epoch))/604800)::int+1))::smallint;
  v_runway:=public.get_exam_prep_content_runway_v1(v_week);
  if not coalesce((v_runway->>'hard_floor_green')::boolean,false)
     or not coalesce((v_runway->>'target_4w_green')::boolean,false) then
    raise exception 'exam_prep_beta_open_recruitment_runway_gate_red';
  end if;

  select * into v_existing
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=v_uid
  for update;
  if v_existing.id is not null then
    if v_existing.member_status='active'
       and exists(
         select 1 from private.exam_prep_feature_entitlements e
         where e.user_id=v_uid and e.entitlement_status='active'
           and e.core_access and not e.ai_assist and not e.mentor_care_entitled
           and e.cohort_key=p_cohort_key
       ) then
      return jsonb_build_object(
        'status','already_active','cohort_key',p_cohort_key,'user_id',v_uid,
        'access_activated',true,'remaining_slots',greatest(0,v_cap-(
          select count(*) from private.exam_prep_beta_members m
          where m.cohort_id=v_c.id and m.member_status<>'removed'
        ))
      );
    end if;
    raise exception 'exam_prep_beta_open_recruitment_existing_membership_requires_governance';
  end if;

  if exists(
    select 1 from private.exam_prep_feature_entitlements e
    where e.user_id=v_uid and e.entitlement_status='active'
      and coalesce(e.cohort_key,'')<>p_cohort_key
  ) then
    raise exception 'exam_prep_beta_conflicting_live_entitlement';
  end if;

  if exists(
    select 1 from private.exam_prep_mentor_service_status s
    where s.learner_user_id=v_uid and s.service_status='assigned_active'
  ) or exists(
    select 1 from private.exam_prep_mentor_assignments a
    where a.learner_user_id=v_uid and a.assignment_status='active'
      and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now())
  ) then
    raise exception 'exam_prep_beta_open_recruitment_mentor_assignment_conflict';
  end if;

  select count(*) into v_occupied
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status<>'removed';
  if v_occupied>=v_cap then
    update private.exam_prep_beta_open_recruitment_v1
    set enabled=false,closed_at=coalesce(closed_at,now()),updated_at=now(),updated_by=v_uid
    where cohort_id=v_c.id;
    raise exception 'exam_prep_beta_open_recruitment_full';
  end if;

  v_wave:=(v_c.current_wave+1)::smallint;

  insert into private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status,created_by,updated_by
  ) values(
    v_c.id,v_uid,'core',v_wave,'candidate',v_uid,v_uid
  );

  perform public.record_exam_prep_beta_consent_v1(
    p_cohort_key,
    v_uid,
    'authenticated_open_recruitment_v1:controlled_beta_v1_2026_09_28',
    now()
  );

  update private.exam_prep_beta_members
  set member_status='active',activated_at=now(),updated_at=now(),updated_by=v_uid
  where cohort_id=v_c.id and user_id=v_uid and member_status='candidate';

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,
    cohort_key,valid_from,valid_until,updated_at,updated_by
  ) values(
    v_uid,'active',true,false,false,p_cohort_key,now(),null,now(),v_uid
  )
  on conflict(user_id) do update set
    entitlement_status='active',
    core_access=true,
    ai_assist=false,
    mentor_care_entitled=false,
    cohort_key=excluded.cohort_key,
    valid_from=now(),
    valid_until=null,
    updated_at=now(),
    updated_by=v_uid;

  insert into private.exam_prep_beta_open_recruitment_members_v1(cohort_id,user_id,joined_at,revoked_at)
  values(v_c.id,v_uid,now(),null)
  on conflict(cohort_id,user_id) do update set joined_at=excluded.joined_at,revoked_at=null;

  select count(*) into v_active
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='active';

  update private.exam_prep_beta_cohorts
  set cohort_status=case when v_active>=v_cap then 'active' else 'canary' end,
      current_wave=v_wave,
      monitoring_until=greatest(coalesce(monitoring_until,now()),now()+(monitoring_hours||' hours')::interval),
      updated_at=now(),updated_by=v_uid
  where id=v_c.id;

  if v_active>=v_cap then
    update private.exam_prep_beta_open_recruitment_v1
    set enabled=false,closed_at=now(),updated_at=now(),updated_by=v_uid
    where cohort_id=v_c.id;
  else
    update private.exam_prep_beta_open_recruitment_v1
    set updated_at=now(),updated_by=v_uid
    where cohort_id=v_c.id;
  end if;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,metadata
  ) values(
    'math_as_p1_p5',v_uid,'learner',
    'beta_open_core_seat_claimed_v1',
    'private.exam_prep_beta_members',v_c.id::text||':'||v_uid::text,v_uid,
    jsonb_build_object(
      'cohort_key',p_cohort_key,'service_mode','core','activation_wave',v_wave,
      'active_members',v_active,'capacity',v_cap,'remaining_slots',greatest(0,v_cap-v_active)
    )
  );

  return jsonb_build_object(
    'status','activated',
    'cohort_key',p_cohort_key,
    'user_id',v_uid,
    'service_mode','core',
    'activation_wave',v_wave,
    'access_activated',true,
    'active_members',v_active,
    'capacity',v_cap,
    'remaining_slots',greatest(0,v_cap-v_active)
  );
end;
$function$;

revoke all on function public.claim_my_exam_prep_beta_core_seat_v1(text,text)
from public,anon,service_role;
grant execute on function public.claim_my_exam_prep_beta_core_seat_v1(text,text)
to authenticated;

-- Open-recruitment learners may withdraw without pausing unrelated learners.
-- Managed/allowlisted learners keep the previous fail-closed revocation contract.
create or replace function public.revoke_my_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_role text;
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_is_open_recruit boolean:=false;
  v_active int;
  v_cap int;
begin
  v_uid:=auth.uid();
  v_role:=auth.role();

  if v_uid is null or v_role is distinct from 'authenticated' then
    raise exception 'exam_prep_beta_self_consent_auth_required';
  end if;
  if p_acknowledgement is distinct from 'I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1' then
    raise exception 'exam_prep_beta_self_revocation_acknowledgement_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=v_uid
  for update;
  if v_m.id is null or v_m.member_status='removed' then
    raise exception 'exam_prep_beta_self_consent_membership_required';
  end if;

  select exists(
    select 1 from private.exam_prep_beta_open_recruitment_members_v1 r
    where r.cohort_id=v_c.id and r.user_id=v_uid and r.revoked_at is null
  ) into v_is_open_recruit;

  if not v_is_open_recruit then
    return public.revoke_exam_prep_beta_consent_v1(
      p_cohort_key,
      v_uid,
      'authenticated_self_revocation_v1:controlled_beta_v1_2026_09_04'
    ) || jsonb_build_object(
      'consent_copy_version','controlled_beta_v1_2026_09_04',
      'subject','self'
    );
  end if;

  if not exists(
    select 1 from private.exam_prep_beta_consents c
    where c.cohort_id=v_c.id and c.user_id=v_uid and c.consent_status='granted'
  ) then
    raise exception 'exam_prep_beta_consent_not_granted';
  end if;

  update private.exam_prep_beta_consents
  set consent_status='revoked',revoked_at=now(),
      revocation_evidence_ref='authenticated_open_recruitment_revocation_v1:controlled_beta_v1_2026_09_28',
      updated_at=now(),updated_by=v_uid
  where cohort_id=v_c.id and user_id=v_uid;

  update private.exam_prep_feature_entitlements
  set entitlement_status='revoked',core_access=false,ai_assist=false,mentor_care_entitled=false,
      valid_until=now(),updated_at=now(),updated_by=v_uid
  where user_id=v_uid and cohort_key=p_cohort_key;

  update private.exam_prep_beta_members
  set member_status='removed',paused_at=null,updated_at=now(),updated_by=v_uid
  where id=v_m.id;

  update private.exam_prep_beta_open_recruitment_members_v1
  set revoked_at=now()
  where cohort_id=v_c.id and user_id=v_uid;

  select count(*) into v_active
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='active';

  select least(v_c.planned_size,r.max_active_members) into v_cap
  from private.exam_prep_beta_open_recruitment_v1 r
  where r.cohort_id=v_c.id;

  update private.exam_prep_beta_cohorts
  set cohort_status='canary',updated_at=now(),updated_by=v_uid
  where id=v_c.id and cohort_status='active' and v_active<v_cap;

  update private.exam_prep_beta_open_recruitment_v1
  set enabled=true,opened_at=coalesce(opened_at,now()),closed_at=null,updated_at=now(),updated_by=v_uid
  where cohort_id=v_c.id
    and v_active<v_cap
    and v_c.cohort_status in ('canary','active');

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,metadata
  ) values(
    'math_as_p1_p5',v_uid,'learner',
    'beta_open_core_seat_withdrawn_v1',
    'private.exam_prep_beta_members',v_c.id::text||':'||v_uid::text,v_uid,
    jsonb_build_object('cohort_key',p_cohort_key,'remaining_active_members',v_active,'capacity',v_cap)
  );

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'user_id',v_uid,
    'consent_status','revoked',
    'member_status','removed',
    'access_revoked',true,
    'cohort_paused',false,
    'remaining_active_members',v_active
  );
end;
$function$;

revoke all on function public.revoke_my_exam_prep_beta_consent_v1(text,text)
from public,anon,service_role;
grant execute on function public.revoke_my_exam_prep_beta_consent_v1(text,text)
to authenticated;

-- Production-safe enablement for the existing Core canary only.
-- In isolated CI the production cohort is absent, so this is a no-op.
do $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
  v_bad int;
  v_runway jsonb;
begin
  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key='math_as_p1_p5_beta_2026_09_01'
  for update;

  if v_c.id is null then
    return;
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1 for update;
  select count(*) into v_active
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='active';

  select count(*) into v_bad
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='active' and service_mode<>'core';

  v_runway:=public.get_exam_prep_content_runway_v1(1);

  if v_c.cohort_status not in ('canary','active')
     or v_c.planned_size<>12
     or v_active<3
     or v_active>=12
     or v_bad<>0
     or v_cfg.rollout_state<>'controlled_beta'
     or v_cfg.kill_switch
     or not v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not coalesce((v_runway->>'hard_floor_green')::boolean,false)
     or not coalesce((v_runway->>'target_4w_green')::boolean,false)
     or exists(
       select 1 from private.exam_prep_beta_ops_incidents i
       where i.cohort_id=v_c.id and i.severity in ('sev0','sev1')
         and i.status in ('open','mitigating')
     ) then
    raise exception 'P0-16 open recruitment production preflight refused';
  end if;

  insert into private.exam_prep_beta_open_recruitment_v1(
    cohort_id,enabled,max_active_members,service_mode,consent_copy_version,
    opened_at,closed_at,opened_by,updated_at,updated_by
  ) values(
    v_c.id,true,12,'core','controlled_beta_v1_2026_09_04',
    now(),null,null,now(),null
  )
  on conflict(cohort_id) do update set
    enabled=true,
    max_active_members=12,
    service_mode='core',
    consent_copy_version='controlled_beta_v1_2026_09_04',
    opened_at=coalesce(private.exam_prep_beta_open_recruitment_v1.opened_at,now()),
    closed_at=null,
    updated_at=now();
end
$$;

commit;
