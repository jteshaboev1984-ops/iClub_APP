-- WEEKLY FLOW RELEASE PACKAGE v1
-- Exact source package for the reviewed weekly-flow release.
-- The temporary OFF state exists only inside this transaction. Other sessions
-- keep seeing the previously committed production feature state until COMMIT.
-- No learner enrollment is inserted here.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='180s';

CREATE TEMP TABLE _weekly_feature_before ON COMMIT DROP AS
SELECT program_key,rollout_state,core_enabled,ai_enabled,mentor_enabled,kill_switch,updated_at
FROM private.exam_prep_feature_config
WHERE program_key='math_as_p1_p5';

DO $release_preflight$
BEGIN
  IF (SELECT count(*) FROM _weekly_feature_before)<>1 THEN
    RAISE EXCEPTION 'weekly release: feature config missing or duplicated';
  END IF;
  IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NOT NULL
     OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NOT NULL
     OR to_regclass('private.exam_prep_weekly_review_rpc_backup_v1') IS NOT NULL
  THEN
    RAISE EXCEPTION 'weekly release: candidate already installed or partial install detected';
  END IF;
END
$release_preflight$;

UPDATE private.exam_prep_feature_config
SET rollout_state='off',core_enabled=false,ai_enabled=false,mentor_enabled=false,kill_switch=true
WHERE program_key='math_as_p1_p5';


-- ===== SOURCE docs/patch-proposals/20260918_exam_prep_resume_lookup_v1.sql | blob 7eb52c0a7fe63c8f6eeaaee8f4a9f2216a1f94ad =====
-- REVIEW PROPOSAL ONLY. Not in supabase/migrations; do not apply to production.
-- Validated against read-only schema inventory on 2026-09-18.
-- This is a discovery endpoint, NOT a session starter or academic state mutation.
-- A separate isolated DB test and owner sign-off are mandatory before promotion.

create or replace function public.get_exam_prep_active_plan_session_safe_v1(
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_session_id uuid;
  v_session private.exam_prep_sessions%rowtype;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_count integer;
  v_answered integer;
  v_first_unanswered smallint;
  v_plan_status text;
  v_plan_week smallint;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1', 'P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select p.program_version_id into v_program
  from private.exam_prep_exam_profiles p
  where p.user_id = v_uid;
  if v_program is null then
    raise exception 'exam_prep_profile_required';
  end if;

  -- Search ALL plan versions and weeks; the former plan may be superseded.
  -- Do not reveal diagnostic, timed, full-paper, other-user or other-program sessions.
  -- PostgreSQL does not provide min(uuid): aggregate the text representation and cast
  -- back ONLY to identify the unique row after checking count=1 below.
  select count(*)::integer, min(s.id::text)::uuid
    into v_count, v_session_id
  from private.exam_prep_sessions s
  join private.exam_prep_session_authorizations a
    on a.id = s.authorization_id
   and a.user_id = v_uid
   and a.component_code = p_component_code
   and a.academic_credit is true
   and a.plan_id is not null
   and a.consumed_session_id = s.id
  where s.user_id = v_uid
    and s.component_code = p_component_code
    and s.program_version_id = v_program
    and s.status = 'active'
    and s.session_type in ('learning', 'mixed', 'retest');

  if v_count = 0 then
    return jsonb_build_object(
      'contract_version', 'active_plan_session_v1',
      'component_code', p_component_code,
      'status', 'none',
      'active_session_count', 0
    );
  end if;
  if v_count <> 1 then
    -- Do not silently pick one of several active sessions or start a replacement.
    return jsonb_build_object(
      'contract_version', 'active_plan_session_v1',
      'component_code', p_component_code,
      'status', 'multiple_active',
      'active_session_count', v_count
    );
  end if;

  select * into strict v_session
  from private.exam_prep_sessions s
  where s.id = v_session_id and s.user_id = v_uid
    and s.component_code = p_component_code
    and s.program_version_id = v_program and s.status = 'active';

  select * into strict v_auth
  from private.exam_prep_session_authorizations a
  where a.id = v_session.authorization_id and a.user_id = v_uid
    and a.component_code = p_component_code and a.academic_credit is true
    and a.status = 'consumed' and a.consumed_session_id = v_session.id
    and a.plan_id is not null;

  select count(r.id)::integer,
         min(si.item_order) filter (where r.id is null)
    into v_answered, v_first_unanswered
  from private.exam_prep_session_items si
  left join private.exam_prep_responses r
    on r.session_id = si.session_id
   and r.item_order = si.item_order
   and r.user_id = v_uid
  where si.session_id = v_session.id;

  select p.status, p.active_week_no into v_plan_status, v_plan_week
  from private.exam_prep_weekly_plans p
  where p.id = v_auth.plan_id and p.user_id = v_uid
    and p.program_version_id = v_program
    and p.component_code = p_component_code;

  -- No answer text, question IDs, protected content, scores or peer data in discovery.
  -- Rehydrate questions only through existing authenticated get_session RPC.
  return jsonb_build_object(
    'contract_version', 'active_plan_session_v1',
    'component_code', p_component_code,
    'status', case when v_first_unanswered is null
                   then 'ready_to_finalize' else 'resume' end,
    'active_session_count', 1,
    'session_id', v_session.id,
    'session_type', v_session.session_type,
    'answered_items', v_answered,
    'total_items', v_session.total_items,
    'first_unanswered_item_order', v_first_unanswered,
    'source_plan_id', v_auth.plan_id,
    'source_plan_priority_order', v_auth.plan_priority_order,
    'source_plan_status', coalesce(v_plan_status, 'unavailable'),
    'source_plan_week', v_plan_week,
    'resume_independent_of_current_plan', true
  );
end;
$function$;

revoke all on function public.get_exam_prep_active_plan_session_safe_v1(text) from public;
revoke all on function public.get_exam_prep_active_plan_session_safe_v1(text) from anon;
grant execute on function public.get_exam_prep_active_plan_session_safe_v1(text) to authenticated;


-- ===== SOURCE docs/patch-proposals/20260918_exam_prep_goal_eligibility_v1.sql | blob ce0f55f72870d280e9889fb8e73337b76badbe15 =====
-- REVIEW PROPOSAL ONLY. Not in supabase/migrations; never run on real learners.
-- Only the existing Core authorization/start RPCs can create academic state.
-- Requires isolated PostgreSQL fixtures, security review and owner approval.

create or replace function public.get_exam_prep_goal_action_state_safe_v1(
  p_component_code text,
  p_goal_id uuid,
  p_plan_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_goal private.exam_prep_weekly_goal_snapshots%rowtype;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_item private.exam_prep_weekly_plan_items%rowtype;
  v_match_count integer;
  v_priority smallint;
  v_twin_count integer;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_session private.exam_prep_sessions%rowtype;
  v_assessment bigint;
  v_now timestamptz;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;
  if p_goal_id is null or p_plan_id is null then
    return jsonb_build_object('status','stale','reason','missing_identity');
  end if;
  select p.program_version_id, private.exam_prep_effective_active_week_v1(v_uid)
    into v_program,v_week
  from private.exam_prep_exam_profiles p where p.user_id=v_uid;
  if v_program is null or v_week is null then
    raise exception 'exam_prep_profile_required';
  end if;

  select * into v_goal from private.exam_prep_weekly_goal_snapshots g
  where g.id=p_goal_id and g.user_id=v_uid and g.program_version_id=v_program
    and g.component_code=p_component_code and g.active_week_no=v_week;
  select * into v_plan from private.exam_prep_weekly_plans p
  where p.id=p_plan_id and p.user_id=v_uid and p.program_version_id=v_program
    and p.component_code=p_component_code and p.active_week_no=v_week
    and p.status='active';
  if v_goal.id is null or v_plan.id is null then
    return jsonb_build_object('status','stale','reason','goal_or_plan_changed');
  end if;

  -- Match immutable goal identity to the ACTIVE plan; frozen order is NOT a route.
  select count(*)::integer,min(i.priority_order)
    into v_match_count,v_priority
  from private.exam_prep_weekly_plan_items i
  where i.plan_id=v_plan.id and i.status='pending'
    and i.skill_code is not distinct from v_goal.skill_code
    and (
      (v_goal.correction_case_id is not null
       and i.correction_case_id=v_goal.correction_case_id
       and ((i.item_type=v_goal.item_type and i.action_code=v_goal.action_code)
         or (v_goal.item_type='correction' and i.item_type='retest'
             and i.action_code='COMPLETE_DELAYED_RETEST')))
      or
      (v_goal.correction_case_id is null and i.correction_case_id is null
       and i.item_type=v_goal.item_type and i.action_code=v_goal.action_code
       and (v_goal.item_type<>'mixed_transfer' or
            (v_goal.assessment_id is not null and
             i.action_payload->>'assessment_id'=v_goal.assessment_id::text)))
    );
  if v_match_count <> 1 then
    return jsonb_build_object('status','stale',
      'reason',case when v_match_count>1 then 'ambiguous_binding' else 'binding_missing' end);
  end if;
  select * into strict v_item from private.exam_prep_weekly_plan_items
  where plan_id=v_plan.id and priority_order=v_priority and status='pending';

  -- Same skill appears twice with potentially different actions: do not guess.
  select count(*)::integer into v_twin_count
  from private.exam_prep_weekly_plan_items i
  where i.plan_id=v_plan.id and i.status='pending'
    and i.skill_code is not distinct from v_item.skill_code
    and (i.item_type=v_item.item_type or
         (v_goal.item_type='correction' and i.item_type in ('correction','retest')));
  if v_twin_count <> 1 then
    return jsonb_build_object('status','stale','reason','duplicate_skill_binding');
  end if;

  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  if v_item.item_type='retest' then
    if v_item.due_at is null or v_item.due_at>v_now then
      return jsonb_build_object('status','waiting','reason','retest_not_due',
        'component_code',p_component_code,'goal_id',v_goal.id,
        'due_at',v_item.due_at);
    end if;
    if v_item.correction_case_id is not null and not exists(
      select 1 from private.exam_prep_correction_cases c
      join private.exam_prep_retest_events r
        on r.correction_case_id=c.id and r.user_id=v_uid
        and r.component_code=p_component_code and r.status in ('scheduled','authorized')
      where c.id=v_item.correction_case_id and c.user_id=v_uid
        and c.component_code=p_component_code and c.status='retest_due'
        and r.due_not_before<=v_now
    ) then
      return jsonb_build_object('status','waiting','reason','retest_not_confirmed');
    end if;
  end if;

  -- Any previously active plan session takes precedence over a NEW start,
  -- including a session whose plan has been superseded or week rolled over.
  if exists (
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_session_authorizations a on a.id=s.authorization_id
      and a.user_id=v_uid and a.component_code=p_component_code and a.plan_id is not null
      and a.academic_credit is true
    where s.user_id=v_uid and s.program_version_id=v_program
      and s.component_code=p_component_code and s.status='active'
      and s.session_type in ('learning','mixed','retest')
      and not (a.plan_id=v_plan.id and a.plan_priority_order=v_item.priority_order)
  ) then
    return jsonb_build_object('status','waiting','reason','resume_existing_session_first');
  end if;

  select * into v_auth from private.exam_prep_session_authorizations a
  where a.user_id=v_uid and a.component_code=p_component_code
    and a.plan_id=v_plan.id and a.plan_priority_order=v_item.priority_order
    and a.status in ('issued','consumed')
  order by a.issued_at desc limit 1;
  if v_auth.id is not null and v_auth.status='consumed' then
    select * into v_session from private.exam_prep_sessions s
    where s.id=v_auth.consumed_session_id and s.authorization_id=v_auth.id
      and s.user_id=v_uid and s.component_code=p_component_code;
    if v_session.id is null then
      return jsonb_build_object('status','waiting','reason','session_reconciliation_required');
    end if;
    if v_session.status='active' then
      return jsonb_build_object('status','resume','component_code',p_component_code,
        'plan_id',v_plan.id,'goal_id',v_goal.id,
        'priority_order',v_item.priority_order,'skill_code',v_item.skill_code,
        'item_type',v_item.item_type,'session_id',v_session.id);
    end if;
    return jsonb_build_object('status','waiting','reason','attempt_already_saved');
  end if;

  -- The current Core learning/correction authorizer selects the FIRST published
  -- assessment. Until the authorizer gains a governed fresh-pack policy,
  -- never advertise an already-exposed assessment as a new independent attempt.
  if v_item.item_type in ('correction','learning') then
    select a.id into v_assessment from private.exam_prep_assessments a
    where a.component_code=p_component_code and a.assessment_type='learning'
      and a.status='published'
      and exists(select 1 from private.exam_prep_assessment_items ai
                 where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)
      and not exists(select 1 from private.exam_prep_assessment_items ai
                     where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)
    order by a.id limit 1;
    if v_assessment is null then
      return jsonb_build_object('status','waiting','reason','approved_content_unavailable');
    end if;
    if exists(select 1 from private.exam_prep_sessions s
              where s.user_id=v_uid and s.program_version_id=v_program
                and s.component_code=p_component_code and s.assessment_id=v_assessment
                and s.status='finalized') then
      return jsonb_build_object('status','content_exhausted',
        'reason','previously_seen_learning_pack');
    end if;
  end if;

  -- This is UI eligibility only. The Core authorize RPC rechecks all access,
  -- due date, correction state, reserves and current plan inside its transaction.
  return jsonb_build_object('status','ready',
    'component_code',p_component_code,'plan_id',v_plan.id,
    'goal_id',v_goal.id,'priority_order',v_item.priority_order,
    'skill_code',v_item.skill_code,'item_type',v_item.item_type);
end;
$function$;

revoke all on function public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid) from public;
revoke all on function public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid) from anon;
grant execute on function public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid) to authenticated;


-- ===== SOURCE docs/patch-proposals/20260919_exam_prep_stable_plan_once_v1.sql | blob f14a1d78baad2527ce6a14e4e87c301a7aba1bdf =====
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


-- ===== SOURCE docs/patch-proposals/20260920_weekly_flow_preinstall_rpc_backup_v1.sql | blob cc791cf976374c88707da236f4e3fa067f8669e5 =====
-- REVIEW-ONLY proposal. Never run on live production without separate explicit approval.
-- Must run AFTER three draft prerequisites, BEFORE atomic compatibility SQL.
-- Captures all eight legacy public interfaces + three already proposed safe ones.
BEGIN;
DO $gate$
BEGIN
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NOT NULL
    OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NOT NULL
    OR to_regprocedure('private.exam_prep_legacy_generate_v1_internal_v1(text,text)') IS NOT NULL
    OR to_regprocedure('private.exam_prep_legacy_generate_v2_internal_v1(text)') IS NOT NULL THEN
  RAISE EXCEPTION 'weekly_backup_not_pristine';
 END IF;
END;$gate$;
CREATE TABLE private.exam_prep_weekly_flow_rpc_backup_v1 (
 signature text PRIMARY KEY,
 function_oid oid NOT NULL UNIQUE,
 original_definition text NOT NULL,
 original_md5 text NOT NULL,
 original_owner oid NOT NULL,
 original_acl aclitem[],
 original_security boolean NOT NULL,
 original_volatility char NOT NULL,
 installed_md5 text,
 captured_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.exam_prep_weekly_flow_rpc_backup_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_weekly_flow_rpc_backup_v1 FROM PUBLIC,anon,authenticated,service_role;
INSERT INTO private.exam_prep_weekly_flow_rpc_backup_v1
(signature,function_oid,original_definition,original_md5,original_owner,
 original_acl,original_security,original_volatility)
SELECT required.signature,p.oid,pg_get_functiondef(p.oid),md5(pg_get_functiondef(p.oid)),
 p.proowner,p.proacl,p.prosecdef,p.provolatile
FROM (VALUES
 ('public.generate_exam_prep_weekly_plan_safe_v1(text,text)'),
 ('public.generate_exam_prep_weekly_plan_safe_v2(text)'),
 ('public.generate_exam_prep_weekly_plan_safe_v3(text)'),
 ('public.authorize_exam_prep_correction_safe_v1(uuid)'),
 ('public.authorize_exam_prep_mixed_safe_v1(text)'),
 ('public.authorize_exam_prep_retest_safe_v1(uuid)'),
 ('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)'),
 ('public.start_exam_prep_session_safe_v1(uuid,text)'),
 ('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'),
 ('public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)'),
 ('public.start_exam_prep_plan_session_once_safe_v1(uuid,text)')
) AS required(signature) JOIN pg_proc p ON p.oid=to_regprocedure(required.signature);
DO $verify$
DECLARE v_count integer; v_drift integer; v_changed text;
BEGIN
 SELECT count(*) INTO v_count FROM private.exam_prep_weekly_flow_rpc_backup_v1;
 IF v_count<>11 THEN RAISE EXCEPTION 'weekly_backup_incomplete_%',v_count; END IF;
 SELECT string_agg(x.signature||': actual='||coalesce(b.original_md5,'MISSING')||' expected='||x.expected_md5,'; ' ORDER BY x.signature)
 INTO v_changed FROM (VALUES
 ('public.generate_exam_prep_weekly_plan_safe_v1(text,text)','58247a59c0967848d21c5ab93cc9d647'),
 ('public.generate_exam_prep_weekly_plan_safe_v2(text)','414916cc437d0d47a34916d15d0a1f05'),
 ('public.generate_exam_prep_weekly_plan_safe_v3(text)','43113f759097c94e4938fb46daa73145'),
 ('public.authorize_exam_prep_correction_safe_v1(uuid)','6ec9de1e0ee9ae4b9b41e80b5f61c2cf'),
 ('public.authorize_exam_prep_mixed_safe_v1(text)','848a4e2ea017ae97a4adfd7e6df907f6'),
 ('public.authorize_exam_prep_retest_safe_v1(uuid)','7e0f81e085354f969ded2eb9fbfa136d'),
 ('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)','d311a67f74c0a1195339947e237f83b1'),
 ('public.start_exam_prep_session_safe_v1(uuid,text)','51b06344e1c4c34d7d9a1d9eae354e06')
 ) x(signature,expected_md5)
 LEFT JOIN private.exam_prep_weekly_flow_rpc_backup_v1 b ON b.signature=x.signature
 WHERE b.original_md5 IS DISTINCT FROM x.expected_md5;
 IF v_changed IS NOT NULL THEN
  RAISE EXCEPTION 'weekly_backup_live_legacy_definition_drift: %',v_changed;
 END IF;
 SELECT count(*) INTO v_drift FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 JOIN pg_proc p ON p.oid=b.function_oid
 WHERE p.proowner<>'postgres'::regrole::oid OR NOT p.prosecdef OR p.provolatile<>'v'
   OR has_function_privilege('anon',p.oid,'EXECUTE')
   OR NOT has_function_privilege('authenticated',p.oid,'EXECUTE');
 IF v_drift<>0 THEN RAISE EXCEPTION 'weekly_backup_function_security_drift_%',v_drift; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_rpc_backup_v1 WHERE installed_md5 IS NOT NULL) THEN
  RAISE EXCEPTION 'weekly_backup_already_attested';
 END IF;
END;$verify$;


-- ===== SOURCE docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql | blob 9e5f87d8684335a37ab318aa25d7f15610130785 =====
-- REVIEW PROPOSAL ONLY. NOT A MIGRATION; DO NOT RUN ON PRODUCTION.
-- Test on disposable PG17 after three prerequisite SQL files AND the 11-RPC backup.
-- All eight original public entrypoints are retained for UNENROLLED learners.
-- Exactly one server-controlled cohort gate; JS flags are not authorization.
-- Enrollment starts empty. No legacy Practice/Tour or learner evidence writes.
BEGIN;
CREATE TABLE private.exam_prep_weekly_flow_enrollment_v1 (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
 enabled boolean NOT NULL DEFAULT false,
 approved_by uuid,
 approved_at timestamptz,
 CONSTRAINT exam_prep_weekly_flow_enrollment_approval_check
  CHECK (enabled IS NOT TRUE OR (approved_by IS NOT NULL AND approved_at IS NOT NULL))
);
ALTER TABLE private.exam_prep_weekly_flow_enrollment_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_weekly_flow_enrollment_v1 FROM PUBLIC,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION private.exam_prep_weekly_flow_enrolled_v1(p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $body$
 SELECT EXISTS (
  SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 e
  JOIN private.exam_prep_feature_config f ON f.program_key='math_as_p1_p5'
  WHERE e.user_id=p_user_id AND e.enabled IS TRUE
   AND f.rollout_state='controlled_beta' AND f.core_enabled IS TRUE
   AND f.kill_switch IS FALSE
 );
$body$;
REVOKE ALL ON FUNCTION private.exam_prep_weekly_flow_enrolled_v1(uuid) FROM PUBLIC,anon,authenticated,service_role;

-- Private originals must be created BEFORE altering any public entrypoint.
-- Copy every callable path, including v1 and direct correction/mixed/retest.
-- Rewrite only original internal-to-internal delegation, never Core math logic.
DO $copy$
DECLARE
 v_old text; v_new text; v_signature text; v_definition text;
 v_anchor text; v_call_old text; v_call_new text;
 v_names text[][] := ARRAY[
  ARRAY['generate_exam_prep_weekly_plan_safe_v1','exam_prep_legacy_generate_v1_internal_v1','text,text'],
  ARRAY['generate_exam_prep_weekly_plan_safe_v2','exam_prep_legacy_generate_v2_internal_v1','text'],
  ARRAY['generate_exam_prep_weekly_plan_safe_v3','exam_prep_legacy_generate_v3_internal_v1','text'],
  ARRAY['authorize_exam_prep_correction_safe_v1','exam_prep_legacy_correction_internal_v1','uuid'],
  ARRAY['authorize_exam_prep_mixed_safe_v1','exam_prep_legacy_mixed_internal_v1','text'],
  ARRAY['authorize_exam_prep_retest_safe_v1','exam_prep_legacy_retest_internal_v1','uuid'],
  ARRAY['authorize_exam_prep_plan_item_safe_v1','exam_prep_legacy_authorize_plan_internal_v1','uuid,integer'],
  ARRAY['start_exam_prep_session_safe_v1','exam_prep_legacy_start_session_internal_v1','uuid,text']
 ];
 v_i integer;
BEGIN
 FOR v_i IN 1..8 LOOP
  v_old:=v_names[v_i][1]; v_new:=v_names[v_i][2]; v_signature:=v_names[v_i][3];
  IF to_regprocedure('public.'||v_old||'('||v_signature||')') IS NULL THEN
   RAISE EXCEPTION 'RPC compatibility source missing: %',v_old;
  END IF;
  v_definition:=pg_get_functiondef(to_regprocedure('public.'||v_old||'('||v_signature||')'));
  v_anchor:='FUNCTION public.'||v_old||'(';
  IF (length(v_definition)-length(replace(v_definition,v_anchor,'')))<>length(v_anchor) THEN
   RAISE EXCEPTION 'RPC source header changed: %',v_old;
  END IF;
  v_definition:=replace(v_definition,v_anchor,'FUNCTION private.'||v_new||'(');
  IF v_i=3 THEN
   v_call_old:='public.generate_exam_prep_weekly_plan_safe_v2(p_component_code)';
   v_call_new:='private.exam_prep_legacy_generate_v2_internal_v1(p_component_code)';
   IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
    RAISE EXCEPTION 'Legacy v3 to v2 delegation drift';
   END IF;
   v_definition:=replace(v_definition,v_call_old,v_call_new);
  END IF;
  IF v_i=7 THEN
   v_call_old:='public.authorize_exam_prep_correction_safe_v1(';
   v_call_new:='private.exam_prep_legacy_correction_internal_v1(';
   IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
    RAISE EXCEPTION 'Core correction delegation drift';
   END IF;
   v_definition:=replace(v_definition,v_call_old,v_call_new);
   v_call_old:='public.authorize_exam_prep_retest_safe_v1(';
   v_call_new:='private.exam_prep_legacy_retest_internal_v1(';
   IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
    RAISE EXCEPTION 'Core retest delegation drift';
   END IF;
   v_definition:=replace(v_definition,v_call_old,v_call_new);
  END IF;
  EXECUTE v_definition;
 END LOOP;
END;$copy$;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v1_internal_v1(text,text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v2_internal_v1(text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v3_internal_v1(text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_correction_internal_v1(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_mixed_internal_v1(text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_retest_internal_v1(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_start_session_internal_v1(uuid,text) FROM PUBLIC,anon,authenticated,service_role;

-- Patch three DRAFT new functions to use inaccessible internal Core originals.
-- Fail on even one upstream body-anchor change, preventing silent recursion.
DO $guard$
DECLARE v_function text; v_def text; v_old text; v_new text; v_guard text;
BEGIN
 v_function:='public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)';
 v_def:=pg_get_functiondef(v_function::regprocedure);
 v_old:='v_generated:=public.generate_exam_prep_weekly_plan_safe_v3(p_component_code);';
 v_new:='v_generated:=private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Stable-plan generator anchor changed'; END IF;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='v_uid := private.exam_prep_require_core_access_v1();';
 v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Stable-plan owner gate anchor changed'; END IF;
 EXECUTE replace(v_def,v_old,v_guard);

 v_function:='public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)';
 v_def:=pg_get_functiondef(v_function::regprocedure);
 v_old:='v_authorized:=public.authorize_exam_prep_plan_item_safe_v1(p_plan_id,v_priority);';
 v_new:='v_authorized:=private.exam_prep_legacy_authorize_plan_internal_v1(p_plan_id,v_priority);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Goal authorization delegate changed'; END IF;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Goal authorization owner gate changed'; END IF;
 EXECUTE replace(v_def,v_old,v_guard);

 v_function:='public.start_exam_prep_plan_session_once_safe_v1(uuid,text)';
 v_def:=pg_get_functiondef(v_function::regprocedure);
 v_old:='v_started:=public.start_exam_prep_session_safe_v1(p_authorization_id,p_idempotency_key);';
 v_new:='v_started:=private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Once-only starter delegate changed'; END IF;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Once-only starter owner gate changed'; END IF;
 EXECUTE replace(v_def,v_old,v_guard);
END;$guard$;

-- Legacy v1 has distinct recovery semantics. Do not silently discard mode or
-- replace an enrolled learner's plan; only the existing new recovery flow may do so.
CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v1(
 p_component_code text,p_recovery_mode text DEFAULT 'normal'::text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_legacy_plan_use_current_flow' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_generate_v1_internal_v1(p_component_code,p_recovery_mode);
END;$body$;

CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v2(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RETURN public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);
 END IF;
 RETURN private.exam_prep_legacy_generate_v2_internal_v1(p_component_code);
END;$body$;

CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RETURN public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);
 END IF;
 RETURN private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);
END;$body$;

-- All direct old academic authorizers fail closed for ENROLLED learners.
-- The exact goal path calls private Core originals, including correction/retest.
CREATE OR REPLACE FUNCTION public.authorize_exam_prep_correction_safe_v1(p_correction_case_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_exact_goal_required' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_correction_internal_v1(p_correction_case_id);
END;$body$;

CREATE OR REPLACE FUNCTION public.authorize_exam_prep_mixed_safe_v1(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_exact_goal_required' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_mixed_internal_v1(p_component_code);
END;$body$;

CREATE OR REPLACE FUNCTION public.authorize_exam_prep_retest_safe_v1(p_correction_case_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_exact_goal_required' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_retest_internal_v1(p_correction_case_id);
END;$body$;

CREATE OR REPLACE FUNCTION public.authorize_exam_prep_plan_item_safe_v1(p_plan_id uuid,p_priority_order integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RETURN jsonb_build_object('status','goal_identity_required');
 END IF;
 RETURN private.exam_prep_legacy_authorize_plan_internal_v1(p_plan_id,p_priority_order);
END;$body$;

-- Guard BOTH plan-bound and unbound academic-credit authorizations. Preserve
-- existing ACTIVE sessions even across rollout; never replay a finalized ID.
-- Genuine separate Stage0 diagnostic, stage-gated timed/paper, and noncredit
-- progress revalidation remain available under their original Core contracts.
-- Always lock the SAME user/component advisory key BEFORE an auth row: a direct
-- legacy starter and once-only starter must not take opposite lock orders.
CREATE OR REPLACE FUNCTION public.start_exam_prep_session_safe_v1(
 p_authorization_id uuid,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE
 v_uid uuid;
 v_component text;
 v_auth private.exam_prep_session_authorizations%rowtype;
 v_existing private.exam_prep_sessions%rowtype;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  -- Read only component first. Row locking here would invert the once-only
  -- lock order and deadlock when old/new tabs start the same authorization.
  SELECT component_code INTO v_component FROM private.exam_prep_session_authorizations
   WHERE id=p_authorization_id AND user_id=v_uid;
  IF v_component NOT IN ('P1','P5') OR v_component IS NULL THEN
   RAISE EXCEPTION 'exam_prep_authorization_not_found' USING errcode='P0002';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||v_component,0));
  SELECT * INTO v_auth FROM private.exam_prep_session_authorizations
   WHERE id=p_authorization_id AND user_id=v_uid FOR UPDATE;
  IF v_auth.id IS NULL OR v_auth.component_code IS DISTINCT FROM v_component THEN
   RAISE EXCEPTION 'exam_prep_authorization_not_found' USING errcode='P0002';
  END IF;
  IF v_auth.plan_id IS NOT NULL THEN
   RETURN public.start_exam_prep_plan_session_once_safe_v1(p_authorization_id,p_idempotency_key);
  END IF;
  IF v_auth.status='consumed' AND v_auth.consumed_session_id IS NOT NULL THEN
   SELECT * INTO v_existing FROM private.exam_prep_sessions
    WHERE id=v_auth.consumed_session_id AND user_id=v_uid AND authorization_id=v_auth.id;
   IF v_existing.id IS NOT NULL AND v_existing.status='active' THEN
    RETURN private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);
   END IF;
   IF v_existing.id IS NOT NULL AND v_existing.status='finalized' THEN
    RETURN jsonb_build_object('status','attempt_already_saved','resumed',true);
   END IF;
  END IF;
  IF v_auth.purpose IN ('learning','mixed','retest') AND coalesce(v_auth.academic_credit,true) THEN
   RAISE EXCEPTION 'exam_prep_exact_weekly_goal_required' USING errcode='42501';
  END IF;
  IF v_auth.purpose NOT IN ('diagnostic','timed','paper') AND
     NOT (v_auth.purpose='retest' AND v_auth.academic_credit IS FALSE
          AND v_auth.credit_context='progress_revalidation') THEN
   RAISE EXCEPTION 'exam_prep_unrecognized_nonplan_authorization' USING errcode='42501';
  END IF;
 END IF;
 RETURN private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);
END;$body$;

DO $verify$
DECLARE v_fn text;
BEGIN
 FOREACH v_fn IN ARRAY ARRAY[
  'private.exam_prep_legacy_generate_v1_internal_v1(text,text)',
  'private.exam_prep_legacy_generate_v2_internal_v1(text)',
  'private.exam_prep_legacy_generate_v3_internal_v1(text)',
  'private.exam_prep_legacy_correction_internal_v1(uuid)',
  'private.exam_prep_legacy_mixed_internal_v1(text)',
  'private.exam_prep_legacy_retest_internal_v1(uuid)',
  'private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)',
  'private.exam_prep_legacy_start_session_internal_v1(uuid,text)',
  'private.exam_prep_weekly_flow_enrolled_v1(uuid)'
 ] LOOP
  IF has_function_privilege('authenticated',v_fn,'EXECUTE') OR
     has_function_privilege('anon',v_fn,'EXECUTE') OR
     has_function_privilege('service_role',v_fn,'EXECUTE') THEN
   RAISE EXCEPTION 'Private Core bypass executable: %',v_fn;
  END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1) THEN
  RAISE EXCEPTION 'Unapproved weekly-flow enrollment present';
 END IF;
END;$verify$;


-- ===== SOURCE docs/patch-proposals/20260920_weekly_flow_postinstall_attestation_v1.sql | blob 5626ad160246618093718057eb8f9aa6f68d4bd0 =====
-- REVIEW-ONLY proposal. Never production without separate owner approval.
-- AFTER atomic full-surface cutover and BEFORE any learner enrollment.
-- Seal installed hashes for all 11 protected public entrypoints.
BEGIN;
DO $verify$
DECLARE b record; v_function pg_proc%rowtype; v_anchor text; v_count integer:=0;
BEGIN
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NULL
   OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL
   OR to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL THEN
  RAISE EXCEPTION 'weekly_attestation_prerequisites_missing';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1) THEN
  RAISE EXCEPTION 'weekly_attestation_requires_zero_enrollment';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_flow_rpc_backup_v1 LOOP
  v_count:=v_count+1;
  SELECT * INTO v_function FROM pg_proc WHERE oid=to_regprocedure(b.signature);
  IF v_function.oid IS NULL OR v_function.oid<>b.function_oid
     OR b.installed_md5 IS NOT NULL
     OR md5(pg_get_functiondef(v_function.oid))=b.original_md5
     OR v_function.proowner IS DISTINCT FROM b.original_owner
     OR v_function.proacl IS DISTINCT FROM b.original_acl
     OR v_function.prosecdef IS DISTINCT FROM b.original_security
     OR v_function.provolatile IS DISTINCT FROM b.original_volatility
     OR has_function_privilege('anon',v_function.oid,'EXECUTE')
     OR NOT has_function_privilege('authenticated',v_function.oid,'EXECUTE') THEN
   RAISE EXCEPTION 'weekly_attestation_public_rpc_mismatch_%',b.signature;
  END IF;
  v_anchor:=CASE b.signature
   WHEN 'public.generate_exam_prep_weekly_plan_safe_v1(text,text)' THEN 'private.exam_prep_legacy_generate_v1_internal_v1'
   WHEN 'public.generate_exam_prep_weekly_plan_safe_v2(text)' THEN 'private.exam_prep_legacy_generate_v2_internal_v1'
   WHEN 'public.generate_exam_prep_weekly_plan_safe_v3(text)' THEN 'private.exam_prep_legacy_generate_v3_internal_v1'
   WHEN 'public.authorize_exam_prep_correction_safe_v1(uuid)' THEN 'private.exam_prep_legacy_correction_internal_v1'
   WHEN 'public.authorize_exam_prep_mixed_safe_v1(text)' THEN 'private.exam_prep_legacy_mixed_internal_v1'
   WHEN 'public.authorize_exam_prep_retest_safe_v1(uuid)' THEN 'private.exam_prep_legacy_retest_internal_v1'
   WHEN 'public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)' THEN 'private.exam_prep_legacy_authorize_plan_internal_v1'
   WHEN 'public.start_exam_prep_session_safe_v1(uuid,text)' THEN 'private.exam_prep_legacy_start_session_internal_v1'
   WHEN 'public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)' THEN 'private.exam_prep_legacy_generate_v3_internal_v1'
   WHEN 'public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)' THEN 'private.exam_prep_legacy_authorize_plan_internal_v1'
   WHEN 'public.start_exam_prep_plan_session_once_safe_v1(uuid,text)' THEN 'private.exam_prep_legacy_start_session_internal_v1'
   ELSE NULL END;
  IF v_anchor IS NULL OR strpos(pg_get_functiondef(v_function.oid),v_anchor)=0
     OR strpos(pg_get_functiondef(v_function.oid),'private.exam_prep_weekly_flow_enrolled_v1')=0 THEN
   RAISE EXCEPTION 'weekly_attestation_candidate_shape_changed_%',b.signature;
  END IF;
 END LOOP;
 IF v_count<>11 THEN RAISE EXCEPTION 'weekly_attestation_snapshot_count_%',v_count; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES
   ('private.exam_prep_legacy_generate_v1_internal_v1(text,text)'),
   ('private.exam_prep_legacy_generate_v2_internal_v1(text)'),
   ('private.exam_prep_legacy_generate_v3_internal_v1(text)'),
   ('private.exam_prep_legacy_correction_internal_v1(uuid)'),
   ('private.exam_prep_legacy_mixed_internal_v1(text)'),
   ('private.exam_prep_legacy_retest_internal_v1(uuid)'),
   ('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'),
   ('private.exam_prep_legacy_start_session_internal_v1(uuid,text)'),
   ('private.exam_prep_weekly_flow_enrolled_v1(uuid)')
  ) v(signature)
  WHERE to_regprocedure(v.signature) IS NULL
    OR has_function_privilege('authenticated',v.signature,'EXECUTE')
    OR has_function_privilege('anon',v.signature,'EXECUTE')
    OR has_function_privilege('service_role',v.signature,'EXECUTE')) THEN
  RAISE EXCEPTION 'weekly_attestation_private_legacy_access';
 END IF;
 IF strpos(pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure),
     'private.exam_prep_legacy_correction_internal_v1(')=0
   OR strpos(pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure),
     'private.exam_prep_legacy_retest_internal_v1(')=0 THEN
  RAISE EXCEPTION 'weekly_attestation_internal_delegation_bypass';
 END IF;
END;$verify$;
UPDATE private.exam_prep_weekly_flow_rpc_backup_v1 b
SET installed_md5=md5(pg_get_functiondef(b.function_oid))
WHERE installed_md5 IS NULL;
DO $sealed$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1
     WHERE installed_md5 IS NOT NULL AND installed_md5<>original_md5)<>11 THEN
  RAISE EXCEPTION 'weekly_attestation_seal_incomplete';
 END IF;
END;$sealed$;


-- ===== SOURCE docs/patch-proposals/20260920_exam_prep_previous_week_adherence_readonly_v1.sql | blob 36f5db5c6cd9d79d58c330864e1319719b0e380f =====
-- DRAFT PROPOSAL ONLY. Not a migration. NEVER execute on live Supabase without
-- separate authorization. Install only AFTER the stable-plan and atomic legacy
-- dispatch proposals; server enrollment defaults to zero learners.
-- Read-only factual previous-week commitment, NOT exam-grade/readiness prediction.
-- No writes to academic evidence, plans, history, users, or legacy tables.
BEGIN;
DO $guard$
BEGIN
  IF to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL
     OR to_regclass('private.exam_prep_weekly_goal_snapshots') IS NULL
     OR to_regprocedure('private.exam_prep_effective_active_week_v1(uuid)') IS NULL THEN
    RAISE EXCEPTION 'prior-week adherence: prerequisite migration/atomic enrollment missing';
  END IF;
END;
$guard$;

CREATE OR REPLACE FUNCTION public.get_exam_prep_previous_week_adherence_safe_v1(p_component_code text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $body$
DECLARE
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_week smallint;
  v_prior smallint;
  v_end timestamptz;
  v_plan_id uuid;
  v_plan_count int;
  v_goal_count int;
  v_due int;
  v_on_time int;
  v_eventually int;
  v_deferred int;
  v_status text;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF p_component_code NOT IN ('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
  END IF;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL THEN
    RAISE EXCEPTION 'exam_prep_profile_required';
  END IF;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  IF v_week IS NULL OR v_week<=1 THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'status','not_due','can_alert',false);
  END IF;
  v_prior:=(v_week-1)::smallint;
  -- The authoritative weekly clock is the profile creation timestamp, NOT
  -- browser dates, target-exam dates or an arbitrary midnight in a time zone.
  v_end:=v_profile.created_at+(v_prior::integer * interval '7 days');
  IF now()<v_end THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'status','not_due','can_alert',false);
  END IF;

  SELECT count(*)::int,(array_agg(p.id ORDER BY p.generated_at,p.id))[1]
    INTO v_plan_count,v_plan_id
  FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=v_uid AND p.program_version_id=v_profile.program_version_id
    AND p.component_code=p_component_code AND p.active_week_no=v_prior
    AND p.generated_at<v_end;
  -- Multiple versions are historically possible under legacy v3. Their frozen
  -- priorities may have been displaced: do NOT blame the learner or guess.
  IF v_plan_count<>1 THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'active_week_no',v_prior,
      'status',CASE WHEN v_plan_count=0 THEN 'no_verified_plan' ELSE 'ambiguous_plan' END,
      'can_alert',false);
  END IF;

  SELECT count(*)::int INTO v_goal_count
  FROM private.exam_prep_weekly_goal_snapshots g
  WHERE g.user_id=v_uid AND g.program_version_id=v_profile.program_version_id
    AND g.component_code=p_component_code AND g.active_week_no=v_prior;
  IF v_goal_count NOT BETWEEN 1 AND 3 OR EXISTS (
      SELECT 1 FROM private.exam_prep_weekly_goal_snapshots g
      LEFT JOIN private.exam_prep_weekly_plan_items i
        ON i.plan_id=g.source_plan_id AND i.priority_order=g.priority_order
      WHERE g.user_id=v_uid AND g.program_version_id=v_profile.program_version_id
        AND g.component_code=p_component_code AND g.active_week_no=v_prior
        AND (g.source_plan_id<>v_plan_id OR g.created_at>=v_end
          OR i.plan_id IS NULL OR i.item_type<>g.item_type
          OR i.skill_code IS DISTINCT FROM g.skill_code
          OR i.correction_case_id IS DISTINCT FROM g.correction_case_id
          OR i.action_code<>g.action_code
          OR g.item_type NOT IN ('learning','mixed_transfer','correction','retest')
          OR (g.item_type='mixed_transfer' AND
            i.action_payload->>'assessment_id' IS DISTINCT FROM g.assessment_id::text))
    ) THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'active_week_no',v_prior,
      'status','unverifiable_goals','can_alert',false);
  END IF;

  -- Link a completed commitment to exactly the frozen plan + priority and
  -- a genuinely finalized academically credited session. Corrections require
  -- the real remediation_completed action, not just another attempt.
  WITH qualified AS (
    SELECT g.id,g.item_type,
      (i.due_at IS NULL OR i.due_at<v_end) AS was_due,
      proof.completed_at
    FROM private.exam_prep_weekly_goal_snapshots g
    JOIN private.exam_prep_weekly_plan_items i
      ON i.plan_id=g.source_plan_id AND i.priority_order=g.priority_order
    LEFT JOIN LATERAL (
      SELECT min(CASE WHEN g.item_type='correction' THEN ca.created_at
                      ELSE s.finalized_at END) AS completed_at
      FROM private.exam_prep_session_authorizations a
      JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
        AND s.user_id=v_uid AND s.component_code=p_component_code
        AND s.status='finalized' AND s.finalized_at IS NOT NULL
      LEFT JOIN private.exam_prep_correction_actions ca
        ON ca.session_id=s.id AND ca.user_id=v_uid
        AND ca.component_code=p_component_code
        AND ca.correction_case_id=g.correction_case_id
        AND ca.action_type='remediation_completed'
      WHERE a.user_id=v_uid AND a.component_code=p_component_code
        AND a.plan_id=g.source_plan_id
        AND a.plan_priority_order=g.priority_order AND a.academic_credit IS TRUE
        AND ((g.item_type='correction' AND s.session_type='learning' AND ca.id IS NOT NULL)
          OR (g.item_type='learning' AND s.session_type='learning')
          OR (g.item_type='mixed_transfer' AND s.session_type='mixed')
          OR (g.item_type='retest' AND s.session_type='retest'))
    ) proof ON true
    WHERE g.user_id=v_uid AND g.program_version_id=v_profile.program_version_id
      AND g.component_code=p_component_code AND g.active_week_no=v_prior
  )
  SELECT count(*) FILTER (WHERE was_due)::int,
         count(*) FILTER (WHERE was_due AND completed_at<v_end)::int,
         count(*) FILTER (WHERE was_due AND completed_at IS NOT NULL)::int,
         count(*) FILTER (WHERE NOT was_due)::int
  INTO v_due,v_on_time,v_eventually,v_deferred FROM qualified;
  IF v_due=0 THEN v_status:='no_due_goals';
  ELSIF v_on_time=v_due THEN v_status:='completed_on_time';
  ELSIF v_eventually=v_due THEN v_status:='caught_up';
  ELSE v_status:='missed'; END IF;
  RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
    'component_code',p_component_code,'active_week_no',v_prior,
    'status',v_status,'can_alert',v_status='missed',
    'scheduled_goals',v_due,'completed_by_deadline',v_on_time,
    'completed_now',v_eventually,'deferred_goals',v_deferred,
    'week_ended_at',v_end,'data_basis','frozen_goals_and_credited_sessions',
    'does_not_change_goals_or_grades',true);
END;
$body$;
REVOKE ALL ON FUNCTION public.get_exam_prep_previous_week_adherence_safe_v1(text)
  FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_previous_week_adherence_safe_v1(text)
  TO authenticated,service_role;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_preinstall_backup_v1.sql | blob 06aefb0134ee20fd7f84c566e117c68fac5cd9d8 =====
-- DRAFT ONLY. Not in supabase/migrations; NEVER apply to live production without
-- separate explicit owner authorization. Run AFTER base weekly-flow + adherence
-- proposals, BEFORE any 20260921 learning-review SQL. Creates backup metadata,
-- no student, academic, Practice, Tour, or historical data writes.
BEGIN;
DO $gate$
BEGIN
 IF to_regclass('private.exam_prep_weekly_review_rpc_backup_v1') IS NOT NULL
 OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NOT NULL
 OR to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') IS NOT NULL
 OR to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NOT NULL THEN
  RAISE EXCEPTION 'review_backup_not_pristine';
 END IF;
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NULL
 OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL THEN
  RAISE EXCEPTION 'review_backup_base_weekly_prerequisites_missing';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
    AND core_enabled IS FALSE AND kill_switch IS TRUE)
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE) THEN
  RAISE EXCEPTION 'review_backup_requires_core_off_and_zero_enrollment';
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1
     WHERE installed_md5 IS NOT NULL AND installed_md5<>original_md5)<>11 THEN
  RAISE EXCEPTION 'review_backup_requires_sealed_base_11_rpc_install';
 END IF;
END;$gate$;
CREATE TABLE private.exam_prep_weekly_review_rpc_backup_v1 (
 signature text PRIMARY KEY,
 operation text NOT NULL CHECK(operation IN ('modified','added')),
 original_oid oid UNIQUE,
 original_definition text,
 original_md5 text,
 original_owner oid,
 original_acl aclitem[],
 original_security boolean,
 original_volatility char,
 installed_oid oid UNIQUE,
 installed_md5 text,
 installed_owner oid,
 installed_acl aclitem[],
 installed_security boolean,
 installed_volatility char,
 captured_at timestamptz NOT NULL DEFAULT now(),
 sealed_at timestamptz,
 CHECK ((operation='modified' AND original_oid IS NOT NULL
    AND original_definition IS NOT NULL AND original_md5 IS NOT NULL
    AND original_owner IS NOT NULL AND original_security IS NOT NULL
    AND original_volatility IS NOT NULL)
  OR (operation='added' AND original_oid IS NULL
    AND original_definition IS NULL AND original_md5 IS NULL))
);
ALTER TABLE private.exam_prep_weekly_review_rpc_backup_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_weekly_review_rpc_backup_v1
 FROM PUBLIC,anon,authenticated,service_role;
INSERT INTO private.exam_prep_weekly_review_rpc_backup_v1(
 signature,operation,original_oid,original_definition,original_md5,
 original_owner,original_acl,original_security,original_volatility)
SELECT names.signature,'modified',p.oid,pg_get_functiondef(p.oid),
 md5(pg_get_functiondef(p.oid)),p.proowner,p.proacl,p.prosecdef,p.provolatile
FROM (VALUES
 ('public.get_exam_prep_active_plan_session_safe_v1(text)'),
 ('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'),
 ('public.get_exam_prep_weekly_progress_safe_v1(text)'),
 ('public.get_exam_prep_previous_week_adherence_safe_v1(text)')
) names(signature)
JOIN pg_proc p ON p.oid=to_regprocedure(names.signature);
INSERT INTO private.exam_prep_weekly_review_rpc_backup_v1(signature,operation)
VALUES('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','added');
DO $verify$
DECLARE b record; n integer:=0;
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1)<>5 OR
   (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 WHERE operation='modified')<>4 THEN
  RAISE EXCEPTION 'review_backup_missing_affected_rpc';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1
  WHERE operation='modified' LOOP
  n:=n+1;
  IF b.original_owner IS DISTINCT FROM 'postgres'::regrole::oid OR
     NOT b.original_security OR
     has_function_privilege('anon',b.original_oid,'EXECUTE') OR
     NOT has_function_privilege('authenticated',b.original_oid,'EXECUTE') OR
     md5(b.original_definition)<>b.original_md5 THEN
    RAISE EXCEPTION 'review_backup_security_or_definition_drift_%',b.signature;
  END IF;
 END LOOP;
 IF n<>4 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_review_rpc_backup_v1
   WHERE installed_md5 IS NOT NULL OR sealed_at IS NOT NULL) THEN
  RAISE EXCEPTION 'review_backup_not_unsealed';
 END IF;
END;$verify$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_verdict_v1.sql | blob 5d947261d8e5c8a01f728d617127ef33d4181f73 =====
-- REVIEW-ONLY; NOT a production migration, do not auto-install.
-- This is a private read-only decision primitive. It neither authorizes nor
-- launches repeat attempts: the entire review/credit/correction path MUST be
-- joined and tested before any learner enrollment. No new question packs.
BEGIN;
CREATE OR REPLACE FUNCTION private.exam_prep_learning_review_verdict_v1(
 p_user_id uuid, p_program_version_id bigint, p_component_code text,
 p_skill_code text, p_assessment_id bigint
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $body$
DECLARE
 v_attempts integer;
 v_required_objectives integer;
 v_complete boolean;
 v_consistent boolean;
 v_correction text;
BEGIN
 IF p_user_id IS NULL OR p_program_version_id IS NULL OR
    p_component_code NOT IN ('P1','P5') OR p_skill_code IS NULL OR
    p_skill_code NOT LIKE p_component_code||'-%' OR p_assessment_id IS NULL OR
    NOT EXISTS (SELECT 1 FROM private.exam_prep_exam_profiles ep
      WHERE ep.user_id=p_user_id AND ep.program_version_id=p_program_version_id) OR
    NOT EXISTS (SELECT 1 FROM private.exam_prep_assessments a
      JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
      WHERE a.id=p_assessment_id AND a.component_code=p_component_code
        AND a.assessment_type='learning' AND a.status='published'
        AND cv.program_version_id=p_program_version_id
        AND cv.component_code=p_component_code AND cv.status='published'
        AND (SELECT COUNT(*) FROM private.exam_prep_assessment_items i
             WHERE i.assessment_id=a.id AND i.question_id IS NOT NULL
               AND i.primary_skill_code=p_skill_code AND i.reserve_role='learning'
               AND i.is_holdout IS FALSE) BETWEEN 3 AND 6
        AND (SELECT COUNT(*) FROM private.exam_prep_assessment_items i
             WHERE i.assessment_id=a.id AND i.written_task_id IS NOT NULL
               AND i.primary_skill_code=p_skill_code AND i.reserve_role='written'
               AND i.is_holdout IS FALSE)=1
        AND NOT EXISTS (SELECT 1 FROM private.exam_prep_assessment_items i
          WHERE i.assessment_id=a.id AND i.primary_skill_code IS DISTINCT FROM p_skill_code)) THEN
   RETURN jsonb_build_object('status','unverifiable');
 END IF;
 SELECT COUNT(*)::integer INTO v_required_objectives
 FROM private.exam_prep_assessment_items i
 WHERE i.assessment_id=p_assessment_id AND i.question_id IS NOT NULL;

 -- Never replace an active session: it may contain a saved written answer.
 IF EXISTS (SELECT 1 FROM private.exam_prep_sessions s
   WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
     AND s.component_code=p_component_code AND s.assessment_id=p_assessment_id
     AND s.status='active') THEN
   RETURN jsonb_build_object('status','resume_first');
 END IF;
 IF EXISTS (SELECT 1 FROM private.exam_prep_sessions s
   WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
     AND s.component_code=p_component_code AND s.assessment_id=p_assessment_id
     AND s.status NOT IN ('finalized','active')) THEN
   RETURN jsonb_build_object('status','unverifiable');
 END IF;

 -- A finalized attempt with an unanswered written item is unfinished, not an
 -- unverifiable error. Only all objective answers correct + saved written work
 -- is completion; never misread 3/3 answers in a 4-question pack as success.
 WITH scored AS (
   SELECT s.id,
     COUNT(*) FILTER (WHERE r.response_kind='machine')::integer AS objectives,
     COUNT(*) FILTER (WHERE r.response_kind='machine' AND r.is_correct IS TRUE)::integer AS correct,
     COUNT(*) FILTER (WHERE r.response_kind='written' AND r.learner_artifact IS NOT NULL)::integer AS written
   FROM private.exam_prep_sessions s
   LEFT JOIN private.exam_prep_responses r ON r.session_id=s.id AND r.user_id=p_user_id
   WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
     AND s.component_code=p_component_code AND s.assessment_id=p_assessment_id
     AND s.status='finalized'
   GROUP BY s.id
 ) SELECT COUNT(*)::integer,
          COALESCE(BOOL_OR(objectives=v_required_objectives AND correct=objectives AND written=1),false),
          COALESCE(BOOL_AND(objectives BETWEEN 0 AND v_required_objectives
            AND correct BETWEEN 0 AND objectives AND written BETWEEN 0 AND 1),false)
 INTO v_attempts,v_complete,v_consistent FROM scored;
 IF v_attempts=0 THEN RETURN jsonb_build_object('status','first_learning'); END IF;
 IF NOT v_consistent THEN RETURN jsonb_build_object('status','unverifiable'); END IF;

 -- A correction that passed remediation must WAIT for its separate fresh retest.
 SELECT c.status INTO v_correction FROM private.exam_prep_correction_cases c
 WHERE c.user_id=p_user_id AND c.component_code=p_component_code
   AND c.skill_code=p_skill_code AND c.status IN ('open','remediating','reopened','retest_due')
 ORDER BY c.updated_at DESC LIMIT 1;
 IF v_correction='retest_due' THEN
   RETURN jsonb_build_object('status','fresh_retest_pending');
 END IF;
 IF v_correction IN ('open','remediating','reopened') THEN
   RETURN jsonb_build_object('status','repeat_learning','fresh_assessment',false);
 END IF;
 IF v_complete THEN RETURN jsonb_build_object('status','learning_completed'); END IF;
 RETURN jsonb_build_object('status','repeat_learning','fresh_assessment',false);
END;$body$;
REVOKE ALL ON FUNCTION private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)
 FROM PUBLIC,anon,authenticated,service_role;
DO $gate$
BEGIN
 IF has_function_privilege('anon',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
   has_function_privilege('authenticated',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
   has_function_privilege('service_role',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') THEN
   RAISE EXCEPTION 'learning_review_private_verdict_exposed';
 END IF;
END;$gate$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_start_v1.sql | blob 390df286e841a4d27cfaca0b71dfe72a75c33c53 =====
-- REVIEW PROPOSAL ONLY; never install in production without independent owner approval.
-- Install after legacy RPC dispatch + private learning review verdict. Default no enrollments.
-- No question rows, prior sessions, goals, Practice or Tours are modified here.
BEGIN;
DO $prerequisite$
BEGIN
 IF to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NULL
 OR to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL
 OR to_regprocedure('private.exam_prep_legacy_start_session_internal_v1(uuid,text)') IS NULL THEN
  RAISE EXCEPTION 'learning_review_prerequisite_missing';
 END IF;
END;$prerequisite$;

CREATE TABLE private.exam_prep_learning_review_starts_v1 (
 authorization_id uuid PRIMARY KEY REFERENCES private.exam_prep_session_authorizations(id) ON DELETE RESTRICT,
 user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
 program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id) ON DELETE RESTRICT,
 component_code text NOT NULL CHECK(component_code IN ('P1','P5')),
 plan_id uuid NOT NULL REFERENCES private.exam_prep_weekly_plans(id) ON DELETE RESTRICT,
 goal_id uuid NOT NULL REFERENCES private.exam_prep_weekly_goal_snapshots(id) ON DELETE RESTRICT,
 priority_order smallint NOT NULL CHECK(priority_order BETWEEN 1 AND 3),
 skill_code text NOT NULL,
 correction_case_id uuid NOT NULL REFERENCES private.exam_prep_correction_cases(id) ON DELETE RESTRICT,
 assessment_id bigint NOT NULL REFERENCES private.exam_prep_assessments(id) ON DELETE RESTRICT,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX exam_prep_learning_review_owner_v1
 ON private.exam_prep_learning_review_starts_v1(user_id,component_code,plan_id,goal_id,created_at DESC);
ALTER TABLE private.exam_prep_learning_review_starts_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_learning_review_starts_v1 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER exam_prep_learning_review_starts_immutable_v1
 BEFORE UPDATE OR DELETE ON private.exam_prep_learning_review_starts_v1
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_block_immutable_mutation_v1();
CREATE TRIGGER exam_prep_learning_review_starts_audit_v1
 AFTER INSERT ON private.exam_prep_learning_review_starts_v1
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_audit_row_change_v1();

-- A single transaction and a shared owner/component lock bind the frozen goal,
-- original assessment, NONCREDIT authorization and new session. We deliberately
-- DO NOT bind a second authorization to the consumed original plan priority:
-- doing so would violate the existing unique index or rewrite historic evidence.
CREATE OR REPLACE FUNCTION public.start_exam_prep_learning_review_safe_v1(
 p_component_code text,p_goal_id uuid,p_plan_id uuid,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $body$
DECLARE
 v_uid uuid;
 v_program bigint;
 v_week smallint;
 v_plan private.exam_prep_weekly_plans%rowtype;
 v_goal private.exam_prep_weekly_goal_snapshots%rowtype;
 v_item private.exam_prep_weekly_plan_items%rowtype;
 v_case private.exam_prep_correction_cases%rowtype;
 v_ass bigint;
 v_matching integer;
 v_active private.exam_prep_sessions%rowtype;
 v_active_count integer;
 v_reused private.exam_prep_sessions%rowtype;
 v_verdict jsonb;
 v_auth uuid;
 v_started jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
 END IF;
 IF p_component_code NOT IN ('P1','P5') OR p_goal_id IS NULL OR p_plan_id IS NULL THEN
  RETURN jsonb_build_object('status','stale');
 END IF;
 IF p_idempotency_key IS NULL OR char_length(p_idempotency_key) NOT BETWEEN 8 AND 160 THEN
  RAISE EXCEPTION 'exam_prep_bad_idempotency_key';
 END IF;
 SELECT program_version_id INTO v_program FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 v_week:=private.exam_prep_effective_active_week_v1(v_uid);
 IF v_program IS NULL OR v_week IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||p_component_code,0));
 SELECT * INTO v_plan FROM private.exam_prep_weekly_plans
 WHERE id=p_plan_id AND user_id=v_uid AND program_version_id=v_program
 AND component_code=p_component_code AND active_week_no=v_week AND status='active' FOR UPDATE;
 SELECT * INTO v_goal FROM private.exam_prep_weekly_goal_snapshots
 WHERE id=p_goal_id AND user_id=v_uid AND program_version_id=v_program
 AND component_code=p_component_code AND active_week_no=v_week;
 IF v_plan.id IS NULL OR v_goal.id IS NULL OR v_goal.item_type NOT IN ('learning','correction')
 OR v_goal.skill_code IS NULL THEN RETURN jsonb_build_object('status','stale'); END IF;
 SELECT count(*)::integer INTO v_matching FROM private.exam_prep_weekly_plan_items i
 WHERE i.plan_id=v_plan.id AND i.status='pending' AND i.item_type=v_goal.item_type
 AND i.skill_code=v_goal.skill_code AND i.correction_case_id IS NOT DISTINCT FROM v_goal.correction_case_id
 AND i.action_code=v_goal.action_code;
 IF v_matching<>1 THEN RETURN jsonb_build_object('status','stale','reason','goal_binding_missing_or_ambiguous'); END IF;
 SELECT * INTO STRICT v_item FROM private.exam_prep_weekly_plan_items i
 WHERE i.plan_id=v_plan.id AND i.status='pending' AND i.item_type=v_goal.item_type
 AND i.skill_code=v_goal.skill_code AND i.correction_case_id IS NOT DISTINCT FROM v_goal.correction_case_id
 AND i.action_code=v_goal.action_code;
 IF (SELECT count(*) FROM private.exam_prep_weekly_plan_items i
     WHERE i.plan_id=v_plan.id AND i.status='pending' AND i.skill_code=v_item.skill_code
      AND i.item_type IN ('learning','correction'))<>1 THEN
  RETURN jsonb_build_object('status','stale','reason','duplicate_skill_binding');
 END IF;

 -- Any active attempt, including another review or an unfinished written answer,
 -- is resumed; never generate a second session during a two-device race.
 SELECT count(*)::integer,(array_agg(s.id ORDER BY s.started_at,s.id))[1]
 INTO v_active_count,v_active.id FROM private.exam_prep_sessions s
 WHERE s.user_id=v_uid AND s.program_version_id=v_program AND s.component_code=p_component_code
 AND s.status='active' AND s.session_type IN ('learning','mixed','retest');
 IF v_active_count>1 THEN RETURN jsonb_build_object('status','multiple_active'); END IF;
 IF v_active_count=1 THEN
  RETURN jsonb_build_object('status','resume_existing_session_first','session_id',v_active.id,
    'component_code',p_component_code);
 END IF;
 SELECT * INTO v_reused FROM private.exam_prep_sessions
 WHERE user_id=v_uid AND client_idempotency_key=p_idempotency_key;
 IF v_reused.id IS NOT NULL THEN RETURN jsonb_build_object('status','attempt_already_saved'); END IF;

 SELECT * INTO v_case FROM private.exam_prep_correction_cases c
 WHERE c.user_id=v_uid AND c.component_code=p_component_code AND c.skill_code=v_item.skill_code
 AND c.status IN ('open','remediating','reopened')
 AND (v_item.correction_case_id IS NULL OR c.id=v_item.correction_case_id)
 ORDER BY c.updated_at DESC LIMIT 1 FOR UPDATE;
 IF v_case.id IS NULL THEN RETURN jsonb_build_object('status','waiting','reason','no_open_correction'); END IF;
 SELECT a.id INTO v_ass FROM private.exam_prep_assessments a
 WHERE a.component_code=p_component_code AND a.assessment_type='learning' AND a.status='published'
 AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
            WHERE ai.assessment_id=a.id AND ai.primary_skill_code=v_item.skill_code)
 AND NOT EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
                WHERE ai.assessment_id=a.id AND ai.primary_skill_code<>v_item.skill_code)
 ORDER BY a.id LIMIT 1;
 IF v_ass IS NULL THEN RETURN jsonb_build_object('status','waiting','reason','content_unavailable'); END IF;
 v_verdict:=private.exam_prep_learning_review_verdict_v1(
    v_uid,v_program,p_component_code,v_item.skill_code,v_ass);
 IF v_verdict->>'status'<>'repeat_learning' THEN
  RETURN jsonb_build_object('status','waiting','reason',coalesce(v_verdict->>'status','unverifiable'));
 END IF;

 INSERT INTO private.exam_prep_session_authorizations(
  user_id,assessment_id,component_code,purpose,status,valid_until,reason,
  correction_case_id,academic_credit,credit_context
 ) VALUES(v_uid,v_ass,p_component_code,'learning','issued',
  private.exam_prep_effective_academic_now_v1(v_uid)+interval '1 hour',
  'Owner-approved same-pack noncredit learning review',v_case.id,false,'learning_review')
 RETURNING id INTO v_auth;
 INSERT INTO private.exam_prep_learning_review_starts_v1(
  authorization_id,user_id,program_version_id,component_code,plan_id,goal_id,
  priority_order,skill_code,correction_case_id,assessment_id
 ) VALUES(v_auth,v_uid,v_program,p_component_code,v_plan.id,v_goal.id,
          v_item.priority_order,v_item.skill_code,v_case.id,v_ass);
 v_started:=private.exam_prep_legacy_start_session_internal_v1(v_auth,p_idempotency_key);
 IF v_started->>'status'<>'active' OR v_started->>'session_id' IS NULL THEN
  RAISE EXCEPTION 'exam_prep_review_atomic_start_failed';
 END IF;
 UPDATE private.exam_prep_correction_cases
 SET status='remediating',updated_at=private.exam_prep_effective_academic_now_v1(v_uid)
 WHERE id=v_case.id;
 PERFORM private.exam_prep_log_correction_action_v1(v_case.id,'remediation_authorized',null,null,null,
   jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass,'noncredit_review',true));
 RETURN jsonb_build_object('status','started','session_id',v_started->>'session_id',
  'component_code',p_component_code,'goal_id',v_goal.id,'plan_id',v_plan.id,
  'repeat_learning',true,'academic_credit',false,'prior_progress_retained',true,
  'not_a_new_independent_check',true);
END;$body$;
REVOKE ALL ON FUNCTION public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)
 FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)
 TO authenticated;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_exact_goal_binding_v1.sql | blob 9498fffae2f690c8e8c30f05fd51d2fec70bb5ee =====
-- DRAFT PROPOSAL ONLY. Apply after learning_review_start_v1 in DISPOSABLE CI.
-- No live SQL installation is authorized. Fail closed on unknown source drift.
-- A frozen goal must belong to the EXACT active plan and priority shown to
-- the learner. Matching only by skill/action can misattribute a legacy replan.
BEGIN;
DO $patch$
DECLARE
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
BEGIN
  v_oid:=to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)');
  IF v_oid IS NULL OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
    RAISE EXCEPTION 'learning_review_binding_prerequisite_missing';
  END IF;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='WHERE id=p_goal_id AND user_id=v_uid AND program_version_id=v_program'
    ||chr(10)||' AND component_code=p_component_code AND active_week_no=v_week;';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'learning_review_goal_source_anchor_drift';
  END IF;
  v_new:='WHERE id=p_goal_id AND user_id=v_uid AND program_version_id=v_program'
    ||chr(10)||' AND component_code=p_component_code AND active_week_no=v_week'
    ||' AND source_plan_id=p_plan_id;';
  v_def:=replace(v_def,v_old,v_new);

  -- Both the COUNT and SELECT of the prospective item require its frozen
  -- priority; the independent duplicate-skill check stays broad on purpose.
  v_old:='WHERE i.plan_id=v_plan.id AND i.status=''pending'' AND i.item_type=v_goal.item_type';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
    RAISE EXCEPTION 'learning_review_priority_anchors_drift';
  END IF;
  v_new:=v_old||chr(10)||' AND i.priority_order=v_goal.priority_order';
  v_def:=replace(v_def,v_old,v_new);
  EXECUTE v_def;
END;
$patch$;
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 OR NOT EXISTS(SELECT 1 FROM pg_proc
   WHERE oid='public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure
   AND prosecdef AND provolatile='v') THEN
  RAISE EXCEPTION 'learning_review_binding_security_drift';
 END IF;
END;
$verify$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_recovery_v1.sql | blob 59a2f94d1eabd6d17a5716e23cfdadfc90c287b7 =====
-- REVIEW PROPOSAL ONLY; run after same-pack start proposal in isolated CI.
-- Add review sessions to the existing read-only recovery RPC, without replacing
-- its public name, owner checks, first-unanswered answer discovery or Core scope.
BEGIN;
DO $patch$
DECLARE v_oid oid;
 v_def text;
 v_old text;
 v_new text;
BEGIN
 IF to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
  RAISE EXCEPTION 'learning_review_recovery_missing_ledger';
 END IF;
 v_oid:=to_regprocedure('public.get_exam_prep_active_plan_session_safe_v1(text)');
 IF v_oid IS NULL THEN RAISE EXCEPTION 'learning_review_recovery_missing_rpc'; END IF;
 v_def:=pg_get_functiondef(v_oid);
 v_old:='and a.academic_credit is true';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
  RAISE EXCEPTION 'learning_review_recovery_credit_anchor_drift';
 END IF;
 v_new:='and (a.academic_credit is true OR (a.academic_credit is false AND a.credit_context=''learning_review''))';
 v_def:=replace(v_def,v_old,v_new);
 v_old:='and a.plan_id is not null';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
  RAISE EXCEPTION 'learning_review_recovery_plan_anchor_drift'; END IF;
 v_new:='and (a.plan_id is not null OR EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=a.id AND rr.user_id=a.user_id AND rr.component_code=a.component_code))';
 v_def:=replace(v_def,v_old,v_new);
 v_old:='where p.id = v_auth.plan_id';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'learning_review_recovery_plan_join_drift'; END IF;
 v_def:=replace(v_def,v_old,
  'where p.id = coalesce(v_auth.plan_id,(SELECT rr.plan_id FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid))');
 v_old:='''source_plan_id'', v_auth.plan_id';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'learning_review_recovery_plan_return_drift'; END IF;
 v_def:=replace(v_def,v_old,
  '''source_plan_id'', coalesce(v_auth.plan_id,(SELECT rr.plan_id FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid))');
 v_old:='''source_plan_priority_order'', v_auth.plan_priority_order';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'learning_review_recovery_priority_return_drift'; END IF;
 v_def:=replace(v_def,v_old,
  '''source_plan_priority_order'', coalesce(v_auth.plan_priority_order,(SELECT rr.priority_order FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid))');
 -- Fresh page loads must show the same learning-review notice as a new start.
 -- Never infer this flag from a session type or browser history.
 v_old:='''resume_independent_of_current_plan'', true';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'learning_review_recovery_notice_anchor_drift'; END IF;
 v_def:=replace(v_def,v_old,
  '''resume_independent_of_current_plan'', true, ''learning_review'', EXISTS('
  ||'SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rr '
  ||'WHERE rr.authorization_id=v_auth.id AND rr.user_id=v_uid '
  ||'AND rr.component_code=p_component_code)');
 EXECUTE v_def;
END;$patch$;
-- Original authenticated access and anon denial are preserved by CREATE OR REPLACE.
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.get_exam_prep_active_plan_session_safe_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_active_plan_session_safe_v1(text)','EXECUTE') THEN
  RAISE EXCEPTION 'learning_review_recovery_acl_changed';
 END IF;
END;$verify$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_goal_eligibility_v1.sql | blob 314bfc03166ba1d12efc8ebfc30eb324e8ae3327 =====
-- REVIEW-ONLY SQL proposal. Apply after private verdict, guarded start and recovery patches.
-- Old content-exhausted response remains for unenrolled users and for any
-- unverifiable, completed or fresh-retest-pending attempt; no academic writes.
BEGIN;
DO $patch$
DECLARE
 v_oid oid;
 v_def text;
 v_old text;
 v_new text;
BEGIN
 IF to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') IS NULL
 OR to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NULL THEN
  RAISE EXCEPTION 'review_goal_eligibility_prerequisite_missing';
 END IF;
 v_oid:=to_regprocedure('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)');
 IF v_oid IS NULL THEN RAISE EXCEPTION 'review_goal_eligibility_missing_rpc'; END IF;
 v_def:=pg_get_functiondef(v_oid);
 v_old:='    return jsonb_build_object(''status'',''waiting'',''reason'',''attempt_already_saved'');';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_goal_eligibility_consumed_anchor_drift'; END IF;
 v_new:='    IF v_item.item_type IN (''learning'',''correction'') AND v_auth.purpose=''learning'' '
 ||'AND private.exam_prep_weekly_flow_enrolled_v1(v_uid) '
 ||'AND (private.exam_prep_learning_review_verdict_v1(v_uid,v_program,p_component_code,v_item.skill_code,v_auth.assessment_id)->>''status'')=''repeat_learning'' THEN'
 ||chr(10)||'      RETURN jsonb_build_object(''status'',''review_ready'',''reason'',''same_pack_learning_review'', '
 ||'''component_code'',p_component_code,''goal_id'',v_goal.id,''plan_id'',v_plan.id, '
 ||'''priority_order'',v_item.priority_order,''skill_code'',v_item.skill_code,''item_type'',v_item.item_type, '
 ||'''fresh_assessment'',false);'
 ||chr(10)||'    END IF;'
 ||chr(10)||v_old;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='      return jsonb_build_object(''status'',''content_exhausted'','||chr(10)
  ||'        ''reason'',''previously_seen_learning_pack'');';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_goal_eligibility_exhausted_anchor_drift'; END IF;
 v_new:='      IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) '
 ||'AND (private.exam_prep_learning_review_verdict_v1(v_uid,v_program,p_component_code,v_item.skill_code,v_assessment)->>''status'')=''repeat_learning'' THEN'
 ||chr(10)||'        RETURN jsonb_build_object(''status'',''review_ready'',''reason'',''same_pack_learning_review'', '
 ||'''component_code'',p_component_code,''goal_id'',v_goal.id,''plan_id'',v_plan.id, '
 ||'''priority_order'',v_item.priority_order,''skill_code'',v_item.skill_code,''item_type'',v_item.item_type, '
 ||'''fresh_assessment'',false);'
 ||chr(10)||'      END IF;'
 ||chr(10)||v_old;
 EXECUTE replace(v_def,v_old,v_new);
END;$patch$;
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)','EXECUTE') THEN
  RAISE EXCEPTION 'review_goal_eligibility_acl_changed'; END IF;
END;$verify$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_weekly_accounting_v1.sql | blob 93fef7c0bc0e1b3daecc5261139e0776882c3df2 =====
-- REVIEW PROPOSAL ONLY, not a migration. Apply after public review start,
-- recovery, goal eligibility and previous-week adherence proposals in isolated CI.
-- A saved repeated learning attempt alone NEVER proves a correction succeeded.
-- Only the existing server-created remediation_completed action can satisfy
-- a correction commitment. These read-only projections cannot credit mastery.
BEGIN;
DO $patch$
DECLARE v_oid oid; v_def text; v_old text; v_new text;
BEGIN
 IF to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL OR
    to_regprocedure('public.get_exam_prep_previous_week_adherence_safe_v1(text)') IS NULL THEN
  RAISE EXCEPTION 'review_weekly_accounting_prerequisite_missing'; END IF;
 v_oid:=to_regprocedure('public.get_exam_prep_weekly_progress_safe_v1(text)');
 IF v_oid IS NULL THEN RAISE EXCEPTION 'review_progress_projection_missing'; END IF;
 v_def:=pg_get_functiondef(v_oid);
 v_old:='coalesce(hist.remediation_done,false) as remediation_done,';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_progress_remediation_anchor_drift'; END IF;
 v_new:='(coalesce(hist.remediation_done,false) OR EXISTS('
  ||'SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rv '
  ||'JOIN private.exam_prep_session_authorizations ra ON ra.id=rv.authorization_id '
  ||'AND ra.user_id=v_uid AND ra.academic_credit IS FALSE '
  ||'AND ra.credit_context=''learning_review'' '
  ||'JOIN private.exam_prep_sessions rs ON rs.authorization_id=ra.id '
  ||'AND rs.user_id=v_uid AND rs.component_code=p_component_code AND rs.status=''finalized'' '
  ||'JOIN private.exam_prep_correction_actions ca ON ca.session_id=rs.id '
  ||'AND ca.correction_case_id=rv.correction_case_id AND ca.action_type=''remediation_completed'' '
  ||'WHERE g.item_type=''correction'' AND rv.user_id=v_uid AND rv.component_code=p_component_code '
  ||'AND rv.goal_id=g.id AND rv.correction_case_id=g.correction_case_id'
  ||')) as remediation_done,';
 EXECUTE replace(v_def,v_old,v_new);

 v_oid:=to_regprocedure('public.get_exam_prep_previous_week_adherence_safe_v1(text)');
 v_def:=pg_get_functiondef(v_oid);
 v_old:='AND a.plan_id=g.source_plan_id'||chr(10)
  ||'        AND a.plan_priority_order=g.priority_order AND a.academic_credit IS TRUE';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_adherence_proof_anchor_drift'; END IF;
 v_new:='AND ((a.plan_id=g.source_plan_id '
  ||'AND a.plan_priority_order=g.priority_order AND a.academic_credit IS TRUE) '
  ||'OR (g.item_type=''correction'' AND a.academic_credit IS FALSE '
  ||'AND a.credit_context=''learning_review'' AND EXISTS('
  ||'SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rv '
  ||'WHERE rv.authorization_id=a.id AND rv.user_id=v_uid '
  ||'AND rv.component_code=p_component_code AND rv.goal_id=g.id '
  ||'AND rv.plan_id=g.source_plan_id AND rv.correction_case_id=g.correction_case_id)))';
 v_def:=replace(v_def,v_old,v_new);
 v_old:='''data_basis'',''frozen_goals_and_credited_sessions''';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'review_adherence_basis_anchor_drift'; END IF;
 EXECUTE replace(v_def,v_old,
  '''data_basis'',''frozen_goals_and_verified_remediation''');
END;$patch$;
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.get_exam_prep_weekly_progress_safe_v1(text)','EXECUTE')
 OR has_function_privilege('anon','public.get_exam_prep_previous_week_adherence_safe_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_weekly_progress_safe_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_previous_week_adherence_safe_v1(text)','EXECUTE') THEN
  RAISE EXCEPTION 'review_weekly_projection_acl_changed'; END IF;
END;$verify$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_frozen_goal_continuity_v1.sql | blob f6e80c4926a7e0f510e2ecdf5c8f061a7151a2db =====
-- DRAFT ONLY. Apply in disposable PG17 AFTER exact_goal_binding AND
-- learning_review_goal_eligibility, BEFORE review postinstall attestation.
-- No live installation, academic writes, snapshot edits or automatic enrollment.
-- Frozen goal order is an immutable commitment, not the latest plan priority.
BEGIN;
DO $pristine$
BEGIN
 IF to_regprocedure('private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)') IS NOT NULL
 OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
  RAISE EXCEPTION 'frozen_goal_continuity_requires_pristine_review_install';
 END IF;
END;$pristine$;

CREATE FUNCTION private.exam_prep_frozen_goal_current_priority_v1(
 p_uid uuid,p_program bigint,p_component text,p_week smallint,
 p_goal uuid,p_current_plan uuid
) RETURNS smallint LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $body$
DECLARE
 g private.exam_prep_weekly_goal_snapshots%rowtype;
 src private.exam_prep_weekly_plans%rowtype;
 dst private.exam_prep_weekly_plans%rowtype;
 v_version integer;
 v_plan uuid;
 v_count integer;
 v_priority smallint;
 v_result smallint;
BEGIN
 IF p_uid IS NULL OR p_program IS NULL OR p_component NOT IN ('P1','P5')
    OR p_week IS NULL OR p_goal IS NULL OR p_current_plan IS NULL THEN RETURN NULL; END IF;
 SELECT * INTO g FROM private.exam_prep_weekly_goal_snapshots
 WHERE id=p_goal AND user_id=p_uid AND program_version_id=p_program
 AND component_code=p_component AND active_week_no=p_week;
 IF g.id IS NULL OR g.item_type NOT IN ('learning','correction')
 OR g.skill_code IS NULL OR (g.item_type='correction' AND g.correction_case_id IS NULL)
 THEN RETURN NULL; END IF;
 SELECT * INTO src FROM private.exam_prep_weekly_plans
 WHERE id=g.source_plan_id AND user_id=p_uid AND program_version_id=p_program
 AND component_code=p_component AND active_week_no=p_week
 AND status IN ('active','superseded');
 SELECT * INTO dst FROM private.exam_prep_weekly_plans
 WHERE id=p_current_plan AND user_id=p_uid AND program_version_id=p_program
 AND component_code=p_component AND active_week_no=p_week AND status='active';
 IF src.id IS NULL OR dst.id IS NULL OR src.plan_version IS NULL
 OR dst.plan_version IS NULL OR src.plan_version<1
 OR dst.plan_version<src.plan_version OR dst.plan_version-src.plan_version>100
 OR dst.generated_at<src.generated_at THEN RETURN NULL; END IF;
 -- Two frozen goals with indistinguishable content/correction identity are not
 -- safely routable. Refuse even if today's plan happens to have one candidate.
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_goal_snapshots other
 WHERE other.user_id=p_uid AND other.program_version_id=p_program
 AND other.component_code=p_component AND other.active_week_no=p_week
 AND other.id<>g.id AND other.item_type=g.item_type
 AND other.skill_code IS NOT DISTINCT FROM g.skill_code
 AND other.correction_case_id IS NOT DISTINCT FROM g.correction_case_id
 AND other.action_code=g.action_code
 AND other.assessment_id IS NOT DISTINCT FROM g.assessment_id)
 THEN RETURN NULL; END IF;
 -- Every intermediate plan version MUST be present exactly once and carry one
 -- identical item identity. A gap, duplicate or changed case/action fails shut.
 -- Its priority may vary: the first must match the frozen ordinal, the last
 -- returns the ACTIVE item ordinal. Historical plan/item rows are never edited.
 FOR v_version IN src.plan_version..dst.plan_version LOOP
  SELECT count(*)::integer INTO v_count FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=p_uid AND p.program_version_id=p_program
   AND p.component_code=p_component AND p.active_week_no=p_week
   AND p.plan_version=v_version AND p.generated_at BETWEEN src.generated_at AND dst.generated_at;
  IF v_count<>1 THEN RETURN NULL; END IF;
  SELECT p.id INTO v_plan FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=p_uid AND p.program_version_id=p_program
   AND p.component_code=p_component AND p.active_week_no=p_week
   AND p.plan_version=v_version;
  SELECT count(*)::integer,min(i.priority_order)
  INTO v_count,v_priority FROM private.exam_prep_weekly_plan_items i
  WHERE i.plan_id=v_plan AND i.item_type=g.item_type
   AND i.skill_code IS NOT DISTINCT FROM g.skill_code
   AND i.correction_case_id IS NOT DISTINCT FROM g.correction_case_id
   AND i.action_code=g.action_code
   AND (g.assessment_id IS NULL OR i.action_payload->>'assessment_id'=g.assessment_id::text)
   AND (v_version<>dst.plan_version OR i.status='pending');
  IF v_count<>1 OR (v_version=src.plan_version AND v_priority<>g.priority_order)
   OR (v_version=dst.plan_version AND v_plan<>dst.id)
  THEN RETURN NULL; END IF;
  IF v_version=dst.plan_version THEN v_result:=v_priority; END IF;
 END LOOP;
 RETURN v_result;
END;$body$;
REVOKE ALL ON FUNCTION private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)
 FROM PUBLIC,anon,authenticated,service_role;

-- The preceding exact-binding patch intentionally rejected ALL superseded
-- source plans; replace that unconditional denial ONLY with the provenance
-- proof above. Require exact existing anchors to avoid editing a drifted RPC.
DO $review_patch$
DECLARE v_def text; v_old text; v_new text;
BEGIN
 v_def:=pg_get_functiondef('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure);
 v_old:=' AND source_plan_id=p_plan_id;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'continuity_review_source_anchor_drift'; END IF;
 v_def:=replace(v_def,v_old,';');
 v_old:=chr(10)||' AND i.priority_order=v_goal.priority_order';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
  RAISE EXCEPTION 'continuity_review_frozen_order_anchors_drift'; END IF;
 v_def:=replace(v_def,v_old,'');
 v_old:=chr(10)||' IF (SELECT count(*) FROM private.exam_prep_weekly_plan_items i';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'continuity_review_verified_item_anchor_drift'; END IF;
 v_new:=chr(10)
 ||' IF private.exam_prep_frozen_goal_current_priority_v1(v_uid,v_program,p_component_code,v_week,p_goal_id,p_plan_id)'
 ||' IS DISTINCT FROM v_item.priority_order THEN'
 ||chr(10)||'  RETURN jsonb_build_object(''status'',''stale'',''reason'',''goal_lineage_unverified'');'
 ||chr(10)||' END IF;'
 ||v_old;
 EXECUTE replace(v_def,v_old,v_new);
END;$review_patch$;

-- The read-only goal endpoint must agree with the atomic starter; never show
-- review_ready for an unproven historical goal, even if skill/action match.
DO $eligibility_patch$
DECLARE v_def text; v_old text; v_new text;
BEGIN
 v_def:=pg_get_functiondef('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'::regprocedure);
 v_old:='v_now:=private.exam_prep_effective_academic_now_v1(v_uid);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'continuity_goal_read_model_anchor_drift'; END IF;
 v_new:='IF v_item.item_type IN (''learning'',''correction'') AND'
 ||chr(10)||'     private.exam_prep_frozen_goal_current_priority_v1(v_uid,v_program,p_component_code,v_week,p_goal_id,p_plan_id)'
 ||' IS DISTINCT FROM v_item.priority_order THEN'
 ||chr(10)||'    RETURN jsonb_build_object(''status'',''stale'',''reason'',''goal_lineage_unverified'');'
 ||chr(10)||'  END IF;'
 ||chr(10)||'  '||v_old;
 EXECUTE replace(v_def,v_old,v_new);
END;$eligibility_patch$;
DO $acl_gate$
BEGIN
 IF has_function_privilege('anon','private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)','EXECUTE')
 OR has_function_privilege('authenticated','private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)','EXECUTE')
 OR has_function_privilege('service_role','private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)','EXECUTE')
 OR has_function_privilege('anon','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'continuity_acl_drift'; END IF;
END;$acl_gate$;


-- ===== SOURCE docs/patch-proposals/20260921_exam_prep_learning_review_postinstall_attestation_v1.sql | blob 456c40496539b66f1029c9299cc0fa6ded0948f5 =====
-- DRAFT ONLY, isolated PostgreSQL first. Run AFTER all six review proposals:
-- verdict, start, exact-goal binding, recovery, goal eligibility, weekly accounting.
-- BEFORE any learner is enrolled or the Core release flag changes.
BEGIN;
DO $gate$
DECLARE b record; p pg_proc%rowtype; v_anchor text; n integer:=0;
BEGIN
 IF to_regclass('private.exam_prep_weekly_review_rpc_backup_v1') IS NULL OR
    to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL OR
    to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NULL THEN
  RAISE EXCEPTION 'review_attestation_prerequisite_missing';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
    AND core_enabled IS FALSE AND kill_switch IS TRUE)
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE) THEN
  RAISE EXCEPTION 'review_attestation_requires_core_off_zero_enrollment';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1 ORDER BY signature LOOP
  n:=n+1;
  SELECT * INTO p FROM pg_proc WHERE oid=to_regprocedure(b.signature);
  IF p.oid IS NULL OR b.installed_md5 IS NOT NULL OR b.sealed_at IS NOT NULL OR
     NOT p.prosecdef OR p.proowner IS DISTINCT FROM 'postgres'::regrole::oid OR
     has_function_privilege('anon',p.oid,'EXECUTE') OR
     NOT has_function_privilege('authenticated',p.oid,'EXECUTE') THEN
    RAISE EXCEPTION 'review_attestation_unexpected_function_state_%',b.signature;
  END IF;
  IF b.operation='modified' AND (p.oid<>b.original_oid OR
     md5(pg_get_functiondef(p.oid))=b.original_md5 OR
     p.proowner IS DISTINCT FROM b.original_owner OR
     p.proacl IS DISTINCT FROM b.original_acl OR
     p.prosecdef IS DISTINCT FROM b.original_security OR
     p.provolatile IS DISTINCT FROM b.original_volatility) THEN
    RAISE EXCEPTION 'review_attestation_modified_rpc_drift_%',b.signature;
  END IF;
  IF b.operation='added' AND (b.original_oid IS NOT NULL OR p.provolatile<>'v' OR
     has_function_privilege('service_role',p.oid,'EXECUTE')) THEN
    RAISE EXCEPTION 'review_attestation_new_starter_drift';
  END IF;
  v_anchor:=CASE b.signature
   WHEN 'public.get_exam_prep_active_plan_session_safe_v1(text)' THEN
    'private.exam_prep_learning_review_starts_v1'
   WHEN 'public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)' THEN
    'private.exam_prep_learning_review_verdict_v1'
   WHEN 'public.get_exam_prep_weekly_progress_safe_v1(text)' THEN
    'private.exam_prep_learning_review_starts_v1'
   WHEN 'public.get_exam_prep_previous_week_adherence_safe_v1(text)' THEN
    'private.exam_prep_learning_review_starts_v1'
   WHEN 'public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)' THEN
    'private.exam_prep_learning_review_verdict_v1'
   ELSE NULL END;
  IF v_anchor IS NULL OR strpos(pg_get_functiondef(p.oid),v_anchor)=0 THEN
   RAISE EXCEPTION 'review_attestation_missing_expected_contract_%',b.signature;
  END IF;
 END LOOP;
 IF n<>5 THEN RAISE EXCEPTION 'review_attestation_expected_five_rpcs_got_%',n; END IF;
 IF has_function_privilege('anon',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
    has_function_privilege('authenticated',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
    has_table_privilege('authenticated','private.exam_prep_learning_review_starts_v1','SELECT') OR
    has_table_privilege('anon','private.exam_prep_learning_review_starts_v1','SELECT') OR
    has_table_privilege('service_role','private.exam_prep_learning_review_starts_v1','SELECT') THEN
  RAISE EXCEPTION 'review_attestation_private_object_exposure';
 END IF;
END;$gate$;
UPDATE private.exam_prep_weekly_review_rpc_backup_v1 b
SET installed_oid=to_regprocedure(b.signature),
 installed_md5=md5(pg_get_functiondef(to_regprocedure(b.signature))),
 installed_owner=p.proowner,installed_acl=p.proacl,
 installed_security=p.prosecdef,installed_volatility=p.provolatile,
 sealed_at=now()
FROM pg_proc p WHERE p.oid=to_regprocedure(b.signature)
 AND b.installed_md5 IS NULL AND b.sealed_at IS NULL;
DO $verify$
DECLARE n integer;
BEGIN
 -- Use the five backed-up OIDs as the source of pg_get_functiondef().
 -- Applying that function to a planner-expanded pg_proc scan can visit
 -- aggregate OIDs, for which PostgreSQL raises an unrelated error.
 SELECT count(*) INTO n FROM private.exam_prep_weekly_review_rpc_backup_v1 b
 JOIN pg_proc p ON p.oid=b.installed_oid
 WHERE b.installed_md5 IS NOT NULL AND b.sealed_at IS NOT NULL
   AND md5(pg_get_functiondef(b.installed_oid))=b.installed_md5
   AND b.installed_owner IS NOT DISTINCT FROM p.proowner
   AND b.installed_acl IS NOT DISTINCT FROM p.proacl
   AND b.installed_security IS NOT DISTINCT FROM p.prosecdef
   AND b.installed_volatility IS NOT DISTINCT FROM p.provolatile;
 IF n<>5 THEN RAISE EXCEPTION 'review_attestation_seal_failed_%',n; END IF;
END;$verify$;


UPDATE private.exam_prep_feature_config f
SET rollout_state=b.rollout_state,
    core_enabled=b.core_enabled,
    ai_enabled=b.ai_enabled,
    mentor_enabled=b.mentor_enabled,
    kill_switch=b.kill_switch,
    updated_at=b.updated_at
FROM _weekly_feature_before b
WHERE f.program_key=b.program_key;

DO $release_postcheck$
DECLARE v_before record; v_after record;
BEGIN
  SELECT * INTO v_before FROM _weekly_feature_before;
  SELECT program_key,rollout_state,core_enabled,ai_enabled,mentor_enabled,kill_switch,updated_at
  INTO v_after FROM private.exam_prep_feature_config WHERE program_key='math_as_p1_p5';

  IF row(v_after.program_key,v_after.rollout_state,v_after.core_enabled,v_after.ai_enabled,
         v_after.mentor_enabled,v_after.kill_switch,v_after.updated_at)
     IS DISTINCT FROM
     row(v_before.program_key,v_before.rollout_state,v_before.core_enabled,v_before.ai_enabled,
         v_before.mentor_enabled,v_before.kill_switch,v_before.updated_at)
  THEN RAISE EXCEPTION 'weekly release: feature config was not restored exactly'; END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1) THEN
    RAISE EXCEPTION 'weekly release: unexpected learner enrollment';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1
      WHERE installed_md5 IS NOT NULL
        AND md5(pg_get_functiondef(function_oid))=installed_md5)<>8
  THEN RAISE EXCEPTION 'weekly release: base RPC seal incomplete'; END IF;

  IF (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1
      WHERE installed_md5 IS NOT NULL AND installed_oid IS NOT NULL
        AND md5(pg_get_functiondef(installed_oid))=installed_md5)<>5
  THEN RAISE EXCEPTION 'weekly release: review RPC seal incomplete'; END IF;
END
$release_postcheck$;

COMMIT;
