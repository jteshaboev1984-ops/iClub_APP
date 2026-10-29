-- One-time publication for P5 normal-distribution translation, staged:
-- task 280 (P5NOR02-W01, wtv3) + assessment 458 (p5_nor02_learning, av3).
-- English prompt/rubric/marks unchanged, RU/UZ standard-normal method restored.
-- This is OWNER-REQUESTED AI-assisted content QA, not independent human signoff.
-- DO NOT execute automatically with deployments. Older versions stay untouched.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='35s';
SELECT pg_advisory_xact_lock(611031528037);
DO $pre$
DECLARE missing_criteria integer;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
   WHERE id=280 AND content_version_id=33 AND task_key='P5NOR02-W01'
   AND task_version='wtv3' AND lifecycle_state='draft' AND rubric_json->>'max_marks'='11')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
   WHERE id=458 AND content_version_id=33 AND assessment_key='p5_nor02_learning'
   AND assessment_version='av3' AND assessment_type='learning' AND status='draft')
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=458)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=458
       AND written_task_id=280 AND reserve_role='written')<>1
 OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1
       WHERE written_task_id=280 AND task_version='wtv3' AND review_state='draft')<>10
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=458)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE written_task_id=280)
 OR (SELECT count(*) FROM private.exam_prep_written_tasks
   WHERE id IN (80,204) AND lifecycle_state='published')<>2
 OR (SELECT count(*) FROM private.exam_prep_assessments
   WHERE id IN (216,400) AND status='published')<>2
 THEN RAISE EXCEPTION 'P5_NOR02_v3_source_or_target_changed'; END IF;

 IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks original
           JOIN private.exam_prep_written_tasks updated ON updated.id=280
           WHERE original.id=204 AND (
           updated.prompt_en IS DISTINCT FROM original.prompt_en
           OR updated.rubric_json IS DISTINCT FROM original.rubric_json
           OR updated.content_version_id IS DISTINCT FROM original.content_version_id))
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
     WHERE id=280
       AND prompt_ru LIKE '%стандартного нормального распределения%'
       AND prompt_uz LIKE '%standart normal taqsimot qiymatlaridan%'
       AND prompt_en LIKE '%use standard-normal values%')
 THEN RAISE EXCEPTION 'P5_NOR02_English_rubric_or_translation_drift';END IF;

 IF (SELECT sum((item.value->>'marks')::int)
    FROM private.exam_prep_written_tasks w
    CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') item(value)
    WHERE w.id=280)<>11 THEN RAISE EXCEPTION 'P5_NOR02_marks_changed';END IF;

 SELECT count(*) INTO missing_criteria
 FROM private.exam_prep_written_tasks w
 CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') item(value)
 CROSS JOIN (VALUES('ru'::text),('uz'::text)) lg(language)
 LEFT JOIN private.exam_prep_written_criteria_locale_v1 lc
   ON lc.written_task_id=w.id AND lc.task_version=w.task_version
   AND lc.criterion_id=item.value->>'id' AND lc.language=lg.language
 WHERE w.id=280 AND (lc.source_rule_md5 IS DISTINCT FROM md5(item.value->>'rule')
   OR length(trim(lc.translated_rule))<3);
 IF missing_criteria<>0 THEN RAISE EXCEPTION 'P5_NOR02_locale_checksum_mismatch';END IF;

 IF EXISTS(SELECT 1 FROM private.exam_prep_assessment_items old
 LEFT JOIN private.exam_prep_assessment_items newer
   ON newer.assessment_id=458 AND newer.item_order=old.item_order
 WHERE old.assessment_id=400 AND
 (newer.assessment_id IS NULL OR newer.question_id IS DISTINCT FROM old.question_id
 OR newer.primary_skill_code IS DISTINCT FROM old.primary_skill_code
 OR newer.reserve_role IS DISTINCT FROM old.reserve_role
 OR newer.is_holdout IS DISTINCT FROM old.is_holdout
 OR newer.written_task_id IS DISTINCT FROM
   CASE WHEN old.written_task_id=204 THEN 280 ELSE old.written_task_id END))
 THEN RAISE EXCEPTION 'P5_NOR02_learning_pack_drift';END IF;
END $pre$;

UPDATE private.exam_prep_written_criteria_locale_v1
SET review_state='approved',
    academic_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN',
    language_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN',
    reviewed_at=now()
WHERE written_task_id=280 AND task_version='wtv3' AND review_state='draft';

UPDATE private.exam_prep_written_tasks
SET lifecycle_state='published',copyright_status='pass',
    qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    approved_at=now()
WHERE id=280 AND task_version='wtv3' AND lifecycle_state='draft';

UPDATE private.exam_prep_assessments
SET status='published',approved_at=now()
WHERE id=458 AND assessment_version='av3' AND status='draft';

DO $post$ BEGIN
 IF (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1
      WHERE written_task_id=280 AND review_state='approved')<>10
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
      WHERE id=280 AND lifecycle_state='published')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
      WHERE id=458 AND status='published')
 OR (SELECT count(*) FROM private.exam_prep_assessments
      WHERE id IN(216,400) AND status='published')<>2
 THEN RAISE EXCEPTION 'P5_NOR02_v3_publication_incomplete';END IF;
END $post$;
SELECT 'P5_NOR02_OWNER_AI_ASSISTED_PUBLISHED' AS result,280 AS written_task_id,458 AS assessment_id;
COMMIT;
