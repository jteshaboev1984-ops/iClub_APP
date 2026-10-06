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

  if coalesce(v_guard->>'reason','') in (
    'subscription_unassigned',
    'plan_unavailable',
    'subject_unavailable',
    'competitive_requires_main_subject',
    'invalid_request',
    'invalid_intent'
  ) then
    return jsonb_build_object(
      'ok',false,
      'reason',v_guard->>'reason'
    );
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
