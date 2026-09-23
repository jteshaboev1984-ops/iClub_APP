-- REVIEW-ONLY proposal. Never production without separate owner approval.
-- AFTER atomic full-surface cutover and BEFORE any learner enrollment.
-- Seal installed hashes for all 11 protected public entrypoints.
BEGIN;
DO $verify$
DECLARE b record; v_function pg_proc%rowtype; v_anchor text; v_count integer:=0;
BEGIN
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NULL
   OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL
   OR to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL THEN
  RAISE EXCEPTION 'weekly_attestation_prerequisites_missing';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1) THEN
  RAISE EXCEPTION 'weekly_attestation_requires_zero_enrollment';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_flow_rpc_backup_v1 LOOP
  v_count:=v_count+1;
  SELECT * INTO v_function FROM pg_proc WHERE oid=to_regprocedure(b.signature);
  IF v_function.oid IS NULL OR v_function.oid<>b.function_oid
     OR b.installed_md5 IS NOT NULL
     OR md5(pg_get_functiondef(v_function.oid))=b.original_md5
     OR v_function.proowner IS DISTINCT FROM b.original_owner
     OR v_function.proacl IS DISTINCT FROM b.original_acl
     OR v_function.prosecdef IS DISTINCT FROM b.original_security
     OR v_function.provolatile IS DISTINCT FROM b.original_volatility
     OR has_function_privilege('anon',v_function.oid,'EXECUTE')
     OR NOT has_function_privilege('authenticated',v_function.oid,'EXECUTE') THEN
   RAISE EXCEPTION 'weekly_attestation_public_rpc_mismatch_%',b.signature;
  END IF;
  v_anchor:=CASE b.signature
   WHEN 'public.generate_exam_prep_weekly_plan_safe_v1(text,text)' THEN 'private.exam_prep_legacy_generate_v1_internal_v1'
   WHEN 'public.generate_exam_prep_weekly_plan_safe_v2(text)' THEN 'private.exam_prep_legacy_generate_v2_internal_v1'
   WHEN 'public.generate_exam_prep_weekly_plan_safe_v3(text)' THEN 'private.exam_prep_legacy_generate_v3_internal_v1'
   WHEN 'public.authorize_exam_prep_correction_safe_v1(uuid)' THEN 'private.exam_prep_legacy_correction_internal_v1'
   WHEN 'public.authorize_exam_prep_mixed_safe_v1(text)' THEN 'private.exam_prep_legacy_mixed_internal_v1'
   WHEN 'public.authorize_exam_prep_retest_safe_v1(uuid)' THEN 'private.exam_prep_legacy_retest_internal_v1'
   WHEN 'public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)' THEN 'private.exam_prep_legacy_authorize_plan_internal_v1'
   WHEN 'public.start_exam_prep_session_safe_v1(uuid,text)' THEN 'private.exam_prep_legacy_start_session_internal_v1'
   WHEN 'public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)' THEN 'private.exam_prep_legacy_generate_v3_internal_v1'
   WHEN 'public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)' THEN 'private.exam_prep_legacy_authorize_plan_internal_v1'
   WHEN 'public.start_exam_prep_plan_session_once_safe_v1(uuid,text)' THEN 'private.exam_prep_legacy_start_session_internal_v1'
   ELSE NULL END;
  IF v_anchor IS NULL OR strpos(pg_get_functiondef(v_function.oid),v_anchor)=0
     OR strpos(pg_get_functiondef(v_function.oid),'private.exam_prep_weekly_flow_enrolled_v1')=0 THEN
   RAISE EXCEPTION 'weekly_attestation_candidate_shape_changed_%',b.signature;
  END IF;
 END LOOP;
 IF v_count<>11 THEN RAISE EXCEPTION 'weekly_attestation_snapshot_count_%',v_count; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES
   ('private.exam_prep_legacy_generate_v1_internal_v1(text,text)'),
   ('private.exam_prep_legacy_generate_v2_internal_v1(text)'),
   ('private.exam_prep_legacy_generate_v3_internal_v1(text)'),
   ('private.exam_prep_legacy_correction_internal_v1(uuid)'),
   ('private.exam_prep_legacy_mixed_internal_v1(text)'),
   ('private.exam_prep_legacy_retest_internal_v1(uuid)'),
   ('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'),
   ('private.exam_prep_legacy_start_session_internal_v1(uuid,text)'),
   ('private.exam_prep_weekly_flow_enrolled_v1(uuid)')
  ) v(signature)
  WHERE to_regprocedure(v.signature) IS NULL
    OR has_function_privilege('authenticated',v.signature,'EXECUTE')
    OR has_function_privilege('anon',v.signature,'EXECUTE')
    OR has_function_privilege('service_role',v.signature,'EXECUTE')) THEN
  RAISE EXCEPTION 'weekly_attestation_private_legacy_access';
 END IF;
 IF strpos(pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure),
     'private.exam_prep_legacy_correction_internal_v1(')=0
   OR strpos(pg_get_functiondef('private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)'::regprocedure),
     'private.exam_prep_legacy_retest_internal_v1(')=0 THEN
  RAISE EXCEPTION 'weekly_attestation_internal_delegation_bypass';
 END IF;
END;$verify$;
UPDATE private.exam_prep_weekly_flow_rpc_backup_v1 b
SET installed_md5=md5(pg_get_functiondef(b.function_oid))
WHERE installed_md5 IS NULL;
DO $sealed$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1
     WHERE installed_md5 IS NOT NULL AND installed_md5<>original_md5)<>11 THEN
  RAISE EXCEPTION 'weekly_attestation_seal_incomplete';
 END IF;
END;$sealed$;
COMMIT;
