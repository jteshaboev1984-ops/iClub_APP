-- Reproducible J09 exact skill Theory-only reader and lesson availability, based on applied SQL.
CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_entry_lesson_v1(p_session_id uuid, p_skill_key text, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();v private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;
 t_title text;t_body text;v_tour integer;v_point text;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_skill_key IS NULL
 OR p_language NOT IN('ru','uz','en') OR p_language IS NULL
 OR p_skill_key !~ '^CHEM9701-[0-9]{2}-[0-9]{2}$'
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=p_session_id AND user_id=v_user;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF v.status<>'finalized' OR v.finalized_at IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','finish_first'); END IF;
 IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(v.items) x(item)
 WHERE x.item->>'skill_key'=p_skill_key)
 THEN RETURN jsonb_build_object('ok',false,'code','skill_not_in_assessment'); END IF;
 SELECT t.locales->p_language->>'title',
 t.locales->p_language->>'explanation',
 t.tour_no,t.syllabus_point
 INTO t_title,t_body,v_tour,v_point
 FROM private.iclub_exam_core_skills_v1 s
 JOIN private.iclub_subject_library lib ON lib.subject_key=s.library_subject_key
 AND lib.active_version=s.library_version_key AND lib.visible_to_learners=true
 JOIN private.iclub_subject_library_theory t ON t.subject_key=s.library_subject_key
 AND t.version_key=s.library_version_key AND t.skill_key=s.skill_key
 WHERE s.program_key='chemistry_9701'
 AND s.version_key='chemistry_2025_2027_v1'
 AND s.skill_key=p_skill_key AND s.level_code='AS'
 LIMIT 1;
 IF t_title IS NULL OR length(coalesce(t_body,''))<30
 THEN RETURN jsonb_build_object('ok',false,'code','lesson_not_released'); END IF;
 RETURN jsonb_build_object('ok',true,'skill_key',p_skill_key,
 'title',t_title,'explanation',t_body,
 'syllabus_point',v_point,'tour_number',v_tour,'locale',p_language,
 'ai_tutor_content_included',false,'can_credit_mastery',false);
END $function$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_lesson_v1(uuid,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_entry_review_v1(p_session_id uuid, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();v private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;rows jsonb;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_language IS NULL
 OR p_language NOT IN('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=p_session_id AND user_id=v_user;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF v.status<>'finalized'
 THEN RETURN jsonb_build_object('ok',false,'code','finish_first'); END IF;
 WITH results AS(
 SELECT (x.item->>'unit')::int unit,x.item->>'skill_key' skill,
 (v.responses ? x.ord::text) answered,
 (v.responses ? x.ord::text) AND
 (x.item->'order'->>(v.responses->x.ord::text->>'choice')::int)::int
 =ascii(x.item->>'key')-65 AS correct
 FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord)
 ), detailed AS(
 SELECT r.unit,r.skill,r.answered,r.correct,
 coalesce(t.locales->p_language->>'title',r.skill) AS title,
 EXISTS(SELECT 1 FROM private.iclub_subject_library lib
 WHERE lib.subject_key=s.library_subject_key
 AND lib.active_version=s.library_version_key
 AND lib.visible_to_learners=true
 AND length(coalesce(t.locales->p_language->>'explanation',''))>30) AS lesson_available
 FROM results r
 JOIN private.iclub_exam_core_skills_v1 s
 ON s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1'
 AND s.skill_key=r.skill AND s.syllabus_unit=r.unit
 JOIN private.iclub_subject_library_theory t
 ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key
 AND t.skill_key=s.skill_key
 )
 SELECT jsonb_agg(jsonb_build_object('unit',unit,'skill_key',skill,'title',title,
 'answered',answered,'correct',correct,'review_needed',NOT correct,
 'lesson_available',lesson_available,
 'suggested_step',CASE WHEN correct THEN 'continue_learning' ELSE 'review_theory' END)
 ORDER BY CASE WHEN correct THEN 1 ELSE 0 END,unit)
 INTO rows FROM detailed;
 IF jsonb_array_length(coalesce(rows,'[]'::jsonb))<>22
 THEN RAISE EXCEPTION 'Entry review skills do not cover 22 AS units'; END IF;
 RETURN jsonb_build_object('ok',true,'score',v.score,'out_of',22,
 'topics',rows,'calibrated_diagnostic',false,'can_credit_mastery',false,
 'evidence_limit','one_question_per_topic_not_mastery',
 'route','syllabus_skill_theory_review');
END $function$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_review_v1(uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_review_v1(uuid,text) TO authenticated;
