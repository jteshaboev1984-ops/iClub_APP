-- Independent second-pass: replace two mathematically inconsistent P1-CIR-03 learning questions.
-- Stage draft versions only; DO NOT alter historic questions, assessments or user data.
-- Old Q7154: r=10, angle 0.8. Correct minor segment 40 - 50sin(0.8) ~ 4.13 (not 16).
-- Old Q7140: r=6, angle 2.2. Correct minor segment 39.6 - 18sin(2.2) ~ 25.05 (not 25.2).
BEGIN;
SET LOCAL statement_timeout='80s';
SET LOCAL lock_timeout='4s';
SELECT pg_advisory_xact_lock(611031528041);

CREATE TEMP TABLE _math_second_pass (old_question bigint PRIMARY KEY,
  source_meta bigint NOT NULL, replacement_key text NOT NULL, new_question bigint) ON COMMIT DROP;
INSERT INTO _math_second_pass(old_question,source_meta,replacement_key) VALUES
 (7154,59270,'P1CIR03-A01-QA20261030'),
 (7140,59272,'P1CIR03-A03-QA20261030');

DO $preflight$
BEGIN
 IF (SELECT count(*) FROM _math_second_pass s
 JOIN private.exam_prep_question_content_meta m ON m.id=s.source_meta AND m.question_id=s.old_question
    AND m.content_version_id=4813 AND m.lifecycle_state='published' AND m.reserve_role='learning'
 JOIN public.questions q ON q.id=s.old_question AND q.is_active=false)<>2
 OR EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta m
    WHERE m.content_version_id=4813
    AND m.content_key IN ('P1CIR03-A01-QA20261030','P1CIR03-A03-QA20261030'))
 OR EXISTS(SELECT 1 FROM public.questions WHERE book_ref IN(
    'ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:P1CIR03-A01:math-review-20261030',
    'ExamPrep:P1:p1_aw13_16_alt_learning_draft_v1:P1CIR03-A03:math-review-20261030'))
 OR EXISTS(SELECT 1 FROM private.exam_prep_assessments
    WHERE content_version_id=4813 AND assessment_key='P1-CIR-03-learning-alt-03'
      AND assessment_version='v3')
 OR (SELECT count(*) FROM private.exam_prep_assessment_items
     WHERE assessment_id=464 AND question_id IN(7154,7140))<>2
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id IN (35421,464))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE assessment_id IN (35421,464))
 OR EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1 WHERE assessment_id IN (35421,464))
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_goal_snapshots WHERE assessment_id IN (35421,464))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE question_id IN(7154,7140))
 THEN RAISE EXCEPTION 'MATH_SECOND_PASS_SOURCE_OR_EXPOSURE_DRIFT';END IF;
END $preflight$;

WITH inserted AS (
 INSERT INTO public.questions
 (subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,
 image_url,is_active,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
 SELECT q.subject_id,q.topic,q.subtopic,q.difficulty,q.qtype,
 CASE s.old_question WHEN 7154 THEN
   'A sector has radius 10 cm and central angle 0.8 radians. Calculate the area of the minor segment between the chord and the arc, to 2 decimal places.'
 ELSE
   'A sector has radius 6 cm and central angle 2.2 radians. Calculate the area of the minor segment between the chord and the arc. Enter your answer in cm² to 2 decimal places.'
 END,
 CASE s.old_question WHEN 7154 THEN
   '["4.13 cm²","16 cm²","35.87 cm²","40 cm²"]' ELSE '[]' END,
 CASE s.old_question WHEN 7154 THEN 'A' ELSE '25.05' END,
 CASE s.old_question WHEN 7154 THEN
   'Sector area = 0.5×10²×0.8=40 cm². Triangle area = 0.5×10²×sin(0.8)≈35.8678 cm². Minor segment = 40−35.8678≈4.13 cm².'
 ELSE
   'Sector area = 0.5×6²×2.2=39.6 cm². Triangle area = 0.5×6²×sin(2.2)≈14.5529 cm². Minor segment = 39.6−14.5529≈25.05 cm².'
 END,
 q.image_url,false,
 CASE s.old_question WHEN 7154 THEN
  'Сектор имеет радиус 10 см и центральный угол 0,8 радиана. Найдите площадь меньшего сегмента между хордой и дугой с точностью до 2 знаков после запятой.'
 ELSE
  'Сектор имеет радиус 6 см и центральный угол 2,2 радиана. Найдите площадь меньшего сегмента между хордой и дугой. Ответ дайте в см² с точностью до 2 знаков после запятой.' END,
 CASE s.old_question WHEN 7154 THEN
  'Sektor radiusi 10 cm, markaziy burchagi 0.8 radian. Vatar va yoy orasidagi kichik segment yuzini 2 ta o‘nli xonagacha toping.'
 ELSE
  'Sektor radiusi 6 cm, markaziy burchagi 2.2 radian. Vatar va yoy orasidagi kichik segment yuzini cm² da 2 ta o‘nli xonagacha toping.' END,
 CASE s.old_question WHEN 7154 THEN
  'A sector has radius 10 cm and central angle 0.8 radians. Calculate the area of the minor segment between the chord and the arc, to 2 decimal places.'
 ELSE
  'A sector has radius 6 cm and central angle 2.2 radians. Calculate the area of the minor segment between the chord and the arc. Enter your answer in cm² to 2 decimal places.' END,
 CASE s.old_question WHEN 7154 THEN
  '["4,13 см²","16 см²","35,87 см²","40 см²"]' ELSE '[]' END,
 CASE s.old_question WHEN 7154 THEN
  '["4.13 cm²","16 cm²","35.87 cm²","40 cm²"]' ELSE '[]' END,
 CASE s.old_question WHEN 7154 THEN
  '["4.13 cm²","16 cm²","35.87 cm²","40 cm²"]' ELSE '[]' END,
 CASE s.old_question WHEN 7154 THEN
  'Площадь сектора = 0,5×10²×0,8=40 см². Площадь треугольника = 0,5×10²×sin(0,8)≈35,8678 см². Площадь меньшего сегмента ≈4,13 см².'
 ELSE
  'Площадь сектора = 0,5×6²×2,2=39,6 см². Площадь треугольника = 0,5×6²×sin(2,2)≈14,5529 см². Площадь меньшего сегмента ≈25,05 см².' END,
 CASE s.old_question WHEN 7154 THEN
  'Sektor yuzi = 0.5×10²×0.8=40 cm². Uchburchak yuzi = 0.5×10²×sin(0.8)≈35.8678 cm². Kichik segment yuzi ≈4.13 cm².'
 ELSE
  'Sektor yuzi = 0.5×6²×2.2=39.6 cm². Uchburchak yuzi = 0.5×6²×sin(2.2)≈14.5529 cm². Kichik segment yuzi ≈25.05 cm².' END,
 CASE s.old_question WHEN 7154 THEN
  'Sector area = 0.5×10²×0.8=40 cm². Triangle area = 0.5×10²×sin(0.8)≈35.8678 cm². Minor segment = 40−35.8678≈4.13 cm².'
 ELSE
  'Sector area = 0.5×6²×2.2=39.6 cm². Triangle area = 0.5×6²×sin(2.2)≈14.5529 cm². Minor segment = 39.6−14.5529≈25.05 cm².' END,
 q.book_ref||':math-review-20261030',q.time_limit_sec,q.quality_flag,'draft'
 FROM _math_second_pass s JOIN public.questions q ON q.id=s.old_question
 ORDER BY s.old_question
 RETURNING id,book_ref
)
UPDATE _math_second_pass s SET new_question=new_q.id
FROM public.questions old_q, inserted new_q
WHERE old_q.id=s.old_question AND
 new_q.book_ref=old_q.book_ref||':math-review-20261030';

INSERT INTO private.exam_prep_question_content_meta
(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
 reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,
 official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,
 qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5,
 approved_at,published_at,rejection_reason,created_at,updated_at)
SELECT m.content_version_id,s.replacement_key,s.new_question,
 m.primary_skill_code,m.secondary_skill_codes,m.reserve_role,
 'withheld','draft',m.originality_attestation,
 '2026-10-30 owner-requested AI-assisted second-pass math correction; old question '||
 s.old_question::text||' immutable; no independent human approval.',
 m.official_scope_ref,m.coursebook_mapping_ref,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
  q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
  coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
  coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
  coalesce(q.image_url,''),coalesce(q.is_active::text,''),
  coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
  coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
  coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
  coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
  coalesce(q.quality_flag,''),coalesce(q.quality_status,''))),
 NULL,NULL,NULL,now(),now()
FROM _math_second_pass s
JOIN private.exam_prep_question_content_meta m ON m.id=s.source_meta
JOIN public.questions q ON q.id=s.new_question;

INSERT INTO private.exam_prep_assessments
 (content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
 title_en,title_ru,title_uz,created_at,approved_at)
SELECT content_version_id,assessment_key,'v3',component_code,assessment_type,'draft',
 title_en,title_ru,title_uz,now(),NULL
FROM private.exam_prep_assessments WHERE id=464;

INSERT INTO private.exam_prep_assessment_items
 (assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,created_at)
SELECT
 (SELECT id FROM private.exam_prep_assessments
  WHERE content_version_id=4813 AND assessment_key='P1-CIR-03-learning-alt-03' AND assessment_version='v3'),
 i.item_order,coalesce((SELECT s.new_question FROM _math_second_pass s WHERE s.old_question=i.question_id),i.question_id),
 i.written_task_id,i.primary_skill_code,i.reserve_role,i.is_holdout,now()
FROM private.exam_prep_assessment_items i WHERE i.assessment_id=464 ORDER BY i.item_order;

DO $post$
DECLARE v_new_ass bigint;
BEGIN
 SELECT id INTO STRICT v_new_ass FROM private.exam_prep_assessments
 WHERE content_version_id=4813 AND assessment_key='P1-CIR-03-learning-alt-03' AND assessment_version='v3';
 IF (SELECT count(*) FROM _math_second_pass WHERE new_question IS NOT NULL)<>2
 OR (SELECT count(*) FROM private.exam_prep_question_content_meta m JOIN _math_second_pass s ON m.question_id=s.new_question
     WHERE m.lifecycle_state='draft' AND m.qa_math_status='pending')<>2
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=v_new_ass)<>4
 OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=v_new_ass AND written_task_id=286)<>1
 OR (SELECT count(*) FROM private.exam_prep_assessment_items i JOIN _math_second_pass s ON i.question_id=s.new_question
     WHERE i.assessment_id=v_new_ass)<>2
 OR EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=v_new_ass)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items si JOIN _math_second_pass s ON si.question_id=s.new_question)
 THEN RAISE EXCEPTION 'MATH_SECOND_PASS_CLONE_FAILED';END IF;
END $post$;
SELECT 'STAGED' AS release,s.old_question,s.new_question,s.replacement_key,
(SELECT id FROM private.exam_prep_assessments
 WHERE content_version_id=4813 AND assessment_key='P1-CIR-03-learning-alt-03' AND assessment_version='v3') AS new_assessment
FROM _math_second_pass s ORDER BY s.old_question;
COMMIT;
