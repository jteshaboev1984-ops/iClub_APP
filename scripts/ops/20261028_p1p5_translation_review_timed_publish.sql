-- One-time owner-directed release of four corrected P1/P5 timed-paper versions.
-- The original published work, timers, marks, learner sessions and attempts are untouched.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='65s';
SELECT pg_advisory_xact_lock(611031528034);
DO $pre$ BEGIN
 IF (SELECT count(*) FROM private.exam_prep_written_tasks WHERE id BETWEEN 272 AND 275 AND lifecycle_state='draft')<>4
 OR (SELECT count(*) FROM private.exam_prep_assessments WHERE id BETWEEN 450 AND 453 AND status='draft')<>4
 OR (SELECT count(*) FROM private.exam_prep_timed_assessment_contracts WHERE assessment_id BETWEEN 450 AND 453 AND status='draft')<>4
 OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE written_task_id BETWEEN 272 AND 275 AND review_state='draft')<>54 THEN
   RAISE EXCEPTION 'pre_release_versions_changed'; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id BETWEEN 450 AND 453)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE assessment_id BETWEEN 450 AND 453) THEN
   RAISE EXCEPTION 'already_issued_staged_paper'; END IF;
END $pre$;
UPDATE private.exam_prep_written_criteria_locale_v1 SET
review_state='approved',
academic_review_ref='OWNER_DIRECTED_AI_ASSISTED_CORRECTION_REVIEW_2026-10-28',
language_review_ref='OWNER_DIRECTED_AI_ASSISTED_CORRECTION_REVIEW_2026-10-28',
reviewed_at=now()
WHERE written_task_id BETWEEN 272 AND 275 AND review_state='draft';
UPDATE private.exam_prep_written_tasks SET
lifecycle_state='published',copyright_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',approved_at=now()
WHERE id BETWEEN 272 AND 275 AND lifecycle_state='draft';
UPDATE private.exam_prep_assessments SET status='published',approved_at=now()
WHERE id BETWEEN 450 AND 453 AND status='draft';
UPDATE private.exam_prep_timed_assessment_contracts SET status='published',published_at=now()
WHERE assessment_id BETWEEN 450 AND 453 AND status='draft';
DO $post$BEGIN
 IF (SELECT count(*) FROM private.exam_prep_written_tasks WHERE id BETWEEN 272 AND 275 AND lifecycle_state='published')<>4
 OR (SELECT count(*) FROM private.exam_prep_assessments WHERE id BETWEEN 450 AND 453 AND status='published')<>4
 OR (SELECT count(*) FROM private.exam_prep_timed_assessment_contracts WHERE assessment_id BETWEEN 450 AND 453 AND status='published')<>4
 OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE written_task_id BETWEEN 272 AND 275 AND review_state='approved')<>54 THEN RAISE EXCEPTION 'release_incomplete';END IF;
END $post$;
SELECT (SELECT count(*) FROM private.exam_prep_assessments WHERE id BETWEEN 450 AND 453 AND status='published') published_papers,
(SELECT count(*) FROM private.exam_prep_timed_assessment_contracts WHERE assessment_id BETWEEN 450 AND 453 AND status='published') published_contracts;
COMMIT;