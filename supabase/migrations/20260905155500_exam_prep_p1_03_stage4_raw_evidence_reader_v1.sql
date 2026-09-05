-- P1-03 Stage-4 raw evidence reader.
-- Read-only facts only: this function cannot approve Stage-4 policy or unlock/promote a learner.
-- Comparison families use immutable paper-profile/timing conditions, not exact form keys.
begin;

create or replace function private.exam_prep_stage4_raw_evidence_v1(
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
  v_stage3 jsonb;
  v_engine text;
  v_total_attempts int:=0;
  v_exact_forms int:=0;
  v_family_count int:=0;
  v_max_family_attempts int:=0;
  v_families jsonb:='[]'::jsonb;
  v_denominator int:=0;
  v_l3_count int:=0;
  v_below_l3_count int:=0;
  v_below_l3 jsonb:='[]'::jsonb;
begin
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_stage4_raw_bad_component';
  end if;
  if not exists(
    select 1 from private.exam_prep_program_versions pv
    where pv.id=p_program_version_id and pv.status='active'
  ) then
    raise exception 'exam_prep_stage4_raw_program_not_active';
  end if;
  if not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_stage4_raw_user_not_found';
  end if;

  v_stage3:=private.exam_prep_stage3_exit_status_v1(p_user_id,p_program_version_id,p_component_code);

  select sev.engine_version into v_engine
  from private.exam_prep_state_engine_versions sev
  where sev.status='active'
  order by sev.created_at desc
  limit 1;
  if v_engine is null then
    raise exception 'exam_prep_stage4_raw_engine_missing';
  end if;

  with eligible as (
    select
      t.session_id,
      t.finalized_at,
      t.comparability_key,
      coalesce(nullif(s.timing_contract->>'paper_profile_version',''),'MISSING_PROFILE') as paper_profile_version,
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
      ) as family_key,
      t.unattempted_marks::numeric/nullif(t.marks_available,0) as unattempted_share,
      (t.objective_marks_after_time+t.objective_lost_after_time_marks+t.pending_review_after_time_marks)::numeric/nullif(t.marks_available,0) as after_time_share,
      t.server_elapsed_sec::numeric/nullif(t.time_limit_sec,0) as elapsed_share
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
  ), ranked as (
    select e.*,
           row_number() over(partition by e.family_key order by e.finalized_at desc,e.session_id) as rn
    from eligible e
  ), grouped as (
    select
      r.family_key,
      max(r.paper_profile_version) as paper_profile_version,
      count(*)::int as attempt_count,
      count(distinct r.comparability_key)::int as exact_form_count,
      array_agg(distinct r.comparability_key order by r.comparability_key) as exact_form_keys,
      max(r.finalized_at) filter(where r.rn=1) as latest_at,
      max(r.finalized_at) filter(where r.rn=2) as previous_at,
      max(r.unattempted_share) filter(where r.rn=1) as latest_unattempted_share,
      max(r.unattempted_share) filter(where r.rn=2) as previous_unattempted_share,
      max(r.after_time_share) filter(where r.rn=1) as latest_after_time_share,
      max(r.after_time_share) filter(where r.rn=2) as previous_after_time_share,
      max(r.elapsed_share) filter(where r.rn=1) as latest_elapsed_share,
      max(r.elapsed_share) filter(where r.rn=2) as previous_elapsed_share
    from ranked r
    group by r.family_key
  )
  select
    (select count(*)::int from eligible),
    (select count(distinct comparability_key)::int from eligible),
    (select count(*)::int from grouped),
    coalesce((select max(attempt_count) from grouped),0),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'family_key',g.family_key,
          'paper_profile_version',g.paper_profile_version,
          'attempt_count',g.attempt_count,
          'exact_form_count',g.exact_form_count,
          'exact_form_keys',to_jsonb(g.exact_form_keys),
          'latest_at',g.latest_at,
          'previous_at',g.previous_at,
          'latest_unattempted_share',g.latest_unattempted_share,
          'previous_unattempted_share',g.previous_unattempted_share,
          'unattempted_share_delta',case when g.previous_unattempted_share is null then null else g.latest_unattempted_share-g.previous_unattempted_share end,
          'latest_after_time_share',g.latest_after_time_share,
          'previous_after_time_share',g.previous_after_time_share,
          'after_time_share_delta',case when g.previous_after_time_share is null then null else g.latest_after_time_share-g.previous_after_time_share end,
          'latest_elapsed_share',g.latest_elapsed_share,
          'previous_elapsed_share',g.previous_elapsed_share,
          'elapsed_share_delta',case when g.previous_elapsed_share is null then null else g.latest_elapsed_share-g.previous_elapsed_share end
        )
        order by g.attempt_count desc,g.latest_at desc,g.family_key
      ) from grouped g
    ),'[]'::jsonb)
  into v_total_attempts,v_exact_forms,v_family_count,v_max_family_attempts,v_families;

  with canonical as (
    select n.skill_code,coalesce(ss.objective_level,0)::int as objective_level
    from private.exam_prep_syllabus_nodes n
    left join private.exam_prep_skill_states ss
      on ss.user_id=p_user_id
     and ss.program_version_id=p_program_version_id
     and ss.component_code=p_component_code
     and ss.skill_code=n.skill_code
     and ss.engine_version=v_engine
    where n.program_version_id=p_program_version_id
      and n.component_code=p_component_code
  ), below as (
    select * from canonical where objective_level<3
  ), detail as (
    select
      b.skill_code,
      b.objective_level,
      (select count(*)::int
       from private.exam_prep_correction_cases c
       where c.user_id=p_user_id and c.component_code=p_component_code and c.skill_code=b.skill_code
         and c.status in ('open','remediating','retest_due','reopened')) as active_correction_cases,
      (select count(*)::int
       from private.exam_prep_correction_cases c
       join private.exam_prep_weekly_plan_items wpi on wpi.correction_case_id=c.id
       join private.exam_prep_weekly_plans wp on wp.id=wpi.plan_id
       where c.user_id=p_user_id and c.component_code=p_component_code and c.skill_code=b.skill_code
         and c.status in ('open','remediating','retest_due','reopened')
         and wp.user_id=p_user_id and wp.program_version_id=p_program_version_id and wp.component_code=p_component_code and wp.status='active'
         and wpi.skill_code=b.skill_code and wpi.item_type in ('correction','retest') and wpi.status='pending') as pending_plan_actions,
      (select count(*)::int
       from private.exam_prep_correction_cases c
       join private.exam_prep_weekly_plan_items wpi on wpi.correction_case_id=c.id
       join private.exam_prep_weekly_plans wp on wp.id=wpi.plan_id
       where c.user_id=p_user_id and c.component_code=p_component_code and c.skill_code=b.skill_code
         and c.status in ('open','remediating','retest_due','reopened')
         and wp.user_id=p_user_id and wp.program_version_id=p_program_version_id and wp.component_code=p_component_code and wp.status='active'
         and wpi.skill_code=b.skill_code and wpi.item_type in ('correction','retest') and wpi.status='pending' and wpi.due_at is not null) as pending_plan_actions_with_due,
      (select count(*)::int
       from private.exam_prep_correction_cases c
       join private.exam_prep_retest_events r on r.correction_case_id=c.id
       where c.user_id=p_user_id and c.component_code=p_component_code and c.skill_code=b.skill_code
         and c.status in ('open','remediating','retest_due','reopened')
         and r.user_id=p_user_id and r.component_code=p_component_code and r.skill_code=b.skill_code
         and r.status in ('scheduled','authorized')) as scheduled_retests,
      (select count(*)::int
       from private.exam_prep_correction_cases c
       join private.exam_prep_retest_events r on r.correction_case_id=c.id
       where c.user_id=p_user_id and c.component_code=p_component_code and c.skill_code=b.skill_code
         and c.status in ('open','remediating','retest_due','reopened')
         and r.user_id=p_user_id and r.component_code=p_component_code and r.skill_code=b.skill_code
         and r.status in ('scheduled','authorized') and r.due_not_before is not null) as scheduled_retests_with_due
    from below b
  )
  select
    (select count(*)::int from canonical),
    (select count(*)::int from canonical where objective_level>=3),
    (select count(*)::int from below),
    coalesce((select jsonb_agg(jsonb_build_object(
      'skill_code',d.skill_code,
      'objective_level',d.objective_level,
      'active_correction_cases',d.active_correction_cases,
      'pending_plan_actions',d.pending_plan_actions,
      'pending_plan_actions_with_due',d.pending_plan_actions_with_due,
      'scheduled_retests',d.scheduled_retests,
      'scheduled_retests_with_due',d.scheduled_retests_with_due
    ) order by d.skill_code) from detail d),'[]'::jsonb)
  into v_denominator,v_l3_count,v_below_l3_count,v_below_l3;

  return jsonb_build_object(
    'reader_version','stage4_raw_evidence_v1_2026_09_05',
    'component_code',p_component_code,
    'stage3_exit_status',v_stage3,
    'comparable_full_attempt_count_total',v_total_attempts,
    'exact_form_count_total',v_exact_forms,
    'comparison_family_count',v_family_count,
    'max_compatible_family_attempt_count',v_max_family_attempts,
    'comparison_families',v_families,
    'canonical_skill_count',v_denominator,
    'l3_or_higher_count',v_l3_count,
    'below_l3_count',v_below_l3_count,
    'below_l3_details',v_below_l3,
    'trend_policy_status','not_deployed',
    'corrective_plan_policy_status','not_deployed',
    'stage4_exit_ready',false,
    'stage4_unlocked',false,
    'stage5_unlocked',false,
    'reason_code',case when coalesce((v_stage3->>'ready')::boolean,false) then 'stage4_policy_not_deployed' else 'stage3_exit_incomplete' end
  );
end;
$$;

revoke all on function private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text) to service_role;

-- Deployment safety: raw reader only; no policy approval, promotion or learner activation.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
  v_registry_rows int;
  v_registry_status text;
  v_p2_contracts int;
begin
  if to_regprocedure('private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)') is null then
    raise exception 'P1-03 Stage-4 raw reader function missing';
  end if;
  if (select max_automatic_stage from private.exam_prep_operational_stage_rules where status='active')<>3 then
    raise exception 'P1-03 Stage-4 raw reader must not move automatic stage ceiling';
  end if;

  select key_registry_status into v_registry_status from private.exam_prep_stage3_exit_rules where status='active';
  select count(*) into v_registry_rows from private.exam_prep_stage3_key_skills;
  if v_registry_status<>'pending' or v_registry_rows<>0 then
    raise exception 'P1-03 Stage-4 raw reader requires pending/empty key registry status=% rows=%',v_registry_status,v_registry_rows;
  end if;

  select count(*) into v_p2_contracts
  from private.exam_prep_timed_assessment_contracts tc
  join private.exam_prep_assessments a on a.id=tc.assessment_id
  where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02');
  if v_p2_contracts<>0 then raise exception 'P1-03 Stage-4 raw reader must not release Paper02 contracts=%',v_p2_contracts; end if;

  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 Stage-4 raw reader requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 Stage-4 raw reader active entitlement residue=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions)
     or exists(select 1 from private.exam_prep_evidence_events)
     or exists(select 1 from private.exam_prep_timed_attempt_results) then
    raise exception 'P1-03 Stage-4 raw reader deployment must not create learner runtime evidence';
  end if;
end $$;

commit;
