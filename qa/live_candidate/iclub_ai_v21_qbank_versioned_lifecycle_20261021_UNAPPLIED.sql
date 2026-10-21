-- iClub AI Global v2.1 | QA migration candidate 2026-10-21
-- Safe, version-aware source ledger / owner's *reported* expert acceptance.
-- No student data updates, no Math/Tour/Practice edits, no publication or grants.
-- Install as separate atomic migration before a controlled source release.
DO $baseline$
BEGIN
 IF to_regclass('private.iclub_ai_v21_qbank_content_history') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_qbank_owner_review_reports') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_qbank_owner_beta_releases') IS NULL
 OR to_regclass('private.iclub_ai_v21_qbank_signed_review_receipts') IS NULL
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
       WHERE source_version='qbank_exact_explanation_draft_v1'
         AND NOT published AND revoked AND NOT content_reviewed AND NOT rights_reviewed
         AND NOT locale_reviewed AND NOT academic_qa_passed AND approved_at IS NULL)<>210
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
       WHERE private.iclub_ai_v21_source_admitted_v1(src))<>111
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_beta_releases)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_signed_review_receipts)
 THEN RAISE EXCEPTION 'Version ledger baseline drift; refuse deployment'; END IF;
END $baseline$;

-- One snapshot per source/revision: history never overwrites student-facing
-- version evidence, even after the current source row is updated.
CREATE TABLE private.iclub_ai_v21_qbank_content_history (
 source_card_key text NOT NULL,
 surface_code text NOT NULL,
 subject_key text NOT NULL,
 context_key text NOT NULL,
 locale text NOT NULL CHECK(locale IN ('en','ru','uz')),
 source_version text NOT NULL,
 publication_revision integer NOT NULL CHECK(publication_revision>0),
 body_text text NOT NULL CHECK(length(btrim(body_text)) BETWEEN 30 AND 6000),
 content_hash text NOT NULL CHECK(content_hash ~ '^[a-f0-9]{64}$'),
 target_hash text NOT NULL CHECK(target_hash ~ '^[a-f0-9]{64}$'),
 initially_admitted boolean NOT NULL DEFAULT false,
 snapshot_basis text NOT NULL CHECK(snapshot_basis IN
   ('original_live_baseline_20261021','owner_governed_revision')),
 archive_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(source_card_key,publication_revision),
 UNIQUE(source_card_key,source_version,content_hash)
);
ALTER TABLE private.iclub_ai_v21_qbank_content_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_qbank_content_history
 FROM PUBLIC,anon,authenticated,service_role;
CREATE FUNCTION private.iclub_ai_v21_qbank_history_immutable_v1()
 RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $no$ BEGIN
 RAISE EXCEPTION 'iClub academic history is append-only';
END $no$;
CREATE TRIGGER iclub_ai_qbank_history_append_only
 BEFORE UPDATE OR DELETE ON private.iclub_ai_v21_qbank_content_history
 FOR EACH ROW EXECUTE FUNCTION private.iclub_ai_v21_qbank_history_immutable_v1();
REVOKE ALL ON FUNCTION private.iclub_ai_v21_qbank_history_immutable_v1()
 FROM PUBLIC,anon,authenticated,service_role;

INSERT INTO private.iclub_ai_v21_qbank_content_history(
 source_card_key,surface_code,subject_key,context_key,locale,source_version,
 publication_revision,body_text,content_hash,target_hash,
 initially_admitted,snapshot_basis)
SELECT a.source_card_key,a.surface_code,a.subject_key,a.context_key,a.locale,
 a.source_version,a.publication_revision,a.body_text,a.content_hash,a.target_hash,
 private.iclub_ai_v21_source_admitted_v1(a),
 'original_live_baseline_20261021'
FROM private.iclub_ai_v21_academic_sources a
WHERE a.content_hash=encode(extensions.digest(convert_to(a.body_text,'UTF8'),'sha256'),'hex');
DO $count$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history
    WHERE initially_admitted)<>111
 THEN RAISE EXCEPTION 'Incomplete baseline content-history snapshot'; END IF;
END $count$;

-- OWNER declaration is a factual report of this conversation, not a fabricated
-- individual Academic/Rights/Locale Ed25519 signature and not a release flag.
CREATE TABLE private.iclub_ai_v21_qbank_owner_review_reports (
 subject_key text NOT NULL,
 question_id bigint NOT NULL CHECK(question_id>0),
 context_key text NOT NULL,
 source_version text NOT NULL,
 target_hash text NOT NULL CHECK(target_hash ~ '^[a-f0-9]{64}$'),
 tri_locale_hashes jsonb NOT NULL,
 owner_report_status text NOT NULL
  CHECK(owner_report_status='expert_checks_reported_complete_by_owner'),
 independent_signatures_verified boolean NOT NULL DEFAULT false
  CHECK (independent_signatures_verified=false),
 released boolean NOT NULL DEFAULT false CHECK (released=false),
 reported_basis text NOT NULL DEFAULT 'owner_chat_attestation_20261021',
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(subject_key,question_id,source_version),
 CHECK(context_key='question_'||question_id::text),
 CHECK(jsonb_typeof(tri_locale_hashes)='object')
);
ALTER TABLE private.iclub_ai_v21_qbank_owner_review_reports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_qbank_owner_review_reports
 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER iclub_ai_qbank_owner_report_append_only
 BEFORE UPDATE OR DELETE ON private.iclub_ai_v21_qbank_owner_review_reports
 FOR EACH ROW EXECUTE FUNCTION private.iclub_ai_v21_qbank_history_immutable_v1();

WITH groups AS (
 SELECT subject_key,context_key,substring(context_key FROM '^question_([0-9]+)$')::bigint question_id,
   source_version,min(target_hash) target_hash,
   jsonb_object_agg(locale,content_hash) hashes,count(*) n,
   count(DISTINCT locale) distinct_locales,count(DISTINCT target_hash) targets
 FROM private.iclub_ai_v21_academic_sources
 WHERE surface_code='practice_error'
   AND source_version='qbank_exact_explanation_draft_v1'
   AND published=false AND revoked=true
 GROUP BY subject_key,context_key,source_version
)
INSERT INTO private.iclub_ai_v21_qbank_owner_review_reports
(subject_key,question_id,context_key,source_version,target_hash,tri_locale_hashes,
 owner_report_status)
SELECT subject_key,question_id,context_key,source_version,target_hash,hashes,
 'expert_checks_reported_complete_by_owner'
FROM groups
WHERE n=3 AND distinct_locales=3 AND targets=1
 AND hashes ?& array['en','ru','uz'];
DO $verify_reports$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_review_reports)<>70
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_review_reports
  WHERE independent_signatures_verified OR released)
 THEN RAISE EXCEPTION 'Owner review reports not exactly 70 closed question groups'; END IF;
END $verify_reports$;

-- Current academic_sources has ONE row per (surface,subject,context,locale).
-- This is deliberate: keep that stable key and preserve historical releases.
-- Unlike the earlier draft revision function, no source_card_key is rewritten,
-- so existing references and delivered evidence keep their original identity.
CREATE FUNCTION private.iclub_ai_v21_stage_qbank_revision_v2(
 p_subject_key text,p_question_id bigint,p_expected_version text,
 p_new_version text,p_locale_texts jsonb,p_editor_note text)
 RETURNS integer LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $update$
DECLARE v_context text:='question_'||p_question_id::text;
 v_lang text;v_new_body text;v_prev private.iclub_ai_v21_academic_sources%rowtype;
 v_total integer:=0;
BEGIN
 IF p_subject_key IS NULL OR p_subject_key !~ '^[a-z][a-z0-9_]{1,79}$'
 OR p_question_id IS NULL OR p_question_id<=0
 OR p_expected_version IS NULL OR p_new_version IS NULL
 OR p_expected_version=p_new_version
 OR p_new_version !~ '^curated_[a-z0-9_]{4,100}$'
 OR p_locale_texts IS NULL OR jsonb_typeof(p_locale_texts)<>'object'
 OR (SELECT count(*) FROM jsonb_object_keys(p_locale_texts))<>3
 OR (SELECT count(*) FROM jsonb_object_keys(p_locale_texts) x
     WHERE x IN ('en','ru','uz'))<>3
 OR p_editor_note IS NULL OR length(btrim(p_editor_note)) NOT BETWEEN 12 AND 500
 THEN RAISE EXCEPTION 'Invalid versioned revision request'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.questions q
   JOIN public.subjects s ON s.id=q.subject_id
   WHERE q.id=p_question_id AND q.is_active AND q.quality_status='published'
     AND s.subject_key=p_subject_key AND s.is_active)
 THEN RAISE EXCEPTION 'Question no longer eligible'; END IF;
 PERFORM 1 FROM private.iclub_ai_v21_academic_sources a
 WHERE a.surface_code='practice_error' AND a.subject_key=p_subject_key
 AND a.context_key=v_context ORDER BY a.locale FOR UPDATE;
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
 WHERE a.surface_code='practice_error' AND a.subject_key=p_subject_key
  AND a.context_key=v_context AND a.source_version=p_expected_version
  AND a.locale IN ('en','ru','uz'))<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
 WHERE a.surface_code='practice_error' AND a.subject_key=p_subject_key
   AND a.context_key=v_context)<>3
 THEN RAISE EXCEPTION 'Expected 3 exact existing locale versions'; END IF;

 FOREACH v_lang IN ARRAY ARRAY['en','ru','uz'] LOOP
  v_new_body:=btrim(p_locale_texts->>v_lang);
  IF jsonb_typeof(p_locale_texts->v_lang)<>'string'
    OR v_new_body IS NULL OR length(v_new_body) NOT BETWEEN 100 AND 6000
  THEN RAISE EXCEPTION 'Revision locale % invalid',v_lang; END IF;
  SELECT * INTO STRICT v_prev FROM private.iclub_ai_v21_academic_sources a
  WHERE a.surface_code='practice_error' AND a.subject_key=p_subject_key
   AND a.context_key=v_context AND a.locale=v_lang;

  IF v_prev.published OR NOT v_prev.revoked OR v_prev.content_reviewed
  OR v_prev.rights_reviewed OR v_prev.locale_reviewed OR v_prev.academic_qa_passed
  OR v_prev.approved_at IS NOT NULL
  OR private.iclub_ai_v21_source_admitted_v1(v_prev)
  OR v_prev.target_hash<>private.iclub_ai_v21_target_fingerprint_v1(
    'practice_error',p_question_id)
  OR v_prev.content_hash<>encode(extensions.digest(
    convert_to(v_prev.body_text,'UTF8'),'sha256'),'hex')
  -- Legacy originally released source keys must NEVER enter this pathway.
  OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_owner_beta_source_releases old
      WHERE old.source_card_key=v_prev.source_card_key)
  -- Previously owner-admitted qbank versions MUST be disabled before revision.
  OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_owner_beta_releases r
      WHERE r.source_card_key=v_prev.source_card_key
        AND r.source_version=v_prev.source_version AND r.enabled)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_content_history h
      WHERE h.source_card_key=v_prev.source_card_key
        AND h.publication_revision=v_prev.publication_revision
        AND h.source_version=v_prev.source_version
        AND h.content_hash=v_prev.content_hash AND h.body_text=v_prev.body_text)
  OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_qbank_content_history h
      WHERE h.source_card_key=v_prev.source_card_key
        AND h.source_version=p_new_version)
  THEN RAISE EXCEPTION 'Revision blocked by live authorization, drift or history'; END IF;
 END LOOP;
 FOREACH v_lang IN ARRAY ARRAY['en','ru','uz'] LOOP
  SELECT * INTO STRICT v_prev FROM private.iclub_ai_v21_academic_sources
   WHERE surface_code='practice_error' AND subject_key=p_subject_key
    AND context_key=v_context AND locale=v_lang;
  v_new_body:=btrim(p_locale_texts->>v_lang);
  UPDATE private.iclub_ai_v21_academic_sources a
  SET source_version=p_new_version,
   publication_revision=v_prev.publication_revision+1,
   body_text=v_new_body,
   content_hash=encode(extensions.digest(convert_to(v_new_body,'UTF8'),'sha256'),'hex'),
   published=false,revoked=true,approved_at=NULL,
   content_reviewed=false,rights_reviewed=false,locale_reviewed=false,
   academic_qa_passed=false
  WHERE a.source_card_key=v_prev.source_card_key
   AND a.surface_code='practice_error' AND a.subject_key=p_subject_key
   AND a.context_key=v_context AND a.locale=v_lang;
  INSERT INTO private.iclub_ai_v21_qbank_content_history(
   source_card_key,surface_code,subject_key,context_key,locale,source_version,
   publication_revision,body_text,content_hash,target_hash,
   initially_admitted,snapshot_basis)
  SELECT a.source_card_key,a.surface_code,a.subject_key,a.context_key,a.locale,
   a.source_version,a.publication_revision,a.body_text,a.content_hash,a.target_hash,
   false,'owner_governed_revision'
  FROM private.iclub_ai_v21_academic_sources a
  WHERE a.source_card_key=v_prev.source_card_key AND a.locale=v_lang;
  v_total:=v_total+1;
 END LOOP;
 IF v_total<>3 THEN RAISE EXCEPTION 'Atomic locale revision incomplete'; END IF;
 RETURN v_total;
END $update$;
REVOKE ALL ON FUNCTION private.iclub_ai_v21_stage_qbank_revision_v2(
 text,bigint,text,text,jsonb,text) FROM PUBLIC,anon,authenticated,service_role;

-- No new source releases, no verified signatures, no learner visibility.
DO $last$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
   WHERE private.iclub_ai_v21_source_admitted_v1(src))<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_review_reports)<>70
 THEN RAISE EXCEPTION 'Version ledger changed live admission unexpectedly'; END IF;
END $last$;
