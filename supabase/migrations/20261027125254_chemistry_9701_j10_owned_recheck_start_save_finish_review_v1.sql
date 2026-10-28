-- J10 account-owned quiz transport: all reads, writes and results guarded.

CREATE FUNCTION public.iclub_exam_chemistry_recheck_start_v1(
 p_client_key text,p_entry_id uuid,p_study_confirmed boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();v_id uuid:=gen_random_uuid();
 v private.iclub_exam_chemistry_recheck_attempts_v1%ROWTYPE;
 source private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;
 n int;units int;v_md5 text;v_items jsonb;v_time timestamptz; approved_md5 text;
BEGIN
 IF v_user IS NULL OR p_entry_id IS NULL OR p_client_key IS NULL
 OR length(p_client_key) NOT BETWEEN 12 AND 128 OR p_client_key!~'^[A-Za-z0-9_-]+$'
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 OR NOT private.iclub_exam_chemistry_recheck_manifest_ok_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO source FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=p_entry_id AND user_id=v_user AND status='finalized'
 AND finalized_at IS NOT NULL;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','entry_not_finalized'); END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(
 pg_catalog.hashtextextended('chem9701_recheck_'||v_user::text,0));
 SELECT * INTO v FROM private.iclub_exam_chemistry_recheck_attempts_v1
 WHERE user_id=v_user AND client_key=p_client_key;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'resumed',true,'status',v.status,'deadline_at',v.deadline_at); END IF;
 SELECT approved_manifest_md5 INTO approved_md5 FROM
 private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1;
 SELECT * INTO v FROM private.iclub_exam_chemistry_recheck_attempts_v1
 WHERE user_id=v_user AND source_manifest_md5=approved_md5
 ORDER BY started_at DESC LIMIT 1;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'resumed',true,'status',v.status,'deadline_at',v.deadline_at,
 'same_source_reused',true); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_recheck_attempts_v1
 WHERE user_id=v_user AND status='active' ORDER BY started_at DESC LIMIT 1;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'resumed',true,'status',v.status,'deadline_at',v.deadline_at); END IF;
 IF p_study_confirmed IS DISTINCT FROM true
 THEN RETURN jsonb_build_object('ok',false,'code','study_acknowledgement_required'); END IF;
 SELECT count(*)::int,count(DISTINCT d.syllabus_unit)::int,
 md5(string_agg(d.id||'|'||d.item_md5,';' ORDER BY d.syllabus_unit)),
 jsonb_agg(jsonb_build_object(
 'unit',d.syllabus_unit,'skill_key',d.skill_key,'key',d.item_json->>'answer_key',
 'locales',d.item_json->'locales','order',
 (SELECT jsonb_agg(x ORDER BY md5(v_id::text||d.id||x::text))
 FROM pg_catalog.generate_series(0,3) x)) ORDER BY d.syllabus_unit)
 INTO n,units,v_md5,v_items
 FROM private.iclub_exam_chemistry_recheck_items_v1 d
 JOIN private.iclub_exam_chemistry_recheck_release_items_v1 approved
 ON approved.item_id=d.id AND approved.item_md5=d.item_md5
 JOIN private.iclub_exam_chemistry_recheck_control_v1 ctl
 ON ctl.id=1 AND approved.release_version=ctl.release_version
 JOIN private.iclub_exam_chemistry_recheck_preflight_v1 pf ON pf.id=d.id
 WHERE pf.seven_internal_AI_reviews AND pf.different_from_entry_stem
 AND pf.different_from_P1_stem AND pf.unreleased_no_mastery
 AND d.item_md5=md5(d.item_json::text);
 IF n<>22 OR units<>22 OR v_items IS NULL OR v_md5 IS DISTINCT FROM approved_md5
 THEN RETURN jsonb_build_object('ok',false,'code','approved_items_not_ready'); END IF;
 v_time:=clock_timestamp();
 INSERT INTO private.iclub_exam_chemistry_recheck_attempts_v1
 (id,user_id,entry_id,client_key,source_manifest_md5,entry_source_md5,
 learning_ack_at,items,started_at,deadline_at)
 VALUES(v_id,v_user,p_entry_id,p_client_key,v_md5,source.source_manifest_md5,
 v_time,v_items,v_time,v_time+interval '30 minutes');
 RETURN jsonb_build_object('ok',true,'session_id',v_id,'resumed',false,
 'status','active','deadline_at',v_time+interval '30 minutes',
 'total_questions',22,'learning_ack_kind','self_report','can_credit_mastery',false);
END $f$;
CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_recheck_answer_v1(p_session_id uuid, p_item_order integer, p_choice integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_recheck_attempts_v1%ROWTYPE;
 prior jsonb;now_at timestamptz;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_item_order NOT BETWEEN 1 AND 22
 OR p_item_order IS NULL OR p_choice NOT BETWEEN 0 AND 3 OR p_choice IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_recheck_attempts_v1
 WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 now_at:=clock_timestamp();
 IF v.status<>'active' OR now_at>=v.deadline_at
 THEN RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired'); END IF;
 prior:=v.responses->p_item_order::text;
 IF prior IS NOT NULL AND (prior->>'choice')::int=p_choice
 THEN RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true); END IF;
 UPDATE private.iclub_exam_chemistry_recheck_attempts_v1
 SET responses=jsonb_set(v.responses,ARRAY[p_item_order::text],
 jsonb_build_object('choice',p_choice,'at',now_at,
 'first_at',coalesce(prior->'first_at',prior->'at',to_jsonb(now_at))),true)
 WHERE id=v.id AND user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false,
 'revised',prior IS NOT NULL,'selected_index',p_choice);
END $function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_recheck_finish_v1(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_recheck_attempts_v1%ROWTYPE;points int;answered int;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_recheck_attempts_v1
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
 UPDATE private.iclub_exam_chemistry_recheck_attempts_v1
 SET status='finalized',score=points,finalized_at=clock_timestamp()
 WHERE id=v.id AND user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'status','finalized','score',points,
 'out_of',22,'answered',answered,'duplicate',false,
 'calibrated_diagnostic',false,'can_credit_mastery',false);
END $function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_recheck_get_v1(p_session_id uuid, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_recheck_attempts_v1%ROWTYPE;result jsonb;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_language NOT IN('ru','uz','en') OR p_language IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_recheck_attempts_v1
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
END $function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_recheck_history_v1()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();recent jsonb;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT jsonb_agg(jsonb_build_object('session_id',s.id,
 'status',s.status,'started_at',s.started_at,'deadline_at',s.deadline_at,
 'score',CASE WHEN s.status='finalized' THEN s.score ELSE NULL END,
 'answered',(SELECT count(*) FROM jsonb_object_keys(s.responses))) ORDER BY s.started_at DESC)
 INTO recent FROM(SELECT id,status,started_at,deadline_at,score,responses
 FROM private.iclub_exam_chemistry_recheck_attempts_v1
 WHERE user_id=v_user ORDER BY started_at DESC LIMIT 20)s;
 RETURN jsonb_build_object('ok',true,'sessions',coalesce(recent,'[]'::jsonb));
END $function$;

CREATE FUNCTION public.iclub_exam_chemistry_recheck_review_v1(
 p_session_id uuid,p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE u uuid:=auth.uid();r private.iclub_exam_chemistry_recheck_attempts_v1%ROWTYPE;
 e private.iclub_exam_chemistry_entry_attempts_v1%ROWTYPE;
 evidence jsonb;
BEGIN
 IF u IS NULL OR p_session_id IS NULL OR p_language IS NULL OR p_language NOT IN('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO r FROM private.iclub_exam_chemistry_recheck_attempts_v1
 WHERE id=p_session_id AND user_id=u;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF r.status<>'finalized' THEN RETURN jsonb_build_object('ok',false,'code','finish_first'); END IF;
 SELECT * INTO e FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE id=r.entry_id AND user_id=u AND status='finalized';
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','entry_not_found'); END IF;
 WITH entry_results AS(
 SELECT (x.item->>'unit')::int AS unit,
 (e.responses ? x.ord::text) AS answered,
 coalesce((e.responses ? x.ord::text) AND
 (x.item->'order'->>(e.responses->x.ord::text->>'choice')::int)::int
 =ascii(x.item->>'key')-65,false) AS correct
 FROM jsonb_array_elements(e.items) WITH ORDINALITY x(item,ord)
 ), recheck_results AS(
 SELECT (x.item->>'unit')::int AS unit,x.item->>'skill_key' skill,
 (r.responses ? x.ord::text) AS answered,
 coalesce((r.responses ? x.ord::text) AND
 (x.item->'order'->>(r.responses->x.ord::text->>'choice')::int)::int
 =ascii(x.item->>'key')-65,false) AS correct
 FROM jsonb_array_elements(r.items) WITH ORDINALITY x(item,ord)
 )
 SELECT jsonb_agg(jsonb_build_object(
 'unit',q.unit,'skill_key',q.skill,
 'title',coalesce(t.locales->p_language->>'title',q.skill),
 'entry_answered',er.answered,'entry_correct',er.correct,
 'recheck_answered',q.answered,'recheck_correct',q.correct,
 'study_recommended',NOT q.correct,
 'single_item_evidence',true,
 'interpretation',CASE
 WHEN NOT q.correct THEN 'review_more'
 WHEN NOT er.correct THEN 'one_correct_after_entry'
 ELSE 'two_individual_correct_answers' END,
 'lesson_available',EXISTS(
 SELECT 1 FROM private.iclub_subject_library lib
 WHERE lib.subject_key=s.library_subject_key
 AND lib.active_version=s.library_version_key AND lib.visible_to_learners)
 ) ORDER BY CASE WHEN q.correct THEN 1 ELSE 0 END,q.unit)
 INTO evidence FROM recheck_results q JOIN entry_results er ON er.unit=q.unit
 JOIN private.iclub_exam_core_skills_v1 s
 ON s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1'
 AND s.skill_key=q.skill AND s.syllabus_unit=q.unit
 JOIN private.iclub_subject_library_theory t
 ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key
 AND t.skill_key=s.skill_key;
 IF jsonb_array_length(coalesce(evidence,'[]'::jsonb))<>22
 THEN RAISE EXCEPTION 'J10 source vs entry unit join incomplete'; END IF;
 RETURN jsonb_build_object('ok',true,'session_id',r.id,
 'entry_session_id',r.entry_id,'score',r.score,'out_of',22,'topics',evidence,
 'learning_ack_kind','self_report','can_credit_mastery',false,
 'calibrated_diagnostic',false,'evidence_limit','one_recheck_item_per_topic',
 'recheck_means_improvement_not_mastery',true);
END $f$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_recheck_start_v1(text,uuid,boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_recheck_start_v1(text,uuid,boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_recheck_get_v1(uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_recheck_get_v1(uuid,text) TO authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_recheck_answer_v1(uuid,integer,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_recheck_answer_v1(uuid,integer,integer) TO authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_recheck_finish_v1(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_recheck_finish_v1(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_recheck_history_v1() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_recheck_history_v1() TO authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_recheck_review_v1(uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_recheck_review_v1(uuid,text) TO authenticated;
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_attempts_v1)<>0
 OR public.get_my_exam_prep_chemistry_recheck_shell_v1('en')<>'{}'::jsonb
 OR has_function_privilege('anon','public.iclub_exam_chemistry_recheck_start_v1(text,uuid,boolean)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_recheck_review_v1(uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Recheck endpoints unexpectedly open'; END IF;
END $post$;