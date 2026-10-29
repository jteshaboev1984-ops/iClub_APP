-- J23 private authored check candidates, distinct from immutable source + recovery layers.
-- No student access or publication. Academic owner must review independently.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $guard$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='private' AND table_name='iclub_exam_chemistry_j23_authored_checks_v1')
 THEN RAISE EXCEPTION 'J23 authored checks already installed; no second installation'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
     WHERE candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v2')<>273
 THEN RAISE EXCEPTION 'J23 recovered source changed; no installation'; END IF;
END $guard$;
CREATE TABLE private.iclub_exam_chemistry_j23_authored_checks_v1 (
 edition_key text NOT NULL,
 source_candidate_version text NOT NULL,
 skill_key text NOT NULL,
 locale text NOT NULL CHECK(locale IN('en','ru','uz')),
 question_text text NOT NULL CHECK(length(btrim(question_text))>=12),
 answer_text text NOT NULL CHECK(length(btrim(answer_text))>=8),
 base_content_hash text NOT NULL CHECK(base_content_hash ~ '^sha256:[a-f0-9]{64}$'),
 question_source text NOT NULL CHECK(question_source IN('new_question','existing_question')),
 authored_sha256 text NOT NULL CHECK(authored_sha256 ~ '^sha256:[a-f0-9]{64}$'),
 review_status text NOT NULL DEFAULT 'draft_pending_independent_science_and_trilingual_signoff'
  CHECK(review_status='draft_pending_independent_science_and_trilingual_signoff'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(edition_key,skill_key,locale),
 FOREIGN KEY(source_candidate_version,skill_key,locale)
 REFERENCES private.iclub_exam_chemistry_j23_as_authoring_recovery_v1(candidate_version,skill_key,locale)
 ON DELETE RESTRICT
);
ALTER TABLE private.iclub_exam_chemistry_j23_authored_checks_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j23_authored_checks_v1 FROM PUBLIC, anon, authenticated;
COMMIT;
