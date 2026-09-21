-- DRAFT ROLLBACK ONLY. Never execute on production without separate explicit
-- owner approval and a reviewed plan for active learners. Refuses Core ON,
-- any enrollment, any active review, or any function/ACL/owner drift.
-- Restores four exact pre-review public definitions and revokes the review
-- starter. Deliberately RETAINS ledger, private verdict, session history,
-- original answers, plans, audit events and synthetic/real evidence.
-- If the base 11-RPC compatibility layer also needs removal, run its separate
-- sealed rollback AFTER this one, under its own explicit approval.
BEGIN;
DO $gate$
DECLARE b record; p pg_proc%rowtype; n integer:=0;
BEGIN
 IF to_regclass('private.exam_prep_weekly_review_rpc_backup_v1') IS NULL
 OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL
 OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL THEN
  RAISE EXCEPTION 'review_rollback_missing_backup_or_ledger';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
  AND core_enabled IS FALSE AND kill_switch IS TRUE) THEN
  RAISE EXCEPTION 'review_rollback_requires_core_off';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1
   WHERE enabled IS TRUE) THEN
  RAISE EXCEPTION 'review_rollback_requires_zero_enrollment';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1 r
  JOIN private.exam_prep_sessions s ON s.authorization_id=r.authorization_id
  WHERE s.status='active') THEN
  RAISE EXCEPTION 'review_rollback_requires_zero_active_review_sessions';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1 ORDER BY signature LOOP
  n:=n+1;
  SELECT * INTO p FROM pg_proc WHERE oid=to_regprocedure(b.signature);
  IF p.oid IS NULL OR b.installed_oid IS NULL OR p.oid<>b.installed_oid OR
     b.installed_md5 IS NULL OR b.sealed_at IS NULL OR
     md5(pg_get_functiondef(p.oid))<>b.installed_md5 OR
     p.proowner IS DISTINCT FROM b.installed_owner OR
     p.proacl IS DISTINCT FROM b.installed_acl OR
     p.prosecdef IS DISTINCT FROM b.installed_security OR
     p.provolatile IS DISTINCT FROM b.installed_volatility THEN
    RAISE EXCEPTION 'review_rollback_refuses_installed_drift_%',b.signature;
  END IF;
  IF b.operation='modified' AND (b.original_definition IS NULL OR
     md5(b.original_definition)<>b.original_md5 OR
     b.original_oid IS DISTINCT FROM p.oid) THEN
    RAISE EXCEPTION 'review_rollback_corrupt_original_backup_%',b.signature;
  END IF;
  IF b.operation='added' AND b.original_definition IS NOT NULL THEN
    RAISE EXCEPTION 'review_rollback_added_endpoint_not_pristine';
  END IF;
 END LOOP;
 IF n<>5 THEN RAISE EXCEPTION 'review_rollback_expected_five_entries_got_%',n; END IF;
END;$gate$;
-- Atomic revoke prevents another authenticated start while the projection
-- definitions are being restored. No ledger or learner rows are deleted.
REVOKE ALL ON FUNCTION public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)
 FROM PUBLIC,anon,authenticated,service_role;
DO $restore$
DECLARE b record;
BEGIN
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1
  WHERE operation='modified' ORDER BY signature LOOP
  EXECUTE b.original_definition;
 END LOOP;
END;$restore$;
DO $verify$
DECLARE b record; p pg_proc%rowtype; n integer:=0;
BEGIN
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1
  WHERE operation='modified' LOOP
  n:=n+1;
  SELECT * INTO p FROM pg_proc WHERE oid=to_regprocedure(b.signature);
  IF p.oid IS NULL OR p.oid<>b.original_oid OR
     md5(pg_get_functiondef(p.oid))<>b.original_md5 OR
     p.proowner IS DISTINCT FROM b.original_owner OR
     p.proacl IS DISTINCT FROM b.original_acl OR
     p.prosecdef IS DISTINCT FROM b.original_security OR
     p.provolatile IS DISTINCT FROM b.original_volatility THEN
    RAISE EXCEPTION 'review_rollback_restore_failed_%',b.signature;
  END IF;
 END LOOP;
 IF n<>4 OR has_function_privilege('anon',
  'public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE') OR
  has_function_privilege('authenticated',
  'public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE') OR
  has_function_privilege('service_role',
  'public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE') THEN
  RAISE EXCEPTION 'review_rollback_postcondition_failed';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1
  WHERE enabled IS TRUE) OR NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
  AND core_enabled IS FALSE AND kill_switch IS TRUE) THEN
  RAISE EXCEPTION 'review_rollback_release_gate_changed';
 END IF;
END;$verify$;
COMMIT;