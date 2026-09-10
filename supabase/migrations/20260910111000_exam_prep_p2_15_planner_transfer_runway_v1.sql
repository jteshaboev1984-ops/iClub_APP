-- P2-15: keep released learning available after its original planning window,
-- avoid repeated full-runway scans inside the weekly-plan skill loop,
-- and surface governed same-component mixed transfer once atomic coverage exists.
-- Exam Prep only; no legacy Practice/Tour/history mutation.

begin;

create or replace function private.exam_prep_component_learning_dependency_green_v1(
  p_program_version_id bigint,
  p_component_code text,
  p_active_week_no smallint
)
returns boolean
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_end_week integer;
  v_green boolean;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_active_week_no is null or p_active_week_no not between 1 and 36 then raise exception 'exam_prep_bad_active_week'; end if;
  if not exists(
    select 1 from private.exam_prep_program_versions pv
    where pv.id=p_program_version_id and pv.status='active'
  ) then raise exception 'exam_prep_program_version_missing'; end if;

  if p_active_week_no>24 then
    select exists(
      select 1
      from private.exam_prep_content_runway_releases r
      where r.program_version_id=p_program_version_id
        and r.component_code=p_component_code
        and r.schedule_status='active'
        and r.active_week_through>=24
        and exists(
          select 1 from private.exam_prep_content_runway_release_skills rs
          where rs.release_id=r.id and rs.required_for_release
        )
        and not exists(
          select 1
          from private.exam_prep_content_runway_release_skills rs
          where rs.release_id=r.id and rs.required_for_release
            and not private.exam_prep_skill_content_ready_v1(
              p_program_version_id,p_component_code,rs.skill_code
            )
        )
    ) into v_green;
    return coalesce(v_green,false);
  end if;

  v_end_week:=least(24,p_active_week_no::integer+1);

  select not exists(
    select 1
    from generate_series(p_active_week_no::integer,v_end_week) g(w)
    where not exists(
      select 1
      from private.exam_prep_content_runway_releases r
      where r.program_version_id=p_program_version_id
        and r.component_code=p_component_code
        and r.schedule_status='active'
        and g.w between r.active_week_from and r.active_week_through
        and exists(
          select 1 from private.exam_prep_content_runway_release_skills rs
          where rs.release_id=r.id and rs.required_for_release
        )
        and not exists(
          select 1
          from private.exam_prep_content_runway_release_skills rs
          where rs.release_id=r.id and rs.required_for_release
            and not private.exam_prep_skill_content_ready_v1(
              p_program_version_id,p_component_code,rs.skill_code
            )
        )
    )
  ) into v_green;

  return coalesce(v_green,false);
end;
$$;
revoke all on function private.exam_prep_component_learning_dependency_green_v1(bigint,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_component_learning_dependency_green_v1(bigint,text,smallint) to service_role;

create or replace function private.exam_prep_skill_runway_ready_for_week_v1(
  p_program_version_id bigint,p_component_code text,p_skill_code text,p_active_week_no smallint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.exam_prep_component_learning_dependency_green_v1(
      p_program_version_id,p_component_code,p_active_week_no
    )
    and private.exam_prep_skill_content_ready_v1(p_program_version_id,p_component_code,p_skill_code)
    and exists(
      select 1
      from private.exam_prep_content_runway_releases r
      join private.exam_prep_content_runway_release_skills rs
        on rs.release_id=r.id and rs.required_for_release
      where r.program_version_id=p_program_version_id
        and r.component_code=p_component_code
        and r.schedule_status='active'
        and r.active_week_from<=p_active_week_no
        and rs.skill_code=p_skill_code
    );
$$;
revoke all on function private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_runway_ready_for_week_v1(bigint,text,text,smallint) to service_role;

create or replace function public.generate_exam_prep_weekly_plan_safe_v2(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_plan uuid;
  v_version int;
  v_order smallint:=0;
  v_case private.exam_prep_recovery_cases%rowtype;
  v_mode text:='normal';
  v_policy jsonb:='{}'::jsonb;
  v_note text;
  v_plan_horizon smallint;
  v_corr record;
  v_skill text;
  v_stage0 boolean:=false;
  v_learning_dependency_green boolean:=false;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id,active_week_no into v_program,v_week
  from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null or v_week<1 then raise exception 'exam_prep_profile_required'; end if;

  perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);

  select coalesce(p.stage0_complete,false) into v_stage0
  from private.exam_prep_component_placements p
  where p.user_id=v_uid and p.program_version_id=v_program and p.component_code=p_component_code
  order by p.derived_at desc limit 1;
  if not coalesce(v_stage0,false) then raise exception 'exam_prep_stage0_required_before_weekly_plan'; end if;

  v_learning_dependency_green:=private.exam_prep_component_learning_dependency_green_v1(
    v_program,p_component_code,v_week
  );

  select * into v_case
  from private.exam_prep_recovery_cases
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code and status='active'
  order by created_at desc limit 1;
  if v_case.id is not null then
    v_mode:=v_case.recovery_mode;
    v_policy:=v_case.allocation_policy;
  end if;

  v_note:=case v_mode
    when 'normal' then 'Evidence-gated Core plan; at most three priorities; no calendar promotion.'
    when 'reserve_1w' then 'Use reserve capacity, move secondary review, preserve key retest and do not rebuild the entire plan.'
    when 'recovery_2_3w' then 'Fourteen-day recovery: 50% mandatory uncovered topics, 25% questions on those topics, 15% older topics, 10% timed practice. Retest and timed work remain present.'
    when 'source_gap_review' then 'The roadmap does not define an exact automatic recovery rule for this missed-day range. Preserve corrections/retests and review the plan without changing stage or evidence standards.'
    when 'rebaseline_over_1mo' then 'Rebaseline this component separately: remaining weeks, must-do syllabus, prerequisites and exam-series feasibility. No overload catch-up.'
    else 'Evidence-gated plan.' end;
  v_plan_horizon:=case when v_mode='recovery_2_3w' then 14 else null end;

  update private.exam_prep_weekly_plans
    set status='superseded'
  where user_id=v_uid and component_code=p_component_code and status='active';

  select coalesce(max(plan_version),0)+1 into v_version
  from private.exam_prep_weekly_plans
  where user_id=v_uid and component_code=p_component_code and active_week_no=v_week;

  insert into private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,status,
    recovery_mode,policy_note,recovery_case_id,allocation_policy,planning_horizon_days
  ) values(
    v_uid,v_program,p_component_code,v_week,v_version,'active',
    v_mode,v_note,v_case.id,coalesce(v_policy,'{}'::jsonb),v_plan_horizon
  ) returning id into v_plan;

  if v_mode='rebaseline_over_1mo' then
    v_order:=1;
    insert into private.exam_prep_weekly_plan_items(
      plan_id,priority_order,item_type,action_code,action_payload
    ) values(
      v_plan,1,'rebaseline','REBASELINE_COMPONENT',jsonb_build_object(
        'component_code',p_component_code,
        'remaining_active_weeks',greatest(36-v_week+1,0),
        'below_l2_count',coalesce(v_case.below_l2_count,0),
        'open_correction_count',coalesce(v_case.open_correction_count,0),
        'prerequisite_blocker_count',coalesce(v_case.prerequisite_blocker_count,0),
        'exam_series_feasibility_review_required',true,
        'evidence_standards_unchanged',true
      )
    );
  end if;

  for v_corr in
    select c.id,c.skill_code,r.due_not_before
    from private.exam_prep_correction_cases c
    join private.exam_prep_retest_events r
      on r.correction_case_id=c.id and r.status in ('scheduled','authorized')
    where c.user_id=v_uid and c.component_code=p_component_code and c.status='retest_due'
    order by r.due_not_before nulls first,c.opened_at
  loop
    exit when v_order>=3;
    v_order:=v_order+1;
    insert into private.exam_prep_weekly_plan_items(
      plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload
    ) values(
      v_plan,v_order,'retest',v_corr.skill_code,v_corr.id,v_corr.due_not_before,
      'COMPLETE_DELAYED_RETEST',jsonb_build_object('preserve_in_recovery',true)
    );
  end loop;

  for v_corr in
    select c.id,c.skill_code
    from private.exam_prep_correction_cases c
    where c.user_id=v_uid and c.component_code=p_component_code
      and c.status in ('open','remediating','reopened')
    order by c.opened_at
  loop
    exit when v_order>=3;
    if not exists(
      select 1 from private.exam_prep_weekly_plan_items i
      where i.plan_id=v_plan and i.correction_case_id=v_corr.id
    ) then
      v_order:=v_order+1;
      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload
      ) values(
        v_plan,v_order,'correction',v_corr.skill_code,v_corr.id,
        'COMPLETE_CORRECTION_ANALOGUES',jsonb_build_object(
          'analogue_floor',3,'analogue_ceiling',6,'written_or_unprompted_required',true,
          'preserve_in_recovery',true
        )
      );
    end if;
  end loop;

  if v_mode='source_gap_review' and v_order<3 then
    v_order:=v_order+1;
    insert into private.exam_prep_weekly_plan_items(
      plan_id,priority_order,item_type,action_code,action_payload
    ) values(
      v_plan,v_order,'rebaseline','REVIEW_RECOVERY_PATH',jsonb_build_object(
        'source_gap',true,
        'missed_days',v_case.missed_days,
        'automatic_recovery_ratio',false,
        'automatic_stage_change',false,
        'evidence_standards_unchanged',true
      )
    );
  end if;

  if v_order<3 and v_mode in ('normal','reserve_1w','recovery_2_3w') and v_learning_dependency_green then
    for v_skill in
      select s.skill_code
      from private.exam_prep_skill_states s
      where s.user_id=v_uid and s.program_version_id=v_program and s.component_code=p_component_code
        and s.engine_version='objective_state_v1' and s.objective_level<=1
        and private.exam_prep_skill_content_ready_v1(v_program,p_component_code,s.skill_code)
        and exists(
          select 1
          from private.exam_prep_content_runway_releases rr
          join private.exam_prep_content_runway_release_skills rs
            on rs.release_id=rr.id and rs.required_for_release and rs.skill_code=s.skill_code
          where rr.program_version_id=v_program
            and rr.component_code=p_component_code
            and rr.schedule_status='active'
            and rr.active_week_from<=v_week
        )
        and exists(
          select 1
          from private.exam_prep_assessments a
          join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
          where a.component_code=p_component_code and a.assessment_type='learning' and a.status='published'
            and ai.primary_skill_code=s.skill_code
        )
      order by s.objective_level,s.skill_code
    loop
      exit when v_order>=3;
      v_order:=v_order+1;
      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,action_code,action_payload
      ) values(
        v_plan,v_order,'learning',v_skill,
        case v_mode
          when 'reserve_1w' then 'RECOVERY_RESERVE_LEARNING'
          when 'recovery_2_3w' then 'RECOVERY_MANDATORY_TOPIC'
          else 'BUILD_FIRST_COVERAGE'
        end,
        case v_mode
          when 'reserve_1w' then jsonb_build_object(
            'reserve_block',true,'move_secondary_review',true,'preserve_key_retest',true
          )
          when 'recovery_2_3w' then jsonb_build_object(
            'allocation_bucket','mandatory_uncovered_topics',
            'mandatory_uncovered_topics_pct',50,
            'questions_on_those_topics_pct',25,
            'older_topics_pct',15,
            'timed_practice_pct',10,
            'follow_learning_with_immediate_questions',true
          )
          else jsonb_build_object('component_code',p_component_code)
        end
      );
    end loop;
  end if;

  return jsonb_build_object(
    'plan_id',v_plan,
    'component_code',p_component_code,
    'active_week_no',v_week,
    'plan_version',v_version,
    'recovery_mode',v_mode,
    'planning_horizon_days',v_plan_horizon,
    'priority_count',v_order,
    'recovery_server_derived',true,
    'p1_p5_separate',true,
    'evidence_standards_unchanged',true,
    'learning_dependency_green',v_learning_dependency_green
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) to authenticated,service_role;

create or replace function private.exam_prep_mixed_assessment_eligible_v1(
  p_user_id uuid,p_component_code text,p_active_week_no smallint,p_assessment_id bigint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_assessments a
    where a.id=p_assessment_id
      and a.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and (
        select count(distinct ai.primary_skill_code)
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
      )>=2
      and (
        select count(distinct n.official_syllabus_section)
        from private.exam_prep_assessment_items ai
        join private.exam_prep_syllabus_nodes n
          on n.component_code=a.component_code and n.skill_code=ai.primary_skill_code
        where ai.assessment_id=a.id
          and n.program_version_id=(
            select program_version_id from private.exam_prep_exam_profiles where user_id=p_user_id
          )
      )>=2
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        left join private.exam_prep_skill_states s
          on s.user_id=p_user_id
          and s.component_code=p_component_code
          and s.skill_code=ai.primary_skill_code
          and s.engine_version='objective_state_v1'
        where ai.assessment_id=a.id
          and (
            s.skill_code is null
            or s.objective_level<2
            or coalesce(s.unresolved_correction_count,0)>0
          )
      )
      and exists(
        select 1
        from private.exam_prep_assessment_items ai
        join private.exam_prep_skill_states s
          on s.user_id=p_user_id
          and s.component_code=p_component_code
          and s.skill_code=ai.primary_skill_code
          and s.engine_version='objective_state_v1'
        where ai.assessment_id=a.id
          and s.hold_reason in ('mixed_transfer_missing','transfer_evidence_missing')
      )
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
          and not exists(
            select 1
            from private.exam_prep_content_runway_releases r
            join private.exam_prep_content_runway_release_skills rs
              on rs.release_id=r.id and rs.required_for_release and rs.skill_code=ai.primary_skill_code
            where r.program_version_id=(
                select program_version_id from private.exam_prep_exam_profiles where user_id=p_user_id
              )
              and r.component_code=p_component_code
              and r.schedule_status='active'
              and r.active_week_from<=p_active_week_no
          )
      )
  );
$$;
revoke all on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) to service_role;

create or replace function private.exam_prep_select_mixed_assessment_v1(
  p_user_id uuid,p_component_code text,p_active_week_no smallint
)
returns bigint
language sql
stable
security definer
set search_path=''
as $$
  select a.id
  from private.exam_prep_assessments a
  where a.component_code=p_component_code
    and a.assessment_type='mixed'
    and a.status='published'
    and private.exam_prep_mixed_assessment_eligible_v1(
      p_user_id,p_component_code,p_active_week_no,a.id
    )
  order by a.id
  limit 1;
$$;
revoke all on function private.exam_prep_select_mixed_assessment_v1(uuid,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_select_mixed_assessment_v1(uuid,text,smallint) to service_role;

create or replace function public.authorize_exam_prep_mixed_safe_v1(p_component_code text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_rule text;
  v_gate private.exam_prep_component_access_gates%rowtype;
  v_ass bigint;
  v_auth uuid;
  v_week smallint;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);

  select program_version_id,private.exam_prep_effective_active_week_v1(v_uid)
    into v_program,v_week
  from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  select rule_version into v_rule
  from private.exam_prep_placement_rule_versions
  where program_version_id=v_program and status='active';
  select * into v_gate
  from private.exam_prep_component_access_gates
  where user_id=v_uid and program_version_id=v_program
    and component_code=p_component_code and rule_version=v_rule;
  if v_gate.user_id is null or not v_gate.foundation_learning_access then
    raise exception 'exam_prep_stage0_not_complete';
  end if;

  v_ass:=private.exam_prep_select_mixed_assessment_v1(v_uid,p_component_code,v_week);
  if v_ass is null then raise exception 'exam_prep_mixed_content_not_ready'; end if;

  insert into private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) values(
    v_uid,v_ass,p_component_code,'mixed','issued',now()+interval '1 hour',
    'Core same-component mixed transfer after atomic coverage'
  ) returning id into v_auth;

  return jsonb_build_object(
    'authorization_id',v_auth,
    'assessment_id',v_ass,
    'component_code',p_component_code,
    'purpose','mixed',
    'selection_basis','covered_same_component_transfer_gap',
    'p1_p5_separate',true
  );
end;
$$;
revoke execute on function public.authorize_exam_prep_mixed_safe_v1(text) from public,anon;
grant execute on function public.authorize_exam_prep_mixed_safe_v1(text) to authenticated,service_role;

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
      select i.skill_code
      from private.exam_prep_progress_revalidation_items i
      where i.case_id=v_case.id and i.status='completed' and i.passed is false
      order by i.item_order
    loop
      continue when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.item_type in ('retest','correction')
      );
      continue when exists(
        select 1 from private.exam_prep_weekly_plan_items x
        where x.plan_id=v_plan and x.skill_code=v_failed.skill_code
          and x.action_code='RECOVERY_REFRESH_RETAINED_SKILL'
      );

      select count(*)::int into v_count from private.exam_prep_weekly_plan_items where plan_id=v_plan;
      select max(priority_order)::smallint into v_replace
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning' and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';

      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      else
        continue;
      end if;

      insert into private.exam_prep_weekly_plan_items(
        plan_id,priority_order,item_type,skill_code,action_code,action_payload
      ) values(
        v_plan,v_replace,'learning',v_failed.skill_code,'RECOVERY_REFRESH_RETAINED_SKILL',
        jsonb_build_object('progress_retained',true,'revalidation_failed',true,'academic_stage_unchanged',true)
      );
      v_applied:=v_applied+1;
    end loop;
  end if;

  -- Corrections/retests/recovery stay ahead of transfer. In a normal plan, use one slot for
  -- mixed transfer as soon as every skill in a governed mixed set already has atomic L2 coverage.
  if coalesce(v_base->>'recovery_mode','normal')='normal' then
    v_mixed_assessment:=private.exam_prep_select_mixed_assessment_v1(
      v_uid,p_component_code,v_effective_week
    );
    if v_mixed_assessment is not null then
      select assessment_key into v_mixed_key
      from private.exam_prep_assessments where id=v_mixed_assessment;

      select min(priority_order)::smallint into v_replace
      from private.exam_prep_weekly_plan_items
      where plan_id=v_plan and item_type='learning'
        and action_code<>'RECOVERY_REFRESH_RETAINED_SKILL';

      select count(*)::int into v_count
      from private.exam_prep_weekly_plan_items where plan_id=v_plan;

      if v_replace is not null then
        delete from private.exam_prep_weekly_plan_items
        where plan_id=v_plan and priority_order=v_replace;
      elsif v_count<3 then
        v_replace:=(v_count+1)::smallint;
      else
        v_replace:=null;
      end if;

      if v_replace is not null then
        insert into private.exam_prep_weekly_plan_items(
          plan_id,priority_order,item_type,skill_code,action_code,action_payload
        ) values(
          v_plan,v_replace,'mixed_transfer',null,'COMPLETE_MIXED_TRANSFER',
          jsonb_build_object(
            'assessment_id',v_mixed_assessment,
            'assessment_key',v_mixed_key,
            'component_code',p_component_code,
            'atomic_coverage_required',true,
            'same_component_only',true,
            'calendar_auto_promotion',false
          )
        );
        v_mixed_planned:=true;
      end if;
    end if;
  end if;

  return v_base || jsonb_build_object(
    'active_week_no',v_effective_week,
    'progress_retained',true,
    'revalidation_refresh_applied',(v_applied>0),
    'revalidation_refresh_count',v_applied,
    'academic_stage_changed_by_recovery',false,
    'calendar_auto_promotion',false,
    'mixed_transfer_planned',v_mixed_planned,
    'mixed_assessment_id',v_mixed_assessment
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

commit;
