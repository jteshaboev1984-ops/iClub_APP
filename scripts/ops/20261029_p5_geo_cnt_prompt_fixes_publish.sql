-- Publish ONLY pre-staged draft P5 localization repairs, with immutable old versions.
-- P5GEO03: restore independence in the expected-trial interpretation (task 281/assessment 459).
-- P5CNT03: fix Russian grammatical/semantic wording of indistinguishable permutations (task 282/assessment 460).
-- Explicit provenance: owner-requested AI-assisted QA, NOT independently human-reviewed.
-- Manual one-time SQL operation. Do NOT auto-run via CI/Vercel.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='40s';
SELECT pg_advisory_xact_lock(611031528039);

CREATE TEMP TABLE _scope(old_task_id bigint,new_task_id bigint,old_assessment_id bigint,new_assessment_id bigint,task_key text,task_version text,assessment_version text,locale_rows integer)
ON COMMIT DROP;
INSERT INTO _scope VALUES
(62,281,167,459,'P5GEO03-W01','wtv2','av2',10),
(185,282,381,460,'P5CNT03-W01','wtv3','av3',8);

DO $gate$ DECLARE f record; bad integer; BEGIN
 FOR f IN SELECT * FROM _scope LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=f.old_task_id AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=f.old_assessment_id AND status='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=f.new_task_id AND task_key=f.task_key AND task_version=f.task_version AND lifecycle_state='draft' AND rubric_json->>'max_marks'='10')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=f.new_assessment_id AND assessment_version=f.assessment_version AND status='draft')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE written_task_id=f.new_task_id AND review_state='draft')<>f.locale_rows
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks WHERE written_task_id=f.new_task_id AND lifecycle_state='draft')<>1
  OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=f.new_assessment_id)<>4
  OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=f.new_assessment_id AND written_task_id=f.new_task_id AND reserve_role='written')<>1
  OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=f.new_assessment_id)
  OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE written_task_id=f.new_task_id)
  THEN RAISE EXCEPTION 'P5_prompt_fix_scope_changed_%',f.new_task_id;END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks old JOIN private.exam_prep_written_tasks new ON new.id=f.new_task_id
     WHERE old.id=f.old_task_id AND (old.prompt_en IS DISTINCT FROM new.prompt_en OR old.rubric_json IS DISTINCT FROM new.rubric_json OR old.content_version_id IS DISTINCT FROM new.content_version_id))
  THEN RAISE EXCEPTION 'P5_prompt_fix_English_or_marks_drift_%',f.new_task_id;END IF;

  SELECT count(*) INTO bad
  FROM private.exam_prep_written_tasks w
  CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') criterion(value)
  CROSS JOIN (VALUES('ru'::text),('uz'::text)) lang(code)
  LEFT JOIN private.exam_prep_written_criteria_locale_v1 loc
    ON loc.written_task_id=w.id AND loc.task_version=w.task_version
    AND loc.criterion_id=criterion.value->>'id' AND loc.language=lang.code
  WHERE w.id=f.new_task_id AND
   (loc.source_rule_md5 IS DISTINCT FROM md5(criterion.value->>'rule') OR loc.translated_rule IS NULL);
  IF bad<>0 THEN RAISE EXCEPTION 'P5_prompt_fix_locale_mismatch_%',f.new_task_id;END IF;
  IF (SELECT sum((criterion.value->>'marks')::int) FROM private.exam_prep_written_tasks w
      CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') criterion(value)
      WHERE w.id=f.new_task_id)<>10
  THEN RAISE EXCEPTION 'P5_prompt_fix_mark_total_changed_%',f.new_task_id;END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_assessment_items old
    LEFT JOIN private.exam_prep_assessment_items new ON new.assessment_id=f.new_assessment_id AND new.item_order=old.item_order
    WHERE old.assessment_id=f.old_assessment_id
      AND (new.assessment_id IS NULL OR new.question_id IS DISTINCT FROM old.question_id
       OR new.primary_skill_code IS DISTINCT FROM old.primary_skill_code OR new.reserve_role IS DISTINCT FROM old.reserve_role
       OR new.is_holdout IS DISTINCT FROM old.is_holdout OR new.written_task_id IS DISTINCT FROM
       CASE WHEN old.written_task_id=f.old_task_id THEN f.new_task_id ELSE old.written_task_id END))
  THEN RAISE EXCEPTION 'P5_prompt_fix_learning_pack_drift_%',f.new_assessment_id;END IF;
 END LOOP;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=281
    AND prompt_ru LIKE '%независимых испытаний%' AND prompt_uz LIKE '%mustaqil tajribalar%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=282
    AND prompt_ru LIKE '%каждый делитель устраняет повторный подсчёт%')
 THEN RAISE EXCEPTION 'P5_prompt_fix_translation_missing';END IF;
END $gate$;

UPDATE private.exam_prep_written_criteria_locale_v1 loc SET
 review_state='approved',
 academic_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN',
 language_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN',
 reviewed_at=now()
FROM _scope f WHERE loc.written_task_id=f.new_task_id AND loc.review_state='draft';

UPDATE private.exam_prep_written_understanding_checks check_item SET
 lifecycle_state='published',
 qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',approved_at=now()
FROM _scope f WHERE check_item.written_task_id=f.new_task_id AND check_item.lifecycle_state='draft';

UPDATE private.exam_prep_written_tasks task SET
 lifecycle_state='published',copyright_status='pass',
 qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',approved_at=now()
FROM _scope f WHERE task.id=f.new_task_id AND task.lifecycle_state='draft';

UPDATE private.exam_prep_assessments a SET status='published',approved_at=now()
FROM _scope f WHERE a.id=f.new_assessment_id AND a.status='draft';

DO $post$ DECLARE f record;BEGIN
 FOR f IN SELECT * FROM _scope LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=f.new_task_id AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=f.new_assessment_id AND status='published')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1
      WHERE written_task_id=f.new_task_id AND review_state='approved')<>f.locale_rows
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks
      WHERE written_task_id=f.new_task_id AND lifecycle_state='published')<>1
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=f.old_task_id AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=f.old_assessment_id AND status='published')
  THEN RAISE EXCEPTION 'P5_prompt_fix_publication_incomplete_%',f.new_task_id;END IF;
 END LOOP;
END $post$;
SELECT 'P5_GEO_CNT_OWNER_AI_ASSISTED_PUBLISHED' AS result,old_task_id,new_task_id,old_assessment_id,new_assessment_id FROM _scope ORDER BY new_task_id;
COMMIT;
