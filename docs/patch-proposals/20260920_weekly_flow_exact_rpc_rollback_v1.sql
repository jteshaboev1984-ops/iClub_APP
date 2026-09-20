-- REVIEW-ONLY ROLLBACK. DO NOT RUN ON PRODUCTION WITHOUT ARCHITECT APPROVAL.
-- Requires an independently reviewed preinstall snapshot AND postinstall seal.
-- Operational order: stop weekly-flow entry, turn Core OFF via a separately
-- authorized safe release procedure, verify zero approved enabled enrollments.
-- This script NEVER disables students automatically or deletes any data.
-- Aborts rather than overwriting intervening function or privilege changes.
-- Intentionally RETAINS private backup, private helper, private legacy copies
-- and disabled enrollment records; no DROP/CASCADE or academic-data writes.
-- Weekly-flow must NOT be reenabled after this rollback without reinstallation.
BEGIN;
DO $gate$
DECLARE
 b record;
 p pg_proc%rowtype;
 v_count integer:=0;
BEGIN
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NULL
    OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL THEN
    RAISE EXCEPTION 'weekly_rollback_backup_or_enrollment_missing';
 END IF;
 IF NOT EXISTS (
   SELECT 1 FROM private.exam_prep_feature_config
   WHERE program_key='math_as_p1_p5' AND rollout_state='off'
     AND core_enabled IS FALSE AND kill_switch IS TRUE
 ) THEN RAISE EXCEPTION 'weekly_rollback_requires_core_off'; END IF;
 IF EXISTS (SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE) THEN
   RAISE EXCEPTION 'weekly_rollback_requires_zero_enrolled_learners';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_flow_rpc_backup_v1 LOOP
   v_count:=v_count+1;
   SELECT * INTO p FROM pg_proc WHERE oid=to_regprocedure(b.signature);
   IF p.oid IS NULL OR p.oid<>b.function_oid OR b.installed_md5 IS NULL
      OR b.original_definition IS NULL
      OR md5(b.original_definition)<>b.original_md5
      OR md5(pg_get_functiondef(p.oid))<>b.installed_md5
      OR p.proowner IS DISTINCT FROM b.original_owner
      OR p.proacl IS DISTINCT FROM b.original_acl
      OR p.prosecdef IS DISTINCT FROM b.original_security
      OR p.provolatile IS DISTINCT FROM b.original_volatility THEN
      RAISE EXCEPTION 'weekly_rollback_refuses_function_drift_%',b.signature;
   END IF;
 END LOOP;
 IF v_count<>7 THEN RAISE EXCEPTION 'weekly_rollback_incomplete_backup_%',v_count; END IF;
END;$gate$;
DO $restore$
DECLARE b record;
BEGIN
 FOR b IN SELECT * FROM private.exam_prep_weekly_flow_rpc_backup_v1 ORDER BY signature LOOP
   EXECUTE b.original_definition;
 END LOOP;
END;$restore$;
DO $verify$
DECLARE b record;
 p pg_proc%rowtype;
 v_count integer:=0;
BEGIN
 FOR b IN SELECT * FROM private.exam_prep_weekly_flow_rpc_backup_v1 LOOP
   v_count:=v_count+1;
   SELECT * INTO p FROM pg_proc WHERE oid=to_regprocedure(b.signature);
   IF p.oid IS NULL OR p.oid<>b.function_oid
      OR md5(pg_get_functiondef(p.oid))<>b.original_md5
      OR p.proowner IS DISTINCT FROM b.original_owner
      OR p.proacl IS DISTINCT FROM b.original_acl
      OR p.prosecdef IS DISTINCT FROM b.original_security
      OR p.provolatile IS DISTINCT FROM b.original_volatility THEN
     RAISE EXCEPTION 'weekly_rollback_restoration_failed_%',b.signature;
   END IF;
 END LOOP;
 IF v_count<>7 THEN RAISE EXCEPTION 'weekly_rollback_restored_count_%',v_count; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE)
    OR NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
       WHERE program_key='math_as_p1_p5' AND rollout_state='off'
         AND core_enabled IS FALSE AND kill_switch IS TRUE) THEN
   RAISE EXCEPTION 'weekly_rollback_release_gate_changed';
 END IF;
END;$verify$;
COMMIT;
