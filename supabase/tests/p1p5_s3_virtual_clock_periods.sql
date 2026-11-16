-- S3 CI-only time warp. Absolute requirement: an EPHEMERAL PG17 source stack.
-- Do not relabel existing academic users as "synthetic": the real governance
-- preflight refuses identities with existing evidence, even in tests.
-- Override the clock function ONLY in this disposable test DB and never in migrations.
\set ON_ERROR_STOP on
BEGIN;
DO $guard$
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users) <> 2
 OR (SELECT count(*) FROM auth.users) <> 2
 OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities)
 OR to_regprocedure('private.exam_prep_effective_academic_now_v1(uuid)') IS NULL
 OR NOT EXISTS(
    SELECT 1 FROM private.exam_prep_component_placements p
    WHERE p.user_id='11111111-1111-4111-8111-111111111191'::uuid
      AND p.stage0_complete=true AND p.component_code IN ('P1','P5'))
 THEN RAISE EXCEPTION 'S3 virtual calendar refused: disposable PG17 two-owner boundary required'; END IF;
END $guard$;
CREATE OR REPLACE FUNCTION private.exam_prep_effective_academic_now_v1(p_user_id uuid)
RETURNS timestamptz LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $clock$
BEGIN
 IF p_user_id='11111111-1111-4111-8111-111111111191'::uuid THEN
   RETURN now()+interval '40 days';
 END IF;
 RETURN now();
END;
$clock$;
COMMIT;
