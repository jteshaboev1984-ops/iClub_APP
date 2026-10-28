-- iClub translation_review.xlsx: versioned criterion fixes inside timed and full paper assessments.
-- Task 121 is published as 229/wtv2; use 229 as source for wtv3 (NOT task 121/wtv1).
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='85s';
SELECT pg_advisory_xact_lock(611031528033);

CREATE TEMP TABLE _paper_fix(old_task bigint PRIMARY KEY,old_ass bigint UNIQUE,new_task bigint,new_ass bigint) ON COMMIT DROP;
INSERT INTO _paper_fix(old_task,old_ass) VALUES(90,373),(229,411),(123,392),(141,393);
DO $pre$ BEGIN
 IF (SELECT count(*) FROM _paper_fix f JOIN private.exam_prep_written_tasks o ON o.id=f.old_task WHERE o.lifecycle_state='published')<>4
 OR (SELECT count(*) FROM _paper_fix f JOIN private.exam_prep_assessments a ON a.id=f.old_ass WHERE a.status='published' AND a.assessment_type IN('paper','timed'))<>4
 THEN RAISE EXCEPTION 'paper_source_changed'; END IF;
 IF EXISTS(SELECT 1 FROM _paper_fix f JOIN private.exam_prep_written_tasks o ON o.id=f.old_task JOIN private.exam_prep_written_tasks n ON n.task_key=o.task_key AND n.content_version_id=o.content_version_id AND n.task_version=CASE WHEN o.task_version='wtv2' THEN 'wtv3' ELSE 'wtv2' END)
 THEN RAISE EXCEPTION 'paper_task_version_collision'; END IF;
 IF EXISTS(SELECT 1 FROM _paper_fix f JOIN private.exam_prep_assessments o ON o.id=f.old_ass JOIN private.exam_prep_assessments n ON n.assessment_key=o.assessment_key AND n.content_version_id=o.content_version_id AND n.assessment_version='av3')
 THEN RAISE EXCEPTION 'paper_assessment_version_collision'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_assessment_items ai JOIN _paper_fix f ON f.old_ass=ai.assessment_id)<>30
 OR (SELECT count(*) FROM private.exam_prep_timed_assessment_items ti JOIN _paper_fix f ON f.old_ass=ti.assessment_id)<>30
 OR (SELECT count(*) FROM private.exam_prep_timed_assessment_contracts tc JOIN _paper_fix f ON f.old_ass=tc.assessment_id AND tc.status='published')<>4
 THEN RAISE EXCEPTION 'timed_source_membership_changed'; END IF;
END $pre$;

WITH cloned AS(
INSERT INTO private.exam_prep_written_tasks
(content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
SELECT o.content_version_id,o.task_key,o.component_code,o.primary_skill_code,o.secondary_skill_codes,
CASE WHEN o.task_version='wtv2' THEN 'wtv3' ELSE 'wtv2' END,
o.prompt_en,o.prompt_ru,o.prompt_uz,o.rubric_json,o.self_review_en,o.self_review_ru,o.self_review_uz,
'draft','pending','pending','pending','pending',now(),null
FROM private.exam_prep_written_tasks o JOIN _paper_fix f ON f.old_task=o.id
ORDER BY o.id RETURNING id,content_version_id,task_key)
UPDATE _paper_fix f SET new_task=n.id FROM private.exam_prep_written_tasks o,cloned n WHERE o.id=f.old_task AND o.content_version_id=n.content_version_id AND o.task_key=n.task_key;

DO $m$ BEGIN IF (SELECT count(*) FROM _paper_fix WHERE new_task IS NOT NULL)<>4 THEN RAISE EXCEPTION 'new_paper_task_map_incomplete';END IF;END $m$;

INSERT INTO private.exam_prep_written_criteria_locale_v1
(written_task_id,task_version,criterion_id,language,source_rule_md5,translated_rule,review_state,academic_review_ref,language_review_ref,reviewed_at)
SELECT f.new_task,n.task_version,l.criterion_id,l.language,l.source_rule_md5,l.translated_rule,'draft',null,null,null
FROM _paper_fix f JOIN private.exam_prep_written_tasks o ON o.id=f.old_task
JOIN private.exam_prep_written_tasks n ON n.id=f.new_task
JOIN private.exam_prep_written_criteria_locale_v1 l ON l.written_task_id=o.id AND l.task_version=o.task_version AND l.review_state='approved';

CREATE TEMP TABLE _paper_text(old_task bigint,criterion text,language text,new_rule text) ON COMMIT DROP;
INSERT INTO _paper_text VALUES
(90,'interval_probability','uz','Phi(2)-Phi(-1)≈0.8186 ni topadi (4 ta o‘nli xonali jadval ishlatilganda 0.8185 ham qabul qilinadi).'),
(229,'quantile_z','uz','Yig‘ma ehtimol 0.90 uchun z taxminan 1.2816 qiymatdan foydalanadi.'),
(123,'horizontal','uz','Gorizontal yo‘nalishda 1/2 koeffitsiyentli siqilish, so‘ng o‘ngga 2 birlik siljishni yoki unga teng kuchli nuqtalar akslantirilishini ko‘rsatadi.'),
(141,'gradients','ru','Находит угловой коэффициент AB, равный 1, и угловой коэффициент перпендикуляра, равный −1.');

UPDATE private.exam_prep_written_criteria_locale_v1 loc SET translated_rule=t.new_rule
FROM _paper_text t JOIN _paper_fix f ON f.old_task=t.old_task JOIN private.exam_prep_written_tasks n ON n.id=f.new_task
WHERE loc.written_task_id=n.id AND loc.task_version=n.task_version AND loc.criterion_id=t.criterion AND loc.language=t.language AND loc.review_state='draft';
DO $v$ BEGIN
 IF (SELECT count(*) FROM _paper_text t JOIN _paper_fix f ON f.old_task=t.old_task
 JOIN private.exam_prep_written_tasks n ON n.id=f.new_task JOIN private.exam_prep_written_criteria_locale_v1 loc ON loc.written_task_id=n.id AND loc.task_version=n.task_version AND loc.criterion_id=t.criterion AND loc.language=t.language AND loc.translated_rule=t.new_rule)<>4 THEN
 RAISE EXCEPTION 'four_paper_rules_not_corrected';END IF;
END $v$;

INSERT INTO private.exam_prep_written_understanding_checks
(written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
SELECT f.new_task,c.check_order,c.check_version,c.check_kind,c.prompt_en,c.prompt_ru,c.prompt_uz,c.options_en,c.options_ru,c.options_uz,c.correct_index,c.rationale_en,c.rationale_ru,c.rationale_uz,'draft','pending','pending','pending',now(),null
FROM _paper_fix f JOIN private.exam_prep_written_understanding_checks c ON c.written_task_id=f.old_task AND c.lifecycle_state='published'
ORDER BY f.old_task,c.check_order;

WITH cloned AS(
INSERT INTO private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz,created_at,approved_at)
SELECT a.content_version_id,a.assessment_key,'av3',a.component_code,a.assessment_type,'draft',a.title_en,a.title_ru,a.title_uz,now(),null
FROM private.exam_prep_assessments a JOIN _paper_fix f ON f.old_ass=a.id ORDER BY a.id
RETURNING id,content_version_id,assessment_key)
UPDATE _paper_fix f SET new_ass=n.id FROM private.exam_prep_assessments o,cloned n
WHERE o.id=f.old_ass AND o.content_version_id=n.content_version_id AND o.assessment_key=n.assessment_key;
DO $v$ BEGIN IF (SELECT count(*) FROM _paper_fix WHERE new_ass IS NOT NULL)<>4 THEN RAISE EXCEPTION 'new_paper_assessment_map_incomplete';END IF;END $v$;

INSERT INTO private.exam_prep_assessment_items
(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,created_at)
SELECT f.new_ass,i.item_order,i.question_id,
CASE WHEN i.written_task_id=f.old_task THEN f.new_task ELSE i.written_task_id END,
i.primary_skill_code,i.reserve_role,i.is_holdout,now()
FROM _paper_fix f JOIN private.exam_prep_assessment_items i ON i.assessment_id=f.old_ass
ORDER BY f.old_ass,i.item_order;

INSERT INTO private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks,created_at)
SELECT f.new_ass,i.item_order,i.max_marks,now()
FROM _paper_fix f JOIN private.exam_prep_timed_assessment_items i ON i.assessment_id=f.old_ass
ORDER BY f.old_ass,i.item_order;

INSERT INTO private.exam_prep_timed_assessment_contracts
(assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,strict_timing,comparison_scope,comparability_key,status,created_at,published_at,min_operational_stage)
SELECT f.new_ass,c.paper_profile_id,regexp_replace(c.contract_version,'v2$','v3'),c.attempt_kind,c.timing_rule,c.marks_available,c.fixed_time_limit_sec,c.strict_timing,c.comparison_scope,
regexp_replace(c.comparability_key,'-v2$','-v3'),'draft',now(),null,c.min_operational_stage
FROM _paper_fix f JOIN private.exam_prep_timed_assessment_contracts c ON c.assessment_id=f.old_ass;

DO $verify$DECLARE v_bad int;BEGIN
 IF (SELECT count(*) FROM private.exam_prep_assessment_items i JOIN _paper_fix f ON f.new_ass=i.assessment_id)<>30 OR
(SELECT count(*) FROM private.exam_prep_timed_assessment_items i JOIN _paper_fix f ON f.new_ass=i.assessment_id)<>30 OR
(SELECT count(*) FROM private.exam_prep_timed_assessment_contracts c JOIN _paper_fix f ON f.new_ass=c.assessment_id AND c.status='draft')<>4 THEN RAISE EXCEPTION 'new_paper_membership_incomplete';END IF;
SELECT count(*) INTO v_bad FROM _paper_fix f JOIN private.exam_prep_assessment_items o ON o.assessment_id=f.old_ass
LEFT JOIN private.exam_prep_assessment_items n ON n.assessment_id=f.new_ass AND n.item_order=o.item_order
WHERE n.assessment_id IS NULL OR n.question_id IS DISTINCT FROM o.question_id
OR n.written_task_id IS DISTINCT FROM CASE WHEN o.written_task_id=f.old_task THEN f.new_task ELSE o.written_task_id END
OR n.primary_skill_code IS DISTINCT FROM o.primary_skill_code OR n.reserve_role IS DISTINCT FROM o.reserve_role OR n.is_holdout IS DISTINCT FROM o.is_holdout;
IF v_bad<>0 THEN RAISE EXCEPTION 'paper_member_drift=%',v_bad;END IF;
IF EXISTS(SELECT 1 FROM _paper_fix f JOIN private.exam_prep_written_tasks o ON o.id=f.old_task JOIN private.exam_prep_written_tasks n ON n.id=f.new_task WHERE o.prompt_en IS DISTINCT FROM n.prompt_en OR o.self_review_en IS DISTINCT FROM n.self_review_en OR o.rubric_json IS DISTINCT FROM n.rubric_json) THEN RAISE EXCEPTION 'academic_paper_source_modified';END IF;
IF EXISTS(SELECT 1 FROM _paper_fix f JOIN private.exam_prep_written_tasks n ON n.id=f.new_task CROSS JOIN LATERAL jsonb_array_elements(n.rubric_json->'criteria') j(value)
LEFT JOIN private.exam_prep_written_criteria_locale_v1 r ON r.written_task_id=n.id AND r.task_version=n.task_version AND r.criterion_id=j.value->>'id' AND r.language='ru'
LEFT JOIN private.exam_prep_written_criteria_locale_v1 u ON u.written_task_id=n.id AND u.task_version=n.task_version AND u.criterion_id=j.value->>'id' AND u.language='uz'
WHERE r.source_rule_md5 IS DISTINCT FROM md5(j.value->>'rule') OR u.source_rule_md5 IS DISTINCT FROM md5(j.value->>'rule') OR r.translated_rule IS NULL OR u.translated_rule IS NULL)
THEN RAISE EXCEPTION 'paper_locale_checksum_mismatch';END IF;
IF EXISTS(SELECT 1 FROM private.exam_prep_sessions s JOIN _paper_fix f ON s.assessment_id=f.new_ass) THEN RAISE EXCEPTION 'student_session_on_new_paper';END IF;
END $verify$;
SELECT old_task,new_task,old_ass,new_ass FROM _paper_fix ORDER BY old_task;
COMMIT;