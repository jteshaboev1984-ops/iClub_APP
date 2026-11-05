-- Issue #450 / P0-16B: future-only signed JWT write epoch for REAL Paper RPCs.
-- NULL by default; nothing is enabled, reset or published in this migration.
BEGIN;
ALTER TABLE private.exam_prep_feature_config
 ADD COLUMN IF NOT EXISTS writer_min_jwt_iat bigint;
COMMENT ON COLUMN private.exam_prep_feature_config.writer_min_jwt_iat IS
 'P0-16B opt-in signed JWT iat cutoff; NULL=OFF. Activation requires separate approval.';

CREATE OR REPLACE FUNCTION private.exam_prep_require_writer_epoch_v1()
RETURNS void LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $guard$
DECLARE v_min bigint; v_claims text; v_iat text;
BEGIN
 SELECT writer_min_jwt_iat INTO v_min FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5';
 IF v_min IS NULL THEN RETURN; END IF;
 -- PostgREST verifies token signature before writing request.jwt.claims.
 v_claims:=nullif(current_setting('request.jwt.claims',true),'');
 v_iat:=coalesce(
   CASE WHEN v_claims IS NOT NULL THEN v_claims::jsonb->>'iat' ELSE NULL END,
   nullif(current_setting('request.jwt.claim.iat',true),''));
 IF v_iat IS NULL OR v_iat !~ '^[0-9]{9,12}$' OR v_iat::bigint<v_min THEN
   RAISE EXCEPTION 'exam_prep_writer_epoch_stale' USING errcode='42501';
 END IF;
END
$guard$;
REVOKE ALL ON FUNCTION private.exam_prep_require_writer_epoch_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_require_writer_epoch_v1()
 TO service_role;

DO $patch$
DECLARE
 v_sig text; v_oid regprocedure; v_src text; v_anchor text; v_new text;
 v_pattern CONSTANT text :=
   'v_uid[[:space:]]*:=[[:space:]]*private[.]exam_prep_require_core_access_v1[(][)];';
 v_hits int;
BEGIN
 FOREACH v_sig IN ARRAY ARRAY[
  'public.authorize_exam_prep_timed_safe_v1(bigint)',
  'public.start_exam_prep_session_safe_v1(uuid,text)',
  'public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)',
  'public.finalize_exam_prep_timed_safe_v1(uuid,text,text)'
 ] LOOP
   v_oid:=to_regprocedure(v_sig);
   IF v_oid IS NULL THEN RAISE EXCEPTION 'P0-16B missing RPC %',v_sig; END IF;
   v_src:=pg_get_functiondef(v_oid);
   SELECT count(*) INTO v_hits FROM regexp_matches(v_src,v_pattern,'gi');
   IF v_hits<>1 OR position('SECURITY DEFINER' in upper(v_src))=0
      OR position('search_path TO ''''' in v_src)=0
      OR position('exam_prep_require_writer_epoch_v1' in v_src)>0
      OR has_function_privilege('anon',v_oid,'EXECUTE')
   THEN RAISE EXCEPTION 'P0-16B source/ACL drift on %, anchors=%',v_sig,v_hits; END IF;
   v_anchor:=substring(v_src FROM v_pattern);
   v_new:=replace(v_src,v_anchor,v_anchor||chr(10)||
     '  PERFORM private.exam_prep_require_writer_epoch_v1();');
   EXECUTE v_new;
   IF position('PERFORM private.exam_prep_require_writer_epoch_v1();' in pg_get_functiondef(v_oid))=0
      OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
      OR has_function_privilege('anon',v_oid,'EXECUTE')
   THEN RAISE EXCEPTION 'P0-16B guard/ACL check failed %',v_sig; END IF;
 END LOOP;
END
$patch$;
COMMIT;
