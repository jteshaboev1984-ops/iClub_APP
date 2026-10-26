-- Already applied to live Supabase 2026-10-26. Schema-only archival source.
-- Unpublished exam content never committed to this public GitHub repository.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_secure_drafts_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Secure draft store already exists'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_core_chemistry_p1_secure_drafts_v1(
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1' CHECK(version_key='chemistry_2025_2027_v1'),
 draft_key text NOT NULL,
 authoring_version text NOT NULL,
 syllabus_unit smallint NOT NULL CHECK(syllabus_unit BETWEEN 1 AND 22),
 skill_key text NOT NULL,
 item_json jsonb NOT NULL CHECK(jsonb_typeof(item_json)='object'),
 item_md5 text GENERATED ALWAYS AS (md5(item_json::text)) STORED,
 source_safety text NOT NULL DEFAULT 'never_committed_to_public_git'
  CHECK(source_safety='never_committed_to_public_git'),
 academic_review text NOT NULL DEFAULT 'pending' CHECK(academic_review='pending'),
 language_review text NOT NULL DEFAULT 'pending' CHECK(language_review='pending'),
 format_review text NOT NULL DEFAULT 'pending' CHECK(format_review='pending'),
 release_enabled boolean NOT NULL DEFAULT false CHECK(release_enabled=false),
 exam_candidate_eligible boolean NOT NULL DEFAULT false CHECK(exam_candidate_eligible=false),
 credit_mastery boolean NOT NULL DEFAULT false CHECK(credit_mastery=false),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(program_key,version_key,draft_key,authoring_version),
 FOREIGN KEY(program_key,version_key,skill_key)
  REFERENCES private.iclub_exam_core_skills_v1(program_key,version_key,skill_key)
  ON UPDATE RESTRICT ON DELETE RESTRICT,
 CHECK(draft_key=item_json->>'id'),
 CHECK(skill_key=item_json->>'skill_key'),
 CHECK(item_json->>'status'='draft'),
 CHECK(item_json->>'release_enabled'='false'),
 CHECK(item_json->'locales' ?& ARRAY['en','ru','uz']),
 CHECK(item_json->>'answer_key' IN ('A','B','C','D'))
);
ALTER TABLE private.iclub_exam_core_chemistry_p1_secure_drafts_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_chemistry_p1_secure_drafts_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_secure_drafts_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_secure_drafts_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_chemistry_p1_secure_drafts_v1 IS
'Private new Chemistry P1 draft source. Never include answer keys in public source control. No grading or learner access.';
DO $post$ BEGIN
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','SELECT')
 OR has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_secure_drafts_v1','INSERT')
 THEN RAISE EXCEPTION 'Unsafe private draft vault grants'; END IF;
END $post$;
