-- iClub internal original-question draft vault. Not a learner or grading data source.
-- A PUBLIC GitHub repo may safely contain this schema, NEVER its content/answer keys.
CREATE TABLE private.iclub_exam_core_authoring_blobs_v1 (
 artifact_key text PRIMARY KEY CHECK (artifact_key ~ '^[a-z0-9_]{12,160}$'),
 program_key text NOT NULL,
 version_key text NOT NULL,
 paper_code text NOT NULL,
 content_kind text NOT NULL CHECK (content_kind='original_mcq_draft'),
 payload_format text NOT NULL DEFAULT 'gzip_json_utf8'
   CHECK (payload_format='gzip_json_utf8'),
 content_gzip bytea NOT NULL CHECK (octet_length(content_gzip)>32),
 raw_sha256 text NOT NULL CHECK (raw_sha256 ~ '^[0-9a-f]{64}$'),
 compressed_sha256 text NOT NULL CHECK (compressed_sha256 ~ '^[0-9a-f]{64}$'),
 question_count smallint NOT NULL CHECK (question_count BETWEEN 1 AND 36),
 review_status text NOT NULL DEFAULT 'draft'
   CHECK (review_status IN ('draft','review_pending','blocked')),
 release_enabled boolean NOT NULL DEFAULT false CHECK (release_enabled=false),
 created_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT authoring_blob_program_fk
   FOREIGN KEY(program_key,version_key,paper_code)
   REFERENCES private.iclub_exam_core_papers_v1(program_key,version_key,paper_code)
   ON UPDATE RESTRICT ON DELETE RESTRICT
);
ALTER TABLE private.iclub_exam_core_authoring_blobs_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_authoring_blobs_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_exam_core_authoring_blobs_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON TABLE private.iclub_exam_core_authoring_blobs_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_authoring_blobs_v1 IS
 'Internal unpublished question-authoring payloads; service-only, gzip JSON, no learner runtime integration or publish path. Public GitHub stores schema only, never answer keys.';
