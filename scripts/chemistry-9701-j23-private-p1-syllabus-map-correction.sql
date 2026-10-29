-- J23 prepared correction: PRIVATE original Chemistry P1 authoring version only.
-- Not a migration and not an automated production deploy. Run only after controlled
-- operator validation; no answer key, full question text or student data in this file.
-- This PRESERVES the old failed immutable source + all its QA history.
-- A new version corrects ONLY its canonical skill reference, and starts seven
-- review gates PENDING, with all release/mastery switches forced false.
BEGIN;
DO $guard$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
     WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
       AND authoring_version='iclub_original_private_20261026_v4'
       AND skill_key='CHEM9701-12-03'
       AND item_md5='abfc181a1dfa4190edc76de7dd554b8f'
       AND release_enabled=false AND exam_candidate_eligible=false AND credit_mastery=false) <> 1
 THEN RAISE EXCEPTION 'J23 STOP: original source differs from inspected baseline'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
     WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
       AND authoring_version='iclub_original_private_20261026_v4'
       AND gate_key='syllabus_scope' AND gate_status='fail') <> 1
 THEN RAISE EXCEPTION 'J23 STOP: original failed QA not preserved'; END IF;
 IF EXISTS (SELECT 1 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
     WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
       AND authoring_version='iclub_original_private_j23_20261028_v5')
 THEN RAISE EXCEPTION 'J23 STOP: corrected version already exists'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_paper_skills_v1
     WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
       AND paper_code='P1' AND skill_key='CHEM9701-12-04'
       AND link_role='direct') <> 1
 THEN RAISE EXCEPTION 'J23 STOP: target skill is not a valid P1 direct skill'; END IF;
 IF (SELECT can_publish FROM private.iclub_exam_chemistry_j12_release_gate_v1 LIMIT 1)
 THEN RAISE EXCEPTION 'J23 STOP: Chemistry publishing is active'; END IF;
END $guard$;

INSERT INTO private.iclub_exam_core_chemistry_p1_secure_drafts_v1
(program_key,version_key,draft_key,authoring_version,syllabus_unit,skill_key,
 item_json,source_safety,academic_review,language_review,format_review,
 release_enabled,exam_candidate_eligible,credit_mastery)
SELECT program_key,version_key,draft_key,
       'iclub_original_private_j23_20261028_v5',syllabus_unit,'CHEM9701-12-04',
       jsonb_set(item_json,'{skill_key}',to_jsonb('CHEM9701-12-04'::text)),
       source_safety,'pending','pending','pending',false,false,false
FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
  AND authoring_version='iclub_original_private_20261026_v4';

INSERT INTO private.iclub_exam_core_chemistry_p1_qa_slots_v1
(program_key,version_key,draft_key,authoring_version,source_snapshot_md5,
 gate_key,gate_status,reviewer_identity,reviewer_evidence,reviewed_at,
 can_release,can_grant_mastery)
SELECT d.program_key,d.version_key,d.draft_key,d.authoring_version,d.item_md5,
       gate.gate_key,'pending',null,null,null,false,false
FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
CROSS JOIN (VALUES ('syllabus_scope'),('answer_and_distractors'),('locale_en'),
                   ('locale_ru'),('locale_uz'),('exam_format'),('content_rights')) gate(gate_key)
WHERE d.draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
  AND d.authoring_version='iclub_original_private_j23_20261028_v5';

DO $verify$
BEGIN
 IF NOT EXISTS (
   SELECT 1 FROM private.iclub_exam_core_chemistry_p1_item_preflight_v1
   WHERE draft_key='CHEM9701-P1-SECURE4-20261026-T12-02'
     AND authoring_version='iclub_original_private_j23_20261028_v5'
     AND skill_key='CHEM9701-12-04'
     AND source_hash_valid AND source_id_and_draft_valid
     AND all_three_locale_keys AND locales_content_structurally_complete
     AND no_duplicate_options_in_locale AND no_duplicate_new_english_stem
     AND no_exact_legacy_english_stem AND direct_p1_skill_exists
     AND seven_review_slots_exist AND all_review_snapshots_current
     AND documented_review_passes=0 AND documented_review_failures=0
     AND remains_draft_and_unapproved
     AND NOT can_issue_learner_assessment AND NOT can_credit_mastery
 ) THEN RAISE EXCEPTION 'J23 STOP: corrected draft did not pass private structural QA'; END IF;
END $verify$;
COMMIT;
-- Deliberately no approval, release manifest, subject switch, Beta permission,
-- answer/key exposure, history or localStorage mutation.
