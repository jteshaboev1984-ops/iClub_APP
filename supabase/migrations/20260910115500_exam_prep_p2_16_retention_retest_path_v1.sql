-- P2-16: allow correctly learned skills to receive the delayed retention evidence
-- required by the canonical skill contract. Correction-driven retests remain higher priority.
-- Calendar time never awards mastery; it only unlocks a due retest.

begin;

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

create or replace function public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_effective_week smallint;
  v_base jsonb;
  v_plan uuid;
  v_case private.exam_prep_progress_revalidation_cases%rowtype;
  v_failed record;
  v_replace smallint;
  v_count int;
  v_applied int:=0;
  v_mixed_assessment bigint;
  v_mixed_key text;
  v_mixed_planned boolean:=false;
  v_retention_skill text;
  v_retention_due timestamptz;
  v_retention_planned boolean:=false;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  v_effective_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_effective_week is null then raise exception 'exam_prep_profile_required'; end if;

  update private.exam_prep_exam_profiles
  set active_week_no=v_effective_week,updated_at=now(),updated_by=v_uid
  where user_id=v_uid and active_week_no<v_effective_week;

  v_base:=public.generate_exam_prep_weekly_plan_safe_v2(p_component_code);
  v_plan:=(v_base->>'plan_id')::uuid;

  select rv.* into v_case
  from private.exam_prep_progress_revalidation_cases rv
  join private.exam_prep_recovery_cases rc on rc.id=rv.recovery_case_id
  where rv.user_id=v_uid and rv.component_code=p_component_code
    and rv.status='refresh_recommended' and rc.status='active'
  order by rv.updated_at desc limit 1;

  if v_case.id is not null then
    for v_failed in
      select i.skill_code from private.exam_prep_progress_revalidation_items i
      where i.case_id=v_case.id and i.status='completed' and i.passed is false
      order by i.item_order
    loop
      continue when exists(select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code and x.item_type in ('retest','correction'));
      continue when exists(select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code and x.action_code='RECOVERY_REFRESH_RETAINED_SKILL');

      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select max(priority_order)::smallint into v_replace from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';

      if v_replace is not null then delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then v_replace:=(v_count+1)::smallint;
      else continue; end if;

      insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
      values(v_plan,v_replace,'learning',v_failed.skill_code,'RECOVERY_REFRESH_RETAINED_SKILL',
        jsonb_build_object('progress_retained',true,'revalidation_failed',true,'academic_stage_unchanged',true));
      v_applied:=v_applied+1;
    end loop;
  end if;

  if coalesce(v_base->>'recovery_mode','normal') in ('normal','reserve_1w','recovery_2_3w') then
    with first_ev as (
      select e.skill_code,min(e.created_at) as first_non_retest_at
      from private.exam_prep_evidence_events e
      join private.exam_prep_sessions ses on ses.id=e.session_id
      where e.user_id=v_uid and e.component_code=p_component_code and e.evidence_type<>'retest'
        and ses.user_id=v_uid and ses.status='finalized'
      group by e.skill_code
    )
    select s.skill_code,
      greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),
               f.first_non_retest_at+interval '2 days')
    into v_retention_skill,v_retention_due
    from private.exam_prep_skill_states s
    join private.exam_prep_skill_contracts c
      on c.program_version_id=s.program_version_id and c.component_code=s.component_code and c.skill_code=s.skill_code
    join first_ev f on f.skill_code=s.skill_code
    where s.user_id=v_uid
      and s.program_version_id=(select program_version_id from private.exam_prep_exam_profiles where user_id=v_uid)
      and s.component_code=p_component_code and s.engine_version='objective_state_v1' and s.objective_level=2
      and c.requires_retest_for_l3 and not s.has_delayed_successful_retest
      and coalesce(s.unresolved_correction_count,0)=0
      and (not c.requires_transfer_for_l3 or s.has_transfer_evidence)
      and (not c.requires_mixed_for_l3 or exists(
        select 1 from private.exam_prep_evidence_events me
        join private.exam_prep_sessions ms on ms.id=me.session_id
        where me.user_id=v_uid and me.component_code=p_component_code and me.skill_code=s.skill_code
          and me.evidence_type='mixed' and me.verification_status='app_verified' and me.is_correct is true
          and ms.user_id=v_uid and ms.status='finalized'))
      and greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),
                   f.first_non_retest_at+interval '2 days')<=now()+interval '7 days'
      and exists(
        select 1 from private.exam_prep_assessments a
        where a.component_code=p_component_code and a.assessment_type='retest' and a.status='published'
          and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=s.skill_code)
          and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>s.skill_code))
    order by
      (greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),
                f.first_non_retest_at+interval '2 days')<=now()) desc,
      greatest(f.first_non_retest_at+(coalesce(c.min_retest_delay_days,0)*interval '1 day'),
               f.first_non_retest_at+interval '2 days'),s.skill_code
    limit 1;

    if v_retention_skill is not null then
      select min(priority_order)::smallint into v_replace from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;

      if v_replace is not null then delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then v_replace:=(v_count+1)::smallint;
      else v_replace:=null; end if;

      if v_replace is not null then
        insert into private.exam_prep_weekly_plan_items(
          plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload)
        values(v_plan,v_replace,'retest',v_retention_skill,null,v_retention_due,'COMPLETE_RETENTION_RETEST',
          jsonb_build_object('retest_kind','retention','correction_required',false,'atomic_coverage_required',true,
            'transfer_requirement_preserved',true,'calendar_auto_promotion',false));
        v_retention_planned:=true;
      end if;
    end if;
  end if;

  if coalesce(v_base->>'recovery_mode','normal')='normal' then
    v_mixed_assessment:=private.exam_prep_select_mixed_assessment_v1(v_uid,p_component_code,v_effective_week);
    if v_mixed_assessment is not null then
      select assessment_key into v_mixed_key from private.exam_prep_assessments where id=v_mixed_assessment;
      select min(priority_order)::smallint into v_replace from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;

      if v_replace is not null then delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then v_replace:=(v_count+1)::smallint;
      else v_replace:=null; end if;

      if v_replace is not null then
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
        values(v_plan,v_replace,'mixed_transfer',null,'COMPLETE_MIXED_TRANSFER',jsonb_build_object(
          'assessment_id',v_mixed_assessment,'assessment_key',v_mixed_key,'component_code',p_component_code,
          'atomic_coverage_required',true,'same_component_only',true,'calendar_auto_promotion',false));
        v_mixed_planned:=true;
      end if;
    end if;
  end if;

  return v_base || jsonb_build_object(
    'active_week_no',v_effective_week,'progress_retained',true,
    'revalidation_refresh_applied',(v_applied>0),'revalidation_refresh_count',v_applied,
    'academic_stage_changed_by_recovery',false,'calendar_auto_promotion',false,
    'retention_retest_planned',v_retention_planned,'retention_retest_skill',v_retention_skill,
    'retention_retest_due_at',v_retention_due,'mixed_transfer_planned',v_mixed_planned,
    'mixed_assessment_id',v_mixed_assessment);
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

commit;
