-- One-time controlled publication for two already staged P1-CIR-03 math corrections.
-- Owner-requested AI-assisted mathematical review, NOT independent human signoff.
-- Task 285/assessment 463: 32sin(1.1) -> segment 6.68 (instead of 9.6).
-- Task 286/assessment 464: 40.5sin(1.2) -> segment 10.85 (instead of 16.6).
-- Do not run automatically; no changes to old published tasks or learner records.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='45s';
SELECT pg_advisory_xact_lock(611031528040);
CREATE TEMP TABLE _publish_scope(
 old_task bigint,new_task bigint,old_assessment bigint,new_assessment bigint,
 expected_marks integer,expected_locale integer,expected_understanding integer) ON COMMIT DROP;
INSERT INTO _publish_scope VALUES (38,285,98,463,10,8,0),(15638,286,35421,464,6,10,1);

DO $g$ DECLARE m record;bad integer;marks integer;BEGIN
 FOR m IN SELECT * FROM _publish_scope LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=m.old_task AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=m.old_assessment AND status='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=m.new_task AND lifecycle_state='draft' AND qa_math_status='pending' AND qa_language_status='pending')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=m.new_assessment AND status='draft')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE written_task_id=m.new_task AND review_state='draft')<>m.expected_locale
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks WHERE written_task_id=m.new_task AND lifecycle_state='draft')<>m.expected_understanding
  OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=m.new_assessment)<>4
  OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=m.new_assessment AND written_task_id=m.new_task AND reserve_role='written')<>1
  OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE written_task_id=m.new_task)
  OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=m.new_assessment)
  THEN RAISE EXCEPTION 'P1_CIR03_publication_preflight_%',m.new_task; END IF;
  SELECT sum((c.value->>'marks')::integer) INTO marks
   FROM private.exam_prep_written_tasks w CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
   WHERE w.id=m.new_task;
  IF marks<>m.expected_marks THEN RAISE EXCEPTION 'P1_CIR03_mark_total_%',m.new_task; END IF;
  SELECT count(*) INTO bad
   FROM private.exam_prep_written_tasks w CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
   CROSS JOIN (VALUES('ru'::text),('uz'::text)) lng(lang)
   LEFT JOIN private.exam_prep_written_criteria_locale_v1 loc ON loc.written_task_id=w.id AND loc.task_version=w.task_version AND loc.criterion_id=c.value->>'id' AND loc.language=lng.lang
   WHERE w.id=m.new_task AND (loc.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule') OR loc.translated_rule IS NULL);
  IF bad<>0 THEN RAISE EXCEPTION 'P1_CIR03_locale_checksum_%',m.new_task; END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_assessment_items oi
   LEFT JOIN private.exam_prep_assessment_items ni ON ni.assessment_id=m.new_assessment AND ni.item_order=oi.item_order
   WHERE oi.assessment_id=m.old_assessment
     AND (ni.assessment_id IS NULL OR ni.question_id IS DISTINCT FROM oi.question_id
     OR ni.primary_skill_code IS DISTINCT FROM oi.primary_skill_code
     OR ni.reserve_role IS DISTINCT FROM oi.reserve_role OR ni.is_holdout IS DISTINCT FROM oi.is_holdout
     OR ni.written_task_id IS DISTINCT FROM CASE WHEN oi.written_task_id=m.old_task THEN m.new_task ELSE oi.written_task_id END))
  THEN RAISE EXCEPTION 'P1_CIR03_assessment_drift_%',m.new_task; END IF;
 END LOOP;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
   WHERE id=285 AND prompt_en LIKE '%1/2 r² sin θ%'
   AND rubric_json::text LIKE '%32sin(1.1)%'
   AND rubric_json::text LIKE '%6.68%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
   WHERE id=286 AND prompt_en LIKE '%1/2 r² sin θ%'
   AND rubric_json::text LIKE '%40.5sin(1.2)%'
   AND rubric_json::text LIKE '%10.85%')
 THEN RAISE EXCEPTION 'P1_CIR03_math_content_or_version_drift'; END IF;
END $g$;

UPDATE private.exam_prep_written_criteria_locale_v1 loc SET
 review_state='approved',
 academic_review_ref='OWNER_REQUESTED_AI_ASSISTED_ACADEMIC_REPAIR_2026_10_30_NOT_HUMAN',
 language_review_ref='OWNER_REQUESTED_AI_ASSISTED_ACADEMIC_REPAIR_2026_10_30_NOT_HUMAN',
 reviewed_at=now()
FROM _publish_scope m WHERE loc.written_task_id=m.new_task AND loc.review_state='draft';

UPDATE private.exam_prep_written_understanding_checks chk SET
 lifecycle_state='published',
 qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',approved_at=now()
FROM _publish_scope m WHERE chk.written_task_id=m.new_task AND chk.lifecycle_state='draft';

UPDATE private.exam_prep_written_tasks task SET
 lifecycle_state='published',copyright_status='pass',
 qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',approved_at=now()
FROM _publish_scope m WHERE task.id=m.new_task AND task.lifecycle_state='draft';

UPDATE private.exam_prep_assessments pack SET status='published',approved_at=now()
FROM _publish_scope m WHERE pack.id=m.new_assessment AND pack.status='draft';

DO $post$ DECLARE m record;BEGIN
 FOR m IN SELECT * FROM _publish_scope LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=m.new_task AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=m.new_assessment AND status='published')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE written_task_id=m.new_task AND review_state='approved')<>m.expected_locale
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks WHERE written_task_id=m.new_task AND lifecycle_state='published')<>m.expected_understanding
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=m.old_task AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=m.old_assessment AND status='published')
  THEN RAISE EXCEPTION 'P1_CIR03_publication_failed_%',m.new_task;END IF;
 END LOOP;
END $post$;
SELECT 'P1_CIR03_AI_ASSISTED_PUBLISHED' AS result,new_task,new_assessment FROM _publish_scope ORDER BY new_task;
COMMIT;
