-- Already applied to live Supabase 2026-10-26. Schema-only archival source.
-- Prior drafts were accessible in a public Git branch; actual viewing/copying is NOT established.
-- Originals are preserved; this archival table cannot itself issue or grade them. Any future use requires separate product and academic review.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_quarantine_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Quarantine exists: do not replace'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_core_chemistry_p1_quarantine_v1(
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1' CHECK(version_key='chemistry_2025_2027_v1'),
 draft_key text NOT NULL,
 source_bundle_key text NOT NULL,
 skill_key text NOT NULL,
 legacy_reference_id bigint,
 source_public_git_commit text NOT NULL,
 item_json jsonb NOT NULL,
 item_md5 text GENERATED ALWAYS AS (md5(item_json::text)) STORED,
 quarantine_reason text NOT NULL DEFAULT 'answer_key_previously_visible_in_public_git'
 CHECK(quarantine_reason='answer_key_previously_visible_in_public_git'),
 review_status text NOT NULL DEFAULT 'pending' CHECK(review_status='pending'),
 release_enabled boolean NOT NULL DEFAULT false CHECK(release_enabled=false),
 learner_assessment_eligible boolean NOT NULL DEFAULT false CHECK(learner_assessment_eligible=false),
 credit_mastery boolean NOT NULL DEFAULT false CHECK(credit_mastery=false),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(program_key,version_key,draft_key),
 FOREIGN KEY(program_key,version_key,skill_key)
 REFERENCES private.iclub_exam_core_skills_v1(program_key,version_key,skill_key)
 ON UPDATE RESTRICT ON DELETE RESTRICT,
 CHECK(jsonb_typeof(item_json)='object'),
 CHECK(item_json ?& ARRAY['id','answer_key','skill_key','locales','status']),
 CHECK(item_json->>'status'='draft'),
 CHECK(item_json->>'release_enabled'='false'),
 CHECK(item_json->'locales' ?& ARRAY['en','ru','uz']),
 CHECK(item_json->>'answer_key' IN ('A','B','C','D')),
 CHECK(draft_key=item_json->>'id'),
 CHECK(skill_key=item_json->>'skill_key')
);
ALTER TABLE private.iclub_exam_core_chemistry_p1_quarantine_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_chemistry_p1_quarantine_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_quarantine_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_quarantine_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_chemistry_p1_quarantine_v1 IS
'Previously exposed Chemistry P1 drafts, permanently excluded from graded assessment. No runtime consumer.';
DO $post$ BEGIN
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_quarantine_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_quarantine_v1','SELECT')
 OR has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_quarantine_v1','INSERT')
 THEN RAISE EXCEPTION 'Unsafe privileges on quarantined draft source'; END IF;
END $post$;
