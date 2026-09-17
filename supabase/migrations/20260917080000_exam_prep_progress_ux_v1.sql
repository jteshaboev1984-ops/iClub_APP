-- PROPOSED, ADDITIVE ONLY: stable weekly presentation goals.
-- DO NOT apply to production before independent SQL/rollback/RLS verification.
-- Never changes the academic planner, mastery, history, Practice or Tours.
begin;

create table if not exists private.exam_prep_weekly_goal_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check (component_code in ('P1','P5')),
  active_week_no smallint not null check (active_week_no between 1 and 36),
  priority_order smallint not null check (priority_order between 1 and 3),
  source_plan_id uuid not null references private.exam_prep_weekly_plans(id) on delete restrict,
  item_type text not null,
  skill_code text,
  correction_case_id uuid references private.exam_prep_correction_cases(id) on delete restrict,
  action_code text not null,
  assessment_id bigint,
  created_at timestamptz not null default now(),
  unique (user_id,program_version_id,component_code,active_week_no,priority_order)
);
create index if not exists exam_prep_weekly_goal_snapshots_scope_idx
  on private.exam_prep_weekly_goal_snapshots(user_id,component_code,active_week_no);
alter table private.exam_prep_weekly_goal_snapshots enable row level security;
revoke all on table private.exam_prep_weekly_goal_snapshots from public,anon,authenticated;
grant all on table private.exam_prep_weekly_goal_snapshots to service_role;

-- Explicit mutation: snapshot first available plan only; repeat calls do nothing.
-- This function writes ONLY the new private snapshot table.
create or replace function public.ensure_exam_prep_weekly_goals_safe_v1(p_component_code text)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_source uuid;
  v_created int := 0;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select p.program_version_id,private.exam_prep_effective_active_week_v1(v_uid)
    into v_program,v_week
  from private.exam_prep_exam_profiles p where p.user_id=v_uid;
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  perform pg_advisory_xact_lock(hashtextextended('ep_progress_ux_v1:'||v_uid::text||':'||p_component_code||':'||v_week::text,0));
  -- The earliest surviving populated historical plan anchors this week. It cannot
  -- be shifted by later regenerations; snapshots are insert-only by this API.
  select p.id into v_source
  from private.exam_prep_weekly_plans p
  where p.user_id=v_uid and p.program_version_id=v_program
    and p.component_code=p_component_code and p.active_week_no=v_week
    and exists(select 1 from private.exam_prep_weekly_plan_items i where i.plan_id=p.id)
  order by p.generated_at,p.id limit 1;
  if v_source is null then
    return jsonb_build_object('contract_version','progress_ux_v1','component_code',p_component_code,
      'active_week_no',v_week,'plan_available',false,'created',0);
  end if;

  insert into private.exam_prep_weekly_goal_snapshots
    (user_id,program_version_id,component_code,active_week_no,priority_order,
     source_plan_id,item_type,skill_code,correction_case_id,action_code,assessment_id)
  select v_uid,v_program,p_component_code,v_week,i.priority_order,
    v_source,i.item_type,i.skill_code,i.correction_case_id,i.action_code,
    case when coalesce(i.action_payload->>'assessment_id','') ~ '^[0-9]+$'
         then (i.action_payload->>'assessment_id')::bigint else null end
  from private.exam_prep_weekly_plan_items i where i.plan_id=v_source
  order by i.priority_order
  on conflict (user_id,program_version_id,component_code,active_week_no,priority_order)
  do nothing;
  get diagnostics v_created = row_count;
  return jsonb_build_object('contract_version','progress_ux_v1','component_code',p_component_code,
    'active_week_no',v_week,'plan_available',true,'created',v_created);
end;
$function$;
revoke execute on function public.ensure_exam_prep_weekly_goals_safe_v1(text) from public,anon;
grant execute on function public.ensure_exam_prep_weekly_goals_safe_v1(text) to authenticated,service_role;

-- Pure projection: neither this function nor its queries mutate goal/evidence data.
-- The latest planner only supplies actionable bindings; all goal identity is frozen.
create or replace function public.get_exam_prep_weekly_progress_safe_v1(p_component_code text)
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_goals jsonb;
  v_done int;
  v_sessions int;
  v_corrections int;
  v_skills int;
  v_coverage numeric;
  v_has_plan boolean;
begin
  v_uid := private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  select p.program_version_id,private.exam_prep_effective_active_week_v1(v_uid)
    into v_program,v_week
  from private.exam_prep_exam_profiles p where p.user_id=v_uid;
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  select exists(
    select 1 from private.exam_prep_weekly_goal_snapshots g
    where g.user_id=v_uid and g.program_version_id=v_program
      and g.component_code=p_component_code and g.active_week_no=v_week
  ) into v_has_plan;

  select count(distinct s.id)::int into v_sessions
  from private.exam_prep_sessions s
  join private.exam_prep_session_authorizations a on a.id=s.authorization_id
    and a.user_id=v_uid and a.component_code=p_component_code and a.academic_credit=true
  where s.user_id=v_uid and s.component_code=p_component_code and s.status='finalized'
    and s.session_type in ('learning','mixed','retest');

  select count(*)::int into v_corrections
  from private.exam_prep_correction_cases c
  where c.user_id=v_uid and c.component_code=p_component_code
    and c.status in ('open','remediating','retest_due','reopened');

  select count(*)::int into v_skills
  from private.exam_prep_skill_states st
  where st.user_id=v_uid and st.program_version_id=v_program
    and st.component_code=p_component_code and st.engine_version='objective_state_v1'
    and st.coverage_confirmed;

  select ss.coverage_pct into v_coverage from private.exam_prep_stage_states ss
  where ss.user_id=v_uid and ss.program_version_id=v_program
    and ss.component_code=p_component_code and ss.engine_version='objective_state_v1'
  order by ss.derived_at desc limit 1;

  with g as (
    select * from private.exam_prep_weekly_goal_snapshots
    where user_id=v_uid and program_version_id=v_program
      and component_code=p_component_code and active_week_no=v_week
  ),
  activity as (
    select g.*,coalesce(hist.n,0)::int as activity_count,
      coalesce(hist.remediation_done,false) as remediation_done,
      c.status as correction_status,
      current_item.priority_order as actionable_order,
      coalesce(retest.due_at,current_item.due_at) as due_at
    from g
    left join private.exam_prep_correction_cases c on c.id=g.correction_case_id
      and c.user_id=v_uid and c.component_code=p_component_code
    left join lateral (
      select count(distinct ses.id)::int as n,
        coalesce(bool_or(ca.action_type='remediation_completed'),false) as remediation_done
      from private.exam_prep_weekly_plans ph
      join private.exam_prep_weekly_plan_items hi on hi.plan_id=ph.id
      join private.exam_prep_session_authorizations a
        on a.plan_id=ph.id and a.plan_priority_order=hi.priority_order
        and a.user_id=v_uid and a.component_code=p_component_code and a.academic_credit=true
      join private.exam_prep_sessions ses on ses.authorization_id=a.id
        and ses.user_id=v_uid and ses.component_code=p_component_code and ses.status='finalized'
      left join private.exam_prep_correction_actions ca
        on ca.session_id=ses.id and ca.correction_case_id=g.correction_case_id
        and ca.action_type='remediation_completed'
      where ph.user_id=v_uid and ph.program_version_id=v_program
        and ph.component_code=p_component_code and ph.active_week_no=v_week
        and hi.item_type=g.item_type
        and (
          (g.correction_case_id is not null and hi.correction_case_id=g.correction_case_id)
          or (g.correction_case_id is null and hi.correction_case_id is null and
              ((g.item_type='mixed_transfer' and g.assessment_id is not null
                and hi.action_payload->>'assessment_id'=g.assessment_id::text)
               or (g.item_type<>'mixed_transfer' and hi.skill_code is not distinct from g.skill_code)))
        )
    ) hist on true
    left join lateral (
      select i.priority_order,i.due_at
      from private.exam_prep_weekly_plans p
      join private.exam_prep_weekly_plan_items i on i.plan_id=p.id
      where p.user_id=v_uid and p.program_version_id=v_program
        and p.component_code=p_component_code and p.active_week_no=v_week
        and p.status='active' and i.status='pending'
        and (i.item_type=g.item_type or
             (g.item_type='correction' and i.item_type='retest' and g.correction_case_id is not null))
        and (
          (g.correction_case_id is not null and i.correction_case_id=g.correction_case_id)
          or (g.correction_case_id is null and i.correction_case_id is null and
              ((g.item_type='mixed_transfer' and g.assessment_id is not null
                and i.action_payload->>'assessment_id'=g.assessment_id::text)
               or (g.item_type<>'mixed_transfer' and i.skill_code is not distinct from g.skill_code)))
        )
      order by p.generated_at desc,i.priority_order limit 1
    ) current_item on true
    left join lateral (
      select min(r.due_not_before) as due_at from private.exam_prep_retest_events r
      where r.correction_case_id=g.correction_case_id and r.user_id=v_uid
        and r.component_code=p_component_code and r.status in ('scheduled','authorized')
    ) retest on g.correction_case_id is not null
  ),
  determined as (
    select activity.*,
      (case when item_type='correction' then remediation_done
        when item_type in ('retest','learning','mixed_transfer') then activity_count>0
        else false end) as weekly_complete,
      case
        when item_type='correction' and remediation_done and correction_status='reopened' then 'needs_rework'
        when item_type='correction' and remediation_done and correction_status='resolved' then 'completed'
        when item_type='correction' and remediation_done then 'waiting_retest'
        when item_type='retest' and activity_count>0 and correction_status='reopened' then 'needs_rework'
        when item_type in ('retest','learning','mixed_transfer') and activity_count>0 then 'completed'
        when activity_count>0 then 'in_progress'
        when actionable_order is null then 'paused'
        else 'not_started'
      end as goal_status
    from activity
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'goal_id',id::text,'component_code',component_code,'priority_order',priority_order,
    'status',goal_status,'weekly_commitment_complete',weekly_complete,
    'correction_open',coalesce(correction_status in ('open','remediating','retest_due','reopened'),false),
    'finalized_sessions',activity_count,'action_priority_order',actionable_order,
    'retest_due_at',due_at,'item_type',item_type,'skill_code',skill_code,
    'plan_changed',(actionable_order is null and not weekly_complete),
    'change_reason',case when actionable_order is null and not weekly_complete
      then 'priority_displaced_by_replanning' else null end
  ) order by priority_order),'[]'::jsonb),
  count(*) filter(where weekly_complete)::int
  into v_goals,v_done from determined;

  return jsonb_build_object(
    'contract_version','progress_ux_v1','component_code',p_component_code,
    'active_week_no',v_week,'plan_available',v_has_plan,
    'goals',v_goals,'completed_goals',coalesce(v_done,0),
    'finalized_study_sessions',coalesce(v_sessions,0),
    'open_corrections',coalesce(v_corrections,0),
    'confirmed_skills',v_skills,'coverage_pct',v_coverage
  );
end;
$function$;
revoke execute on function public.get_exam_prep_weekly_progress_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_weekly_progress_safe_v1(text) to authenticated,service_role;

commit;
