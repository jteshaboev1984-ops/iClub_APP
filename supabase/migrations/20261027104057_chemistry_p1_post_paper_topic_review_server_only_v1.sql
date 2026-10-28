-- Chemistry 9701: closed post-paper topic review. Not a diagnostic,
-- NOT mastery or forecast; 1-2 items per AS unit cannot establish readiness.
-- Private authoritative saved responses only; no write and no keys in output.
DO $pre$ BEGIN
 IF to_regprocedure('public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)') IS NOT NULL
 THEN RAISE EXCEPTION 'Review-plan RPC exists: do not overwrite'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Expected zero user attempts and Chemistry beta OFF'; END IF;
END $pre$;
CREATE FUNCTION public.iclub_exam_chemistry_p1_review_plan_v1(
 p_session_id uuid,p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $function$
DECLARE
 v_uid uuid:=auth.uid();
 v private.iclub_exam_chemistry_p1_live_attempts_v1%ROWTYPE;
 v_topics jsonb;
 v_focus jsonb;
 v_problem_units integer;
 v_count integer;
BEGIN
 IF v_uid IS NULL OR p_session_id IS NULL OR p_language IS NULL
 OR p_language NOT IN ('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE id=p_session_id AND user_id=v_uid;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF v.status<>'finalized' OR v.finalized_at IS NULL OR v.score IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','finish_first'); END IF;
 WITH titles(unit,title_en,title_ru,title_uz) AS (VALUES
(1,'Atomic structure','Строение атома','Atom tuzilishi'),
(2,'Atoms, molecules and stoichiometry','Атомы, молекулы и стехиометрия','Atomlar, molekulalar va stexiometriya'),
(3,'Chemical bonding','Химическая связь','Kimyoviy bog‘lanish'),
(4,'States of matter','Агрегатные состояния вещества','Moddaning agregat holatlari'),
(5,'Chemical energetics','Химическая энергетика','Kimyoviy energetika'),
(6,'Electrochemistry','Электрохимия','Elektrokimyo'),
(7,'Equilibria','Химическое равновесие','Kimyoviy muvozanat'),
(8,'Reaction kinetics','Кинетика химических реакций','Reaksiya kinetikasi'),
(9,'The Periodic Table: chemical periodicity','Периодические закономерности','Davriy qonuniyatlar'),
(10,'Group 2','Элементы группы 2','2-guruh elementlari'),
(11,'Group 17','Элементы группы 17','17-guruh elementlari'),
(12,'Nitrogen and sulfur','Азот и сера','Azot va oltingugurt'),
(13,'An introduction to AS Level organic chemistry','Основы органической химии AS','AS organik kimyosiga kirish'),
(14,'Hydrocarbons','Углеводороды','Uglevodorodlar'),
(15,'Halogen compounds','Галогенсодержащие соединения','Galogenli birikmalar'),
(16,'Hydroxy compounds','Гидроксильные соединения','Gidroksil birikmalar'),
(17,'Carbonyl compounds','Карбонильные соединения','Karbonil birikmalar'),
(18,'Carboxylic acids and derivatives','Карбоновые кислоты и производные','Karbon kislotalar va ularning hosilalari'),
(19,'Nitrogen compounds','Азотсодержащие соединения','Azotli birikmalar'),
(20,'Polymerisation','Полимеризация','Polimerlanish'),
(21,'Organic synthesis','Органический синтез','Organik sintez'),
(22,'Analytical techniques','Аналитические методы','Tahlil usullari')
 ), assessed AS(
 SELECT (x.item->>'unit')::int unit,
 v.responses ? x.ord::text AS answered,
 CASE WHEN v.responses ? x.ord::text
 THEN (x.item->'display_order'->>(
 (v.responses->x.ord::text->>'choice')::int))::int
 =ascii(x.item->>'key')-65
 ELSE false END AS correct
 FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord)
 ), counts AS(
 SELECT unit,count(*)::int questions,
 count(*) FILTER(WHERE answered)::int answered,
 count(*) FILTER(WHERE correct)::int correct,
 count(*) FILTER(WHERE answered AND NOT correct)::int incorrect,
 count(*) FILTER(WHERE NOT answered)::int skipped
 FROM assessed GROUP BY unit
 ), ordered AS(
 SELECT t.unit,CASE p_language WHEN 'ru' THEN t.title_ru
 WHEN 'uz' THEN t.title_uz ELSE t.title_en END title,
 c.questions,c.answered,c.correct,c.incorrect,c.skipped,
 (c.incorrect+c.skipped)>0 AS review_needed
 FROM titles t JOIN counts c ON c.unit=t.unit
 ), priorities AS(
 SELECT *,row_number() OVER(ORDER BY (incorrect+skipped) DESC,
 incorrect DESC,unit) AS priority
 FROM ordered WHERE review_needed
 )
 SELECT
 (SELECT jsonb_agg(jsonb_build_object(
 'unit',o.unit,'title',o.title,'questions',o.questions,
 'answered',o.answered,'correct',o.correct,
 'incorrect',o.incorrect,'unanswered',o.skipped,
 'review_needed',o.review_needed) ORDER BY o.unit)
 FROM ordered o),
 (SELECT jsonb_agg(jsonb_build_object(
 'unit',f.unit,'title',f.title,'questions',f.questions,
 'incorrect',f.incorrect,'unanswered',f.skipped)
 ORDER BY f.priority) FROM priorities f WHERE f.priority<=5),
 (SELECT count(*)::int FROM ordered WHERE review_needed),
 (SELECT count(*)::int FROM ordered)
 INTO v_topics,v_focus,v_problem_units,v_count;
 IF v_count<>22 OR jsonb_array_length(coalesce(v_topics,'[]'::jsonb))<>22
 OR (SELECT sum((y->>'questions')::int)
 FROM jsonb_array_elements(v_topics)y)<>40
 OR (SELECT sum((y->>'correct')::int)
 FROM jsonb_array_elements(v_topics)y)<>v.score
 THEN RAISE EXCEPTION 'Chemistry saved paper/topic scoring inconsistent'; END IF;
 RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'paper_code','P1','total_questions',40,'score',v.score,
 'topics',v_topics,'focus_first',coalesce(v_focus,'[]'::jsonb),
 'topics_to_review',v_problem_units,
 'evidence_limit','one_or_two_questions_per_topic_no_mastery_inference',
 'can_credit_mastery',false,
 'next_step_kind','review_errors_then_use_independent_followup_content',
 'exam_prep_diagnostic_result',false);
END $function$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)
 TO authenticated;
DO $post$ BEGIN
 IF has_function_privilege('anon','public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Review-plan RPC permissions unsafe'; END IF;
 IF (public.iclub_exam_chemistry_p1_review_plan_v1(
 '00000000-0000-4000-8000-000000000001'::uuid,'ru')->>'ok') IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Review plan accessible when Chemistry beta OFF'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 THEN RAISE EXCEPTION 'Review plan wrote student history'; END IF;
END $post$;