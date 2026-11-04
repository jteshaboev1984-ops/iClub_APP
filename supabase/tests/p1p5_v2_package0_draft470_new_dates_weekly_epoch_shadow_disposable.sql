-- Issue #450 P0-19: exact unmerged PR #470 P2-16/P2-17 learner date
-- and voluntary weekly target writers, after 14 pinned 2026110303/04 migrations.
-- DISPOSABLE PostgreSQL 17 ONLY. NOT a production migration/deployment.
-- Protect personal P1/P5 dates, leave old school-confirmed appointments
-- historical, and never conflate student-chosen date with official timetable.
\set ON_ERROR_STOP on
DO $p019$
DECLARE
 v_rpc text; v_oid oid; v_definition text;
 v_anchor text:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_patched integer:=0;
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR to_regclass('private.p0_16_academic_epoch_gate') IS NULL
 OR (SELECT epoch FROM private.p0_16_academic_epoch_gate
     WHERE program_key='math_as_p1_p5')<>2
 OR to_regclass('private.exam_prep_learner_exam_dates_v1') IS NULL
 THEN RAISE EXCEPTION 'P0-19 refuses unpinned/non-disposable P2 schema'; END IF;
 IF (SELECT count(*) FROM information_schema.columns
  WHERE table_schema='private'
   AND table_name='exam_prep_learner_exam_dates_v1'
   AND column_name IN ('user_id','program_version_id','component_code','exam_date'))<>4
 THEN RAISE EXCEPTION 'P0-19 learner dates ownership FK/columns changed'; END IF;
 IF has_table_privilege('authenticated','private.exam_prep_learner_exam_dates_v1','INSERT')
 OR has_table_privilege('authenticated','private.exam_prep_learner_exam_dates_v1','UPDATE')
 OR has_table_privilege('anon','private.exam_prep_learner_exam_dates_v1','INSERT')
 THEN RAISE EXCEPTION 'P0-19 learner-chosen date table is exposed to clients'; END IF;

 FOR v_rpc IN SELECT unnest(ARRAY[
   'save_my_exam_prep_timeline_dates_safe_v1',
   'accept_my_exam_prep_timeline_weekly_target_safe_v1'
 ]) LOOP
  SELECT p.oid INTO STRICT v_oid FROM pg_proc p JOIN pg_namespace n
   ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname=v_rpc
   AND has_function_privilege('authenticated',p.oid,'EXECUTE')
   AND NOT has_function_privilege('anon',p.oid,'EXECUTE');
  v_definition:=pg_get_functiondef(v_oid);
  IF (length(v_definition)-length(replace(v_definition,v_anchor,'')))<>length(v_anchor)
  OR v_definition LIKE '%p0_16_require_current_epoch_v1%'
  OR v_definition NOT ILIKE '%SECURITY DEFINER%'
  THEN RAISE EXCEPTION 'P0-19 unsafe source mutation on %',v_rpc; END IF;
  EXECUTE replace(v_definition,v_anchor,
    v_anchor||E'\n  PERFORM private.p0_16_require_current_epoch_v1(v_uid,NULL::uuid);');
  v_patched:=v_patched+1;
 END LOOP;
 IF v_patched<>2 THEN RAISE EXCEPTION 'P0-19 incomplete personal-date/recommendation gate'; END IF;
 IF EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_exam_prep_simple_learning_timeline_safe_v1'
   AND pg_get_functiondef(p.oid) LIKE '%private.p0_16_require_current_epoch_v1%'
 ) THEN RAISE EXCEPTION 'P0-19 accidentally modified learner read projection'; END IF;
 RAISE NOTICE 'PASS P0-19 two actual P2 learner write RPCs fenced, historical appointments and read projections untouched';
END $p019$;
