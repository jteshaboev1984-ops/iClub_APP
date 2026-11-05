-- Issue #450 P0-16B: read API must not write projections through an old
-- signed JWT during a separately authorized, opt-in future cutover.
-- It MUST still return the persisted P1/P5 state without resetting anything.
BEGIN;

CREATE OR REPLACE FUNCTION private.exam_prep_writer_epoch_current_v1()
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $current$
DECLARE v_min bigint; v_claims text; v_iat text;
BEGIN
 SELECT writer_min_jwt_iat INTO v_min
   FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5';
 IF v_min IS NULL THEN RETURN true; END IF;
 v_claims:=nullif(current_setting('request.jwt.claims',true),'');
 v_iat:=coalesce(
   CASE WHEN v_claims IS NOT NULL THEN v_claims::jsonb->>'iat' ELSE NULL END,
   nullif(current_setting('request.jwt.claim.iat',true),''));
 RETURN v_iat IS NOT NULL AND v_iat ~ '^[0-9]{9,12}$'
        AND v_iat::bigint>=v_min;
END
$current$;
REVOKE ALL ON FUNCTION private.exam_prep_writer_epoch_current_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_writer_epoch_current_v1()
 TO service_role;

-- One canonical check shared by the 10 existing scoped write entry points.
CREATE OR REPLACE FUNCTION private.exam_prep_require_writer_epoch_v1()
RETURNS void LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $require$
BEGIN
 IF NOT private.exam_prep_writer_epoch_current_v1() THEN
   RAISE EXCEPTION 'exam_prep_writer_epoch_stale' USING errcode='42501';
 END IF;
END
$require$;
REVOKE ALL ON FUNCTION private.exam_prep_require_writer_epoch_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_require_writer_epoch_v1()
 TO service_role;

-- The original get-state RPC is a read/write projection route: its internal
-- rebuild deletes/recreates stage and skill projections, although the endpoint
-- appears read-only to an old open tab. Skip ONLY that write if epoch is stale.
DO $patch$
DECLARE
  v_oid CONSTANT regprocedure:='public.get_exam_prep_state_safe_v1(text)'::regprocedure;
  v_source text;
  v_anchor CONSTANT text := 'perform private.rebuild_exam_prep_state_v1(v_uid,p_component_code);';
  v_new text;
  v_hits integer;
BEGIN
  v_source:=pg_get_functiondef(v_oid);
  v_hits:=(length(v_source)-length(replace(v_source,v_anchor,'')))/length(v_anchor);
  IF v_hits<>1
    OR position('private.exam_prep_require_core_access_v1()' in v_source)=0
    OR position('SECURITY DEFINER' in upper(v_source))=0
    OR position('search_path TO ''''' in v_source)=0
    OR position('exam_prep_writer_epoch_current_v1' in v_source)>0
    OR has_function_privilege('anon',v_oid,'EXECUTE')
  THEN RAISE EXCEPTION 'P0-16B GET state writer source/ACL drift, anchors=%',v_hits; END IF;
  v_new:=replace(v_source,v_anchor,
    'if private.exam_prep_writer_epoch_current_v1() then'||chr(10)||
    '    '||v_anchor||chr(10)||
    '  end if;');
  EXECUTE v_new;
  IF position('if private.exam_prep_writer_epoch_current_v1() then'
     in pg_get_functiondef(v_oid))=0
     OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
  THEN RAISE EXCEPTION 'P0-16B guarded projection read not installed'; END IF;
END
$patch$;
COMMIT;
