\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p261.isolated_db', true) IS DISTINCT FROM 'true'
     AND current_setting('p238.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-61 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_cohort_id bigint;
  v_result jsonb;
  v_epoch timestamptz;
  v_until timestamptz;
  v_blocked boolean:=false;
BEGIN
  INSERT INTO private.exam_prep_beta_cohorts(
    cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,
    started_at,monitoring_until,notes
  ) VALUES(
    'p261-ci-cohort','math_as_p1_p5','canary',12,1,72,
    now()-interval '7 days',now()-interval '4 days',
    'isolated P2-61 real monitoring window validation'
  ) RETURNING id INTO v_cohort_id;

  INSERT INTO private.exam_prep_beta_expansion_controls(
    cohort_id,development_data_state,required_validation_generation,cleanup_evidence_ref
  ) VALUES(v_cohort_id,'clean','p2_36_expansion_v1','p2-61-clean-fixture');

  v_result:=public.arm_exam_prep_beta_real_monitoring_v1(
    'p261-ci-cohort','p2-61-isolated-cleanup-proof'
  );

  v_epoch:=(v_result->>'real_review_epoch_started_at')::timestamptz;
  v_until:=(v_result->>'monitoring_until')::timestamptz;

  IF v_result->>'development_data_state'<>'real_monitoring'
     OR coalesce((v_result->>'synthetic_progress_rows')::int,-1)<>0
     OR coalesce((v_result->>'monitoring_hours')::int,-1)<>72 THEN
    RAISE EXCEPTION 'P2-61 arm result contract wrong: %',v_result;
  END IF;

  IF v_until < v_epoch + interval '71 hours 59 minutes'
     OR v_until > v_epoch + interval '72 hours 1 minute' THEN
    RAISE EXCEPTION 'P2-61 monitoring window is not anchored to real epoch: epoch=% until=%',v_epoch,v_until;
  END IF;

  IF (select monitoring_until from private.exam_prep_beta_cohorts where id=v_cohort_id)<>v_until THEN
    RAISE EXCEPTION 'P2-61 cohort monitoring_until did not persist real window';
  END IF;

  BEGIN
    PERFORM public.arm_exam_prep_beta_real_monitoring_v1(
      'p261-ci-cohort','p2-61-repeat-arm-proof'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM<>'exam_prep_real_monitoring_already_armed' THEN RAISE; END IF;
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-61 repeated real-monitoring arm was not blocked';
  END IF;

  IF has_function_privilege('anon','public.arm_exam_prep_beta_real_monitoring_v1(text,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.arm_exam_prep_beta_real_monitoring_v1(text,text)','EXECUTE')
     OR NOT has_function_privilege('service_role','public.arm_exam_prep_beta_real_monitoring_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-61 arm RPC grant boundary wrong';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts WHERE cohort_key='p261-ci-cohort';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-61 rollback left cohort residue=%',v_count; END IF;
END
$$;

\echo 'P2-61 real monitoring window matrix: GREEN'
