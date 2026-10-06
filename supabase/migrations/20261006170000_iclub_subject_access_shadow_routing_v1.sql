-- iClub commercial subject-access shadow routing v1.
-- Observes how future Free/Plus/Pro subject access would behave on real app routes
-- for the server-authorized canary cohort, without blocking any current learner path.
--
-- Safety:
-- - shadow only; no production access enforcement;
-- - no writes to public.user_subjects or learner evidence/history;
-- - no route can use this response as academic authority;
-- - historical result/recommendation routes remain future-readable;
-- - only minimal route metadata is stored, never learner answer/chat content.

begin;

alter table private.iclub_commercial_access_config
  add column if not exists subject_access_shadow_routing_enabled boolean not null default false;

create table if not exists private.iclub_subject_access_shadow_events (
  event_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  subject_key text not null,
  route_code text not null,
  access_class text not null
    check (access_class in ('study','competitive','history')),
  plan_code text not null,
  would_allow boolean not null,
  reason text not null,
  access_unchanged boolean not null default true,
  created_at timestamptz not null default now(),
  check (char_length(subject_key) between 2 and 80),
  check (char_length(route_code) between 2 and 80),
  check (char_length(reason) between 2 and 120)
);

create index if not exists iclub_subject_access_shadow_events_user_created_idx
  on private.iclub_subject_access_shadow_events(user_id,created_at desc);

create index if not exists iclub_subject_access_shadow_events_route_created_idx
  on private.iclub_subject_access_shadow_events(route_code,created_at desc);

alter table private.iclub_subject_access_shadow_events enable row level security;
revoke all on private.iclub_subject_access_shadow_events from public,anon,authenticated;
grant all on private.iclub_subject_access_shadow_events to service_role;

create or replace function public.record_iclub_my_subject_access_shadow_v1(
  p_subject_key text,
  p_route_code text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $shadow$
declare
  v_uid uuid:=auth.uid();
  v_cfg private.iclub_commercial_access_config%rowtype;
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_caps jsonb;
  v_slot private.iclub_subject_slot_selections%rowtype;
  v_subject record;
  v_route text:=trim(coalesce(p_route_code,''));
  v_subject_key text:=trim(coalesce(p_subject_key,''));
  v_access_class text;
  v_plan_code text;
  v_would_allow boolean:=false;
  v_reason text:='subject_not_selected';
begin
  if v_uid is null then
    return jsonb_build_object(
      'observed',false,
      'reason','auth_required',
      'access_unchanged',true
    );
  end if;

  if length(v_subject_key)<2 or length(v_route)<2 then
    return jsonb_build_object(
      'observed',false,
      'reason','invalid_request',
      'access_unchanged',true
    );
  end if;

  v_access_class:=case
    when v_route in (
      'catalog_subject_hub',
      'global_books',
      'subject_video',
      'subject_exam_prep',
      'subject_practice',
      'subject_books',
      'recommendation_books',
      'recommendation_practice',
      'recommendation_train',
      'recommendation_retry',
      'recommendation_repeat_drill',
      'tour_practice',
      'recommendation_to_subject'
    ) then 'study'
    when v_route in (
      'profile_competitive_subject_hub',
      'subject_tours'
    ) then 'competitive'
    when v_route in (
      'global_recommendations',
      'profile_recommendations',
      'subject_recommendations'
    ) then 'history'
    else null
  end;

  if v_access_class is null then
    return jsonb_build_object(
      'observed',false,
      'reason','route_not_allowed',
      'access_unchanged',true
    );
  end if;

  select * into v_cfg
  from private.iclub_commercial_access_config
  where id=1;

  if not found
     or not coalesce(v_cfg.subject_access_shadow_routing_enabled,false)
     or v_cfg.subject_limits_mode<>'shadow' then
    return jsonb_build_object(
      'observed',false,
      'reason','shadow_routing_disabled',
      'access_unchanged',true
    );
  end if;

  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if not found
     or not private.iclub_rollout_allows_user_v1(v_uid,v_runtime.plans_rollout_mode) then
    return jsonb_build_object(
      'observed',false,
      'reason','rollout_unavailable',
      'access_unchanged',true
    );
  end if;

  select s.subject_key,s.type,s.is_active
  into v_subject
  from public.subjects s
  where s.subject_key=v_subject_key
  limit 1;

  if not found or coalesce(v_subject.is_active,false) is not true then
    return jsonb_build_object(
      'observed',false,
      'reason','subject_unavailable',
      'access_unchanged',true
    );
  end if;

  v_caps:=public.get_iclub_subscription_capabilities_service_v1(v_uid);
  if coalesce((v_caps->>'resolved')::boolean,false) is not true then
    return jsonb_build_object(
      'observed',false,
      'reason',coalesce(v_caps->>'reason','subscription_unavailable'),
      'access_unchanged',true
    );
  end if;

  v_plan_code:=coalesce(v_caps->>'plan_code','free');

  select * into v_slot
  from private.iclub_subject_slot_selections x
  where x.user_id=v_uid
    and x.subject_key=v_subject_key;

  if v_access_class='history' then
    v_would_allow:=true;
    v_reason:='history_preserved';

  elsif v_access_class='competitive' then
    if v_subject.type<>'main' then
      v_would_allow:=false;
      v_reason:='competitive_requires_main_subject';
    elsif found and v_slot.competitive_selected then
      v_would_allow:=true;
      v_reason:='competitive_selected';
    else
      v_would_allow:=false;
      v_reason:='competitive_not_selected';
    end if;

  else
    if coalesce((v_caps->>'all_available_subjects')::boolean,false) then
      v_would_allow:=true;
      v_reason:='plan_all_subjects';
    elsif found and v_slot.study_selected then
      v_would_allow:=true;
      v_reason:='subject_selected';
    else
      v_would_allow:=false;
      v_reason:='subject_not_selected';
    end if;
  end if;

  insert into private.iclub_subject_access_shadow_events(
    user_id,subject_key,route_code,access_class,plan_code,
    would_allow,reason,access_unchanged
  ) values (
    v_uid,v_subject_key,v_route,v_access_class,v_plan_code,
    v_would_allow,v_reason,true
  );

  return jsonb_build_object(
    'observed',true,
    'subject_key',v_subject_key,
    'route_code',v_route,
    'access_class',v_access_class,
    'plan_code',v_plan_code,
    'would_allow',v_would_allow,
    'reason',v_reason,
    'access_unchanged',true
  );
end;
$shadow$;

revoke all on function public.record_iclub_my_subject_access_shadow_v1(text,text)
  from public,anon;
grant execute on function public.record_iclub_my_subject_access_shadow_v1(text,text)
  to authenticated,service_role;

commit;
