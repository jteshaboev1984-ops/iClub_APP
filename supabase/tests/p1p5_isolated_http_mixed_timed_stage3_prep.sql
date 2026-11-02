-- CI-only isolated synthetic Stage 3 evidence preparation.
-- This is NOT a production migration. In the SAME psql process, prepend
-- the pure pg_temp helper functions from p2_69_full_stage0_6_core_simulation.sql
-- (but NOT its BEGIN, $main$ body, COMMIT or rollback statements).
-- Helpers issue test-only direct published-content authorizations but submit
-- normal server-graded answers through public RPCs. All later positive
-- mixed/timed authorization and scoring is driven over real HTTP/JWT.
\set ON_ERROR_STOP on
DO $$
DECLARE
  v_run CONSTANT text:='SV-P1P5-MIXED-TIMED-HTTP-01';
  v_uid uuid;
  v_clock jsonb;
  v_program bigint;
  v_progress jsonb;
  v_s jsonb;
  v_session uuid;
  v_cycles integer;
  v_component text;
  v_stage int;
BEGIN
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
     OR (SELECT count(*) FROM public.users)<>2
     OR (SELECT count(*) FROM auth.users)<>2
     OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_validation_runs WHERE run_id=v_run)
  THEN RAISE EXCEPTION 'REFUSED: Stage 3 test needs fresh disposable PG17, exactly 2 fake users'; END IF;

  PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',repeat('b',40),'p1p5-http-stage3',
    26912,'core','p1p5-stage3-published-content-http-evidence'
  );
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P1P5-MIXED-TIMED-01',
    'p1p5-stage3-canonical-identity-proof',
    'Disposable real HTTP mixed and timed academic boundary','en'
  );
  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,
    jsonb_build_object('purpose','real-http-mixed-timed','source','published-migrations')
  );
  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(
    v_run,'p1p5-stage3-clock-init-proof'
  );
  IF v_clock->>'clock_status'<>'active' THEN RAISE EXCEPTION 'clock init not active'; END IF;

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_uid,'active',true,false,false,null,now()-interval '1 minute');

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,6);
  SELECT program_version_id INTO v_program
  FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_program IS NULL THEN RAISE EXCEPTION 'canonical synthetic exam profile missing'; END IF;

  -- All-correct diagnostic Stage 0, with actual public RPC and frozen content;
  -- do not directly set any stage or insert synthetic mastery records.
  FOREACH v_component IN ARRAY array['P1','P5'] LOOP
    v_cycles:=0;
    LOOP
      v_progress:=public.get_exam_prep_diagnostic_progress_safe_v1(v_component);
      EXIT WHEN coalesce((v_progress->>'stage0_complete')::boolean,false);
      v_cycles:=v_cycles+1;
      IF v_cycles>28 THEN RAISE EXCEPTION 'Stage 0 failed to converge %',v_component; END IF;
      v_s:=public.start_exam_prep_next_diagnostic_safe_v1(
        v_component,'stage3-prep-'||v_component||'-diag-'||v_cycles::text
      );
      v_session:=(v_s->>'session_id')::uuid;
      PERFORM pg_temp.p269_complete_session_correct_v1(
        v_session,'stage3-prep-'||v_component||'-diag-'||v_cycles::text
      );
    END LOOP;
    IF v_cycles<1 THEN RAISE EXCEPTION 'no diagnostic actually completed %',v_component; END IF;
  END LOOP;

  -- Evidence threshold from canonical P2-69 rules: 37/45 P1 and 30/36 P5
  -- skills L2, all by genuine objective grading, not state manipulation.
  PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P1',37);
  PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P5',30);
  FOREACH v_component IN ARRAY array['P1','P5'] LOOP
    PERFORM private.rebuild_exam_prep_state_v1(v_uid,v_component);
    SELECT operational_stage INTO v_stage FROM private.exam_prep_stage_states
    WHERE user_id=v_uid AND program_version_id=v_program
      AND component_code=v_component AND engine_version='objective_state_v1';
    IF v_stage<3 THEN RAISE EXCEPTION 'Stage3 requires real evidence % got %',v_component,v_stage; END IF;
  END LOOP;

  IF EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
    OR EXISTS(SELECT 1 FROM public.practice_attempts)
    OR EXISTS(SELECT 1 FROM public.tour_attempts)
    OR EXISTS(SELECT 1 FROM public.certificates)
  THEN RAISE EXCEPTION 'Stage3 synthetic evidence touched legacy/release tables'; END IF;
END $$;
