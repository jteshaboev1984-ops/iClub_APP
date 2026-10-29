-- One-time publish: corrected P1-TRI-01 zeros rubric, already staged in Supabase.
-- No retroactive modification of old v1/v2, historical assessment, sessions or marks.
-- AI-assisted owner-requested provenance; NOT an independent human academic review.
-- Apply only after checking all guard preconditions; never auto-replay as a migration.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='35s';
SELECT pg_advisory_xact_lock(611031528036);

DO $gate$
DECLARE v_total integer; v_bad integer;
BEGIN
  IF (SELECT count(*) FROM private.exam_prep_written_tasks
      WHERE id=279 AND content_version_id=5 AND task_key='P1TRI01-W01'
        AND task_version='wtv3' AND lifecycle_state='draft' AND qa_math_status='pending'
        AND rubric_json->>'max_marks'='10')<>1
    OR (SELECT count(*) FROM private.exam_prep_assessments
      WHERE id=457 AND content_version_id=5 AND assessment_key='p1_tri01_learning'
        AND assessment_version='av3' AND assessment_type='learning' AND status='draft')<>1
    OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=457)<>4
    OR (SELECT count(*) FROM private.exam_prep_assessment_items
        WHERE assessment_id=457 AND written_task_id=279 AND reserve_role='written')<>1
    OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1
        WHERE written_task_id=279 AND task_version='wtv3' AND review_state='draft')<>8
    OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=457)
    OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE written_task_id=279)
    OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=184 AND lifecycle_state='published')
    OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=380 AND status='published')
  THEN RAISE EXCEPTION 'P1_TRI01_v3_source_changed_or_student_state_exists'; END IF;

  SELECT sum((c.value->>'marks')::integer) INTO v_total
    FROM private.exam_prep_written_tasks w
    CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value) WHERE w.id=279;
  IF v_total<>10 THEN RAISE EXCEPTION 'P1_TRI01_v3_marks_changed'; END IF;
  IF (SELECT count(*) FROM private.exam_prep_written_tasks w
      CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
      WHERE w.id=279 AND c.value->>'id'='shape' AND (c.value->>'marks')::int=2
        AND c.value->>'rule'='1 mark for coherent sine curve and labelled scale; 1 mark for both exact zeros x=π/6 and x=5π/6.')<>1
  THEN RAISE EXCEPTION 'P1_TRI01_shape_or_zeros_wrong'; END IF;

  SELECT count(*) INTO v_bad FROM private.exam_prep_written_tasks w
    CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
    CROSS JOIN (VALUES('ru'::text),('uz'::text)) language(code)
    LEFT JOIN private.exam_prep_written_criteria_locale_v1 l
      ON l.written_task_id=w.id AND l.task_version=w.task_version
      AND l.criterion_id=c.value->>'id' AND l.language=language.code
    WHERE w.id=279 AND (l.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule')
      OR l.translated_rule IS NULL OR length(btrim(l.translated_rule))<3);
  IF v_bad<>0 THEN RAISE EXCEPTION 'P1_TRI01_locale_checksum_or_coverage_invalid_%',v_bad; END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_assessment_items old
    LEFT JOIN private.exam_prep_assessment_items new
      ON new.assessment_id=457 AND new.item_order=old.item_order
    WHERE old.assessment_id=380 AND
      (new.assessment_id IS NULL
        OR new.question_id IS DISTINCT FROM old.question_id
        OR new.primary_skill_code IS DISTINCT FROM old.primary_skill_code
        OR new.reserve_role IS DISTINCT FROM old.reserve_role
        OR new.is_holdout IS DISTINCT FROM old.is_holdout
        OR new.written_task_id IS DISTINCT FROM
          CASE WHEN old.written_task_id=184 THEN 279 ELSE old.written_task_id END))
  THEN RAISE EXCEPTION 'P1_TRI01_cloned_learning_pack_drift'; END IF;
END $gate$;

UPDATE private.exam_prep_written_criteria_locale_v1
 SET review_state='approved',
     academic_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN',
     language_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN',
     reviewed_at=now()
 WHERE written_task_id=279 AND task_version='wtv3' AND review_state='draft';

UPDATE private.exam_prep_written_tasks
 SET lifecycle_state='published',copyright_status='pass',
     qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
     approved_at=now()
 WHERE id=279 AND lifecycle_state='draft';

UPDATE private.exam_prep_assessments
 SET status='published',approved_at=now()
 WHERE id=457 AND status='draft';

DO $verify$ BEGIN
 IF (SELECT count(*) FROM private.exam_prep_written_tasks WHERE id=279 AND lifecycle_state='published')<>1
 OR (SELECT count(*) FROM private.exam_prep_assessments WHERE id=457 AND status='published')<>1
 OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1
     WHERE written_task_id=279 AND review_state='approved')<>8
 OR (SELECT count(*) FROM private.exam_prep_written_tasks WHERE id IN(17,184) AND lifecycle_state='published')<>2
 OR (SELECT count(*) FROM private.exam_prep_assessments WHERE id IN(38,380) AND status='published')<>2
 THEN RAISE EXCEPTION 'P1_TRI01_post_publish_incomplete';END IF;
END $verify$;
SELECT 'P1TRI01_OWNER_AI_ASSISTED_RELEASED' AS result,279 AS task_id,457 AS assessment_id;
COMMIT;
