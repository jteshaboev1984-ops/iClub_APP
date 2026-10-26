-- Already applied in Supabase 20261026174124. Private schema + source-linked AI review evidence.
-- Depends on separately ingested 9 versioned legacy corrections, which are PRIVATE, not Git files.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Legacy revision review table exists'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry not draft/off'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1(
 program_key text NOT NULL,
 version_key text NOT NULL,
 revision_key text NOT NULL,
 revision_version text NOT NULL,
 item_md5 text NOT NULL CHECK(item_md5 ~ '^[0-9a-f]{32}$'),
 source_legacy_question_id bigint NOT NULL,
 review_status text NOT NULL CHECK(review_status IN ('ai_pass','ai_hold')),
 reviewer_identity text NOT NULL DEFAULT 'OpenAI GPT-6 internal AI review — not a human examiner',
 reason text NOT NULL CHECK(length(btrim(reason))>=60),
 independent_human_review boolean NOT NULL DEFAULT false CHECK(independent_human_review=false),
 can_issue_formative boolean NOT NULL DEFAULT false CHECK(can_issue_formative=false),
 can_issue_exam boolean NOT NULL DEFAULT false CHECK(can_issue_exam=false),
 can_credit_mastery boolean NOT NULL DEFAULT false CHECK(can_credit_mastery=false),
 reviewed_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(program_key,version_key,revision_key,revision_version),
 FOREIGN KEY(program_key,version_key,revision_key,revision_version)
 REFERENCES private.iclub_exam_core_chemistry_p1_legacy_revisions_v1
 (program_key,version_key,revision_key,revision_version)
 ON UPDATE RESTRICT ON DELETE RESTRICT
);
ALTER TABLE private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1 IS
 'Internal AI review of private legacy practice revisions; no independent human review and no learner assessment authority.';
-- Closed evidence is inserted only after the private source revisions exist.
INSERT INTO private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1
(program_key,version_key,revision_key,revision_version,item_md5,source_legacy_question_id,review_status,reason)
SELECT program_key,version_key,revision_key,revision_version,item_md5,source_legacy_question_id,'ai_pass',
 'Internal GPT-6 academic/translation editorial assessment of prior Chemistry P1 legacy ID '
 ||source_legacy_question_id::text||'. Original source row and user history left unchanged; source snapshot '
 ||item_md5||'. No independent examiner signoff and no assessment authority.'
FROM (SELECT DISTINCT ON(source_legacy_question_id) *
 FROM private.iclub_exam_core_chemistry_p1_legacy_revisions_v1
 ORDER BY source_legacy_question_id,revision_version DESC) latest;
DO $post$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1)<>9
 THEN RAISE EXCEPTION 'Expected 9 internal AI revision assessments'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1','SELECT')
 THEN RAISE EXCEPTION 'Review table exposed'; END IF;
END $post$;