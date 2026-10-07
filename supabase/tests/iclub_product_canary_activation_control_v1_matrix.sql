\set ON_ERROR_STOP on

BEGIN;

create temp table canary_activation_people(
  person_key text primary key,
  user_id uuid not null unique
) on commit drop;

do $people$
declare
  k text;
  uid uuid;
begin
  foreach k in array array['free','plus','pro','normal'] loop
    uid:=gen_random_uuid();

    insert into auth.users(id,aud,role,email,created_at,updated_at)
    values(
      uid,'authenticated','authenticated',
      k||'.canary-activation@example.invalid',now(),now()
    );

    insert into public.users(
      id,first_name,last_name,language_code,created_at,must_change_password
    ) values(
      uid,'Canary',initcap(k),'ru',now(),false
    );

    insert into canary_activation_people(person_key,user_id)
    values(k,uid);
  end loop;
end;
$people$;

insert into private.exam_prep_beta_members(
  user_id,member_status,service_mode,activation_wave
)
select user_id,'active','core_ai',1
from canary_activation_people
where person_key in ('free','plus','pro');

insert into private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key
)
select user_id,'active',true,true,false,'ci-three-user'
from canary_activation_people
where person_key in ('free','plus','pro');

-- One legacy row proves activation, selection and rollback never reinterpret or
-- rewrite the existing public.user_subjects contract.
insert into public.user_subjects(user_id,subject_id,mode,is_pinned)
select user_id,1,'competitive',false
from canary_activation_people
where person_key='free';

create temp table canary_activation_legacy_digest as
select
  count(*)::bigint as row_count,
  md5(coalesce(string_agg(
    user_id::text||':'||subject_id::text||':'||mode||':'||is_pinned::text,
    ',' order by user_id::text,subject_id
  ),'')) as digest
from public.user_subjects;


-- Preflight must recognize exactly the three active Exam Prep Core+AI learners
-- and prove every commercial/global-AI switch remains dormant.
do $preflight$
declare
  v jsonb;
begin
  v:=public.get_iclub_product_canary_activation_snapshot_service_v1();

  if coalesce((v->>'safe_to_activate')::boolean,false) is not true
     or (v->>'eligible_beta_count')::integer<>3
     or (v->>'active_beta_members')::integer<>3
     or (v->>'active_core_ai_entitlements')::integer<>3
     or (v->>'active_mentor_entitlements')::integer<>0
     or length(v->>'eligible_beta_fingerprint')<>32 then
    raise exception 'Initial canary preflight is not GREEN: %',v;
  end if;

  if (v->'runtime'->>'plans_rollout_mode')<>'off'
     or coalesce((v->'runtime'->>'plans_ui_enabled')::boolean,true)
     or (v->'commercial'->>'subject_limits_mode')<>'off'
     or coalesce((v->'commercial'->>'subject_selection_ui_enabled')::boolean,true) then
    raise exception 'Initial canary preflight did not stay dormant: %',v;
  end if;
end;
$preflight$;


-- A wrong identity set must fail before any canary row or runtime flag changes.
do $wrong_identity$
declare
  v jsonb;
  fp text;
  free_uid uuid:=(select user_id from canary_activation_people where person_key='normal');
  plus_uid uuid:=(select user_id from canary_activation_people where person_key='plus');
  pro_uid uuid:=(select user_id from canary_activation_people where person_key='pro');
begin
  fp:=public.get_iclub_product_canary_activation_snapshot_service_v1()
    ->>'eligible_beta_fingerprint';

  v:=public.activate_iclub_plans_subject_canary_service_v1(
    free_uid,plus_uid,pro_uid,fp,'ci-wrong-set'
  );

  if coalesce((v->>'ok')::boolean,true)
     or v->>'reason'<>'beta_set_mismatch' then
    raise exception 'Wrong three-user identity set was not rejected: %',v;
  end if;

  if (select count(*) from private.iclub_product_canary_users where enabled)<>0
     or (select plans_rollout_mode from private.iclub_global_ai_runtime_config where id=1)<>'off'
     or (select subject_limits_mode from private.iclub_commercial_access_config where id=1)<>'off' then
    raise exception 'Rejected activation left partial canary state';
  end if;
end;
$wrong_identity$;


-- Correct activation is one atomic transition: exact three beta users, exactly
-- one Free/Plus/Pro test override, Plans canary ON, subject selection SHADOW,
-- while Global AI, checkout and lifecycle remain OFF.
do $activate$
declare
  v jsonb;
  fp text;
  free_uid uuid:=(select user_id from canary_activation_people where person_key='free');
  plus_uid uuid:=(select user_id from canary_activation_people where person_key='plus');
  pro_uid uuid:=(select user_id from canary_activation_people where person_key='pro');
begin
  fp:=public.get_iclub_product_canary_activation_snapshot_service_v1()
    ->>'eligible_beta_fingerprint';

  v:=public.activate_iclub_plans_subject_canary_service_v1(
    free_uid,plus_uid,pro_uid,fp,'ci-three-user-activation'
  );

  if coalesce((v->>'ok')::boolean,false) is not true
     or v->>'plans_rollout_mode'<>'canary'
     or v->>'subject_limits_mode'<>'shadow'
     or coalesce((v->>'global_ai_enabled')::boolean,true) then
    raise exception 'Correct canary activation failed: %',v;
  end if;

  if (select count(*) from private.iclub_product_canary_users where enabled)<>3
     or (select count(*) from private.iclub_product_canary_users where enabled and test_plan_code='free')<>1
     or (select count(*) from private.iclub_product_canary_users where enabled and test_plan_code='plus')<>1
     or (select count(*) from private.iclub_product_canary_users where enabled and test_plan_code='pro')<>1 then
    raise exception 'Free/Plus/Pro canary distribution mismatch';
  end if;

  if not (select plans_ui_enabled from private.iclub_global_ai_runtime_config where id=1)
     or (select plans_rollout_mode from private.iclub_global_ai_runtime_config where id=1)<>'canary'
     or (select checkout_enabled from private.iclub_global_ai_runtime_config where id=1)
     or (select global_ai_rollout_mode from private.iclub_global_ai_runtime_config where id=1)<>'off'
     or (select ui_enabled from private.iclub_global_ai_runtime_config where id=1)
     or (select gateway_enabled from private.iclub_global_ai_runtime_config where id=1)
     or (select generation_enabled from private.iclub_global_ai_runtime_config where id=1)
     or not (select kill_switch from private.iclub_global_ai_runtime_config where id=1) then
    raise exception 'Activation changed forbidden Global AI/checkout flags';
  end if;

  if (select lifecycle_enabled from private.iclub_commercial_access_config where id=1)
     or (select subject_limits_mode from private.iclub_commercial_access_config where id=1)<>'shadow'
     or not (select subject_selection_ui_enabled from private.iclub_commercial_access_config where id=1) then
    raise exception 'Activation commercial flags mismatch';
  end if;
end;
$activate$;


-- A normal learner cannot see or mutate the canary surfaces even by calling the
-- authenticated server RPCs directly.
do $noncanary_direct_calls$
declare
  v jsonb;
  uid uuid:=(select user_id from canary_activation_people where person_key='normal');
begin
  perform set_config('request.jwt.claim.sub',uid::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_plan_ui_bootstrap_v1();
  if coalesce((v->>'visible')::boolean,true)
     or v->>'reason'<>'rollout_unavailable' then
    raise exception 'Non-canary escaped Plans server gate: %',v;
  end if;

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  if coalesce((v->>'visible')::boolean,true)
     or v->>'reason'<>'rollout_unavailable' then
    raise exception 'Non-canary escaped subject-selection server gate: %',v;
  end if;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,false);
  if coalesce((v->>'ok')::boolean,true)
     or v->>'reason'<>'rollout_unavailable' then
    raise exception 'Non-canary mutated shadow subject slots: %',v;
  end if;
end;
$noncanary_direct_calls$;


-- The Free canary sees the correct plan, may save one future subject choice,
-- cannot exceed the future Free limit, and still leaves legacy access untouched.
do $free_canary$
declare
  v jsonb;
  uid uuid:=(select user_id from canary_activation_people where person_key='free');
  before_count bigint;
  after_count bigint;
  before_digest text;
  after_digest text;
begin
  perform set_config('request.jwt.claim.sub',uid::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_plan_ui_bootstrap_v1();
  if coalesce((v->>'visible')::boolean,false) is not true
     or v->>'current_plan_code'<>'free'
     or coalesce((v->>'checkout_enabled')::boolean,true) then
    raise exception 'Free canary Plans bootstrap mismatch: %',v;
  end if;

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  if coalesce((v->>'visible')::boolean,false) is not true
     or v->>'plan_code'<>'free'
     or (v->>'study_subject_limit')::integer<>1
     or (v->>'competitive_subject_limit')::integer<>1
     or coalesce((v->>'access_unchanged')::boolean,false) is not true then
    raise exception 'Free canary subject bootstrap mismatch: %',v;
  end if;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  if coalesce((v->>'ok')::boolean,false) is not true
     or coalesce((v->>'access_unchanged')::boolean,false) is not true then
    raise exception 'Free canary first shadow selection failed: %',v;
  end if;

  v:=public.set_iclub_my_subject_slot_v1('biology',true,false);
  if coalesce((v->>'ok')::boolean,true)
     or v->>'reason'<>'study_subject_limit_reached' then
    raise exception 'Free canary exceeded one study subject: %',v;
  end if;

  select row_count,digest into before_count,before_digest
  from canary_activation_legacy_digest;

  select
    count(*)::bigint,
    md5(coalesce(string_agg(
      user_id::text||':'||subject_id::text||':'||mode||':'||is_pinned::text,
      ',' order by user_id::text,subject_id
    ),''))
  into after_count,after_digest
  from public.user_subjects;

  if before_count<>after_count
     or before_digest is distinct from after_digest then
    raise exception 'Canary activation/selection mutated public.user_subjects';
  end if;
end;
$free_canary$;


-- Operational rollback turns the two learner-facing canary surfaces OFF and
-- disables canary membership without deleting the private shadow choice.
do $deactivate$
declare
  v jsonb;
  slots_before integer;
begin
  select count(*) into slots_before
  from private.iclub_subject_slot_selections;

  v:=public.deactivate_iclub_plans_subject_canary_service_v1('ci-rollback');

  if coalesce((v->>'ok')::boolean,false) is not true
     or coalesce((v->>'plans_ui_enabled')::boolean,true)
     or v->>'plans_rollout_mode'<>'off'
     or coalesce((v->>'subject_selection_ui_enabled')::boolean,true)
     or v->>'subject_limits_mode'<>'off' then
    raise exception 'Canary operational rollback failed: %',v;
  end if;

  if (select count(*) from private.iclub_product_canary_users where enabled)<>0
     or (select count(*) from private.iclub_subject_slot_selections)<>slots_before
     or slots_before<>1 then
    raise exception 'Rollback deleted shadow evidence or left enabled canaries';
  end if;
end;
$deactivate$;


-- A second activation may safely restore the same three canaries while retaining
-- the prior private shadow choice. This proves rollback is reversible.
do $reactivate$
declare
  v jsonb;
  fp text;
  free_uid uuid:=(select user_id from canary_activation_people where person_key='free');
  plus_uid uuid:=(select user_id from canary_activation_people where person_key='plus');
  pro_uid uuid:=(select user_id from canary_activation_people where person_key='pro');
begin
  fp:=public.get_iclub_product_canary_activation_snapshot_service_v1()
    ->>'eligible_beta_fingerprint';

  v:=public.activate_iclub_plans_subject_canary_service_v1(
    free_uid,plus_uid,pro_uid,fp,'ci-reactivation'
  );

  if coalesce((v->>'ok')::boolean,false) is not true then
    raise exception 'Reactivation after safe rollback failed: %',v;
  end if;

  v:=public.deactivate_iclub_plans_subject_canary_service_v1('ci-second-rollback');
  if coalesce((v->>'ok')::boolean,false) is not true then
    raise exception 'Second safe rollback failed: %',v;
  end if;
end;
$reactivate$;


-- A real subscription row must block this test-plan-only phase.
do $paid_entitlement_guard$
declare
  v jsonb;
  fp text;
  free_uid uuid:=(select user_id from canary_activation_people where person_key='free');
  plus_uid uuid:=(select user_id from canary_activation_people where person_key='plus');
  pro_uid uuid:=(select user_id from canary_activation_people where person_key='pro');
  normal_uid uuid:=(select user_id from canary_activation_people where person_key='normal');
begin
  insert into private.iclub_subscription_entitlements(
    user_id,plan_code,entitlement_status,entitlement_source
  ) values (
    normal_uid,'free','active','ci-explicit-entitlement'
  );

  v:=public.get_iclub_product_canary_activation_snapshot_service_v1();
  if coalesce((v->>'safe_to_activate')::boolean,true)
     or (v->>'explicit_subscription_rows')::integer<>1 then
    raise exception 'Explicit subscription row did not close activation preflight: %',v;
  end if;

  fp:=v->>'eligible_beta_fingerprint';
  v:=public.activate_iclub_plans_subject_canary_service_v1(
    free_uid,plus_uid,pro_uid,fp,'ci-paid-row-guard'
  );

  if coalesce((v->>'ok')::boolean,true)
     or v->>'reason'<>'preflight_not_green' then
    raise exception 'Activation ignored explicit subscription row: %',v;
  end if;

  if (select plans_rollout_mode from private.iclub_global_ai_runtime_config where id=1)<>'off'
     or (select subject_limits_mode from private.iclub_commercial_access_config where id=1)<>'off'
     or (select count(*) from private.iclub_product_canary_users where enabled)<>0 then
    raise exception 'Rejected paid-row activation left partial state';
  end if;
end;
$paid_entitlement_guard$;


-- Browser roles must never acquire authority to activate/deactivate the cohort.
do $privileges$
begin
  if has_function_privilege(
       'authenticated',
       'public.get_iclub_product_canary_activation_snapshot_service_v1()',
       'EXECUTE'
     )
     or has_function_privilege(
       'authenticated',
       'public.activate_iclub_plans_subject_canary_service_v1(uuid,uuid,uuid,text,text)',
       'EXECUTE'
     )
     or has_function_privilege(
       'authenticated',
       'public.deactivate_iclub_plans_subject_canary_service_v1(text)',
       'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.activate_iclub_plans_subject_canary_service_v1(uuid,uuid,uuid,text,text)',
       'EXECUTE'
     ) then
    raise exception 'Browser role received canary activation authority';
  end if;
end;
$privileges$;

ROLLBACK;

\echo 'iClub product canary activation control v1 SQL matrix: GREEN'
