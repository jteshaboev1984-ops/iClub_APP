-- J-07: private distinct Chemistry AS entry-check content bank, NEVER student-facing.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_entry_items_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Entry bank already exists'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND launch_enabled=false)
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Chemistry must stay draft/OFF'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_chemistry_entry_items_v1(
 id text PRIMARY KEY CHECK(id~'^CHEM9701-ENTRY-J07-T(0[1-9]|1[0-9]|2[0-2])-[0-9]{2}$'),
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1' CHECK(version_key='chemistry_2025_2027_v1'),
 syllabus_unit smallint NOT NULL CHECK(syllabus_unit BETWEEN 1 AND 22),
 skill_key text NOT NULL,syllabus_point text NOT NULL,
 item_json jsonb NOT NULL,item_md5 text GENERATED ALWAYS AS (md5(item_json::text)) STORED,
 review_status text NOT NULL DEFAULT 'pending'
 CHECK(review_status IN('pending','internal_ai_reviewed','hold')),
 reviewer_type text NOT NULL DEFAULT 'none'
 CHECK(reviewer_type IN('none','internal_ai')),
 can_issue_learner boolean NOT NULL DEFAULT false CHECK(can_issue_learner=false),
 can_grade_mastery boolean NOT NULL DEFAULT false CHECK(can_grade_mastery=false),
 can_be_p1_paper boolean NOT NULL DEFAULT false CHECK(can_be_p1_paper=false),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(program_key,version_key,syllabus_unit),
 CHECK(item_json->>'id'=id),CHECK(item_json->>'skill_key'=skill_key),
 CHECK((item_json->>'syllabus_unit')::int=syllabus_unit),
 CHECK(item_json->>'paper_code'='ENTRY'),
 CHECK(item_json->>'question_type'='single_choice'),CHECK(item_json->>'status'='draft'),
 CHECK(item_json->>'answer_key' IN ('A','B','C','D')),
 CHECK(item_json->'locales' ?& ARRAY['en','ru','uz']),
 CHECK(jsonb_array_length(item_json->'locales'->'en'->'options')=4),
 CHECK(jsonb_array_length(item_json->'locales'->'ru'->'options')=4),
 CHECK(jsonb_array_length(item_json->'locales'->'uz'->'options')=4)
);
CREATE TABLE private.iclub_exam_chemistry_entry_review_v1(
 item_id text NOT NULL REFERENCES private.iclub_exam_chemistry_entry_items_v1(id) ON DELETE RESTRICT,
 snapshot_md5 text NOT NULL CHECK(snapshot_md5~'^[0-9a-f]{32}$'),
 gate text NOT NULL CHECK(gate IN('syllabus_scope','answer_and_distractors',
 'locale_en','locale_ru','locale_uz','exam_format','independence_from_P1')),
 verdict text NOT NULL DEFAULT 'pending' CHECK(verdict IN('pending','internal_ai_pass','hold')),
 reviewer_type text NOT NULL DEFAULT 'none' CHECK(reviewer_type IN('none','internal_ai')),
 reviewed_at timestamptz, created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(item_id,gate),CHECK(reviewer_type='internal_ai' OR verdict='pending')
);
ALTER TABLE private.iclub_exam_chemistry_entry_items_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_items_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_review_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_review_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_entry_items_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_entry_review_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_entry_items_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_entry_review_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_chemistry_entry_items_v1 IS
 '22 original draft diagnostic items, private, no student release, no P1 reuse, no mastery or calibration';
DO $post$ BEGIN
 IF has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_items_v1','SELECT')
 OR has_table_privilege('anon','private.iclub_exam_chemistry_entry_review_v1','SELECT')
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_items_v1)<>0
 THEN RAISE EXCEPTION 'Entry bank leaked or prefilled'; END IF;
END $post$;