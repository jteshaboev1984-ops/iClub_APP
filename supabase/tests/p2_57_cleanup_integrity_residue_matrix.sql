\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p257.isolated_db', true) IS DISTINCT FROM 'true'
     AND current_setting('p238.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-57 REFUSED: p257.isolated_db=true or p238.isolated_db=true is required. Use only an ephemeral test database.';
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
    RAISE EXCEPTION 'P2-57 canonical program/diagnostic fixture missing';
  END IF;

  INSERT INTO private.exam_prep_beta_cohorts(
    cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes
  ) VALUES(
    'p257-ci-cohort','math_as_p1_p5','draft',12,0,72,'isolated P2-57 cleanup-integrity validation'
  ) RETURNING id INTO v_cohort_id;

  INSERT INTO private.exam_prep_beta_expansion_controls(
    cohort_id,development_data_state,required_validation_generation
  ) VALUES(v_cohort_id,'synthetic_present','p2_36_expansion_v1');

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_uid,'authenticated','authenticated',
    'p257-'||replace(v_uid::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P257','Integrity Residue','en',now(),false);

  INSERT INTO private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status
  ) VALUES(v_cohort_id,v_uid,'core',1,'candidate');

  PERFORM public.record_exam_prep_beta_consent_v1(
    'p257-ci-cohort',v_uid,'p2-57-test-consent',now()
  );

  UPDATE private.exam_prep_beta_members
  SET member_status='active',activated_at=now(),updated_at=now()
  WHERE cohort_id=v_cohort_id AND user_id=v_uid;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    v_uid,v_assessment.id,v_assessment.component_code,'diagnostic','issued',
    now()+interval '1 hour','P2-57 integrity residue fixture',true
  ) RETURNING id INTO v_auth;

  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract
  ) VALUES(
    v_auth,v_uid,v_assessment.program_version_id,v_assessment.content_version_id,v_assessment.id,v_assessment.assessment_version,
    v_assessment.component_code,'diagnostic','active','p257-integrity-session',1,'{}'::jsonb
  ) RETURNING id INTO v_session;

  UPDATE private.exam_prep_session_authorizations
  SET status='consumed',consumed_at=now(),consumed_session_id=v_session
  WHERE id=v_auth;

  INSERT INTO private.exam_prep_integrity_events(
    session_id,user_id,event_type,client_event_id
  ) VALUES(
    v_session,v_uid,'visibility_hidden','p257-integrity-event-0001'
  );

  v_payload:=public.get_exam_prep_beta_cleanup_readiness_v1('p257-ci-cohort');

  IF coalesce((v_payload->>'ready_to_arm')::boolean,true) THEN
    RAISE EXCEPTION 'P2-57 cleanup gate falsely reports ready with integrity residue';
  END IF;
  IF coalesce((v_payload#>>'{blocking_counts,integrity_events}')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-57 integrity residue missing from cleanup breakdown: %',v_payload;
  END IF;
  IF coalesce((v_payload#>>'{blocking_counts,sessions}')::int,0)<>1
     OR coalesce((v_payload#>>'{blocking_counts,session_authorizations}')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-57 session fixture missing from cleanup breakdown: %',v_payload;
  END IF;
  IF coalesce((v_payload->>'blocking_rows')::int,0)<>3 THEN
    RAISE EXCEPTION 'P2-57 expected three blocking rows (authorization/session/integrity), got %',v_payload->>'blocking_rows';
  END IF;

  IF has_function_privilege('anon','private.exam_prep_beta_synthetic_residue_v2(bigint)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_beta_synthetic_residue_v2(bigint)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-57 private cleanup residue helper became browser-executable';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p257-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-57 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_integrity_events WHERE client_event_id='p257-integrity-event-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-57 rollback left integrity residue=%',v_count; END IF;
END
$$;

\echo 'P2-57 cleanup integrity residue matrix: GREEN'
