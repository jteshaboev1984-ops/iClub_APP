-- QA ONLY / UNAPPLIED: generic proof-of-origin for original iClub question-bank AI explanations.
-- This SQL must NOT be applied in production without separate owner authorization,
-- recorded rights + academic + EN/RU/UZ evidence, and scratch PostgreSQL QA.
-- Does not authorize any currently staged source: the new release table starts EMPTY.
-- No changes to questions, attempts, Practice pools, grades, Math Tutor, Edge or UI.
DO $guard$
BEGIN
 IF to_regclass('private.iclub_ai_v21_qbank_owner_beta_releases') IS NOT NULL
 OR md5(pg_get_functiondef(
   'private.iclub_ai_v21_source_admitted_v1(private.iclub_ai_v21_academic_sources)'::regprocedure))
   <> '3189bbb8332cc1604f381a6b2e984c81'
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
   WHERE source_version='qbank_exact_explanation_draft_v1'
     AND NOT published AND revoked AND NOT content_reviewed
     AND NOT rights_reviewed AND NOT locale_reviewed AND NOT academic_qa_passed
     AND approved_at IS NULL)<>210
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
   WHERE private.iclub_ai_v21_source_admitted_v1(src))<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_owner_beta_source_releases WHERE enabled)<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_deliveries)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND enabled AND NOT provider_enabled)<>1
 THEN RAISE EXCEPTION 'Qbank beta origin upgrade: live baseline differs, abort'; END IF;
END $guard$;

-- Attestations are not inferred from the existing question bank. Each row needs
-- separate explicit owner release, academic, rights and 3-language evidence.
-- Database constraints require references, but do NOT cryptographically verify reviewers.
-- Consequently no row is populated or approved by this technical migration.
CREATE TABLE private.iclub_ai_v21_qbank_owner_beta_releases(
 source_card_key text NOT NULL
   REFERENCES private.iclub_ai_v21_academic_sources(source_card_key),
 source_version text NOT NULL,
 content_hash text NOT NULL CHECK(content_hash ~ '^[a-f0-9]{64}$'),
 target_hash text NOT NULL CHECK(target_hash ~ '^[a-f0-9]{64}$'),
 subject_key text NOT NULL,
 question_id bigint NOT NULL CHECK(question_id>0),
 locale text NOT NULL CHECK(locale IN ('en','ru','uz')),
 origin_basis text NOT NULL DEFAULT 'original_iclub_question_bank'
   CHECK(origin_basis IN ('original_iclub_question_bank',
    'original_iclub_curated_revision')),
 original_source_hash text NOT NULL CHECK(original_source_hash ~ '^[a-f0-9]{64}$'),
 editorial_revision_ref text,
 CHECK (origin_basis<>'original_iclub_curated_revision'
    OR (editorial_revision_ref IS NOT NULL
     AND length(btrim(editorial_revision_ref)) BETWEEN 12 AND 512)),
 owner_release_ref text NOT NULL CHECK(length(btrim(owner_release_ref)) BETWEEN 12 AND 512),
 rights_evidence_ref text NOT NULL CHECK(length(btrim(rights_evidence_ref)) BETWEEN 12 AND 512),
 academic_evidence_ref text NOT NULL CHECK(length(btrim(academic_evidence_ref)) BETWEEN 12 AND 512),
 locale_evidence_ref text NOT NULL CHECK(length(btrim(locale_evidence_ref)) BETWEEN 12 AND 512),
 enabled boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 released_at timestamptz,
 CHECK (NOT enabled OR released_at IS NOT NULL),
 PRIMARY KEY(source_card_key,source_version,content_hash),
 UNIQUE(subject_key,question_id,locale,source_version)
);
ALTER TABLE private.iclub_ai_v21_qbank_owner_beta_releases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_qbank_owner_beta_releases
 FROM PUBLIC,anon,authenticated,service_role;

-- Separate signed editorial evidence ingest. NOLOGIN roles have no key,
-- may not be assumed by learner service_role, and are NOT provisioned live.
DO $roles$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles
    WHERE rolname='iclub_ai_v21_qbank_review_importer') THEN
  CREATE ROLE iclub_ai_v21_qbank_review_importer NOLOGIN;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles
    WHERE rolname='iclub_ai_v21_qbank_review_safety') THEN
  CREATE ROLE iclub_ai_v21_qbank_review_safety NOLOGIN;
 END IF;
END $roles$;
CREATE TABLE private.iclub_ai_v21_qbank_signed_review_receipts(
 source_card_key text NOT NULL
  REFERENCES private.iclub_ai_v21_academic_sources(source_card_key),
 subject_key text NOT NULL,
 question_id bigint NOT NULL CHECK(question_id>0),
 locale text NOT NULL CHECK(locale IN ('en','ru','uz')),
 source_version text NOT NULL,
 content_hash text NOT NULL CHECK(content_hash ~ '^[a-f0-9]{64}$'),
 target_hash text NOT NULL CHECK(target_hash ~ '^[a-f0-9]{64}$'),
 original_source_hash text NOT NULL CHECK(original_source_hash ~ '^[a-f0-9]{64}$'),
 p4_source_envelope_hash text NOT NULL CHECK(p4_source_envelope_hash ~ '^[a-f0-9]{64}$'),
 signed_manifest_hash text NOT NULL CHECK(signed_manifest_hash ~ '^[a-f0-9]{64}$'),
 ticket_id uuid NOT NULL UNIQUE,
 trusted_registry_revision text NOT NULL
  CHECK(length(btrim(trusted_registry_revision)) BETWEEN 5 AND 100),
 content_reviewer uuid NOT NULL,
 rights_reviewer uuid NOT NULL,
 technical_reviewer uuid NOT NULL,
 academic_reviewer uuid NOT NULL,
 language_reviewer uuid NOT NULL,
 evidence_record_ref text NOT NULL
  CHECK(length(btrim(evidence_record_ref)) BETWEEN 12 AND 512),
 verified_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 suspended_at timestamptz,
 PRIMARY KEY(source_card_key,source_version,content_hash),
 UNIQUE(subject_key,question_id,locale,source_version),
 CHECK (
  content_reviewer<>rights_reviewer AND
  content_reviewer<>technical_reviewer AND
  content_reviewer<>academic_reviewer AND
  content_reviewer<>language_reviewer AND
  rights_reviewer<>technical_reviewer AND
  rights_reviewer<>academic_reviewer AND
  rights_reviewer<>language_reviewer AND
  technical_reviewer<>academic_reviewer AND
  technical_reviewer<>language_reviewer AND
  academic_reviewer<>language_reviewer
 )
);
ALTER TABLE private.iclub_ai_v21_qbank_signed_review_receipts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_ai_v21_qbank_signed_review_receipts
 FROM PUBLIC,anon,authenticated,service_role;
GRANT USAGE ON SCHEMA private TO iclub_ai_v21_qbank_review_importer,
 iclub_ai_v21_qbank_review_safety;
GRANT INSERT ON private.iclub_ai_v21_qbank_signed_review_receipts
 TO iclub_ai_v21_qbank_review_importer;
GRANT UPDATE(suspended_at) ON private.iclub_ai_v21_qbank_signed_review_receipts
 TO iclub_ai_v21_qbank_review_safety;
CREATE POLICY iclub_qbank_signed_receipt_import_only
 ON private.iclub_ai_v21_qbank_signed_review_receipts
 FOR INSERT TO iclub_ai_v21_qbank_review_importer
 WITH CHECK(suspended_at IS NULL);
-- Safety can only disable a signed receipt, never clear the suspension.
GRANT SELECT ON private.iclub_ai_v21_qbank_signed_review_receipts
 TO iclub_ai_v21_qbank_review_safety;
CREATE POLICY iclub_qbank_signed_receipt_safety_read
 ON private.iclub_ai_v21_qbank_signed_review_receipts
 FOR SELECT TO iclub_ai_v21_qbank_review_safety USING(true);
CREATE POLICY iclub_qbank_signed_receipt_safety_disable
 ON private.iclub_ai_v21_qbank_signed_review_receipts
 FOR UPDATE TO iclub_ai_v21_qbank_review_safety
 USING(true) WITH CHECK(suspended_at IS NOT NULL);
-- PostgreSQL does NOT verify Ed25519: an independent credentialed importer
-- must verify all 5 roles using the exact existing P4 message format BEFORE
-- importing a receipt. No live import credentials and NO initial rows.
-- A receipt does not itself release content; an owner beta release is separate.

-- Independent curated revisions may differ from the stored bank explanation
-- only with a version-pinned original SHA, signed-review record references,
-- matching live question hash and a shared three-language editorial revision.
-- No question, grades or attempts change.
-- Pure reusable gate. Same old legacy pathway stays word-for-word identical.
-- No subject IDs or individual question IDs are embedded in routing.
CREATE OR REPLACE FUNCTION private.iclub_ai_v21_source_admitted_v1(
 src private.iclub_ai_v21_academic_sources
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $admit$
 SELECT coalesce(
  (src.published AND NOT src.revoked AND src.content_reviewed
   AND src.rights_reviewed AND src.locale_reviewed
   AND src.academic_qa_passed AND src.approved_at IS NOT NULL)
  OR
  (src.surface_code='practice_error' AND NOT src.published AND src.revoked
   AND NOT src.content_reviewed AND NOT src.rights_reviewed
   AND NOT src.locale_reviewed AND NOT src.academic_qa_passed
   AND src.approved_at IS NULL
   AND EXISTS(
    SELECT 1
    FROM private.iclub_ai_v21_owner_beta_source_releases beta
    JOIN private.practice_ai_source_cards legacy
      ON legacy.source_card_key=beta.source_card_key
    JOIN public.questions q ON q.id=legacy.question_id
    JOIN public.subjects subject ON subject.id=q.subject_id
    WHERE beta.source_card_key=src.source_card_key
     AND beta.enabled
     AND beta.release_basis='owner_authorized_closed_beta_20261020'
     AND beta.source_version=src.source_version
     AND beta.content_hash=src.content_hash
     AND beta.target_hash=src.target_hash
     AND legacy.source_version=src.source_version
     AND legacy.locale=src.locale
     AND legacy.subject_key=src.subject_key
     AND legacy.card_type='answer_explanation'
     AND legacy.approval_status='approved'
     AND legacy.rights_status='original_iclub'
     AND legacy.is_runtime_allowed
     AND legacy.approved_at IS NOT NULL
     AND legacy.content_hash=src.content_hash
     AND legacy.body_text=src.body_text
     AND subject.subject_key=src.subject_key
     AND subject.is_active AND q.is_active
     AND q.quality_status='published'
     AND src.context_key='question_'||q.id::text
   ))
  OR
  -- A separate owner-controlled path for new iClub original question-bank
  -- explanations; requires explicit recorded proof, NOT just "has explanation".
  (src.surface_code='practice_error' AND NOT src.published AND src.revoked
   AND NOT src.content_reviewed AND NOT src.rights_reviewed
   AND NOT src.locale_reviewed AND NOT src.academic_qa_passed
   AND src.approved_at IS NULL
   AND EXISTS(
    SELECT 1
    FROM private.iclub_ai_v21_qbank_owner_beta_releases beta
    JOIN private.iclub_ai_v21_qbank_signed_review_receipts proof
      ON proof.source_card_key=beta.source_card_key
     AND proof.source_version=beta.source_version
     AND proof.content_hash=beta.content_hash
    JOIN public.questions q ON q.id=beta.question_id
    JOIN public.subjects subject ON subject.id=q.subject_id
    WHERE beta.source_card_key=src.source_card_key
     AND beta.enabled AND beta.released_at IS NOT NULL
     AND proof.suspended_at IS NULL
     AND proof.subject_key=src.subject_key
     AND proof.question_id=q.id AND proof.locale=src.locale
     AND proof.source_version=src.source_version
     AND proof.content_hash=src.content_hash
     AND proof.target_hash=src.target_hash
     AND proof.original_source_hash=beta.original_source_hash
     AND proof.p4_source_envelope_hash=encode(extensions.digest(
      convert_to(src.body_text||E'\n'||'{}'::jsonb::text,'UTF8'),
      'sha256'),'hex')
     AND beta.origin_basis IN ('original_iclub_question_bank',
       'original_iclub_curated_revision')
     AND beta.original_source_hash=encode(extensions.digest(
      convert_to(btrim(CASE src.locale
       WHEN 'en' THEN q.explanation_en
       WHEN 'ru' THEN q.explanation_ru
       WHEN 'uz' THEN q.explanation_uz END),'UTF8'),'sha256'),'hex')
     AND beta.source_version=src.source_version
     AND beta.content_hash=src.content_hash
     AND beta.target_hash=src.target_hash
     AND beta.subject_key=src.subject_key
     AND beta.locale=src.locale
     AND subject.subject_key=src.subject_key AND subject.is_active
     AND q.is_active AND q.quality_status='published'
     AND src.context_key='question_'||q.id::text
     AND (
      (beta.origin_basis='original_iclub_question_bank'
       AND btrim(src.body_text)=btrim(CASE src.locale
         WHEN 'en' THEN q.explanation_en
         WHEN 'ru' THEN q.explanation_ru
         WHEN 'uz' THEN q.explanation_uz END))
      OR
      (beta.origin_basis='original_iclub_curated_revision'
       AND length(btrim(src.body_text)) BETWEEN 100 AND 6000
       AND length(btrim(beta.editorial_revision_ref)) BETWEEN 12 AND 512)
     )
     AND src.content_hash=encode(extensions.digest(
       convert_to(src.body_text,'UTF8'),'sha256'),'hex')
     AND src.target_hash=private.iclub_ai_v21_target_fingerprint_v1(
       'practice_error',q.id)
     -- No released AI answer outside active genuine Practice pools.
     AND EXISTS(
       SELECT 1 FROM public.practice_pool_questions pp
       JOIN public.practice_pools p ON p.id=pp.pool_id AND p.is_active
       WHERE pp.question_id=q.id AND pp.is_active AND p.subject_id=q.subject_id)
     -- Every release must have all three locales independently evidenced
     -- and version-aligned, not just a single accidentally admitted language.
     AND (
       SELECT count(DISTINCT sibling.locale)
       FROM private.iclub_ai_v21_qbank_owner_beta_releases sibling
       JOIN private.iclub_ai_v21_qbank_signed_review_receipts signed_sibling
         ON signed_sibling.source_card_key=sibling.source_card_key
        AND signed_sibling.source_version=sibling.source_version
        AND signed_sibling.content_hash=sibling.content_hash
       JOIN private.iclub_ai_v21_academic_sources other
         ON other.source_card_key=sibling.source_card_key
       WHERE sibling.question_id=beta.question_id
         AND sibling.subject_key=beta.subject_key AND sibling.enabled
         AND sibling.source_version=src.source_version
         AND sibling.target_hash=src.target_hash
         AND sibling.origin_basis=beta.origin_basis
         AND sibling.original_source_hash=encode(extensions.digest(
           convert_to(btrim(CASE sibling.locale
             WHEN 'en' THEN q.explanation_en
             WHEN 'ru' THEN q.explanation_ru
             WHEN 'uz' THEN q.explanation_uz END),'UTF8'),'sha256'),'hex')
         AND sibling.released_at IS NOT NULL
         AND signed_sibling.suspended_at IS NULL
         AND signed_sibling.subject_key=sibling.subject_key
         AND signed_sibling.question_id=q.id
         AND signed_sibling.locale=sibling.locale
         AND signed_sibling.source_version=sibling.source_version
         AND signed_sibling.content_hash=sibling.content_hash
         AND signed_sibling.target_hash=sibling.target_hash
         AND signed_sibling.original_source_hash=sibling.original_source_hash
         AND signed_sibling.locale IN ('en','ru','uz')
         AND sibling.locale IN ('en','ru','uz')
         AND other.surface_code='practice_error'
         AND other.subject_key=src.subject_key
         AND other.context_key=src.context_key
         AND other.locale=sibling.locale
         AND other.source_version=sibling.source_version
         AND other.content_hash=sibling.content_hash
         AND other.target_hash=sibling.target_hash
         AND other.revoked AND NOT other.published
         AND NOT other.content_reviewed AND NOT other.rights_reviewed
         AND NOT other.locale_reviewed AND NOT other.academic_qa_passed
         AND other.approved_at IS NULL
         AND other.content_hash=encode(extensions.digest(
           convert_to(other.body_text,'UTF8'),'sha256'),'hex')
         AND signed_sibling.p4_source_envelope_hash=encode(extensions.digest(
           convert_to(other.body_text||E'\n'||'{}'::jsonb::text,'UTF8'),
           'sha256'),'hex')
         AND (
           (sibling.origin_basis='original_iclub_question_bank'
             AND btrim(other.body_text)=btrim(CASE sibling.locale
               WHEN 'en' THEN q.explanation_en
               WHEN 'ru' THEN q.explanation_ru
               WHEN 'uz' THEN q.explanation_uz END))
           OR
           (sibling.origin_basis='original_iclub_curated_revision'
              AND sibling.editorial_revision_ref=beta.editorial_revision_ref
              AND length(btrim(sibling.editorial_revision_ref)) BETWEEN 12 AND 512
              AND length(btrim(other.body_text)) BETWEEN 100 AND 6000)
         )
     )=3
   ))
 ,false);
$admit$;
REVOKE ALL ON FUNCTION private.iclub_ai_v21_source_admitted_v1(
 private.iclub_ai_v21_academic_sources) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_ai_v21_source_admitted_v1(
 private.iclub_ai_v21_academic_sources) TO service_role;

-- The new pathway must remain entirely OFF until separately authorized.
DO $verify$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_beta_releases)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_signed_review_receipts)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources src
   WHERE private.iclub_ai_v21_source_admitted_v1(src))<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
   WHERE source_version='qbank_exact_explanation_draft_v1'
     AND NOT published AND revoked AND NOT content_reviewed
     AND NOT rights_reviewed AND NOT locale_reviewed
     AND NOT academic_qa_passed AND approved_at IS NULL)<>210
 THEN RAISE EXCEPTION 'Qbank release unexpectedly enabled; roll back transaction'; END IF;
END $verify$;
