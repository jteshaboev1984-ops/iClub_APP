-- DRAFT ONLY. Not in supabase/migrations; NEVER apply to live production without
-- separate explicit owner authorization. Run AFTER base weekly-flow + adherence
-- proposals, BEFORE any 20260921 learning-review SQL. Creates backup metadata,
-- no student, academic, Practice, Tour, or historical data writes.
BEGIN;
DO $gate$
BEGIN
 IF to_regclass('private.exam_prep_weekly_review_rpc_backup_v1') IS NOT NULL
 OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NOT NULL
 OR to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') IS NOT NULL
 OR to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NOT NULL THEN
  RAISE EXCEPTION 'review_backup_not_pristine';
 END IF;
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NULL
 OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL THEN
  RAISE EXCEPTION 'review_backup_base_weekly_prerequisites_missing';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
    AND core_enabled IS FALSE AND kill_switch IS TRUE)
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE) THEN
  RAISE EXCEPTION 'review_backup_requires_core_off_and_zero_enrollment';
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1
     WHERE installed_md5 IS NOT NULL AND installed_md5<>original_md5)<>11 THEN
  RAISE EXCEPTION 'review_backup_requires_sealed_base_11_rpc_install';
 END IF;
END;$gate$;
CREATE TABLE private.exam_prep_weekly_review_rpc_backup_v1 (
 signature text PRIMARY KEY,
 operation text NOT NULL CHECK(operation IN ('modified','added')),
 original_oid oid UNIQUE,
 original_definition text,
 original_md5 text,
 original_owner oid,
 original_acl aclitem[],
 original_security boolean,
 original_volatility char,
 installed_oid oid UNIQUE,
 installed_md5 text,
 installed_owner oid,
 installed_acl aclitem[],
 installed_security boolean,
 installed_volatility char,
 captured_at timestamptz NOT NULL DEFAULT now(),
 sealed_at timestamptz,
 CHECK ((operation='modified' AND original_oid IS NOT NULL
    AND original_definition IS NOT NULL AND original_md5 IS NOT NULL
    AND original_owner IS NOT NULL AND original_security IS NOT NULL
    AND original_volatility IS NOT NULL)
  OR (operation='added' AND original_oid IS NULL
    AND original_definition IS NULL AND original_md5 IS NULL))
);
ALTER TABLE private.exam_prep_weekly_review_rpc_backup_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_weekly_review_rpc_backup_v1
 FROM PUBLIC,anon,authenticated,service_role;
INSERT INTO private.exam_prep_weekly_review_rpc_backup_v1(
 signature,operation,original_oid,original_definition,original_md5,
 original_owner,original_acl,original_security,original_volatility)
SELECT names.signature,'modified',p.oid,pg_get_functiondef(p.oid),
 md5(pg_get_functiondef(p.oid)),p.proowner,p.proacl,p.prosecdef,p.provolatile
FROM (VALUES
 ('public.get_exam_prep_active_plan_session_safe_v1(text)'),
 ('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'),
 ('public.get_exam_prep_weekly_progress_safe_v1(text)'),
 ('public.get_exam_prep_previous_week_adherence_safe_v1(text)')
) names(signature)
JOIN pg_proc p ON p.oid=to_regprocedure(names.signature);
INSERT INTO private.exam_prep_weekly_review_rpc_backup_v1(signature,operation)
VALUES('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','added');
DO $verify$
DECLARE b record; n integer:=0;
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1)<>5 OR
   (SELECT count(*) FROM private.exam_prep_weekly_review_rpc_backup_v1 WHERE operation='modified')<>4 THEN
  RAISE EXCEPTION 'review_backup_missing_affected_rpc';
 END IF;
 FOR b IN SELECT * FROM private.exam_prep_weekly_review_rpc_backup_v1
  WHERE operation='modified' LOOP
  n:=n+1;
  IF b.original_owner IS DISTINCT FROM 'postgres'::regrole::oid OR
     NOT b.original_security OR
     has_function_privilege('anon',b.original_oid,'EXECUTE') OR
     NOT has_function_privilege('authenticated',b.original_oid,'EXECUTE') OR
     md5(b.original_definition)<>b.original_md5 THEN
    RAISE EXCEPTION 'review_backup_security_or_definition_drift_%',b.signature;
  END IF;
 END LOOP;
 IF n<>4 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_review_rpc_backup_v1
   WHERE installed_md5 IS NOT NULL OR sealed_at IS NOT NULL) THEN
  RAISE EXCEPTION 'review_backup_not_unsealed';
 END IF;
END;$verify$;
COMMIT;