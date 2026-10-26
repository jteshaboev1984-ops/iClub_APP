-- Applied live under Supabase migration version 20261026180059.
-- Non-destructive private-only QA sessions; no existing product table is changed.
-- Depends on completed private Chemistry I-11 views/content (separate approved stage).
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_p1_shadow_sessions_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Closed Chemistry session table already exists'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1'
 AND integration_mode='native' AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry not native draft OFF'; END IF;
END $pre$;
CREATE TABLE private.iclub_exam_chemistry_p1_shadow_sessions_v1(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 owner_id uuid NOT NULL CHECK(owner_id='00000000-0000-4000-8000-000000009701'::uuid),
 program_key text NOT NULL DEFAULT 'chemistry_9701' CHECK(program_key='chemistry_9701'),
 version_key text NOT NULL DEFAULT 'chemistry_2025_2027_v1' CHECK(version_key='chemistry_2025_2027_v1'),
 paper_code text NOT NULL DEFAULT 'P1' CHECK(paper_code='P1'),
 client_key text NOT NULL CHECK(length(client_key) BETWEEN 12 AND 128 AND
 client_key~'^[a-zA-Z0-9_-]+$'),
 status text NOT NULL DEFAULT 'active' CHECK(status IN('active','finalized')),
 source_manifest_md5 text NOT NULL CHECK(source_manifest_md5 ~ '^[a-f0-9]{32}$'),
 items jsonb NOT NULL CHECK(jsonb_typeof(items)='array' AND jsonb_array_length(items)=40),
 responses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(responses)='object'),
 started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 deadline_at timestamptz NOT NULL,
 finalized_at timestamptz,
 score integer CHECK(score BETWEEN 0 AND 40),
 reviewed_by_owner boolean NOT NULL DEFAULT false CHECK(reviewed_by_owner=false),
 credits_user_progress boolean NOT NULL DEFAULT false CHECK(credits_user_progress=false),
 CHECK(deadline_at>started_at),
 CHECK((status='active' AND finalized_at IS NULL AND score IS NULL)
 OR (status='finalized' AND finalized_at IS NOT NULL AND score IS NOT NULL)),
 UNIQUE(owner_id,program_key,version_key,paper_code,client_key)
);
CREATE UNIQUE INDEX iclub_chem_p1_shadow_only_active_uq
ON private.iclub_exam_chemistry_p1_shadow_sessions_v1(owner_id,program_key,version_key,paper_code)
WHERE status='active';
ALTER TABLE private.iclub_exam_chemistry_p1_shadow_sessions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_shadow_sessions_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_p1_shadow_sessions_v1
 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_p1_shadow_sessions_v1 TO service_role;
COMMENT ON TABLE private.iclub_exam_chemistry_p1_shadow_sessions_v1 IS
 'Closed synthetic QA ONLY. Never real student sessions, no Maths/Economics attempts touched. Answers are private and never exposed pre-finalisation.';

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
$function$

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_shadow_get_v1(p_owner uuid, p_session_id uuid, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v private.iclub_exam_chemistry_p1_shadow_sessions_v1%ROWTYPE; v_rows jsonb;
BEGIN
 IF p_owner IS DISTINCT FROM '00000000-0000-4000-8000-000000009701'::uuid
 OR p_session_id IS NULL OR p_language NOT IN ('en','ru','uz')
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
$function$

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text) TO service_role;
DO $post$ BEGIN
 IF has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 OR has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_sessions_v1','SELECT')
 THEN RAISE EXCEPTION 'Chemistry closed QA session service privileges leaked'; END IF;
END $post$;