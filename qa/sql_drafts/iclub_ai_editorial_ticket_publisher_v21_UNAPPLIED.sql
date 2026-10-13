-- iClub AI v2.1 P4 - controlled release transition, SCRATCH-ONLY / UNAPPLIED.
-- No academic material is authored, corrected, approved or imported here.
-- Requires independent, out-of-band editorial signoff tickets.
-- NEVER grant publication to the learner-facing Supabase service_role.
DO $scratch_guard$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
 AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
 AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
 AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
   RAISE EXCEPTION 'BLOCKED: editorial publisher only in local scratch';
 END IF;
END $scratch_guard$;
CREATE SCHEMA IF NOT EXISTS private;
-- Dedicated non-login publication executor, deliberately NOT a member of
-- service_role. Real credential provisioning requires a separate security review.
DO $role$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='iclub_ai_v21_editorial_publisher') THEN
  CREATE ROLE iclub_ai_v21_editorial_publisher NOLOGIN;
 END IF;
END $role$;
CREATE TABLE private.iclub_ai_v21_editorial_tickets(
 ticket_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 surface_code text NOT NULL,
 subject_key text NOT NULL,
 feature_code text NOT NULL,
 topic_key text NOT NULL,
 locale text NOT NULL CHECK(locale IN ('ru','uz','en')),
 source_id text NOT NULL,
 source_version text NOT NULL,
 source_hash text NOT NULL CHECK(source_hash ~ '^[0-9a-f]{64}$'),
 action text NOT NULL CHECK(action IN ('publish','revoke')),
 qa_evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
 reason text NOT NULL DEFAULT '',
 created_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL DEFAULT (now()+interval '24 hours'),
 used_at timestamptz,
 CHECK(expires_at>created_at),
 CHECK(jsonb_typeof(qa_evidence)='object'),
 CHECK(length(reason)<=500),
 CHECK(length(surface_code) BETWEEN 1 AND 90),
 CHECK(length(subject_key) BETWEEN 1 AND 90),
 CHECK(length(feature_code) BETWEEN 1 AND 90),
 CHECK(length(topic_key) BETWEEN 1 AND 160)
);
-- Ticket insert / signoffs are OFFLINE governance ingestion responsibility.
-- Public/learner/servicerole must NOT be able to mint their own approvals.
CREATE TABLE private.iclub_ai_v21_ticket_signoffs(
 ticket_id uuid NOT NULL REFERENCES private.iclub_ai_v21_editorial_tickets(ticket_id),
 reviewer_id uuid NOT NULL,
 review_domain text NOT NULL CHECK(review_domain IN
  ('content','rights','technical','safety')),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(ticket_id,review_domain),
 UNIQUE(ticket_id,reviewer_id)
);
REVOKE ALL ON private.iclub_ai_v21_editorial_tickets FROM public,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_ai_v21_ticket_signoffs FROM public,anon,authenticated,service_role;

-- Independently authenticated (offline) Ed25519 evidence importer; NO live keys.
DO $role$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='iclub_ai_v21_evidence_importer') THEN
  CREATE ROLE iclub_ai_v21_evidence_importer NOLOGIN;
 END IF;
END $role$;
CREATE TABLE private.iclub_ai_v21_verified_review_attestations(
 ticket_id uuid PRIMARY KEY REFERENCES private.iclub_ai_v21_editorial_tickets(ticket_id),
 action text NOT NULL CHECK(action IN('publish','revoke')),
 surface_code text NOT NULL,subject_key text NOT NULL,feature_code text NOT NULL,
 topic_key text NOT NULL,locale text NOT NULL,source_id text NOT NULL,
 source_version text NOT NULL,source_hash text NOT NULL CHECK(source_hash~'^[a-f0-9]{64}$'),
 expected_revision bigint NOT NULL CHECK(expected_revision>=0),
 qa_evidence jsonb NOT NULL CHECK(jsonb_typeof(qa_evidence)='object'),
 reason text NOT NULL DEFAULT '',
 reviewers jsonb NOT NULL CHECK(jsonb_typeof(reviewers)='object'),
 manifest_sha256 text NOT NULL CHECK(manifest_sha256~'^[a-f0-9]{64}$'),
 trust_registry_revision text NOT NULL,
 verified_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL DEFAULT (now()+interval '15 minutes'),
 CHECK(expires_at>verified_at AND expires_at<=verified_at+interval '24 hours')
);
REVOKE ALL ON TABLE private.iclub_ai_v21_verified_review_attestations
 FROM PUBLIC,anon,authenticated,service_role,iclub_ai_v21_editorial_publisher;
GRANT INSERT ON TABLE private.iclub_ai_v21_verified_review_attestations
 TO iclub_ai_v21_evidence_importer;
-- The 8 independent gate results are recorded and signed in an OUT-OF-BAND
-- editorial review, not guessed from source presence/card count.
-- This helper is called only after all three independent signoff rows exist.
CREATE OR REPLACE FUNCTION public.publish_iclub_ai_v21_ticket(
 p_ticket_id uuid,p_expected_revision bigint
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 SET search_path='' AS $publish$
DECLARE
 t private.iclub_ai_v21_editorial_tickets%rowtype;
 s private.iclub_ai_v21_editorial_source_versions%rowtype;
 r private.iclub_ai_topic_release_v21%rowtype;
 n bigint;
 required_gates text[]:=ARRAY[
  'content_approved','rights_approved','source_version_verified',
  'correctness_passed','negative_tests_passed','exam_security_passed',
  'locale_verified','accessibility_passed'];
 k text;
BEGIN
 IF p_ticket_id IS NULL OR p_expected_revision IS NULL
 OR p_expected_revision<0 THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;
 SELECT * INTO t FROM private.iclub_ai_v21_editorial_tickets
 WHERE ticket_id=p_ticket_id FOR UPDATE;
 IF NOT FOUND OR t.action<>'publish' OR t.used_at IS NOT NULL
 OR t.expires_at<=now() THEN
  RETURN jsonb_build_object('ok',false,'reason','ticket_unavailable');
 END IF;
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_ticket_signoffs x
  WHERE x.ticket_id=t.ticket_id AND x.review_domain='content'
 ) OR NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_ticket_signoffs x
  WHERE x.ticket_id=t.ticket_id AND x.review_domain='rights'
 ) OR NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_ticket_signoffs x
  WHERE x.ticket_id=t.ticket_id AND x.review_domain='technical'
 ) THEN
  RETURN jsonb_build_object('ok',false,'reason','editorial_signoffs_missing');
 END IF;
 FOREACH k IN ARRAY required_gates LOOP
  IF t.qa_evidence->k IS DISTINCT FROM 'true'::jsonb THEN
   RETURN jsonb_build_object('ok',false,'reason','editorial_gate_missing');
  END IF;
 END LOOP;
 -- Serialize all versions/locales of the SAME scoped topic. Lock first, then
 -- lock exact content+release, preventing concurrent "last writer wins".
 PERFORM pg_advisory_xact_lock(hashtextextended(
  t.surface_code||'/'||t.subject_key||'/'||t.feature_code||'/'||
  t.topic_key||'/'||t.locale,4127));
 SELECT * INTO s FROM private.iclub_ai_v21_editorial_source_versions
 WHERE surface_code=t.surface_code AND subject_key=t.subject_key
 AND feature_code=t.feature_code AND topic_key=t.topic_key AND locale=t.locale
 AND source_id=t.source_id AND source_version=t.source_version
 FOR UPDATE;
 IF NOT FOUND OR s.record_state NOT IN ('draft','published')
 OR s.source_conflict IS DISTINCT FROM false
 OR s.source_hash IS DISTINCT FROM t.source_hash
 OR s.source_hash IS DISTINCT FROM encode(sha256(convert_to(
  s.source_text||E'\n'||s.prepared_variants::text,'UTF8')),'hex')
 THEN
  RETURN jsonb_build_object('ok',false,'reason','source_identity_unverified');
 END IF;
 -- Never approve totally empty material, nor re-enable quarantined source.
 IF length(btrim(s.source_text))=0 AND s.prepared_variants='{}'::jsonb THEN
  RETURN jsonb_build_object('ok',false,'reason','empty_source');
 END IF;
 SELECT * INTO r FROM private.iclub_ai_topic_release_v21
 WHERE surface_code=t.surface_code AND subject_key=t.subject_key
 AND feature_code=t.feature_code AND topic_key=t.topic_key AND locale=t.locale
 FOR UPDATE;
 IF FOUND THEN
  IF r.publication_revision IS DISTINCT FROM p_expected_revision
   OR r.publication_state='approved'
   OR r.publication_state='suspended'
  THEN
   RETURN jsonb_build_object('ok',false,'reason','revision_or_state_conflict');
  END IF;
  n:=r.publication_revision+1;
 ELSE
  IF p_expected_revision<>0 THEN
   RETURN jsonb_build_object('ok',false,'reason','revision_or_state_conflict');
  END IF;
  n:=1;
 END IF;
 -- A reviewer UUID is not an identity proof. The imported attestation must
 -- be independently Ed25519 verified and exactly match this one ticket.
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_verified_review_attestations a
  WHERE a.ticket_id=t.ticket_id AND a.action='publish'
   AND a.surface_code=t.surface_code AND a.subject_key=t.subject_key
   AND a.feature_code=t.feature_code AND a.topic_key=t.topic_key
   AND a.locale=t.locale AND a.source_id=t.source_id
   AND a.source_version=t.source_version AND a.source_hash=t.source_hash
   AND a.expected_revision=p_expected_revision AND a.qa_evidence=t.qa_evidence
   AND a.reason=t.reason AND a.verified_at<=now() AND a.expires_at>now()
   AND a.reviewers->>'content'=(
    SELECT reviewer_id::text FROM private.iclub_ai_v21_ticket_signoffs
     WHERE ticket_id=t.ticket_id AND review_domain='content')
   AND a.reviewers->>'rights'=(
    SELECT reviewer_id::text FROM private.iclub_ai_v21_ticket_signoffs
     WHERE ticket_id=t.ticket_id AND review_domain='rights')
   AND a.reviewers->>'technical'=(
    SELECT reviewer_id::text FROM private.iclub_ai_v21_ticket_signoffs
     WHERE ticket_id=t.ticket_id AND review_domain='technical')
   AND (SELECT count(*) FROM jsonb_object_keys(a.reviewers))=3
 ) THEN RETURN jsonb_build_object('ok',false,'reason','editorial_attestation_missing');
 END IF;
 -- A signed review cannot itself override runtime OFF, beta/cohort or
 -- provider constraints: this toggles only the editorial *topic* row.
 UPDATE private.iclub_ai_v21_editorial_source_versions SET
  record_state='published',rights_approved=true,qa_passed=true,
  integrity_verified=true,runtime_allowed=true,updated_at=now()
 WHERE surface_code=t.surface_code AND subject_key=t.subject_key
 AND feature_code=t.feature_code AND topic_key=t.topic_key AND locale=t.locale
 AND source_id=t.source_id AND source_version=t.source_version;
 INSERT INTO private.iclub_ai_topic_release_v21(
  surface_code,subject_key,feature_code,topic_key,locale,
  source_id,source_version,source_hash,
  content_approved,rights_approved,source_version_verified,
  correctness_passed,negative_tests_passed,exam_security_passed,
  locale_verified,accessibility_passed,source_conflict,
  publication_state,feature_enabled,publication_revision,approved_at,approved_by
 ) VALUES(
  t.surface_code,t.subject_key,t.feature_code,t.topic_key,t.locale,
  t.source_id,t.source_version,t.source_hash,
  true,true,true,true,true,true,true,true,false,
  'approved',true,n,now(),
  (SELECT x.reviewer_id FROM private.iclub_ai_v21_ticket_signoffs x
    WHERE x.ticket_id=t.ticket_id AND x.review_domain='content')
 ) ON CONFLICT(surface_code,subject_key,feature_code,topic_key,locale)
 DO UPDATE SET
  source_id=excluded.source_id,source_version=excluded.source_version,
  source_hash=excluded.source_hash,content_approved=true,rights_approved=true,
  source_version_verified=true,correctness_passed=true,
  negative_tests_passed=true,exam_security_passed=true,
  locale_verified=true,accessibility_passed=true,source_conflict=false,
  publication_state='approved',feature_enabled=true,
  publication_revision=excluded.publication_revision,
  approved_at=excluded.approved_at,approved_by=excluded.approved_by,
  updated_at=now();
 UPDATE private.iclub_ai_v21_editorial_tickets SET used_at=now()
 WHERE ticket_id=p_ticket_id;
 RETURN jsonb_build_object('ok',true,'status','published',
  'publication_revision',n);
END;
$publish$;

-- Emergency editorial suspension: ticket must already be staged by an
-- independent safety reviewer; no source text/answer/student state mutation.
CREATE OR REPLACE FUNCTION public.revoke_iclub_ai_v21_ticket(
 p_ticket_id uuid,p_expected_revision bigint
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 SET search_path='' AS $revoke$
DECLARE
 t private.iclub_ai_v21_editorial_tickets%rowtype;
 r private.iclub_ai_topic_release_v21%rowtype;
 n bigint;
BEGIN
 IF p_ticket_id IS NULL OR p_expected_revision IS NULL
 OR p_expected_revision<=0 THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;
 SELECT * INTO t FROM private.iclub_ai_v21_editorial_tickets
 WHERE ticket_id=p_ticket_id FOR UPDATE;
 IF NOT FOUND OR t.action<>'revoke' OR t.used_at IS NOT NULL
 OR t.expires_at<=now() OR length(btrim(t.reason))<8 OR
 NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_ticket_signoffs x
  WHERE x.ticket_id=t.ticket_id AND x.review_domain='safety')
 THEN
  RETURN jsonb_build_object('ok',false,'reason','revocation_ticket_unavailable');
 END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(
  t.surface_code||'/'||t.subject_key||'/'||t.feature_code||'/'||
  t.topic_key||'/'||t.locale,4127));
 SELECT * INTO r FROM private.iclub_ai_topic_release_v21
 WHERE surface_code=t.surface_code AND subject_key=t.subject_key
 AND feature_code=t.feature_code AND topic_key=t.topic_key AND locale=t.locale
 FOR UPDATE;
 IF NOT FOUND OR r.publication_revision<>p_expected_revision
 OR r.publication_state<>'approved'
 OR r.source_id<>t.source_id OR r.source_version<>t.source_version
 OR r.source_hash<>t.source_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','revision_or_state_conflict');
 END IF;
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_verified_review_attestations a
  WHERE a.ticket_id=t.ticket_id AND a.action='revoke'
   AND a.surface_code=t.surface_code AND a.subject_key=t.subject_key
   AND a.feature_code=t.feature_code AND a.topic_key=t.topic_key
   AND a.locale=t.locale AND a.source_id=t.source_id
   AND a.source_version=t.source_version AND a.source_hash=t.source_hash
   AND a.expected_revision=p_expected_revision AND a.qa_evidence=t.qa_evidence
   AND a.reason=t.reason AND a.verified_at<=now() AND a.expires_at>now()
   AND a.reviewers->>'safety'=(
    SELECT reviewer_id::text FROM private.iclub_ai_v21_ticket_signoffs
     WHERE ticket_id=t.ticket_id AND review_domain='safety')
   AND (SELECT count(*) FROM jsonb_object_keys(a.reviewers))=1
 ) THEN RETURN jsonb_build_object('ok',false,'reason','safety_attestation_missing');
 END IF;
 n:=r.publication_revision+1;
 UPDATE private.iclub_ai_topic_release_v21
 SET publication_state='suspended',feature_enabled=false,
  publication_revision=n,updated_at=now()
 WHERE surface_code=t.surface_code AND subject_key=t.subject_key
 AND feature_code=t.feature_code AND topic_key=t.topic_key AND locale=t.locale;
 UPDATE private.iclub_ai_v21_editorial_source_versions
 SET record_state='suspended',runtime_allowed=false,updated_at=now()
 WHERE surface_code=t.surface_code AND subject_key=t.subject_key
 AND feature_code=t.feature_code AND topic_key=t.topic_key AND locale=t.locale
 AND source_id=t.source_id AND source_version=t.source_version;
 UPDATE private.iclub_ai_v21_editorial_tickets SET used_at=now()
 WHERE ticket_id=p_ticket_id;
 RETURN jsonb_build_object('ok',true,'status','suspended',
  'publication_revision',n);
END;
$revoke$;

REVOKE ALL ON FUNCTION public.publish_iclub_ai_v21_ticket(uuid,bigint)
 FROM public,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION public.revoke_iclub_ai_v21_ticket(uuid,bigint)
 FROM public,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.publish_iclub_ai_v21_ticket(uuid,bigint)
 TO iclub_ai_v21_editorial_publisher;
GRANT EXECUTE ON FUNCTION public.revoke_iclub_ai_v21_ticket(uuid,bigint)
 TO iclub_ai_v21_editorial_publisher;

-- No API to WRITE review tickets. A future offline/governance ingestion is
-- independently approved and credentials isolated from learner-serving Edge.
-- Never integrate either publisher function into qa/edge_v21/index.ts.
