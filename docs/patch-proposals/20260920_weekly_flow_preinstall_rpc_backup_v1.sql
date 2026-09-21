-- REVIEW-ONLY proposal. Never run on live production without separate explicit approval.
-- Must run AFTER three draft prerequisites, BEFORE atomic compatibility SQL.
-- Captures all eight legacy public interfaces + three already proposed safe ones.
BEGIN;
DO $gate$
BEGIN
 IF to_regclass('private.exam_prep_weekly_flow_rpc_backup_v1') IS NOT NULL
    OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NOT NULL
    OR to_regprocedure('private.exam_prep_legacy_generate_v1_internal_v1(text,text)') IS NOT NULL
    OR to_regprocedure('private.exam_prep_legacy_generate_v2_internal_v1(text)') IS NOT NULL THEN
  RAISE EXCEPTION 'weekly_backup_not_pristine';
 END IF;
END;$gate$;
CREATE TABLE private.exam_prep_weekly_flow_rpc_backup_v1 (
 signature text PRIMARY KEY,
 function_oid oid NOT NULL UNIQUE,
 original_definition text NOT NULL,
 original_md5 text NOT NULL,
 original_owner oid NOT NULL,
 original_acl aclitem[],
 original_security boolean NOT NULL,
 original_volatility char NOT NULL,
 installed_md5 text,
 captured_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.exam_prep_weekly_flow_rpc_backup_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_weekly_flow_rpc_backup_v1 FROM PUBLIC,anon,authenticated,service_role;
INSERT INTO private.exam_prep_weekly_flow_rpc_backup_v1
(signature,function_oid,original_definition,original_md5,original_owner,
 original_acl,original_security,original_volatility)
SELECT required.signature,p.oid,pg_get_functiondef(p.oid),md5(pg_get_functiondef(p.oid)),
 p.proowner,p.proacl,p.prosecdef,p.provolatile
FROM (VALUES
 ('public.generate_exam_prep_weekly_plan_safe_v1(text,text)'),
 ('public.generate_exam_prep_weekly_plan_safe_v2(text)'),
 ('public.generate_exam_prep_weekly_plan_safe_v3(text)'),
 ('public.authorize_exam_prep_correction_safe_v1(uuid)'),
 ('public.authorize_exam_prep_mixed_safe_v1(text)'),
 ('public.authorize_exam_prep_retest_safe_v1(uuid)'),
 ('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)'),
 ('public.start_exam_prep_session_safe_v1(uuid,text)'),
 ('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)'),
 ('public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)'),
 ('public.start_exam_prep_plan_session_once_safe_v1(uuid,text)')
) AS required(signature) JOIN pg_proc p ON p.oid=to_regprocedure(required.signature);
DO $verify$
DECLARE v_count integer; v_drift integer; v_changed text;
BEGIN
 SELECT count(*) INTO v_count FROM private.exam_prep_weekly_flow_rpc_backup_v1;
 IF v_count<>11 THEN RAISE EXCEPTION 'weekly_backup_incomplete_%',v_count; END IF;
 SELECT string_agg(x.signature||': actual='||coalesce(b.original_md5,'MISSING')||' expected='||x.expected_md5,'; ' ORDER BY x.signature)
 INTO v_changed FROM (VALUES
 ('public.generate_exam_prep_weekly_plan_safe_v1(text,text)','58247a59c0967848d21c5ab93cc9d647'),
 ('public.generate_exam_prep_weekly_plan_safe_v2(text)','414916cc437d0d47a34916d15d0a1f05'),
 ('public.generate_exam_prep_weekly_plan_safe_v3(text)','43113f759097c94e4938fb46daa73145'),
 ('public.authorize_exam_prep_correction_safe_v1(uuid)','6ec9de1e0ee9ae4b9b41e80b5f61c2cf'),
 ('public.authorize_exam_prep_mixed_safe_v1(text)','848a4e2ea017ae97a4adfd7e6df907f6'),
 ('public.authorize_exam_prep_retest_safe_v1(uuid)','7e0f81e085354f969ded2eb9fbfa136d'),
 ('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)','d311a67f74c0a1195339947e237f83b1'),
 ('public.start_exam_prep_session_safe_v1(uuid,text)','51b06344e1c4c34d7d9a1d9eae354e06')
 ) x(signature,expected_md5)
 LEFT JOIN private.exam_prep_weekly_flow_rpc_backup_v1 b ON b.signature=x.signature
 WHERE b.original_md5 IS DISTINCT FROM x.expected_md5;
 IF v_changed IS NOT NULL THEN
  RAISE EXCEPTION 'weekly_backup_live_legacy_definition_drift: %',v_changed;
 END IF;
 SELECT count(*) INTO v_drift FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 JOIN pg_proc p ON p.oid=b.function_oid
 WHERE p.proowner<>'postgres'::regrole::oid OR NOT p.prosecdef OR p.provolatile<>'v'
   OR has_function_privilege('anon',p.oid,'EXECUTE')
   OR NOT has_function_privilege('authenticated',p.oid,'EXECUTE');
 IF v_drift<>0 THEN RAISE EXCEPTION 'weekly_backup_function_security_drift_%',v_drift; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_rpc_backup_v1 WHERE installed_md5 IS NOT NULL) THEN
  RAISE EXCEPTION 'weekly_backup_already_attested';
 END IF;
END;$verify$;
COMMIT;
