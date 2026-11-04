-- Issue #450 P0-18: PR #469 snapshot P1/P5 horizon/schedule/report writers.
-- ISOLATED PG17 ONLY. This is a test overlay, NOT a production migration.
-- Requires the THREE EXACT draft PR #469 additive migrations to have been
-- independently installed from pinned commit e125c0e43878a3910aaa66b32ee9cb848402a0ec.
-- The existing P0-16/17 test gate is already epoch=2. No live student data.
\set ON_ERROR_STOP on
DO $p018$
DECLARE
 v_rpc text;
 v_oid oid;
 v_definition text;
 v_anchor text:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_written integer:=0;
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR to_regclass('private.p0_16_academic_epoch_gate') IS NULL
 OR (SELECT epoch FROM private.p0_16_academic_epoch_gate
     WHERE program_key='math_as_p1_p5')<>2
 OR to_regclass('private.exam_prep_periodic_study_report_receipts_v1') IS NULL
 THEN RAISE EXCEPTION 'P0-18 refused missing isolated pinned draft P1 candidate'; END IF;
 IF (SELECT count(*) FROM information_schema.columns
     WHERE table_schema='private'
     AND table_name='exam_prep_periodic_study_report_receipts_v1'
     AND column_name IN ('program_version_id','diagnostic_anchor_at'))<>2
 THEN RAISE EXCEPTION 'P0-18 refuses old unscoped receipt key'; END IF;
 IF EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
   AND p.proname IN ('get_exam_prep_personal_horizon_safe_v1',
                    'get_exam_prep_study_schedule_safe_v1')
   AND pg_get_functiondef(p.oid) LIKE '%private.p0_16_require_current_epoch_v1%'
 ) THEN RAISE EXCEPTION 'P0-18 unexpectedly changed read-only projections'; END IF;

 FOR v_rpc IN SELECT unnest(ARRAY[
  'save_my_exam_prep_exam_appointment_v2',
  'save_exam_prep_study_schedule_safe_v1',
  'claim_exam_prep_periodic_study_report_safe_v1'
 ]) LOOP
  SELECT p.oid INTO STRICT v_oid FROM pg_proc p
   JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname=v_rpc
     AND has_function_privilege('authenticated',p.oid,'EXECUTE')
     AND NOT has_function_privilege('anon',p.oid,'EXECUTE');
  v_definition:=pg_get_functiondef(v_oid);
  IF (length(v_definition)-length(replace(v_definition,v_anchor,'')))<>length(v_anchor)
  OR v_definition NOT ILIKE '%SECURITY DEFINER%'
  OR v_definition LIKE '%p0_16_require_current_epoch_v1%'
  THEN RAISE EXCEPTION 'P0-18 refusing draft writer source/ACL drift: %',v_rpc; END IF;
  EXECUTE replace(v_definition,v_anchor,
       v_anchor||E'\n  PERFORM private.p0_16_require_current_epoch_v1(v_uid,NULL::uuid);');
  v_written:=v_written+1;
 END LOOP;
 IF v_written<>3 THEN RAISE EXCEPTION 'P0-18 missing draft writer'; END IF;
 RAISE NOTICE 'PASS P0-18 exactly three draft 469 writes fenced; two read-only queries untouched';
END $p018$;
