-- iClub AI v2.1: additive, prepared General Help beta foundation.
-- Production-safe installation with all gates OFF; separate from Mathematics Exam Prep.
-- No modifications of existing learner records, v1 tariffs, memberships or AI functions.
DO $preflight$
BEGIN
 IF to_regclass('private.iclub_ai_v21_beta_control') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_beta_members') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_beta_help_sources') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_beta_usage') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_beta_deliveries') IS NOT NULL
 OR to_regprocedure('public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)') IS NOT NULL
 OR to_regprocedure('private.iclub_ai_has_active_protected_assessment_v1(uuid)') IS NULL
 OR to_regclass('public.practice_sessions_v4') IS NULL
 OR to_regprocedure('extensions.digest(bytea,text)') IS NULL
 THEN
   RAISE EXCEPTION 'iClub AI v2.1 beta preflight: unexpected objects or missing dependencies';
 END IF;
END $preflight$;

CREATE TABLE private.iclub_ai_v21_beta_control(
 singleton smallint PRIMARY KEY CHECK(singleton=1),
 beta_enabled boolean NOT NULL DEFAULT false,
 prepared_enabled boolean NOT NULL DEFAULT false,
 generation_enabled boolean NOT NULL DEFAULT false CHECK(generation_enabled=false),
 approved_release text NOT NULL DEFAULT 'none',
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (NOT prepared_enabled OR beta_enabled)
);
INSERT INTO private.iclub_ai_v21_beta_control(singleton) VALUES (1);

CREATE TABLE private.iclub_ai_v21_beta_members(
 user_id uuid PRIMARY KEY,
 enabled boolean NOT NULL DEFAULT false,
 consent_version text,
 consent_at timestamptz,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (NOT enabled OR
  (consent_version='global_ai_beta_v21' AND consent_at IS NOT NULL))
);
-- No auto-enrolment: the three existing Math-beta consents do not cover Global AI.

CREATE TABLE private.iclub_ai_v21_beta_help_sources(
 help_key text NOT NULL CHECK(help_key ~ '^[a-z][a-z0-9_]{2,59}$'),
 locale text NOT NULL CHECK(locale IN ('ru','uz','en')),
 message text NOT NULL CHECK(length(btrim(message)) BETWEEN 10 AND 1800),
 source_version text NOT NULL CHECK(length(source_version) BETWEEN 1 AND 80),
 source_hash text NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 publication_revision bigint NOT NULL DEFAULT 1 CHECK(publication_revision>0),
 content_reviewed boolean NOT NULL DEFAULT false,
 rights_reviewed boolean NOT NULL DEFAULT false,
 locale_reviewed boolean NOT NULL DEFAULT false,
 published boolean NOT NULL DEFAULT false,
 revoked boolean NOT NULL DEFAULT true,
 approved_at timestamptz,
 PRIMARY KEY(help_key,locale),
 CHECK (NOT published OR
  (content_reviewed AND rights_reviewed AND locale_reviewed AND
   NOT revoked AND approved_at IS NOT NULL))
);
-- Intentionally empty: product-copy approval is not source/right publication.

CREATE TABLE private.iclub_ai_v21_beta_usage(
 user_id uuid PRIMARY KEY,
 started_at timestamptz NOT NULL,
 committed_count smallint NOT NULL DEFAULT 0 CHECK(committed_count BETWEEN 0 AND 3),
 updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE private.iclub_ai_v21_beta_deliveries(
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 help_key text NOT NULL,
 locale text NOT NULL,
 source_version text NOT NULL,
 source_hash text NOT NULL,
 publication_revision bigint NOT NULL,
 delivered_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX iclub_ai_v21_beta_deliveries_user_idx
 ON private.iclub_ai_v21_beta_deliveries(user_id,delivered_at DESC);

DO $perms$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY[
 'iclub_ai_v21_beta_control','iclub_ai_v21_beta_members',
 'iclub_ai_v21_beta_help_sources','iclub_ai_v21_beta_usage',
 'iclub_ai_v21_beta_deliveries'
 ] LOOP
  EXECUTE format('REVOKE ALL ON TABLE private.%I FROM PUBLIC,anon,authenticated,service_role',t);
  EXECUTE format('ALTER TABLE private.%I ENABLE ROW LEVEL SECURITY',t);
 END LOOP;
END $perms$;

-- The only callable user-facing operation is service_role-only, after GoTrue
-- verifies a learner JWT. Atomic quota and approved response, no paid model.
CREATE FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(
 p_user_id uuid,p_request_id uuid,p_help_key text,p_locale text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $deliver$
DECLARE
 c private.iclub_ai_v21_beta_control%rowtype;
 m private.iclub_ai_v21_beta_members%rowtype;
 s private.iclub_ai_v21_beta_help_sources%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 old private.iclub_ai_v21_beta_deliveries%rowtype;
 v_now timestamptz := clock_timestamp();
BEGIN
 IF p_user_id IS NULL OR p_request_id IS NULL
 OR p_locale NOT IN ('ru','uz','en')
 OR p_help_key NOT IN (
  'support_help','catalog_help','ratings_help','home_next',
  'practice_rules','tour_rules','books_help','about_help',
  'notifications_help','community_help','certificates_help',
  'profile_meaning','video_help','recs_help','archive_help'
 ) THEN RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- The singleton row lock serializes read/grant/quota, including two workers.
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
  WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none' THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 SELECT * INTO m FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id;
 IF NOT FOUND OR NOT m.enabled OR m.consent_version<>'global_ai_beta_v21'
 OR m.consent_at IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 -- Protection is derived from server academic tables, never browser view hints.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (
  SELECT 1 FROM public.practice_sessions_v4
  WHERE user_id=p_user_id AND status='in_progress'
 ) THEN
  RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 SELECT * INTO s FROM private.iclub_ai_v21_beta_help_sources
  WHERE help_key=p_help_key AND locale=p_locale FOR SHARE;
 IF NOT FOUND OR NOT s.published OR s.revoked
 OR NOT s.content_reviewed OR NOT s.rights_reviewed
 OR NOT s.locale_reviewed OR s.approved_at IS NULL
 OR encode(extensions.digest(convert_to(s.message,'UTF8'),'sha256'),'hex')
    <>s.source_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- A same-ID retry is idempotent only for the SAME owner/key/version/revision;
 -- after revocation, neither new nor historical messages are returned.
 SELECT * INTO old FROM private.iclub_ai_v21_beta_deliveries
  WHERE request_id=p_request_id;
 IF FOUND THEN
  IF old.user_id=p_user_id AND old.help_key=p_help_key
  AND old.locale=p_locale AND old.source_hash=s.source_hash
  AND old.source_version=s.source_version
  AND old.publication_revision=s.publication_revision THEN
   RETURN jsonb_build_object('ok',true,'message',s.message,
     'mode','prepared','academic_state_changed',false,
     'provider_called',false,'replayed',true);
  END IF;
  RETURN jsonb_build_object('ok',false,'reason','request_conflict');
 END IF;

 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES (p_user_id,v_now,0)
 ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at <= v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
   SET started_at=v_now,committed_count=0,updated_at=v_now
   WHERE user_id=p_user_id;
  u.committed_count:=0;
 END IF;
 IF u.committed_count>=3 THEN
  RETURN jsonb_build_object('ok',false,'reason','usage_exhausted',
    'reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_deliveries(
  request_id,user_id,help_key,locale,source_version,source_hash,publication_revision
 ) VALUES (
  p_request_id,p_user_id,p_help_key,p_locale,
  s.source_version,s.source_hash,s.publication_revision
 );
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+1,updated_at=v_now
 WHERE user_id=p_user_id;

 RETURN jsonb_build_object('ok',true,'message',s.message,
  'mode','prepared','academic_state_changed',false,
  'provider_called',false,'replayed',false);
END $deliver$;

REVOKE ALL ON FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(
 uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(
 uuid,uuid,text,text) TO service_role;
