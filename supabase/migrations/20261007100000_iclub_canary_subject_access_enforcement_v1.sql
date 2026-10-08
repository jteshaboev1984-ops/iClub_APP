-- iClub canary subject-access enforcement preview v1.
-- Reversible beta-only access simulation for the three service-managed canary users.
--
-- This phase never deletes or rewrites legacy public.user_subjects or learner history.
-- When OFF (default), every learner keeps the existing production access behavior.
-- When ON, only canary users experience their tariff subject selection as an access gate.

begin;

alter table private.iclub_commercial_access_config
  add column if not exists canary_subject_access_enforced boolean not null default false;

create or replace function public.get_iclub_my_subject_access_v1(
  p_subject_key text,
  p_intent text default 'study'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $access$
declare
  v_uid uuid:=auth.uid();
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_subject record;
  v_slot private.iclub_subject_slot_selections%rowtype;
  v_selected_count integer:=0;
  v_plan text;
  v_all boolean:=false;
begin
  if v_uid is null then
    return jsonb_build_object(
      'allowed',false,
      'enforced',false,
      'reason','auth_required'
    );
  end if;

  if coalesce(length(trim(p_subject_key)),0)<2 then
    return jsonb_build_object(
      'allowed',false,
      'enforced',false,
      'reason','invalid_subject'
    );
  end if;

  if p_intent not in ('study','competitive','legacy_toggle') then
    return jsonb_build_object(
      'allowed',false,
      'enforced',false,
      'reason','invalid_intent'
    );
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found or not coalesce(v_cfg.canary_subject_access_enforced,false) then
    return jsonb_build_object(
      'allowed',true,
      'enforced',false,
      'reason','access_preview_disabled'
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  -- Canary subject enforcement is intentionally narrower than future public
  -- enforcement. It can never affect a non-canary learner.
  if not found
     or v_runtime.plans_rollout_mode<>'canary'
     or not private.iclub_is_product_canary_v1(v_uid) then
    return jsonb_build_object(
      'allowed',true,
      'enforced',false,
      'reason','not_canary'
    );
  end if;

  select s.subject_key,s.type,s.is_active
  into v_subject
  from public.subjects s
  where s.subject_key=trim(p_subject_key)
  limit 1;

  if not found or coalesce(v_subject.is_active,false) is not true then
    return jsonb_build_object(
      'allowed',false,
      'enforced',true,
      'reason','subject_unavailable'
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'allowed',false,
      'enforced',true,
      'reason',coalesce(v_caps->>'reason','subscription_unavailable')
    );
  end if;

  v_plan:=coalesce(v_caps->>'plan_code','free');
  v_all:=coalesce((v_caps->>'all_available_subjects')::boolean,false);

  if p_intent='legacy_toggle' then
    return jsonb_build_object(
      'allowed',false,
      'enforced',true,
      'reason','manage_in_plan_subjects',
      'plan_code',v_plan
    );
  end if;

  select * into v_slot
  from private.iclub_subject_slot_selections x
  where x.user_id=v_uid
    and x.subject_key=trim(p_subject_key);

  if p_intent='study' then
    if v_all then
      return jsonb_build_object(
        'allowed',true,
        'enforced',true,
        'reason','plan_all_subjects',
        'plan_code',v_plan
      );
    end if;

    if found and v_slot.study_selected then
      return jsonb_build_object(
        'allowed',true,
        'enforced',true,
        'reason','subject_selected',
        'plan_code',v_plan
      );
    end if;

    select count(*) into v_selected_count
    from private.iclub_subject_slot_selections x
    where x.user_id=v_uid
      and x.study_selected;

    return jsonb_build_object(
      'allowed',false,
      'enforced',true,
      'reason',case
        when v_selected_count=0 then 'subject_selection_required'
        else 'subject_not_in_plan'
      end,
      'plan_code',v_plan
    );
  end if;

  if v_subject.type<>'main' then
    return jsonb_build_object(
      'allowed',false,
      'enforced',true,
      'reason','competitive_requires_main_subject',
      'plan_code',v_plan
    );
  end if;

  if found and v_slot.competitive_selected then
    return jsonb_build_object(
      'allowed',true,
      'enforced',true,
      'reason','competitive_selected',
      'plan_code',v_plan
    );
  end if;

  return jsonb_build_object(
    'allowed',false,
    'enforced',true,
    'reason','competitive_not_in_plan',
    'plan_code',v_plan
  );
end;
$access$;

revoke all on function public.get_iclub_my_subject_access_v1(text,text)
  from public,anon;
grant execute on function public.get_iclub_my_subject_access_v1(text,text)
  to authenticated,service_role;

commit;
