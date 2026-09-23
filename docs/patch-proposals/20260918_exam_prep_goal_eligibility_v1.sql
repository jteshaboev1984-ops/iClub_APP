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
