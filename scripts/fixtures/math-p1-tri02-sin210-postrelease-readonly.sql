-- Read-only postflight for the single corrected sine-210 MCQ and unused learning pack.
-- This must NEVER alter learner attempts, old source questions or production state.
DO $verify$
DECLARE new_question bigint; new_assessment bigint; hash_expected text;
BEGIN
 SELECT m.question_id INTO STRICT new_question
 FROM private.exam_prep_question_content_meta m
 WHERE m.content_version_id=4813 AND m.content_key='P1TRI02-A01-QA20261101'
   AND m.lifecycle_state='published' AND m.qa_math_status='pass' AND m.exposure_state='released';
 SELECT id INTO STRICT new_assessment FROM private.exam_prep_assessments
 WHERE content_version_id=4813 AND assessment_key='P1-TRI-02-learning-alt-03'
   AND assessment_version='v2' AND status='published';
 IF new_question<>10101 OR new_assessment<>466
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta
  WHERE id=59273 AND content_key='P1TRI02-A01' AND lifecycle_state='retired'
   AND exposure_state='retired')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
  WHERE id=35422 AND status='retired')
 OR NOT EXISTS(SELECT 1 FROM public.questions WHERE id=7142 AND correct_answer='C')
 OR NOT EXISTS(SELECT 1 FROM public.questions q WHERE q.id=new_question
  AND q.correct_answer='A' AND q.qtype='mcq' AND q.is_active=false
  AND q.options_text_en::jsonb->>0='−1/2'
  AND q.options_text_en::jsonb->>2='−√3/2'
  AND q.options_text_ru::jsonb=q.options_text_en::jsonb
  AND q.options_text_uz::jsonb=q.options_text_en::jsonb)
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=new_assessment)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
     WHERE assessment_id=new_assessment AND question_id=new_question
       AND item_order=1 AND reserve_role='learning')<>1
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
     WHERE assessment_id=new_assessment AND written_task_id=15639)<>1
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE question_id IN(7142,new_question))
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id IN(35422,new_assessment))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE assessment_id IN(35422,new_assessment))
 OR abs(sin((210*pi()/180)::double precision)+0.5)>1e-12
 THEN RAISE EXCEPTION 'SIN210_READONLY_LIVE_POSTFLIGHT_FAILED'; END IF;

 SELECT md5(concat_ws(chr(31),
 q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
 coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
 coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
 coalesce(q.image_url,''),coalesce(q.is_active::text,''),
 coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
 coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
 coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
 coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
 coalesce(q.quality_flag,''),coalesce(q.quality_status,''))) INTO STRICT hash_expected
 FROM public.questions q WHERE q.id=new_question;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta
  WHERE question_id=new_question AND question_snapshot_md5=hash_expected)
 THEN RAISE EXCEPTION 'SIN210_SNAPSHOT_HASH_DRIFT'; END IF;
END $verify$;
SELECT 'SIN210_CORRECTED_LIVE_PASS' result, 10101 AS corrected_question,466 AS published_pack;
