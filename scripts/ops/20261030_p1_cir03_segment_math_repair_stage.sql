-- Correct mathematically inconsistent central-triangle data in two P1-CIR-03 tasks.
-- Versioned DRAFT content only. No existing approved rows, sessions, scores, or flags modified.
-- Academic check: A_triangle=r*r*sin(theta)/2; A_segment=r*r*(theta-sin(theta))/2.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='90s';
SELECT pg_advisory_xact_lock(611031528040);
CREATE TEMP TABLE _segment_repair(
 old_task bigint PRIMARY KEY, old_assessment bigint UNIQUE,
 next_task_version text, next_assessment_version text,
 new_task bigint,new_assessment bigint) ON COMMIT DROP;
INSERT INTO _segment_repair(old_task,old_assessment,next_task_version,next_assessment_version)
VALUES (38,98,'wtv2','av2'),(15638,35421,'v2','v2');

DO $guard$
BEGIN
 IF (SELECT count(*) FROM _segment_repair m
 JOIN private.exam_prep_written_tasks w ON w.id=m.old_task AND w.lifecycle_state='published'
 JOIN private.exam_prep_assessments a ON a.id=m.old_assessment AND a.status='published' AND a.assessment_type='learning'
 JOIN private.exam_prep_assessment_items i ON i.assessment_id=a.id AND i.written_task_id=w.id AND i.reserve_role='written')<>2
 THEN RAISE EXCEPTION 'P1_CIR03_SOURCE_DRIFT'; END IF;
 IF EXISTS(SELECT 1 FROM _segment_repair m JOIN private.exam_prep_written_tasks old ON old.id=m.old_task
 JOIN private.exam_prep_written_tasks newer ON newer.content_version_id=old.content_version_id AND newer.task_key=old.task_key AND newer.task_version=m.next_task_version)
 OR EXISTS(SELECT 1 FROM _segment_repair m JOIN private.exam_prep_assessments old ON old.id=m.old_assessment
 JOIN private.exam_prep_assessments newer ON newer.content_version_id=old.content_version_id AND newer.assessment_key=old.assessment_key AND newer.assessment_version=m.next_assessment_version)
 THEN RAISE EXCEPTION 'P1_CIR03_VERSION_EXISTS'; END IF;
END $guard$;

WITH inserted AS(
 INSERT INTO private.exam_prep_written_tasks
 (content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
 SELECT w.content_version_id,w.task_key,w.component_code,w.primary_skill_code,w.secondary_skill_codes,m.next_task_version,
 CASE m.old_task WHEN 38 THEN 'A sector has radius 8 and angle 1.1 radians. (a) Find its area. (b) Use A=1/2 r² sin θ to calculate the area of the triangle between the two radii and the chord, then find the area of the minor segment to 2 decimal places. (c) Remove a concentric inner sector of radius 5 with the same angle; find the remaining annular-sector area. Show the formula used in each part.'
 ELSE 'A sector has radius 9 cm and angle 1.2 radians. (a) Find its area. (b) Use A=1/2 r² sin θ to calculate the triangle area between the two radii and the chord, then find the area of the minor segment to 2 decimal places. (c) Remove a concentric inner sector of radius 5 cm with the same angle; find the remaining annular-sector area. Show the formula used in each part.' END,
 CASE m.old_task WHEN 38 THEN 'Сектор имеет радиус 8 и угол 1,1 радиана. (a) Найдите его площадь. (b) По формуле A=1/2 r² sin θ вычислите площадь треугольника между радиусами и хордой, затем площадь меньшего сегмента с точностью до 2 знаков после запятой. (c) Удаляют концентрический сектор радиуса 5 с тем же углом. Найдите оставшуюся площадь кольцевого сектора. Покажите формулу в каждой части.'
 ELSE 'Сектор имеет радиус 9 см и угол 1,2 радиана. (a) Найдите его площадь. (b) По формуле A=1/2 r² sin θ вычислите площадь треугольника между радиусами и хордой, затем площадь меньшего сегмента с точностью до 2 знаков после запятой. (c) Удаляют концентрический сектор радиуса 5 см с тем же углом. Найдите оставшуюся площадь кольцевого сектора. Покажите формулу в каждой части.' END,
 CASE m.old_task WHEN 38 THEN 'Sektor radiusi 8 va burchagi 1.1 radian. (a) Uning yuzini toping. (b) Ikki radius va vatar orasidagi uchburchak yuzini A=1/2 r² sin θ formulasi orqali hisoblang, so‘ng kichik segment yuzini 2 ta o‘nli xonagacha toping. (c) Shu burchakli radiusi 5 bo‘lgan konsentrik ichki sektor olib tashlanadi. Qolgan halqasimon sektor yuzini toping. Har qismda formulani ko‘rsating.'
 ELSE 'Sektor radiusi 9 cm va burchagi 1.2 radian. (a) Uning yuzini toping. (b) Ikki radius va vatar orasidagi uchburchak yuzini A=1/2 r² sin θ formulasi orqali hisoblang, so‘ng kichik segment yuzini 2 ta o‘nli xonagacha toping. (c) Shu burchakli radiusi 5 cm bo‘lgan konsentrik ichki sektor olib tashlanadi. Qolgan halqasimon sektor yuzini toping. Har qismda formulani ko‘rsating.' END,
 jsonb_set(w.rubric_json,'{criteria}',(
  SELECT jsonb_agg(
   CASE WHEN criterion.value->>'id'='segment' THEN jsonb_set(criterion.value,'{rule}',to_jsonb(
    CASE m.old_task WHEN 38 THEN 'Calculates triangle area 32sin(1.1)≈28.52, then minor segment 35.2−32sin(1.1)≈6.68 (2 d.p.).'
    ELSE 'Calculates triangle area 40.5sin(1.2)≈37.75 cm² and minor segment 48.6−40.5sin(1.2)≈10.85 cm² (2 d.p.).' END::text))
   ELSE criterion.value END ORDER BY criterion.ord)
  FROM jsonb_array_elements(w.rubric_json->'criteria') WITH ORDINALITY criterion(value,ord)),false),
 'Use A_triangle=1/2 r² sin θ and A_segment=1/2 r²(θ−sin θ); an independently supplied triangle area can contradict the given radius and angle.',
 'Используйте A_треугольника=1/2 r² sin θ и A_сегмента=1/2 r²(θ−sin θ).',
 'Uchburchak yuzi A=1/2 r² sin θ, segment yuzi esa A=1/2 r²(θ−sin θ).',
 'draft','pending','pending','pending','pending',now(),NULL
 FROM _segment_repair m JOIN private.exam_prep_written_tasks w ON w.id=m.old_task ORDER BY w.id
 RETURNING id,content_version_id,task_key
)
UPDATE _segment_repair m SET new_task=n.id
FROM private.exam_prep_written_tasks old,inserted n
WHERE old.id=m.old_task AND old.content_version_id=n.content_version_id AND old.task_key=n.task_key;

INSERT INTO private.exam_prep_written_criteria_locale_v1
(written_task_id,task_version,criterion_id,language,source_rule_md5,translated_rule,review_state)
SELECT m.new_task,new.task_version,loc.criterion_id,loc.language,
 CASE WHEN loc.criterion_id='segment' THEN md5((SELECT c.value->>'rule' FROM jsonb_array_elements(new.rubric_json->'criteria') c(value) WHERE c.value->>'id'='segment')) ELSE loc.source_rule_md5 END,
 CASE WHEN loc.criterion_id='segment' AND loc.language='ru' AND m.old_task=38 THEN 'Вычисляет площадь треугольника 32sin(1.1)≈28,52 и площадь меньшего сегмента 35,2−32sin(1.1)≈6,68 (до 2 знаков после запятой).'
 WHEN loc.criterion_id='segment' AND loc.language='uz' AND m.old_task=38 THEN 'Uchburchak yuzi 32sin(1.1)≈28.52 va kichik segment yuzi 35.2−32sin(1.1)≈6.68 (2 ta o‘nli xonagacha) ekanini hisoblaydi.'
 WHEN loc.criterion_id='segment' AND loc.language='ru' AND m.old_task=15638 THEN 'Вычисляет площадь треугольника 40,5sin(1.2)≈37,75 см² и площадь меньшего сегмента 48,6−40,5sin(1.2)≈10,85 см² (до 2 знаков после запятой).'
 WHEN loc.criterion_id='segment' AND loc.language='uz' AND m.old_task=15638 THEN 'Uchburchak yuzi 40.5sin(1.2)≈37.75 cm² va kichik segment yuzi 48.6−40.5sin(1.2)≈10.85 cm² (2 ta o‘nli xonagacha) ekanini hisoblaydi.'
 ELSE loc.translated_rule END,'draft'
FROM _segment_repair m
JOIN private.exam_prep_written_tasks old ON old.id=m.old_task
JOIN private.exam_prep_written_tasks new ON new.id=m.new_task
JOIN private.exam_prep_written_criteria_locale_v1 loc
 ON loc.written_task_id=old.id AND loc.task_version=old.task_version AND loc.review_state='approved';

INSERT INTO private.exam_prep_written_understanding_checks
(written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,created_at,approved_at)
SELECT m.new_task,c.check_order,c.check_version,c.check_kind,c.prompt_en,c.prompt_ru,c.prompt_uz,c.options_en,c.options_ru,c.options_uz,c.correct_index,c.rationale_en,c.rationale_ru,c.rationale_uz,'draft','pending','pending','pending',now(),NULL
FROM _segment_repair m
JOIN private.exam_prep_written_understanding_checks c ON c.written_task_id=m.old_task AND c.lifecycle_state='published';

WITH inserted AS(
 INSERT INTO private.exam_prep_assessments
 (content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz,created_at,approved_at)
 SELECT a.content_version_id,a.assessment_key,m.next_assessment_version,a.component_code,a.assessment_type,'draft',a.title_en,a.title_ru,a.title_uz,now(),NULL
 FROM _segment_repair m JOIN private.exam_prep_assessments a ON a.id=m.old_assessment ORDER BY a.id
 RETURNING id,content_version_id,assessment_key
)
UPDATE _segment_repair m SET new_assessment=n.id
FROM private.exam_prep_assessments old,inserted n
WHERE old.id=m.old_assessment AND old.content_version_id=n.content_version_id AND old.assessment_key=n.assessment_key;

INSERT INTO private.exam_prep_assessment_items
(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,created_at)
SELECT m.new_assessment,i.item_order,i.question_id,
 CASE WHEN i.written_task_id=m.old_task THEN m.new_task ELSE i.written_task_id END,
 i.primary_skill_code,i.reserve_role,i.is_holdout,now()
FROM _segment_repair m JOIN private.exam_prep_assessment_items i
ON i.assessment_id=m.old_assessment ORDER BY m.old_task,i.item_order;

DO $verify$
DECLARE m record; bad integer; total integer;
BEGIN
 FOR m IN SELECT * FROM _segment_repair LOOP
  IF m.new_task IS NULL OR m.new_assessment IS NULL
  OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=m.new_assessment)<>4
  OR (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=m.new_assessment AND written_task_id=m.new_task)<>1
  THEN RAISE EXCEPTION 'P1_CIR03_CLONE_INCOMPLETE_%',m.old_task; END IF;
  SELECT sum((c.value->>'marks')::integer) INTO total
  FROM private.exam_prep_written_tasks w CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
  WHERE w.id=m.new_task;
  IF (m.old_task=38 AND total<>10) OR (m.old_task=15638 AND total<>6)
  THEN RAISE EXCEPTION 'P1_CIR03_MARKS_CHANGED_%',m.old_task; END IF;
  SELECT count(*) INTO bad
  FROM private.exam_prep_written_tasks w CROSS JOIN LATERAL jsonb_array_elements(w.rubric_json->'criteria') c(value)
  CROSS JOIN (VALUES('ru'::text),('uz'::text)) lg(code)
  LEFT JOIN private.exam_prep_written_criteria_locale_v1 loc
    ON loc.written_task_id=w.id AND loc.task_version=w.task_version
    AND loc.criterion_id=c.value->>'id' AND loc.language=lg.code
  WHERE w.id=m.new_task
    AND (loc.source_rule_md5 IS DISTINCT FROM md5(c.value->>'rule') OR loc.translated_rule IS NULL);
  IF bad<>0 THEN RAISE EXCEPTION 'P1_CIR03_LOCALE_MISMATCH_%',m.old_task; END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE assessment_id=m.new_assessment)
  OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE written_task_id=m.new_task)
  THEN RAISE EXCEPTION 'P1_CIR03_LEARNER_SESSION_ADDED_%',m.old_task; END IF;
 END LOOP;
END $verify$;
SELECT 'STAGED_DRAFT' status,old_task,new_task,old_assessment,new_assessment
FROM _segment_repair ORDER BY old_task;
COMMIT;
