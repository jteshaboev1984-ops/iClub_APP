-- Chemistry 9701 J-02: authenticated per-learner P1 MCQ server transport.
-- Strict launch gate, explicit owner manifest, beta consent and subject ownership.
-- No existing Mathematics/Economics/Practice tables/functions are changed.
DO $pre$ BEGIN
 IF to_regprocedure('public.iclub_exam_chemistry_p1_start_v1(text)') IS NOT NULL
 OR to_regprocedure('public.iclub_exam_chemistry_p1_get_v1(uuid,text)') IS NOT NULL
 THEN RAISE EXCEPTION 'Chemistry P1 public API already exists'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_owner_release_items_v1)<>0
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Chemistry P1 authorization must still be closed'; END IF;
END $pre$;
CREATE FUNCTION public.iclub_exam_chemistry_p1_start_v1(p_client_key text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();v_session uuid:=gen_random_uuid();
 v_existing private.iclub_exam_chemistry_p1_live_attempts_v1%ROWTYPE;
 v_num int;v_units int;v_hash text;v_allowed text;v_items jsonb;v_now timestamptz;
BEGIN
 IF v_user IS NULL OR p_client_key IS NULL
 OR length(p_client_key) NOT BETWEEN 12 AND 128
 OR p_client_key !~ '^[a-zA-Z0-9_-]+$'
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(
 pg_catalog.hashtextextended('chem9701_p1_'||v_user::text,0));

 SELECT * INTO v_existing FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE user_id=v_user AND client_key=p_client_key;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
 'status',v_existing.status,'resumed',true,'deadline_at',v_existing.deadline_at); END IF;
 SELECT * INTO v_existing FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE user_id=v_user AND status='active';
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
 'status','active','resumed',true,'deadline_at',v_existing.deadline_at); END IF;

 SELECT approved_content_manifest INTO v_allowed
 FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1 AND enabled=true;
 WITH valid AS(
 SELECT b.proposed_question_no,b.syllabus_unit,b.skill_key,
 d.draft_key,d.authoring_version,d.item_md5,d.item_json
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
 ON d.program_key=b.program_key AND d.version_key=b.version_key
 AND d.draft_key=b.draft_key AND d.authoring_version=b.authoring_version
 AND d.item_md5=b.source_snapshot_md5
 JOIN private.iclub_exam_chemistry_p1_owner_release_items_v1 rel
 ON rel.program_key=d.program_key AND rel.version_key=d.version_key
 AND rel.draft_key=d.draft_key AND rel.authoring_version=d.authoring_version
 AND rel.item_md5=d.item_md5
 WHERE b.planning_role='proposed_form'
 AND b.proposed_question_no BETWEEN 1 AND 40
 AND d.item_md5=md5(d.item_json::text)
 AND d.item_json->>'answer_key' IN('A','B','C','D')
 AND d.item_json->'locales' ?& ARRAY['en','ru','uz']
 AND (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 WHERE qa.program_key=d.program_key AND qa.version_key=d.version_key
 AND qa.draft_key=d.draft_key AND qa.authoring_version=d.authoring_version
 AND qa.source_snapshot_md5=d.item_md5 AND qa.gate_status='pass')=7
 AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 WHERE qa.program_key=d.program_key AND qa.version_key=d.version_key
 AND qa.draft_key=d.draft_key AND qa.authoring_version=d.authoring_version
 AND qa.gate_status='fail')
 )
 SELECT count(*),count(DISTINCT syllabus_unit),
 md5(string_agg(draft_key||'|'||item_md5,';' ORDER BY proposed_question_no)),
 jsonb_agg(jsonb_build_object('draft_key',draft_key,
 'authoring_version',authoring_version,'source_md5',item_md5,
 'skill_key',skill_key,'unit',syllabus_unit,
 'key',item_json->>'answer_key',
 'locales',item_json->'locales',
 'display_order',(
 SELECT jsonb_agg(i ORDER BY md5(v_session::text||draft_key||i::text))
 FROM generate_series(0,3) i)
 ) ORDER BY proposed_question_no)
 INTO v_num,v_units,v_hash,v_items FROM valid;
 IF v_num<>40 OR v_units<>22 OR v_hash IS NULL
 OR v_hash IS DISTINCT FROM v_allowed
 THEN RETURN jsonb_build_object('ok',false,'code','paper_not_ready'); END IF;
 v_now:=clock_timestamp();
 INSERT INTO private.iclub_exam_chemistry_p1_live_attempts_v1
 (id,user_id,client_key,source_manifest_md5,items,started_at,deadline_at)
 VALUES(v_session,v_user,p_client_key,v_hash,v_items,v_now,v_now+interval '75 minutes');
 RETURN jsonb_build_object('ok',true,'session_id',v_session,'status','active',
 'resumed',false,'deadline_at',v_now+interval '75 minutes','total_items',40);
END $f$;

CREATE FUNCTION public.iclub_exam_chemistry_p1_get_v1(
 p_session_id uuid,p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
 v private.iclub_exam_chemistry_p1_live_attempts_v1%ROWTYPE;v_rows jsonb;
BEGIN
 IF v_user IS NULL OR p_session_id IS NULL OR p_language IS NULL
 OR p_language NOT IN ('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN jsonb_build_object('ok',false,'code','not_available'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_live_attempts_v1
 WHERE id=p_session_id AND user_id=v_user;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 SELECT jsonb_agg(jsonb_build_object(
 'order',x.ord,'skill_key',x.item->>'skill_key','unit',(x.item->>'unit')::int,
 'question',x.item->'locales'->p_language->>'stem',
 'options',(SELECT jsonb_agg(x.item->'locales'->p_language->'options'->(op.value::int)
 ORDER BY op.ord)
 FROM jsonb_array_elements_text(x.item->'display_order') WITH ORDINALITY op(value,ord)),
 'answered',v.responses ? x.ord::text,
 'selected_index',CASE WHEN v.responses ? x.ord::text
 THEN (v.responses->x.ord::text->>'choice')::int ELSE NULL END,
 'correct_index',CASE WHEN v.status='finalized' THEN
 (SELECT (p.ord-1)::int FROM jsonb_array_elements_text(x.item->'display_order')
 WITH ORDINALITY p(value,ord)
 WHERE p.value::int=ascii(x.item->>'key')-65) ELSE NULL END,
 'explanation',CASE WHEN v.status='finalized'
 THEN x.item->'locales'->p_language->>'explanation' ELSE NULL END)
 ORDER BY x.ord) INTO v_rows
 FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord);
 RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'paper_code','P1','status',v.status,'started_at',v.started_at,
 'deadline_at',v.deadline_at,
 'time_remaining_seconds',greatest(0,ceil(extract(epoch FROM
 (v.deadline_at-clock_timestamp())))::int),
 'total_items',40,'score',CASE WHEN v.status='finalized' THEN v.score ELSE NULL END,
 'items',coalesce(v_rows,'[]'::jsonb));
END $f$;

REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_start_v1(text)
FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_p1_get_v1(uuid,text)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_start_v1(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_p1_get_v1(uuid,text) TO authenticated;
DO $post$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_owner_release_items_v1)<>0
 THEN RAISE EXCEPTION 'Chemistry learner content unexpectedly created'; END IF;
 IF public.iclub_exam_chemistry_p1_start_v1('testclient00001')->>'ok' IS DISTINCT FROM 'false'
 OR public.iclub_exam_chemistry_p1_get_v1(gen_random_uuid(),'ru')->>'ok' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Chemistry runtime leaked while OFF'; END IF;
 IF has_function_privilege('anon','public.iclub_exam_chemistry_p1_start_v1(text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_p1_get_v1(uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Anon chemistry access granted'; END IF;
END $post$;