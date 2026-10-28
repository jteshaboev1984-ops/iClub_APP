-- Economics 9708 v3 editor's final internal review 2026-10-28.
-- Reviewed by AI academic editor: NOT Cambridge certification / NOT external-human attestation.
-- No learner release, no user assignments, no legacy task updates.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='45s';
DO $pre$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027' AND status='draft' AND academic_review='pending' AND language_review='pending' AND source_review='pending' AND NOT release_enabled)<>22 THEN RAISE EXCEPTION '22 untouched candidate drafts required'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 WHERE program_key='economics_9708' AND task_version<>'economics_9708_written_editorial_candidate_v3_20261027' AND status='draft' AND NOT release_enabled)<>22 THEN RAISE EXCEPTION '22 legacy drafts must be preserved'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_source_cards_v1 WHERE program_key='economics_9708' AND source_version='economics_sectionA_editorial_v3_20261027' AND status='draft' AND NOT release_enabled AND academic_review='pending' AND language_review='pending' AND source_review='pending' AND private.iclub_exam_written_source_locale_valid_v1(content,'en') AND private.iclub_exam_written_source_locale_valid_v1(content,'ru') AND private.iclub_exam_written_source_locale_valid_v1(content,'uz') AND content_sha256=encode(pg_catalog.sha256(pg_catalog.convert_to(content::text,'UTF8')),'hex'))<>2 THEN RAISE EXCEPTION '2 valid draft sources required'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_source_bindings_v1 WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027')<>10 THEN RAISE EXCEPTION '10 source bindings required'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_access_v1) OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1) OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1) THEN RAISE EXCEPTION 'written learner assignments must remain empty'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5' AND status='active')<>1 THEN RAISE EXCEPTION 'Math active baseline changed'; END IF;
END;$pre$;
UPDATE private.iclub_exam_core_written_tasks_v1 SET status='approved',academic_review='approved',language_review='approved',source_review='approved'
WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
 AND task_version='economics_9708_written_editorial_candidate_v3_20261027' AND status='draft' AND NOT release_enabled;
UPDATE private.iclub_exam_written_source_cards_v1 SET status='approved',academic_review='approved',language_review='approved',source_review='approved'
WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
 AND source_version='economics_sectionA_editorial_v3_20261027' AND status='draft' AND NOT release_enabled;
DO $post$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027' AND status='approved' AND academic_review='approved' AND language_review='approved' AND source_review='approved' AND NOT release_enabled)<>22 THEN RAISE EXCEPTION 'task approval mismatch'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_source_cards_v1 WHERE program_key='economics_9708' AND source_version='economics_sectionA_editorial_v3_20261027' AND status='approved' AND academic_review='approved' AND language_review='approved' AND source_review='approved' AND NOT release_enabled)<>2 THEN RAISE EXCEPTION 'source approval mismatch'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 WHERE program_key='economics_9708' AND task_version<>'economics_9708_written_editorial_candidate_v3_20261027' AND status='draft' AND NOT release_enabled)<>22 THEN RAISE EXCEPTION 'legacy task changed'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_tasks_v1 WHERE program_key='economics_9708' AND release_enabled) OR EXISTS(SELECT 1 FROM private.iclub_exam_written_source_cards_v1 WHERE program_key='economics_9708' AND release_enabled) THEN RAISE EXCEPTION 'release forbidden in QA step'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_access_v1) OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1) OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1) THEN RAISE EXCEPTION 'learner runtime unexpectedly changed'; END IF;
END;$post$;
COMMIT;