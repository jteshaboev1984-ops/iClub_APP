\set ON_ERROR_STOP on
\echo 'P1-03 Stage-4 policy proposal v0 rollback matrix'

begin;

create or replace function pg_temp.stage4_trend_policy_proposal_v0(
  p_previous_unattempted_share numeric,
  p_latest_unattempted_share numeric,
  p_previous_after_time_share numeric,
  p_latest_after_time_share numeric
)
returns boolean
language plpgsql
immutable
as $$
begin
  if p_previous_unattempted_share is null
     or p_latest_unattempted_share is null
     or p_previous_after_time_share is null
     or p_latest_after_time_share is null then
    return false;
  end if;

  if p_previous_unattempted_share < 0 or p_previous_unattempted_share > 1
     or p_latest_unattempted_share < 0 or p_latest_unattempted_share > 1
     or p_previous_after_time_share < 0 or p_previous_after_time_share > 1
     or p_latest_after_time_share < 0 or p_latest_after_time_share > 1 then
    return false;
  end if;

  return p_latest_unattempted_share <= p_previous_unattempted_share
     and p_latest_after_time_share <= p_previous_after_time_share
     and (
       p_latest_unattempted_share < p_previous_unattempted_share
       or p_latest_after_time_share < p_previous_after_time_share
       or (p_latest_unattempted_share = 0 and p_latest_after_time_share = 0)
     );
end;
$$;

create or replace function pg_temp.stage4_corrective_plan_policy_proposal_v0(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text,
  p_skill_code text
)
returns boolean
language sql
stable
as $$
  select exists(
    select 1
    from private.exam_prep_correction_cases c
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.skill_code=p_skill_code
      and c.status in ('open','remediating','retest_due','reopened')
      and (
        exists(
          select 1
          from private.exam_prep_weekly_plan_items wpi
          join private.exam_prep_weekly_plans wp on wp.id=wpi.plan_id
          where wp.user_id=p_user_id
            and wp.program_version_id=p_program_version_id
            and wp.component_code=p_component_code
            and wp.status='active'
            and wpi.correction_case_id=c.id
            and wpi.skill_code=p_skill_code
            and wpi.item_type in ('correction','retest')
            and wpi.status='pending'
            and wpi.due_at is not null
        )
        or exists(
          select 1
          from private.exam_prep_retest_events r
          where r.correction_case_id=c.id
            and r.user_id=p_user_id
            and r.component_code=p_component_code
            and r.skill_code=p_skill_code
            and r.status in ('scheduled','authorized')
            and r.due_not_before is not null
        )
      )
  );
$$;

do $$
declare
  v_user uuid := '00000000-0000-4000-8000-000000001053'::uuid;
  v_program bigint;
  v_engine text;
  v_case_plan uuid;
  v_case_retest uuid;
  v_case_missing_due uuid;
  v_plan uuid;
begin
  -- Trend truth table: direction-only, score-independent, fail closed on bad inputs.
  if not pg_temp.stage4_trend_policy_proposal_v0(0.16,0.08,0.12,0.04) then
    raise exception 'P1-03 Stage-4 policy proposal: both improving should pass';
  end if;
  if pg_temp.stage4_trend_policy_proposal_v0(0.16,0.08,0.04,0.06) then
    raise exception 'P1-03 Stage-4 policy proposal: one dimension worsening must fail';
  end if;
  if pg_temp.stage4_trend_policy_proposal_v0(0.08,0.08,0.04,0.04) then
    raise exception 'P1-03 Stage-4 policy proposal: flat positive deficit must fail';
  end if;
  if not pg_temp.stage4_trend_policy_proposal_v0(0,0,0,0) then
    raise exception 'P1-03 Stage-4 policy proposal: stable zero deficit should pass';
  end if;
  if pg_temp.stage4_trend_policy_proposal_v0(null,0,0,0)
     or pg_temp.stage4_trend_policy_proposal_v0(1.1,0,0,0)
     or pg_temp.stage4_trend_policy_proposal_v0(0,0,-0.1,0) then
    raise exception 'P1-03 Stage-4 policy proposal: invalid trend input must fail closed';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  select engine_version into v_engine
  from private.exam_prep_state_engine_versions
  where status='active'
  order by created_at desc limit 1;
  if v_program is null or v_engine is null then
    raise exception 'P1-03 Stage-4 policy proposal: governed program/engine missing';
  end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage4-policy-proposal@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage4PolicyProposal','en');

  if pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P1','P1-QUA-01') then
    raise exception 'P1-03 Stage-4 policy proposal: no-case state must fail';
  end if;

  -- Open exact case alone is not an explicit plan.
  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-QUA-01','open',v_engine,'{"source":"rollback_stage4_policy_proposal"}'::jsonb
  ) returning id into v_case_plan;

  if pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P1','P1-QUA-01') then
    raise exception 'P1-03 Stage-4 policy proposal: open case without next action must fail';
  end if;

  -- Exact active weekly-plan action qualifies.
  insert into private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,status,recovery_mode,policy_note
  ) values(
    v_user,v_program,'P1',25,1,'active','normal','Rollback-only Stage-4 policy proposal fixture.'
  ) returning id into v_plan;

  insert into private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,action_code,action_payload,status
  ) values(
    v_plan,1,'correction','P1-QUA-01',v_case_plan,now()+interval '1 day',
    'stage4_policy_proposal_correction','{}'::jsonb,'pending'
  );

  if not pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P1','P1-QUA-01') then
    raise exception 'P1-03 Stage-4 policy proposal: exact active-plan linkage should pass';
  end if;
  if pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P1','P1-FUN-01')
     or pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P5','P5-DAT-01') then
    raise exception 'P1-03 Stage-4 policy proposal: component/skill firewall failed';
  end if;

  -- Exact scheduled retest with a due boundary is an alternative concrete next action.
  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-FUN-01','retest_due',v_engine,'{"source":"rollback_stage4_policy_proposal"}'::jsonb
  ) returning id into v_case_retest;

  insert into private.exam_prep_retest_events(
    correction_case_id,user_id,component_code,skill_code,status,due_not_before
  ) values(
    v_case_retest,v_user,'P1','P1-FUN-01','scheduled',now()+interval '2 days'
  );

  if not pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P1','P1-FUN-01') then
    raise exception 'P1-03 Stage-4 policy proposal: exact scheduled retest should pass';
  end if;

  -- Scheduled label without a concrete due boundary does not qualify.
  insert into private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,engine_version,reason
  ) values(
    v_user,'P1','P1-COO-01','retest_due',v_engine,'{"source":"rollback_stage4_policy_proposal"}'::jsonb
  ) returning id into v_case_missing_due;

  insert into private.exam_prep_retest_events(
    correction_case_id,user_id,component_code,skill_code,status,due_not_before
  ) values(
    v_case_missing_due,v_user,'P1','P1-COO-01','scheduled',null
  );

  if pg_temp.stage4_corrective_plan_policy_proposal_v0(v_user,v_program,'P1','P1-COO-01') then
    raise exception 'P1-03 Stage-4 policy proposal: scheduled retest without due boundary must fail';
  end if;

  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage-4 policy proposal: automatic stage ceiling moved';
  end if;

  raise notice 'P1-03 Stage-4 policy proposal v0 rollback matrix: GREEN';
end $$;

rollback;

\echo 'P1-03 Stage-4 policy proposal v0 rollback matrix: GREEN'
