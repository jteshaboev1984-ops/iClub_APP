-- Issue #450 P4-06: source-authenticated full-stack FINAL writer/ACL proof.
-- Only disposable PG17 with synthetic accounts; absolutely no mutations.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
  v_name text;
  v_private text[];
  v_source text;
  v_finalizer text;
  v_score text;
  v_gate text;
  v_grade text;
  v_user uuid;
  v_components int;
  v_count int;
BEGIN
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
     OR (SELECT count(*) FROM auth.users)<>3
     OR (SELECT count(*) FROM public.users)<>3
  THEN RAISE EXCEPTION 'P4-06 REFUSED: NOT disposable three-actor PG17'; END IF;
  SELECT user_id INTO STRICT v_user FROM private.exam_prep_synthetic_identities
   WHERE run_id='SV-P1P5-MIXED-TIMED-HTTP-01'
     AND identity_kind='learner' AND identity_status='active';
  v_private:=ARRAY[
    'private.exam_prep_timed_execution_comparable_v1(uuid)',
    'private.exam_prep_stage3_exit_status_v1(uuid,bigint,text)',
    'private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)',
    'private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)',
    'private.exam_prep_stage5_operational_completion_v1(uuid,bigint,text)'
  ];
  FOREACH v_name IN ARRAY v_private LOOP
    IF to_regprocedure(v_name) IS NULL
       OR NOT has_function_privilege('service_role',v_name,'EXECUTE')
       OR has_function_privilege('authenticated',v_name,'EXECUTE')
       OR has_function_privilege('anon',v_name,'EXECUTE')
    THEN RAISE EXCEPTION 'P4-06 private service-role ACL broken %',v_name; END IF;
    v_source:=pg_get_functiondef(to_regprocedure(v_name));
    IF position('SECURITY DEFINER' IN upper(v_source))=0
       OR position('search_path TO ''''' IN v_source)=0
    THEN RAISE EXCEPTION 'P4-06 unsafe definer/search_path %',v_name; END IF;
  END LOOP;

  v_finalizer:=pg_get_functiondef(
    'public.finalize_exam_prep_timed_safe_v1(uuid,text,text)'::regprocedure);
  IF NOT has_function_privilege('authenticated',
     'public.finalize_exam_prep_timed_safe_v1(uuid,text,text)','EXECUTE')
     OR NOT has_function_privilege('service_role',
     'public.finalize_exam_prep_timed_safe_v1(uuid,text,text)','EXECUTE')
     OR has_function_privilege('anon',
     'public.finalize_exam_prep_timed_safe_v1(uuid,text,text)','EXECUTE')
     OR position('SECURITY DEFINER' in upper(v_finalizer))=0
     OR position('search_path TO ''''' in v_finalizer)=0
     OR position('private.exam_prep_require_core_access_v1()' in v_finalizer)=0
     OR position('insert into private.exam_prep_timed_attempt_results' in lower(v_finalizer))=0
     OR position('perform private.rebuild_exam_prep_state_v1(v_uid,v_s.component_code);' in v_finalizer)
       <=position('insert into private.exam_prep_timed_attempt_results' in lower(v_finalizer))
  THEN RAISE EXCEPTION 'P4-06 finalizer post-ledger writer/auth ordering drift'; END IF;

  v_score:=pg_get_functiondef(
    'private.exam_prep_timed_score_comparable_v1(uuid)'::regprocedure);
  v_gate:=pg_get_functiondef('private.exam_prep_apply_stage0_gate_v1()'::regprocedure);
  v_grade:=pg_get_functiondef('private.exam_prep_apply_readiness_projection_v1()'::regprocedure);
  IF position('pending_review_in_time_marks' in v_score)=0
     OR position('pending_review_after_time_marks' in v_score)=0
     OR position('private.exam_prep_stage5_operational_completion_v1' in v_gate)=0
     OR position('operational_calibration_access' in v_gate)=0
     OR position('private.exam_prep_stage5_readiness_status_v1' in v_grade)=0
     OR position('exam_prep_stage5_operational_completion_v1' in v_grade)<>0
  THEN RAISE EXCEPTION 'P4-06 Core execution vs scored-grade projections conflated'; END IF;

  SELECT count(*) INTO v_components FROM private.exam_prep_stage_states
  WHERE user_id=v_user AND engine_version='objective_state_v1'
    AND component_code IN ('P1','P5')
    AND operational_stage=6 AND app_readiness_estimate='INSUFFICIENT_EVIDENCE';
  IF v_components<>2 THEN RAISE EXCEPTION 'P4-06 P1/P5 operational/readiness isolation failed'; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_timed_written_self_marks
   WHERE user_id=v_user;
  IF v_count<>0 THEN RAISE EXCEPTION 'P4-06 learner self-scoring resurrected'; END IF;
  IF EXISTS(SELECT 1 FROM public.practice_attempts)
     OR EXISTS(SELECT 1 FROM public.tour_attempts)
     OR EXISTS(SELECT 1 FROM public.certificates)
  THEN RAISE EXCEPTION 'P4-06 legacy learner evidence affected'; END IF;
  RAISE NOTICE 'P4-06 PASS: five private ACLs, immutable authenticated finalizer post-ledger writer, Stage6-only no false grade, synthetic legacy boundary';
  RAISE NOTICE 'P4-06 SCOPE: nested trigger/old-epoch P0-16B and public release approval remain separately OPEN / NO_GO';
END $proof$;
