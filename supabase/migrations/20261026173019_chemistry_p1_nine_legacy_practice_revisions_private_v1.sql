-- Already applied in Supabase 20261026173019. Schema-only source.
-- Question text, translations, distractors and keys are imported separately into PRIVATE storage.
-- NEVER commit unissued assessment bodies or keys to the public repository.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_legacy_revisions_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Legacy revisions table exists; refuse overwrite'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701'
 AND version_key='chemistry_2025_2027_v1' AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry must be DRAFT/OFF'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_core_chemistry_p1_legacy_revisions_v1 (
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1' CHECK(version_key='chemistry_2025_2027_v1'),
 paper_code text NOT NULL DEFAULT 'P1' CHECK(paper_code='P1'),
 revision_key text NOT NULL,
 source_legacy_question_id bigint NOT NULL,
 skill_key text NOT NULL,
 source_snapshot_md5 text NOT NULL CHECK(source_snapshot_md5 ~ '^[a-f0-9]{32}$'),
 revision_version text NOT NULL,
 item_json jsonb NOT NULL CHECK(jsonb_typeof(item_json)='object'),
 item_md5 text GENERATED ALWAYS AS (md5(item_json::text)) STORED,
 provenance text NOT NULL DEFAULT 'revision_of_already_published_practice_item'
 CHECK(provenance='revision_of_already_published_practice_item'),
 review_status text NOT NULL DEFAULT 'pending' CHECK(review_status='pending'),
 exam_unseen_inventory boolean NOT NULL DEFAULT false CHECK(exam_unseen_inventory=false),
 release_enabled boolean NOT NULL DEFAULT false CHECK(release_enabled=false),
 can_score boolean NOT NULL DEFAULT false CHECK(can_score=false),
 can_credit_mastery boolean NOT NULL DEFAULT false CHECK(can_credit_mastery=false),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(program_key,version_key,revision_key,revision_version),
 FOREIGN KEY(program_key,version_key,paper_code,skill_key,source_legacy_question_id)
 REFERENCES private.iclub_exam_core_question_candidates_v1
 (program_key,version_key,paper_code,skill_key,legacy_question_id)
 ON UPDATE RESTRICT ON DELETE RESTRICT,
 CHECK(item_json->>'id'=revision_key),
 CHECK(item_json->>'skill_key'=skill_key),
 CHECK(item_json->>'source_legacy_question_id'=source_legacy_question_id::text),
 CHECK(item_json->>'status'='draft'),
 CHECK(item_json->>'release_enabled'='false'),
 CHECK(item_json->'locales' ?& ARRAY['en','ru','uz']),
 CHECK(item_json->>'answer_key' IN ('A','B','C','D'))
);
ALTER TABLE private.iclub_exam_core_chemistry_p1_legacy_revisions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_chemistry_p1_legacy_revisions_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_legacy_revisions_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_legacy_revisions_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_chemistry_p1_legacy_revisions_v1 IS
 'Separate private revision of old published practice items; does not change public questions or learner progress; does not add secure unseen exam inventory.';
DO $post$ BEGIN
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_legacy_revisions_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_legacy_revisions_v1','SELECT')
 OR has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_legacy_revisions_v1','INSERT')
 THEN RAISE EXCEPTION 'Unsafe grants'; END IF;
END $post$;