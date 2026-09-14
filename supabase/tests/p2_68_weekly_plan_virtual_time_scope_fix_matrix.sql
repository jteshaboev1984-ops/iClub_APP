\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p268fix.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-68 FIX REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_run text:='SV-P268FIX-CI-0001';
  v_uid uuid;
  v_real_uid uuid:=gen_random_uuid();
  v_program bigint;
  v_skill text;
  v_clock jsonb;
  v_virtual_now timestamptz;
  v_plan uuid;
  v_real_plan uuid;
  v_synth_created timestamptz;
  v_real_created timestamptz;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';
  IF v_program IS NULL THEN
    RAISE EXCEPTION 'P2-68 FIX canonical program missing';
  END IF;

  SELECT skill_code INTO v_skill
  FROM private.exam_prep_syllabus_nodes
  WHERE program_version_id=v_program
    AND component_code='P1'
  ORDER BY sequence_no,skill_code
  LIMIT 1;
  IF v_skill IS NULL THEN
    RAISE EXCEPTION 'P2-68 FIX governed P1 skill missing';
  END IF;

  PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',repeat('6',40),'p2-68-fix',26802,'core',
    'p2-68-weekly-plan-owner-fix-proof'
  );
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P268FIX-LEARNER-01','p2-68-fix-identity-proof',
    'Dedicated weekly-plan virtual-time regression learner.','en'
  );
  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,jsonb_build_object('p2_68_fix','start')
  );
  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(v_run,'p2-68-fix-clock-init');
  v_virtual_now:=(v_clock->>'virtual_now')::timestamptz;
  v_clock:=private.advance_exam_prep_synthetic_clock_v1(
    v_run,v_virtual_now,604800,'advance one week for weekly-plan ownership regression'
  );
  v_virtual_now:=(v_clock->>'virtual_now')::timestamptz;

  INSERT INTO private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,
    status,recovery_mode,max_priorities,policy_note
  ) VALUES(
    v_uid,v_program,'P1',2,1,'active','normal',3,'P2-68 synthetic weekly-plan owner regression'
  ) RETURNING id INTO v_plan;

  INSERT INTO private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,action_code,action_payload
  ) VALUES(
    v_plan,1,'learning',v_skill,'BUILD_FIRST_COVERAGE',jsonb_build_object('p2_68_fix',true)
  );

  SELECT created_at INTO v_synth_created
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=v_plan AND priority_order=1;

  IF v_synth_created IS DISTINCT FROM v_virtual_now THEN
    RAISE EXCEPTION 'P2-68 FIX synthetic weekly-plan item was not stamped with parent learner virtual time: % vs %',
      v_synth_created,v_virtual_now;
  END IF;

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_real_uid,'authenticated','authenticated',
    'p268fix-real-'||replace(v_real_uid::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_real_uid,'P268','Real Weekly Plan Control','en',now(),false);

  INSERT INTO private.exam_prep_weekly_plans(
    user_id,program_version_id,component_code,active_week_no,plan_version,
    status,recovery_mode,max_priorities,policy_note
  ) VALUES(
    v_real_uid,v_program,'P1',1,1,'active','normal',3,'P2-68 real weekly-plan control'
  ) RETURNING id INTO v_real_plan;

  INSERT INTO private.exam_prep_weekly_plan_items(
    plan_id,priority_order,item_type,skill_code,action_code,action_payload
  ) VALUES(
    v_real_plan,1,'learning',v_skill,'BUILD_FIRST_COVERAGE',jsonb_build_object('p2_68_fix','real-control')
  );

  SELECT created_at INTO v_real_created
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=v_real_plan AND priority_order=1;

  IF abs(extract(epoch from (v_real_created-now())))>5 THEN
    RAISE EXCEPTION 'P2-68 FIX real weekly-plan item left the real server clock: % vs %',
      v_real_created,now();
  END IF;
  IF v_real_created>=v_virtual_now-interval '1 minute' THEN
    RAISE EXCEPTION 'P2-68 FIX real weekly-plan item inherited synthetic virtual time';
  END IF;
END
$$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_synthetic_validation_runs
    WHERE run_id='SV-P268FIX-CI-0001'
  ) THEN
    RAISE EXCEPTION 'P2-68 FIX rollback left synthetic run residue';
  END IF;
END
$$;

\echo 'P2-68 weekly-plan virtual-time scope fix matrix: GREEN'
