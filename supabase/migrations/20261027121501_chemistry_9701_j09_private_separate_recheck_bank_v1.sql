-- Chemistry J09: never-issued independent AS recheck content bank. All source bodies are
-- inserted only through the private administration connection, never in public Git history.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_recheck_items_v1') IS NOT NULL
 OR to_regclass('private.iclub_exam_chemistry_recheck_review_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'J09 recheck content bank already exists'; END IF;
 IF (SELECT status<>'draft' OR launch_enabled FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701')
 OR (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 THEN RAISE EXCEPTION 'Chemistry must be draft and entry gate OFF'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_chemistry_recheck_items_v1 (
 id text PRIMARY KEY CHECK(id~'^CHEM9701-RECHECK-J09-T(0[1-9]|1[0-9]|2[0-2])-01$'),
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1' CHECK(version_key='chemistry_2025_2027_v1'),
 syllabus_unit smallint NOT NULL CHECK(syllabus_unit BETWEEN 1 AND 22),
 skill_key text NOT NULL,syllabus_point text NOT NULL,
 item_json jsonb NOT NULL,
 item_md5 text GENERATED ALWAYS AS (md5(item_json::text)) STORED,
 review_status text NOT NULL DEFAULT 'pending' CHECK(review_status IN ('pending','internal_ai_reviewed','hold')),
 reviewer_type text NOT NULL DEFAULT 'none' CHECK(reviewer_type IN ('none','internal_ai')),
 can_issue_learner boolean NOT NULL DEFAULT false CHECK(can_issue_learner=false),
 can_credit_mastery boolean NOT NULL DEFAULT false CHECK(can_credit_mastery=false),
 can_be_entry_question boolean NOT NULL DEFAULT false CHECK(can_be_entry_question=false),
 can_be_P1_paper boolean NOT NULL DEFAULT false CHECK(can_be_P1_paper=false),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(program_key,version_key,syllabus_unit),
 CHECK(item_json->>'id'=id),
 CHECK(item_json->>'skill_key'=skill_key),
 CHECK((item_json->>'syllabus_unit')::int=syllabus_unit),
 CHECK(item_json->>'assessment_code'='RECHECK'),
 CHECK(item_json->>'question_type'='single_choice'),
 CHECK(item_json->>'status'='draft'),
 CHECK(item_json->>'answer_key' IN ('A','B','C','D')),
 CHECK(item_json->'locales' ?& ARRAY['en','ru','uz']),
 CHECK(jsonb_array_length(item_json->'locales'->'en'->'options')=4),
 CHECK(jsonb_array_length(item_json->'locales'->'ru'->'options')=4),
 CHECK(jsonb_array_length(item_json->'locales'->'uz'->'options')=4)
);
CREATE TABLE private.iclub_exam_chemistry_recheck_review_v1 (
 item_id text NOT NULL REFERENCES private.iclub_exam_chemistry_recheck_items_v1(id) ON DELETE RESTRICT,
 snapshot_md5 text NOT NULL CHECK(snapshot_md5~'^[0-9a-f]{32}$'),
 gate text NOT NULL CHECK(gate IN ('syllabus_scope','scientific_key','distractor_quality',
 'locale_en','locale_ru','locale_uz','distinct_from_entry_and_P1')),
 verdict text NOT NULL DEFAULT 'pending' CHECK(verdict IN ('pending','internal_ai_pass','hold')),
 reviewer_type text NOT NULL DEFAULT 'none' CHECK(reviewer_type IN ('none','internal_ai')),
 reviewed_at timestamptz,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(item_id,gate),
 CHECK(reviewer_type='internal_ai' OR verdict='pending')
);
ALTER TABLE private.iclub_exam_chemistry_recheck_items_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_items_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_review_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_recheck_review_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_items_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_review_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_items_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_review_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_chemistry_recheck_items_v1 IS
 'Unseen stand-alone AS recheck content. Single question per unit insufficient to grant mastery. No direct learner issuance. Private only.';
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_items_v1)<>0
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_recheck_items_v1','SELECT')
 THEN RAISE EXCEPTION 'Recheck bank not initially blank/private'; END IF;
END $post$;