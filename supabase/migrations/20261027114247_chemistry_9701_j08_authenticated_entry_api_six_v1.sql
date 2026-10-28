-- J08: account-owned ENTRY start/get/save/finish/history/review. No P1 or mastery writes.
-- All public functions are explicitly authenticated-only and enforce current cohort/owner GO.
DO $pre$ BEGIN
 IF to_regprocedure('public.iclub_exam_chemistry_entry_start_v1(text)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_entry_get_v1(uuid,text)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_entry_answer_v1(uuid,integer,integer)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_entry_finish_v1(uuid)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_entry_history_v1()') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_entry_review_v1(uuid,text)') IS NOT NULL
 THEN RAISE EXCEPTION 'Entry learner functions already exist'; END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_release_items_v1)<>0
 THEN RAISE EXCEPTION 'J08 beta must remain empty/OFF'; END IF;
END $pre$;

CREATE FUNCTION public.iclub_exam_chemistry_entry_start_v1(p_client_key text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();v_id uuid:=gen_random_uuid();
 v private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;
 n int;units int;v_md5 text;v_items jsonb;v_time timestamptz;
BEGIN
 IF v_user IS NULL OR p_client_key IS NULL OR length(p_client_key) NOT BETWEEN 12 AND 128
 OR p_client_key!~'^[A-Za-z0-9_-]+$'
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(
 pg_catalog.hashtextextended('chem9701_entry_user_'||v_user::text,0));
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE user_id=v_user AND client_key=p_client_key;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'resumed',true,'status',v.status,'deadline_at',v.deadline_at); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE user_id=v_user AND status='active';
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'resumed',true,'status',v.status,'deadline_at',v.deadline_at); END IF;
 SELECT count(*)::int,count(DISTINCT d.syllabus_unit)::int,
 md5(string_agg(d.id||'|'||d.item_md5,';' ORDER BY d.syllabus_unit)),
 jsonb_agg(jsonb_build_object(
 'unit',d.syllabus_unit,'skill_key',d.skill_key,'key',d.item_json->>'answer_key',
 'locales',d.item_json->'locales','order',
 (SELECT jsonb_agg(x ORDER BY md5(v_id::text||d.id||x::text))
 FROM pg_catalog.generate_series(0,3) x)) ORDER BY d.syllabus_unit)
 INTO n,units,v_md5,v_items
 FROM private.iclub_exam_chemistry_entry_items_v1 d
 JOIN private.iclub_exam_chemistry_entry_release_items_v1 approved
 ON approved.item_id=d.id AND approved.item_md5=d.item_md5
 JOIN private.iclub_exam_chemistry_entry_release_v1 ctl
 ON ctl.id=1 AND approved.release_version=ctl.release_version
 JOIN private.iclub_exam_chemistry_entry_study_links_v1 links
 ON links.private_entry_id=d.id
 WHERE d.review_status='internal_ai_reviewed' AND d.reviewer_type='internal_ai'
 AND links.AI_review_complete AND links.seven_review_gates
 AND links.syllabus_skill_link AND links.trilingual_theory_link
 AND links.trilingual_tutor_link AND links.distinct_from_exam_blueprint
 AND links.unreleased AND d.item_md5=md5(d.item_json::text);
 IF n<>22 OR units<>22 OR v_items IS NULL OR v_md5 IS DISTINCT FROM
 (SELECT approved_manifest_md5 FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 THEN RETURN jsonb_build_object('ok',false,'code','approved_items_not_ready'); END IF;
 v_time:=clock_timestamp();
 INSERT INTO private.iclub_exam_chemistry_entry_attempts_v1
 (id,user_id,client_key,source_manifest_md5,items,started_at,deadline_at)
 VALUES(v_id,v_user,p_client_key,v_md5,v_items,v_time,v_time+interval '30 minutes');
 RETURN jsonb_build_object('ok',true,'session_id',v_id,'resumed',false,
 'status','active','deadline_at',v_time+interval '30 minutes',
 'total_questions',22,'can_credit_mastery',false);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_entry_get_v1(p_session_id uuid,p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;result jsonb;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_language NOT IN('ru','uz','en') OR p_language IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=p_session_id AND user_id=v_user;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 SELECT jsonb_agg(jsonb_build_object(
 'order',x.ord,'unit',(x.item->>'unit')::int,
 'skill_key',x.item->>'skill_key',
 'question',x.item->'locales'->p_language->>'stem',
 'options',(SELECT jsonb_agg(x.item->'locales'->p_language->'options'->(p.value::int)
 ORDER BY p.ord) FROM jsonb_array_elements_text(x.item->'order')
 WITH ORDINALITY p(value,ord)),
 'answered',v.responses ? x.ord::text,
 'selected_index',CASE WHEN v.responses ? x.ord::text THEN
 (v.responses->x.ord::text->>'choice')::int ELSE NULL END,
 'correct_index',CASE WHEN v.status='finalized' THEN
 (SELECT (p.ord-1)::int FROM jsonb_array_elements_text(x.item->'order')
 WITH ORDINALITY p(value,ord)
 WHERE p.value::int=ascii(x.item->>'key')-65) ELSE NULL END,
 'explanation',CASE WHEN v.status='finalized'
 THEN x.item->'locales'->p_language->>'explanation' ELSE NULL END
 ) ORDER BY x.ord) INTO result
 FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord);
 RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'status',v.status,'deadline_at',v.deadline_at,
 'score',CASE WHEN v.status='finalized' THEN v.score ELSE NULL END,
 'items',coalesce(result,'[]'::jsonb),'can_credit_mastery',false,
 'calibrated_diagnostic',false);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_entry_answer_v1(
 p_session_id uuid,p_item_order integer,p_choice integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;
 prior jsonb;now_at timestamptz;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_item_order NOT BETWEEN 1 AND 22
 OR p_item_order IS NULL OR p_choice NOT BETWEEN 0 AND 3 OR p_choice IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 now_at:=clock_timestamp();
 IF v.status<>'active' OR now_at>=v.deadline_at
 THEN RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired'); END IF;
 prior:=v.responses->p_item_order::text;
 IF prior IS NOT NULL AND (prior->>'choice')::int=p_choice
 THEN RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true); END IF;
 UPDATE private.iclub_exam_chemistry_entry_attempts_v1
 SET responses=jsonb_set(v.responses,ARRAY[p_item_order::text],
 jsonb_build_object('choice',p_choice,'at',now_at,
 'first_at',coalesce(prior->'first_at',prior->'at',to_jsonb(now_at))),true)
 WHERE id=v.id AND user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false,
 'revised',prior IS NOT NULL,'selected_index',p_choice);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_entry_finish_v1(p_session_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;points int;answered int;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF v.status='finalized' THEN RETURN jsonb_build_object('ok',true,
 'status','finalized','score',v.score,'out_of',22,'duplicate',true,
 'calibrated_diagnostic',false,'can_credit_mastery',false); END IF;
 SELECT coalesce(sum(CASE WHEN v.responses ? x.ord::text
 AND (x.item->'order'->>(
 (v.responses->x.ord::text->>'choice')::int))::int
 =ascii(x.item->>'key')-65 THEN 1 ELSE 0 END),0)::int,
 count(*) FILTER(WHERE v.responses ? x.ord::text)::int
 INTO points,answered FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord);
 UPDATE private.iclub_exam_chemistry_entry_attempts_v1
 SET status='finalized',score=points,finalized_at=clock_timestamp()
 WHERE id=v.id AND user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'status','finalized','score',points,
 'out_of',22,'answered',answered,'duplicate',false,
 'calibrated_diagnostic',false,'can_credit_mastery',false);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_entry_history_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();recent jsonb;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT jsonb_agg(jsonb_build_object('session_id',s.id,
 'status',s.status,'started_at',s.started_at,'deadline_at',s.deadline_at,
 'score',CASE WHEN s.status='finalized' THEN s.score ELSE NULL END,
 'answered',(SELECT count(*) FROM jsonb_object_keys(s.responses))) ORDER BY s.started_at DESC)
 INTO recent FROM(SELECT id,status,started_at,deadline_at,score,responses
 FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE user_id=v_user ORDER BY started_at DESC LIMIT 20)s;
 RETURN jsonb_build_object('ok',true,'sessions',coalesce(recent,'[]'::jsonb));
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_entry_review_v1(
 p_session_id uuid,p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
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
 coalesce(t.locales->p_language->>'title',r.skill) AS title
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
 'suggested_step',CASE WHEN correct THEN 'continue_learning' ELSE 'review_theory' END)
 ORDER BY CASE WHEN correct THEN 1 ELSE 0 END,unit)
 INTO rows FROM detailed;
 IF jsonb_array_length(coalesce(rows,'[]'::jsonb))<>22
 THEN RAISE EXCEPTION 'Entry review skills do not cover 22 AS units'; END IF;
 RETURN jsonb_build_object('ok',true,'score',v.score,'out_of',22,
 'topics',rows,'calibrated_diagnostic',false,'can_credit_mastery',false,
 'evidence_limit','one_question_per_topic_not_mastery',
 'route','syllabus_skill_theory_review');
END $f$;

REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_start_v1(text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_get_v1(uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_answer_v1(uuid,integer,integer) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_finish_v1(uuid) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_history_v1() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_review_v1(uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_start_v1(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_get_v1(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_answer_v1(uuid,integer,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_finish_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_history_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_review_v1(uuid,text) TO authenticated;
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1) IS DISTINCT FROM false
 OR has_function_privilege('anon','public.iclub_exam_chemistry_entry_get_v1(uuid,text)','EXECUTE')
 OR (public.iclub_exam_chemistry_entry_start_v1('qa_entry_auth_denied_001')->>'ok') IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'New learner entry functions unexpectedly open'; END IF;
END $post$;