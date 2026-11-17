\set ON_ERROR_STOP on
BEGIN;
SET LOCAL iclub.e2e_isolated = 'true';
-- P2-69 proven pg_temp helper definitions are inserted by the wrapper here.
-- The following DO block runs in the SAME disposable psql connection.
DO $stage_on$
DECLARE
  v_run constant text:='SV-P1P5-STAGEON-UI-01';
  v_uid uuid; v_program bigint; v_component text; v_progress jsonb;
  v_start jsonb; v_session uuid; v_round integer; v_mix integer;
  v_retests integer; v_p1_stage integer; v_p5_stage integer;
  v_p1_l3 integer; v_p5_l3 integer; v_check jsonb;
  v_before text;
BEGIN
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
     OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_validation_runs WHERE run_id=v_run)
  THEN RAISE EXCEPTION 'REFUSED: fresh disposable PG17 Stage-ON fixture only'; END IF;
  v_before:=(SELECT count(*)::text FROM private.exam_prep_timed_attempt_results) || '/' ||
    (SELECT count(*)::text FROM public.practice_attempts) || '/' ||
    (SELECT count(*)::text FROM public.tour_attempts) || '/' ||
    (SELECT count(*)::text FROM public.certificates);
  PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',
    '5a52e40b1c8c732f4cd498595f1fce2d0ced4242',
    'p1p5-stageon-ui',26905,'core','source-backed-stage-on-chromium'
  );
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P1P5-STAGEON-UI-01',
    'p1p5-real-objective-evidence','Ephemeral objective learner for signed UI','en'
  );
  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,jsonb_build_object('purpose','real-evidence-stageon-browser'));
  PERFORM private.initialize_exam_prep_synthetic_clock_v1(v_run,'stageon-clock');
  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
  ) VALUES(v_uid,'active',true,false,false,clock_timestamp()-interval '1 minute');
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,6);
  SELECT program_version_id INTO v_program
    FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_program IS NULL THEN RAISE EXCEPTION 'Missing real exam profile'; END IF;

  -- Complete actual diagnostic RPCs for both P1 and P5, including all raw
  -- objective response/evidence history. Never seed stage projection rows.
  FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
    v_round:=0;
    LOOP
      v_progress:=public.get_exam_prep_diagnostic_progress_safe_v1(v_component);
      EXIT WHEN coalesce((v_progress->>'stage0_complete')::boolean,false);
      v_round:=v_round+1;
      IF v_round>30 THEN RAISE EXCEPTION 'Stage0 failed to converge %',v_component; END IF;
      v_start:=public.start_exam_prep_next_diagnostic_safe_v1(
        v_component,'stageon-'||lower(v_component)||'-diag-'||v_round
      );
      v_session:=(v_start->>'session_id')::uuid;
      PERFORM pg_temp.p269_complete_session_correct_v1(
        v_session,'stageon-'||lower(v_component)||'-diag-'||v_round
      );
    END LOOP;
    IF v_round<1 THEN RAISE EXCEPTION 'No real diagnostic run for %',v_component; END IF;
  END LOOP;

  -- P1 objective Stage6 requires stable L3 for all 45 skills;
  -- P5 intentionally remains short of independently confirmed L3.
  PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P1',45);
  PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P5',36);
  v_mix:=pg_temp.p269_complete_selected_mixed_v1(v_uid,v_program,'P1');
  IF v_mix<1 THEN RAISE EXCEPTION 'No published P1 mixed transfer'; END IF;
  PERFORM pg_temp.p269_advance_days_v1(v_run,7,'Stage-ON fresh retest interval');
  v_retests:=pg_temp.p269_complete_retests_all_skills_v1(v_uid,v_program,'P1');
  IF v_retests<>45 THEN RAISE EXCEPTION 'Missing P1 retest %',v_retests; END IF;

  UPDATE private.exam_prep_hybrid_s4_config_v1 SET stage_gates_enabled=true WHERE singleton;
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,null);
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,null);
  SELECT operational_stage,l3_count INTO v_p1_stage,v_p1_l3
  FROM private.exam_prep_stage_states
  WHERE user_id=v_uid AND component_code='P1'
    AND program_version_id=v_program AND engine_version='objective_state_v1';
  SELECT operational_stage,l3_count INTO v_p5_stage,v_p5_l3
  FROM private.exam_prep_stage_states
  WHERE user_id=v_uid AND component_code='P5'
    AND program_version_id=v_program AND engine_version='objective_state_v1';

  IF v_p1_l3<>45 OR v_p1_stage<>6 THEN
    RAISE EXCEPTION 'P1 Stage6 real finalized evidence not earned stage=% L3=%',
      v_p1_stage,v_p1_l3; END IF;
  IF v_p5_stage>=6 OR v_p5_l3>=36 THEN
    RAISE EXCEPTION 'P5 independently must stay blocked stage=% L3=%',
      v_p5_stage,v_p5_l3; END IF;
  v_check:=private.exam_prep_stage5_hybrid_operational_v1(v_uid,v_program,'P1');
  IF coalesce((v_check->>'ready')::boolean,false) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P1 real objective Stage6 status failed %',v_check; END IF;
  IF (SELECT count(*) FROM private.exam_prep_timed_attempt_results WHERE user_id=v_uid)<>0
  THEN RAISE EXCEPTION 'Synthetic learner obtained unearned Paper marks'; END IF;
  IF v_before IS DISTINCT FROM
    ((SELECT count(*)::text FROM private.exam_prep_timed_attempt_results) || '/' ||
     (SELECT count(*)::text FROM public.practice_attempts) || '/' ||
     (SELECT count(*)::text FROM public.tour_attempts) || '/' ||
     (SELECT count(*)::text FROM public.certificates))
  THEN RAISE EXCEPTION 'Unrelated legacy records changed'; END IF;
  RAISE NOTICE 'STAGEON REAL EVIDENCE PASS: P1 stage % L3 %, P5 stage % L3 %, Paper marks 0',
    v_p1_stage,v_p1_l3,v_p5_stage,v_p5_l3;
END;
$stage_on$;
COMMIT;
