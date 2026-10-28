-- J09 source correction custody: old never-released manuscripts remain private.
CREATE TABLE IF NOT EXISTS private.iclub_exam_chemistry_recheck_revisions_v1(
 id bigserial PRIMARY KEY,
 item_id text NOT NULL,
 archived_item_md5 text NOT NULL CHECK(archived_item_md5~'^[0-9a-f]{32}$'),
 archived_item_json jsonb NOT NULL,
 correction_reason text NOT NULL,
 saved_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(item_id,archived_item_md5)
);
ALTER TABLE private.iclub_exam_chemistry_recheck_revisions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_revisions_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_revisions_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_revisions_v1 TO service_role;
REVOKE ALL ON SEQUENCE private.iclub_exam_chemistry_recheck_revisions_v1_id_seq FROM PUBLIC,anon,authenticated;
DO $verify$ BEGIN
 IF has_table_privilege('authenticated','private.iclub_exam_chemistry_recheck_revisions_v1','SELECT')
 THEN RAISE EXCEPTION 'Recheck archive is not private'; END IF;
END $verify$;