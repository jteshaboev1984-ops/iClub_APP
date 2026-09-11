\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p238.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-38 REFUSED: p238.isolated_db=true is required. Use only a disposable/local/dev database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_cohort_id bigint;
  v_payload jsonb;
  v_blocked boolean:=false;
BEGIN
  SELECT id INTO v_cohort_id
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='p236-ci-cohort';

  IF v_cohort_id IS NULL THEN
    INSERT INTO private.exam_prep_beta_cohorts(
      cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes
    ) VALUES(
      'p236-ci-cohort','math_as_p1_p5','draft',12,0,72,'isolated P2-38 cleanup validation'
    ) RETURNING id INTO v_cohort_id;
  END IF;

  INSERT INTO private.exam_prep_beta_expansion_controls(
    cohort_id,development_data_state,required_validation_generation
  ) VALUES(v_cohort_id,'synthetic_present','p2_36_expansion_v1')
  ON CONFLICT(cohort_id) DO UPDATE SET
    development_data_state='synthetic_present',
    real_review_epoch_started_at=null,
    cleanup_evidence_ref=null,
    updated_at=now();

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_uid,'authenticated','authenticated',
    'p238-'||replace(v_uid::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P238','Cleanup Gate','en',now(),false);

  INSERT INTO private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status,activated_at
  ) VALUES(v_cohort_id,v_uid,'core',1,'active',now());

  -- This row is intentionally outside the old P2-36 residue list.
  INSERT INTO private.exam_prep_ai_daily_usage(user_id)
  VALUES(v_uid);

  v_payload:=public.get_exam_prep_beta_cleanup_readiness_v1('p236-ci-cohort');
  IF coalesce((v_payload->>'ready_to_arm')::boolean,true) THEN
    RAISE EXCEPTION 'P2-38 cleanup gate falsely reports ready with AI usage residue';
  END IF;
  IF coalesce((v_payload->>'blocking_rows')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-38 expected exactly one blocking row, got %',v_payload->>'blocking_rows';
  END IF;
  IF coalesce((v_payload#>>'{blocking_counts,ai_daily_usage}')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-38 AI usage residue missing from breakdown';
  END IF;

  BEGIN
    PERFORM public.arm_exam_prep_beta_real_monitoring_v1('p236-ci-cohort','p2-38-blocked-proof');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'exam_prep_synthetic_progress_cleanup_incomplete rows=%' THEN
      RAISE;
    END IF;
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-38 arm path did not fail closed with residue';
  END IF;

  DELETE FROM private.exam_prep_ai_daily_usage WHERE user_id=v_uid;
  v_payload:=public.get_exam_prep_beta_cleanup_readiness_v1('p236-ci-cohort');
  IF NOT coalesce((v_payload->>'ready_to_arm')::boolean,false) THEN
    RAISE EXCEPTION 'P2-38 clean cohort did not become armable: %',v_payload;
  END IF;
  IF coalesce((v_payload->>'blocking_rows')::int,-1)<>0 THEN
    RAISE EXCEPTION 'P2-38 clean cohort still reports residue: %',v_payload;
  END IF;
  IF coalesce((v_payload#>>'{preserved_controls,active_beta_members}')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-38 active beta membership was not preserved in cleanup model';
  END IF;

  PERFORM public.arm_exam_prep_beta_real_monitoring_v1('p236-ci-cohort','p2-38-clean-proof');
  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_beta_expansion_controls
    WHERE cohort_id=v_cohort_id
      AND development_data_state='real_monitoring'
      AND real_review_epoch_started_at IS NOT NULL
      AND cleanup_evidence_ref='p2-38-clean-proof'
  ) THEN
    RAISE EXCEPTION 'P2-38 clean arm did not persist real-monitoring state';
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM public.arm_exam_prep_beta_real_monitoring_v1('p236-ci-cohort','p2-38-rearm-proof');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM<>'exam_prep_real_monitoring_already_armed' THEN
      RAISE;
    END IF;
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-38 re-arm unexpectedly reset the real-review epoch';
  END IF;
END
$$;

ROLLBACK;

SELECT 'P2-38 cleanup residue gate matrix: GREEN' AS result;
