-- Issue #450 / P0-16B: close remaining real learner action entry points.
-- Source-guarded, additive, NULL-by-default signed JWT epoch; NEVER activate
-- a cutoff or change learner rows, app hours, exams or progress in this file.
BEGIN;
DO $scope$
DECLARE
  v_signature text;
  v_oid regprocedure;
  v_source text;
  v_anchor text;
  v_count int;
  v_after text;
  v_auth_anchor CONSTANT text :=
    'v_uid[[:space:]]*:=[[:space:]]*private[.]exam_prep_require_core_access_v1[(][)];';
BEGIN
  IF to_regprocedure('private.exam_prep_require_writer_epoch_v1()') IS NULL
     OR to_regprocedure('private.exam_prep_writer_epoch_current_v1()') IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='private'
         AND table_name='exam_prep_feature_config'
         AND column_name='writer_min_jwt_iat'
     )
  THEN RAISE EXCEPTION 'P0-16B existing OFF-by-default epoch dependency missing'; END IF;

  FOREACH v_signature IN ARRAY ARRAY[
    -- Current and still-callable previous app versions: no bypass through v1.
    'public.save_exam_prep_exam_profile_v1(text,text,numeric,numeric)',
    'public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)',
    'public.save_exam_prep_study_schedule_safe_v1(integer,integer)',
    'public.save_my_exam_prep_timeline_dates_safe_v1(date,date)',
    'public.save_my_exam_prep_exam_appointment_v1(text,timestamptz)',
    'public.claim_exam_prep_periodic_study_report_safe_v1()',
    'public.record_my_exam_prep_interruption_v1(date,date,text)',
    'public.record_my_exam_prep_interruption_v2(date,date,text)',
    'public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer)',
    'public.start_my_exam_prep_extra_hard_safe_v1(text,text)',
    'public.submit_my_exam_prep_extra_hard_safe_v1(uuid,text,text,text)',
    'public.set_my_exam_prep_exam_ops_confirmation_v1(text,text,boolean)'
  ] LOOP
    v_oid:=to_regprocedure(v_signature);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'P0-16B missing real learner RPC %',v_signature;
    END IF;
    v_source:=pg_get_functiondef(v_oid);
    SELECT count(*) INTO v_count
    FROM regexp_matches(v_source,v_auth_anchor,'gi');
    IF v_count<>1
       OR position('SECURITY DEFINER' IN upper(v_source))=0
       OR position('search_path TO ''''' IN v_source)=0
       OR position('exam_prep_require_writer_epoch_v1' IN v_source)>0
       OR has_function_privilege('anon',v_oid,'EXECUTE')
       OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
    THEN
      RAISE EXCEPTION 'P0-16B RPC ownership/source/ACL drift %, guard anchors=%',
        v_signature,v_count;
    END IF;
    v_anchor:=substring(v_source FROM v_auth_anchor);
    EXECUTE replace(v_source,v_anchor,
      v_anchor||chr(10)||'  PERFORM private.exam_prep_require_writer_epoch_v1();');
    v_after:=pg_get_functiondef(v_oid);
    IF position('PERFORM private.exam_prep_require_writer_epoch_v1();' IN v_after)=0
       OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
       OR has_function_privilege('anon',v_oid,'EXECUTE')
    THEN
      RAISE EXCEPTION 'P0-16B did not retain authorizer/ACL on %',v_signature;
    END IF;
  END LOOP;
END
$scope$;
COMMIT;
