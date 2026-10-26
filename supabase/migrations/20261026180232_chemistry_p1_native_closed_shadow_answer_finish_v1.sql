-- Applied live under Supabase migration version 20261026180232. QA only, no student functions.
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
 OR p_session_id IS NULL OR p_item_order NOT BETWEEN 1 AND 40
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
$function$

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_shadow_finish_v1(p_owner uuid, p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v private.iclub_exam_chemistry_p1_shadow_sessions_v1%ROWTYPE;
 v_score integer; v_answered integer; v_done timestamptz;
BEGIN
 IF p_owner IS DISTINCT FROM '00000000-0000-4000-8000-000000009701'::uuid
 OR p_session_id IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','qa_only_invalid_request'); END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND status='draft' AND launch_enabled=false)
 THEN RETURN jsonb_build_object('ok',false,'code','preview_closed_by_gate'); END IF;
 SELECT * INTO v FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1
 WHERE id=p_session_id AND owner_id=p_owner FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF v.status='finalized' THEN
 RETURN jsonb_build_object('ok',true,'status','finalized','score',v.score,
 'out_of',40,'duplicate',true,'can_credit_mastery',false); END IF;

 SELECT coalesce(sum(CASE WHEN v.responses ? ix.ord::text
 AND (ix.item->'display_order'->>(
 (v.responses->ix.ord::text->>'choice')::integer))::integer =
 ascii(ix.item->>'key')-65
 THEN 1 ELSE 0 END),0)::integer,
 count(*) FILTER(WHERE v.responses ? ix.ord::text)::integer
 INTO v_score,v_answered
 FROM jsonb_array_elements(v.items) WITH ORDINALITY ix(item,ord);

 v_done:=clock_timestamp();
 UPDATE private.iclub_exam_chemistry_p1_shadow_sessions_v1
 SET status='finalized',score=v_score,finalized_at=v_done
 WHERE id=v.id AND owner_id=p_owner AND status='active';

 RETURN jsonb_build_object('ok',true,'status','finalized','score',v_score,
 'out_of',40,'answered',v_answered,
 'completed_after_deadline',v_done>=v.deadline_at,
 'duplicate',false,'can_credit_mastery',false,'qa_only',true);
END;
$function$

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)
 TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)
 TO service_role;
DO $post$ BEGIN
 IF has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)','EXECUTE')
 OR has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'Student access to closed shadow scoring'; END IF;
END $post$;