-- Issue #450 P0-16B, continuation of NULL-by-default signed JWT writer epoch.
-- Cover common learner actions, not synthetic/admin maintenance or read endpoints.
-- No cutoff activation and NO live user data changes.
BEGIN;
DO $guard$
DECLARE
  v_sig text; v_oid regprocedure; v_src text; v_anchor text;
  v_pattern CONSTANT text :=
    'v_uid[[:space:]]*:=[[:space:]]*private[.]exam_prep_require_core_access_v1[(][)];';
  v_hits integer;
BEGIN
  IF to_regprocedure('private.exam_prep_require_writer_epoch_v1()') IS NULL
     OR NOT EXISTS(SELECT 1 FROM information_schema.columns
         WHERE table_schema='private'
           AND table_name='exam_prep_feature_config'
           AND column_name='writer_min_jwt_iat')
  THEN RAISE EXCEPTION 'P0-16B signed JWT guard dependency absent'; END IF;
  FOREACH v_sig IN ARRAY ARRAY[
    'public.start_exam_prep_next_diagnostic_safe_v1(text,text)',
    'public.finalize_exam_prep_session_safe_v1(uuid,text)',
    'public.finalize_exam_prep_session_written_v1(uuid,text)',
    'public.advance_exam_prep_written_step_safe_v1(uuid,integer,text)',
    'public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)',
    'public.generate_exam_prep_weekly_plan_safe_v3(text)'
  ] LOOP
    v_oid:=to_regprocedure(v_sig);
    IF v_oid IS NULL THEN RAISE EXCEPTION 'P0-16B missing real Core RPC %',v_sig; END IF;
    v_src:=pg_get_functiondef(v_oid);
    SELECT count(*) INTO v_hits FROM regexp_matches(v_src,v_pattern,'gi');
    IF v_hits<>1 OR position('SECURITY DEFINER' in upper(v_src))=0
      OR position('search_path TO ''''' in v_src)=0
      OR position('exam_prep_require_writer_epoch_v1' in v_src)>0
      OR has_function_privilege('anon',v_oid,'EXECUTE')
    THEN RAISE EXCEPTION 'P0-16B Core writer source drift: %, anchors=%',v_sig,v_hits; END IF;
    v_anchor:=substring(v_src FROM v_pattern);
    EXECUTE replace(v_src,v_anchor,
       v_anchor||chr(10)||'  PERFORM private.exam_prep_require_writer_epoch_v1();');
    IF position('PERFORM private.exam_prep_require_writer_epoch_v1();' in pg_get_functiondef(v_oid))=0
       OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
       OR has_function_privilege('anon',v_oid,'EXECUTE')
    THEN RAISE EXCEPTION 'P0-16B Core writer guard/ACL failed: %',v_sig; END IF;
  END LOOP;
END
$guard$;
COMMIT;
