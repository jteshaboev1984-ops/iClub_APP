-- One-time versioned localization correction in P5 Paper 02.
-- Does not edit original versions, attempts, marks, timed contract, or progress.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='70s';
SELECT pg_advisory_xact_lock(611031528035);
DO $guard$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE id=232 AND task_version='wtv2' AND lifecycle_state='published' AND self_review_uz LIKE '%inverse-normal%')
 THEN RAISE EXCEPTION 'P5FP02_current_written_source_changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=375 AND assessment_version='av2' AND status='published' AND assessment_key='p5_stage4_full_paper_02')
 THEN RAISE EXCEPTION 'P5FP02_current_assessment_changed'; END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks n JOIN private.exam_prep_written_tasks o ON o.id=232 AND n.task_key=o.task_key AND n.content_version_id=o.content_version_id AND n.task_version='wtv3')
 OR EXISTS(SELECT 1 FROM private.exam_prep_assessments n JOIN private.exam_prep_assessments o ON o.id=375 AND n.assessment_key=o.assessment_key AND n.content_version_id=o.content_version_id AND n.assessment_version='av3')
 THEN RAISE EXCEPTION 'P5FP02_next_version_exists'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=375)<>7
 OR(SELECT count(*) FROM private.exam_prep_timed_assessment_items WHERE assessment_id=375)<>7
 OR(SELECT count(*) FROM private.exam_prep_timed_assessment_contracts WHERE assessment_id=375 AND status='published')<>1
 THEN RAISE EXCEPTION 'P5FP02_timed_source_changed';END IF;
END $guard$;
CREATE TEMP TABLE _p5_inverse_fix(new_task_id bigint,new_assessment_id bigint) ON COMMIT DROP;
INSERT INTO _p5_inverse_fix VALUES(null,null);
WITH n AS (
INSERT INTO private.exam_prep_written_tasks
(content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
SELECT content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,'wtv3',
prompt_en,prompt_ru,replace(prompt_uz,'4 ta kasr xonasigacha','4 ta o‘nli xonagacha'),
rubric_json,self_review_en,self_review_ru,
'Teskari normal taqsimotga oid ikkita shartdan mu va sigma uchun ikkita chiziqli tenglama tuzing; z ishoralarini to‘g‘ri tanlagandan keyingina simmetriyadan foydalaning.',
'draft','pending','pending','pending','pending',now(),null
FROM private.exam_prep_written_tasks WHERE id=232 RETURNING id
)
UPDATE _p5_inverse_fix SET new_task_id=(SELECT id FROM n);
INSERT INTO private.exam_prep_written_criteria_locale_v1
(written_task_id,task_version,criterion_id,language,source_rule_md5,translated_rule,review_state,academic_review_ref,language_review_ref,reviewed_at)
SELECT m.new_task_id,'wtv3',l.criterion_id,l.language,l.source_rule_md5,l.translated_rule,'draft',null,null,null
FROM _p5_inverse_fix m JOIN private.exam_prep_written_criteria_locale_v1 l ON l.written_task_id=232 AND l.task_version='wtv2' AND l.review_state='approved';
WITH n AS(
INSERT INTO private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz,created_at,approved_at)
SELECT content_version_id,assessment_key,'av3',component_code,assessment_type,'draft',title_en,title_ru,title_uz,now(),null FROM private.exam_prep_assessments WHERE id=375 RETURNING id
)
UPDATE _p5_inverse_fix SET new_assessment_id=(SELECT id FROM n);
INSERT INTO private.exam_prep_assessment_items
(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,created_at)
SELECT m.new_assessment_id,i.item_order,i.question_id,CASE WHEN i.written_task_id=232 THEN m.new_task_id ELSE i.written_task_id END,
i.primary_skill_code,i.reserve_role,i.is_holdout,now()
FROM private.exam_prep_assessment_items i CROSS JOIN _p5_inverse_fix m WHERE i.assessment_id=375 ORDER BY i.item_order;
INSERT INTO private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks,created_at)
SELECT m.new_assessment_id,i.item_order,i.max_marks,now()
FROM private.exam_prep_timed_assessment_items i CROSS JOIN _p5_inverse_fix m WHERE i.assessment_id=375 ORDER BY i.item_order;
INSERT INTO private.exam_prep_timed_assessment_contracts
(assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,strict_timing,comparison_scope,comparability_key,status,created_at,published_at,min_operational_stage)
SELECT m.new_assessment_id,c.paper_profile_id,regexp_replace(c.contract_version,'v2$','v3'),c.attempt_kind,c.timing_rule,c.marks_available,c.fixed_time_limit_sec,c.strict_timing,c.comparison_scope,
regexp_replace(c.comparability_key,'-v2$','-v3'),'draft',now(),null,c.min_operational_stage
FROM private.exam_prep_timed_assessment_contracts c CROSS JOIN _p5_inverse_fix m WHERE c.assessment_id=375;
DO $validate$ DECLARE bad int;BEGIN
 IF (SELECT count(*) FROM private.exam_prep_assessment_items i JOIN _p5_inverse_fix m ON i.assessment_id=m.new_assessment_id)<>7
 OR(SELECT count(*) FROM private.exam_prep_timed_assessment_items i JOIN _p5_inverse_fix m ON i.assessment_id=m.new_assessment_id)<>7 THEN RAISE EXCEPTION 'P5FP02_new_paper_mismatch';END IF;
 SELECT count(*) INTO bad FROM private.exam_prep_assessment_items oi CROSS JOIN _p5_inverse_fix m
 LEFT JOIN private.exam_prep_assessment_items ni ON ni.assessment_id=m.new_assessment_id AND ni.item_order=oi.item_order
 WHERE oi.assessment_id=375 AND
(ni.assessment_id IS NULL OR ni.question_id IS DISTINCT FROM oi.question_id OR ni.reserve_role IS DISTINCT FROM oi.reserve_role OR ni.is_holdout IS DISTINCT FROM oi.is_holdout OR ni.primary_skill_code IS DISTINCT FROM oi.primary_skill_code OR ni.written_task_id IS DISTINCT FROM CASE WHEN oi.written_task_id=232 THEN m.new_task_id ELSE oi.written_task_id END);
 IF bad<>0 THEN RAISE EXCEPTION 'P5FP02_paper_item_drift=%',bad;END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks new JOIN _p5_inverse_fix m ON m.new_task_id=new.id JOIN private.exam_prep_written_tasks old ON old.id=232 WHERE new.prompt_en IS DISTINCT FROM old.prompt_en OR new.self_review_en IS DISTINCT FROM old.self_review_en OR new.rubric_json IS DISTINCT FROM old.rubric_json) THEN RAISE EXCEPTION 'P5FP02_academic_drift';END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions s JOIN _p5_inverse_fix m ON m.new_assessment_id=s.assessment_id) THEN RAISE EXCEPTION 'P5FP02_session_modified';END IF;
END $validate$;
UPDATE private.exam_prep_written_criteria_locale_v1 SET review_state='approved',
academic_review_ref='OWNER_DIRECTED_AI_ASSISTED_CORRECTION_REVIEW_2026-10-28',
language_review_ref='OWNER_DIRECTED_AI_ASSISTED_CORRECTION_REVIEW_2026-10-28',reviewed_at=now()
WHERE written_task_id=(SELECT new_task_id FROM _p5_inverse_fix) AND review_state='draft';
UPDATE private.exam_prep_written_tasks SET lifecycle_state='published',copyright_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',approved_at=now()
WHERE id=(SELECT new_task_id FROM _p5_inverse_fix) AND lifecycle_state='draft';
UPDATE private.exam_prep_assessments SET status='published',approved_at=now()
WHERE id=(SELECT new_assessment_id FROM _p5_inverse_fix) AND status='draft';
UPDATE private.exam_prep_timed_assessment_contracts SET status='published',published_at=now()
WHERE assessment_id=(SELECT new_assessment_id FROM _p5_inverse_fix) AND status='draft';
SELECT * FROM _p5_inverse_fix;
COMMIT;