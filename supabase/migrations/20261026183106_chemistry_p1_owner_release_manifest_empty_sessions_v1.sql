-- Applied to private Supabase as version 20261026183106.
-- Empty versioned releases and learner sessions, independent of Economics/Maths/Practice.
CREATE TABLE private.iclub_exam_chemistry_p1_owner_release_items_v1(
 program_key text NOT NULL CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL CHECK(version_key='chemistry_2025_2027_v1'),
 draft_key text NOT NULL,
 authoring_version text NOT NULL,
 item_md5 text NOT NULL CHECK(item_md5 ~ '^[a-f0-9]{32}$'),
 approved_by_owner_at timestamptz NOT NULL,
 release_version text NOT NULL CHECK(length(release_version)>=12),
 PRIMARY KEY(program_key,version_key,draft_key,authoring_version),
 FOREIGN KEY(program_key,version_key,draft_key,authoring_version)
 REFERENCES private.iclub_exam_core_chemistry_p1_secure_drafts_v1
 (program_key,version_key,draft_key,authoring_version)
 ON UPDATE RESTRICT ON DELETE RESTRICT
);
CREATE TABLE private.iclub_exam_chemistry_p1_live_attempts_v1(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1'
 CHECK(version_key='chemistry_2025_2027_v1'),
 paper_code text NOT NULL DEFAULT 'P1' CHECK(paper_code='P1'),
 client_key text NOT NULL CHECK(length(client_key) BETWEEN 12 AND 128
 AND client_key ~ '^[a-zA-Z0-9_-]+$'),
 status text NOT NULL DEFAULT 'active' CHECK(status IN('active','finalized')),
 source_manifest_md5 text NOT NULL CHECK(source_manifest_md5 ~ '^[a-f0-9]{32}$'),
 items jsonb NOT NULL CHECK(jsonb_typeof(items)='array' AND jsonb_array_length(items)=40),
 responses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(responses)='object'),
 started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 deadline_at timestamptz NOT NULL,
 finalized_at timestamptz,
 score integer CHECK(score BETWEEN 0 AND 40),
 credited_to_mastery boolean NOT NULL DEFAULT false CHECK(credited_to_mastery=false),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(deadline_at>started_at),
 CHECK((status='active' AND score IS NULL AND finalized_at IS NULL)
 OR (status='finalized' AND score IS NOT NULL AND finalized_at IS NOT NULL)),
 UNIQUE(user_id,program_key,version_key,paper_code,client_key)
);
CREATE UNIQUE INDEX iclub_chemistry_p1_live_one_active_uq
ON private.iclub_exam_chemistry_p1_live_attempts_v1(user_id,program_key,version_key,paper_code)
WHERE status='active';
CREATE INDEX iclub_chemistry_p1_live_history_idx
ON private.iclub_exam_chemistry_p1_live_attempts_v1(user_id,started_at DESC);
ALTER TABLE private.iclub_exam_chemistry_p1_owner_release_items_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_owner_release_items_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_live_attempts_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_live_attempts_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_p1_owner_release_items_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_p1_live_attempts_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_p1_owner_release_items_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_p1_live_attempts_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_chemistry_p1_owner_release_items_v1 IS
'Requires explicit owner approval and exact private content hashes to make any specific draft available.';
COMMENT ON TABLE private.iclub_exam_chemistry_p1_live_attempts_v1 IS
'Future authenticated Chemistry P1 attempts, empty until separate beta GO; no auto mastery or mixed Maths/Economics records.';
DO $qa$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_p1_owner_release_items_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 THEN RAISE EXCEPTION 'No Chemistry release rows or attempts allowed in staging'; END IF;
 IF has_table_privilege('authenticated','private.iclub_exam_chemistry_p1_live_attempts_v1','SELECT')
 OR has_table_privilege('anon','private.iclub_exam_chemistry_p1_live_attempts_v1','INSERT')
 THEN RAISE EXCEPTION 'Private MCQ answer bank privilege leak'; END IF;
END $qa$;