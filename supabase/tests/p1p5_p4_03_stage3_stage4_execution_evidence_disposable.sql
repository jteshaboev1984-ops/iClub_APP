-- Issue #450 P4-03: source-accurate Stage3/4 signed-paper proof in disposable PG17.
-- Runs AFTER real JWT/PostgREST answered P1/P5 full paper + timed sections,
-- BEFORE existing reversible synthetic cleanup. No production data access.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
  v_owner uuid;
  v_program bigint;
  v_component text;
  v_stage3 jsonb;
  v_stage4 jsonb;
  v_timed jsonb;
  v_stage5 jsonb;
  v_rule text;
  v_paper_count int;
  v_executed int;
  v_scored int;
  v_stage int;
  v_source text;
  v_sig text;
BEGIN
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
     OR (SELECT count(*) FROM public.users)<>3
     OR (SELECT count(*) FROM auth.users)<>3
  THEN RAISE EXCEPTION 'P4-03 REFUSED: disposable PG17 with three synthetic actors only'; END IF;

  SELECT si.user_id INTO STRICT v_owner
  FROM private.exam_prep_synthetic_identities si
  WHERE si.run_id='SV-P1P5-MIXED-TIMED-HTTP-01'
    AND si.identity_status='active' AND si.identity_kind='learner';

  SELECT p.program_version_id INTO STRICT v_program
  FROM private.exam_prep_exam_profiles p
  WHERE p.user_id=v_owner;

  FOREACH v_sig IN ARRAY ARRAY[
    'private.exam_prep_stage3_exit_status_v1(uuid,bigint,text)',
    'private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)',
    'private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)'
  ] LOOP
    v_source:=pg_get_functiondef(to_regprocedure(v_sig));
    IF position('private.exam_prep_timed_execution_comparable_v1(t.session_id)' IN v_source)=0
       OR position('private.exam_prep_timed_score_comparable_v1(t.session_id)' IN v_source)>0
       OR has_function_privilege('anon',v_sig,'EXECUTE')
       OR has_function_privilege('authenticated',v_sig,'EXECUTE')
       OR NOT has_function_privilege('service_role',v_sig,'EXECUTE')
    THEN RAISE EXCEPTION 'P4-03 source/ACL contract broken for %',v_sig; END IF;
  END LOOP;
  -- NEVER change actual scoring or Stage5 eligibility as a side-effect.
  v_source:=pg_get_functiondef(
    'private.exam_prep_stage5_raw_readiness_v1(uuid,bigint,text)'::regprocedure);
  IF position('private.exam_prep_timed_score_comparable_v1(t.session_id)' IN v_source)=0
  THEN RAISE EXCEPTION 'P4-03 modified Stage5 ungraded score boundary'; END IF;

  SELECT rule_version INTO v_rule
  FROM private.exam_prep_stage4_exit_rules WHERE status='active'
  ORDER BY created_at DESC LIMIT 1;
  IF v_rule IS NULL THEN RAISE EXCEPTION 'P4-03 active Stage4 evaluation rule missing'; END IF;

  FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
    SELECT count(*)::int,
      count(*) FILTER(WHERE private.exam_prep_timed_execution_comparable_v1(t.session_id))::int,
      count(*) FILTER(WHERE private.exam_prep_timed_score_comparable_v1(t.session_id))::int
    INTO v_paper_count,v_executed,v_scored
    FROM private.exam_prep_timed_attempt_results t
    JOIN private.exam_prep_sessions s ON s.id=t.session_id
    WHERE s.user_id=v_owner AND t.user_id=v_owner
      AND t.component_code=v_component AND s.status='finalized'
      AND s.session_type='paper' AND t.attempt_kind='full_paper'
      AND t.pending_review_in_time_marks>0 AND t.objective_marks_in_time=0;

    v_stage3:=private.exam_prep_stage3_exit_status_v1(v_owner,v_program,v_component);
    v_stage4:=private.exam_prep_stage4_raw_evidence_v1(v_owner,v_program,v_component);
    v_timed:=private.exam_prep_stage4_timed_section_gate_v1(
      v_owner,v_program,v_component,v_rule);
    v_stage5:=private.exam_prep_stage5_readiness_status_v1(v_owner,v_program,v_component);
    SELECT operational_stage INTO v_stage
    FROM private.exam_prep_stage_states
    WHERE user_id=v_owner AND program_version_id=v_program
      AND component_code=v_component AND engine_version='objective_state_v1';

    IF v_paper_count<>1 OR v_executed<>1 OR v_scored<>0
       OR (v_stage3->>'comparable_full_baseline_count')::int<>1
       OR (v_stage4->>'comparable_full_attempt_count_total')::int<>1
       OR (v_stage4->>'max_compatible_family_attempt_count')::int<>1
       OR (v_timed->>'completed_distinct_timed_section_count')::int<1
       OR (v_timed->>'required_majority_count')::int<>2
       OR coalesce((v_timed->>'ready')::boolean,false)
       OR coalesce((v_stage5->>'stage5_ready')::boolean,false)
       OR v_stage<>3
    THEN RAISE EXCEPTION
      'P4-03 source-backed evidence failed % papers % executed % scored % stage3 % stage4 % timed % stage5 % operational %',
      v_component,v_paper_count,v_executed,v_scored,v_stage3,v_stage4,v_timed,v_stage5,v_stage;
    END IF;
    RAISE NOTICE
      'P4-03 PASS %: 1 real answered written Paper counts for Stage3 and Stage4 execution, timed section tracked; 0 graded papers, Stage5 not-ready, Core stage3 unchanged',
      v_component;
  END LOOP;

  RAISE NOTICE 'P4-03 PASS: both components preserve ACL, original scored reader, genuine timing, corrections and independent Core state; no promotion';
END
$proof$;
