-- iClub Plans + subject-selection canary activation control v1.
--
-- Dormant by design. This migration does NOT activate any learner, plan, UI,
-- rollout mode or subject limit. It only creates service-role-only controls
-- for a future explicit three-user canary activation.
--
-- Safety boundary:
-- - the three users must be exactly the currently active Mathematics Exam Prep
--   beta members with active Core + AI entitlement;
-- - test plans are Free / Plus / Pro overrides, not paid entitlements;
-- - Global AI, checkout and subscription lifecycle must remain OFF;
-- - subject limits may only move OFF -> SHADOW;
-- - no public learner/history table is written;
-- - migration_state is never finalized here.

begin;

create or replace function public.get_iclub_product_canary_activation_snapshot_service_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $snapshot$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_active_beta integer:=0;
  v_active_core_ai integer:=0;
  v_active_mentor integer:=0;
  v_overlap integer:=0;
  v_fingerprint text:=null;
  v_enabled_canaries integer:=0;
  v_canary_rows integer:=0;
  v_unexpected_canary_rows integer:=0;
  v_subscription_rows integer:=0;
  v_slot_rows integer:=0;
  v_non_beta_slot_rows integer:=0;
  v_migration_rows integer:=0;
  v_migrated_rows integer:=0;
  v_safe boolean:=false;
begin
  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  select count(distinct b.user_id)
  into v_active_beta
  from private.exam_prep_beta_members b
  where b.member_status='active';

  select
    count(*) filter(
      where e.entitlement_status='active'
        and e.core_access
        and e.ai_assist
    ),
    count(*) filter(
      where e.entitlement_status='active'
        and e.mentor_care_entitled
    )
  into v_active_core_ai,v_active_mentor
  from private.exam_prep_feature_entitlements e;

  select
    count(distinct b.user_id),
    md5(coalesce(string_agg(distinct b.user_id::text,',' order by b.user_id::text),''))
  into v_overlap,v_fingerprint
  from private.exam_prep_beta_members b
  join private.exam_prep_feature_entitlements e
    on e.user_id=b.user_id
  where b.member_status='active'
    and e.entitlement_status='active'
    and e.core_access
    and e.ai_assist;

  select count(*) filter(where c.enabled),count(*)
  into v_enabled_canaries,v_canary_rows
  from private.iclub_product_canary_users c;

  select count(*)
  into v_unexpected_canary_rows
  from private.iclub_product_canary_users c
  where not exists(
    select 1
    from private.exam_prep_beta_members b
    join private.exam_prep_feature_entitlements e
      on e.user_id=b.user_id
    where b.user_id=c.user_id
      and b.member_status='active'
      and e.entitlement_status='active'
      and e.core_access
      and e.ai_assist
  );

  select count(*)
  into v_subscription_rows
  from private.iclub_subscription_entitlements;

  select count(*)
  into v_slot_rows
  from private.iclub_subject_slot_selections;

  select count(*)
  into v_non_beta_slot_rows
  from private.iclub_subject_slot_selections s
  where not exists(
    select 1
    from private.exam_prep_beta_members b
    join private.exam_prep_feature_entitlements e
      on e.user_id=b.user_id
    where b.user_id=s.user_id
      and b.member_status='active'
      and e.entitlement_status='active'
      and e.core_access
      and e.ai_assist
  );

  select count(*),count(*) filter(where m.migration_state='migrated')
  into v_migration_rows,v_migrated_rows
  from private.iclub_commercial_migration_state m;

  v_safe:=
    v_runtime.id is not null
    and v_cfg.id is not null
    and not v_runtime.ui_enabled
    and not v_runtime.gateway_enabled
    and not v_runtime.generation_enabled
    and v_runtime.kill_switch
    and v_runtime.global_ai_rollout_mode='off'
    and not v_runtime.plans_ui_enabled
    and v_runtime.plans_rollout_mode='off'
    and not v_runtime.checkout_enabled
    and not v_cfg.lifecycle_enabled
    and v_cfg.subject_limits_mode='off'
    and not v_cfg.subject_selection_ui_enabled
    and v_cfg.grandfather_snapshot_completed_at is null
    and v_active_beta=3
    and v_active_core_ai=3
    and v_overlap=3
    and v_active_mentor=0
    and v_enabled_canaries=0
    and v_unexpected_canary_rows=0
    and v_subscription_rows=0
    and v_non_beta_slot_rows=0
    and v_migration_rows=0
    and v_migrated_rows=0;

  return jsonb_build_object(
    'safe_to_activate',v_safe,
    'eligible_beta_count',v_overlap,
    'eligible_beta_fingerprint',v_fingerprint,
    'active_beta_members',v_active_beta,
    'active_core_ai_entitlements',v_active_core_ai,
    'active_mentor_entitlements',v_active_mentor,
    'enabled_canaries',v_enabled_canaries,
    'canary_rows',v_canary_rows,
    'unexpected_canary_rows',v_unexpected_canary_rows,
    'explicit_subscription_rows',v_subscription_rows,
    'subject_slot_rows',v_slot_rows,
    'non_beta_subject_slot_rows',v_non_beta_slot_rows,
    'commercial_migration_rows',v_migration_rows,
    'migrated_rows',v_migrated_rows,
    'grandfather_snapshot_complete',v_cfg.grandfather_snapshot_completed_at is not null,
    'runtime',jsonb_build_object(
      'global_ai_ui_enabled',v_runtime.ui_enabled,
      'global_ai_gateway_enabled',v_runtime.gateway_enabled,
      'global_ai_generation_enabled',v_runtime.generation_enabled,
      'global_ai_kill_switch',v_runtime.kill_switch,
      'global_ai_rollout_mode',v_runtime.global_ai_rollout_mode,
      'plans_ui_enabled',v_runtime.plans_ui_enabled,
      'plans_rollout_mode',v_runtime.plans_rollout_mode,
      'checkout_enabled',v_runtime.checkout_enabled
    ),
    'commercial',jsonb_build_object(
      'lifecycle_enabled',v_cfg.lifecycle_enabled,
      'subject_limits_mode',v_cfg.subject_limits_mode,
      'subject_selection_ui_enabled',v_cfg.subject_selection_ui_enabled
    )
  );
end;
$snapshot$;

revoke all on function public.get_iclub_product_canary_activation_snapshot_service_v1()
  from public,anon,authenticated;
grant execute on function public.get_iclub_product_canary_activation_snapshot_service_v1()
  to service_role;


create or replace function public.activate_iclub_plans_subject_canary_service_v1(
  p_free_user_id uuid,
  p_plus_user_id uuid,
  p_pro_user_id uuid,
  p_expected_beta_fingerprint text,
  p_source text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $activate$
declare
  v_snapshot jsonb;
  v_match_count integer:=0;
  v_enabled integer:=0;
  v_free_count integer:=0;
  v_plus_count integer:=0;
  v_pro_count integer:=0;
begin
  if p_free_user_id is null
     or p_plus_user_id is null
     or p_pro_user_id is null
     or p_free_user_id=p_plus_user_id
     or p_free_user_id=p_pro_user_id
     or p_plus_user_id=p_pro_user_id then
    return jsonb_build_object('ok',false,'reason','invalid_canary_identity_set');
  end if;

  if coalesce(length(trim(p_expected_beta_fingerprint)),0)<>32 then
    return jsonb_build_object('ok',false,'reason','invalid_beta_fingerprint');
  end if;

  if coalesce(length(trim(p_source)),0)<2
     or length(trim(p_source))>80 then
    return jsonb_build_object('ok',false,'reason','invalid_source');
  end if;

  perform pg_advisory_xact_lock(hashtextextended('iclub-product-canary-activation-v1',0));

  -- Freeze the two existing Exam Prep authority sets for this very short
  -- activation transaction. This prevents a cohort/entitlement change between
  -- preflight validation and the final flag flip.
  lock table private.exam_prep_beta_members in share mode;
  lock table private.exam_prep_feature_entitlements in share mode;

  -- Serialize the runtime/config rows that will be changed.
  perform 1
  from private.iclub_global_ai_runtime_config
  where id=1
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','runtime_config_missing');
  end if;

  perform 1
  from private.iclub_commercial_access_config
  where id=1
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','commercial_config_missing');
  end if;

  v_snapshot:=public.get_iclub_product_canary_activation_snapshot_service_v1();

  if coalesce((v_snapshot->>'safe_to_activate')::boolean,false) is not true then
    return jsonb_build_object(
      'ok',false,
      'reason','preflight_not_green',
      'snapshot',v_snapshot
    );
  end if;

  if v_snapshot->>'eligible_beta_fingerprint'<>trim(p_expected_beta_fingerprint) then
    return jsonb_build_object(
      'ok',false,
      'reason','beta_fingerprint_changed',
      'current_beta_fingerprint',v_snapshot->>'eligible_beta_fingerprint'
    );
  end if;

  select count(distinct b.user_id)
  into v_match_count
  from private.exam_prep_beta_members b
  join private.exam_prep_feature_entitlements e
    on e.user_id=b.user_id
  where b.member_status='active'
    and e.entitlement_status='active'
    and e.core_access
    and e.ai_assist
    and b.user_id=any(array[p_free_user_id,p_plus_user_id,p_pro_user_id]);

  if v_match_count<>3 then
    return jsonb_build_object('ok',false,'reason','beta_set_mismatch');
  end if;

  insert into private.iclub_product_canary_users(
    user_id,enabled,test_plan_code,source,created_at,updated_at
  ) values
    (p_free_user_id,true,'free',trim(p_source),now(),now()),
    (p_plus_user_id,true,'plus',trim(p_source),now(),now()),
    (p_pro_user_id,true,'pro',trim(p_source),now(),now())
  on conflict(user_id) do update
  set enabled=true,
      test_plan_code=excluded.test_plan_code,
      source=excluded.source,
      updated_at=now();

  select
    count(*) filter(where enabled),
    count(*) filter(where enabled and test_plan_code='free'),
    count(*) filter(where enabled and test_plan_code='plus'),
    count(*) filter(where enabled and test_plan_code='pro')
  into v_enabled,v_free_count,v_plus_count,v_pro_count
  from private.iclub_product_canary_users;

  if v_enabled<>3
     or v_free_count<>1
     or v_plus_count<>1
     or v_pro_count<>1 then
    raise exception 'Canary activation invariant failed: enabled %, free %, plus %, pro %',
      v_enabled,v_free_count,v_plus_count,v_pro_count;
  end if;

  update private.iclub_global_ai_runtime_config
  set plans_ui_enabled=true,
      plans_rollout_mode='canary',
      checkout_enabled=false,
      global_ai_rollout_mode='off',
      ui_enabled=false,
      gateway_enabled=false,
      generation_enabled=false,
      kill_switch=true,
      updated_at=now()
  where id=1;

  update private.iclub_commercial_access_config
  set lifecycle_enabled=false,
      subject_limits_mode='shadow',
      subject_selection_ui_enabled=true,
      updated_at=now()
  where id=1;

  return jsonb_build_object(
    'ok',true,
    'mode','canary',
    'enabled_canaries',3,
    'test_plans',jsonb_build_object('free',1,'plus',1,'pro',1),
    'plans_ui_enabled',true,
    'plans_rollout_mode','canary',
    'subject_selection_ui_enabled',true,
    'subject_limits_mode','shadow',
    'checkout_enabled',false,
    'lifecycle_enabled',false,
    'global_ai_enabled',false,
    'legacy_access_unchanged',true
  );
end;
$activate$;

revoke all on function public.activate_iclub_plans_subject_canary_service_v1(
  uuid,uuid,uuid,text,text
) from public,anon,authenticated;
grant execute on function public.activate_iclub_plans_subject_canary_service_v1(
  uuid,uuid,uuid,text,text
) to service_role;


create or replace function public.deactivate_iclub_plans_subject_canary_service_v1(
  p_source text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $deactivate$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_disabled integer:=0;
  v_slot_rows integer:=0;
begin
  if coalesce(length(trim(p_source)),0)<2
     or length(trim(p_source))>80 then
    return jsonb_build_object('ok',false,'reason','invalid_source');
  end if;

  perform pg_advisory_xact_lock(hashtextextended('iclub-product-canary-activation-v1',0));

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','runtime_config_missing');
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1
  for update;

  if not found then
    return jsonb_build_object('ok',false,'reason','commercial_config_missing');
  end if;

  -- This rollback control is intentionally phase-scoped. Refuse to disable the
  -- shared canary cohort if a later independent Global AI or paid-lifecycle
  -- phase has been activated.
  if v_runtime.global_ai_rollout_mode<>'off'
     or v_runtime.ui_enabled
     or v_runtime.gateway_enabled
     or v_runtime.generation_enabled
     or not v_runtime.kill_switch then
    return jsonb_build_object('ok',false,'reason','global_ai_phase_active');
  end if;

  if v_cfg.lifecycle_enabled
     or v_runtime.checkout_enabled then
    return jsonb_build_object('ok',false,'reason','paid_lifecycle_phase_active');
  end if;

  update private.iclub_commercial_access_config
  set subject_selection_ui_enabled=false,
      subject_limits_mode='off',
      updated_at=now()
  where id=1;

  update private.iclub_global_ai_runtime_config
  set plans_ui_enabled=false,
      plans_rollout_mode='off',
      checkout_enabled=false,
      updated_at=now()
  where id=1;

  update private.iclub_product_canary_users
  set enabled=false,
      updated_at=now()
  where enabled;

  get diagnostics v_disabled=row_count;

  select count(*) into v_slot_rows
  from private.iclub_subject_slot_selections;

  return jsonb_build_object(
    'ok',true,
    'plans_ui_enabled',false,
    'plans_rollout_mode','off',
    'subject_selection_ui_enabled',false,
    'subject_limits_mode','off',
    'disabled_canaries',v_disabled,
    'preserved_subject_slot_rows',v_slot_rows,
    'legacy_access_unchanged',true,
    'source',trim(p_source)
  );
end;
$deactivate$;

revoke all on function public.deactivate_iclub_plans_subject_canary_service_v1(text)
  from public,anon,authenticated;
grant execute on function public.deactivate_iclub_plans_subject_canary_service_v1(text)
  to service_role;

commit;
