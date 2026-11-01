-- One-time, atomic, versioned correction of published P1TRI02-A01 (Q7142).
-- Independent trigonometry: sin(210°)=sin(180°+30°)=-1/2; original keyed C (-sqrt(3)/2)
-- while original MCQ option A is -1/2 and EN/RU/UZ explanations were correct.
-- Reuse only under exact live preconditions. Already delivered learners are immutable.
-- AI-assisted owner-requested academic correction, NOT independent human approval.
BEGIN;
SET LOCAL statement_timeout='80s';
SET LOCAL lock_timeout='4s';
SELECT pg_advisory_xact_lock(611031528042);
DO $academic_release$
DECLARE new_q bigint;new_ass bigint; source_hash text;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta m
   JOIN public.questions q ON q.id=m.question_id
   WHERE m.id=59273 AND m.question_id=7142 AND m.content_version_id=4813
     AND m.content_key='P1TRI02-A01' AND m.lifecycle_state='published'
     AND m.exposure_state='released' AND m.reserve_role='learning'
     AND q.is_active=false AND q.qtype='mcq' AND q.correct_answer='C'
     AND q.question_text_en='Find the exact value of sin 210°.'
     AND q.options_text_en::jsonb='["−1/2","1/2","−√3/2","√3/2"]'::jsonb
     AND q.options_text_ru::jsonb=q.options_text_en::jsonb
     AND q.options_text_uz::jsonb=q.options_text_en::jsonb
     AND q.explanation_en LIKE '%−sin30°=−1/2%')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
   WHERE id=35422 AND assessment_key='P1-TRI-02-learning-alt-03'
     AND assessment_version='v1' AND content_version_id=4813
     AND assessment_type='learning' AND status='published')
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=35422)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=35422
     AND question_id=7142 AND item_order=1 AND primary_skill_code='P1-TRI-02'
       AND reserve_role='learning')<>1
 OR EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta
     WHERE content_version_id=4813 AND content_key='P1TRI02-A01-QA20261101')
 OR EXISTS(SELECT 1 FROM private.exam_prep_assessments
     WHERE content_version_id=4813 AND assessment_key='P1-TRI-02-learning-alt-03'
       AND assessment_version='v2')
 OR EXISTS(SELECT 1 FROM public.questions
     WHERE book_ref='ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:P1TRI02-A01:math-review-20261101')
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=35422)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE assessment_id=35422)
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_goal_snapshots WHERE assessment_id=35422)
 OR EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1 WHERE assessment_id=35422)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE question_id=7142)
 THEN RAISE EXCEPTION 'P1TRI02_SIN210_PRECONDITION_OR_LEARNER_USAGE_DRIFT'; END IF;
 IF abs(sin((210*pi()/180)::double precision)+0.5)>1e-12
 THEN RAISE EXCEPTION 'P1TRI02_TRIG_ORACLE_FAILED'; END IF;

 INSERT INTO public.questions
 (subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,
 image_url,is_active,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
 SELECT subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,'A',explanation,
 image_url,false,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref||':math-review-20261101',
 time_limit_sec,quality_flag,'draft'
 FROM public.questions WHERE id=7142 RETURNING id INTO STRICT new_q;

 SELECT md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
   coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
   coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),
   coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
   coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
   coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
   coalesce(q.quality_flag,''),coalesce(q.quality_status,''))) INTO STRICT source_hash
 FROM public.questions q WHERE q.id=new_q;

 INSERT INTO private.exam_prep_question_content_meta
 (content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
  reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,
  official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,
  qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5,
  approved_at,published_at,rejection_reason,created_at,updated_at)
 SELECT m.content_version_id,'P1TRI02-A01-QA20261101',new_q,
  m.primary_skill_code,m.secondary_skill_codes,m.reserve_role,
  'released','published',m.originality_attestation,
  'OWNER_REQUESTED_AI_ASSISTED_MATH_REPAIR_2026_11_01_NO_INDEPENDENT_HUMAN: Q7142 old C=-sqrt(3)/2, new A=-1/2; old learner state untouched.',
  m.official_scope_ref,m.coursebook_mapping_ref,
  'pass','pass','pass','pass','pass','not_applicable',source_hash,
  now(),now(),NULL,now(),now()
 FROM private.exam_prep_question_content_meta m WHERE m.id=59273;

 INSERT INTO private.exam_prep_assessments
 (content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
 title_en,title_ru,title_uz,created_at,approved_at)
 SELECT content_version_id,assessment_key,'v2',component_code,assessment_type,'published',
 title_en,title_ru,title_uz,now(),now()
 FROM private.exam_prep_assessments WHERE id=35422 RETURNING id INTO STRICT new_ass;

 INSERT INTO private.exam_prep_assessment_items
 (assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,created_at)
 SELECT new_ass,item_order,CASE WHEN question_id=7142 THEN new_q ELSE question_id END,
 written_task_id,primary_skill_code,reserve_role,is_holdout,now()
 FROM private.exam_prep_assessment_items WHERE assessment_id=35422 ORDER BY item_order;

 IF (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=new_ass)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=new_ass AND question_id=new_q
     AND reserve_role='learning' AND item_order=1)<>1
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=new_ass AND written_task_id=15639)<>1
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE question_id IN(7142,new_q))
 THEN RAISE EXCEPTION 'P1TRI02_NEW_ASSESSMENT_INVALID'; END IF;

 UPDATE private.exam_prep_assessments SET status='retired' WHERE id=35422 AND status='published';
 UPDATE private.exam_prep_question_content_meta SET lifecycle_state='retired',
 exposure_state='retired',updated_at=now() WHERE id=59273 AND lifecycle_state='published';

 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
   WHERE id=new_ass AND status='published')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments
   WHERE id=35422 AND status='retired')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta
   WHERE question_id=new_q AND content_key='P1TRI02-A01-QA20261101'
     AND question_snapshot_md5=source_hash AND qa_math_status='pass' AND lifecycle_state='published')
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta
   WHERE id=59273 AND lifecycle_state='retired')
 OR NOT EXISTS(SELECT 1 FROM public.questions
   WHERE id=7142 AND correct_answer='C')
 OR NOT EXISTS(SELECT 1 FROM public.questions
   WHERE id=new_q AND correct_answer='A' AND is_active=false)
 THEN RAISE EXCEPTION 'P1TRI02_POSTPUBLISH_FAILED'; END IF;
END $academic_release$;
SELECT 'P1TRI02_A01_SIN210_VERSIONED_PUBLISHED' AS result,
  (SELECT question_id FROM private.exam_prep_question_content_meta
   WHERE content_version_id=4813 AND content_key='P1TRI02-A01-QA20261101') AS new_question_id,
  (SELECT id FROM private.exam_prep_assessments
   WHERE content_version_id=4813 AND assessment_key='P1-TRI-02-learning-alt-03' AND assessment_version='v2') AS new_assessment_id;
COMMIT;
