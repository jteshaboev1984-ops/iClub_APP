-- Economics 9708: Core criteria-only contract. No worked answers or indicative answer content in the learner RPC.
-- Adopt existing signed-off Written Learning v1.3: learner solves offline, optional assessment criteria, Next = progress only.
-- Personal solution review/verification is not a Core feature; it requires separately active Mentor Care scope.
-- Additive function change only; never rewrite task, source, access, attempt, plan or historical progress.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='40s';

CREATE OR REPLACE FUNCTION public.iclub_exam_written_criteria_v1(
 p_item_id uuid,p_task_key text,p_task_version text,p_task_token uuid,
 p_language text DEFAULT 'en'
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $criteria$
DECLARE
 v_raw jsonb;
 v_scheme jsonb;
 v_program text;
 v_language text;
 v_focus text;
 v_descriptors text[];
 v_max integer;
 v_ao12 integer;
 v_ao3 integer;
 v_style text;
BEGIN
 IF auth.uid() IS NULL THEN
  RETURN jsonb_build_object('ok',false,'code','not_authorized');
 END IF;
 -- The original private Core contract checks active own plan, current step,
 -- version token, release state and prior sequence. Do not bypass it.
 v_raw:=private.iclub_exam_core_written_criteria_v1(
  p_item_id,p_task_key,p_task_version,p_task_token,p_language);
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 i
  WHERE i.id=p_item_id AND i.learner_user_id=auth.uid()
   AND i.task_key=p_task_key AND i.task_version=p_task_version
   AND i.task_token=p_task_token
   AND private.iclub_exam_written_source_ready_v1(
    i.program_key,i.version_key,i.task_key,i.task_version)
 ) THEN RETURN jsonb_build_object('available',false); END IF;
 IF v_raw->>'available'<>'true' THEN RETURN v_raw; END IF;
 SELECT i.program_key INTO v_program
 FROM private.iclub_exam_core_written_plan_items_v1 i
 WHERE i.id=p_item_id AND i.learner_user_id=auth.uid()
   AND i.task_key=p_task_key AND i.task_version=p_task_version
   AND i.task_token=p_task_token;

 -- No behaviour change to Chemistry and any future independent Written Core subject.
 IF v_program<>'economics_9708' THEN RETURN v_raw; END IF;

 -- For Economics require an exact version and checksum-matched private mark allocation.
 SELECT m.max_marks,m.ao12_marks,m.ao3_marks,m.marking_style
 INTO v_max,v_ao12,v_ao3,v_style
 FROM private.iclub_exam_core_written_plan_items_v1 i
 JOIN private.iclub_exam_core_written_tasks_v1 t
  ON t.program_key=i.program_key AND t.version_key=i.version_key
   AND t.task_key=i.task_key AND t.task_version=i.task_version
 JOIN private.iclub_exam_written_mark_scheme_v1 m
  ON m.program_key=t.program_key AND m.version_key=t.version_key
   AND m.task_key=t.task_key AND m.task_version=t.task_version
 WHERE i.id=p_item_id AND i.learner_user_id=auth.uid()
   AND i.task_key=p_task_key AND i.task_version=p_task_version
   AND i.task_token=p_task_token
   AND m.task_sha256=encode(pg_catalog.sha256(
    pg_catalog.convert_to(t.questions::text||'|'||t.answer_requirements::text,'UTF8')),'hex');
 IF NOT FOUND THEN
  RETURN jsonb_build_object('available',false,'code','assessment_criteria_unavailable');
 END IF;

 v_language:=CASE WHEN p_language IN ('ru','uz','en') THEN p_language ELSE 'en' END;
 -- Focus is the SKILL being assessed, not the correct answer; no numerical
 -- result, market movement, economic conclusion or model response is disclosed.
 v_focus:=CASE
  WHEN p_task_key IN ('P2.A.b','P4.A.a') THEN 'calculation'
  WHEN p_task_key IN ('P2.A.a','P2.A.e') THEN 'definition'
  WHEN p_task_key IN ('P2.A.c','P2.C1.a','P4.B1','P4.B2') THEN 'diagram'
  WHEN p_task_key IN ('P2.A.f','P2.B1.b','P2.B2.b','P2.C1.b','P2.C2.b','P4.A.d',
   'P4.C1','P4.C2') THEN 'evaluation'
  ELSE 'analysis'
 END;
 CASE v_language
 WHEN 'ru' THEN
  v_descriptors:=ARRAY[
   'AO1 — точность экономических понятий, определений и терминологии, относящихся к вопросу.',
   'AO2 — применение экономической теории, обоснованность причинно-следственных связей и работа с заданным контекстом.'
  ];
  IF v_ao3>0 THEN
   v_descriptors:=array_append(v_descriptors,
    'AO3 — сопоставление аргументов и ограничений, обоснованный вывод в соответствии с формулировкой вопроса.');
  END IF;
  v_descriptors:=array_append(v_descriptors,CASE v_focus
   WHEN 'calculation' THEN 'Для расчётного вопроса оцениваются выбор данных, последовательность вычислений, единицы измерения и точность результата.'
   WHEN 'definition' THEN 'Для вопроса на понятия оцениваются точность определения, экономический смысл и соответствие вопросу.'
   WHEN 'diagram' THEN 'Если диаграмма уместна, оцениваются экономическая корректность, подписи и связь диаграммы с объяснением.'
   WHEN 'evaluation' THEN 'Для оценочного вопроса важны развитые аргументы, рассмотрение условий и аргументированный итог.'
   ELSE 'Для аналитического вопроса важны последовательность аргументации и корректная интерпретация заданной информации.'
  END);
 WHEN 'uz' THEN
  v_descriptors:=ARRAY[
   'AO1 — savolga tegishli iqtisodiy tushunchalar, ta’riflar va atamalarning aniqligi.',
   'AO2 — iqtisodiy nazariyani qo‘llash, sabab-oqibat bog‘lanishlarini asoslash va berilgan vaziyatni tahlil qilish.'
  ];
  IF v_ao3>0 THEN
   v_descriptors:=array_append(v_descriptors,
    'AO3 — dalillar va cheklovlarni solishtirish, savolga mos asoslangan xulosa chiqarish.');
  END IF;
  v_descriptors:=array_append(v_descriptors,CASE v_focus
   WHEN 'calculation' THEN 'Hisoblashda ma’lumotlarni tanlash, hisoblash ketma-ketligi, o‘lchov birliklari va natijaning aniqligi baholanadi.'
   WHEN 'definition' THEN 'Tushunchaga oid savolda ta’rifning aniqligi, iqtisodiy mazmun va savolga moslik baholanadi.'
   WHEN 'diagram' THEN 'Diagramma o‘rinli bo‘lsa, uning iqtisodiy to‘g‘riligi, belgilari va izohga aloqasi baholanadi.'
   WHEN 'evaluation' THEN 'Baholash savolida rivojlantirilgan dalillar, shartlarni ko‘rib chiqish va asoslangan xulosa muhim.'
   ELSE 'Tahliliy savolda mantiqiy izchillik va berilgan ma’lumotni to‘g‘ri talqin qilish muhim.'
  END);
 ELSE
  v_descriptors:=ARRAY[
   'AO1 — accurate and relevant economic knowledge, definitions and terminology.',
   'AO2 — application of economic theory, developed cause-and-effect reasoning and use of the given context.'
  ];
  IF v_ao3>0 THEN
   v_descriptors:=array_append(v_descriptors,
    'AO3 — weighing arguments and limitations, reaching a justified judgement that addresses the question.');
  END IF;
  v_descriptors:=array_append(v_descriptors,CASE v_focus
   WHEN 'calculation' THEN 'For a calculation, assessment considers data selection, clear working, correct units and numerical accuracy.'
   WHEN 'definition' THEN 'For a concept question, assessment considers a precise definition, economic meaning and relevance.'
   WHEN 'diagram' THEN 'Where appropriate, a diagram is assessed for economic accuracy, labels and integration with the explanation.'
   WHEN 'evaluation' THEN 'For evaluation, developed arguments, consideration of conditions and a reasoned conclusion are important.'
   ELSE 'For analysis, assessment considers a clear logical chain and correct interpretation of given information.'
  END);
 END CASE;

 v_scheme:=jsonb_build_object(
  'max_marks',v_max,'ao12_marks',v_ao12,'ao3_marks',v_ao3,
  'marking_style',v_style,'assessment_criteria',to_jsonb(v_descriptors),
  'official_cambridge',false,
  'basis','iclub_9708_assessment_objectives_no_answers_v1');

 -- Return an explicit allowlist. The private legacy v_raw contains
 -- task.answer_requirements and is NEVER serialized to Economics Core.
 RETURN jsonb_build_object(
  'available',true,'task_key',p_task_key,'task_version',p_task_version,
  'title',CASE v_language WHEN 'ru' THEN 'Критерии оценивания'
                          WHEN 'uz' THEN 'Baholash mezonlari'
                          ELSE 'Assessment criteria' END,
  'mark_scheme',v_scheme);
END;
$criteria$;
REVOKE ALL ON FUNCTION public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)
 TO authenticated;
DO $guard$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_written_mark_scheme_v1
 WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027')<>22
 THEN RAISE EXCEPTION 'scoring_bank_baseline_changed'; END IF;
 IF has_function_privilege('anon',
 'public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'anonymous_criteria_access'; END IF;
END;$guard$;
COMMIT;