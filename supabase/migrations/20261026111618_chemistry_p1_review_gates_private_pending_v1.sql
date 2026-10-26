-- Already applied in production at 20261026111618. ADDITIVE private Chemistry P1 QA-review registry.
-- No question text, answer keys, explanations, rubrics or learner data included.
DO $pre$
BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_qa_slots_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Review slots already exist; do not overwrite'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry must remain draft/OFF'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1)<>18
 THEN RAISE EXCEPTION 'Expected 18 private draft questions'; END IF;
END $pre$;

CREATE TABLE private.iclub_exam_core_chemistry_p1_qa_slots_v1 (
 program_key text NOT NULL,
 version_key text NOT NULL,
 draft_key text NOT NULL,
 authoring_version text NOT NULL,
 source_snapshot_md5 text NOT NULL CHECK(source_snapshot_md5 ~ '^[a-f0-9]{32}$'),
 gate_key text NOT NULL CHECK(gate_key IN
 ('syllabus_scope','answer_and_distractors','locale_en','locale_ru',
  'locale_uz','exam_format','content_rights')),
 gate_status text NOT NULL DEFAULT 'pending' CHECK(gate_status IN ('pending','pass','fail')),
 reviewer_identity text NULL,
 reviewer_evidence text NULL,
 reviewed_at timestamptz NULL,
 can_release boolean NOT NULL DEFAULT false CHECK(can_release=false),
 can_grant_mastery boolean NOT NULL DEFAULT false CHECK(can_grant_mastery=false),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(program_key,version_key,draft_key,authoring_version,gate_key),
 FOREIGN KEY(program_key,version_key,draft_key,authoring_version)
  REFERENCES private.iclub_exam_core_chemistry_p1_secure_drafts_v1
  (program_key,version_key,draft_key,authoring_version)
  ON UPDATE RESTRICT ON DELETE RESTRICT,
 CHECK(
  (gate_status='pending' AND reviewer_identity IS NULL
   AND reviewer_evidence IS NULL AND reviewed_at IS NULL)
  OR
  (gate_status IN ('pass','fail') AND length(btrim(reviewer_identity))>=3
   AND length(btrim(reviewer_evidence))>=30 AND reviewed_at IS NOT NULL)
 )
);
ALTER TABLE private.iclub_exam_core_chemistry_p1_qa_slots_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_chemistry_p1_qa_slots_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_qa_slots_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_qa_slots_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_core_chemistry_p1_qa_slots_v1 IS
 'Private source-hash-bound reviewer gates; no learner delivery, grades or mastery authority.';

INSERT INTO private.iclub_exam_core_chemistry_p1_qa_slots_v1
(program_key,version_key,draft_key,authoring_version,source_snapshot_md5,gate_key)
SELECT d.program_key,d.version_key,d.draft_key,d.authoring_version,d.item_md5,g.gate_key
FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
CROSS JOIN (VALUES ('syllabus_scope'::text),('answer_and_distractors'),('locale_en'),
 ('locale_ru'),('locale_uz'),('exam_format'),('content_rights')) g(gate_key)
WHERE d.program_key='chemistry_9701' AND d.version_key='chemistry_2025_2027_v1';

DO $post$
BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1)<>126
 THEN RAISE EXCEPTION 'Expected 126 pending review slots'; END IF;
 IF EXISTS(
 SELECT 1 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 q
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
 USING(program_key,version_key,draft_key,authoring_version)
 WHERE q.gate_status<>'pending' OR q.source_snapshot_md5<>d.item_md5
 OR q.can_release OR q.can_grant_mastery)
 THEN RAISE EXCEPTION 'Review gate signed or source changed'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_qa_slots_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_qa_slots_v1','SELECT')
 OR has_table_privilege('service_role','private.iclub_exam_core_chemistry_p1_qa_slots_v1','UPDATE')
 THEN RAISE EXCEPTION 'Review slots have unsafe privileges'; END IF;
END $post$;