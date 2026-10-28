-- J-07: private metadata bridge from distinct entry check to verified syllabus skill and trilingual Theory/Tutor.
-- No question content or AI tutor text is included in this view.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_entry_study_links_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'J07 study links already exist'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_items_v1)<>22
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_review_v1 WHERE verdict='internal_ai_pass')<>154
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'J07 source not ready or beta ON'; END IF;
END $pre$;
CREATE VIEW private.iclub_exam_chemistry_entry_study_links_v1
WITH(security_invoker=true) AS
SELECT d.syllabus_unit,d.id AS private_entry_id,d.skill_key,d.syllabus_point,d.item_md5 AS source_md5,
 d.review_status='internal_ai_reviewed' AND d.reviewer_type='internal_ai' AS AI_review_complete,
 (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_review_v1 q
 WHERE q.item_id=d.id AND q.snapshot_md5=d.item_md5
 AND q.verdict='internal_ai_pass' AND q.reviewer_type='internal_ai')=7 AS seven_review_gates,
 EXISTS(SELECT 1 FROM private.iclub_exam_core_skills_v1 s
 WHERE s.program_key=d.program_key AND s.version_key=d.version_key
 AND s.skill_key=d.skill_key AND s.syllabus_unit=d.syllabus_unit
 AND s.level_code='AS') AS syllabus_skill_link,
 EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_paper_catalog_preview_v1 c
 WHERE c.program_key=d.program_key AND c.version_key=d.version_key
 AND c.paper_code='P1' AND c.skill_key=d.skill_key
 AND c.theory_by_locale ?& ARRAY['ru','uz','en']) AS trilingual_theory_link,
 EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_paper_catalog_preview_v1 c
 WHERE c.program_key=d.program_key AND c.version_key=d.version_key
 AND c.paper_code='P1' AND c.skill_key=d.skill_key
 AND c.tutor_by_locale ?& ARRAY['ru','uz','en']) AS trilingual_tutor_link,
 NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 WHERE b.program_key=d.program_key AND b.version_key=d.version_key
 AND b.planning_role='proposed_form' AND b.skill_key=d.skill_key) AS distinct_from_exam_blueprint,
 NOT (d.can_issue_learner OR d.can_grade_mastery OR d.can_be_p1_paper) AS unreleased,
 'entry_check_not_calibrated_or_marked_mastered'::text AS assessment_meaning
FROM private.iclub_exam_chemistry_entry_items_v1 d;
REVOKE ALL ON private.iclub_exam_chemistry_entry_study_links_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_chemistry_entry_study_links_v1 TO service_role;
DO $post$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_study_links_v1)<>22
 OR EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_entry_study_links_v1
 WHERE NOT(AI_review_complete AND seven_review_gates AND syllabus_skill_link
 AND trilingual_theory_link AND trilingual_tutor_link
 AND distinct_from_exam_blueprint AND unreleased))
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_study_links_v1','SELECT')
 THEN RAISE EXCEPTION 'Study path links missing or leaked'; END IF;
END $post$;