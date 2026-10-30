-- READ-ONLY post-publication contract: six owner-requested AI-assisted P1/P5 repairs.
-- Check live release without creating/altering any learners, records or flags.
DO $audit$
DECLARE f record; bad int;
BEGIN
 FOR f IN SELECT * FROM (VALUES
 (184,279,380,457,10,8,0),
 (204,280,400,458,11,10,0),
 (62,281,167,459,10,10,1),
 (185,282,381,460,10,8,1),
 (38,285,98,463,10,8,0),
 (15638,286,35421,464,6,10,1)
 ) AS m(old_task,new_task,old_assessment,new_assessment,marks,locales,checks)
 LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=f.new_task AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=f.old_task AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=f.new_assessment AND status='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=f.old_assessment AND status='published')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 l
      WHERE l.written_task_id=f.new_task AND l.review_state='approved'
       AND l.academic_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_30_NO_INDEPENDENT_HUMAN')<>f.locales
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks c
      WHERE c.written_task_id=f.new_task AND c.lifecycle_state='published')<>f.checks
  OR (SELECT count(*) FROM private.exam_prep_assessment_items i
      WHERE i.assessment_id=f.new_assessment)<>4
  OR (SELECT count(*) FROM private.exam_prep_assessment_items i
      WHERE i.assessment_id=f.new_assessment AND i.written_task_id=f.new_task)<>1
  OR EXISTS(SELECT 1 FROM private.exam_prep_session_items si WHERE si.written_task_id=f.new_task)
  THEN RAISE EXCEPTION 'MATH_SIX_READONLY_CONTRACT_FAILED_%',f.new_task;END IF;
  SELECT count(*) INTO bad
  FROM private.exam_prep_written_tasks w
  CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
  CROSS JOIN (VALUES('ru'::text),('uz'::text)) lang(code)
  LEFT JOIN private.exam_prep_written_criteria_locale_v1 l
     ON l.written_task_id=w.id AND l.task_version=w.task_version
     AND l.criterion_id=c.value->>'id' AND l.language=lang.code
  WHERE w.id=f.new_task AND
   (l.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule')
    OR l.translated_rule IS NULL);
  IF bad<>0 THEN RAISE EXCEPTION 'MATH_SIX_READONLY_LOCALE_HASH_FAILED_%',f.new_task;END IF;
  IF (SELECT sum((c.value->>'marks')::int)
      FROM private.exam_prep_written_tasks w
      CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
      WHERE w.id=f.new_task)<>f.marks
  THEN RAISE EXCEPTION 'MATH_SIX_READONLY_MARKS_FAILED_%',f.new_task;END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
   WHERE id IN(279,280,281,282,285,286) AND lifecycle_state='draft')
 THEN RAISE EXCEPTION 'MATH_SIX_READONLY_STILL_DRAFT'; END IF;
END $audit$;
SELECT 'MATH_SIX_READONLY_CONTRACT_PASS' AS status,
  (SELECT count(*) FROM private.exam_prep_written_tasks
   WHERE id IN(279,280,281,282,285,286) AND lifecycle_state='published') AS published_corrected_tasks,
  (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1
   WHERE written_task_id IN(279,280,281,282,285,286) AND review_state='approved') AS published_locales,
  (SELECT count(*) FROM private.exam_prep_written_understanding_checks
   WHERE written_task_id IN(279,280,281,282,285,286) AND lifecycle_state='published') AS published_understanding_checks;
