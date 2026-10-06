-- iClub grandfathering + subject slot services v1.
-- Depends on 20261006153000_iclub_subscription_access_lifecycle_v1.sql.
-- No legacy learner rows are mutated.

begin;

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
  v_reason text;
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

  v_reason:=coalesce(v_guard->>'reason','');

  if v_reason in (
    'subscription_unassigned',
    'plan_unavailable',
    'subject_unavailable',
    'competitive_requires_main_subject',
    'invalid_request',
    'invalid_intent'
  ) then
    return jsonb_build_object('ok',false,'reason',v_reason);
  end if;

  if coalesce((v_guard->>'allowed')::boolean,false) is not true
     and v_cfg.subject_limits_mode='enforced' then
    return jsonb_build_object(
      'ok',false,
      'reason',coalesce(v_reason,'subject_limit_reached')
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
