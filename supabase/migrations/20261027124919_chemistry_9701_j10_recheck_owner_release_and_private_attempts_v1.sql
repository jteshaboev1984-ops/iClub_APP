-- J10: isolated Chemistry recheck release and account-owned state, all OFF/empty.
-- Recheck is one unseen form after a completed ENTRY, not a certificate of mastery.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_recheck_control_v1') IS NOT NULL
 OR to_regclass('private.iclub_exam_chemistry_recheck_release_items_v1') IS NOT NULL
 OR to_regclass('private.iclub_exam_chemistry_recheck_attempts_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'J10 tables already exist'; END IF;
 IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND launch_enabled=false)
 OR (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) IS DISTINCT FROM false
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_preflight_v1
 WHERE seven_internal_AI_reviews AND different_from_entry_stem AND different_from_P1_stem
 AND unreleased_no_mastery)<>22
 THEN RAISE EXCEPTION 'Chemistry is not closed or 22 J09 originals not fully reviewed'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_chemistry_recheck_control_v1(
 id smallint PRIMARY KEY CHECK(id=1),
 enabled boolean NOT NULL DEFAULT false,
 owner_go_at timestamptz,
 release_version text,
 approved_manifest_md5 text CHECK(approved_manifest_md5 IS NULL OR approved_manifest_md5~'^[a-f0-9]{32}$'),
 CHECK(enabled=false OR (owner_go_at IS NOT NULL AND
 length(release_version)>=12 AND approved_manifest_md5 IS NOT NULL))
);
INSERT INTO private.iclub_exam_chemistry_recheck_control_v1(id,enabled) VALUES(1,false);
CREATE TABLE private.iclub_exam_chemistry_recheck_release_items_v1(
 item_id text PRIMARY KEY REFERENCES private.iclub_exam_chemistry_recheck_items_v1(id) ON DELETE RESTRICT,
 item_md5 text NOT NULL CHECK(item_md5~'^[a-f0-9]{32}$'),
 release_version text NOT NULL CHECK(length(release_version)>=12),
 approved_at timestamptz NOT NULL
);
CREATE TABLE private.iclub_exam_chemistry_recheck_attempts_v1(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
 entry_id uuid NOT NULL REFERENCES private.iclub_exam_chemistry_entry_attempts_v1(id) ON DELETE RESTRICT,
 client_key text NOT NULL CHECK(length(client_key) BETWEEN 12 AND 128 AND client_key~'^[A-Za-z0-9_-]+$'),
 source_manifest_md5 text NOT NULL CHECK(source_manifest_md5~'^[a-f0-9]{32}$'),
 entry_source_md5 text NOT NULL CHECK(entry_source_md5~'^[a-f0-9]{32}$'),
 learning_ack_at timestamptz NOT NULL,
 learning_ack_kind text NOT NULL DEFAULT 'self_report' CHECK(learning_ack_kind='self_report'),
 status text NOT NULL DEFAULT 'active' CHECK(status IN('active','finalized')),
 items jsonb NOT NULL CHECK(jsonb_typeof(items)='array' AND jsonb_array_length(items)=22),
 responses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(responses)='object'),
 started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 deadline_at timestamptz NOT NULL,
 finalized_at timestamptz,
 score integer CHECK(score BETWEEN 0 AND 22),
 credited_to_mastery boolean NOT NULL DEFAULT false CHECK(credited_to_mastery=false),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(deadline_at>started_at),
 CHECK((status='active' AND finalized_at IS NULL AND score IS NULL)
 OR (status='finalized' AND finalized_at IS NOT NULL AND score IS NOT NULL)),
 UNIQUE(user_id,client_key),
 UNIQUE(user_id,source_manifest_md5)
);
CREATE UNIQUE INDEX chemistry_recheck_one_active_per_user_v1
 ON private.iclub_exam_chemistry_recheck_attempts_v1(user_id) WHERE status='active';
CREATE INDEX chemistry_recheck_owner_history_v1
 ON private.iclub_exam_chemistry_recheck_attempts_v1(user_id,started_at DESC);
ALTER TABLE private.iclub_exam_chemistry_recheck_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_control_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_release_items_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_release_items_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_attempts_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_attempts_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_control_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_release_items_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_attempts_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_control_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_release_items_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_attempts_v1 TO service_role;
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_release_items_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1) IS DISTINCT FROM false
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_recheck_attempts_v1','SELECT')
 THEN RAISE EXCEPTION 'J10 must start empty, gated and private'; END IF;
END $post$;