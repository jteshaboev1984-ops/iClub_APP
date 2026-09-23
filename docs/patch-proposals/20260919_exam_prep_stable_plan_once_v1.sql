-- REVIEW-ONLY CONTRACT, 19 Sep 2026. NEVER AUTO-APPLY.
-- Not a production migration. These new RPCs are NOT wired into the app.
-- The legacy generator/authorizer/starter remain callable; all three entry points
-- need a separately audited cutover before any release. See issues #113 and #122.
-- Retain every existing plan, response, evidence event and legacy table.

create or replace function public.ensure_exam_prep_stable_weekly_plan_safe_v1(
  p_component_code text
) returns jsonb language plpgsql security definer set search_path = '' as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_resume jsonb;
  v_generated jsonb;
  v_current jsonb;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  v_week := private.exam_prep_effective_active_week_v1(v_uid);
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  -- One transaction-level lock shared by all NEW plan and goal/session RPCs.
  perform pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||p_component_code,0));
  select * into v_plan from private.exam_prep_weekly_plans
   where user_id=v_uid and program_version_id=v_program
     and component_code=p_component_code and active_week_no=v_week and status='active'
   for update;
  if v_plan.id is not null then
    v_current:=public.get_exam_prep_weekly_plan_safe_v2(p_component_code);
    if v_current->>'plan_id' is distinct from v_plan.id::text then
      raise exception 'exam_prep_plan_projection_mismatch';
    end if;
    return v_current || jsonb_build_object('contract_version','stable_weekly_plan_v1',
      'status','existing','created',false);
  end if;

  -- Finish a session from the previous plan/week before generating new work.
  v_resume:=public.get_exam_prep_active_plan_session_safe_v1(p_component_code);
  if v_resume->>'status' in ('resume','ready_to_finalize','multiple_active') then
    return jsonb_build_object('contract_version','stable_weekly_plan_v1',
      'status','resume_first','created',false,'recovery',v_resume);
  end if;

  -- The existing Core generator is the sole academic planning authority.
  -- Call once only when no plan exists for the effective week.
  v_generated:=public.generate_exam_prep_weekly_plan_safe_v3(p_component_code);
  v_current:=public.get_exam_prep_weekly_plan_safe_v2(p_component_code);
  if v_generated->>'plan_id' is null or
     v_current->>'plan_id' is distinct from v_generated->>'plan_id' then
    raise exception 'exam_prep_generated_plan_not_current';
  end if;
  return v_current || jsonb_build_object('contract_version','stable_weekly_plan_v1',
    'status','created','created',true);
end;
$function$;
revoke all on function public.ensure_exam_prep_stable_weekly_plan_safe_v1(text) from public,anon;
grant execute on function public.ensure_exam_prep_stable_weekly_plan_safe_v1(text) to authenticated;

create or replace function public.authorize_exam_prep_goal_once_safe_v1(
  p_component_code text, p_goal_id uuid, p_plan_id uuid
) returns jsonb language plpgsql security definer set search_path = '' as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_decision jsonb;
  v_authorized jsonb;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_session private.exam_prep_sessions%rowtype;
  v_priority integer;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_goal_id is null or p_plan_id is null then
    return jsonb_build_object('status','stale','reason','missing_identity');
  end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  perform pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||p_component_code,0));
  -- Serialize against old-generator UPDATE of this plan during a goal click.
  select * into v_plan from private.exam_prep_weekly_plans
  where id=p_plan_id and user_id=v_uid and program_version_id=v_program
    and component_code=p_component_code and active_week_no=v_week and status='active'
  for update;
  if v_plan.id is null then
    return jsonb_build_object('status','stale','reason','plan_changed');
  end if;
  v_decision:=public.get_exam_prep_goal_action_state_safe_v1(p_component_code,p_goal_id,p_plan_id);
  if v_decision->>'status' <> 'ready' then
    return v_decision;
  end if;
  v_priority:=(v_decision->>'priority_order')::integer;
  if v_priority is null or v_priority not between 1 and 3 then
    raise exception 'exam_prep_goal_priority_invalid';
  end if;

  -- Core rechecks correction/retest/runway/assessment and its own idempotent lock.
  v_authorized:=public.authorize_exam_prep_plan_item_safe_v1(p_plan_id,v_priority);
  if v_authorized->>'authorization_id' is null then
    raise exception 'exam_prep_plan_authorization_missing';
  end if;
  select * into v_auth from private.exam_prep_session_authorizations
  where id=(v_authorized->>'authorization_id')::uuid and user_id=v_uid
    and component_code=p_component_code and plan_id=v_plan.id
    and plan_priority_order=v_priority for update;
  if v_auth.id is null then raise exception 'exam_prep_authorization_binding_changed'; end if;
  if v_auth.status='consumed' then
    select * into v_session from private.exam_prep_sessions
     where id=v_auth.consumed_session_id and authorization_id=v_auth.id
       and user_id=v_uid and component_code=p_component_code;
    if v_session.id is not null and v_session.status='active' then
      return jsonb_build_object('status','resume','session_id',v_session.id,
        'component_code',p_component_code,'goal_id',p_goal_id,'plan_id',p_plan_id);
    end if;
    return jsonb_build_object('status','attempt_already_saved','reason','consumed_authorization');
  end if;
  if v_auth.status<>'issued' then
    return jsonb_build_object('status','stale','reason','authorization_unavailable');
  end if;
  return jsonb_build_object('status','authorized','authorization_id',v_auth.id,
    'component_code',p_component_code,'goal_id',p_goal_id,'plan_id',p_plan_id,
    'priority_order',v_priority);
end;
$function$;
revoke all on function public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid) from public,anon;
grant execute on function public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid) to authenticated;

create or replace function public.start_exam_prep_plan_session_once_safe_v1(
  p_authorization_id uuid, p_idempotency_key text
) returns jsonb language plpgsql security definer set search_path = '' as $function$
declare
  v_uid uuid;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_session private.exam_prep_sessions%rowtype;
  v_resume jsonb;
  v_started jsonb;
  v_program bigint;
  v_week smallint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_authorization_id is null then raise exception 'exam_prep_authorization_required'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then
    raise exception 'exam_prep_bad_idempotency_key';
  end if;
  select * into v_auth from private.exam_prep_session_authorizations
  where id=p_authorization_id and user_id=v_uid;
  if v_auth.id is null or v_auth.plan_id is null or v_auth.academic_credit is not true
     or v_auth.component_code not in ('P1','P5') then
    raise exception 'exam_prep_plan_authorization_not_found' using errcode='P0002';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||v_auth.component_code,0));
  -- Lock plan BEFORE auth, matching goal authorizer order to avoid deadlocks.
  select * into v_plan from private.exam_prep_weekly_plans
   where id=v_auth.plan_id and user_id=v_uid and component_code=v_auth.component_code
   for update;
  select * into v_auth from private.exam_prep_session_authorizations
   where id=p_authorization_id and user_id=v_uid for update;
  if v_plan.id is null or v_auth.id is null or v_auth.plan_id is distinct from v_plan.id
     or v_auth.academic_credit is not true then
    raise exception 'exam_prep_authorization_binding_changed';
  end if;
  if v_auth.status='consumed' then
    select * into v_session from private.exam_prep_sessions
    where id=v_auth.consumed_session_id and authorization_id=v_auth.id
      and user_id=v_uid and component_code=v_auth.component_code;
    if v_session.id is null then
      return jsonb_build_object('status','reconciliation_required');
    end if;
    if v_session.status='active' then
      return jsonb_build_object('status','resume','session_id',v_session.id,
        'component_code',v_session.component_code);
    end if;
    -- Crucial: never return a finalized session ID or re-open it on replay.
    return jsonb_build_object('status','attempt_already_saved');
  end if;
  if v_auth.status<>'issued' then
    return jsonb_build_object('status','authorization_unavailable');
  end if;
  select program_version_id into v_program from private.exam_prep_exam_profiles where user_id=v_uid;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;
  if v_plan.program_version_id<>v_program or v_plan.active_week_no<>v_week
     or v_plan.status<>'active' or v_auth.plan_priority_order is null
     or not exists (select 1 from private.exam_prep_weekly_plan_items i
                    where i.plan_id=v_plan.id and i.priority_order=v_auth.plan_priority_order
                      and i.status='pending') then
    return jsonb_build_object('status','stale','reason','plan_changed_before_start');
  end if;
  if v_auth.valid_until is not null and v_auth.valid_until<=now() then
    return jsonb_build_object('status','authorization_expired');
  end if;
  -- The frozen key must never become a way to resume or switch a different authorization.
  select * into v_session from private.exam_prep_sessions
    where user_id=v_uid and client_idempotency_key=p_idempotency_key;
  if v_session.id is not null then
    if v_session.authorization_id<>v_auth.id then raise exception 'exam_prep_idempotency_conflict'; end if;
    if v_session.status='active' then
      return jsonb_build_object('status','resume','session_id',v_session.id,
        'component_code',v_session.component_code);
    end if;
    return jsonb_build_object('status','attempt_already_saved');
  end if;
  -- A previous plan's active session wins over starting any new session.
  v_resume:=public.get_exam_prep_active_plan_session_safe_v1(v_auth.component_code);
  if v_resume->>'status' in ('resume','ready_to_finalize') then
    return jsonb_build_object('status','resume_existing_session_first',
      'session_id',v_resume->>'session_id');
  elsif v_resume->>'status'='multiple_active' then
    return jsonb_build_object('status','multiple_active');
  end if;
  if v_auth.purpose='learning' and exists(
     select 1 from private.exam_prep_sessions s
     where s.user_id=v_uid and s.program_version_id=v_program
       and s.component_code=v_auth.component_code
       and s.assessment_id=v_auth.assessment_id and s.status='finalized') then
    return jsonb_build_object('status','content_exhausted','reason','previously_seen_learning_pack');
  end if;
  v_started:=public.start_exam_prep_session_safe_v1(p_authorization_id,p_idempotency_key);
  if v_started->>'status'<>'active' or v_started->>'session_id' is null then
    raise exception 'exam_prep_session_start_unexpected_state';
  end if;
  return jsonb_build_object('status','started','session_id',v_started->>'session_id',
    'component_code',v_auth.component_code);
end;
$function$;
revoke all on function public.start_exam_prep_plan_session_once_safe_v1(uuid,text) from public,anon;
grant execute on function public.start_exam_prep_plan_session_once_safe_v1(uuid,text) to authenticated;
