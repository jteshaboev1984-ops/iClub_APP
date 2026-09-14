\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p263.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-63 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_synth uuid:=gen_random_uuid();
  v_real_shaped uuid:=gen_random_uuid();
  v_bad_email uuid:=gen_random_uuid();
  v_cohort_id bigint;
  v_run_id text:='SV-P263CI-0001';
  v_preflight jsonb;
  v_report jsonb;
  v_blocked boolean;
BEGIN
  INSERT INTO private.exam_prep_beta_cohorts(
    cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes
  ) VALUES(
    'p263-ci-real-cohort','math_as_p1_p5','draft',12,0,72,
    'isolated P2-63 real/synthetic firewall validation'
  ) RETURNING id INTO v_cohort_id;

  PERFORM private.register_exam_prep_synthetic_validation_run_v1(
    v_run_id,'p263-v1',repeat('a',40),'p2-64',263,'core','p2-63-isolated-proof'
  );

  -- Fresh dedicated synthetic account: auth/public identity exists, but no Exam
  -- Prep state, legacy attempts or certificates exist yet.
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_synth,'authenticated','authenticated',
    'exam-prep-sv-p263-'||replace(v_synth::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_synth,'P263','Synthetic','en',now(),false);

  v_preflight:=private.exam_prep_synthetic_identity_preflight_v1(v_synth);
  IF coalesce((v_preflight->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_preflight->>'private_exam_prep_rows')::int,-1)<>0
     OR coalesce((v_preflight->>'practice_attempts')::int,-1)<>0
     OR coalesce((v_preflight->>'tour_attempts')::int,-1)<>0
     OR coalesce((v_preflight->>'certificates')::int,-1)<>0 THEN
    RAISE EXCEPTION 'P2-63 clean synthetic identity was not eligible: %',v_preflight;
  END IF;

  INSERT INTO private.exam_prep_synthetic_identities(
    user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
  ) VALUES(
    v_synth,v_run_id,'learner','SVF-P263-CLEAN','active','p2-63-isolated-proof',
    'Dedicated isolated synthetic learner identity for firewall validation.'
  );

  IF NOT private.is_exam_prep_synthetic_identity_v1(v_synth) THEN
    RAISE EXCEPTION 'P2-63 synthetic identity registry lookup failed';
  END IF;

  -- Synthetic identity -> real beta membership must fail, even for service-role
  -- style direct database writes.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_beta_members(
      cohort_id,user_id,service_mode,activation_wave,member_status
    ) VALUES(v_cohort_id,v_synth,'core',1,'candidate');
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_identity_forbidden_in_real_beta_control' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-63 synthetic identity entered real beta membership';
  END IF;

  -- Synthetic identity -> real beta consent must fail too.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_beta_consents(
      cohort_id,user_id,consent_status,consented_at,grant_evidence_ref
    ) VALUES(v_cohort_id,v_synth,'granted',now(),'p2-63-forbidden-consent');
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_identity_forbidden_in_real_beta_control' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-63 synthetic identity received real beta consent';
  END IF;

  -- A real beta cohort entitlement is also forbidden. A cohort-less entitlement
  -- remains available for future dedicated synthetic harness plumbing.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_feature_entitlements(
      user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
    ) VALUES(
      v_synth,'active',true,false,false,'p263-ci-real-cohort',now()
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_identity_forbidden_in_real_beta_control' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-63 synthetic identity received a real beta entitlement';
  END IF;

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_synth,'active',true,false,false,null,now());

  -- Reverse direction: an account already carrying real-beta/Exam Prep control
  -- state cannot later be relabelled synthetic, even if its email looks synthetic.
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_real_shaped,'authenticated','authenticated',
    'exam-prep-sv-p263-real-shaped-'||replace(v_real_shaped::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_real_shaped,'P263','Real shaped','en',now(),false);
  INSERT INTO private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status
  ) VALUES(v_cohort_id,v_real_shaped,'core',1,'candidate');

  v_preflight:=private.exam_prep_synthetic_identity_preflight_v1(v_real_shaped);
  IF coalesce((v_preflight->>'eligible')::boolean,true)
     OR coalesce((v_preflight->>'reason_code'),'')<>'preexisting_exam_prep_state'
     OR coalesce((v_preflight->>'private_exam_prep_rows')::int,0)<1 THEN
    RAISE EXCEPTION 'P2-63 preexisting real-beta state was not detected: %',v_preflight;
  END IF;

  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_synthetic_identities(
      user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
    ) VALUES(
      v_real_shaped,v_run_id,'learner','SVF-P263-REAL-SHAPED','active','p2-63-relabel-proof',
      'This insert must fail because the account already has beta state.'
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_identity_preflight_failed: preexisting_exam_prep_state' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-63 real-beta identity was relabelled synthetic';
  END IF;

  -- Dedicated synthetic naming is part of the structural registration boundary.
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_bad_email,'authenticated','authenticated',
    'p263-normal-looking-'||replace(v_bad_email::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_bad_email,'P263','Bad email','en',now(),false);

  v_preflight:=private.exam_prep_synthetic_identity_preflight_v1(v_bad_email);
  IF coalesce((v_preflight->>'eligible')::boolean,true)
     OR coalesce((v_preflight->>'reason_code'),'')<>'synthetic_email_pattern_required' THEN
    RAISE EXCEPTION 'P2-63 synthetic naming guard failed: %',v_preflight;
  END IF;

  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_synthetic_identities(
      user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
    ) VALUES(
      v_bad_email,v_run_id,'learner','SVF-P263-BAD-EMAIL','active','p2-63-email-proof',
      'This insert must fail because the identity is not dedicated synthetic.'
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_identity_preflight_failed: synthetic_email_pattern_required' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-63 ordinary identity was accepted as synthetic';
  END IF;

  v_report:=private.exam_prep_synthetic_real_boundary_report_v1();
  IF coalesce((v_report->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_report->>'synthetic_identities')::int,-1)<>1
     OR coalesce((v_report->>'beta_member_overlap')::int,-1)<>0
     OR coalesce((v_report->>'beta_consent_overlap')::int,-1)<>0
     OR coalesce((v_report->>'beta_entitlement_overlap')::int,-1)<>0 THEN
    RAISE EXCEPTION 'P2-63 boundary report not clean: %',v_report;
  END IF;

  -- Browser roles cannot inspect or mutate the classification boundary or call
  -- the private preflight/report helpers.
  IF has_table_privilege('anon','private.exam_prep_synthetic_identities','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_identities','SELECT')
     OR has_table_privilege('anon','private.exam_prep_synthetic_identities','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_identities','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_identities','UPDATE') THEN
    RAISE EXCEPTION 'P2-63 synthetic identity registry became browser-accessible';
  END IF;

  IF has_function_privilege('anon','private.exam_prep_synthetic_identity_preflight_v1(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_synthetic_identity_preflight_v1(uuid)','EXECUTE')
     OR has_function_privilege('anon','private.is_exam_prep_synthetic_identity_v1(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','private.is_exam_prep_synthetic_identity_v1(uuid)','EXECUTE')
     OR has_function_privilege('anon','private.exam_prep_synthetic_real_boundary_report_v1()','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_synthetic_real_boundary_report_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-63 private firewall helpers became browser-callable';
  END IF;

  IF NOT has_function_privilege('service_role','private.exam_prep_synthetic_identity_preflight_v1(uuid)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.exam_prep_synthetic_real_boundary_report_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-63 service-role firewall inspection boundary missing';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM auth.users
  WHERE email LIKE 'exam-prep-sv-p263-%@invalid.example'
     OR email LIKE 'p263-normal-looking-%@invalid.example';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-63 rollback left synthetic auth users=%',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='p263-ci-real-cohort';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-63 rollback left synthetic firewall cohort rows=%',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_identities;
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-63 rollback left synthetic identity registry rows=%',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_validation_runs
  WHERE run_id='SV-P263CI-0001';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-63 rollback left synthetic run registry rows=%',v_count;
  END IF;
END
$$;

\echo 'P2-63 bidirectional synthetic firewall matrix: GREEN'