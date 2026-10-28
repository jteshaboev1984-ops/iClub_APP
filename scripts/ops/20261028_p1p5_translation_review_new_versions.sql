-- iClub P1/P5 translation_review.xlsx (148 flags) — targeted versioned learning repairs.
-- Never update locked approved locale records or existing student records.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='100s';
SELECT pg_advisory_xact_lock(611031528031);

CREATE TEMP TABLE _review_20261028 (
 old_task_id bigint PRIMARY KEY,
 old_assessment_id bigint NOT NULL UNIQUE,
 new_task_id bigint,
 new_assessment_id bigint
) ON COMMIT DROP;
INSERT INTO _review_20261028(old_task_id,old_assessment_id) VALUES
(1,2),(182,378),(156,352),(199,395),(174,370),(175,371),(170,366),
(165,361),(15604,35204),(15606,35206),(15632,35381),
(15647,35430),(15659,35478),(158,354),(176,372),(166,362);

DO $pre$ BEGIN
 IF (SELECT count(*) FROM _review_20261028 m JOIN private.exam_prep_written_tasks t ON t.id=m.old_task_id WHERE t.lifecycle_state='published')<>16
 THEN RAISE EXCEPTION 'review_source_tasks_changed'; END IF;
 IF (SELECT count(*) FROM _review_20261028 m JOIN private.exam_prep_assessments a ON a.id=m.old_assessment_id WHERE a.status='published' AND a.assessment_type='learning')<>16
 THEN RAISE EXCEPTION 'review_source_assessments_changed'; END IF;
 IF EXISTS (
 SELECT 1 FROM _review_20261028 m JOIN private.exam_prep_written_tasks o ON o.id=m.old_task_id
 JOIN private.exam_prep_written_tasks n ON n.task_key=o.task_key AND n.content_version_id=o.content_version_id
 AND n.task_version=CASE o.task_version WHEN 'wtv1' THEN 'wtv2' WHEN 'wtv2' THEN 'wtv3' WHEN 'v1' THEN 'v2' ELSE 'invalid' END
 ) THEN RAISE EXCEPTION 'review_task_version_collision'; END IF;
 IF EXISTS (
 SELECT 1 FROM _review_20261028 m JOIN private.exam_prep_assessments o ON o.id=m.old_assessment_id
 JOIN private.exam_prep_assessments n ON n.assessment_key=o.assessment_key AND n.content_version_id=o.content_version_id
 AND n.assessment_version=CASE o.assessment_version WHEN 'av1' THEN 'av2' WHEN 'av2' THEN 'av3' WHEN 'v1' THEN 'v2' ELSE 'invalid' END
 ) THEN RAISE EXCEPTION 'review_assessment_version_collision'; END IF;
 IF EXISTS (
 SELECT 1 FROM _review_20261028 m JOIN private.exam_prep_assessment_items i ON i.assessment_id=m.old_assessment_id
 WHERE i.written_task_id=m.old_task_id AND i.reserve_role<>'written'
 ) THEN RAISE EXCEPTION 'original_reserve_role_changed'; END IF;
 IF (SELECT count(*) FROM _review_20261028 m JOIN private.exam_prep_assessment_items i ON i.assessment_id=m.old_assessment_id AND i.written_task_id=m.old_task_id)<>16
 THEN RAISE EXCEPTION 'source_task_membership_changed'; END IF;
END $pre$;

WITH cloned AS (
INSERT INTO private.exam_prep_written_tasks
(content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
SELECT o.content_version_id,o.task_key,o.component_code,o.primary_skill_code,o.secondary_skill_codes,
CASE o.task_version WHEN 'wtv1' THEN 'wtv2' WHEN 'wtv2' THEN 'wtv3' WHEN 'v1' THEN 'v2' END,
o.prompt_en,
CASE o.id WHEN 165 THEN replace(o.prompt_ru,'до 1 знака','до 1 знака после запятой') ELSE o.prompt_ru END,
CASE o.id
 WHEN 158 THEN replace(replace(o.prompt_uz,'Qarama-qarshi hodisa','To‘ldiruvchi hodisa'),'tartibni hisobga olmaydigan guruhlashlardan','kombinatsiyalardan')
 WHEN 165 THEN replace(o.prompt_uz,'1 xonagacha','1 ta o‘nli xonagacha')
 WHEN 176 THEN replace(o.prompt_uz,'4 xonagacha','4 ta o‘nli xonagacha')
 ELSE o.prompt_uz END,
o.rubric_json,o.self_review_en,
CASE o.id
 WHEN 166 THEN 'Сначала примените поправку на непрерывность к целочисленным границам, затем вычислите z. Это предотвращает типичные ошибки на одну единицу в границах.'
 ELSE o.self_review_ru END,
o.self_review_uz,
'draft','pending','pending','pending','pending',now(),null
FROM private.exam_prep_written_tasks o JOIN _review_20261028 m ON m.old_task_id=o.id
ORDER BY o.id
RETURNING id,content_version_id,task_key)
UPDATE _review_20261028 m SET new_task_id=n.id
FROM private.exam_prep_written_tasks old,cloned n
WHERE old.id=m.old_task_id AND old.content_version_id=n.content_version_id AND old.task_key=n.task_key;

DO $v$ BEGIN IF (SELECT count(*) FROM _review_20261028 WHERE new_task_id IS NOT NULL)<>16
 THEN RAISE EXCEPTION 'incomplete_new_tasks'; END IF; END $v$;

INSERT INTO private.exam_prep_written_criteria_locale_v1
(written_task_id,task_version,criterion_id,language,source_rule_md5,translated_rule,review_state,academic_review_ref,language_review_ref,reviewed_at)
SELECT m.new_task_id,n.task_version,loc.criterion_id,loc.language,loc.source_rule_md5,loc.translated_rule,'draft',null,null,null
FROM _review_20261028 m JOIN private.exam_prep_written_tasks n ON n.id=m.new_task_id
JOIN private.exam_prep_written_tasks old ON old.id=m.old_task_id
JOIN private.exam_prep_written_criteria_locale_v1 loc
 ON loc.written_task_id=old.id AND loc.task_version=old.task_version AND loc.review_state='approved';

CREATE TEMP TABLE _review_criteria_fixes(old_task_id bigint,criterion_id text,language text,new_rule text) ON COMMIT DROP;
INSERT INTO _review_criteria_fixes VALUES
(1,'features','uz','Taqqoslash uchun ikkita mos xususiyatni ko‘rsatadi: mediana, kvartillararo kenglik, variatsiya kengligi yoki chet qiymatlar.'),
(182,'perp_gradient','ru','Использует отрицательную обратную величину −1/2 и указывает, что произведение угловых коэффициентов равно −1.'),
(156,'completeness','ru','Показывает, что 2 исхода монеты × 4 исхода спиннера = 8 исходов.'),
(199,'iqr','uz','Kvartillararo kenglikni IQR=39−18=21 deb hisoblaydi.'),
(174,'box_structure','ru','Верно указывает ящики A:14–26 с медианой 20 и B:17–31 с медианой 22 и заданные концы усов.'),
(175,'at_least_blue','uz','To‘ldiruvchi hodisa orqali 1−5/14=9/14 ni yoki ko‘k jeton qatnashgan shoxlar ehtimollari yig‘indisini topadi.'),
(175,'at_least_blue','ru','Использует дополнение 1−5/14=9/14 или эквивалентную сумму ветвей с синей фишкой.'),
(170,'first_chain','ru','По правилу дифференцирования сложной функции получает 30(3x−1)^4.'),
(165,'central_z','uz','Har biri 10% li dumlar uchun z=+-1.2816 dan foydalanadi.'),
(15604,'one_one_inverse','uz','x>=0 da g ning o‘zaro bir qiymatli (inyektiv) ekanini tushuntirib, g^-1(x)=sqrt(x), x>=0 ni topadi.'),
(15606,'features','uz','Mediana, kvartillararo kenglik (IQR), variatsiya kengligi yoki chet qiymatlar kabi ikkita tegishli xususiyatni aniqlaydi.'),
(15632,'median','uz','B medianasi yuqoriroq ekanini ko‘rsatadi: 26 (A da esa 24).'),
(15647,'multiplyadd','ru','Правильно перемножает вероятности вдоль ветвей и складывает вероятности несовместных путей.'),
(15659,'accuracy','uz','So‘ralgan ehtimollarni 4 ta o‘nli xonagacha to‘g‘ri hisoblaydi.');

UPDATE private.exam_prep_written_criteria_locale_v1 l
SET translated_rule=f.new_rule
FROM _review_criteria_fixes f
JOIN _review_20261028 m ON m.old_task_id=f.old_task_id
JOIN private.exam_prep_written_tasks n ON n.id=m.new_task_id
WHERE l.written_task_id=n.id AND l.task_version=n.task_version
 AND l.criterion_id=f.criterion_id AND l.language=f.language
 AND l.review_state='draft';

DO $v$ BEGIN
 IF (SELECT count(*) FROM _review_criteria_fixes f
 JOIN _review_20261028 m ON m.old_task_id=f.old_task_id
 JOIN private.exam_prep_written_tasks n ON n.id=m.new_task_id
 JOIN private.exam_prep_written_criteria_locale_v1 l ON l.written_task_id=n.id AND l.task_version=n.task_version AND l.criterion_id=f.criterion_id AND l.language=f.language AND l.translated_rule=f.new_rule)<>14
 THEN RAISE EXCEPTION 'incomplete_criterion_corrections'; END IF;
END $v$;

-- Copy only CURRENT published understanding checks; retired historical versions remain retired in their original records.
INSERT INTO private.exam_prep_written_understanding_checks
(written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
SELECT m.new_task_id,c.check_order,c.check_version,c.check_kind,c.prompt_en,c.prompt_ru,c.prompt_uz,c.options_en,c.options_ru,c.options_uz,c.correct_index,c.rationale_en,c.rationale_ru,c.rationale_uz,
'draft','pending','pending','pending',now(),null
FROM _review_20261028 m
JOIN private.exam_prep_written_understanding_checks c ON c.written_task_id=m.old_task_id AND c.lifecycle_state='published'
ORDER BY m.old_task_id,c.check_order;

WITH cloned AS(
INSERT INTO private.exam_prep_assessments
(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz,created_at,approved_at)
SELECT a.content_version_id,a.assessment_key,
CASE a.assessment_version WHEN 'av1' THEN 'av2' WHEN 'av2' THEN 'av3' WHEN 'v1' THEN 'v2' END,
a.component_code,a.assessment_type,'draft',a.title_en,a.title_ru,a.title_uz,now(),null
FROM private.exam_prep_assessments a JOIN _review_20261028 m ON m.old_assessment_id=a.id
ORDER BY a.id
RETURNING id,content_version_id,assessment_key)
UPDATE _review_20261028 m SET new_assessment_id=n.id
FROM private.exam_prep_assessments old,cloned n
WHERE old.id=m.old_assessment_id AND old.content_version_id=n.content_version_id AND old.assessment_key=n.assessment_key;

DO $v$ BEGIN IF (SELECT count(*) FROM _review_20261028 WHERE new_assessment_id IS NOT NULL)<>16
 THEN RAISE EXCEPTION 'incomplete_new_assessments'; END IF; END $v$;

INSERT INTO private.exam_prep_assessment_items
(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,created_at)
SELECT m.new_assessment_id,i.item_order,i.question_id,
 CASE WHEN i.written_task_id=m.old_task_id THEN m.new_task_id ELSE i.written_task_id END,
 i.primary_skill_code,i.reserve_role,i.is_holdout,now()
FROM _review_20261028 m JOIN private.exam_prep_assessment_items i ON i.assessment_id=m.old_assessment_id
ORDER BY m.old_assessment_id,i.item_order;

DO $verify$
DECLARE v_mismatch int;
BEGIN
 IF EXISTS(SELECT 1 FROM _review_20261028 m JOIN private.exam_prep_written_tasks o ON o.id=m.old_task_id JOIN private.exam_prep_written_tasks n ON n.id=m.new_task_id
 WHERE o.prompt_en IS DISTINCT FROM n.prompt_en OR o.self_review_en IS DISTINCT FROM n.self_review_en
 OR o.rubric_json IS DISTINCT FROM n.rubric_json OR o.content_version_id IS DISTINCT FROM n.content_version_id OR n.lifecycle_state<>'draft') THEN
 RAISE EXCEPTION 'english_or_rubric_drift'; END IF;

 SELECT count(*) INTO v_mismatch FROM _review_20261028 m
 JOIN private.exam_prep_assessment_items old ON old.assessment_id=m.old_assessment_id
 LEFT JOIN private.exam_prep_assessment_items new ON new.assessment_id=m.new_assessment_id AND new.item_order=old.item_order
 WHERE new.assessment_id IS NULL OR new.question_id IS DISTINCT FROM old.question_id
 OR new.written_task_id IS DISTINCT FROM CASE WHEN old.written_task_id=m.old_task_id THEN m.new_task_id ELSE old.written_task_id END
 OR new.reserve_role IS DISTINCT FROM old.reserve_role OR new.is_holdout IS DISTINCT FROM old.is_holdout
 OR new.primary_skill_code IS DISTINCT FROM old.primary_skill_code;
 IF v_mismatch<>0 THEN RAISE EXCEPTION 'assessment_item_drift=%',v_mismatch; END IF;
 IF EXISTS(SELECT 1 FROM _review_20261028 m JOIN private.exam_prep_written_tasks n ON n.id=m.new_task_id CROSS JOIN LATERAL jsonb_array_elements(n.rubric_json->'criteria') c(value)
 LEFT JOIN private.exam_prep_written_criteria_locale_v1 r ON r.written_task_id=n.id AND r.task_version=n.task_version AND r.criterion_id=c.value->>'id' AND r.language='ru'
 LEFT JOIN private.exam_prep_written_criteria_locale_v1 u ON u.written_task_id=n.id AND u.task_version=n.task_version AND u.criterion_id=c.value->>'id' AND u.language='uz'
 WHERE r.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule')
 OR u.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule')
 OR r.translated_rule IS NULL OR u.translated_rule IS NULL)
 THEN RAISE EXCEPTION 'criterion_coverage_or_checksum_mismatch';END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions s JOIN _review_20261028 m ON m.new_assessment_id=s.assessment_id) THEN RAISE EXCEPTION 'student_session_link_to_new_drafts';END IF;
END $verify$;

SELECT old_task_id,new_task_id,old_assessment_id,new_assessment_id
FROM _review_20261028 ORDER BY old_task_id;
COMMIT;