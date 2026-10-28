-- Chemistry 9701 P1 J-02: authenticated owner-scoped answer/finish/history.
-- No AI grading, no mastery credit; Chemistry beta and content gates currently OFF.
DO $pre$ BEGIN
 IF to_regprocedure('public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_p1_finish_v1(uuid)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_p1_history_v1()') IS NOT NULL
 THEN RAISE EXCEPTION 'Chemistry learner answer/finish/history already exists'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Chemistry must remain empty and OFF'; END IF;
END $pre$;

CREATE FUNCTION public.iclub_exam_chemistry_p1_answer_v1(
 p_session_id uuid,p_item_order integer,p_choice integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_p1_live_attempts_v1%ROWTYPE;
 v_prior jsonb;v_time timestamptz;v_key text;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_item_order IS NULL OR p_choice IS NULL
 OR p_item_order NOT BETWEEN 1 AND 40 OR p_choice NOT BETWEEN 0 AND 3
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 v_time:=clock_timestamp();
 IF v.status<>'active' OR v_time>=v.deadline_at
 THEN RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired'); END IF;
 v_key:=p_item_order::text;v_prior:=v.responses->v_key;
 IF v_prior IS NOT NULL AND (v_prior->>'choice')::int=p_choice
 THEN RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true,
 'revised',false,'selected_index',p_choice); END IF;
 UPDATE private.iclub_exam_chemistry_p1_live_attempts_v1
 SET responses=jsonb_set(v.responses,ARRAY[v_key],jsonb_build_object(
 'choice',p_choice,'at',v_time,
 'first_at',coalesce(v_prior->'first_at',v_prior->'at',to_jsonb(v_time))),true)
 WHERE id=v.id AND user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false,
 'revised',v_prior IS NOT NULL,'selected_index',p_choice);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_p1_finish_v1(p_session_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_p1_live_attempts_v1%ROWTYPE;
 v_correct integer;v_answered integer;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF v.status='finalized' THEN
 RETURN jsonb_build_object('ok',true,'status','finalized','score',v.score,
 'out_of',40,'duplicate',true,'credited_to_mastery',false); END IF;
 SELECT coalesce(sum(CASE WHEN v.responses ? x.ord::text
 AND (x.item->'display_order'->>(
 (v.responses->x.ord::text->>'choice')::int))::int=
 ascii(x.item->>'key')-65
 THEN 1 ELSE 0 END),0)::int,
 count(*) FILTER(WHERE v.responses ? x.ord::text)::int
 INTO v_correct,v_answered
 FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord);
 UPDATE private.iclub_exam_chemistry_p1_live_attempts_v1
 SET status='finalized',score=v_correct,finalized_at=clock_timestamp()
 WHERE id=v.id AND user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'status','finalized',
 'score',v_correct,'out_of',40,'answered',v_answered,
 'duplicate',false,'credited_to_mastery',false);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_p1_history_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();v_rows jsonb;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT jsonb_agg(jsonb_build_object(
 'session_id',z.id,'paper_code','P1','status',z.status,
 'started_at',z.started_at,'deadline_at',z.deadline_at,
 'score',CASE WHEN z.status='finalized' THEN z.score ELSE NULL END,
 'answered',jsonb_object_length(z.responses)) ORDER BY z.started_at DESC)
 INTO v_rows
 FROM (SELECT id,status,started_at,deadline_at,score,responses
 FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE user_id=v_user ORDER BY started_at DESC LIMIT 30) z;
 RETURN jsonb_build_object('ok',true,'sessions',coalesce(v_rows,'[]'::jsonb));
END $f$;

REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_finish_v1(uuid)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_history_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_finish_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_history_v1() TO authenticated;
DO $post$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 THEN RAISE EXCEPTION 'Chemistry student sessions unexpectedly appeared'; END IF;
 IF has_function_privilege('anon','public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_p1_finish_v1(uuid)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_p1_history_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'Anon allowed to write/read Chemistry student history'; END IF;
 IF (public.iclub_exam_chemistry_p1_history_v1()->>'ok') IS DISTINCT FROM 'false'
 OR (public.iclub_exam_chemistry_p1_answer_v1(gen_random_uuid(),1,0)->>'ok') IS DISTINCT FROM 'false'
 OR (public.iclub_exam_chemistry_p1_finish_v1(gen_random_uuid())->>'ok') IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Chemistry unexpectedly callable while not authorised'; END IF;
END $post$;