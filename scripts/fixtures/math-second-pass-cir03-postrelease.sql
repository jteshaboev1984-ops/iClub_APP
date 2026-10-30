-- Read-only live post-release assertions for P1-CIR-03 second pass.
-- Do not touch production data.
DO $verify$DECLARE mismatches integer;BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
     WHERE id=465 AND assessment_key='P1-CIR-03-learning-alt-03'
     AND assessment_version='v3' AND status='published')
 OR (SELECT count(*) FROM private.exam_prep_assessments
     WHERE id IN(35421,464) AND status='retired')<>2
 OR (SELECT count(*) FROM private.exam_prep_question_content_meta
     WHERE question_id IN(10099,10100) AND lifecycle_state='published'
       AND exposure_state='released' AND qa_math_status='pass')<>2
 OR (SELECT count(*) FROM private.exam_prep_question_content_meta
     WHERE question_id IN(7154,7140) AND lifecycle_state='retired')<>2
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=465)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
     WHERE assessment_id=465 AND question_id IN(10099,10100))<>2
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
     WHERE assessment_id=465 AND written_task_id=286)<>1
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id IN(35421,464,465))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE question_id IN(7154,7140,10099,10100))
 THEN RAISE EXCEPTION 'SECOND_PASS_CIR03_LIVE_STATE_REGRESSION';END IF;
 IF round((40-50*sin(0.8))::numeric,2)<>4.13
 OR round((39.6-18*sin(2.2))::numeric,2)<>25.05
 OR NOT EXISTS(SELECT 1 FROM public.questions WHERE id=10100 AND correct_answer='A'
   AND options_text_en::jsonb->>0='4.13 cm²')
 OR NOT EXISTS(SELECT 1 FROM public.questions WHERE id=10099 AND correct_answer='25.05')
 THEN RAISE EXCEPTION 'SECOND_PASS_CIR03_MATH_KEY_REGRESSION';END IF;
 SELECT count(*) INTO mismatches
 FROM private.exam_prep_question_content_meta m
 JOIN public.questions q ON q.id=m.question_id
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
 IF mismatches<>0 THEN RAISE EXCEPTION 'SECOND_PASS_CIR03_SOURCE_HASH_REGRESSION';END IF;
END $verify$;
SELECT 'SECOND_PASS_CIR03_READONLY_PASS' AS result, 465 AS assessment, 2 AS corrected_questions;
