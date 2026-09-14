\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p264.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-64 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_run_id text:='SV-P264CI-0001';
  v_user uuid:=gen_random_uuid();
  v_payload jsonb;
  v_blocked boolean;
  v_event_count int;
BEGIN
  -- Invalid provenance never enters the registry.
  v_blocked:=false;
  BEGIN
    PERFORM private.register_exam_prep_synthetic_validation_run_v1(
      'bad-run','scenario-v1',repeat('a',40),'p2-64',264,'core','p2-64-invalid-proof'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_run_id_invalid' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 invalid run id was accepted';
  END IF;

  v_payload:=private.register_exam_prep_synthetic_validation_run_v1(
    v_run_id,'scenario-v1',repeat('b',40),'p2-64',264,'core','p2-64-isolated-proof'
  );
  IF v_payload->>'run_id'<>v_run_id
     OR v_payload->>'run_status'<>'registered'
     OR v_payload->>'cleanup_status'<>'not_started'
     OR v_payload->>'capability_mode'<>'core'
     OR (v_payload->>'deterministic_seed')::bigint<>264 THEN
    RAISE EXCEPTION 'P2-64 registered run payload invalid: %',v_payload;
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.register_exam_prep_synthetic_validation_run_v1(
      v_run_id,'scenario-v1',repeat('b',40),'p2-64',264,'core','p2-64-duplicate-proof'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_run_already_registered' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 duplicate run registration was accepted';
  END IF;

  -- Dedicated synthetic identity has exactly one immutable run owner.
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_user,'authenticated','authenticated',
    'exam-prep-sv-p264-'||replace(v_user::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_user,'P264','Synthetic','en',now(),false);

  INSERT INTO private.exam_prep_synthetic_identities(
    user_id,run_id,identity_status,evidence_ref,purpose
  ) VALUES(
    v_user,v_run_id,'active','p2-64-identity-proof',
    'Dedicated P2-64 synthetic identity run-ownership validation.'
  );

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_synthetic_identities
    WHERE user_id=v_user AND run_id=v_run_id
  ) THEN
    RAISE EXCEPTION 'P2-64 synthetic identity was not bound to its run';
  END IF;

  v_blocked:=false;
  BEGIN
    UPDATE private.exam_prep_synthetic_identities
    SET run_id='SV-P264CI-9999'
    WHERE user_id=v_user;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_identity_provenance_immutable' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 synthetic identity run ownership was mutable';
  END IF;

  -- Optimistic expected-status transition fails closed on stale caller state.
  v_blocked:=false;
  BEGIN
    PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
      v_run_id,'running','completed','{}'::jsonb,null,'{}'::jsonb
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_run_status_changed expected=running actual=registered' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 stale expected run status did not fail closed';
  END IF;

  v_payload:=private.transition_exam_prep_synthetic_validation_run_v1(
    v_run_id,'registered','running',null,null,jsonb_build_object('step','start')
  );
  IF v_payload->>'run_status'<>'running' OR v_payload->>'started_at' IS NULL THEN
    RAISE EXCEPTION 'P2-64 run did not enter running state correctly: %',v_payload;
  END IF;

  -- Cleanup cannot begin while the run is still active.
  v_blocked:=false;
  BEGIN
    PERFORM private.transition_exam_prep_synthetic_cleanup_v1(
      v_run_id,'not_started','pending','{}'::jsonb
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_cleanup_requires_terminal_run' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 cleanup began before run reached terminal state';
  END IF;

  v_payload:=private.transition_exam_prep_synthetic_validation_run_v1(
    v_run_id,'running','completed',jsonb_build_object('matrix','green'),null,
    jsonb_build_object('step','complete')
  );
  IF v_payload->>'run_status'<>'completed'
     OR v_payload->>'finished_at' IS NULL
     OR v_payload#>>'{audit_result,matrix}'<>'green' THEN
    RAISE EXCEPTION 'P2-64 completed run payload invalid: %',v_payload;
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
      v_run_id,'completed','running',null,null,'{}'::jsonb
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_run_transition_invalid completed->running' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 terminal run was restarted';
  END IF;

  PERFORM private.transition_exam_prep_synthetic_cleanup_v1(
    v_run_id,'not_started','pending',jsonb_build_object('step','queue-cleanup')
  );
  v_payload:=private.transition_exam_prep_synthetic_cleanup_v1(
    v_run_id,'pending','running',jsonb_build_object('step','cleanup-start')
  );
  IF v_payload->>'cleanup_status'<>'running' OR v_payload->>'cleanup_started_at' IS NULL THEN
    RAISE EXCEPTION 'P2-64 cleanup did not enter running state: %',v_payload;
  END IF;

  v_payload:=private.transition_exam_prep_synthetic_cleanup_v1(
    v_run_id,'running','clean',jsonb_build_object('step','cleanup-clean')
  );
  IF v_payload->>'cleanup_status'<>'clean' OR v_payload->>'cleaned_at' IS NULL THEN
    RAISE EXCEPTION 'P2-64 cleanup did not enter clean state: %',v_payload;
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.transition_exam_prep_synthetic_cleanup_v1(
      v_run_id,'clean','pending','{}'::jsonb
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_cleanup_transition_invalid clean->pending' in SQLERRM)>0 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 clean cleanup state was reopened';
  END IF;

  SELECT count(*) INTO v_event_count
  FROM private.exam_prep_synthetic_validation_run_events
  WHERE run_id=v_run_id;
  IF v_event_count<>6 THEN
    RAISE EXCEPTION 'P2-64 expected 6 immutable run events, got %',v_event_count;
  END IF;

  v_blocked:=false;
  BEGIN
    UPDATE private.exam_prep_synthetic_validation_run_events
    SET details=jsonb_build_object('tampered',true)
    WHERE run_id=v_run_id;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_run_event_immutable' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-64 run event history was mutable';
  END IF;

  -- Browser roles cannot access registries or lifecycle functions. Service role
  -- receives read + controlled function execution, not raw table writes.
  IF has_table_privilege('anon','private.exam_prep_synthetic_validation_runs','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_validation_runs','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_validation_runs','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_validation_runs','UPDATE')
     OR has_table_privilege('anon','private.exam_prep_synthetic_validation_run_events','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_validation_run_events','SELECT') THEN
    RAISE EXCEPTION 'P2-64 synthetic run registry became browser-accessible';
  END IF;

  IF has_table_privilege('service_role','private.exam_prep_synthetic_validation_runs','INSERT')
     OR has_table_privilege('service_role','private.exam_prep_synthetic_validation_runs','UPDATE')
     OR has_table_privilege('service_role','private.exam_prep_synthetic_validation_run_events','INSERT')
     OR has_table_privilege('service_role','private.exam_prep_synthetic_validation_run_events','UPDATE') THEN
    RAISE EXCEPTION 'P2-64 service role has raw write access instead of controlled lifecycle functions';
  END IF;

  IF NOT has_table_privilege('service_role','private.exam_prep_synthetic_validation_runs','SELECT')
     OR NOT has_table_privilege('service_role','private.exam_prep_synthetic_validation_run_events','SELECT')
     OR NOT has_function_privilege('service_role','private.register_exam_prep_synthetic_validation_run_v1(text,text,text,text,bigint,text,text)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.transition_exam_prep_synthetic_validation_run_v1(text,text,text,jsonb,text,jsonb)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.transition_exam_prep_synthetic_cleanup_v1(text,text,text,jsonb)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-64 service-role controlled run lifecycle boundary missing';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_validation_runs
  WHERE run_id='SV-P264CI-0001';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-64 rollback left run rows=%',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_validation_run_events
  WHERE run_id='SV-P264CI-0001';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-64 rollback left run event rows=%',v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM auth.users
  WHERE email LIKE 'exam-prep-sv-p264-%@invalid.example';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-64 rollback left synthetic auth users=%',v_count;
  END IF;
END
$$;

\echo 'P2-64 synthetic validation run registry matrix: GREEN'
