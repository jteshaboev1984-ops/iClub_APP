-- Applied live as 20261026181402. Closed Chemistry synthetic-only QA RPC hardening.
CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_shadow_start_v1(p_owner uuid, p_client_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_id uuid:=gen_random_uuid();
 v_existing private.iclub_exam_chemistry_p1_shadow_sessions_v1%ROWTYPE;
 v_num int; v_topics int; v_qa int;
 v_manifest text; v_items jsonb; v_start timestamptz;
BEGIN
 IF p_owner IS DISTINCT FROM '00000000-0000-4000-8000-000000009701'::uuid
 OR p_client_key IS NULL OR length(p_client_key) NOT BETWEEN 12 AND 128
 OR p_client_key !~ '^[a-zA-Z0-9_-]+$'
 THEN RETURN jsonb_build_object('ok',false,'code','qa_only_invalid_request'); END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('iclub_chemistry_p1_closed_QA_start',0));
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 p
 JOIN private.iclub_exam_core_papers_v1 paper USING(program_key,version_key)
 WHERE p.program_key='chemistry_9701' AND p.version_key='chemistry_2025_2027_v1'
 AND p.integration_mode='native' AND p.status='draft' AND p.launch_enabled=false
 AND paper.paper_code='P1' AND paper.status='draft'
 AND paper.assessment_kind='mcq' AND paper.mcq_count=40 AND paper.duration_seconds=4500)
 THEN RETURN jsonb_build_object('ok',false,'code','preview_closed_by_gate'); END IF;

 SELECT * INTO v_existing FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1
 WHERE owner_id=p_owner AND client_key=p_client_key;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
 'status',v_existing.status,'resumed',true,'deadline_at',v_existing.deadline_at); END IF;
 SELECT * INTO v_existing FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1
 WHERE owner_id=p_owner AND status='active';
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
 'status','active','resumed',true,'deadline_at',v_existing.deadline_at); END IF;

 WITH chosen AS (
 SELECT b.*,src.item_json,src.item_md5
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 src
 ON src.program_key=b.program_key AND src.version_key=b.version_key
 AND src.draft_key=b.draft_key AND src.authoring_version=b.authoring_version
 AND src.item_md5=b.source_snapshot_md5
 WHERE b.planning_role='proposed_form' AND b.proposed_question_no BETWEEN 1 AND 40
 AND src.release_enabled=false AND src.exam_candidate_eligible=false
 AND src.credit_mastery=false AND src.item_md5=md5(src.item_json::text)
 AND src.item_json->'locales' ?& ARRAY['en','ru','uz']
 AND src.item_json->>'answer_key' IN ('A','B','C','D')
 ), validated AS (
 SELECT chosen.* FROM chosen
 WHERE (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 WHERE qa.program_key=chosen.program_key AND qa.version_key=chosen.version_key
 AND qa.draft_key=chosen.draft_key AND qa.authoring_version=chosen.authoring_version
 AND qa.source_snapshot_md5=chosen.item_md5 AND qa.gate_status='pass')=7
 AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 qa
 WHERE qa.program_key=chosen.program_key AND qa.version_key=chosen.version_key
 AND qa.draft_key=chosen.draft_key AND qa.authoring_version=chosen.authoring_version
 AND qa.gate_status='fail')
 )
 SELECT count(*),count(DISTINCT syllabus_unit),
 md5(string_agg(draft_key||'|'||item_md5,';' ORDER BY proposed_question_no)),
 jsonb_agg(jsonb_build_object(
  'draft_key',draft_key,'authoring_version',authoring_version,'source_md5',item_md5,
  'skill_key',skill_key,'syllabus_unit',syllabus_unit,
  'key',item_json->>'answer_key','locales',item_json->'locales',
  'display_order',(
   SELECT jsonb_agg(idx ORDER BY md5(v_id::text||draft_key||idx::text))
   FROM generate_series(0,3) idx
  )
 ) ORDER BY proposed_question_no)
 INTO v_num,v_topics,v_manifest,v_items FROM validated;
 IF v_num<>40 OR v_topics<>22 OR v_items IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','preview_source_not_ready'); END IF;
 v_start:=clock_timestamp();
 INSERT INTO private.iclub_exam_chemistry_p1_shadow_sessions_v1
 (id,owner_id,client_key,source_manifest_md5,items,started_at,deadline_at)
 VALUES (v_id,p_owner,p_client_key,v_manifest,v_items,v_start,v_start+interval '75 minutes');

 RETURN jsonb_build_object('ok',true,'session_id',v_id,'status','active',
 'resumed',false,'deadline_at',v_start+interval '75 minutes','total_items',40);
END;
$function$;

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_shadow_get_v1(p_owner uuid, p_session_id uuid, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v private.iclub_exam_chemistry_p1_shadow_sessions_v1%ROWTYPE; v_rows jsonb;
BEGIN
 IF p_owner IS DISTINCT FROM '00000000-0000-4000-8000-000000009701'::uuid
 OR p_session_id IS NULL OR p_language IS NULL OR p_language NOT IN ('en','ru','uz')
 THEN RETURN jsonb_build_object('ok',false,'code','qa_only_invalid_request'); END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RETURN jsonb_build_object('ok',false,'code','preview_closed_by_gate'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1
 WHERE id=p_session_id AND owner_id=p_owner;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;

 SELECT jsonb_agg(jsonb_build_object(
 'order',x.ord,'skill_key',x.item->>'skill_key',
 'unit',(x.item->>'syllabus_unit')::int,
 'question',x.item->'locales'->p_language->>'stem',
 'options',(
   SELECT jsonb_agg(x.item->'locales'->p_language->'options'->(idx.value::int)
    ORDER BY idx.position)
   FROM jsonb_array_elements_text(x.item->'display_order')
   WITH ORDINALITY idx(value,position)
 ),
 'answered',v.responses ? x.ord::text,
 'selected_index',CASE WHEN v.responses ? x.ord::text
 THEN (v.responses->x.ord::text->>'choice')::integer ELSE NULL END,
 'correct_index',CASE WHEN v.status='finalized' THEN (
    SELECT (pos.ord-1)::int FROM jsonb_array_elements_text(x.item->'display_order')
    WITH ORDINALITY pos(val,ord)
    WHERE pos.val::integer=ascii(x.item->>'key')-65
 ) ELSE NULL END,
 'explanation',CASE WHEN v.status='finalized'
 THEN x.item->'locales'->p_language->>'explanation' ELSE NULL END
 ) ORDER BY x.ord) INTO v_rows
 FROM jsonb_array_elements(v.items) WITH ORDINALITY x(item,ord);

 RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'paper_code','P1','program_key','chemistry_9701','status',v.status,
 'started_at',v.started_at,'deadline_at',v.deadline_at,
 'time_remaining_seconds',greatest(0,ceil(extract(epoch FROM
 (v.deadline_at-clock_timestamp())))::integer),
 'total_items',40,'score',CASE WHEN v.status='finalized' THEN v.score ELSE NULL END,
 'items',coalesce(v_rows,'[]'::jsonb),
 'qa_only',true,'can_credit_mastery',false);
END;
$function$;

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_shadow_answer_v1(p_owner uuid, p_session_id uuid, p_item_order integer, p_choice integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v private.iclub_exam_chemistry_p1_shadow_sessions_v1%ROWTYPE;
 v_key text; v_prior jsonb; v_now timestamptz;
BEGIN
 IF p_owner IS DISTINCT FROM '00000000-0000-4000-8000-000000009701'::uuid
 OR p_session_id IS NULL OR p_item_order IS NULL OR p_choice IS NULL OR p_item_order NOT BETWEEN 1 AND 40
 OR p_choice NOT BETWEEN 0 AND 3
 THEN RETURN jsonb_build_object('ok',false,'code','qa_only_invalid_request'); END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RETURN jsonb_build_object('ok',false,'code','preview_closed_by_gate'); END IF;

 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1
 WHERE id=p_session_id AND owner_id=p_owner FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 v_now:=clock_timestamp();
 IF v.status<>'active' OR v_now>=v.deadline_at
 THEN RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired'); END IF;
 v_key:=p_item_order::text;
 v_prior:=v.responses->v_key;
 IF v_prior IS NOT NULL AND (v_prior->>'choice')::integer=p_choice
 THEN RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true,
 'revised',false,'selected_index',p_choice); END IF;

 UPDATE private.iclub_exam_chemistry_p1_shadow_sessions_v1
 SET responses=jsonb_set(v.responses,ARRAY[v_key],jsonb_build_object(
 'choice',p_choice,'at',v_now,
 'first_at',coalesce(v_prior->'first_at',v_prior->'at',to_jsonb(v_now))),true)
 WHERE id=v.id AND owner_id=p_owner AND status='active';

 RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false,
 'revised',v_prior IS NOT NULL,'selected_index',p_choice);
END;
$function$;

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer) TO service_role;
DO $post$ BEGIN
 IF has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)','EXECUTE')
 THEN RAISE EXCEPTION 'Student callable QA RPC detected'; END IF;
END $post$;