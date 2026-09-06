-- P1-03 learner-safe weekly-plan item authorization.
-- A learner may only launch work that is present in their current active plan.
-- Existing correction/retest/mixed guards remain authoritative; ordinary learning
-- is additionally constrained by the governed runway for the plan's active week.
begin;

create or replace function public.authorize_exam_prep_plan_item_safe_v1(
  p_plan_id uuid,
  p_priority_order integer
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_item private.exam_prep_weekly_plan_items%rowtype;
  v_ass bigint;
  v_auth uuid;
  v_questions int;
  v_written int;
  v_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_plan_id is null then raise exception 'exam_prep_plan_id_required'; end if;
  if p_priority_order is null or p_priority_order not between 1 and 3 then
    raise exception 'exam_prep_bad_plan_priority';
  end if;

  select * into v_plan
  from private.exam_prep_weekly_plans
  where id=p_plan_id and user_id=v_uid and status='active';
  if v_plan.id is null then raise exception 'exam_prep_active_plan_not_found' using errcode='P0002'; end if;

  select * into v_item
  from private.exam_prep_weekly_plan_items
  where plan_id=v_plan.id and priority_order=p_priority_order::smallint and status='pending';
  if v_item.plan_id is null then raise exception 'exam_prep_pending_plan_item_not_found' using errcode='P0002'; end if;

  if v_item.item_type='correction' then
    if v_item.correction_case_id is null then raise exception 'exam_prep_plan_correction_case_required'; end if;
    v_result:=public.authorize_exam_prep_correction_safe_v1(v_item.correction_case_id);

  elsif v_item.item_type='retest' then
    if v_item.correction_case_id is null then raise exception 'exam_prep_plan_retest_case_required'; end if;
    v_result:=public.authorize_exam_prep_retest_safe_v1(v_item.correction_case_id);

  elsif v_item.item_type='mixed_transfer' then
    v_result:=public.authorize_exam_prep_mixed_safe_v1(v_plan.component_code);

  elsif v_item.item_type='learning' then
    if v_item.skill_code is null then raise exception 'exam_prep_plan_learning_skill_required'; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(
      v_plan.program_version_id,v_plan.component_code,v_item.skill_code,v_plan.active_week_no
    ) then
      raise exception 'exam_prep_plan_learning_outside_ready_runway';
    end if;

    select a.id into v_ass
    from private.exam_prep_assessments a
    where a.component_code=v_plan.component_code
      and a.assessment_type='learning'
      and a.status='published'
      and exists(
        select 1 from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code
      )
      and not exists(
        select 1 from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code
      )
    order by a.id
    limit 1;
    if v_ass is null then raise exception 'exam_prep_plan_learning_content_not_ready'; end if;

    select count(*) filter(where question_id is not null),count(*) filter(where written_task_id is not null)
      into v_questions,v_written
    from private.exam_prep_assessment_items
    where assessment_id=v_ass;
    if v_questions<3 or v_written<1 then raise exception 'exam_prep_plan_learning_content_floor_not_met'; end if;

    insert into private.exam_prep_session_authorizations(
      user_id,assessment_id,component_code,purpose,status,valid_until,reason
    ) values(
      v_uid,v_ass,v_plan.component_code,'learning','issued',now()+interval '1 hour',
      'Active weekly plan learning priority '||p_priority_order::text||'; skill '||v_item.skill_code
    ) returning id into v_auth;

    v_result:=jsonb_build_object(
      'authorization_id',v_auth,'assessment_id',v_ass,'component_code',v_plan.component_code,
      'skill_code',v_item.skill_code,'purpose','learning'
    );

  else
    raise exception 'exam_prep_plan_item_not_session_actionable type=%',v_item.item_type;
  end if;

  return v_result || jsonb_build_object(
    'plan_id',v_plan.id,'priority_order',v_item.priority_order,'item_type',v_item.item_type,
    'action_code',v_item.action_code
  );
end;
$$;

revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;

-- Deployment boundary: adding the learner-safe plan launcher must not activate beta
-- or manufacture learner runtime evidence.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 plan item authorizer requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 plan item authorizer active entitlement residue=%',v_active; end if;
end $$;

commit;
