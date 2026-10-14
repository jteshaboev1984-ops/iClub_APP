-- iClub AI P6 §51 navigation publication gate. UNAPPLIED QA SCRATCH ONLY.
-- Reuses the existing independent editorial source + release tables; no seeds.
-- Navigation labels in the candidate snapshot are NEVER sufficient to publish.
DO $guard$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
   AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
   AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
    AND current_setting('application_name')='iclub_ai_v21_local_scratch'))
 THEN RAISE EXCEPTION 'BLOCKED: P6 navigation source approval is scratch only';END IF;
END $guard$;

-- A global source cannot acquire rights from "general" as a fake subject.
-- It must be approved in ALL THREE locales by the independent editorial
-- publisher and rehash the exact immutable source payload every request.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_general_scope_service()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $general_source_v21$
DECLARE
 v_count integer;v_versions integer;v_version text;v_fingerprint text;
BEGIN
 IF NOT EXISTS (SELECT 1 FROM private.iclub_global_ai_runtime_config c
   WHERE c.id=1 AND c.kill_switch=false AND c.ui_enabled=true
     AND c.gateway_enabled=true) THEN
  RETURN jsonb_build_object('allowed',false,'reason','global_ai_disabled');END IF;
 SELECT count(*)::integer,count(DISTINCT rel.source_version)::integer,
        max(rel.source_version),
        encode(sha256(convert_to(
         string_agg(rel.locale||':'||rel.source_hash,'|' ORDER BY rel.locale),'UTF8')),'hex')
 INTO v_count,v_versions,v_version,v_fingerprint
 FROM private.iclub_ai_topic_release_v21 rel
 WHERE rel.surface_code='global' AND rel.subject_key='general'
   AND rel.feature_code='app_help' AND rel.topic_key='navigation'
   AND rel.locale IN ('ru','uz','en')
   AND public.get_iclub_ai_v21_source_proof_service(
    'global','general','app_help','navigation',rel.locale)->>'approved'='true';
 IF v_count<>3 OR v_versions<>1 OR v_version IS NULL
 OR v_fingerprint IS NULL THEN
  RETURN jsonb_build_object('allowed',false,'reason','source_in_development');
 END IF;
 -- This is a SOURCE capability only, NOT user rights or a billing grant.
 RETURN jsonb_build_object('allowed',true,'scope','general',
  'release_approved',true,'source_version',v_version,
  'source_fingerprint',v_fingerprint);
END;
$general_source_v21$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_general_scope_service()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_general_scope_service()
 TO service_role;
