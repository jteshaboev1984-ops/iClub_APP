-- P2-07: source-faithful recovery engine for interruption / late-catch-up planning.
-- Recovery changes pace and plan metadata only. It never lowers evidence standards,
-- never transfers P1/P5 mastery, never changes readiness thresholds and never changes
-- an operational stage solely because a learner was absent.
--
-- Normative source boundaries:
--   <= 1 week   -> reserve block; move secondary review; preserve key retest.
--   2-3 weeks   -> 14-day recovery; 50/25/15/10 allocation; preserve retest/timed.
--   > 1 month   -> separate P1/P5 rebaseline + exam-series feasibility review.
-- The source does NOT define a precise automatic mode for 8-13 or 22-30 missed days.
-- Those ranges therefore enter source_gap_review instead of silently borrowing a rule.

begin;

create table if not exists private.exam_prep_recovery_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  interruption_started_on date not null,
  resumed_on date not null,
  missed_days smallint not null check(missed_days between 1 and 365),
  interruption_kind text not null default 'absence'
    check(interruption_kind in ('absence','planned_holiday','other')),
  recovery_mode text not null
    check(recovery_mode in ('reserve_1w','source_gap_review','recovery_2_3w','rebaseline_over_1mo')),
  source_gap boolean not null default false,
  source_gap_note text null,
  status text not null default 'active' check(status in ('active','superseded','completed')),
  recovery_window_started_on date null,
  recovery_window_ends_on date null,
  stage_snapshot smallint null check(stage_snapshot is null or stage_snapshot between 0 and 6),
  coverage_snapshot numeric(5,2) null check(coverage_snapshot is null or coverage_snapshot between 0 and 100),
  below_l2_count integer not null default 0 check(below_l2_count>=0),
  open_correction_count integer not null default 0 check(open_correction_count>=0),
  prerequisite_blocker_count integer not null default 0 check(prerequisite_blocker_count>=0),
  plan_review_required boolean not null default false,
  feasibility_review_required boolean not null default false,
  allocation_policy jsonb not null default '{}'::jsonb,
  evidence_standards_preserved boolean not null default true check(evidence_standards_preserved is true),
  absence_stage_downgrade_allowed boolean not null default false check(absence_stage_downgrade_allowed is false),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,component_code,interruption_started_on,resumed_on),
  check(resumed_on>interruption_started_on),
  check(
    (recovery_mode='recovery_2_3w' and recovery_window_started_on is not null and recovery_window_ends_on=recovery_window_started_on+13)
    or (recovery_mode<>'recovery_2_3w' and recovery_window_ends_on is null)
  )
);

create unique index if not exists exam_prep_one_active_recovery_case_component_idx
  on private.exam_prep_recovery_cases(user_id,component_code)
  where status='active';
create index if not exists exam_prep_recovery_cases_user_history_idx
  on private.exam_prep_recovery_cases(user_id,created_at desc);

alter table private.exam_prep_recovery_cases enable row level security;
revoke all on private.exam_prep_recovery_cases from public,anon,authenticated;
grant all on private.exam_prep_recovery_cases to service_role;

drop trigger if exists exam_prep_recovery_cases_audit_v1 on private.exam_prep_recovery_cases;
create trigger exam_prep_recovery_cases_audit_v1
after insert or update or delete on private.exam_prep_recovery_cases
for each row execute function private.exam_prep_audit_row_change_v1();

-- Existing weekly-plan storage remains the same object. Add only recovery metadata.
alter table private.exam_prep_weekly_plans
  add column if not exists recovery_case_id uuid null references private.exam_prep_recovery_cases(id) on delete restrict;
alter table private.exam_prep_weekly_plans
  add column if not exists allocation_policy jsonb not null default '{}'::jsonb;
alter table private.exam_prep_weekly_plans
  add column if not exists planning_horizon_days smallint null check(planning_horizon_days is null or planning_horizon_days between 1 and 31);

alter table private.exam_prep_weekly_plans
  drop constraint if exists exam_prep_weekly_plans_recovery_mode_check;
alter table private.exam_prep_weekly_plans
  add constraint exam_prep_weekly_plans_recovery_mode_check
  check(recovery_mode in ('normal','reserve_1w','source_gap_review','recovery_2_3w','rebaseline_over_1mo'));

create or replace function private.exam_prep_recovery_mode_for_missed_days_v1(p_missed_days integer)
returns text
language plpgsql
immutable
security definer
set search_path=''
as $$
begin
  if p_missed_days is null or p_missed_days<1 then raise exception 'exam_prep_bad_missed_days'; end if;
  if p_missed_days<=7 then return 'reserve_1w'; end if;
  if p_missed_days between 14 and 21 then return 'recovery_2_3w'; end if;
  if p_missed_days>=31 then return 'rebaseline_over_1mo'; end if;
  -- 8-13 and 22-30 are deliberately not assigned to a source-defined mode.
  return 'source_gap_review';
end;
$$;
revoke all on function private.exam_prep_recovery_mode_for_missed_days_v1(integer) from public,anon,authenticated;
grant execute on function private.exam_prep_recovery_mode_for_missed_days_v1(integer) to service_role;

create or replace function private.exam_prep_recovery_policy_v1(
  p_recovery_mode text,
  p_interruption_kind text default 'absence'
)
returns jsonb
language plpgsql
immutable
security definer
set search_path=''
as $$
declare v_policy jsonb;
begin
  if p_interruption_kind not in ('absence','planned_holiday','other') then raise exception 'exam_prep_bad_interruption_kind'; end if;

  v_policy:=case p_recovery_mode
    when 'reserve_1w' then jsonb_build_object(
      'source_rule','up_to_one_week',
      'reserve_block',true,
      'move_secondary_review',true,
      'preserve_key_retest',true,
      'rebuild_entire_plan',false,
      'automatic_stage_downgrade',false,
      'evidence_standards_unchanged',true
    )
    when 'recovery_2_3w' then jsonb_build_object(
      'source_rule','two_to_three_weeks',
      'recovery_horizon_days',14,
      'allocation',jsonb_build_object(
        'mandatory_uncovered_topics_pct',50,
        'questions_on_those_topics_pct',25,
        'older_topics_pct',15,
        'timed_practice_pct',10
      ),
      'preserve_retest',true,
      'preserve_timed_practice',true,
      'max_blockers',3,
      'reduce_low_value_work',true,
      'temporarily_pause',jsonb_build_array(
        'decorative_notes','additional_courses','optional_hard_questions','low_priority_prep_projects'
      ),
      'automatic_stage_downgrade',false,
      'evidence_standards_unchanged',true
    )
    when 'rebaseline_over_1mo' then jsonb_build_object(
      'source_rule','over_one_month',
      'recalculate_remaining_weeks',true,
      'identify_must_do_syllabus',true,
      'identify_prerequisites',true,
      'component_rebaseline_required',true,
      'exam_series_feasibility_review_required',true,
      'reduce_passive_learning',true,
      'short_learning_then_immediate_practice',true,
      'sleep_debt_catch_up_prohibited',true,
      'automatic_stage_downgrade',false,
      'evidence_standards_unchanged',true
    )
    when 'source_gap_review' then jsonb_build_object(
      'source_rule','exact_range_not_defined_in_source',
      'source_gap',true,
      'undefined_ranges_days',jsonb_build_array('8-13','22-30'),
      'plan_review_required',true,
      'preserve_corrections_and_retests',true,
      'automatic_recovery_ratio',false,
      'automatic_stage_change',false,
      'evidence_standards_unchanged',true
    )
    else raise exception 'exam_prep_bad_recovery_mode'
  end;

  if p_interruption_kind='planned_holiday' then
    v_policy:=v_policy || jsonb_build_object(
      'planned_holiday',true,
      'holiday_is_reserve_not_bulk_content_sprint',true,
      'genuine_rest_days_required',true
    );
  end if;
  return v_policy;
end;
$$;
revoke all on function private.exam_prep_recovery_policy_v1(text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_recovery_policy_v1(text,text) to service_role;

create or replace function public.record_my_exam_prep_interruption_v1(
  p_interruption_started_on date,
  p_resumed_on date,
  p_interruption_kind text default 'absence'
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_engine text;
  v_days integer;
  v_mode text;
  v_policy jsonb;
  v_component text;
  v_stage smallint;
  v_coverage numeric;
  v_below_l2 integer;
  v_open_corrections integer;
  v_prereq_blockers integer;
  v_case uuid;
  v_cases jsonb:='[]'::jsonb;
  v_gap boolean;
  v_gap_note text;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_interruption_kind not in ('absence','planned_holiday','other') then raise exception 'exam_prep_bad_interruption_kind'; end if;
  if p_interruption_started_on is null or p_resumed_on is null or p_resumed_on<=p_interruption_started_on then
    raise exception 'exam_prep_bad_interruption_dates';
  end if;
  if p_resumed_on>current_date then raise exception 'exam_prep_future_resume_not_allowed'; end if;
  v_days:=p_resumed_on-p_interruption_started_on;
  if v_days<1 or v_days>365 then raise exception 'exam_prep_bad_missed_days'; end if;

  select program_version_id into v_program
  from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  select engine_version into v_engine
  from private.exam_prep_state_engine_versions
  where status='active'
  order by created_at desc limit 1;
  if v_engine is null then raise exception 'exam_prep_state_engine_missing'; end if;

  v_mode:=private.exam_prep_recovery_mode_for_missed_days_v1(v_days);
  v_policy:=private.exam_prep_recovery_policy_v1(v_mode,p_interruption_kind);
  v_gap:=(v_mode='source_gap_review');
  v_gap_note:=case when v_gap then
    'The approved roadmap defines <=1 week, 2-3 weeks and >1 month, but does not define a precise automatic recovery rule for this missed-day range. Planning review is required; evidence standards and stages remain unchanged.'
    else null end;

  foreach v_component in array array['P1','P5'] loop
    select ss.operational_stage,ss.coverage_pct
      into v_stage,v_coverage
    from private.exam_prep_stage_states ss
    where ss.user_id=v_uid and ss.program_version_id=v_program and ss.component_code=v_component and ss.engine_version=v_engine
    order by ss.derived_at desc limit 1;

    select count(*)::int into v_below_l2
    from private.exam_prep_syllabus_nodes n
    left join private.exam_prep_skill_states s
      on s.user_id=v_uid and s.program_version_id=v_program and s.component_code=v_component
      and s.skill_code=n.skill_code and s.engine_version=v_engine
    where n.program_version_id=v_program and n.component_code=v_component
      and coalesce(s.objective_level,0)<2;

    select count(*)::int into v_open_corrections
    from private.exam_prep_correction_cases c
    where c.user_id=v_uid and c.component_code=v_component
      and c.status in ('open','remediating','retest_due','reopened');

    select count(distinct ps.prerequisite_code)::int into v_prereq_blockers
    from private.exam_prep_prerequisite_states ps
    where ps.user_id=v_uid and ps.program_version_id=v_program and ps.status in ('blocker','retest_needed')
      and exists(
        select 1 from private.exam_prep_prerequisite_edges pe
        where pe.program_version_id=v_program and pe.from_node_code=ps.prerequisite_code
          and pe.target_component_code=v_component and pe.is_mastery_crediting=false
      );

    update private.exam_prep_recovery_cases
      set status='superseded',updated_at=now()
    where user_id=v_uid and component_code=v_component and status='active'
      and (interruption_started_on,resumed_on) is distinct from (p_interruption_started_on,p_resumed_on);

    insert into private.exam_prep_recovery_cases(
      user_id,program_version_id,component_code,interruption_started_on,resumed_on,missed_days,
      interruption_kind,recovery_mode,source_gap,source_gap_note,status,
      recovery_window_started_on,recovery_window_ends_on,stage_snapshot,coverage_snapshot,
      below_l2_count,open_correction_count,prerequisite_blocker_count,
      plan_review_required,feasibility_review_required,allocation_policy,
      evidence_standards_preserved,absence_stage_downgrade_allowed,updated_at
    ) values(
      v_uid,v_program,v_component,p_interruption_started_on,p_resumed_on,v_days,
      p_interruption_kind,v_mode,v_gap,v_gap_note,'active',
      case when v_mode='recovery_2_3w' then current_date else null end,
      case when v_mode='recovery_2_3w' then current_date+13 else null end,
      coalesce(v_stage,0),coalesce(v_coverage,0),coalesce(v_below_l2,0),coalesce(v_open_corrections,0),coalesce(v_prereq_blockers,0),
      v_mode='source_gap_review',v_mode='rebaseline_over_1mo',v_policy,true,false,now()
    )
    on conflict(user_id,component_code,interruption_started_on,resumed_on) do update set
      program_version_id=excluded.program_version_id,missed_days=excluded.missed_days,
      interruption_kind=excluded.interruption_kind,recovery_mode=excluded.recovery_mode,
      source_gap=excluded.source_gap,source_gap_note=excluded.source_gap_note,status='active',
      recovery_window_started_on=excluded.recovery_window_started_on,recovery_window_ends_on=excluded.recovery_window_ends_on,
      stage_snapshot=excluded.stage_snapshot,coverage_snapshot=excluded.coverage_snapshot,
      below_l2_count=excluded.below_l2_count,open_correction_count=excluded.open_correction_count,
      prerequisite_blocker_count=excluded.prerequisite_blocker_count,
      plan_review_required=excluded.plan_review_required,feasibility_review_required=excluded.feasibility_review_required,
      allocation_policy=excluded.allocation_policy,evidence_standards_preserved=true,
      absence_stage_downgrade_allowed=false,updated_at=now()
    returning id into v_case;

    v_cases:=v_cases || jsonb_build_array(jsonb_build_object(
      'component_code',v_component,
      'recovery_mode',v_mode,
      'missed_days',v_days,
      'source_gap',v_gap,
      'recovery_window_ends_on',case when v_mode='recovery_2_3w' then current_date+13 else null end,
      'plan_review_required',v_mode='source_gap_review',
      'feasibility_review_required',v_mode='rebaseline_over_1mo',
      'stage_snapshot',coalesce(v_stage,0),
      'coverage_snapshot',coalesce(v_coverage,0),
      'below_l2_count',coalesce(v_below_l2,0),
      'open_correction_count',coalesce(v_open_corrections,0),
      'prerequisite_blocker_count',coalesce(v_prereq_blockers,0),
      'allocation_policy',v_policy,
      'evidence_standards_unchanged',true,
      'stage_changed_by_recovery',false
    ));
  end loop;

  return jsonb_build_object(
    'missed_days',v_days,
    'interruption_kind',p_interruption_kind,
    'recovery_mode',v_mode,
    'source_gap',v_gap,
    'components',v_cases,
    'p1_p5_separate',true,
    'evidence_standards_unchanged',true,
    'stage_changed_by_recovery',false
  );
end;
$$;
revoke execute on function public.record_my_exam_prep_interruption_v1(date,date,text) from public,anon;
grant execute on function public.record_my_exam_prep_interruption_v1(date,date,text) to authenticated,service_role;

create or replace function public.get_exam_prep_recovery_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_case private.exam_prep_recovery_cases%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_case
  from private.exam_prep_recovery_cases
  where user_id=v_uid and component_code=p_component_code and status='active'
  order by created_at desc limit 1;

  if v_case.id is null then
    return jsonb_build_object(
      'component_code',p_component_code,
      'active',false,
      'recovery_mode','normal',
      'evidence_standards_unchanged',true,
      'stage_changed_by_recovery',false
    );
  end if;

  return jsonb_build_object(
    'component_code',v_case.component_code,
    'active',true,
    'interruption_kind',v_case.interruption_kind,
    'missed_days',v_case.missed_days,
    'recovery_mode',v_case.recovery_mode,
    'source_gap',v_case.source_gap,
    'plan_review_required',v_case.plan_review_required,
    'feasibility_review_required',v_case.feasibility_review_required,
    'recovery_window_started_on',v_case.recovery_window_started_on,
    'recovery_window_ends_on',v_case.recovery_window_ends_on,
    'stage_snapshot',v_case.stage_snapshot,
    'coverage_snapshot',v_case.coverage_snapshot,
    'below_l2_count',v_case.below_l2_count,
    'open_correction_count',v_case.open_correction_count,
    'prerequisite_blocker_count',v_case.prerequisite_blocker_count,
    'allocation_policy',v_case.allocation_policy,
    'evidence_standards_unchanged',v_case.evidence_standards_preserved,
    'stage_changed_by_recovery',v_case.absence_stage_downgrade_allowed,
    'p1_p5_separate',true
  );
end;
$$;
revoke execute on function public.get_exam_prep_recovery_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_recovery_safe_v1(text) to authenticated,service_role;

-- Server-derived weekly plan. The browser no longer chooses recovery mode.
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
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id,active_week_no into v_program,v_week
  from private.exam_prep_exam_profiles where user_id=v_uid;
  if v_program is null or v_week<1 then raise exception 'exam_prep_profile_required'; end if;

  -- Refresh academic projections exactly as the pre-existing weekly planner already does.
  -- Recovery itself never writes a stage/skill/readiness value.
  perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);
  perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);

  select coalesce(p.stage0_complete,false) into v_stage0
  from private.exam_prep_component_placements p
  where p.user_id=v_uid and p.program_version_id=v_program and p.component_code=p_component_code
  order by p.derived_at desc limit 1;
  if not coalesce(v_stage0,false) then raise exception 'exam_prep_stage0_required_before_weekly_plan'; end if;

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

  -- >1 month: the first priority is a component-specific rebaseline. Existing evidence is retained.
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

  -- Due delayed retests are never discarded by recovery.
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

  -- Open corrective cycles remain above ordinary new content.
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

  -- Undefined source ranges do not receive an invented automatic ratio or a silent fast-track.
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

  -- Ordinary / <=1-week / 2-3-week plans may add governed learning after higher-value corrective work.
  if v_order<3 and v_mode in ('normal','reserve_1w','recovery_2_3w') then
    for v_skill in
      select s.skill_code
      from private.exam_prep_skill_states s
      where s.user_id=v_uid and s.program_version_id=v_program and s.component_code=p_component_code
        and s.engine_version='objective_state_v1' and s.objective_level<=1
        and private.exam_prep_skill_runway_ready_for_week_v1(v_program,p_component_code,s.skill_code,v_week)
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
    'evidence_standards_unchanged',true
  );
end;
$$;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) to authenticated,service_role;

create or replace function public.get_exam_prep_weekly_plan_safe_v2(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_recovery private.exam_prep_recovery_cases%rowtype;
  v_items jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_plan
  from private.exam_prep_weekly_plans
  where user_id=v_uid and component_code=p_component_code and status='active'
  order by generated_at desc limit 1;

  if v_plan.id is null then
    return jsonb_build_object(
      'component_code',p_component_code,'plan',null,'items','[]'::jsonb,
      'recovery',jsonb_build_object('active',false,'recovery_mode','normal')
    );
  end if;

  if v_plan.recovery_case_id is not null then
    select * into v_recovery
    from private.exam_prep_recovery_cases
    where id=v_plan.recovery_case_id and user_id=v_uid and component_code=p_component_code;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'priority_order',i.priority_order,
    'item_type',i.item_type,
    'skill_code',i.skill_code,
    'correction_case_id',i.correction_case_id,
    'due_at',i.due_at,
    'action_code',i.action_code,
    'action_payload',i.action_payload,
    'status',i.status
  ) order by i.priority_order),'[]'::jsonb)
  into v_items
  from private.exam_prep_weekly_plan_items i
  where i.plan_id=v_plan.id;

  return jsonb_build_object(
    'plan_id',v_plan.id,
    'component_code',v_plan.component_code,
    'active_week_no',v_plan.active_week_no,
    'plan_version',v_plan.plan_version,
    'recovery_mode',v_plan.recovery_mode,
    'policy_note',v_plan.policy_note,
    'planning_horizon_days',v_plan.planning_horizon_days,
    'allocation_policy',v_plan.allocation_policy,
    'recovery',case when v_recovery.id is null then jsonb_build_object(
      'active',false,'recovery_mode','normal'
    ) else jsonb_build_object(
      'active',v_recovery.status='active',
      'missed_days',v_recovery.missed_days,
      'recovery_mode',v_recovery.recovery_mode,
      'source_gap',v_recovery.source_gap,
      'plan_review_required',v_recovery.plan_review_required,
      'feasibility_review_required',v_recovery.feasibility_review_required,
      'recovery_window_ends_on',v_recovery.recovery_window_ends_on,
      'allocation_policy',v_recovery.allocation_policy,
      'evidence_standards_unchanged',true,
      'stage_changed_by_recovery',false
    ) end,
    'items',v_items
  );
end;
$$;
revoke execute on function public.get_exam_prep_weekly_plan_safe_v2(text) from public,anon;
grant execute on function public.get_exam_prep_weekly_plan_safe_v2(text) to authenticated,service_role;

-- Release guards: recovery is planning-only and must not alter the current controlled-beta capability boundary.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_approved int;
begin
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then
    raise exception 'P2-07 recovery release: Core-only controlled-beta boundary drift';
  end if;
  select count(*) into v_approved from private.exam_prep_stage5_thresholds where status='approved';
  if v_approved<>0 then raise exception 'P2-07 recovery release must not create/approve Stage-5 readiness thresholds'; end if;
  if exists(
    select 1 from information_schema.role_table_grants
    where table_schema='private' and table_name='exam_prep_recovery_cases' and grantee in ('anon','authenticated')
  ) then raise exception 'P2-07 recovery cases exposed directly'; end if;
end $$;

commit;
