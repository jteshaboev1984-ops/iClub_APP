-- P2-05 App Readiness + optional Mentor Verified Readiness formal contract.
-- Read-only contract. Strong/borderline/weak synthetic behavior is separately
-- exercised by p1_04_stage5_stage6_readiness_matrix.sql inside isolated CI.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_program bigint;
  v_bad int;
  v_rules int;
  v_refs int;
  v_thresholds int;
  v_def text;
  v_rls boolean;
BEGIN
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  if v_program is null then
    raise exception 'P2-05 canonical program missing';
  end if;

  if to_regprocedure('private.exam_prep_stage5_raw_readiness_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_mentor_verified_readiness_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('public.get_exam_prep_readiness_summary_safe_v1(text)') is null then
    raise exception 'P2-05 readiness functions missing';
  end if;

  select count(*) into v_rules
  from private.exam_prep_stage5_readiness_rules
  where status='active'
    and min_comparable_full_attempts=3
    and require_stage4_exit
    and require_all_skills_l3
    and require_all_corrections_closed
    and require_last_three_above_threshold;
  if v_rules<>1 then
    raise exception 'P2-05 active readiness rule mismatch=%',v_rules;
  end if;

  -- The current release deliberately has no approved future-series threshold.
  -- June-2026 Cambridge values are historical reference only and cannot unlock readiness.
  select count(*) into v_thresholds
  from private.exam_prep_stage5_thresholds
  where status='approved';
  if v_thresholds<>0 then
    raise exception 'P2-05 current release unexpectedly has approved readiness thresholds=%',v_thresholds;
  end if;

  select count(*) into v_refs
  from private.exam_prep_threshold_references
  where program_version_id=v_program
    and status='active'
    and reference_version='cambridge_9709_june_2026_zone4_reference_v1'
    and exam_series='June 2026'
    and source_url='https://www.cambridgeinternational.org/Images/761530-mathematics-9709-june-2026-grade-threshold-table.pdf'
    and component_code in ('P1','P5')
    and special_note_code in ('paper12_replacement','paper52_assessed_marks');
  if v_refs<>10 then
    raise exception 'P2-05 official Cambridge June 2026 reference-only set mismatch=%',v_refs;
  end if;

  select pg_get_functiondef('private.exam_prep_stage5_raw_readiness_v1(uuid,bigint,text)'::regprocedure)
  into v_def;
  if position('s.session_type=''paper''' in v_def)=0
     or position('t.attempt_kind=''full_paper''' in v_def)=0
     or position('t.timing_rule=''official_full''' in v_def)=0
     or position('t.comparison_scope=''full''' in v_def)=0
     or position('and t.strict_timing' in v_def)=0
     or position('private.exam_prep_timed_score_comparable_v1(t.session_id)' in v_def)=0 then
    raise exception 'P2-05 last-three comparable-paper filter drifted';
  end if;

  select pg_get_functiondef('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)'::regprocedure)
  into v_def;
  if position('three_comparable_attempts_incomplete' in v_def)=0
     or position('threshold_configuration_pending' in v_def)=0
     or position('objective_skill_stability_incomplete' in v_def)=0
     or position('corrective_cycles_open' in v_def)=0
     or position('last_three_below_individual_threshold' in v_def)=0
     or position('unattempted_marks_not_minimal' in v_def)=0
     or position('after_time_dependency_not_closed' in v_def)=0 then
    raise exception 'P2-05 readiness fail-closed reason chain drifted';
  end if;

  select c.relrowsecurity into v_rls
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='private' and c.relname='exam_prep_readiness_signoffs';
  if not coalesce(v_rls,false) then
    raise exception 'P2-05 readiness signoff RLS missing';
  end if;

  if not exists(
    select 1
    from pg_trigger t
    join pg_class c on c.oid=t.tgrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='private'
      and c.relname='exam_prep_readiness_signoffs'
      and t.tgname='exam_prep_readiness_signoffs_immutable_v1'
      and not t.tgisinternal
  ) then
    raise exception 'P2-05 immutable readiness signoff trigger missing';
  end if;

  select pg_get_functiondef('private.exam_prep_materialize_readiness_signoff_v1()'::regprocedure)
  into v_def;
  if position('exam_prep_second_check_must_be_independent' in v_def)=0
     or position('exam_prep_readiness_assignment_not_active' in v_def)=0
     or position('exam_prep_readiness_second_check_stale' in v_def)=0
     or position('exam_prep_readiness_evidence_changed' in v_def)=0
     or position('lead_mentor' in v_def)=0
     or position('academic_moderator' in v_def)=0 then
    raise exception 'P2-05 Mentor Verified second-check/evidence binding drifted';
  end if;

  select pg_get_functiondef('public.get_exam_prep_readiness_summary_safe_v1(text)'::regprocedure)
  into v_def;
  if position('not_official_cambridge_grade' in v_def)=0
     or position('mentor_verification_optional_for_core' in v_def)=0
     or position('p1_p5_separate' in v_def)=0
     or position('latest_official_reference' in v_def)=0
     or position('Official Cambridge 9709 · June 2026 reference' in v_def)=0
     or position('readiness_gate_active'',false' in v_def)=0 then
    raise exception 'P2-05 learner summary safety flags missing';
  end if;

  if position('rule_version' in v_def)>0
     or position('program_version_id'',v_program' in v_def)>0
     or position('last_three_evaluation' in v_def)>0
     or position('readiness_fingerprint' in v_def)>0 then
    raise exception 'P2-05 internal readiness implementation detail leaked through learner summary';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_readiness_summary_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_readiness_summary_safe_v1(text)','EXECUTE') then
    raise exception 'P2-05 learner summary RPC privilege boundary drift';
  end if;

  -- Mentor verification must be optional service value, not a Core progression dependency.
  select count(*) into v_bad
  from private.exam_prep_operational_stage_rules
  where status='active'
    and lower(coalesce(transition_rule,'')) like '%mentor verified%';
  if v_bad<>0 then
    raise exception 'P2-05 Mentor Verified wording leaked into automatic stage progression rows=%',v_bad;
  end if;
END
$$;

\echo 'P2-05 App Readiness + optional Mentor Verified Readiness contract: GREEN'
