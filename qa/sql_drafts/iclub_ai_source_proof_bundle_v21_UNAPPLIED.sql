-- iClub AI v2.1 P2/P4: source-proof bridge. SCRATCH-ONLY / UNAPPLIED.
-- The academic content team owns editorial publication. THIS file adds only
-- the technical private receiver and READ-only service-role RPC contracts.
DO $source_scratch_guard$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
  OR (inet_server_addr() IS NOT NULL
   AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
   AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
    AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
  RAISE EXCEPTION 'BLOCKED: source proof bridge only in local scratch';
 END IF;
END $source_scratch_guard$;

CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE private.iclub_ai_v21_editorial_source_versions(
 surface_code text NOT NULL,
 subject_key text NOT NULL,
 feature_code text NOT NULL,
 topic_key text NOT NULL,
 locale text NOT NULL CHECK(locale IN ('ru','uz','en')),
 source_id text NOT NULL,
 source_version text NOT NULL,
 -- Immutable digest contract: SHA256(UTF8(source_text || LF ||
 -- JSONB canonical prepared_variants text)).
 source_hash text NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 source_text text NOT NULL DEFAULT '',
 prepared_variants jsonb NOT NULL DEFAULT '{}'::jsonb,
 rights_approved boolean NOT NULL DEFAULT false,
 qa_passed boolean NOT NULL DEFAULT false,
 integrity_verified boolean NOT NULL DEFAULT false,
 runtime_allowed boolean NOT NULL DEFAULT false,
 source_conflict boolean NOT NULL DEFAULT false,
 record_state text NOT NULL DEFAULT 'draft'
   CHECK(record_state IN ('draft','published','suspended')),
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(surface_code,subject_key,feature_code,topic_key,locale,source_id,source_version),
 CHECK(jsonb_typeof(prepared_variants)='object'),
 CHECK(length(source_text)<=16000),
 CHECK(length(source_id) BETWEEN 1 AND 200),
 CHECK(length(source_version) BETWEEN 1 AND 100),
 CHECK(length(topic_key) BETWEEN 1 AND 160),
 CHECK((surface_code='lesson' AND feature_code='topic_explanation')
    OR (surface_code='practice' AND feature_code='answer_explanation')
    OR (surface_code='global' AND subject_key='general'
      AND feature_code='app_help' AND topic_key='navigation'))
);
REVOKE ALL ON TABLE private.iclub_ai_v21_editorial_source_versions
 FROM public,anon,authenticated;
-- No INSERT/UPDATE/DELETE grant or publisher function: editorial production
-- belongs to another workstream, under separately reviewed authorization.

-- A release-row alone is never source attestation. A source row alone is
-- never published. BOTH independent tables, eight release gates, a rights
-- proof and a freshly recomputed SHA256 are required.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_source_proof_service(
 p_surface text,p_subject text,p_feature text,p_topic text,p_locale text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
 SET search_path='' AS $source_proof$
DECLARE v private.iclub_ai_v21_editorial_source_versions%rowtype;
        rel private.iclub_ai_topic_release_v21%rowtype;
BEGIN
 IF p_surface IS NULL OR p_subject IS NULL OR p_feature IS NULL
 OR p_topic IS NULL OR p_locale NOT IN ('ru','uz','en')
 OR p_locale IS NULL THEN
  RETURN jsonb_build_object('approved',false,'reason','in_development');
 END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_global_ai_runtime_config c
 WHERE c.id=1 AND c.kill_switch=false AND c.ui_enabled=true
  AND c.gateway_enabled=true) THEN
  RETURN jsonb_build_object('approved',false,'reason','unavailable');
 END IF;
 SELECT * INTO rel FROM private.iclub_ai_topic_release_v21 r
 WHERE r.surface_code=p_surface AND r.subject_key=p_subject
 AND r.feature_code=p_feature AND r.topic_key=p_topic AND r.locale=p_locale;
 IF NOT FOUND OR rel.publication_state<>'approved' OR rel.feature_enabled<>true
 OR rel.source_conflict OR rel.approved_at IS NULL OR rel.approved_by IS NULL
 OR NOT (rel.content_approved AND rel.rights_approved AND
 rel.source_version_verified AND rel.correctness_passed AND
 rel.negative_tests_passed AND rel.exam_security_passed AND
 rel.locale_verified AND rel.accessibility_passed) THEN
  RETURN jsonb_build_object('approved',false,'reason','in_development');
 END IF;
 SELECT * INTO v FROM private.iclub_ai_v21_editorial_source_versions s
 WHERE s.surface_code=p_surface AND s.subject_key=p_subject
 AND s.feature_code=p_feature AND s.topic_key=p_topic AND s.locale=p_locale
 AND s.source_id=rel.source_id AND s.source_version=rel.source_version;
 IF NOT FOUND OR v.record_state<>'published'
 OR v.rights_approved IS DISTINCT FROM true
 OR v.qa_passed IS DISTINCT FROM true
 OR v.integrity_verified IS DISTINCT FROM true
 OR v.runtime_allowed IS DISTINCT FROM true
 OR v.source_conflict IS DISTINCT FROM false
 OR v.source_hash<>rel.source_hash
 OR v.source_hash<>encode(sha256(convert_to(
  v.source_text||E'\n'||v.prepared_variants::text,'UTF8')),'hex') THEN
  RETURN jsonb_build_object('approved',false,'reason','in_development');
 END IF;
 RETURN jsonb_build_object('approved',true,'rights_approved',true,
 'runtime_allowed',true,'source_conflict',false,
 'source_id',v.source_id,'source_version',v.source_version,'source_hash',v.source_hash);
END;
$source_proof$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_source_proof_service(
 text,text,text,text,text) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_source_proof_service(
 text,text,text,text,text) TO service_role;

-- Read the EXACT source bound to the currently server-minted screen.
-- Return only ONE approved prepared action, never entire answer bank.
-- Cross-subject, cross-locale, stale handle, mismatched hash -> deny.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_source_bundle_service(
 p_user_id uuid,p_context_handle text,
 p_source_id text,p_source_version text,p_source_hash text,
 p_publication_revision bigint,p_locale text,p_route_class text,p_prompt_key text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
 SET search_path='' AS $source_bundle$
DECLARE c jsonb;
        ref jsonb;
        proof jsonb;
        v private.iclub_ai_v21_editorial_source_versions%rowtype;
        r private.iclub_ai_topic_release_v21%rowtype;
        selected_text text;
        prepared jsonb;
BEGIN
 IF p_user_id IS NULL OR p_context_handle IS NULL OR p_source_id IS NULL
 OR p_source_version IS NULL OR p_source_hash IS NULL OR p_publication_revision IS NULL
 OR p_locale NOT IN ('ru','uz','en') OR p_locale IS NULL
 OR p_route_class NOT IN ('prepared','generated') OR p_route_class IS NULL
 OR p_prompt_key IS NULL THEN
  RETURN jsonb_build_object('approved',false,'reason','invalid_request');
 END IF;
 c:=public.get_iclub_ai_v21_scoped_context_service(p_user_id,p_context_handle);
 IF c->>'allowed' IS DISTINCT FROM 'true' THEN
  RETURN jsonb_build_object('approved',false,'reason','context_unavailable');
 END IF;
 ref:=c->'context';
 SELECT * INTO r FROM private.iclub_ai_topic_release_v21 rel
 WHERE rel.surface_code=ref->>'surface' AND rel.subject_key=ref->>'subject'
 AND rel.feature_code=ref->>'feature' AND rel.topic_key=ref->>'topic'
 AND rel.locale=p_locale;
 IF NOT FOUND OR r.source_id<>p_source_id
 OR r.source_version<>p_source_version OR r.source_hash<>p_source_hash
 OR r.publication_revision<>p_publication_revision THEN
  RETURN jsonb_build_object('approved',false,'reason','source_changed');
 END IF;
 proof:=public.get_iclub_ai_v21_source_proof_service(
  ref->>'surface',ref->>'subject',ref->>'feature',ref->>'topic',p_locale);
 IF proof->>'approved' IS DISTINCT FROM 'true' THEN
  RETURN jsonb_build_object('approved',false,'reason','in_development');
 END IF;
 SELECT * INTO v FROM private.iclub_ai_v21_editorial_source_versions s
 WHERE s.surface_code=ref->>'surface' AND s.subject_key=ref->>'subject'
 AND s.feature_code=ref->>'feature' AND s.topic_key=ref->>'topic'
 AND s.locale=p_locale AND s.source_id=p_source_id
 AND s.source_version=p_source_version AND s.source_hash=p_source_hash;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('approved',false,'reason','source_unavailable');
 END IF;
 -- Navigation assistance is deterministic and editorially prepared ONLY.
 -- Never forward unreviewed navigation text to a model to improvise UI steps.
 IF ref->>'surface'='global' AND (
   ref->>'subject'<>'general' OR ref->>'feature'<>'app_help'
   OR ref->>'topic'<>'navigation' OR p_route_class<>'prepared'
   OR p_prompt_key NOT IN ('nav_home','nav_courses','nav_ratings',
     'nav_profile','nav_about','nav_support')) THEN
  RETURN jsonb_build_object('approved',false,'reason','route_unavailable');
 END IF;
 IF p_route_class='prepared' THEN
  IF p_prompt_key !~ '^[a-z0-9_]{3,60}$'
   OR jsonb_typeof(v.prepared_variants->p_prompt_key) IS DISTINCT FROM 'string' THEN
   RETURN jsonb_build_object('approved',false,'reason','in_development');
  END IF;
  selected_text:=v.prepared_variants->>p_prompt_key;
  IF length(btrim(selected_text))=0 OR length(selected_text)>3000 THEN
   RETURN jsonb_build_object('approved',false,'reason','in_development');
  END IF;
  prepared:=jsonb_build_object(p_prompt_key,selected_text);
 ELSE
  IF p_prompt_key<>'' OR length(btrim(v.source_text))<8 THEN
   RETURN jsonb_build_object('approved',false,'reason','in_development');
  END IF;
  selected_text:=v.source_text;
  prepared:='{}'::jsonb;
 END IF;
 RETURN jsonb_build_object('approved',true,'rights_approved',true,
  'qa_passed',true,'integrity_verified',true,'runtime_allowed',true,
  'source_conflict',false,
  'source_id',v.source_id,'source_version',v.source_version,
  'source_hash',v.source_hash,'publication_revision',r.publication_revision,
  'generation_allowed',p_route_class='generated',
  'source_text',CASE WHEN p_route_class='generated' THEN selected_text ELSE '' END,
  'prepared_variants',prepared);
END;
$source_bundle$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_source_bundle_service(
 uuid,text,text,text,text,bigint,text,text,text) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_source_bundle_service(
 uuid,text,text,text,text,bigint,text,text,text) TO service_role;

-- No publishing grants, no dataset seeds, no writes to academic tables.
-- The authorized editorial workflow must publish content in a separate step.
