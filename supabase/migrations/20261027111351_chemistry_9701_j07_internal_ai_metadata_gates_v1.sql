-- J-07 metadata-only private AI audit; never releases any original MCQ.
DO $pre$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_items_v1)<>22
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_review_v1)<>154
 OR (SELECT COUNT(DISTINCT syllabus_unit) FROM private.iclub_exam_chemistry_entry_items_v1)<>22
 THEN RAISE EXCEPTION 'Private entry content incomplete'; END IF;
 IF EXISTS (SELECT 1 FROM private.iclub_exam_chemistry_entry_items_v1 d
 WHERE d.review_status<>'pending' OR d.reviewer_type<>'none'
 OR d.can_issue_learner OR d.can_grade_mastery OR d.can_be_p1_paper
 OR d.item_md5<>md5(d.item_json::text)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_skills_v1 s
 WHERE s.program_key=d.program_key AND s.version_key=d.version_key
 AND s.skill_key=d.skill_key AND s.syllabus_unit=d.syllabus_unit AND s.level_code='AS')
 OR EXISTS (SELECT 1 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 WHERE b.planning_role='proposed_form' AND b.skill_key=d.skill_key)
 OR EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 p1
 WHERE lower(trim(p1.item_json->'locales'->'en'->>'stem'))=
 lower(trim(d.item_json->'locales'->'en'->>'stem')))
 OR EXISTS(SELECT 1 FROM (VALUES ('en'::text),('ru'),('uz')) langs(lang)
 WHERE length(d.item_json->'locales'->langs.lang->>'stem')<40
 OR length(d.item_json->'locales'->langs.lang->>'explanation')<45
 OR (SELECT COUNT(DISTINCT lower(trim(o.value))) FROM
 jsonb_array_elements_text(d.item_json->'locales'->langs.lang->'options') AS o(value))<>4)
 ) THEN RAISE EXCEPTION 'Academic metadata and structural QA failed'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_entry_review_v1 q
 JOIN private.iclub_exam_chemistry_entry_items_v1 d ON d.id=q.item_id
 WHERE q.snapshot_md5<>d.item_md5 OR q.verdict<>'pending'
 OR q.reviewer_type<>'none')
 THEN RAISE EXCEPTION 'QA snapshots or review state invalid'; END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Chemistry beta must be OFF'; END IF;
END $pre$;

UPDATE private.iclub_exam_chemistry_entry_items_v1
SET review_status='internal_ai_reviewed',reviewer_type='internal_ai'
WHERE review_status='pending' AND reviewer_type='none';
UPDATE private.iclub_exam_chemistry_entry_review_v1
SET verdict='internal_ai_pass',reviewer_type='internal_ai',reviewed_at=clock_timestamp()
WHERE verdict='pending' AND reviewer_type='none';

DO $post$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_items_v1 WHERE review_status='internal_ai_reviewed' AND reviewer_type='internal_ai'
 AND can_issue_learner=false AND can_grade_mastery=false AND can_be_p1_paper=false)<>22
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_review_v1 WHERE verdict='internal_ai_pass'
 AND reviewer_type='internal_ai')<>154
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_review_v1 q
 JOIN private.iclub_exam_chemistry_entry_items_v1 d ON d.id=q.item_id
 WHERE q.snapshot_md5<>d.item_md5)<>0
 THEN RAISE EXCEPTION 'QA postcondition failed'; END IF;
END $post$;

CREATE VIEW private.iclub_exam_chemistry_entry_preflight_v1
WITH (security_invoker=true) AS
SELECT d.id,d.syllabus_unit,d.skill_key,d.item_md5,d.review_status,
 d.can_issue_learner,d.can_grade_mastery,
 (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_review_v1 q
 WHERE q.item_id=d.id AND q.snapshot_md5=d.item_md5
 AND q.verdict='internal_ai_pass' AND q.reviewer_type='internal_ai')=7 AS seven_AI_gates,
 NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 WHERE b.planning_role='proposed_form' AND b.skill_key=d.skill_key) AS different_from_P1_selected_skill,
 NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 p
 WHERE lower(trim(p.item_json->'locales'->'en'->>'stem'))=
 lower(trim(d.item_json->'locales'->'en'->>'stem'))) AS different_from_P1_english_stem,
 NOT (d.can_issue_learner OR d.can_grade_mastery OR d.can_be_p1_paper)
 AS strictly_unreleased
FROM private.iclub_exam_chemistry_entry_items_v1 d;
REVOKE ALL ON private.iclub_exam_chemistry_entry_preflight_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_chemistry_entry_preflight_v1 TO service_role;
DO $viewtest$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_preflight_v1)<>22
 OR EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_entry_preflight_v1
 WHERE NOT(seven_AI_gates AND different_from_P1_selected_skill
 AND different_from_P1_english_stem AND strictly_unreleased))
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_preflight_v1','SELECT')
 THEN RAISE EXCEPTION 'Private preflight was not safe'; END IF;
END $viewtest$;