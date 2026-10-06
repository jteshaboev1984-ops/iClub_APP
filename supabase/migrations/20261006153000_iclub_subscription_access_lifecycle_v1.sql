-- iClub subscription lifecycle + commercial subject access foundation v1.
-- Additive and dormant by design.
--
-- Safety laws:
-- - never rewrites/deletes legacy public.user_subjects;
-- - never touches Practice/Tours/Exam Prep/history/certificates/recommendations;
-- - existing learners remain on legacy access until an explicit, versioned cutover;
-- - subject limits cannot be enforced until a grandfather snapshot is complete;
-- - slot selection is stored separately from legacy learning/competitive preferences;
-- - browser roles cannot mutate subscription or commercial access state.

begin;

alter table private.iclub_subscription_entitlements
  add column if not exists current_period_start timestamptz null,
  add column if not exists current_period_end timestamptz null,
  add column if not exists cancel_at_period_end boolean not null default false,
  add column if not exists scheduled_plan_code text null
    references private.iclub_plan_policies(plan_code),
  add column if not exists scheduled_change_at timestamptz null,
  add column if not exists last_event_id uuid null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid='private.iclub_subscription_entitlements'::regclass
      and conname='iclub_subscription_period_order_check'
  ) then
    alter table private.iclub_subscription_entitlements
      add constraint iclub_subscription_period_order_check
      check (
        current_period_end is null
        or current_period_start is null
        or current_period_end > current_period_start
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid='private.iclub_subscription_entitlements'::regclass
      and conname='iclub_subscription_scheduled_change_check'
  ) then
    alter table private.iclub_subscription_entitlements
      add constraint iclub_subscription_scheduled_change_check
      check (
        (scheduled_plan_code is null and scheduled_change_at is null)
        or (scheduled_plan_code is not null and scheduled_change_at is not null)
      );
  end if;
end
$$;

create table if not exists private.iclub_subscription_events (
  event_id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  event_type text not null check (event_type in (
    'activate',
    'renew',
    'upgrade',
    'downgrade',
    'schedule_downgrade',
    'schedule_cancel',
    'cancel',
    'pause',
    'resume',
    'revoke',
    'expire'
  )),
  from_plan_code text null,
  to_plan_code text null,
  effective_at timestamptz not null,
  period_start timestamptz null,
  period_end timestamptz null,
  source text not null,
  applied boolean not null default false,
  applied_at timestamptz null,
  result_status text null,
  created_at timestamptz not null default now(),
  check (char_length(source) between 2 and 80),
  check (period_end is null or period_start is null or period_end > period_start)
);

create index if not exists iclub_subscription_events_user_created_idx
  on private.iclub_subscription_events(user_id,created_at desc);

create table if not exists private.iclub_commercial_access_config (
  id smallint primary key default 1 check (id=1),
  policy_version text not null default 'commercial_access_v1',
  lifecycle_enabled boolean not null default false,
  subject_limits_mode text not null default 'off'
    check (subject_limits_mode in ('off','shadow','enforced')),
  grandfather_strategy text not null default 'preserve_legacy_until_choice'
    check (grandfather_strategy in ('preserve_legacy_until_choice')),
  grandfather_snapshot_version text null,
  grandfather_snapshot_completed_at timestamptz null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  check (
    subject_limits_mode <> 'enforced'
    or grandfather_snapshot_completed_at is not null
  )
);

insert into private.iclub_commercial_access_config(id)
values(1)
on conflict(id) do nothing;

create table if not exists private.iclub_commercial_migration_state (
  user_id uuid primary key references public.users(id) on delete cascade,
  migration_state text not null default 'legacy_preserved'
    check (migration_state in ('legacy_preserved','selection_ready','migrated')),
  snapshot_version text null,
  snapshot_captured_at timestamptz null,
  selection_confirmed_at timestamptz null,
  source text not null default 'grandfather_capture',
  updated_at timestamptz not null default now(),
  check (char_length(source) between 2 and 80)
);

create table if not exists private.iclub_legacy_subject_snapshot (
  user_id uuid not null references public.users(id) on delete cascade,
  subject_key text not null,
  legacy_mode text not null check (legacy_mode in ('study','competitive')),
  legacy_pinned boolean not null default false,
  snapshot_version text not null,
  captured_at timestamptz not null default now(),
  primary key(user_id,subject_key,snapshot_version),
  check (char_length(subject_key) between 2 and 80),
  check (char_length(snapshot_version) between 2 and 120)
);

create index if not exists iclub_legacy_subject_snapshot_user_idx
  on private.iclub_legacy_subject_snapshot(user_id,captured_at desc);

create table if not exists private.iclub_subject_slot_selections (
  user_id uuid not null references public.users(id) on delete cascade,
  subject_key text not null,
  study_selected boolean not null default false,
  competitive_selected boolean not null default false,
  source text not null,
  selected_at timestamptz null,
  updated_at timestamptz not null default now(),
  primary key(user_id,subject_key),
  check (char_length(subject_key) between 2 and 80),
  check (char_length(source) between 2 and 80),
  check (not competitive_selected or study_selected)
);

create index if not exists iclub_subject_slot_selections_user_idx
  on private.iclub_subject_slot_selections(user_id,study_selected,competitive_selected);

create table if not exists private.iclub_subject_slot_events (
  event_id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  subject_key text not null,
  from_study boolean not null,
  to_study boolean not null,
  from_competitive boolean not null,
  to_competitive boolean not null,
  source text not null,
  created_at timestamptz not null default now(),
  check (char_length(subject_key) between 2 and 80),
  check (char_length(source) between 2 and 80),
  check (not to_competitive or to_study)
);

create index if not exists iclub_subject_slot_events_user_created_idx
  on private.iclub_subject_slot_events(user_id,created_at desc);

alter table private.iclub_subscription_events enable row level security;
alter table private.iclub_commercial_access_config enable row level security;
alter table private.iclub_commercial_migration_state enable row level security;
alter table private.iclub_legacy_subject_snapshot enable row level security;
alter table private.iclub_subject_slot_selections enable row level security;
alter table private.iclub_subject_slot_events enable row level security;

revoke all on private.iclub_subscription_events from public,anon,authenticated;
revoke all on private.iclub_commercial_access_config from public,anon,authenticated;
revoke all on private.iclub_commercial_migration_state from public,anon,authenticated;
revoke all on private.iclub_legacy_subject_snapshot from public,anon,authenticated;
revoke all on private.iclub_subject_slot_selections from public,anon,authenticated;
revoke all on private.iclub_subject_slot_events from public,anon,authenticated;

grant all on private.iclub_subscription_events to service_role;
grant all on private.iclub_commercial_access_config to service_role;
grant all on private.iclub_commercial_migration_state to service_role;
grant all on private.iclub_legacy_subject_snapshot to service_role;
grant all on private.iclub_subject_slot_selections to service_role;
grant all on private.iclub_subject_slot_events to service_role;

create or replace function public.apply_iclub_subscription_event_service_v1(
  p_event_id uuid,
  p_user_id uuid,
  p_event_type text,
  p_plan_code text,
  p_effective_at timestamptz,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_source text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_ent private.iclub_subscription_entitlements%rowtype;
  v_existing private.iclub_subscription_events%rowtype;
  v_from_plan text;
  v_now timestamptz:=now();
  v_effective timestamptz:=coalesce(p_effective_at,now());
begin
  if p_event_id is null or p_user_id is null then
    return jsonb_build_object('ok',false,'reason','invalid_identity');
  end if;

  if coalesce(length(trim(p_source)),0)<2 then
    return jsonb_build_object('ok',false,'reason','invalid_source');
  end if;

  if p_event_type not in (
    'activate','renew','upgrade','downgrade','schedule_downgrade',
    'schedule_cancel','cancel','pause','resume','revoke','expire'
  ) then
    return jsonb_build_object('ok',false,'reason','invalid_event_type');
  end if;

  if p_period_end is not null
     and p_period_start is not null
     and p_period_end<=p_period_start then
    return jsonb_build_object('ok',false,'reason','invalid_period');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found or not v_cfg.lifecycle_enabled then
    return jsonb_build_object('ok',false,'reason','lifecycle_disabled');
  end if;

  if not exists(select 1 from public.users where id=p_user_id) then
    return jsonb_build_object('ok',false,'reason','user_not_found');
  end if;

  perform pg_advisory_xact_lock(hashtextextended('iclub-subscription:'||p_user_id::text,0));

  select * into v_existing
  from private.iclub_subscription_events
  where event_id=p_event_id;

  if found then
    if v_existing.user_id<>p_user_id
       or v_existing.event_type<>p_event_type then
      return jsonb_build_object('ok',false,'reason','event_identity_mismatch');
    end if;

    return jsonb_build_object(
      'ok',v_existing.applied,
      'reason',case when v_existing.applied then null else coalesce(v_existing.result_status,'event_not_applied') end,
      'duplicate',true,
      'event_id',v_existing.event_id
    );
  end if;

  select * into v_ent
  from private.iclub_subscription_entitlements
  where user_id=p_user_id
  for update;

  v_from_plan:=case when found then v_ent.plan_code else null end;

  if p_event_type in ('activate','renew','upgrade','downgrade','schedule_downgrade')
     and (
       p_plan_code is null
       or not exists(
         select 1
         from private.iclub_plan_policies p
         where p.plan_code=p_plan_code
           and p.is_active
       )
     ) then
    return jsonb_build_object('ok',false,'reason','plan_unavailable');
  end if;

  insert into private.iclub_subscription_events(
    event_id,user_id,event_type,from_plan_code,to_plan_code,effective_at,
    period_start,period_end,source,applied,result_status
  ) values (
    p_event_id,p_user_id,p_event_type,v_from_plan,p_plan_code,v_effective,
    p_period_start,p_period_end,trim(p_source),false,'pending'
  );

  if p_event_type='activate' then
    insert into private.iclub_subscription_entitlements(
      user_id,plan_code,entitlement_status,entitlement_source,
      valid_from,valid_until,current_period_start,current_period_end,
      cancel_at_period_end,scheduled_plan_code,scheduled_change_at,
      last_event_id,updated_at
    ) values (
      p_user_id,p_plan_code,'active',trim(p_source),
      v_effective,p_period_end,p_period_start,p_period_end,
      false,null,null,p_event_id,v_now
    )
    on conflict(user_id) do update
    set plan_code=excluded.plan_code,
        entitlement_status='active',
        entitlement_source=excluded.entitlement_source,
        valid_from=excluded.valid_from,
        valid_until=excluded.valid_until,
        current_period_start=excluded.current_period_start,
        current_period_end=excluded.current_period_end,
        cancel_at_period_end=false,
        scheduled_plan_code=null,
        scheduled_change_at=null,
        last_event_id=excluded.last_event_id,
        updated_at=v_now;

  elsif p_event_type='renew' then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    update private.iclub_subscription_entitlements
    set plan_code=coalesce(p_plan_code,plan_code),
        entitlement_status='active',
        entitlement_source=trim(p_source),
        valid_from=coalesce(valid_from,v_effective),
        valid_until=p_period_end,
        current_period_start=coalesce(p_period_start,v_effective),
        current_period_end=p_period_end,
        cancel_at_period_end=false,
        scheduled_plan_code=null,
        scheduled_change_at=null,
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type in ('upgrade','downgrade') then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    update private.iclub_subscription_entitlements
    set plan_code=p_plan_code,
        entitlement_status='active',
        entitlement_source=trim(p_source),
        valid_from=least(coalesce(valid_from,v_effective),v_effective),
        valid_until=coalesce(p_period_end,valid_until),
        current_period_start=coalesce(p_period_start,current_period_start,v_effective),
        current_period_end=coalesce(p_period_end,current_period_end),
        cancel_at_period_end=false,
        scheduled_plan_code=null,
        scheduled_change_at=null,
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type='schedule_downgrade' then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    if p_effective_at is null or p_effective_at<=now() then
      return jsonb_build_object('ok',false,'reason','scheduled_change_must_be_future');
    end if;

    update private.iclub_subscription_entitlements
    set scheduled_plan_code=p_plan_code,
        scheduled_change_at=p_effective_at,
        cancel_at_period_end=false,
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type='schedule_cancel' then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    update private.iclub_subscription_entitlements
    set cancel_at_period_end=true,
        scheduled_plan_code=null,
        scheduled_change_at=null,
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type in ('cancel','expire') then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    update private.iclub_subscription_entitlements
    set entitlement_status='cancelled',
        valid_until=least(coalesce(valid_until,v_effective),v_effective),
        cancel_at_period_end=false,
        scheduled_plan_code=null,
        scheduled_change_at=null,
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type='pause' then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    update private.iclub_subscription_entitlements
    set entitlement_status='paused',
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type='resume' then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    if v_ent.valid_until is not null and v_ent.valid_until<=v_now then
      return jsonb_build_object('ok',false,'reason','subscription_expired');
    end if;

    update private.iclub_subscription_entitlements
    set entitlement_status='active',
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;

  elsif p_event_type='revoke' then
    if v_from_plan is null then
      return jsonb_build_object('ok',false,'reason','subscription_missing');
    end if;

    update private.iclub_subscription_entitlements
    set entitlement_status='revoked',
        valid_until=least(coalesce(valid_until,v_effective),v_effective),
        cancel_at_period_end=false,
        scheduled_plan_code=null,
        scheduled_change_at=null,
        last_event_id=p_event_id,
        updated_at=v_now
    where user_id=p_user_id;
  end if;

  update private.iclub_subscription_events
  set applied=true,
      applied_at=now(),
      result_status='applied'
  where event_id=p_event_id;

  return jsonb_build_object(
    'ok',true,
    'event_id',p_event_id,
    'event_type',p_event_type,
    'previous_plan_code',v_from_plan,
    'current_plan_code',(
      select plan_code
      from private.iclub_subscription_entitlements
      where user_id=p_user_id
    )
  );
end;
$$;

revoke all on function public.apply_iclub_subscription_event_service_v1(
  uuid,uuid,text,text,timestamptz,timestamptz,timestamptz,text
) from public,anon,authenticated;
grant execute on function public.apply_iclub_subscription_event_service_v1(
  uuid,uuid,text,text,timestamptz,timestamptz,timestamptz,text
) to service_role;

create or replace function public.capture_iclub_legacy_access_baseline_service_v1(
  p_snapshot_version text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_users integer:=0;
  v_subjects integer:=0;
begin
  if coalesce(length(trim(p_snapshot_version)),0)<2 then
    return jsonb_build_object('ok',false,'reason','invalid_snapshot_version');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','commercial_config_missing');
  end if;

  if v_cfg.subject_limits_mode<>'shadow' then
    return jsonb_build_object('ok',false,'reason','shadow_mode_required');
  end if;

  if v_cfg.grandfather_snapshot_completed_at is not null then
    if v_cfg.grandfather_snapshot_version=trim(p_snapshot_version) then
      return jsonb_build_object(
        'ok',true,
        'duplicate',true,
        'snapshot_version',v_cfg.grandfather_snapshot_version,
        'completed_at',v_cfg.grandfather_snapshot_completed_at
      );
    end if;

    return jsonb_build_object('ok',false,'reason','snapshot_already_finalized');
  end if;

  insert into private.iclub_commercial_migration_state(
    user_id,migration_state,snapshot_version,snapshot_captured_at,source,updated_at
  )
  select
    u.id,'legacy_preserved',trim(p_snapshot_version),now(),'grandfather_capture',now()
  from public.users u
  on conflict(user_id) do nothing;

  get diagnostics v_users=row_count;

  insert into private.iclub_legacy_subject_snapshot(
    user_id,subject_key,legacy_mode,legacy_pinned,snapshot_version,captured_at
  )
  select
    us.user_id,
    s.subject_key,
    case when us.mode='competitive' then 'competitive' else 'study' end,
    case when us.mode='competitive' then false else coalesce(us.is_pinned,false) end,
    trim(p_snapshot_version),
    now()
  from public.user_subjects us
  join public.subjects s on s.id=us.subject_id
  where coalesce(s.subject_key,'')<>''
  on conflict(user_id,subject_key,snapshot_version) do nothing;

  get diagnostics v_subjects=row_count;

  update private.iclub_commercial_access_config
  set grandfather_snapshot_version=trim(p_snapshot_version),
      grandfather_snapshot_completed_at=now(),
      updated_at=now()
  where id=1;

  return jsonb_build_object(
    'ok',true,
    'duplicate',false,
    'snapshot_version',trim(p_snapshot_version),
    'users_captured',v_users,
    'legacy_subject_rows_captured',v_subjects
  );
end;
$$;

revoke all on function public.capture_iclub_legacy_access_baseline_service_v1(text)
  from public,anon,authenticated;
grant execute on function public.capture_iclub_legacy_access_baseline_service_v1(text)
  to service_role;

create or replace function public.get_iclub_subject_access_guard_service_v1(
  p_user_id uuid,
  p_subject_key text,
  p_intent text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_migration private.iclub_commercial_migration_state%rowtype;
  v_caps jsonb;
  v_slot private.iclub_subject_slot_selections%rowtype;
  v_subject record;
  v_study_limit integer;
  v_comp_limit integer;
  v_study_count integer:=0;
  v_comp_count integer:=0;
begin
  if p_user_id is null or coalesce(length(trim(p_subject_key)),0)<2 then
    return jsonb_build_object('allowed',false,'reason','invalid_request');
  end if;

  if p_intent not in ('open','select_study','select_competitive') then
    return jsonb_build_object('allowed',false,'reason','invalid_intent');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found or v_cfg.subject_limits_mode='off' then
    return jsonb_build_object(
      'allowed',true,
      'mode','legacy_passthrough',
      'reason','subject_limits_off'
    );
  end if;

  if v_cfg.subject_limits_mode='enforced'
     and v_cfg.grandfather_snapshot_completed_at is null then
    -- Commercial enforcement must fail open rather than accidentally lock
    -- existing learners if grandfather preparation is incomplete.
    return jsonb_build_object(
      'allowed',true,
      'mode','legacy_passthrough',
      'reason','grandfather_snapshot_incomplete'
    );
  end if;

  select subject_key,type,is_active
  into v_subject
  from public.subjects
  where subject_key=trim(p_subject_key)
  limit 1;

  if not found or coalesce(v_subject.is_active,false) is not true then
    return jsonb_build_object('allowed',false,'reason','subject_unavailable');
  end if;

  select * into v_migration
  from private.iclub_commercial_migration_state
  where user_id=p_user_id;

  if found
     and v_migration.migration_state='legacy_preserved'
     and p_intent='open' then
    return jsonb_build_object(
      'allowed',true,
      'mode','grandfathered',
      'reason','legacy_access_preserved'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);

  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    if v_cfg.subject_limits_mode='shadow' then
      return jsonb_build_object(
        'allowed',true,
        'mode','shadow',
        'reason',coalesce(v_caps->>'reason','subscription_unresolved')
      );
    end if;

    return jsonb_build_object(
      'allowed',false,
      'mode','commercial',
      'reason',coalesce(v_caps->>'reason','subscription_unresolved')
    );
  end if;

  v_study_limit:=nullif(v_caps->>'study_subject_limit','')::integer;
  v_comp_limit:=coalesce(nullif(v_caps->>'competitive_subject_limit','')::integer,0);

  select * into v_slot
  from private.iclub_subject_slot_selections
  where user_id=p_user_id
    and subject_key=trim(p_subject_key);

  if p_intent='open' then
    if coalesce((v_caps->>'all_available_subjects')::boolean,false) then
      return jsonb_build_object(
        'allowed',true,
        'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
        'reason','plan_all_subjects'
      );
    end if;

    if found and v_slot.study_selected then
      return jsonb_build_object(
        'allowed',true,
        'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
        'reason','subject_selected'
      );
    end if;

    return jsonb_build_object(
      'allowed',v_cfg.subject_limits_mode='shadow',
      'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
      'reason','subject_not_selected'
    );
  end if;

  select
    count(*) filter(where study_selected),
    count(*) filter(where competitive_selected)
  into v_study_count,v_comp_count
  from private.iclub_subject_slot_selections
  where user_id=p_user_id
    and subject_key<>trim(p_subject_key);

  if p_intent='select_study' then
    if v_study_limit is null or v_study_count<v_study_limit then
      return jsonb_build_object(
        'allowed',true,
        'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
        'reason','study_slot_available',
        'limit',v_study_limit,
        'used',v_study_count
      );
    end if;

    return jsonb_build_object(
      'allowed',v_cfg.subject_limits_mode='shadow',
      'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
      'reason','study_subject_limit_reached',
      'limit',v_study_limit,
      'used',v_study_count
    );
  end if;

  if v_subject.type<>'main' then
    return jsonb_build_object(
      'allowed',false,
      'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
      'reason','competitive_requires_main_subject'
    );
  end if;

  if v_comp_count<v_comp_limit
     and (v_study_limit is null or v_study_count<v_study_limit) then
    return jsonb_build_object(
      'allowed',true,
      'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
      'reason','competitive_slot_available',
      'competitive_limit',v_comp_limit,
      'competitive_used',v_comp_count
    );
  end if;

  return jsonb_build_object(
    'allowed',v_cfg.subject_limits_mode='shadow',
    'mode',case when v_cfg.subject_limits_mode='shadow' then 'shadow' else 'commercial' end,
    'reason',case
      when v_comp_count>=v_comp_limit then 'competitive_subject_limit_reached'
      else 'study_subject_limit_reached'
    end,
    'study_limit',v_study_limit,
    'study_used',v_study_count,
    'competitive_limit',v_comp_limit,
    'competitive_used',v_comp_count
  );
end;
$$;

revoke all on function public.get_iclub_subject_access_guard_service_v1(uuid,text,text)
  from public,anon,authenticated;
grant execute on function public.get_iclub_subject_access_guard_service_v1(uuid,text,text)
  to service_role;

create or replace function public.set_iclub_subject_slot_service_v1(
  p_event_id uuid,
  p_user_id uuid,
  p_subject_key text,
  p_study_selected boolean,
  p_competitive_selected boolean,
  p_source text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_guard jsonb;
  v_existing private.iclub_subject_slot_selections%rowtype;
  v_old_study boolean:=false;
  v_old_comp boolean:=false;
begin
  if p_event_id is null
     or p_user_id is null
     or coalesce(length(trim(p_subject_key)),0)<2
     or coalesce(length(trim(p_source)),0)<2 then
    return jsonb_build_object('ok',false,'reason','invalid_request');
  end if;

  if coalesce(p_competitive_selected,false)
     and not coalesce(p_study_selected,false) then
    return jsonb_build_object('ok',false,'reason','competitive_requires_study');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found or v_cfg.subject_limits_mode='off' then
    return jsonb_build_object('ok',false,'reason','subject_slot_writes_disabled');
  end if;

  if exists(
    select 1
    from private.iclub_subject_slot_events
    where event_id=p_event_id
  ) then
    return jsonb_build_object('ok',true,'duplicate',true,'event_id',p_event_id);
  end if;

  perform pg_advisory_xact_lock(hashtextextended('iclub-subject-slot:'||p_user_id::text,0));

  select * into v_existing
  from private.iclub_subject_slot_selections
  where user_id=p_user_id
    and subject_key=trim(p_subject_key)
  for update;

  if found then
    v_old_study:=v_existing.study_selected;
    v_old_comp:=v_existing.competitive_selected;
  end if;

  if coalesce(p_competitive_selected,false) then
    v_guard:=public.get_iclub_subject_access_guard_service_v1(
      p_user_id,trim(p_subject_key),'select_competitive'
    );
  elsif coalesce(p_study_selected,false) then
    v_guard:=public.get_iclub_subject_access_guard_service_v1(
      p_user_id,trim(p_subject_key),'select_study'
    );
  else
    v_guard:=jsonb_build_object('allowed',true,'reason','release_slot');
  end if;

  if coalesce((v_guard->>'allowed')::boolean,false) is not true
     and v_cfg.subject_limits_mode='enforced' then
    return jsonb_build_object(
      'ok',false,
      'reason',coalesce(v_guard->>'reason','subject_limit_reached')
    );
  end if;

  insert into private.iclub_subject_slot_selections(
    user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
  ) values (
    p_user_id,trim(p_subject_key),coalesce(p_study_selected,false),
    coalesce(p_competitive_selected,false),trim(p_source),
    case when coalesce(p_study_selected,false) then now() else null end,
    now()
  )
  on conflict(user_id,subject_key) do update
  set study_selected=excluded.study_selected,
      competitive_selected=excluded.competitive_selected,
      source=excluded.source,
      selected_at=case
        when excluded.study_selected and not private.iclub_subject_slot_selections.study_selected then now()
        when excluded.study_selected then private.iclub_subject_slot_selections.selected_at
        else null
      end,
      updated_at=now();

  insert into private.iclub_subject_slot_events(
    event_id,user_id,subject_key,from_study,to_study,
    from_competitive,to_competitive,source
  ) values (
    p_event_id,p_user_id,trim(p_subject_key),
    v_old_study,coalesce(p_study_selected,false),
    v_old_comp,coalesce(p_competitive_selected,false),
    trim(p_source)
  );

  return jsonb_build_object(
    'ok',true,
    'duplicate',false,
    'subject_key',trim(p_subject_key),
    'study_selected',coalesce(p_study_selected,false),
    'competitive_selected',coalesce(p_competitive_selected,false),
    'shadow',v_cfg.subject_limits_mode='shadow'
  );
end;
$$;

revoke all on function public.set_iclub_subject_slot_service_v1(
  uuid,uuid,text,boolean,boolean,text
) from public,anon,authenticated;
grant execute on function public.set_iclub_subject_slot_service_v1(
  uuid,uuid,text,boolean,boolean,text
) to service_role;

create or replace function public.finalize_iclub_subject_selection_service_v1(
  p_user_id uuid,
  p_source text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_caps jsonb;
  v_study_limit integer;
  v_comp_limit integer;
  v_study_count integer:=0;
  v_comp_count integer:=0;
begin
  if p_user_id is null or coalesce(length(trim(p_source)),0)<2 then
    return jsonb_build_object('ok',false,'reason','invalid_request');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found or v_cfg.subject_limits_mode='off' then
    return jsonb_build_object('ok',false,'reason','subject_selection_disabled');
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(p_user_id);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'ok',false,
      'reason',coalesce(v_caps->>'reason','subscription_unresolved')
    );
  end if;

  v_study_limit:=nullif(v_caps->>'study_subject_limit','')::integer;
  v_comp_limit:=coalesce(nullif(v_caps->>'competitive_subject_limit','')::integer,0);

  select
    count(*) filter(where study_selected),
    count(*) filter(where competitive_selected)
  into v_study_count,v_comp_count
  from private.iclub_subject_slot_selections
  where user_id=p_user_id;

  if v_study_limit is not null and v_study_count>v_study_limit then
    return jsonb_build_object('ok',false,'reason','study_subject_limit_reached');
  end if;

  if v_comp_count>v_comp_limit then
    return jsonb_build_object('ok',false,'reason','competitive_subject_limit_reached');
  end if;

  if v_study_limit is not null and v_study_count=0 then
    return jsonb_build_object('ok',false,'reason','study_subject_required');
  end if;

  insert into private.iclub_commercial_migration_state(
    user_id,migration_state,selection_confirmed_at,source,updated_at
  ) values (
    p_user_id,'migrated',now(),trim(p_source),now()
  )
  on conflict(user_id) do update
  set migration_state='migrated',
      selection_confirmed_at=now(),
      source=excluded.source,
      updated_at=now();

  return jsonb_build_object(
    'ok',true,
    'migration_state','migrated',
    'study_selected',v_study_count,
    'competitive_selected',v_comp_count
  );
end;
$$;

revoke all on function public.finalize_iclub_subject_selection_service_v1(uuid,text)
  from public,anon,authenticated;
grant execute on function public.finalize_iclub_subject_selection_service_v1(uuid,text)
  to service_role;

commit;
