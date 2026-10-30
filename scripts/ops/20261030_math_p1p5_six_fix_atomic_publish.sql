-- One atomic, owner-authorized, AI-assisted release for six versioned P1/P5 corrections.
-- NO automatic application by CI or deployment. Reuse only with identical live DB preconditions.
-- NOT an independent qualified human academic or language signoff.
-- Old published tasks, responses, sessions, gate flags and other subjects are immutable.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='90s';
SELECT pg_advisory_xact_lock(611031528036);
SELECT pg_advisory_xact_lock(611031528037);
SELECT pg_advisory_xact_lock(611031528039);
SELECT pg_advisory_xact_lock(611031528040);

CREATE TEMP TABLE _academic_fixes (
 old_task_id bigint NOT NULL UNIQUE,
 new_task_id bigint NOT NULL PRIMARY KEY,
 old_assessment_id bigint NOT NULL UNIQUE,
 new_assessment_id bigint NOT NULL UNIQUE,
 task_key text NOT NULL,
 next_task_version text NOT NULL,
 next_assessment_version text NOT NULL,
 expected_marks int NOT NULL,
 expected_criteria int NOT NULL,
 expected_checks int NOT NULL,
 expected_content_version bigint NOT NULL
) ON COMMIT DROP;
INSERT INTO _academic_fixes VALUES
(184,279,380,457,'P1TRI01-W01','wtv3','av3',10,4,0,5),
(204,280,400,458,'P5NOR02-W01','wtv3','av3',11,5,0,33),
(62,281,167,459,'P5GEO03-W01','wtv2','av2',10,5,1,23),
(185,282,381,460,'P5CNT03-W01','wtv3','av3',10,4,1,6),
(38,285,98,463,'P1CIR03-W01','wtv2','av2',10,4,0,12),
(15638,286,35421,464,'P1CIR03-AW14','v2','v2',6,5,1,4813);

DO $preflight$
DECLARE f record; observed_marks int; observed_bad int;
BEGIN
 IF (SELECT count(*) FROM _academic_fixes)<>6
 THEN RAISE EXCEPTION 'MATH_SIX_EXPECTED_FIX_SET_DRIFT'; END IF;
 FOR f IN SELECT * FROM _academic_fixes ORDER BY new_task_id LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks t
    WHERE t.id=f.old_task_id AND t.task_key=f.task_key
      AND t.content_version_id=f.expected_content_version AND t.lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments a
    WHERE a.id=f.old_assessment_id AND a.assessment_type='learning' AND a.status='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks t
    WHERE t.id=f.new_task_id AND t.task_key=f.task_key
      AND t.content_version_id=f.expected_content_version
      AND t.task_version=f.next_task_version AND t.lifecycle_state='draft'
      AND t.qa_math_status='pending' AND t.qa_language_status='pending'
      AND (t.rubric_json->>'max_marks')::int=f.expected_marks
      AND jsonb_array_length(t.rubric_json->'criteria')=f.expected_criteria)
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments a
    WHERE a.id=f.new_assessment_id AND a.content_version_id=f.expected_content_version
      AND a.assessment_version=f.next_assessment_version
      AND a.assessment_type='learning' AND a.status='draft')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 l
      WHERE l.written_task_id=f.new_task_id AND l.task_version=f.next_task_version
        AND l.review_state='draft')<>f.expected_criteria*2
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks c
      WHERE c.written_task_id=f.new_task_id AND c.lifecycle_state='draft')<>f.expected_checks
  OR (SELECT count(*) FROM private.exam_prep_assessment_items i
      WHERE i.assessment_id=f.new_assessment_id)<>4
  OR (SELECT count(*) FROM private.exam_prep_assessment_items i
      WHERE i.assessment_id=f.new_assessment_id AND i.written_task_id=f.new_task_id
        AND i.reserve_role='written')<>1
  OR EXISTS(SELECT 1 FROM private.exam_prep_sessions s WHERE s.assessment_id=f.new_assessment_id)
  OR EXISTS(SELECT 1 FROM private.exam_prep_session_items si WHERE si.written_task_id=f.new_task_id)
  THEN RAISE EXCEPTION 'MATH_SIX_LIVE_PRECONDITION_FAILED_%',f.new_task_id; END IF;

  SELECT sum((c.value->>'marks')::int) INTO observed_marks
    FROM private.exam_prep_written_tasks t
    CROSS JOIN LATERAL jsonb_array_elements(t.rubric_json->'criteria') c(value)
    WHERE t.id=f.new_task_id;
  IF observed_marks<>f.expected_marks
  THEN RAISE EXCEPTION 'MATH_SIX_MARKS_DRIFT_%',f.new_task_id; END IF;

  SELECT count(*) INTO observed_bad
    FROM private.exam_prep_written_tasks t
    CROSS JOIN LATERAL jsonb_array_elements(t.rubric_json->'criteria') c(value)
    CROSS JOIN (VALUES('ru'::text),('uz'::text)) lng(code)
    LEFT JOIN private.exam_prep_written_criteria_locale_v1 l
      ON l.written_task_id=t.id AND l.task_version=t.task_version
      AND l.criterion_id=c.value->>'id' AND l.language=lng.code
    WHERE t.id=f.new_task_id AND
      (l.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule')
       OR l.translated_rule IS NULL OR length(btrim(l.translated_rule))<3);
  IF observed_bad<>0
  THEN RAISE EXCEPTION 'MATH_SIX_LOCALE_CHECKSUM_MISMATCH_%',f.new_task_id; END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_assessment_items old
     LEFT JOIN private.exam_prep_assessment_items newer
       ON newer.assessment_id=f.new_assessment_id AND newer.item_order=old.item_order
     WHERE old.assessment_id=f.old_assessment_id
       AND (newer.assessment_id IS NULL
        OR newer.question_id IS DISTINCT FROM old.question_id
        OR newer.primary_skill_code IS DISTINCT FROM old.primary_skill_code
        OR newer.reserve_role IS DISTINCT FROM old.reserve_role
        OR newer.is_holdout IS DISTINCT FROM old.is_holdout
        OR newer.written_task_id IS DISTINCT FROM CASE
          WHEN old.written_task_id=f.old_task_id THEN f.new_task_id
          ELSE old.written_task_id END))
  THEN RAISE EXCEPTION 'MATH_SIX_LEARNING_PACK_DRIFT_%',f.new_task_id;END IF;
 END LOOP;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
    WHERE id=279 AND rubric_json::text LIKE '%π/6%'
                  AND rubric_json::text LIKE '%5π/6%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
    WHERE id=280 AND prompt_ru LIKE '%стандартного нормального распределения%'
      AND prompt_uz LIKE '%standart normal taqsimot qiymatlaridan%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
    WHERE id=281 AND prompt_ru LIKE '%независимых испытаний%'
      AND prompt_uz LIKE '%mustaqil tajribalar%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
    WHERE id=282 AND prompt_ru LIKE '%каждый делитель устраняет повторный подсчёт%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
    WHERE id=285 AND rubric_json::text LIKE '%32sin(1.1)%'
      AND rubric_json::text LIKE '%6.68%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
    WHERE id=286 AND rubric_json::text LIKE '%40.5sin(1.2)%'
      AND rubric_json::text LIKE '%10.85%')
 THEN RAISE EXCEPTION 'MATH_SIX_CORRECTED_CONTENT_MISSING'; END IF;
END $preflight$;

-- These status transitions apply ONLY to the six isolated, student-unseen new versions.
-- The review provenance is explicit about AI assistance and does not imply human signoff.
UPDATE private.exam_prep_written_criteria_locale_v1 l
  SET review_state='approved',
      academic_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_30_NO_INDEPENDENT_HUMAN',
      language_review_ref='OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_30_NO_INDEPENDENT_HUMAN',
      reviewed_at=now()
  FROM _academic_fixes f
  WHERE l.written_task_id=f.new_task_id AND l.task_version=f.next_task_version
    AND l.review_state='draft';

UPDATE private.exam_prep_written_understanding_checks c
  SET lifecycle_state='published',
      qa_math_status='pass',qa_language_status='pass',
      qa_technical_status='pass',approved_at=now()
  FROM _academic_fixes f
  WHERE c.written_task_id=f.new_task_id AND c.lifecycle_state='draft';

UPDATE private.exam_prep_written_tasks t
  SET lifecycle_state='published',copyright_status='pass',
      qa_math_status='pass',qa_language_status='pass',
      qa_technical_status='pass',approved_at=now()
  FROM _academic_fixes f
  WHERE t.id=f.new_task_id AND t.task_version=f.next_task_version
    AND t.lifecycle_state='draft';

UPDATE private.exam_prep_assessments a
  SET status='published',approved_at=now()
  FROM _academic_fixes f
  WHERE a.id=f.new_assessment_id AND a.assessment_version=f.next_assessment_version
    AND a.status='draft';

DO $postflight$
DECLARE f record; observed int;
BEGIN
 FOR f IN SELECT * FROM _academic_fixes LOOP
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
      WHERE id=f.new_task_id AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
      WHERE id=f.new_assessment_id AND status='published')
  OR (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 l
      WHERE l.written_task_id=f.new_task_id AND l.review_state='approved')<>f.expected_criteria*2
  OR (SELECT count(*) FROM private.exam_prep_written_understanding_checks c
      WHERE c.written_task_id=f.new_task_id AND c.lifecycle_state='published')<>f.expected_checks
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks
      WHERE id=f.old_task_id AND lifecycle_state='published')
  OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
      WHERE id=f.old_assessment_id AND status='published')
  THEN RAISE EXCEPTION 'MATH_SIX_ATOMIC_RELEASE_POSTFLIGHT_FAILED_%',f.new_task_id; END IF;
 END LOOP;
 SELECT count(*) INTO observed
  FROM private.exam_prep_sessions s JOIN _academic_fixes f ON f.new_assessment_id=s.assessment_id;
 IF observed<>0 THEN RAISE EXCEPTION 'MATH_SIX_UNEXPECTED_SESSION_CREATED'; END IF;
END $postflight$;
SELECT 'MATH_SIX_OWNER_AI_ASSISTED_PUBLISHED' AS release,
  f.new_task_id,f.new_assessment_id FROM _academic_fixes f ORDER BY f.new_task_id;
COMMIT;
