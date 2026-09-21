-- DRAFT ONLY, isolated PostgreSQL first. Run AFTER all six review proposals:
-- verdict, start, exact-goal binding, recovery, goal eligibility, weekly accounting.
-- BEFORE any learner is enrolled or the Core release flag changes.
BEGIN;
DO $gate$
DECLARE b record; p pg_proc%rowtype; v_anchor text; n integer:=0;
BEGIN
 IF to_regclass('private.exam_prep_weekly_review_rpc_backup_v1') IS NULL OR
    to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL OR
    to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NULL THEN
  RAISE EXCEPTION 'review_attestation_prerequisite_missing';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
    AND core_enabled IS FALSE AND kill_switch IS TRUE)
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE) THEN
  RAISE EXCEPTION 'review_attestation_requires_core_off_zero_enrollment';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1 ORDER BY signature LOOP
  n:=n+1;
  SELECT * INTO p FROM pg_proc WHERE oid=to_regprocedure(b.signature);
  IF p.oid IS NULL OR b.installed_md5 IS NOT NULL OR b.sealed_at IS NOT NULL OR
     NOT p.prosecdef OR p.proowner IS DISTINCT FROM 'postgres'::regrole::oid OR
     has_function_privilege('anon',p.oid,'EXECUTE') OR
     NOT has_function_privilege('authenticated',p.oid,'EXECUTE') THEN
    RAISE EXCEPTION 'review_attestation_unexpected_function_state_%',b.signature;
  END IF;
  IF b.operation='modified' AND (p.oid<>b.original_oid OR
     md5(pg_get_functiondef(p.oid))=b.original_md5 OR
     p.proowner IS DISTINCT FROM b.original_owner OR
     p.proacl IS DISTINCT FROM b.original_acl OR
     p.prosecdef IS DISTINCT FROM b.original_security OR
     p.provolatile IS DISTINCT FROM b.original_volatility) THEN
    RAISE EXCEPTION 'review_attestation_modified_rpc_drift_%',b.signature;
  END IF;
  IF b.operation='added' AND (b.original_oid IS NOT NULL OR p.provolatile<>'v' OR
     has_function_privilege('service_role',p.oid,'EXECUTE')) THEN
    RAISE EXCEPTION 'review_attestation_new_starter_drift';
  END IF;
  v_anchor:=CASE b.signature
   WHEN 'public.get_exam_prep_active_plan_session_safe_v1(text)' THEN
    'private.exam_prep_learning_review_starts_v1'
   WHEN 'public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)' THEN
    'private.exam_prep_learning_review_verdict_v1'
   WHEN 'public.get_exam_prep_weekly_progress_safe_v1(text)' THEN
    'private.exam_prep_learning_review_starts_v1'
   WHEN 'public.get_exam_prep_previous_week_adherence_safe_v1(text)' THEN
    'private.exam_prep_learning_review_starts_v1'
   WHEN 'public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)' THEN
    'private.exam_prep_learning_review_verdict_v1'
   ELSE NULL END;
  IF v_anchor IS NULL OR strpos(pg_get_functiondef(p.oid),v_anchor)=0 THEN
   RAISE EXCEPTION 'review_attestation_missing_expected_contract_%',b.signature;
  END IF;
 END LOOP;
 IF n<>5 THEN RAISE EXCEPTION 'review_attestation_expected_five_rpcs_got_%',n; END IF;
 IF has_function_privilege('anon',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
    has_function_privilege('authenticated',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
    has_table_privilege('authenticated','private.exam_prep_learning_review_starts_v1','SELECT') OR
    has_table_privilege('anon','private.exam_prep_learning_review_starts_v1','SELECT') OR
    has_table_privilege('service_role','private.exam_prep_learning_review_starts_v1','SELECT') THEN
  RAISE EXCEPTION 'review_attestation_private_object_exposure';
 END IF;
END;$gate$;
UPDATE private.exam_prep_weekly_review_rpc_backup_v1 b
SET installed_oid=to_regprocedure(b.signature),
 installed_md5=md5(pg_get_functiondef(to_regprocedure(b.signature))),
 installed_owner=p.proowner,installed_acl=p.proacl,
 installed_security=p.prosecdef,installed_volatility=p.provolatile,
 sealed_at=now()
FROM pg_proc p WHERE p.oid=to_regprocedure(b.signature)
 AND b.installed_md5 IS NULL AND b.sealed_at IS NULL;
DO $verify$
DECLARE n integer;
BEGIN
 SELECT count(*) INTO n FROM private.exam_prep_weekly_review_rpc_backup_v1 b
 JOIN pg_proc p ON p.oid=b.installed_oid
 WHERE b.installed_md5 IS NOT NULL AND b.sealed_at IS NOT NULL
   AND md5(pg_get_functiondef(p.oid))=b.installed_md5
   AND b.installed_owner IS NOT DISTINCT FROM p.proowner
   AND b.installed_acl IS NOT DISTINCT FROM p.proacl
   AND b.installed_security IS NOT DISTINCT FROM p.prosecdef
   AND b.installed_volatility IS NOT DISTINCT FROM p.provolatile;
 IF n<>5 THEN RAISE EXCEPTION 'review_attestation_seal_failed_%',n; END IF;
END;$verify$;
COMMIT;