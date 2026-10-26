-- Applied to private Supabase 20261026132634.
-- Chemistry P1 internal AI-only review provenance. DOES NOT certify independent human QA.
-- No private exam question body, key, answer options or student data in this source.
DO $pre$
BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Internal AI evidence ledger already exists; refuse replacement'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry must be draft and OFF'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701')<>30
 THEN RAISE EXCEPTION 'Wrong legacy candidate count'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1(
 program_key text NOT NULL CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL CHECK(version_key='chemistry_2025_2027_v1'),
 paper_code text NOT NULL CHECK(paper_code='P1'),
 skill_key text NOT NULL,
 legacy_question_id bigint NOT NULL,
 source_snapshot_md5 text NOT NULL CHECK(source_snapshot_md5 ~ '^[a-f0-9]{32}$'),
 review_class text NOT NULL CHECK(review_class IN
 ('ai_first_pass_no_issue_found','ai_editorial_hold')),
 reviewer_identity text NOT NULL DEFAULT
 'OpenAI GPT-6 — internal AI QA; not an independent human examiner',
 reviewer_evidence text NOT NULL CHECK(length(btrim(reviewer_evidence))>=45),
 academy_review_is_independent boolean NOT NULL DEFAULT false CHECK(academy_review_is_independent=false),
 can_issue_question boolean NOT NULL DEFAULT false CHECK(can_issue_question=false),
 can_credit_mastery boolean NOT NULL DEFAULT false CHECK(can_credit_mastery=false),
 reviewed_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(program_key,version_key,paper_code,skill_key,legacy_question_id),
 FOREIGN KEY(program_key,version_key,paper_code,skill_key,legacy_question_id)
 REFERENCES private.iclub_exam_core_question_candidates_v1
 (program_key,version_key,paper_code,skill_key,legacy_question_id)
 ON UPDATE RESTRICT ON DELETE RESTRICT,
 FOREIGN KEY(program_key,version_key,legacy_question_id)
 REFERENCES private.iclub_exam_core_question_review_v1(program_key,version_key,legacy_question_id)
 ON UPDATE RESTRICT ON DELETE RESTRICT
);
ALTER TABLE private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1
FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1 IS
'Private GPT-6 internal editorial QA only. No external expert authority, marks or learner access.';

INSERT INTO private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1
(program_key,version_key,paper_code,skill_key,legacy_question_id,source_snapshot_md5,
review_class,reviewer_evidence)
SELECT c.program_key,c.version_key,c.paper_code,c.skill_key,c.legacy_question_id,
 c.source_snapshot_md5,
 CASE WHEN c.qa_scope_status='fail' OR c.qa_academic_status='fail'
 OR c.qa_language_status='fail' OR c.qa_format_status='fail'
 THEN 'ai_editorial_hold' ELSE 'ai_first_pass_no_issue_found' END,
 CASE c.legacy_question_id
 WHEN 1903 THEN 'Internal AI: particle-versus-number wording and Russian grammar mismatch; keep candidate blocked.'
 WHEN 1908 THEN 'Internal AI: p subshell was conflated with individual dumbbell-shaped p orbital; needs versioned correction.'
 WHEN 1953 THEN 'Internal AI: broken connective punctuation in both RU and UZ explanations.'
 WHEN 1978 THEN 'Internal AI: Russian question asks for a single particle but the correct model requires two species.'
 WHEN 1987 THEN 'Internal AI: ambiguous intramolecular-vs-intermolecular NH3 bonding; English answer label untranslated in RU and UZ.'
 WHEN 1997 THEN 'Internal AI: untranslated English Metallic lattice label in RU and UZ explanations.'
 WHEN 2018 THEN 'Internal AI: uninformative generic explanation for sodium metallic bonding; requires chemistry-specific rationale.'
 WHEN 2036 THEN 'Internal AI: generic explanation fails to explain ammonia hydrogen bonding against alternatives.'
 WHEN 2048 THEN 'Internal AI: generic explanation fails to compare water hydrogen bonding and relative boiling point.'
 ELSE 'Internal GPT-6 AI first-pass checked chemistry content, correct answer, distractors, EN/RU/UZ meaning and Cambridge 9701 skill mapping. No obvious defect; no external examiner approval and no learner release granted.'
 END
FROM private.iclub_exam_core_question_candidates_v1 c
JOIN private.iclub_exam_core_question_review_v1 r
 ON r.program_key=c.program_key AND r.version_key=c.version_key
 AND r.legacy_question_id=c.legacy_question_id
 AND r.source_snapshot_md5=c.source_snapshot_md5
WHERE c.program_key='chemistry_9701' AND c.version_key='chemistry_2025_2027_v1'
AND c.paper_code='P1';

DO $post$ DECLARE count_all int; held int; checked int;
BEGIN
 SELECT COUNT(*),COUNT(*) FILTER(WHERE review_class='ai_editorial_hold'),
 COUNT(*) FILTER(WHERE review_class='ai_first_pass_no_issue_found')
 INTO count_all,held,checked
 FROM private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1;
 IF count_all<>30 OR held<>9 OR checked<>21
 THEN RAISE EXCEPTION 'Review ledger must have 30/9/21 rows'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1','SELECT')
 OR has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_legacy_ai_reviews_v1','UPDATE')
 THEN RAISE EXCEPTION 'Reviewer data confidentiality invalid'; END IF;
END $post$;