BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';

DO $preflight$
BEGIN
  IF to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL
     OR to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL
  THEN
    RAISE EXCEPTION 'weekly_flow_status_prerequisite_missing';
  END IF;
  IF to_regprocedure('public.get_my_exam_prep_weekly_flow_status_v1()') IS NOT NULL THEN
    RAISE EXCEPTION 'weekly_flow_status_already_installed';
  END IF;
END
$preflight$;

CREATE FUNCTION public.get_my_exam_prep_weekly_flow_status_v1()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path=''
AS $fn$
DECLARE
  v_uid uuid:=auth.uid();
  v_enabled boolean:=false;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  v_enabled:=private.exam_prep_weekly_flow_enrolled_v1(v_uid);

  RETURN jsonb_build_object(
    'contract_version','weekly_flow_status_v1',
    'enabled',v_enabled
  );
END
$fn$;

REVOKE ALL ON FUNCTION public.get_my_exam_prep_weekly_flow_status_v1()
FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_weekly_flow_status_v1()
TO authenticated,service_role;

DO $postcheck$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname='get_my_exam_prep_weekly_flow_status_v1'
      AND p.prosecdef IS TRUE
      AND p.provolatile='s'
      AND p.proowner='postgres'::regrole::oid
  ) THEN
    RAISE EXCEPTION 'weekly_flow_status_security_postcheck_failed';
  END IF;

  IF has_function_privilege('anon',
      'public.get_my_exam_prep_weekly_flow_status_v1()'::regprocedure,'EXECUTE')
  THEN
    RAISE EXCEPTION 'weekly_flow_status_anon_execute_detected';
  END IF;

  IF NOT has_function_privilege('authenticated',
      'public.get_my_exam_prep_weekly_flow_status_v1()'::regprocedure,'EXECUTE')
  THEN
    RAISE EXCEPTION 'weekly_flow_status_authenticated_execute_missing';
  END IF;
END
$postcheck$;

COMMIT;
