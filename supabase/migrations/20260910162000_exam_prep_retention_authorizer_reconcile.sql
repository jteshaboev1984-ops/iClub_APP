-- Reconcile production authorizer with the existing P2-16 retention path.
-- Correction retests remain unchanged; retention retests are allowed only when due
-- and only after confirmed coverage/transfer with no open correction.
create or replace function public.authorize_exam_prep_plan_item_safe_v1(p_plan_id uuid, p_priority_order integer)
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
  v_state private.exam_prep_skill_states%rowtype;
  v_contract private.exam_prep_skill_contracts%rowtype;
  v_has_mixed boolean:=false;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_plan_id is null then raise exception 'exam_prep_plan_id_required'; end if;
  if p_priority_order is null or p_priority_order not between 1 and 3 then raise exception 'exam_prep_bad_plan_priority'; end if;

  select * into v_plan from private.exam_prep_weekly_plans
  where id=p_plan_id and user_id=v_uid and status='active';
  if v_plan.id is null then raise exception 'exam_prep_active_plan_not_found' using errcode='P0002'; end if;

  select * into v_item from private.exam_prep_weekly_plan_items
  where plan_id=v_plan.id and priority_order=p_priority_order::smallint and status='pending';
  if v_item.plan_id is null then raise exception 'exam_prep_pending_plan_item_not_found' using errcode='P0002'; end if;

  if v_item.item_type='correction' then
    if v_item.correction_case_id is null then raise exception 'exam_prep_plan_correction_case_required'; end if;
    v_result:=public.authorize_exam_prep_correction_safe_v1(v_item.correction_case_id);

  elsif v_item.item_type='retest' then
    if v_item.correction_case_id is not null then
      v_result:=public.authorize_exam_prep_retest_safe_v1(v_item.correction_case_id);
    else
      if v_item.action_code<>'COMPLETE_RETENTION_RETEST' then raise exception 'exam_prep_plan_retest_case_required'; end if;
      if v_item.skill_code is null then raise exception 'exam_prep_retention_retest_skill_required'; end if;
      if v_item.due_at is null then raise exception 'exam_prep_retention_retest_due_required'; end if;
      if v_item.due_at>now() then raise exception 'exam_prep_retest_too_early'; end if;

      perform private.rebuild_exam_prep_state_v1(v_uid,v_plan.component_code);

      select * into v_state from private.exam_prep_skill_states s
      where s.user_id=v_uid and s.program_version_id=v_plan.program_version_id
        and s.component_code=v_plan.component_code and s.skill_code=v_item.skill_code
        and s.engine_version='objective_state_v1';
      select * into v_contract from private.exam_prep_skill_contracts c
      where c.program_version_id=v_plan.program_version_id
        and c.component_code=v_plan.component_code and c.skill_code=v_item.skill_code;

      if v_state.skill_code is null or v_contract.skill_code is null then raise exception 'exam_prep_retention_retest_state_missing'; end if;
      if v_state.objective_level<2 then raise exception 'exam_prep_retention_retest_coverage_required'; end if;
      if v_state.has_delayed_successful_retest then raise exception 'exam_prep_retention_retest_already_satisfied'; end if;
      if coalesce(v_state.unresolved_correction_count,0)>0 then raise exception 'exam_prep_retention_retest_correction_open'; end if;
      if v_contract.requires_transfer_for_l3 and not v_state.has_transfer_evidence then raise exception 'exam_prep_retention_retest_transfer_required'; end if;

      if v_contract.requires_mixed_for_l3 then
        select exists(
          select 1 from private.exam_prep_evidence_events e
          join private.exam_prep_sessions ses on ses.id=e.session_id
          where e.user_id=v_uid and e.component_code=v_plan.component_code
            and e.skill_code=v_item.skill_code and e.evidence_type='mixed'
            and e.verification_status='app_verified' and e.is_correct is true
            and ses.user_id=v_uid and ses.status='finalized'
        ) into v_has_mixed;
        if not v_has_mixed then raise exception 'exam_prep_retention_retest_mixed_required'; end if;
      end if;

      select a.id into v_ass from private.exam_prep_assessments a
      where a.component_code=v_plan.component_code and a.assessment_type='retest' and a.status='published'
        and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)
        and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)
      order by a.id limit 1;
      if v_ass is null then raise exception 'exam_prep_retest_content_not_ready'; end if;

      select count(*) filter(where question_id is not null),count(*) filter(where written_task_id is not null)
        into v_questions,v_written from private.exam_prep_assessment_items where assessment_id=v_ass;
      if coalesce(v_questions,0)<1 then raise exception 'exam_prep_retest_content_not_ready'; end if;

      insert into private.exam_prep_session_authorizations(
        user_id,assessment_id,component_code,purpose,status,valid_until,reason,correction_case_id
      ) values(
        v_uid,v_ass,v_plan.component_code,'retest','issued',now()+interval '1 hour',
        'Core delayed retention retest after confirmed coverage/transfer',null
      ) returning id into v_auth;

      v_result:=jsonb_build_object(
        'authorization_id',v_auth,'assessment_id',v_ass,'component_code',v_plan.component_code,
        'skill_code',v_item.skill_code,'due_not_before',v_item.due_at,'purpose','retest','retest_kind','retention'
      );
    end if;

  elsif v_item.item_type='mixed_transfer' then
    v_result:=public.authorize_exam_prep_mixed_safe_v1(v_plan.component_code);

  elsif v_item.item_type='learning' then
    if v_item.skill_code is null then raise exception 'exam_prep_plan_learning_skill_required'; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(v_plan.program_version_id,v_plan.component_code,v_item.skill_code,v_plan.active_week_no) then
      raise exception 'exam_prep_plan_learning_outside_ready_runway';
    end if;

    select a.id into v_ass from private.exam_prep_assessments a
    where a.component_code=v_plan.component_code and a.assessment_type='learning' and a.status='published'
      and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=v_item.skill_code)
      and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>v_item.skill_code)
    order by a.id limit 1;
    if v_ass is null then raise exception 'exam_prep_plan_learning_content_not_ready'; end if;

    select count(*) filter(where question_id is not null),count(*) filter(where written_task_id is not null)
      into v_questions,v_written from private.exam_prep_assessment_items where assessment_id=v_ass;
    if v_questions<3 or v_written<1 then raise exception 'exam_prep_plan_learning_content_floor_not_met'; end if;

    insert into private.exam_prep_session_authorizations(user_id,assessment_id,component_code,purpose,status,valid_until,reason)
    values(v_uid,v_ass,v_plan.component_code,'learning','issued',now()+interval '1 hour',
      'Active weekly plan learning priority '||p_priority_order::text||'; skill '||v_item.skill_code)
    returning id into v_auth;

    v_result:=jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass,'component_code',v_plan.component_code,
      'skill_code',v_item.skill_code,'purpose','learning');
  else
    raise exception 'exam_prep_plan_item_not_session_actionable type=%',v_item.item_type;
  end if;

  return v_result || jsonb_build_object('plan_id',v_plan.id,'priority_order',v_item.priority_order,
    'item_type',v_item.item_type,'action_code',v_item.action_code);
end;
$$;
revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;
