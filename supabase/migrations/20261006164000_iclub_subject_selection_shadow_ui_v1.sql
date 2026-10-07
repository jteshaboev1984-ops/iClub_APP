-- iClub beta subject-selection UI v1.
-- Browser-safe shadow selector for the three-user canary cohort.
--
-- This phase never mutates public.user_subjects and never changes current learner access.
-- It writes only to private.iclub_subject_slot_selections while subject_limits_mode='shadow'.

begin;

alter table private.iclub_commercial_access_config
  add column if not exists subject_selection_ui_enabled boolean not null default false;

create or replace function public.get_iclub_subject_selection_bootstrap_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $bootstrap$
declare
  v_uid uuid:=auth.uid();
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_subjects jsonb;
  v_slots jsonb;
  v_study_count integer:=0;
  v_comp_count integer:=0;
  v_migration_state text:='legacy_preserved';
begin
  if v_uid is null then
    return jsonb_build_object(
      'visible',false,
      'reason','auth_required',
      'ui_version','subject_selection_shadow_v1'
    );
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found
     or not coalesce(v_cfg.subject_selection_ui_enabled,false)
     or v_cfg.subject_limits_mode<>'shadow' then
    return jsonb_build_object(
      'visible',false,
      'reason','subject_selection_disabled',
      'ui_version','subject_selection_shadow_v1'
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or not private.iclub_rollout_allows_user_v1(v_uid,v_runtime.plans_rollout_mode) then
    return jsonb_build_object(
      'visible',false,
      'reason','rollout_unavailable',
      'ui_version','subject_selection_shadow_v1'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'visible',false,
      'reason',coalesce(v_caps->>'reason','subscription_unavailable'),
      'ui_version','subject_selection_shadow_v1'
    );
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'subject_key',s.subject_key,
      'type',s.type
    )
    order by s.id
  ),'[]'::jsonb)
  into v_subjects
  from public.subjects s
  where s.is_active
    and coalesce(s.subject_key,'')<>'';

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'subject_key',x.subject_key,
      'study_selected',x.study_selected,
      'competitive_selected',x.competitive_selected
    )
    order by x.subject_key
  ),'[]'::jsonb)
  into v_slots
  from private.iclub_subject_slot_selections x
  where x.user_id=v_uid;

  select
    count(*) filter(where study_selected),
    count(*) filter(where competitive_selected)
  into v_study_count,v_comp_count
  from private.iclub_subject_slot_selections
  where user_id=v_uid;

  select m.migration_state into v_migration_state
  from private.iclub_commercial_migration_state m
  where m.user_id=v_uid;

  v_migration_state:=coalesce(v_migration_state,'legacy_preserved');

  return jsonb_build_object(
    'visible',true,
    'reason',null,
    'plan_code',v_caps->>'plan_code',
    'study_subject_limit',v_caps->'study_subject_limit',
    'all_available_subjects',coalesce((v_caps->>'all_available_subjects')::boolean,false),
    'competitive_subject_limit',coalesce((v_caps->>'competitive_subject_limit')::integer,0),
    'study_selected_count',v_study_count,
    'competitive_selected_count',v_comp_count,
    'subjects',v_subjects,
    'selections',v_slots,
    'migration_state',v_migration_state,
    'access_unchanged',true,
    'ui_version','subject_selection_shadow_v1'
  );
end;
$bootstrap$;

revoke all on function public.get_iclub_subject_selection_bootstrap_v1()
  from public,anon;
grant execute on function public.get_iclub_subject_selection_bootstrap_v1()
  to authenticated,service_role;

create or replace function public.set_iclub_my_subject_slot_v1(
  p_subject_key text,
  p_study_selected boolean,
  p_competitive_selected boolean
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $setslot$
declare
  v_uid uuid:=auth.uid();
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_subject record;
  v_study_limit integer;
  v_comp_limit integer;
  v_all_subjects boolean:=false;
  v_current_study boolean:=false;
  v_current_comp boolean:=false;
  v_study_used_other integer:=0;
  v_comp_used_other integer:=0;
  v_result jsonb;
begin
  if v_uid is null then
    return jsonb_build_object('ok',false,'reason','auth_required');
  end if;

  if coalesce(length(trim(p_subject_key)),0)<2 then
    return jsonb_build_object('ok',false,'reason','invalid_subject');
  end if;

  if coalesce(p_competitive_selected,false)
     and not coalesce(p_study_selected,false) then
    return jsonb_build_object('ok',false,'reason','competitive_requires_study');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found
     or not coalesce(v_cfg.subject_selection_ui_enabled,false)
     or v_cfg.subject_limits_mode<>'shadow' then
    return jsonb_build_object('ok',false,'reason','subject_selection_disabled');
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or not private.iclub_rollout_allows_user_v1(v_uid,v_runtime.plans_rollout_mode) then
    return jsonb_build_object('ok',false,'reason','rollout_unavailable');
  end if;

  select s.subject_key,s.type,s.is_active
  into v_subject
  from public.subjects s
  where s.subject_key=trim(p_subject_key)
  limit 1;

  if not found or coalesce(v_subject.is_active,false) is not true then
    return jsonb_build_object('ok',false,'reason','subject_unavailable');
  end if;

  if coalesce(p_competitive_selected,false)
     and v_subject.type<>'main' then
    return jsonb_build_object('ok',false,'reason','competitive_requires_main_subject');
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'ok',false,
      'reason',coalesce(v_caps->>'reason','subscription_unavailable')
    );
  end if;

  -- One learner's slot changes are serialized so two quick taps/requests cannot
  -- race past the plan limit.
  perform pg_advisory_xact_lock(hashtextextended('iclub-subject-slot:'||v_uid::text,0));

  v_all_subjects:=coalesce((v_caps->>'all_available_subjects')::boolean,false);
  v_study_limit:=nullif(v_caps->>'study_subject_limit','')::integer;
  v_comp_limit:=coalesce(nullif(v_caps->>'competitive_subject_limit','')::integer,0);

  select
    coalesce(bool_or(x.study_selected),false),
    coalesce(bool_or(x.competitive_selected),false)
  into v_current_study,v_current_comp
  from private.iclub_subject_slot_selections x
  where x.user_id=v_uid
    and x.subject_key=trim(p_subject_key);

  select
    count(*) filter(where x.study_selected),
    count(*) filter(where x.competitive_selected)
  into v_study_used_other,v_comp_used_other
  from private.iclub_subject_slot_selections x
  where x.user_id=v_uid
    and x.subject_key<>trim(p_subject_key);

  if coalesce(p_study_selected,false)
     and not v_all_subjects
     and not v_current_study
     and v_study_limit is not null
     and v_study_used_other>=v_study_limit then
    return jsonb_build_object(
      'ok',false,
      'reason','study_subject_limit_reached',
      'limit',v_study_limit,
      'used',v_study_used_other
    );
  end if;

  if coalesce(p_competitive_selected,false)
     and not v_current_comp
     and v_comp_used_other>=v_comp_limit then
    return jsonb_build_object(
      'ok',false,
      'reason','competitive_subject_limit_reached',
      'limit',v_comp_limit,
      'used',v_comp_used_other
    );
  end if;

  v_result:=public.set_iclub_subject_slot_service_v1(
    gen_random_uuid(),
    v_uid,
    trim(p_subject_key),
    coalesce(p_study_selected,false),
    coalesce(p_competitive_selected,false),
    'browser_shadow_v1'
  );

  if coalesce((v_result->>'ok')::boolean,false) is not true then
    return v_result;
  end if;

  return jsonb_build_object(
    'ok',true,
    'subject_key',trim(p_subject_key),
    'study_selected',coalesce(p_study_selected,false),
    'competitive_selected',coalesce(p_competitive_selected,false),
    'access_unchanged',true
  );
end;
$setslot$;
revoke all on function public.set_iclub_my_subject_slot_v1(text,boolean,boolean)
  from public,anon;
grant execute on function public.set_iclub_my_subject_slot_v1(text,boolean,boolean)
  to authenticated,service_role;

commit;