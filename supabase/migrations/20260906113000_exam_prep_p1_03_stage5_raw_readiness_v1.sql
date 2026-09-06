-- P1-03 pre-live depth: raw Stage-5 Exam Readiness evidence reader.
-- This migration deliberately does NOT define Stage-5 policy, thresholds, progression,
-- or any learner-facing unlock. It only exposes governed facts required by the existing
-- Stage-5 catalog law: >=3 comparable strict attempts, last-three evidence, and open corrections.

begin;

create or replace function private.exam_prep_stage5_raw_readiness_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_engine text;
  v_stage4_deployed boolean:=false;
  v_stage4 jsonb;
  v_total_attempts int:=0;
  v_family_count int:=0;
  v_max_family_attempts int:=0;
  v_selected_family text;
  v_selected_family_attempts int:=0;
  v_last_three_count int:=0;
  v_last_three jsonb:='[]'::jsonb;
  v_denominator int:=0;
  v_l3_count int:=0;
  v_below_l3_count int:=0;
  v_unresolved_cases int:=0;
  v_unresolved_skills int:=0;
  v_reason text;
begin
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_stage5_raw_bad_component';
  end if;
  if not exists(
    select 1 from private.exam_prep_program_versions pv
    where pv.id=p_program_version_id and pv.status='active'
  ) then
    raise exception 'exam_prep_stage5_raw_program_not_active';
  end if;
  if not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_stage5_raw_user_not_found';
  end if;

  v_stage4_deployed:=to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null;
  if v_stage4_deployed then
    execute 'select private.exam_prep_stage4_exit_status_v1($1,$2,$3)'
      into v_stage4 using p_user_id,p_program_version_id,p_component_code;
  else
    v_stage4:=jsonb_build_object(
      'ready',false,
      'reason_code','stage4_policy_not_deployed',
      'stage4_unlocked',false,
      'stage5_unlocked',false
    );
  end if;

  select sev.engine_version into v_engine
  from private.exam_prep_state_engine_versions sev
  where sev.status='active'
  order by sev.created_at desc
  limit 1;
  if v_engine is null then
    raise exception 'exam_prep_stage5_raw_engine_missing';
  end if;

  with eligible as (
    select
      t.session_id,
      t.finalized_at,
      t.comparability_key,
      concat_ws('|',
        s.program_version_id::text,
        s.component_code,
        coalesce(nullif(s.timing_contract->>'paper_profile_version',''),'MISSING_PROFILE'),
        t.attempt_kind,
        t.timing_rule,
        t.comparison_scope,
        t.strict_timing::text,
        t.marks_available::text,
        t.time_limit_sec::text
      ) as family_key
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    join private.exam_prep_assessments a on a.id=t.assessment_id
    where t.user_id=p_user_id
      and t.component_code=p_component_code
      and s.user_id=p_user_id
      and s.program_version_id=p_program_version_id
      and s.component_code=p_component_code
      and s.session_type='paper'
      and s.status='finalized'
      and t.attempt_kind='full_paper'
      and t.timing_rule='official_full'
      and t.comparison_scope='full'
      and t.strict_timing
      and t.timing_comparable
      and a.status='published'
      and private.exam_prep_timed_score_comparable_v1(t.session_id)
  ), grouped as (
    select family_key,count(*)::int as attempt_count,max(finalized_at) as latest_at
    from eligible
    group by family_key
  )
  select
    (select count(*)::int from eligible),
    (select count(*)::int from grouped),
    coalesce((select max(attempt_count) from grouped),0),
    (select family_key from grouped order by attempt_count desc,latest_at desc,family_key limit 1),
    coalesce((select attempt_count from grouped order by attempt_count desc,latest_at desc,family_key limit 1),0)
  into v_total_attempts,v_family_count,v_max_family_attempts,v_selected_family,v_selected_family_attempts;

  if v_selected_family is not null then
    with eligible as (
      select
        t.session_id,
        t.finalized_at,
        t.comparability_key,
        t.marks_available,
        t.time_limit_sec,
        t.server_elapsed_sec,
        t.unattempted_marks,
        (t.objective_marks_after_time+t.objective_lost_after_time_marks+t.pending_review_after_time_marks) as after_time_marks,
        concat_ws('|',
          s.program_version_id::text,
          s.component_code,
          coalesce(nullif(s.timing_contract->>'paper_profile_version',''),'MISSING_PROFILE'),
          t.attempt_kind,
          t.timing_rule,
          t.comparison_scope,
          t.strict_timing::text,
          t.marks_available::text,
          t.time_limit_sec::text
        ) as family_key
      from private.exam_prep_timed_attempt_results t
      join private.exam_prep_sessions s on s.id=t.session_id
      join private.exam_prep_assessments a on a.id=t.assessment_id
      where t.user_id=p_user_id
        and t.component_code=p_component_code
        and s.user_id=p_user_id
        and s.program_version_id=p_program_version_id
        and s.component_code=p_component_code
        and s.session_type='paper'
        and s.status='finalized'
        and t.attempt_kind='full_paper'
        and t.timing_rule='official_full'
        and t.comparison_scope='full'
        and t.strict_timing
        and t.timing_comparable
        and a.status='published'
        and private.exam_prep_timed_score_comparable_v1(t.session_id)
    ), latest_three as (
      select *
      from eligible
      where family_key=v_selected_family
      order by finalized_at desc,session_id desc
      limit 3
    ), chronological as (
      select l.*,
             row_number() over(order by finalized_at,session_id)::int as attempt_no
      from latest_three l
    )
    select
      count(*)::int,
      coalesce(jsonb_agg(jsonb_build_object(
        'attempt_no',c.attempt_no,
        'session_id',c.session_id,
        'finalized_at',c.finalized_at,
        'comparability_key',c.comparability_key,
        'marks_available',c.marks_available,
        'time_limit_sec',c.time_limit_sec,
        'server_elapsed_sec',c.server_elapsed_sec,
        'unattempted_marks',c.unattempted_marks,
        'unattempted_share',c.unattempted_marks::numeric/nullif(c.marks_available,0),
        'after_time_marks',c.after_time_marks,
        'after_time_share',c.after_time_marks::numeric/nullif(c.marks_available,0),
        'elapsed_share',c.server_elapsed_sec::numeric/nullif(c.time_limit_sec,0)
      ) order by c.attempt_no),'[]'::jsonb)
    into v_last_three_count,v_last_three
    from chronological c;
  end if;

  select
    count(*)::int,
    count(*) filter(where coalesce(ss.objective_level,0)>=3)::int,
    count(*) filter(where coalesce(ss.objective_level,0)<3)::int
  into v_denominator,v_l3_count,v_below_l3_count
  from private.exam_prep_syllabus_nodes n
  left join private.exam_prep_skill_states ss
    on ss.user_id=p_user_id
   and ss.program_version_id=p_program_version_id
   and ss.component_code=p_component_code
   and ss.skill_code=n.skill_code
   and ss.engine_version=v_engine
  where n.program_version_id=p_program_version_id
    and n.component_code=p_component_code;

  select count(*)::int,count(distinct c.skill_code)::int
  into v_unresolved_cases,v_unresolved_skills
  from private.exam_prep_correction_cases c
  where c.user_id=p_user_id
    and c.component_code=p_component_code
    and c.status in ('open','remediating','retest_due','reopened');

  if not coalesce((v_stage4->>'ready')::boolean,false) then
    v_reason:='stage4_exit_incomplete';
  elsif v_selected_family_attempts<3 or v_last_three_count<3 then
    v_reason:='three_comparable_attempts_incomplete';
  else
    v_reason:='stage5_policy_not_deployed';
  end if;

  return jsonb_build_object(
    'reader_version','stage5_raw_readiness_v1_2026_09_06',
    'component_code',p_component_code,
    'stage4_evaluator_deployed',v_stage4_deployed,
    'stage4_exit_status',v_stage4,
    'comparable_full_attempt_count_total',v_total_attempts,
    'comparison_family_count',v_family_count,
    'max_compatible_family_attempt_count',v_max_family_attempts,
    'selected_family_key',v_selected_family,
    'selected_family_attempt_count',v_selected_family_attempts,
    'last_three_count',v_last_three_count,
    'last_three_attempts',v_last_three,
    'has_three_comparable_strict_attempts',(v_last_three_count=3),
    'canonical_skill_count',v_denominator,
    'l3_or_higher_count',v_l3_count,
    'below_l3_count',v_below_l3_count,
    'unresolved_correction_case_count',v_unresolved_cases,
    'unresolved_correction_skill_count',v_unresolved_skills,
    'last_three_trend_policy_status','not_deployed',
    'minimal_unattempted_threshold_status','not_defined_in_source_plan',
    'fundamentals_corrections_closure_policy_status','not_deployed',
    'stage5_policy_status','not_deployed',
    'stage5_ready',false,
    'stage5_unlocked',false,
    'stage6_unlocked',false,
    'reason_code',v_reason
  );
end;
$$;

revoke all on function private.exam_prep_stage5_raw_readiness_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage5_raw_readiness_v1(uuid,bigint,text) to service_role;

-- Do not install even a read-only readiness surface into a live rollout accidentally.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
  v_stage smallint;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage-5 raw reader requires fail-closed feature state';
  end if;
  select count(*)::int into v_active
  from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then
    raise exception 'P1-03 Stage-5 raw reader active entitlement residue=%',v_active;
  end if;
  select max_automatic_stage into v_stage
  from private.exam_prep_operational_stage_rules where status='active';
  if v_stage<>3 then
    raise exception 'P1-03 Stage-5 raw reader requires automatic stage ceiling=3 got=%',v_stage;
  end if;
end $$;

commit;
