-- P2-17: future retention reminders and mixed-transfer work must not starve the
-- last uncovered learning priority. Due retests still outrank ordinary learning.
-- No legacy Practice/Tour/history tables are touched.

begin;

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
  v_learning_count int;
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

      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      else
        continue;
      end if;

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
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      v_replace:=null;

      if v_retention_due<=now() then
        select max(priority_order)::smallint into v_replace
        from private.exam_prep_weekly_plan_items
        where plan_id=v_plan and item_type='learning'
          and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
        if v_replace is null and v_count<3 then v_replace:=(v_count+1)::smallint; end if;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      end if;

      if v_replace is not null then
        if exists(select 1 from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace) then
          delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
        end if;
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
      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select count(*)::int into v_learning_count from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      v_replace:=null;

      if v_count<3 then
        v_replace:=(v_count+1)::smallint;
      elsif v_learning_count>=2 then
        select max(priority_order)::smallint into v_replace from private.exam_prep_weekly_plan_items
        where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';
      end if;

      if v_replace is not null then
        if exists(select 1 from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace) then
          delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
        end if;
        insert into private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code,action_payload)
        values(v_plan,v_replace,'mixed_transfer',null,'COMPLETE_MIXED_TRANSFER',jsonb_build_object(
          'assessment_id',v_mixed_assessment,'assessment_key',v_mixed_key,'component_code',p_component_code,
          'atomic_coverage_required',true,'same_component_only',true,'calendar_auto_promotion',false));
        v_mixed_planned:=true;
      end if;
    end if;
  end if;

  select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;

  return v_base || jsonb_build_object(
    'active_week_no',v_effective_week,'priority_count',v_count,'progress_retained',true,
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
