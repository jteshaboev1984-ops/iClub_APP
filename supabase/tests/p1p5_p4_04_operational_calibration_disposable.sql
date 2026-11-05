-- Issue #450 P4-04 negative: genuine ONE written Paper must not unlock Stage6.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
  v_owner uuid; v_program bigint; v_comp text; v_op jsonb; v_scored jsonb;
BEGIN
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
     OR (SELECT count(*) FROM public.users)<>3
     OR (SELECT count(*) FROM auth.users)<>3
  THEN RAISE EXCEPTION 'P4-04 REFUSED: isolated three-actor PG17 only'; END IF;
  SELECT user_id INTO STRICT v_owner
  FROM private.exam_prep_synthetic_identities
  WHERE run_id='SV-P1P5-MIXED-TIMED-HTTP-01'
    AND identity_kind='learner' AND identity_status='active';
  SELECT program_version_id INTO STRICT v_program
  FROM private.exam_prep_exam_profiles WHERE user_id=v_owner;
  IF has_function_privilege('anon',
    'private.exam_prep_stage5_operational_completion_v1(uuid,bigint,text)','EXECUTE')
    OR has_function_privilege('authenticated',
    'private.exam_prep_stage5_operational_completion_v1(uuid,bigint,text)','EXECUTE')
    OR NOT has_function_privilege('service_role',
    'private.exam_prep_stage5_operational_completion_v1(uuid,bigint,text)','EXECUTE')
  THEN RAISE EXCEPTION 'P4-04 operational gate ACL failure'; END IF;
  FOREACH v_comp IN ARRAY ARRAY['P1','P5'] LOOP
    v_op:=private.exam_prep_stage5_operational_completion_v1(v_owner,v_program,v_comp);
    v_scored:=private.exam_prep_stage5_readiness_status_v1(v_owner,v_program,v_comp);
    IF coalesce((v_op->>'operational_calibration_access')::boolean,false)
       OR coalesce((v_scored->>'ready')::boolean,false)
       OR coalesce((v_op->>'exam_readiness_claim')::boolean,false)
       OR (v_op->>'compatible_execution_papers')::int<>1
       OR coalesce((v_op->>'mentor_required')::boolean,true)
    THEN RAISE EXCEPTION 'P4-04 false Stage6 or exam-readiness promotion % op=% scored=%',
       v_comp,v_op,v_scored;
    END IF;
  END LOOP;
  IF position('private.exam_prep_stage5_operational_completion_v1' IN
     pg_get_functiondef('private.exam_prep_apply_stage0_gate_v1()'::regprocedure))=0
     OR position('private.exam_prep_stage5_readiness_status_v1' IN
     pg_get_functiondef('private.exam_prep_apply_readiness_projection_v1()'::regprocedure))=0
  THEN RAISE EXCEPTION 'P4-04 operational/grade projection separation broken'; END IF;
  RAISE NOTICE 'P4-04 PASS: ONE signed P1/P5 Paper is not Stage6, App Readiness remains ungraded, Mentor not required';
END $proof$;
