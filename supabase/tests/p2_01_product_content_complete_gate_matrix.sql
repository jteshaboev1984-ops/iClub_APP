-- P2-01 Product Content-Complete formal gate matrix.
-- Product milestone only. Never learner Syllabus Closure / Exam Ready.
\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p201_before AS
SELECT
  (SELECT count(*) FROM public.users) users,
  (SELECT count(*) FROM public.practice_attempts) practice_attempts,
  (SELECT count(*) FROM public.practice_answers) practice_answers,
  (SELECT count(*) FROM public.tour_attempts) tour_attempts,
  (SELECT count(*) FROM public.tour_answers) tour_answers,
  (SELECT count(*) FROM public.certificates) certificates,
  (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
  (SELECT count(*) FROM private.exam_prep_skill_states) skill_states,
  (SELECT count(*) FROM private.exam_prep_stage_states) stage_states,
  (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases,
  (SELECT count(*) FROM private.exam_prep_timed_attempt_results) timed_results,
  (SELECT count(*) FROM private.exam_prep_responses) exam_prep_responses;

DO $$
DECLARE
  v_program bigint;
  v_metrics jsonb;
  v_status jsonb;
  v_bad int;
  v_pct numeric;
BEGIN
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  if v_program is null then
    raise exception 'P2-01 active canonical program missing';
  end if;

  if not exists(
    select 1
    from private.exam_prep_product_roadmap_milestones
    where program_version_id=v_program
      and milestone_key='product_content_complete'
      and milestone_kind='product_content_complete'
      and target_date=date '2027-02-15'
      and product_label='Product Content-Complete'
      and milestone_status='met'
      and dependency_role='content_dependency_gate'
      and can_block_learner_if_unavailable
      and can_force_learner_stage=false
      and can_raise_learner_mastery=false
      and can_label_learner_exam_ready=false
  ) then
    raise exception 'P2-01 Product Content-Complete milestone not safely met';
  end if;

  select metrics into v_metrics
  from private.exam_prep_product_content_complete_audits
  where program_version_id=v_program
    and gate_version='p2_01_product_content_complete_v1'
    and audit_status='passed';

  if v_metrics is null then
    raise exception 'P2-01 passed content-complete audit missing';
  end if;

  if coalesce((v_metrics->>'skills_total')::int,0)<>81
     or coalesce((v_metrics->>'skills_p1')::int,0)<>45
     or coalesce((v_metrics->>'skills_p5')::int,0)<>36
     or coalesce((v_metrics->>'content_ready_skills')::int,0)<>81
     or coalesce((v_metrics->>'annual_min_diagnostic')::int,0)<3
     or coalesce((v_metrics->>'annual_min_retest')::int,0)<4
     or coalesce((v_metrics->>'annual_min_learning_transfer')::int,0)<8
     or coalesce((v_metrics->>'annual_min_written')::int,0)<2
     or coalesce((v_metrics->>'governed_machine_questions')::int,0)<1215
     or coalesce((v_metrics->>'governed_written_tasks')::int,0)<233
     or coalesce((v_metrics->>'diagnostic_items')::int,0)<243
     or coalesce((v_metrics->>'approved_diagnostic_rules')::int,0)<729
     or coalesce((v_metrics->>'mixed_nodes_total')::int,0)<>23
     or coalesce((v_metrics->>'same_component_mixed_nodes')::int,0)<>21
     or coalesce((v_metrics->>'cross_prerequisite_nodes')::int,0)<>2
     or coalesce((v_metrics->>'p1_timed_sections')::int,0)<2
     or coalesce((v_metrics->>'p5_timed_sections')::int,0)<2
     or coalesce((v_metrics->>'p1_full_papers')::int,0)<1
     or coalesce((v_metrics->>'p5_full_papers')::int,0)<1
     or coalesce((v_metrics->>'p1_modified_papers')::int,0)<1
     or coalesce((v_metrics->>'p5_modified_papers')::int,0)<1
     or coalesce((v_metrics->>'timed_tracking_fields')::int,0)<>11
     or coalesce((v_metrics->>'past_paper_companion_rows')::int,0)<>2
     or coalesce((v_metrics->>'never_exposed_transfer_retest_pct')::numeric,0)<20
     or coalesce((v_metrics->>'product_content_complete_is_syllabus_closure')::boolean,true)
     or coalesce((v_metrics->>'product_content_complete_is_learner_exam_ready')::boolean,true)
  then
    raise exception 'P2-01 audit payload does not satisfy Product Content-Complete contract: %',v_metrics;
  end if;

  if (select count(*) from private.exam_prep_skill_contracts where program_version_id=v_program)<>81
     or (select count(*) from private.exam_prep_syllabus_nodes where program_version_id=v_program)<>81
     or (select count(*) from private.exam_prep_skill_contracts
         where program_version_id=v_program
           and not private.exam_prep_skill_content_ready_v1(program_version_id,component_code,skill_code))<>0
  then
    raise exception 'P2-01 live 81-skill coverage drifted after milestone transition';
  end if;

  select count(*) into v_bad
  from (
    select s.skill_code,
      count(distinct m.id) filter(
        where cv.status='published'
          and m.lifecycle_state in ('published','reserve')
          and m.reserve_role='diagnostic') d,
      count(distinct m.id) filter(
        where cv.status='published'
          and m.lifecycle_state in ('published','reserve')
          and m.reserve_role='retest') r,
      count(distinct m.id) filter(
        where cv.status='published'
          and m.lifecycle_state in ('published','reserve')
          and m.reserve_role in ('learning','mixed')) lx,
      count(distinct wt.id) filter(
        where wcv.status='published' and wt.lifecycle_state='published') w
    from private.exam_prep_skill_contracts s
    left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    left join private.exam_prep_written_tasks wt on wt.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions wcv on wcv.id=wt.content_version_id
    where s.program_version_id=v_program
    group by s.skill_code
  ) d
  where d<3 or r<4 or lx<8 or w<2;
  if v_bad<>0 then
    raise exception 'P2-01 live annual content depth failed skills=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_mixed_nodes where program_version_id=v_program)<>23
     or (select count(*) from private.exam_prep_mixed_nodes
         where program_version_id=v_program and owner_component_code in ('P1','P5'))<>21
     or (select count(*) from private.exam_prep_mixed_nodes
         where program_version_id=v_program and owner_component_code is null)<>2
     or exists(select 1 from private.exam_prep_mixed_nodes
         where program_version_id=v_program and denominator_credit)
  then
    raise exception 'P2-01 mixed registry / non-crediting firewall drifted';
  end if;

  select count(*) into v_bad
  from private.exam_prep_mixed_nodes n
  where n.program_version_id=v_program
    and n.owner_component_code in ('P1','P5')
    and not exists(
      select 1
      from private.exam_prep_assessment_mixed_nodes am
      join private.exam_prep_assessments a on a.id=am.assessment_id
      where am.program_version_id=n.program_version_id
        and am.mixed_code=n.mixed_code
        and am.component_code=n.owner_component_code
        and a.component_code=n.owner_component_code
        and a.status='published'
    );
  if v_bad<>0 then
    raise exception 'P2-01 same-component mixed nodes missing governed assessments=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_mixed_nodes n
    join private.exam_prep_mixed_links l
      on l.program_version_id=n.program_version_id and l.mixed_code=n.mixed_code
    where n.program_version_id=v_program
      and n.owner_component_code in ('P1','P5')
      and l.linked_node_kind='skill'
      and l.linked_component_code<>n.owner_component_code
  ) then
    raise exception 'P2-01 cross-component mixed skill leakage';
  end if;

  if (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P1'
        and t.status='published' and t.attempt_kind='timed_section' and t.strict_timing)<2
     or (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P5'
        and t.status='published' and t.attempt_kind='timed_section' and t.strict_timing)<2
     or (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P1'
        and t.status='published' and t.attempt_kind='full_paper'
        and t.strict_timing and t.timing_rule='official_full' and t.comparison_scope='full')<1
     or (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P5'
        and t.status='published' and t.attempt_kind='full_paper'
        and t.strict_timing and t.timing_rule='official_full' and t.comparison_scope='full')<1
  then
    raise exception 'P2-01 timed/full-paper capacity drifted';
  end if;

  if (select count(*) from private.exam_prep_paper_metadata
      where program_version_id=v_program
        and component_code in ('P1','P5')
        and resource_kind='official_past_paper_portal'
        and rights_status='metadata_only_external'
        and publication_status='approved'
        and source_level=4)<>2
  then
    raise exception 'P2-01 Past Paper Companion metadata-only contract drifted';
  end if;

  with candidate as (
    select m.id
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    where cv.program_version_id=v_program
      and cv.status='published'
      and m.lifecycle_state in ('published','reserve')
      and m.reserve_role in ('retest','mixed')
  ), unseen as (
    select c.id
    from candidate c
    where not exists(
      select 1 from private.exam_prep_session_items si where si.content_meta_id=c.id
    )
  )
  select round(100.0*(select count(*) from unseen)/nullif((select count(*) from candidate),0),2)
  into v_pct;
  if coalesce(v_pct,0)<20 then
    raise exception 'P2-01 live unseen transfer/retest reserve below 20%%: %',v_pct;
  end if;

  v_status:=private.exam_prep_product_roadmap_status_v1();

  if coalesce((v_status->>'product_status_does_not_equal_learner_readiness')::boolean,false) is not true
     or coalesce((v_status->>'learner_state_mutated')::boolean,true) is not false
     or coalesce((v_status->>'can_force_learner_stage')::boolean,true) is not false
     or coalesce((v_status->>'can_raise_learner_mastery')::boolean,true) is not false
     or coalesce((v_status->>'can_label_learner_exam_ready')::boolean,true) is not false
  then
    raise exception 'P2-01 product/student roadmap firewall projection drifted: %',v_status;
  end if;

  begin
    update private.exam_prep_product_roadmap_milestones
    set product_label='Learner Exam Ready'
    where program_version_id=v_program and milestone_key='product_content_complete';
    raise exception 'P2-01 label guard accepted forbidden learner readiness wording';
  exception when check_violation then
    null;
  end;
END
$$;

DO $$
DECLARE
  b record;
  a record;
BEGIN
  SELECT * INTO b FROM p201_before;
  SELECT
    (SELECT count(*) FROM public.users) users,
    (SELECT count(*) FROM public.practice_attempts) practice_attempts,
    (SELECT count(*) FROM public.practice_answers) practice_answers,
    (SELECT count(*) FROM public.tour_attempts) tour_attempts,
    (SELECT count(*) FROM public.tour_answers) tour_answers,
    (SELECT count(*) FROM public.certificates) certificates,
    (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
    (SELECT count(*) FROM private.exam_prep_skill_states) skill_states,
    (SELECT count(*) FROM private.exam_prep_stage_states) stage_states,
    (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases,
    (SELECT count(*) FROM private.exam_prep_timed_attempt_results) timed_results,
    (SELECT count(*) FROM private.exam_prep_responses) exam_prep_responses
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-01 product gate contract mutated learner/legacy state before=% after=%',
      row_to_json(b),row_to_json(a);
  END IF;
END
$$;

ROLLBACK;

\echo 'P2-01 Product Content-Complete formal gate matrix: GREEN'
