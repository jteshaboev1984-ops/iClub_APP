-- iClub AI v2.1 generic academic publication + one authoritative resolver.
-- Additive schema only; no Math Tutor/Practice/Tour/user data mutation.
-- Academic policy intentionally OFF until independent editorial publication.
DO $preflight$
BEGIN
 IF to_regclass('private.iclub_ai_v21_academic_policy') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_academic_sources') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_tour_archive_permissions') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_academic_deliveries') IS NOT NULL
 OR to_regprocedure('public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_beta_control') IS NULL
 OR to_regclass('private.iclub_ai_v21_beta_members') IS NULL
 OR to_regclass('private.iclub_ai_v21_beta_usage') IS NULL
 OR to_regclass('public.practice_sessions_v4') IS NULL
 OR to_regclass('public.practice_session_answers_v4') IS NULL
 OR to_regclass('public.practice_attempts') IS NULL
 OR to_regclass('public.lessons') IS NULL
 OR to_regclass('public.tour_attempts') IS NULL
 OR to_regclass('public.user_subjects') IS NULL
 OR to_regprocedure('private.iclub_ai_has_active_protected_assessment_v1(uuid)') IS NULL
 THEN RAISE EXCEPTION 'Generic academic resolver dependencies changed; installation stopped'; END IF;
END $preflight$;

CREATE TABLE private.iclub_ai_v21_academic_policy(
 singleton smallint PRIMARY KEY CHECK (singleton=1),
 enabled boolean NOT NULL DEFAULT false,
 provider_enabled boolean NOT NULL DEFAULT false CHECK(provider_enabled=false),
 publication_contract text NOT NULL DEFAULT 'academic_source_v1',
 updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.iclub_ai_v21_academic_policy(singleton) VALUES (1);

-- A universal release, independent of legacy approved source flags.
-- Editors supply one unique (surface,subject,context,locale) published row.
-- Future subject or content additions are data records, not code branches.
CREATE TABLE private.iclub_ai_v21_academic_sources(
 surface_code text NOT NULL
  CHECK (surface_code IN ('practice_error','lesson_topic','tour_archive')),
 subject_key text NOT NULL CHECK (subject_key ~ '^[a-z][a-z0-9_]{1,79}$'),
 context_key text NOT NULL CHECK (context_key ~ '^(question|lesson|tour)_[1-9][0-9]{0,17}(_archive)?$'),
 locale text NOT NULL CHECK(locale IN ('ru','uz','en')),
 source_card_key text NOT NULL UNIQUE,
 source_version text NOT NULL CHECK(length(source_version) BETWEEN 1 AND 120),
 publication_revision integer NOT NULL CHECK(publication_revision>0),
 body_text text NOT NULL CHECK(length(btrim(body_text)) BETWEEN 30 AND 6000),
 content_hash text NOT NULL CHECK(content_hash ~ '^[0-9a-f]{64}$'),
 content_reviewed boolean NOT NULL DEFAULT false,
 rights_reviewed boolean NOT NULL DEFAULT false,
 locale_reviewed boolean NOT NULL DEFAULT false,
 academic_qa_passed boolean NOT NULL DEFAULT false,
 published boolean NOT NULL DEFAULT false,
 revoked boolean NOT NULL DEFAULT true,
 approved_at timestamptz,
 PRIMARY KEY(surface_code,subject_key,context_key,locale),
 CHECK ((surface_code='practice_error' AND context_key ~ '^question_[1-9][0-9]*$')
     OR (surface_code='lesson_topic' AND context_key ~ '^lesson_[1-9][0-9]*$')
     OR (surface_code='tour_archive' AND context_key ~ '^tour_[1-9][0-9]*_archive$')),
 CHECK (NOT published OR (NOT revoked AND content_reviewed AND rights_reviewed
       AND locale_reviewed AND academic_qa_passed AND approved_at IS NOT NULL))
);

-- Tour archive release is independently operated; a completed attempt alone
-- can never reveal a live competition's answers.
CREATE TABLE private.iclub_ai_v21_tour_archive_permissions(
 tour_id bigint PRIMARY KEY REFERENCES public.tours(id),
 available_at timestamptz NOT NULL,
 approved boolean NOT NULL DEFAULT false,
 revoked boolean NOT NULL DEFAULT true,
 approved_at timestamptz,
 CHECK(NOT approved OR (NOT revoked AND approved_at IS NOT NULL))
);

CREATE TABLE private.iclub_ai_v21_academic_deliveries(
 request_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 surface_code text NOT NULL,
 subject_key text NOT NULL,
 context_key text NOT NULL,
 locale text NOT NULL,
 source_card_key text NOT NULL,
 source_version text NOT NULL,
 content_hash text NOT NULL,
 publication_revision integer NOT NULL,
 delivered_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX iclub_ai_v21_academic_deliveries_user
 ON private.iclub_ai_v21_academic_deliveries(user_id,delivered_at DESC);
CREATE INDEX iclub_ai_v21_academic_sources_published
 ON private.iclub_ai_v21_academic_sources(surface_code,subject_key,context_key,locale)
 WHERE published AND NOT revoked;

DO $permissions$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY[
  'iclub_ai_v21_academic_policy','iclub_ai_v21_academic_sources',
  'iclub_ai_v21_tour_archive_permissions','iclub_ai_v21_academic_deliveries'
 ] LOOP
  EXECUTE format('REVOKE ALL ON TABLE private.%I FROM PUBLIC,anon,authenticated,service_role',t);
  EXECUTE format('ALTER TABLE private.%I ENABLE ROW LEVEL SECURITY',t);
 END LOOP;
END $permissions$;

-- One content-agnostic service function for all current and future subjects.
-- The Edge verifies GoTrue JWT; this function is service_role-only.
-- p_record_id: legacy finalized Practice attempt OR lesson OR Tour attempt.
-- p_question_id: exact Practice question only. All selectors remain untrusted.
CREATE FUNCTION public.deliver_iclub_ai_v21_academic_service(
 p_user_id uuid,p_request_id uuid,p_surface text,p_record_id bigint,
 p_question_id bigint,p_locale text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $academic$
DECLARE
 c private.iclub_ai_v21_beta_control%rowtype;
 m private.iclub_ai_v21_beta_members%rowtype;
 pol private.iclub_ai_v21_academic_policy%rowtype;
 source private.iclub_ai_v21_academic_sources%rowtype;
 old private.iclub_ai_v21_academic_deliveries%rowtype;
 usage private.iclub_ai_v21_beta_usage%rowtype;
 v_subject text;
 v_key text;
 v_now timestamptz:=clock_timestamp();
 v_tour bigint;
BEGIN
 IF p_user_id IS NULL OR p_request_id IS NULL
 OR p_surface NOT IN ('practice_error','lesson_topic','tour_archive')
 OR p_locale NOT IN ('ru','uz','en')
 OR p_record_id IS NULL OR p_record_id<=0
 OR (p_surface='practice_error' AND (p_question_id IS NULL OR p_question_id<=0))
 OR (p_surface<>'practice_error' AND p_question_id IS NOT NULL) THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;

 -- Serialize beta gate, publication, quota and delivery into one transaction.
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control WHERE singleton=1 FOR UPDATE;
 SELECT * INTO pol FROM private.iclub_ai_v21_academic_policy WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT coalesce(c.beta_enabled,false)
 OR NOT coalesce(c.prepared_enabled,false) OR coalesce(c.generation_enabled,true)
 OR NOT coalesce(pol.enabled,false) OR coalesce(pol.provider_enabled,true)
 THEN RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;
 SELECT * INTO m FROM private.iclub_ai_v21_beta_members WHERE user_id=p_user_id;
 IF NOT FOUND OR NOT m.enabled OR m.consent_version<>'global_ai_beta_v21'
 OR m.consent_at IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS(SELECT 1 FROM public.practice_sessions_v4 ps
           WHERE ps.user_id=p_user_id AND ps.status='in_progress')
 THEN RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 IF p_surface='practice_error' THEN
   -- The app provides LEGACY attempt ID from its real Practice review DOM.
   -- The source authority is the matching finalized V4 server session,
   -- including a verified incorrect AND actually answered question.
   SELECT subj.subject_key INTO v_subject
   FROM public.practice_attempts pa
   JOIN public.practice_sessions_v4 ps ON ps.legacy_attempt_id=pa.id
   JOIN public.practice_session_answers_v4 answer
     ON answer.session_id=ps.id AND answer.question_id=p_question_id
   JOIN public.subjects subj ON subj.id=ps.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   WHERE pa.id=p_record_id AND pa.user_id=p_user_id
     AND ps.user_id=p_user_id AND pa.subject_id=ps.subject_id
     AND ps.status='finalized' AND ps.finalized_at IS NOT NULL
     AND answer.answered_at IS NOT NULL AND answer.is_correct IS FALSE
     AND p_question_id=ANY(ps.question_ids) AND subj.is_active
   LIMIT 1;
   v_key:='question_'||p_question_id::text;
 ELSIF p_surface='lesson_topic' THEN
   SELECT subj.subject_key INTO v_subject
   FROM public.lessons lesson
   JOIN public.subjects subj ON subj.id=lesson.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   WHERE lesson.id=p_record_id AND subj.is_active LIMIT 1;
   v_key:='lesson_'||p_record_id::text;
 ELSIF p_surface='tour_archive' THEN
   SELECT subj.subject_key,tour.id INTO v_subject,v_tour
   FROM public.tour_attempts a
   JOIN public.tours tour ON tour.id=a.tour_id
   JOIN public.subjects subj ON subj.id=tour.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   JOIN private.iclub_ai_v21_tour_archive_permissions access
     ON access.tour_id=tour.id
   WHERE a.id=p_record_id AND a.user_id=p_user_id
     AND a.status IN ('submitted','time_expired')
     AND subj.is_active AND access.approved AND NOT access.revoked
     AND access.approved_at IS NOT NULL AND access.available_at<=v_now
     AND tour.end_date < (v_now AT TIME ZONE 'Asia/Tashkent')::date
   LIMIT 1;
   v_key:='tour_'||v_tour::text||'_archive';
 END IF;
 IF v_subject IS NULL OR v_key IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','context_not_authorized'); END IF;

 SELECT * INTO source FROM private.iclub_ai_v21_academic_sources s
 WHERE s.surface_code=p_surface AND s.subject_key=v_subject
 AND s.context_key=v_key AND s.locale=p_locale FOR SHARE;
 IF NOT FOUND OR NOT source.published OR source.revoked
 OR NOT source.content_reviewed OR NOT source.rights_reviewed
 OR NOT source.locale_reviewed OR NOT source.academic_qa_passed
 OR source.approved_at IS NULL
 OR encode(extensions.digest(convert_to(source.body_text,'UTF8'),'sha256'),'hex')
   <>source.content_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 SELECT * INTO old FROM private.iclub_ai_v21_academic_deliveries
  WHERE request_id=p_request_id;
 IF FOUND THEN
  IF old.user_id=p_user_id AND old.surface_code=p_surface
  AND old.subject_key=v_subject AND old.context_key=v_key
  AND old.locale=p_locale AND old.source_card_key=source.source_card_key
  AND old.content_hash=source.content_hash
  AND old.source_version=source.source_version
  AND old.publication_revision=source.publication_revision THEN
   RETURN jsonb_build_object('ok',true,'message',source.body_text,
    'mode','prepared','provider_called',false,
    'academic_state_changed',false,'replayed',true);
  END IF;
  RETURN jsonb_build_object('ok',false,'reason','request_conflict'); END IF;
 -- Prevent cross-route request-id reuse against existing Help quota claims.
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_deliveries
            WHERE request_id=p_request_id) THEN
  RETURN jsonb_build_object('ok',false,'reason','request_conflict'); END IF;

 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES(p_user_id,v_now,0) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO usage FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF usage.started_at<=v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
  SET started_at=v_now,committed_count=0,updated_at=v_now WHERE user_id=p_user_id;
  usage.committed_count:=0;
 END IF;
 IF usage.committed_count>=3 THEN
  RETURN jsonb_build_object('ok',false,'reason','usage_exhausted',
    'reset_at',usage.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_academic_deliveries(
 request_id,user_id,surface_code,subject_key,context_key,locale,
 source_card_key,source_version,content_hash,publication_revision
 ) VALUES(p_request_id,p_user_id,p_surface,v_subject,v_key,p_locale,
 source.source_card_key,source.source_version,source.content_hash,
 source.publication_revision);
 UPDATE private.iclub_ai_v21_beta_usage SET committed_count=committed_count+1,
 updated_at=v_now WHERE user_id=p_user_id;
 RETURN jsonb_build_object('ok',true,'message',source.body_text,
  'mode','prepared','provider_called',false,
  'academic_state_changed',false,'replayed',false);
END $academic$;
REVOKE ALL ON FUNCTION public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)
 TO service_role;
