-- J08 correction: entry learning links are immutable academic source references,
-- not dependent on PREVIEW catalog disappearing when Chemistry is published.
-- No student content, release flags or existing user rows touched.
CREATE OR REPLACE VIEW private.iclub_exam_chemistry_entry_study_links_v1
WITH (security_invoker=true) AS
SELECT d.syllabus_unit,d.id AS private_entry_id,d.skill_key,d.syllabus_point,
 d.item_md5 AS source_md5,
 d.review_status='internal_ai_reviewed' AND d.reviewer_type='internal_ai' AS AI_review_complete,
 (SELECT count(*) FROM private.iclub_exam_chemistry_entry_review_v1 q
  WHERE q.item_id=d.id AND q.snapshot_md5=d.item_md5
  AND q.verdict='internal_ai_pass' AND q.reviewer_type='internal_ai')=7 AS seven_review_gates,
 EXISTS(SELECT 1 FROM private.iclub_exam_core_skills_v1 s
  WHERE s.program_key=d.program_key AND s.version_key=d.version_key
  AND s.skill_key=d.skill_key AND s.syllabus_unit=d.syllabus_unit AND s.level_code='AS')
 AS syllabus_skill_link,
 EXISTS(SELECT 1 FROM private.iclub_exam_core_skills_v1 s
  JOIN private.iclub_subject_library_theory t
  ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key
  AND t.skill_key=s.skill_key
  WHERE s.program_key=d.program_key AND s.version_key=d.version_key
  AND s.skill_key=d.skill_key AND s.syllabus_unit=d.syllabus_unit
  AND t.locales ?& ARRAY['ru','uz','en'])
 AS trilingual_theory_link,
 (SELECT count(DISTINCT tutor.locale)=3
  FROM private.iclub_exam_core_skills_v1 s
  JOIN private.iclub_subject_library_tutor tutor
  ON tutor.subject_key=s.library_subject_key AND tutor.version_key=s.library_version_key
  AND tutor.skill_key=s.skill_key AND tutor.locale IN ('ru','uz','en')
  WHERE s.program_key=d.program_key AND s.version_key=d.version_key
  AND s.skill_key=d.skill_key AND s.syllabus_unit=d.syllabus_unit)
 AS trilingual_tutor_link,
 NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 WHERE b.program_key=d.program_key AND b.version_key=d.version_key
 AND b.planning_role='proposed_form' AND b.skill_key=d.skill_key)
 AS distinct_from_exam_blueprint,
 NOT(d.can_issue_learner OR d.can_grade_mastery OR d.can_be_p1_paper) AS unreleased,
 'entry_check_not_calibrated_or_marked_mastered'::text AS assessment_meaning
FROM private.iclub_exam_chemistry_entry_items_v1 d;
REVOKE ALL ON private.iclub_exam_chemistry_entry_study_links_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_chemistry_entry_study_links_v1 TO service_role;
DO $check$
DECLARE n int;
BEGIN
 SELECT count(*) INTO n FROM private.iclub_exam_chemistry_entry_study_links_v1
 WHERE AI_review_complete AND seven_review_gates AND syllabus_skill_link
 AND trilingual_theory_link AND trilingual_tutor_link AND distinct_from_exam_blueprint AND unreleased;
 IF n<>22 OR has_table_privilege('authenticated',
 'private.iclub_exam_chemistry_entry_study_links_v1','SELECT')
 THEN RAISE EXCEPTION '22 stable links must be private'; END IF;
END $check$;