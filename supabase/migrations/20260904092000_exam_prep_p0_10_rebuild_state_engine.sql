-- P0-10: deterministic rebuild of objective skill/component projections.
-- Raw P0-09 evidence is never mutated. Automatic authority is capped at L3.

begin;

create or replace function private.rebuild_exam_prep_state_v1(
  p_user_id uuid,
  p_component_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_program_version_id bigint;
  v_engine text := 'objective_state_v1';
  v_component text;
  v_rows int := 0;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_state_user_not_found';
  end if;
  if p_component_code is not null and p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_state_invalid_component';
  end if;

  select pv.id into v_program_version_id
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program_version_id is null then raise exception 'exam_prep_state_program_version_missing'; end if;
  if not exists(select 1 from private.exam_prep_state_engine_versions e where e.engine_version=v_engine and e.status='active') then
    raise exception 'exam_prep_state_engine_not_active';
  end if;

  delete from private.exam_prep_skill_states st
  where st.user_id=p_user_id
    and st.program_version_id=v_program_version_id
    and st.engine_version=v_engine
    and (p_component_code is null or st.component_code=p_component_code);

  delete from private.exam_prep_stage_states st
  where st.user_id=p_user_id
    and st.program_version_id=v_program_version_id
    and st.engine_version=v_engine
    and (p_component_code is null or st.component_code=p_component_code);

  with contracts as (
    select c.*
    from private.exam_prep_skill_contracts c
    where c.program_version_id=v_program_version_id
      and (p_component_code is null or c.component_code=p_component_code)
  ), ev as (
    select e.*
    from private.exam_prep_evidence_events e
    join private.exam_prep_sessions s on s.id=e.session_id
    where e.user_id=p_user_id
      and s.user_id=p_user_id
      and s.status='finalized'
      and s.program_version_id=v_program_version_id
      and e.component_code=s.component_code
      and (p_component_code is null or e.component_code=p_component_code)
  ), agg as (
    select
      c.program_version_id,c.component_code,c.skill_code,c.contract_profile,
      c.min_first_coverage_correct,c.min_provisional_correct,c.min_accuracy_pct,
      c.requires_written_for_l2,c.requires_transfer_for_l3,c.requires_mixed_for_l3,
      c.requires_retest_for_l3,c.min_retest_delay_days,
      count(e.id)::int as evidence_total,
      count(e.id) filter(where e.verification_status='app_verified' and e.is_correct is not null)::int as objective_evidence_count,
      count(e.id) filter(where e.verification_status='app_verified' and e.is_correct is true)::int as correct_objective_count,
      count(e.id) filter(where e.evidence_type='learning')::int as learning_count,
      count(e.id) filter(where e.evidence_type='diagnostic')::int as diagnostic_count,
      count(e.id) filter(where e.evidence_type='mixed')::int as mixed_count,
      count(e.id) filter(where e.evidence_type='timed')::int as timed_count,
      count(e.id) filter(where e.evidence_type='retest')::int as retest_count,
      count(e.id) filter(where e.evidence_type='written')::int as written_count,
      coalesce(bool_or(e.verification_status='app_verified' and e.is_correct is true and e.evidence_type in ('mixed','timed')),false) as has_transfer,
      coalesce(bool_or(e.verification_status='app_verified' and e.is_correct is true and e.evidence_type='mixed'),false) as has_mixed,
      coalesce(bool_or(e.verification_status='app_verified' and e.is_correct is true and e.evidence_type='retest'),false) as has_successful_retest,
      coalesce(bool_or(e.evidence_type='written'),false) as has_written,
      coalesce(bool_or(e.verification_status='mentor_verified'),false) as has_mentor_verified,
      min(e.created_at) filter(where e.evidence_type<>'retest') as first_non_retest_at,
      max(e.created_at) as source_evidence_through
    from contracts c
    left join ev e on e.component_code=c.component_code and e.skill_code=c.skill_code
    group by c.program_version_id,c.component_code,c.skill_code,c.contract_profile,
      c.min_first_coverage_correct,c.min_provisional_correct,c.min_accuracy_pct,
      c.requires_written_for_l2,c.requires_transfer_for_l3,c.requires_mixed_for_l3,
      c.requires_retest_for_l3,c.min_retest_delay_days
  ), enriched as (
    select a.*,
      case when a.objective_evidence_count>0
        then round((100.0*a.correct_objective_count/a.objective_evidence_count)::numeric,2)
        else null end as accuracy_pct,
      coalesce((
        select count(*) from private.exam_prep_correction_cases cc
        where cc.user_id=p_user_id
          and cc.component_code=a.component_code
          and cc.skill_code=a.skill_code
          and cc.status<>'resolved'
      ),0)::int as unresolved_corrections,
      exists(
        select 1 from ev r
        where r.component_code=a.component_code
          and r.skill_code=a.skill_code
          and r.evidence_type='retest'
          and r.verification_status='app_verified'
          and r.is_correct is true
          and a.first_non_retest_at is not null
          and (a.min_retest_delay_days=0 or r.created_at >= a.first_non_retest_at + (a.min_retest_delay_days * interval '1 day'))
      ) as has_delayed_successful_retest
    from agg a
  ), scored as (
    select e.*,
      (
        e.correct_objective_count>=e.min_first_coverage_correct
        and coalesce(e.accuracy_pct,0)>=e.min_accuracy_pct
        and (not e.requires_written_for_l2 or e.has_written)
      ) as l2_ready,
      (
        e.correct_objective_count>=e.min_provisional_correct
        and coalesce(e.accuracy_pct,0)>=e.min_accuracy_pct
        and (not e.requires_written_for_l2 or e.has_written)
        and (not e.requires_transfer_for_l3 or e.has_transfer)
        and (not e.requires_mixed_for_l3 or e.has_mixed)
        and (not e.requires_retest_for_l3 or e.has_delayed_successful_retest)
        and e.unresolved_corrections=0
      ) as l3_ready
    from enriched e
  )
  insert into private.exam_prep_skill_states(
    user_id,program_version_id,component_code,skill_code,engine_version,
    objective_level,coverage_confirmed,evidence_total,objective_evidence_count,correct_objective_count,
    objective_accuracy_pct,learning_count,diagnostic_count,mixed_count,timed_count,retest_count,written_count,
    has_transfer_evidence,has_successful_retest,has_delayed_successful_retest,has_written_evidence,
    has_mentor_verified_evidence,unresolved_correction_count,hold_reason,source_evidence_through,derived_at
  )
  select
    p_user_id,s.program_version_id,s.component_code,s.skill_code,v_engine,
    case when s.evidence_total=0 then 0 when s.l3_ready then 3 when s.l2_ready then 2 else 1 end,
    s.l2_ready,
    s.evidence_total,s.objective_evidence_count,s.correct_objective_count,s.accuracy_pct,
    s.learning_count,s.diagnostic_count,s.mixed_count,s.timed_count,s.retest_count,s.written_count,
    s.has_transfer,s.has_successful_retest,s.has_delayed_successful_retest,s.has_written,s.has_mentor_verified,
    s.unresolved_corrections,
    case
      when s.evidence_total=0 then 'no_finalized_evidence'
      when s.l3_ready then 'human_verification_pending_for_l4_l5'
      when s.correct_objective_count<s.min_first_coverage_correct then 'first_coverage_objective_evidence_insufficient'
      when coalesce(s.accuracy_pct,0)<s.min_accuracy_pct then 'objective_accuracy_below_contract'
      when s.requires_written_for_l2 and not s.has_written then 'written_evidence_missing'
      when s.correct_objective_count<s.min_provisional_correct then 'provisional_contract_evidence_insufficient'
      when s.requires_mixed_for_l3 and not s.has_mixed then 'mixed_transfer_missing'
      when s.requires_transfer_for_l3 and not s.has_transfer then 'transfer_evidence_missing'
      when s.requires_retest_for_l3 and not s.has_delayed_successful_retest and s.min_retest_delay_days>0 then 'delayed_retest_missing'
      when s.requires_retest_for_l3 and not s.has_delayed_successful_retest then 'successful_retest_missing'
      when s.unresolved_corrections>0 then 'open_correction'
      else 'provisional_evidence_incomplete'
    end,
    s.source_evidence_through,now()
  from scored s;

  get diagnostics v_rows = row_count;

  foreach v_component in array case when p_component_code is null then array['P1','P5'] else array[p_component_code] end loop
    insert into private.exam_prep_stage_states(
      user_id,program_version_id,component_code,engine_version,
      denominator_count,l0_count,l1_count,l2_count,l3_count,coverage_count,coverage_pct,
      open_correction_count,retest_due_count,evidence_stage_candidate,operational_stage,
      stage_gate_status,stage_hold_reason,app_readiness_estimate,app_readiness_reason,derived_at
    )
    select
      p_user_id,v_program_version_id,v_component,v_engine,
      count(*)::smallint,
      count(*) filter(where objective_level=0)::smallint,
      count(*) filter(where objective_level=1)::smallint,
      count(*) filter(where objective_level=2)::smallint,
      count(*) filter(where objective_level=3)::smallint,
      count(*) filter(where coverage_confirmed)::smallint,
      round((100.0*count(*) filter(where coverage_confirmed)/count(*))::numeric,2),
      coalesce((select count(*) from private.exam_prep_correction_cases cc where cc.user_id=p_user_id and cc.component_code=v_component and cc.status<>'resolved'),0)::int,
      coalesce((select count(*) from private.exam_prep_retest_events r where r.user_id=p_user_id and r.component_code=v_component and r.status in ('scheduled','authorized') and (r.due_not_before is null or r.due_not_before<=now())),0)::int,
      case
        when count(*) filter(where coverage_confirmed)>=ceil(0.15*count(*)) then 2
        when count(*) filter(where objective_level>0)>0 then 1
        else 0
      end::smallint,
      0,
      'blocked_dependency',
      'Operational Stage 1+ is intentionally blocked in objective_state_v1 until explicit machine-readable placement and prerequisite closure exist; Stage 3+ additionally needs key-skill/full-paper gates.',
      'INSUFFICIENT_EVIDENCE',
      'App Readiness Estimate remains INSUFFICIENT_EVIDENCE until the governed comparable full-paper subsystem and Stage 5 inputs exist; coverage alone never implies readiness.',
      now()
    from private.exam_prep_skill_states st
    where st.user_id=p_user_id and st.program_version_id=v_program_version_id
      and st.component_code=v_component and st.engine_version=v_engine
    on conflict(user_id,program_version_id,component_code,engine_version) do update set
      denominator_count=excluded.denominator_count,l0_count=excluded.l0_count,l1_count=excluded.l1_count,
      l2_count=excluded.l2_count,l3_count=excluded.l3_count,coverage_count=excluded.coverage_count,
      coverage_pct=excluded.coverage_pct,open_correction_count=excluded.open_correction_count,
      retest_due_count=excluded.retest_due_count,evidence_stage_candidate=excluded.evidence_stage_candidate,
      operational_stage=excluded.operational_stage,stage_gate_status=excluded.stage_gate_status,
      stage_hold_reason=excluded.stage_hold_reason,app_readiness_estimate=excluded.app_readiness_estimate,
      app_readiness_reason=excluded.app_readiness_reason,derived_at=excluded.derived_at;
  end loop;

  return jsonb_build_object('user_id',p_user_id,'program_version_id',v_program_version_id,
    'component',coalesce(p_component_code,'ALL'),'engine_version',v_engine,'skill_rows',v_rows);
end;
$$;

revoke execute on function private.rebuild_exam_prep_state_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.rebuild_exam_prep_state_v1(uuid,text) to service_role;

create or replace function public.get_exam_prep_state_safe_v1(p_component_code text default null)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_uid uuid; v_program bigint; v_engine text := 'objective_state_v1'; v_result jsonb;
begin
  perform private.exam_prep_require_core_access_v1();
  v_uid := auth.uid();
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if p_component_code is not null and p_component_code not in ('P1','P5') then raise exception 'exam_prep_state_invalid_component'; end if;

  perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);
  select id into v_program from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';

  select jsonb_build_object(
    'engine_version',v_engine,
    'components',coalesce((
      select jsonb_agg(jsonb_build_object(
        'component_code',ss.component_code,
        'operational_stage',ss.operational_stage,
        'evidence_stage_candidate',ss.evidence_stage_candidate,
        'stage_gate_status',ss.stage_gate_status,
        'stage_hold_reason',ss.stage_hold_reason,
        'denominator_count',ss.denominator_count,
        'coverage_count',ss.coverage_count,
        'coverage_pct',ss.coverage_pct,
        'levels',jsonb_build_object('L0',ss.l0_count,'L1',ss.l1_count,'L2',ss.l2_count,'L3',ss.l3_count),
        'open_corrections',ss.open_correction_count,
        'retests_due',ss.retest_due_count,
        'app_readiness_estimate',ss.app_readiness_estimate,
        'app_readiness_reason',ss.app_readiness_reason
      ) order by ss.component_code)
      from private.exam_prep_stage_states ss
      where ss.user_id=v_uid and ss.program_version_id=v_program and ss.engine_version=v_engine
        and (p_component_code is null or ss.component_code=p_component_code)
    ),'[]'::jsonb),
    'skills',coalesce((
      select jsonb_agg(jsonb_build_object(
        'skill_code',st.skill_code,
        'component_code',st.component_code,
        'objective_level',st.objective_level,
        'coverage_confirmed',st.coverage_confirmed,
        'objective_accuracy_pct',st.objective_accuracy_pct,
        'evidence_total',st.evidence_total,
        'objective_evidence_count',st.objective_evidence_count,
        'correct_objective_count',st.correct_objective_count,
        'has_written_evidence',st.has_written_evidence,
        'has_transfer_evidence',st.has_transfer_evidence,
        'has_successful_retest',st.has_successful_retest,
        'has_delayed_successful_retest',st.has_delayed_successful_retest,
        'unresolved_correction_count',st.unresolved_correction_count,
        'hold_reason',st.hold_reason
      ) order by st.component_code,s.sequence_no)
      from private.exam_prep_skill_states st
      join private.exam_prep_syllabus_nodes s on s.program_version_id=st.program_version_id and s.skill_code=st.skill_code
      where st.user_id=v_uid and st.program_version_id=v_program and st.engine_version=v_engine
        and (p_component_code is null or st.component_code=p_component_code)
    ),'[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

revoke execute on function public.get_exam_prep_state_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_state_safe_v1(text) to authenticated,service_role;

commit;
