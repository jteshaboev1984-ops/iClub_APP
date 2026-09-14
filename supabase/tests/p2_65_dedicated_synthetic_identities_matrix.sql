\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p265.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-65 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p265_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  v_learner_a uuid:=gen_random_uuid();
  v_mentor_a uuid:=gen_random_uuid();
  v_learner_b uuid:=gen_random_uuid();
  v_real uuid:=gen_random_uuid();
  v_real_mentor uuid:=gen_random_uuid();
  v_run_a text:='SV-P265CI-RUN-A';
  v_run_b text:='SV-P265CI-RUN-B';
  v_blocked boolean;
  v_report jsonb;
BEGIN
  PERFORM private.register_exam_prep_synthetic_validation_run_v1(
    v_run_a,'p265-identities-v1',repeat('c',40),'p2-65',26501,'core','p2-65-run-a-proof'
  );
  PERFORM private.register_exam_prep_synthetic_validation_run_v1(
    v_run_b,'p265-identities-v1',repeat('d',40),'p2-65',26502,'mentor_technical','p2-65-run-b-proof'
  );

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES
    (v_learner_a,'authenticated','authenticated','exam-prep-sv-p265-la-'||replace(v_learner_a::text,'-','')||'@invalid.example',now(),now(),false,false),
    (v_mentor_a,'authenticated','authenticated','exam-prep-sv-p265-ma-'||replace(v_mentor_a::text,'-','')||'@invalid.example',now(),now(),false,false),
    (v_learner_b,'authenticated','authenticated','exam-prep-sv-p265-lb-'||replace(v_learner_b::text,'-','')||'@invalid.example',now(),now(),false,false),
    (v_real,'authenticated','authenticated','p265-real-'||replace(v_real::text,'-','')||'@invalid.example',now(),now(),false,false),
    (v_real_mentor,'authenticated','authenticated','p265-real-mentor-'||replace(v_real_mentor::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES
    (v_learner_a,'P265','Synthetic Learner A','en',now(),false),
    (v_mentor_a,'P265','Synthetic Mentor A','en',now(),false),
    (v_learner_b,'P265','Synthetic Learner B','en',now(),false),
    (v_real,'P265','Real Control','en',now(),false),
    (v_real_mentor,'P265','Real Mentor Control','en',now(),false);

  INSERT INTO p265_people(person_key,user_id) VALUES
    ('learner_a',v_learner_a),('mentor_a',v_mentor_a),('learner_b',v_learner_b),
    ('real',v_real),('real_mentor',v_real_mentor);

  INSERT INTO private.exam_prep_synthetic_identities(
    user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
  ) VALUES
    (v_learner_a,v_run_a,'learner','SVF-P265-LEARNER-A','active','p2-65-learner-a-proof','Dedicated P2-65 synthetic learner fixture A.'),
    (v_mentor_a,v_run_a,'mentor','SVF-P265-MENTOR-A','active','p2-65-mentor-a-proof','Dedicated P2-65 synthetic mentor-shaped fixture A.'),
    (v_learner_b,v_run_b,'learner','SVF-P265-LEARNER-B','active','p2-65-learner-b-proof','Dedicated P2-65 synthetic learner fixture B.');

  IF (SELECT count(*) FROM private.exam_prep_synthetic_identities WHERE run_id=v_run_a)<>2
     OR (SELECT count(*) FROM private.exam_prep_synthetic_identities WHERE run_id=v_run_b)<>1
     OR (SELECT count(*) FROM private.exam_prep_synthetic_identities WHERE identity_kind='mentor')<>1 THEN
    RAISE EXCEPTION 'P2-65 dedicated identity provenance counts are wrong';
  END IF;

  v_blocked:=false;
  BEGIN
    UPDATE private.exam_prep_synthetic_identities
    SET identity_kind='mentor'
    WHERE user_id=v_learner_a;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_identity_provenance_immutable' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 identity kind was mutable'; END IF;

  v_blocked:=false;
  BEGIN
    UPDATE private.exam_prep_synthetic_identities
    SET fixture_profile_key='SVF-P265-TAMPERED'
    WHERE user_id=v_learner_a;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_identity_provenance_immutable' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 fixture profile provenance was mutable'; END IF;

  -- Synthetic mentor-shaped identities are not real staff and gain no human authority.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
    VALUES(v_mentor_a,'mentor','active');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_staff_role_forbidden_until_mentor_technical_gate' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 synthetic mentor gained a real staff role'; END IF;

  -- Same-run synthetic learner -> synthetic mentor anchor is structurally valid.
  INSERT INTO private.exam_prep_mentor_assignments(
    learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
  ) VALUES(v_learner_a,v_mentor_a,'P1','active',now());

  -- Synthetic -> real crossing is forbidden.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_mentor_assignments(
      learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
    ) VALUES(v_learner_a,v_real,'P5','active',now());
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_assignment_real_boundary_crossing' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 synthetic learner crossed into real mentor assignment'; END IF;

  -- Real -> synthetic crossing is forbidden.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_mentor_assignments(
      learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
    ) VALUES(v_real,v_mentor_a,'P1','active',now());
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_assignment_real_boundary_crossing' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 real learner crossed into synthetic mentor assignment'; END IF;

  -- Cross-run synthetic assignments are forbidden.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_mentor_assignments(
      learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
    ) VALUES(v_learner_b,v_mentor_a,'P1','active',now());
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_assignment_cross_run_forbidden' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 cross-run synthetic assignment was accepted'; END IF;

  -- Identity kinds are directional and cannot be reversed.
  v_blocked:=false;
  BEGIN
    INSERT INTO private.exam_prep_mentor_assignments(
      learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
    ) VALUES(v_mentor_a,v_learner_a,'P5','active',now());
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_assignment_identity_kind_mismatch' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-65 reversed synthetic identity kinds were accepted'; END IF;

  -- Real control assignment proves there is independent real private state to hide.
  INSERT INTO private.exam_prep_mentor_assignments(
    learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
  ) VALUES(v_real,v_real_mentor,'P5','active',now());

  INSERT INTO private.exam_prep_exam_profiles(user_id,active_week_no)
  VALUES(v_learner_a,0),(v_real,0);

  v_report:=private.exam_prep_synthetic_identity_isolation_report_v1();
  IF coalesce((v_report->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_report->>'synthetic_identities')::int,-1)<>3
     OR coalesce((v_report->>'synthetic_staff_role_rows')::int,-1)<>0
     OR coalesce((v_report->>'real_synthetic_assignment_crossings')::int,-1)<>0
     OR coalesce((v_report->>'cross_run_assignments')::int,-1)<>0
     OR coalesce((v_report->>'identity_kind_assignment_mismatches')::int,-1)<>0 THEN
    RAISE EXCEPTION 'P2-65 isolation report not clean: %',v_report;
  END IF;

  IF has_table_privilege('anon','private.exam_prep_synthetic_identities','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_identities','SELECT')
     OR has_function_privilege('anon','private.exam_prep_synthetic_identity_isolation_report_v1()','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_synthetic_identity_isolation_report_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-65 synthetic identity isolation internals became browser-accessible';
  END IF;
  IF NOT has_function_privilege('service_role','private.exam_prep_synthetic_identity_isolation_report_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-65 service-role isolation report boundary missing';
  END IF;
END
$$;

-- Authenticate as the synthetic learner. The current browser boundary denies the
-- private schema entirely; the public capability surface must also remain fail-closed
-- despite a same-run synthetic assignment anchor.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p265_people WHERE person_key='learner_a'),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  v_blocked boolean:=false;
  v_cap record;
BEGIN
  BEGIN
    PERFORM count(*) FROM private.exam_prep_exam_profiles;
  EXCEPTION WHEN insufficient_privilege THEN
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-65 browser unexpectedly read private learner profiles';
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM count(*) FROM private.exam_prep_mentor_assignments;
  EXCEPTION WHEN insufficient_privilege THEN
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN
    RAISE EXCEPTION 'P2-65 browser unexpectedly read private mentor assignments';
  END IF;

  SELECT * INTO v_cap FROM public.get_exam_prep_capabilities_v1();
  IF coalesce(v_cap.core_access,true)
     OR coalesce(v_cap.ai_assist,true)
     OR coalesce(v_cap.mentor_care_entitled,true)
     OR coalesce(v_cap.mentor_assignment_active,true)
     OR coalesce(v_cap.mentor_authority,true) THEN
    RAISE EXCEPTION 'P2-65 synthetic identity gained browser capability authority';
  END IF;
END
$$;

RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claim.role','',true);

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM auth.users
  WHERE email LIKE 'exam-prep-sv-p265-%@invalid.example'
     OR email LIKE 'p265-real-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-65 rollback left test auth users=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_validation_runs
  WHERE run_id IN ('SV-P265CI-RUN-A','SV-P265CI-RUN-B');
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-65 rollback left synthetic runs=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_identities
  WHERE fixture_profile_key LIKE 'SVF-P265-%';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-65 rollback left synthetic identities=%',v_count; END IF;
END
$$;

\echo 'P2-65 dedicated synthetic identities matrix: GREEN'