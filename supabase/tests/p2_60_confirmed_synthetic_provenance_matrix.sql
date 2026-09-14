\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p260.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-60 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_cohort_id bigint;
  v_program bigint;
  v_assessment record;
  v_auth uuid;
  v_session uuid;
  v_payload jsonb;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';

  SELECT a.id,a.assessment_version,a.component_code,a.content_version_id,cv.program_version_id
  INTO v_assessment
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE a.assessment_type='diagnostic'
    AND a.status='published'
    AND cv.status='published'
  ORDER BY a.id
  LIMIT 1;

  IF v_program IS NULL OR v_assessment.id IS NULL THEN
    RAISE EXCEPTION 'P2-60 canonical diagnostic fixture missing';
  END IF;

  INSERT INTO private.exam_prep_beta_cohorts(
    cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes
  ) VALUES(
    'p260-ci-cohort','math_as_p1_p5','canary',12,0,72,
    'isolated P2-60 confirmed synthetic provenance validation'
  ) RETURNING id INTO v_cohort_id;

  INSERT INTO private.exam_prep_beta_expansion_controls(
    cohort_id,development_data_state,required_validation_generation
  ) VALUES(v_cohort_id,'synthetic_present','p2_36_expansion_v1');

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_uid,'authenticated','authenticated',
    'p260-'||replace(v_uid::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P260','Confirmed Synthetic','en',now(),false);

  INSERT INTO private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status
  ) VALUES(v_cohort_id,v_uid,'core',1,'candidate');
  PERFORM public.record_exam_prep_beta_consent_v1(
    'p260-ci-cohort',v_uid,'p2-60-test-consent',now()
  );
  UPDATE private.exam_prep_beta_members
  SET member_status='active',activated_at=now(),updated_at=now()
  WHERE cohort_id=v_cohort_id AND user_id=v_uid;
  UPDATE private.exam_prep_beta_cohorts
  SET current_wave=1,updated_at=now()
  WHERE id=v_cohort_id;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    v_uid,v_assessment.id,v_assessment.component_code,'diagnostic','issued',
    now()+interval '1 hour','P2-60 confirmed synthetic fixture',true
  ) RETURNING id INTO v_auth;

  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract,finalized_at
  ) VALUES(
    v_auth,v_uid,v_assessment.program_version_id,v_assessment.content_version_id,
    v_assessment.id,v_assessment.assessment_version,v_assessment.component_code,
    'diagnostic','finalized','ep-diag-p260-confirmed-test',1,'{}'::jsonb,now()
  ) RETURNING id INTO v_session;

  v_payload:=private.exam_prep_beta_cleanup_provenance_v1(v_cohort_id);
  IF coalesce((v_payload->>'eligible')::boolean,true)
     OR coalesce((v_payload->>'ambiguous_sessions')::int,0)<>1
     OR coalesce((v_payload->>'confirmed_synthetic_sessions')::int,0)<>0 THEN
    RAISE EXCEPTION 'P2-60 unconfirmed browser-shaped session was not blocked: %',v_payload;
  END IF;

  INSERT INTO private.exam_prep_beta_synthetic_session_overrides(
    cohort_id,client_idempotency_key,provenance_status,evidence_ref,confirmation_note
  ) VALUES(
    v_cohort_id,'ep-diag-p260-confirmed-test','confirmed_synthetic',
    'p2-60-isolated-proof','Isolated operator-confirmed test provenance fixture.'
  );

  v_payload:=private.exam_prep_beta_cleanup_provenance_v1(v_cohort_id);
  IF coalesce((v_payload->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_payload->>'ambiguous_sessions')::int,-1)<>0
     OR coalesce((v_payload->>'confirmed_synthetic_sessions')::int,0)<>1
     OR coalesce((v_payload->>'synthetic_sessions')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-60 confirmed synthetic provenance did not become eligible: %',v_payload;
  END IF;

  IF has_table_privilege('anon','private.exam_prep_beta_synthetic_session_overrides','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_beta_synthetic_session_overrides','SELECT')
     OR has_table_privilege('anon','private.exam_prep_beta_synthetic_session_overrides','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_beta_synthetic_session_overrides','INSERT') THEN
    RAISE EXCEPTION 'P2-60 provenance overrides became browser-accessible';
  END IF;

  IF NOT has_function_privilege('service_role','public.cleanup_exam_prep_beta_synthetic_progress_v2(text,integer,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.cleanup_exam_prep_beta_synthetic_progress_v2(text,integer,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-60 governed cleanup RPC privilege boundary changed';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p260-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-60 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts WHERE cohort_key='p260-ci-cohort';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-60 rollback left synthetic cohort rows=%',v_count; END IF;
END
$$;

\echo 'P2-60 confirmed synthetic provenance matrix: GREEN'
