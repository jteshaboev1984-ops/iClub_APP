\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p266.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-66 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

CREATE TABLE public.p266_legacy_probe(
  id bigint generated always as identity primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  note text
);

CREATE TEMP TABLE p266_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  v_run text:='SV-P266CI-RUN-0001';
  v_learner uuid;
  v_mentor uuid;
  v_payload jsonb;
  v_inventory jsonb;
  v_blocked boolean:=false;
  v_summary int;
BEGIN
  PERFORM private.register_exam_prep_synthetic_validation_run_v1(
    v_run,'p266-lifecycle-v1',repeat('e',40),'p2-66',26601,'core','p2-66-run-proof'
  );

  v_learner:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P266-LEARNER-01','p2-66-learner-proof',
    'Dedicated reusable synthetic learner for P2-66 lifecycle validation.','en'
  );
  v_mentor:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'mentor','SVF-P266-MENTOR-01','p2-66-mentor-proof',
    'Dedicated reusable synthetic mentor fixture for P2-66 lifecycle validation.','ru'
  );

  INSERT INTO p266_people(person_key,user_id)
  VALUES('learner',v_learner),('mentor',v_mentor);

  IF (SELECT count(*) FROM private.exam_prep_synthetic_identities WHERE run_id=v_run)<>2 THEN
    RAISE EXCEPTION 'P2-66 synthetic seeder did not create exactly two identities';
  END IF;
  IF (SELECT count(*) FROM auth.users
      WHERE id IN (v_learner,v_mentor)
        AND email LIKE 'exam-prep-sv-%@invalid.example')<>2 THEN
    RAISE EXCEPTION 'P2-66 synthetic auth identity contract invalid';
  END IF;

  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,jsonb_build_object('p2_66','run-start')
  );

  -- Seed only run-owned Exam Prep state. No real beta membership/consent is used.
  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_learner,'active',true,false,false,null,now());

  INSERT INTO private.exam_prep_exam_profiles(user_id,active_week_no)
  VALUES(v_learner,0);

  INSERT INTO private.exam_prep_mentor_assignments(
    learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
  ) VALUES(v_learner,v_mentor,'P1','active',now());

  v_inventory:=private.exam_prep_synthetic_run_inventory_v1(v_run);
  IF coalesce((v_inventory->>'identity_count')::int,-1)<>2
     OR coalesce((v_inventory->>'clean_boundary')::boolean,false) IS NOT TRUE
     OR coalesce((v_inventory#>>'{legacy_refs,total_refs}')::int,-1)<>0
     OR coalesce((v_inventory->>'protected_control_refs')::int,-1)<>0
     OR coalesce((v_inventory->>'mixed_real_synthetic_edges')::int,-1)<>0 THEN
    RAISE EXCEPTION 'P2-66 clean run inventory invalid: %',v_inventory;
  END IF;

  -- A new/unknown legacy table with a public.users FK is detected dynamically.
  INSERT INTO public.p266_legacy_probe(user_id,note)
  VALUES(v_learner,'must block run completion and cleanup');

  v_inventory:=private.exam_prep_synthetic_run_inventory_v1(v_run);
  IF coalesce((v_inventory#>>'{legacy_refs,total_refs}')::int,0)<>1
     OR coalesce((v_inventory->>'clean_boundary')::boolean,true) THEN
    RAISE EXCEPTION 'P2-66 dynamic legacy contamination was not detected: %',v_inventory;
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.complete_exam_prep_synthetic_run_v1(v_run,2,'{}'::jsonb);
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_run_boundary_not_clean:' in SQLERRM)=1 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-66 contaminated run was completed';
  END IF;

  DELETE FROM public.p266_legacy_probe WHERE user_id=v_learner;

  v_payload:=private.complete_exam_prep_synthetic_run_v1(
    v_run,2,jsonb_build_object('matrix','green')
  );
  IF v_payload->>'run_status'<>'completed'
     OR v_payload#>>'{audit_result,result}'<>'green' THEN
    RAISE EXCEPTION 'P2-66 run completion audit invalid: %',v_payload;
  END IF;

  -- Stale expected identity count fails before any cleanup state changes.
  v_blocked:=false;
  BEGIN
    PERFORM private.cleanup_exam_prep_synthetic_run_v1(
      v_run,3,'p2-66-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_synthetic_identity_count_mismatch expected=3 actual=2' in SQLERRM)=1 THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-66 stale identity snapshot did not fail closed';
  END IF;
  IF (SELECT cleanup_status FROM private.exam_prep_synthetic_validation_runs WHERE run_id=v_run)<>'not_started' THEN
    RAISE EXCEPTION 'P2-66 failed preflight mutated cleanup lifecycle';
  END IF;

  v_payload:=private.cleanup_exam_prep_synthetic_run_v1(
    v_run,2,'p2-66-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF v_payload->>'cleanup_status'<>'clean'
     OR coalesce((v_payload->>'idempotent')::boolean,true)
     OR coalesce((v_payload->>'deleted_identity_count')::int,-1)<>2
     OR coalesce((v_payload->>'summary_audit_events')::int,-1)<>1 THEN
    RAISE EXCEPTION 'P2-66 cleanup result invalid: %',v_payload;
  END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities WHERE run_id=v_run)
     OR EXISTS(SELECT 1 FROM public.users WHERE id IN (v_learner,v_mentor))
     OR EXISTS(SELECT 1 FROM auth.users WHERE id IN (v_learner,v_mentor))
     OR EXISTS(SELECT 1 FROM private.exam_prep_exam_profiles WHERE user_id=v_learner)
     OR EXISTS(SELECT 1 FROM private.exam_prep_feature_entitlements WHERE user_id=v_learner)
     OR EXISTS(SELECT 1 FROM private.exam_prep_mentor_assignments WHERE learner_user_id=v_learner OR mentor_user_id=v_mentor) THEN
    RAISE EXCEPTION 'P2-66 cleanup left synthetic identity or operational residue';
  END IF;

  SELECT count(*) INTO v_summary
  FROM private.exam_prep_audit_events
  WHERE event_type='synthetic_validation_run_cleaned'
    AND object_type='private.exam_prep_synthetic_validation_runs'
    AND object_id=v_run;
  IF v_summary<>1 THEN
    RAISE EXCEPTION 'P2-66 expected exactly one cleanup summary, got %',v_summary;
  END IF;

  -- Cleanup is idempotent and does not duplicate summary evidence.
  v_payload:=private.cleanup_exam_prep_synthetic_run_v1(
    v_run,2,'p2-66-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF coalesce((v_payload->>'idempotent')::boolean,false) IS NOT TRUE
     OR coalesce((v_payload->>'summary_audit_events')::int,-1)<>1 THEN
    RAISE EXCEPTION 'P2-66 repeated cleanup was not idempotent: %',v_payload;
  END IF;

  IF (SELECT cleanup_status FROM private.exam_prep_synthetic_validation_runs WHERE run_id=v_run)<>'clean' THEN
    RAISE EXCEPTION 'P2-66 run registry did not retain clean terminal status';
  END IF;

  IF has_function_privilege('anon','private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-66 engineering harness became browser-callable';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P266CI-RUN-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-66 rollback left synthetic run rows=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'exam-prep-sv-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-66 rollback left synthetic auth users=%',v_count; END IF;

  IF to_regclass('public.p266_legacy_probe') IS NOT NULL THEN
    RAISE EXCEPTION 'P2-66 rollback left legacy probe table';
  END IF;
END
$$;

\echo 'P2-66 reusable synthetic run engine matrix: GREEN'
