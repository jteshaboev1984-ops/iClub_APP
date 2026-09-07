-- Exam Prep learner read surfaces v1: Syllabus Tracker, Skill Detail, Correction Queue.
-- Additive/read-only API only. No learner evidence/mastery/history/legacy rows are mutated.
-- Master Plan EP-05/EP-06/EP-08: 45 P1 / 36 P5 denominator, prerequisites/mixed outside denominator,
-- evidence history and delayed retest visible, component firewall preserved.

begin;

create or replace function private.exam_prep_syllabus_tracker_payload_v1(
  p_user_id uuid,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_engine text;
  v_expected_skills int;
  v_expected_areas int;
  v_skill_count int;
  v_area_count int;
  v_payload jsonb;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_tracker_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_tracker_program_missing'; end if;

  select ev.engine_version into v_engine
  from private.exam_prep_state_engine_versions ev
  where ev.status='active'
  order by ev.activated_at desc nulls last,ev.created_at desc
  limit 1;
  if v_engine is null then raise exception 'exam_prep_tracker_engine_missing'; end if;

  v_expected_skills:=case when p_component_code='P1' then 45 else 36 end;
  v_expected_areas:=case when p_component_code='P1' then 8 else 5 end;

  select count(*),count(distinct n.official_syllabus_section)
    into v_skill_count,v_area_count
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program and n.component_code=p_component_code;

  if v_skill_count<>v_expected_skills or v_area_count<>v_expected_areas then
    raise exception 'exam_prep_tracker_denominator_drift component=% skills=% areas=%',p_component_code,v_skill_count,v_area_count;
  end if;

  with skill_rows as (
    select
      n.sequence_no,
      n.official_syllabus_section,
      n.skill_code,
      n.canonical_description,
      coalesce(ss.objective_level,0)::int as objective_level,
      coalesce(ss.coverage_confirmed,false) as coverage_confirmed,
      coalesce(ss.evidence_total,0)::int as evidence_total,
      coalesce(ss.objective_evidence_count,0)::int as objective_evidence_count,
      coalesce(ss.unresolved_correction_count,0)::int as unresolved_correction_count,
      ss.source_evidence_through,
      exists(
        select 1
        from private.exam_prep_stage3_key_skills k
        join private.exam_prep_stage3_exit_rules r on r.rule_version=k.rule_version and r.status='active'
        where k.program_version_id=v_program
          and k.component_code=p_component_code
          and k.skill_code=n.skill_code
      ) as key_skill,
      c.id as correction_case_id,
      c.status as correction_status,
      rt.due_not_before as retest_due_at,
      le.evidence_type as latest_evidence_type,
      le.verification_status as latest_verification_status,
      le.is_correct as latest_is_correct,
      le.created_at as latest_evidence_at
    from private.exam_prep_syllabus_nodes n
    left join private.exam_prep_skill_states ss
      on ss.user_id=p_user_id
     and ss.program_version_id=n.program_version_id
     and ss.component_code=n.component_code
     and ss.skill_code=n.skill_code
     and ss.engine_version=v_engine
    left join lateral (
      select cc.id,cc.status,cc.updated_at
      from private.exam_prep_correction_cases cc
      where cc.user_id=p_user_id
        and cc.component_code=p_component_code
        and cc.skill_code=n.skill_code
        and cc.status in ('open','remediating','retest_due','reopened')
      order by cc.updated_at desc,cc.opened_at desc
      limit 1
    ) c on true
    left join lateral (
      select re.due_not_before
      from private.exam_prep_retest_events re
      where re.user_id=p_user_id
        and re.component_code=p_component_code
        and re.skill_code=n.skill_code
        and re.status in ('scheduled','authorized')
      order by re.created_at desc
      limit 1
    ) rt on true
    left join lateral (
      select e.evidence_type,e.verification_status,e.is_correct,e.created_at
      from private.exam_prep_evidence_events e
      where e.user_id=p_user_id
        and e.component_code=p_component_code
        and e.skill_code=n.skill_code
      order by e.created_at desc,e.id desc
      limit 1
    ) le on true
    where n.program_version_id=v_program
      and n.component_code=p_component_code
  ), area_rows as (
    select
      official_syllabus_section,
      min(sequence_no) as area_order,
      count(*)::int as skill_count,
      count(*) filter(where coverage_confirmed)::int as coverage_count,
      count(*) filter(where objective_level>=2)::int as l2_or_higher_count,
      count(*) filter(where objective_level>=3)::int as l3_count,
      count(*) filter(where correction_case_id is not null)::int as open_correction_count,
      jsonb_agg(
        jsonb_build_object(
          'sequence_no',sequence_no,
          'skill_code',skill_code,
          'description',canonical_description,
          'objective_level',objective_level,
          'coverage_confirmed',coverage_confirmed,
          'evidence_total',evidence_total,
          'objective_evidence_count',objective_evidence_count,
          'unresolved_correction_count',unresolved_correction_count,
          'key_skill',key_skill,
          'correction_case_id',correction_case_id,
          'correction_status',correction_status,
          'retest_due_at',retest_due_at,
          'latest_evidence_type',latest_evidence_type,
          'latest_verification_status',latest_verification_status,
          'latest_is_correct',latest_is_correct,
          'latest_evidence_at',latest_evidence_at,
          'source_evidence_through',source_evidence_through
        ) order by sequence_no
      ) as skills
    from skill_rows
    group by official_syllabus_section
  )
  select jsonb_build_object(
    'component_code',p_component_code,
    'program_version_id',v_program,
    'engine_version',v_engine,
    'denominator_count',v_skill_count,
    'area_count',v_area_count,
    'coverage_count',(select count(*) from skill_rows where coverage_confirmed),
    'coverage_pct',round(100.0*(select count(*) from skill_rows where coverage_confirmed)/greatest(v_skill_count,1),2),
    'l0_count',(select count(*) from skill_rows where objective_level=0),
    'l1_count',(select count(*) from skill_rows where objective_level=1),
    'l2_count',(select count(*) from skill_rows where objective_level=2),
    'l3_count',(select count(*) from skill_rows where objective_level>=3),
    'open_correction_count',(select count(*) from skill_rows where correction_case_id is not null),
    'support_scope',jsonb_build_object(
      'prerequisite_nodes',(select count(*) from private.exam_prep_prerequisite_nodes pn where pn.program_version_id=v_program),
      'mixed_nodes_total',(select count(*) from private.exam_prep_mixed_nodes mn where mn.program_version_id=v_program),
      'mixed_nodes_owned',(select count(*) from private.exam_prep_mixed_nodes mn where mn.program_version_id=v_program and mn.owner_component_code=p_component_code),
      'denominator_credit',false
    ),
    'areas',coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'official_syllabus_section',official_syllabus_section,
          'skill_count',skill_count,
          'coverage_count',coverage_count,
          'l2_or_higher_count',l2_or_higher_count,
          'l3_count',l3_count,
          'open_correction_count',open_correction_count,
          'skills',skills
        ) order by area_order
      ) from area_rows
    ),'[]'::jsonb)
  ) into v_payload;

  return v_payload;
end;
$$;

revoke all on function private.exam_prep_syllabus_tracker_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_syllabus_tracker_payload_v1(uuid,text) to service_role;

create or replace function public.get_exam_prep_syllabus_tracker_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_syllabus_tracker_payload_v1(v_uid,p_component_code);
end;
$$;
revoke all on function public.get_exam_prep_syllabus_tracker_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_syllabus_tracker_safe_v1(text) to authenticated,service_role;

create or replace function private.exam_prep_skill_detail_payload_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_engine text;
  v_node private.exam_prep_syllabus_nodes%rowtype;
  v_state private.exam_prep_skill_states%rowtype;
  v_payload jsonb;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_skill_detail_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_skill_code is null or btrim(p_skill_code)='' then raise exception 'exam_prep_skill_code_required'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_skill_detail_program_missing'; end if;

  select ev.engine_version into v_engine
  from private.exam_prep_state_engine_versions ev
  where ev.status='active'
  order by ev.activated_at desc nulls last,ev.created_at desc
  limit 1;
  if v_engine is null then raise exception 'exam_prep_skill_detail_engine_missing'; end if;

  select * into v_node
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program
    and n.component_code=p_component_code
    and n.skill_code=p_skill_code;
  if v_node.skill_code is null then raise exception 'exam_prep_skill_not_found' using errcode='P0002'; end if;

  select * into v_state
  from private.exam_prep_skill_states ss
  where ss.user_id=p_user_id
    and ss.program_version_id=v_program
    and ss.component_code=p_component_code
    and ss.skill_code=p_skill_code
    and ss.engine_version=v_engine;

  with prereq_codes as (
    select btrim(x) as code
    from regexp_split_to_table(coalesce(v_node.prerequisites_text,''),'\s*;\s*') x
    where btrim(x)<>''
  ), prereqs as (
    select
      pc.code,
      case when pn.prerequisite_code is not null then 'foundation' else 'skill' end as kind,
      coalesce(pn.definition,sn.canonical_description,pc.code) as label,
      ps.status as foundation_status,
      ps.evidence_source as foundation_evidence_source,
      ss2.component_code as skill_component_code,
      ss2.objective_level as skill_objective_level,
      ss2.coverage_confirmed as skill_coverage_confirmed
    from prereq_codes pc
    left join private.exam_prep_prerequisite_nodes pn
      on pn.program_version_id=v_program and pn.prerequisite_code=pc.code
    left join private.exam_prep_syllabus_nodes sn
      on sn.program_version_id=v_program and sn.skill_code=pc.code
    left join private.exam_prep_prerequisite_states ps
      on ps.user_id=p_user_id and ps.program_version_id=v_program and ps.prerequisite_code=pc.code
    left join private.exam_prep_skill_states ss2
      on ss2.user_id=p_user_id and ss2.program_version_id=v_program
     and ss2.skill_code=pc.code and ss2.engine_version=v_engine
  ), evid as (
    select e.evidence_type,e.verification_status,e.is_correct,e.source_version,e.created_at,
           s.session_type,s.finalized_at
    from private.exam_prep_evidence_events e
    join private.exam_prep_sessions s on s.id=e.session_id and s.user_id=p_user_id
    where e.user_id=p_user_id
      and e.component_code=p_component_code
      and e.skill_code=p_skill_code
    order by e.created_at desc,e.id desc
    limit 20
  ), corrections as (
    select
      c.id,c.status,c.opened_at,c.updated_at,c.resolved_at,
      case when c.reason->>'source'='finalized_incorrect_evidence' then 'incorrect_evidence' else coalesce(c.reason->>'source','other') end as origin,
      rt.status as retest_status,rt.due_not_before as retest_due_at,rt.completed_at as retest_completed_at,
      ca.action_type as latest_action_type,ca.created_at as latest_action_at
    from private.exam_prep_correction_cases c
    left join lateral (
      select r.status,r.due_not_before,r.completed_at
      from private.exam_prep_retest_events r
      where r.correction_case_id=c.id and r.user_id=p_user_id
      order by r.created_at desc
      limit 1
    ) rt on true
    left join lateral (
      select a.action_type,a.created_at
      from private.exam_prep_correction_actions a
      where a.correction_case_id=c.id and a.user_id=p_user_id
      order by a.created_at desc,a.id desc
      limit 1
    ) ca on true
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.skill_code=p_skill_code
    order by c.opened_at desc
    limit 10
  ), mixed as (
    select mn.mixed_code,mn.owner_component_code,mn.evidence_focus,mn.mastery_rule
    from private.exam_prep_mixed_links ml
    join private.exam_prep_mixed_nodes mn
      on mn.program_version_id=ml.program_version_id and mn.mixed_code=ml.mixed_code
    where ml.program_version_id=v_program
      and ml.linked_node_kind='skill'
      and ml.linked_node_code=p_skill_code
    order by mn.mixed_code
  )
  select jsonb_build_object(
    'component_code',p_component_code,
    'program_version_id',v_program,
    'engine_version',v_engine,
    'skill_code',v_node.skill_code,
    'sequence_no',v_node.sequence_no,
    'official_syllabus_section',v_node.official_syllabus_section,
    'description',v_node.canonical_description,
    'state',jsonb_build_object(
      'objective_level',coalesce(v_state.objective_level,0),
      'coverage_confirmed',coalesce(v_state.coverage_confirmed,false),
      'evidence_total',coalesce(v_state.evidence_total,0),
      'objective_evidence_count',coalesce(v_state.objective_evidence_count,0),
      'correct_objective_count',coalesce(v_state.correct_objective_count,0),
      'objective_accuracy_pct',v_state.objective_accuracy_pct,
      'learning_count',coalesce(v_state.learning_count,0),
      'diagnostic_count',coalesce(v_state.diagnostic_count,0),
      'mixed_count',coalesce(v_state.mixed_count,0),
      'timed_count',coalesce(v_state.timed_count,0),
      'retest_count',coalesce(v_state.retest_count,0),
      'written_count',coalesce(v_state.written_count,0),
      'has_transfer_evidence',coalesce(v_state.has_transfer_evidence,false),
      'has_successful_retest',coalesce(v_state.has_successful_retest,false),
      'has_delayed_successful_retest',coalesce(v_state.has_delayed_successful_retest,false),
      'has_written_evidence',coalesce(v_state.has_written_evidence,false),
      'has_mentor_verified_evidence',coalesce(v_state.has_mentor_verified_evidence,false),
      'unresolved_correction_count',coalesce(v_state.unresolved_correction_count,0),
      'hold_reason',v_state.hold_reason,
      'source_evidence_through',v_state.source_evidence_through
    ),
    'key_skill',exists(
      select 1 from private.exam_prep_stage3_key_skills k
      join private.exam_prep_stage3_exit_rules r on r.rule_version=k.rule_version and r.status='active'
      where k.program_version_id=v_program and k.component_code=p_component_code and k.skill_code=p_skill_code
    ),
    'evidence_requirements',jsonb_build_object(
      'required_mastery_evidence',v_node.required_mastery_evidence,
      'app_can_verify',v_node.app_can_verify,
      'human_judgement_note',v_node.mentor_must_verify,
      'human_verification_is_separate_claim',true
    ),
    'resources',jsonb_build_object(
      'book_chapter',v_node.book_chapter,
      'book_pages',v_node.book_pages,
      'official_source_url',v_node.official_source_url
    ),
    'prerequisites',coalesce((select jsonb_agg(jsonb_build_object(
      'code',code,'kind',kind,'label',label,
      'foundation_status',foundation_status,'foundation_evidence_source',foundation_evidence_source,
      'skill_component_code',skill_component_code,'skill_objective_level',skill_objective_level,
      'skill_coverage_confirmed',skill_coverage_confirmed
    ) order by code) from prereqs),'[]'::jsonb),
    'mixed_connections',coalesce((select jsonb_agg(jsonb_build_object(
      'mixed_code',mixed_code,'owner_component_code',owner_component_code,
      'evidence_focus',evidence_focus,'mastery_rule',mastery_rule,'denominator_credit',false
    ) order by mixed_code) from mixed),'[]'::jsonb),
    'evidence_history',coalesce((select jsonb_agg(jsonb_build_object(
      'evidence_type',evidence_type,'verification_status',verification_status,'is_correct',is_correct,
      'source_version',source_version,'session_type',session_type,'created_at',created_at,'finalized_at',finalized_at
    ) order by created_at desc) from evid),'[]'::jsonb),
    'correction_history',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'status',status,'origin',origin,
      'opened_at',opened_at,'updated_at',updated_at,'resolved_at',resolved_at,
      'retest_status',retest_status,'retest_due_at',retest_due_at,'retest_completed_at',retest_completed_at,
      'latest_action_type',latest_action_type,'latest_action_at',latest_action_at
    ) order by opened_at desc) from corrections),'[]'::jsonb)
  ) into v_payload;

  return v_payload;
end;
$$;

revoke all on function private.exam_prep_skill_detail_payload_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_skill_detail_payload_v1(uuid,text,text) to service_role;

create or replace function public.get_exam_prep_skill_detail_safe_v1(p_component_code text,p_skill_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_skill_detail_payload_v1(v_uid,p_component_code,p_skill_code);
end;
$$;
revoke all on function public.get_exam_prep_skill_detail_safe_v1(text,text) from public,anon;
grant execute on function public.get_exam_prep_skill_detail_safe_v1(text,text) to authenticated,service_role;

create or replace function private.exam_prep_correction_queue_payload_v1(
  p_user_id uuid,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_payload jsonb;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_correction_queue_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_correction_queue_program_missing'; end if;

  with active_cases as (
    select
      c.id,c.skill_code,c.status,c.opened_at,c.updated_at,
      n.sequence_no,n.official_syllabus_section,n.canonical_description,
      case when c.reason->>'source'='finalized_incorrect_evidence' then 'incorrect_evidence' else coalesce(c.reason->>'source','other') end as origin,
      rt.id as retest_event_id,rt.status as retest_status,rt.due_not_before as retest_due_at,
      ca.action_type as latest_action_type,ca.created_at as latest_action_at,
      exists(
        select 1 from private.exam_prep_assessments a
        where a.component_code=p_component_code and a.assessment_type='learning' and a.status='published'
          and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=c.skill_code)
          and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>c.skill_code)
      ) as correction_content_ready,
      exists(
        select 1 from private.exam_prep_assessments a
        where a.component_code=p_component_code and a.assessment_type='retest' and a.status='published'
          and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code=c.skill_code)
          and not exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=a.id and ai.primary_skill_code<>c.skill_code)
      ) as retest_content_ready
    from private.exam_prep_correction_cases c
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program and n.component_code=c.component_code and n.skill_code=c.skill_code
    left join lateral (
      select r.id,r.status,r.due_not_before
      from private.exam_prep_retest_events r
      where r.correction_case_id=c.id and r.user_id=p_user_id
      order by r.created_at desc
      limit 1
    ) rt on true
    left join lateral (
      select a.action_type,a.created_at
      from private.exam_prep_correction_actions a
      where a.correction_case_id=c.id and a.user_id=p_user_id
      order by a.created_at desc,a.id desc
      limit 1
    ) ca on true
    where c.user_id=p_user_id
      and c.component_code=p_component_code
      and c.status in ('open','remediating','retest_due','reopened')
  ), normalized as (
    select *,
      case
        when status in ('open','reopened') then 'review_error'
        when status='remediating' then 'practice_analogues'
        when status='retest_due' and retest_due_at is not null and retest_due_at>now() then 'wait_delayed_retest'
        when status='retest_due' then 'delayed_retest'
        else 'review_error'
      end as process_step,
      (status in ('open','remediating','reopened') and correction_content_ready) as can_start_correction,
      (status='retest_due' and retest_status='scheduled' and retest_due_at is not null and retest_due_at<=now() and retest_content_ready) as can_start_retest
    from active_cases
  ), resolved_recent as (
    select c.id,c.skill_code,c.opened_at,c.resolved_at,n.official_syllabus_section,n.canonical_description
    from private.exam_prep_correction_cases c
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=v_program and n.component_code=c.component_code and n.skill_code=c.skill_code
    where c.user_id=p_user_id and c.component_code=p_component_code and c.status='resolved'
    order by c.resolved_at desc nulls last,c.updated_at desc
    limit 10
  )
  select jsonb_build_object(
    'component_code',p_component_code,
    'active_count',(select count(*) from normalized),
    'retest_due_count',(select count(*) from normalized where status='retest_due'),
    'cases',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,
      'skill_code',skill_code,
      'official_syllabus_section',official_syllabus_section,
      'description',canonical_description,
      'status',status,
      'origin',origin,
      'process_step',process_step,
      'opened_at',opened_at,
      'updated_at',updated_at,
      'retest_event_id',retest_event_id,
      'retest_status',retest_status,
      'retest_due_at',retest_due_at,
      'latest_action_type',latest_action_type,
      'latest_action_at',latest_action_at,
      'correction_content_ready',correction_content_ready,
      'retest_content_ready',retest_content_ready,
      'can_start_correction',can_start_correction,
      'can_start_retest',can_start_retest
    ) order by sequence_no,opened_at) from normalized),'[]'::jsonb),
    'recent_resolved',coalesce((select jsonb_agg(jsonb_build_object(
      'correction_case_id',id,'skill_code',skill_code,'official_syllabus_section',official_syllabus_section,
      'description',canonical_description,'opened_at',opened_at,'resolved_at',resolved_at
    ) order by resolved_at desc) from resolved_recent),'[]'::jsonb)
  ) into v_payload;

  return v_payload;
end;
$$;

revoke all on function private.exam_prep_correction_queue_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_queue_payload_v1(uuid,text) to service_role;

create or replace function public.get_exam_prep_correction_queue_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_correction_queue_payload_v1(v_uid,p_component_code);
end;
$$;
revoke all on function public.get_exam_prep_correction_queue_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_correction_queue_safe_v1(text) to authenticated,service_role;

-- Deployment invariants: canonical denominator stays exact; only safe RPCs become learner-callable.
do $$
declare
  v_program bigint;
  v_p1 int; v_p5 int; v_a1 int; v_a5 int;
begin
  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active';
  if v_program is null then raise exception 'Exam Prep learner read API: canonical program missing'; end if;

  select count(*) filter(where component_code='P1'),count(*) filter(where component_code='P5'),
         count(distinct official_syllabus_section) filter(where component_code='P1'),
         count(distinct official_syllabus_section) filter(where component_code='P5')
    into v_p1,v_p5,v_a1,v_a5
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program;
  if v_p1<>45 or v_p5<>36 or v_a1<>8 or v_a5<>5 then
    raise exception 'Exam Prep learner read API: canonical denominator drift P1=%/% P5=%/%',v_p1,v_a1,v_p5,v_a5;
  end if;

  if to_regprocedure('public.get_exam_prep_syllabus_tracker_safe_v1(text)') is null
     or to_regprocedure('public.get_exam_prep_skill_detail_safe_v1(text,text)') is null
     or to_regprocedure('public.get_exam_prep_correction_queue_safe_v1(text)') is null then
    raise exception 'Exam Prep learner read API: safe RPC missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_syllabus_tracker_safe_v1(text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_skill_detail_safe_v1(text,text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_correction_queue_safe_v1(text)','EXECUTE') then
    raise exception 'Exam Prep learner read API: anon execute leak';
  end if;
end $$;

commit;
