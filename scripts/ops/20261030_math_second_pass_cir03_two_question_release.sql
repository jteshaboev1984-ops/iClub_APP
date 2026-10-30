-- Controlled single-transaction release of corrected P1-CIR-03 learning MCQ/input.
-- Distinct new questions: 10100 (MCQ 4.13), 10099 (input 25.05). New pack 465/v3.
-- Retire only historic unused packs 35421/v1 and 464/v2 and their two faulty governed content-meta rows.
-- Student responses/session state NEVER changed; no mass access flag changes.
-- This is owner-requested AI-assisted mathematics/language review, not human signoff.
BEGIN;
SET LOCAL statement_timeout='60s';
SET LOCAL lock_timeout='4s';
SELECT pg_advisory_xact_lock(611031528041);
DO $guard$ DECLARE bad int;BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
   WHERE id=465 AND content_version_id=4813 AND assessment_key='P1-CIR-03-learning-alt-03'
   AND assessment_version='v3' AND status='draft')
 OR (SELECT count(*) FROM private.exam_prep_assessments
   WHERE id IN(35421,464) AND status='published')<>2
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id IN (35421,464,465))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE assessment_id IN (35421,464,465))
 OR EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1 WHERE assessment_id IN(35421,464,465))
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_goal_snapshots WHERE assessment_id IN(35421,464,465))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE question_id IN(7154,7140,10099,10100))
 OR (SELECT count(*) FROM private.exam_prep_question_content_meta
   WHERE question_id IN(10099,10100) AND content_version_id=4813
    AND lifecycle_state='draft' AND exposure_state='withheld'
    AND qa_math_status='pending')<>2
 OR (SELECT count(*) FROM private.exam_prep_question_content_meta
   WHERE question_id IN(7154,7140) AND content_version_id=4813 AND lifecycle_state='published')<>2
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=465)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
    WHERE assessment_id=465 AND ((question_id IN(10099,10100) AND reserve_role='learning')
       OR (written_task_id=286 AND reserve_role='written')))<>3
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
    WHERE assessment_id=465 AND question_id=7138 AND item_order=2)<>1
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id IN(35421,464)
    AND question_id IN(7154,7140))<>4
 THEN RAISE EXCEPTION 'CIR03_SECOND_PASS_RELEASE_GUARD_DRIFT'; END IF;

 IF round((40-50*sin(0.8))::numeric,2)<>4.13
 OR round((39.6-18*sin(2.2))::numeric,2)<>25.05
 OR NOT EXISTS(SELECT 1 FROM public.questions q
    WHERE q.id=10100 AND q.is_active=false AND q.qtype='mcq'
      AND q.correct_answer='A' AND (q.options_text_en::jsonb->>0)='4.13 cm²'
      AND jsonb_array_length(q.options_text_en::jsonb)=4
      AND jsonb_array_length(q.options_text_ru::jsonb)=4
      AND jsonb_array_length(q.options_text_uz::jsonb)=4)
 OR NOT EXISTS(SELECT 1 FROM public.questions q
    WHERE q.id=10099 AND q.is_active=false AND q.qtype='input'
      AND q.correct_answer='25.05' AND q.options_text_en::jsonb='[]'::jsonb)
 THEN RAISE EXCEPTION 'CIR03_SECOND_PASS_MATHEMATICS_OR_KEY_MISMATCH';END IF;

 SELECT count(*) INTO bad
 FROM private.exam_prep_question_content_meta m JOIN public.questions q ON q.id=m.question_id
 WHERE m.question_id IN(10099,10100)
 AND m.question_snapshot_md5 IS DISTINCT FROM md5(concat_ws(chr(31),
  q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
  coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
  coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
  coalesce(q.image_url,''),coalesce(q.is_active::text,''),
  coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
  coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
  coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
  coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
  coalesce(q.quality_flag,''),coalesce(q.quality_status,'')));
 IF bad<>0 THEN RAISE EXCEPTION 'CIR03_SECOND_PASS_SOURCE_SNAPSHOT_CHANGED';END IF;
END $guard$;

-- Governance publication only: original underlying public question rows are immutable.
UPDATE private.exam_prep_question_content_meta
SET lifecycle_state='published',exposure_state='released',
 copyright_status='pass',qa_scope_status='pass',
 qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
 approved_at=now(),published_at=now(),updated_at=now()
WHERE question_id IN(10099,10100)
 AND content_version_id=4813 AND lifecycle_state='draft';

UPDATE private.exam_prep_assessments
SET status='published',approved_at=now()
WHERE id=465 AND status='draft';

-- These earlier packs have no issued authorizations, sessions, plans or review starts.
UPDATE private.exam_prep_assessments
SET status='retired'
WHERE id IN(35421,464) AND status='published';

-- Prevent old mathematically inconsistent items being rediscovered via metadata.
UPDATE private.exam_prep_question_content_meta
SET lifecycle_state='retired',exposure_state='retired',updated_at=now()
WHERE question_id IN(7140,7154) AND content_version_id=4813
 AND lifecycle_state='published';

DO $post$BEGIN
 IF (SELECT count(*) FROM private.exam_prep_question_content_meta
    WHERE question_id IN(10099,10100) AND lifecycle_state='published'
     AND exposure_state='released' AND qa_math_status='pass')<>2
 OR (SELECT count(*) FROM private.exam_prep_question_content_meta
    WHERE question_id IN(7140,7154) AND lifecycle_state='retired')<>2
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
    WHERE id=465 AND status='published')
 OR (SELECT count(*) FROM private.exam_prep_assessments
    WHERE id IN(35421,464) AND status='retired')<>2
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id IN (35421,464,465))
 THEN RAISE EXCEPTION 'CIR03_SECOND_PASS_PUBLISH_INCOMPLETE'; END IF;
END $post$;
SELECT 'PUBLISHED_AND_SUPERSEDED_UNUSED_FAULTY_PACKS' AS result,
 465 AS corrected_assessment,10099 AS corrected_input,10100 AS corrected_mcq;
COMMIT;
