-- iClub AI Layer v2.1 — TECHNICAL publication gate only, NO CONTENT.
-- DO NOT APPLY: scratch PostgreSQL only. Not in supabase/migrations.
-- Content/questions/cards are authored and editorially approved in a separate workstream.
-- This registry is the technical interface for a FUTURE approved publication workflow.
-- The table does not store lessons, questions, answers, prompts or learner data.
DO $iclub_ai_v21_release_scratch_only$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
    OR (inet_server_addr() IS NOT NULL AND
        inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)) THEN
   RAISE EXCEPTION 'BLOCKED: topic readiness draft is scratch only';
 END IF;
END $iclub_ai_v21_release_scratch_only$;

CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE IF NOT EXISTS private.iclub_ai_topic_release_v21(
 surface_code text not null,
 subject_key text not null,
 feature_code text not null,
 topic_key text not null,
 locale text not null check(locale in ('ru','uz','en')),
 source_id text not null,
 source_version text not null,
 source_hash text not null check(source_hash ~ '^[0-9a-f]{64}$'),
 -- Individual editorial and technical gates; NEVER derive from card count.
 content_approved boolean not null default false,
 rights_approved boolean not null default false,
 source_version_verified boolean not null default false,
 correctness_passed boolean not null default false,
 negative_tests_passed boolean not null default false,
 exam_security_passed boolean not null default false,
 locale_verified boolean not null default false,
 accessibility_passed boolean not null default false,
 source_conflict boolean not null default false,
 publication_state text not null default 'draft'
   check(publication_state in ('draft','approved','suspended')),
 feature_enabled boolean not null default false,
 -- Not an authorization to launch beta. Global rollout + per-user cohort
 -- authorization is checked separately by the Edge, including owner approval.
 publication_revision bigint not null default 1
   check(publication_revision>0),
 approved_at timestamptz,
 approved_by uuid,
 updated_at timestamptz not null default now(),
 primary key(surface_code,subject_key,feature_code,topic_key,locale),
 check(
   publication_state<>'approved' OR (
    approved_at is not null
    and approved_by is not null
    and content_approved and rights_approved and source_version_verified
    and correctness_passed and negative_tests_passed
    and exam_security_passed and locale_verified and accessibility_passed
    and source_conflict=false
   )
 ),
 check(length(surface_code) between 1 and 90
   and length(subject_key) between 1 and 90
   and length(feature_code) between 1 and 90
   and length(topic_key) between 1 and 160
   and length(source_id) between 1 and 200
   and length(source_version) between 1 and 100)
);
REVOKE ALL ON TABLE private.iclub_ai_topic_release_v21
  FROM public,anon,authenticated;
GRANT SELECT ON TABLE private.iclub_ai_topic_release_v21 TO service_role;

CREATE OR REPLACE FUNCTION public.get_iclub_ai_topic_release_service_v21(
 p_surface text,p_subject text,p_feature text,p_topic text,p_locale text
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $$
DECLARE
 v private.iclub_ai_topic_release_v21%rowtype;
BEGIN
 IF p_surface is null or p_subject is null or p_feature is null
    or p_topic is null or p_locale not in ('ru','uz','en')
    or p_locale is null
    or length(p_surface) not between 1 and 90
    or length(p_subject) not between 1 and 90
    or length(p_feature) not between 1 and 90
    or length(p_topic) not between 1 and 160 THEN
  RETURN jsonb_build_object('ready',false,'reason','invalid_context');
 END IF;

 -- A global, independent OFF switch is mandatory even for fully published rows.
 IF NOT EXISTS(
   SELECT 1 FROM private.iclub_global_ai_runtime_config cfg
   WHERE cfg.id=1 AND cfg.kill_switch=false
      AND cfg.ui_enabled=true AND cfg.gateway_enabled=true
 ) THEN
  RETURN jsonb_build_object('ready',false,'reason','global_ai_disabled');
 END IF;

 SELECT * INTO v FROM private.iclub_ai_topic_release_v21
 WHERE surface_code=p_surface and subject_key=p_subject
   and feature_code=p_feature and topic_key=p_topic and locale=p_locale;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('ready',false,'reason','in_development');
 END IF;
 IF v.publication_state<>'approved' OR v.feature_enabled<>true
    OR v.source_conflict=true OR v.approved_at is null OR v.approved_by is null
    OR NOT (
      v.content_approved AND v.rights_approved AND v.source_version_verified
      AND v.correctness_passed AND v.negative_tests_passed
      AND v.exam_security_passed AND v.locale_verified AND v.accessibility_passed
    ) THEN
  RETURN jsonb_build_object('ready',false,'reason','in_development');
 END IF;

 -- Only the trusted Edge reads this metadata. STILL require at request time:
 -- authenticated owner, active exam protection, per-user cohort, exact live
 -- source hash/version/rights and output proof. Not an AI or billing permission.
 RETURN jsonb_build_object(
   'ready',true,'surface',v.surface_code,'subject',v.subject_key,
   'feature',v.feature_code,'topic',v.topic_key,'locale',v.locale,
   'source_id',v.source_id,'source_version',v.source_version,
   'source_hash',v.source_hash,'revision',v.publication_revision
 );
END;
$$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_topic_release_service_v21(
  text,text,text,text,text) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_topic_release_service_v21(
  text,text,text,text,text) TO service_role;

-- Updates are RESERVED to a reviewed future content-publication service.
-- This migration draft intentionally includes NO write/approval RPC, no seed
-- of approved content, no user/payment changes and no app route replacement.
