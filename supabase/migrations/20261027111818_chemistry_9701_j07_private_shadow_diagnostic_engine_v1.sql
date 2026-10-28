-- J-07 isolated service-only, synthetic Chemistry ENTRY question-flow validation.
-- NO learner API. No reuse of P1 attempts, grades, releases, cohorts or history.
DO $before$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_entry_shadow_v1') IS NOT NULL
 OR to_regprocedure('private.iclub_exam_chemistry_entry_shadow_start_v1(text)') IS NOT NULL
 THEN RAISE EXCEPTION 'J07 shadow engine already exists'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_study_links_v1
 WHERE seven_review_gates AND trilingual_theory_link AND trilingual_tutor_link
 AND distinct_from_exam_blueprint AND unreleased)<>22
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Entry source incomplete or Chemistry accidentally ON'; END IF;
END $before$;
CREATE TABLE private.iclub_exam_chemistry_entry_shadow_v1 (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 synthetic_owner uuid NOT NULL DEFAULT '00000000-0000-4000-8000-000000009702'::uuid
 CHECK(synthetic_owner='00000000-0000-4000-8000-000000009702'::uuid),
 client_key text NOT NULL CHECK(length(client_key) BETWEEN 12 AND 128
 AND client_key~'^[A-Za-z0-9_-]+$'),
 source_manifest_md5 text NOT NULL CHECK(source_manifest_md5~'^[0-9a-f]{32}$'),
 status text NOT NULL DEFAULT 'active' CHECK(status IN('active','finalized')),
 items jsonb NOT NULL CHECK(jsonb_typeof(items)='array' AND jsonb_array_length(items)=22),
 responses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(responses)='object'),
 started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 deadline_at timestamptz NOT NULL,finalized_at timestamptz,
 score integer CHECK(score BETWEEN 0 AND 22),
 can_credit_mastery boolean NOT NULL DEFAULT false CHECK(can_credit_mastery=false),
 can_issue_paper_1_score boolean NOT NULL DEFAULT false CHECK(can_issue_paper_1_score=false),
 CHECK(deadline_at>started_at),
 CHECK((status='active' AND score IS NULL AND finalized_at IS NULL)
 OR (status='finalized' AND score IS NOT NULL AND finalized_at IS NOT NULL)),
 UNIQUE(synthetic_owner,client_key)
);
CREATE UNIQUE INDEX iclub_chemistry_entry_shadow_only_one_active_v1
 ON private.iclub_exam_chemistry_entry_shadow_v1(synthetic_owner) WHERE status='active';
ALTER TABLE private.iclub_exam_chemistry_entry_shadow_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_entry_shadow_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_entry_shadow_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_entry_shadow_v1 TO service_role;

CREATE FUNCTION private.iclub_exam_chemistry_entry_shadow_start_v1(p_client_key text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v uuid:=gen_random_uuid();existing private.iclub_exam_chemistry_entry_shadow_v1%ROWTYPE;
 n integer; units integer; versions text;arr jsonb;timest timestamptz;
BEGIN
 IF p_client_key IS NULL OR length(p_client_key) NOT BETWEEN 12 AND 128
 OR p_client_key!~'^[A-Za-z0-9_-]+$'
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND launch_enabled=false)
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RETURN jsonb_build_object('ok',false,'code','qa_gate_closed'); END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('chem9701_entry_shadow_start',0));
 SELECT * INTO existing FROM private.iclub_exam_chemistry_entry_shadow_v1
 WHERE client_key=p_client_key;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'id',existing.id,
 'resumed',true,'status',existing.status,'deadline_at',existing.deadline_at); END IF;
 SELECT * INTO existing FROM private.iclub_exam_chemistry_entry_shadow_v1 WHERE status='active';
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'id',existing.id,
 'resumed',true,'status',existing.status,'deadline_at',existing.deadline_at); END IF;
 SELECT count(*),count(DISTINCT d.syllabus_unit),
 md5(string_agg(d.id||'|'||d.item_md5,';' ORDER BY d.syllabus_unit)),
 jsonb_agg(jsonb_build_object('unit',d.syllabus_unit,
 'skill_key',d.skill_key,'key',d.item_json->>'answer_key',
 'locales',d.item_json->'locales',
 'order',(SELECT jsonb_agg(x ORDER BY md5(v::text||d.id||x::text))
 FROM generate_series(0,3) x)) ORDER BY d.syllabus_unit)
 INTO n,units,versions,arr
 FROM private.iclub_exam_chemistry_entry_items_v1 d
 JOIN private.iclub_exam_chemistry_entry_study_links_v1 l ON l.private_entry_id=d.id
 WHERE d.review_status='internal_ai_reviewed' AND d.reviewer_type='internal_ai'
 AND l.AI_review_complete AND l.seven_review_gates AND l.syllabus_skill_link
 AND l.trilingual_theory_link AND l.trilingual_tutor_link
 AND l.distinct_from_exam_blueprint AND l.unreleased
 AND d.item_md5=md5(d.item_json::text);
 IF n<>22 OR units<>22 OR arr IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','source_not_ready'); END IF;
 timest:=clock_timestamp();
 INSERT INTO private.iclub_exam_chemistry_entry_shadow_v1
 (id,client_key,source_manifest_md5,items,started_at,deadline_at)
 VALUES(v,p_client_key,versions,arr,timest,timest+interval '30 minutes');
 RETURN jsonb_build_object('ok',true,'id',v,'resumed',false,
 'status','active','items',22,'deadline_at',timest+interval '30 minutes',
 'qa_only',true,'calibrated_diagnostic',false);
END $f$;

CREATE FUNCTION private.iclub_exam_chemistry_entry_shadow_get_v1(p_id uuid,p_lang text DEFAULT 'en')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE rowv private.iclub_exam_chemistry_entry_shadow_v1%ROWTYPE;result jsonb;
BEGIN
 IF p_id IS NULL OR p_lang IS NULL OR p_lang NOT IN('ru','uz','en')
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RETURN jsonb_build_object('ok',false,'code','qa_gate_closed'); END IF;
 SELECT * INTO rowv FROM private.iclub_exam_chemistry_entry_shadow_v1 WHERE id=p_id;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 SELECT jsonb_agg(jsonb_build_object(
 'question_no',q.n,'unit',(q.item->>'unit')::int,
 'skill_key',q.item->>'skill_key',
 'stem',q.item->'locales'->p_lang->>'stem',
 'options',(SELECT jsonb_agg(q.item->'locales'->p_lang->'options'->(p.value::int)
 ORDER BY p.ord) FROM jsonb_array_elements_text(q.item->'order')
 WITH ORDINALITY p(value,ord)),
 'answered',rowv.responses ? q.n::text,
 'selected_index',CASE WHEN rowv.responses ? q.n::text
 THEN (rowv.responses->q.n::text->>'choice')::int ELSE NULL END,
 'correct_index',CASE WHEN rowv.status='finalized' THEN
 (SELECT (p.ord-1)::int FROM jsonb_array_elements_text(q.item->'order')
 WITH ORDINALITY p(value,ord)
 WHERE p.value::int=ascii(q.item->>'key')-65) ELSE NULL END,
 'explanation',CASE WHEN rowv.status='finalized'
 THEN q.item->'locales'->p_lang->>'explanation' ELSE NULL END
 ) ORDER BY q.n) INTO result
 FROM jsonb_array_elements(rowv.items) WITH ORDINALITY q(item,n);
 RETURN jsonb_build_object('ok',true,'id',rowv.id,'qa_only',true,
 'status',rowv.status,'duration_minutes',30,'deadline_at',rowv.deadline_at,
 'score',CASE WHEN rowv.status='finalized' THEN rowv.score ELSE NULL END,
 'calibrated_diagnostic',false,'can_credit_mastery',false,
 'questions',coalesce(result,'[]'::jsonb));
END $f$;

CREATE FUNCTION private.iclub_exam_chemistry_entry_shadow_answer_v1(
 p_id uuid,p_order integer,p_choice integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE s private.iclub_exam_chemistry_entry_shadow_v1%ROWTYPE;
BEGIN
 IF p_id IS NULL OR p_order IS NULL OR p_choice IS NULL
 OR p_order NOT BETWEEN 1 AND 22 OR p_choice NOT BETWEEN 0 AND 3
 THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RETURN jsonb_build_object('ok',false,'code','qa_gate_closed'); END IF;
 SELECT * INTO s FROM private.iclub_exam_chemistry_entry_shadow_v1
 WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF s.status<>'active' OR clock_timestamp()>=s.deadline_at
 THEN RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired'); END IF;
 IF s.responses ? p_order::text AND (s.responses->p_order::text->>'choice')::int=p_choice
 THEN RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true); END IF;
 UPDATE private.iclub_exam_chemistry_entry_shadow_v1
 SET responses=jsonb_set(s.responses,ARRAY[p_order::text],jsonb_build_object(
 'choice',p_choice,'at',clock_timestamp()),true)
 WHERE id=p_id AND status='active';
 RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false);
END $f$;

CREATE FUNCTION private.iclub_exam_chemistry_entry_shadow_finish_v1(p_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE s private.iclub_exam_chemistry_entry_shadow_v1%ROWTYPE;
 points integer;answered integer;topics jsonb;
BEGIN
 IF p_id IS NULL THEN RETURN jsonb_build_object('ok',false,'code','invalid_request'); END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RETURN jsonb_build_object('ok',false,'code','qa_gate_closed'); END IF;
 SELECT * INTO s FROM private.iclub_exam_chemistry_entry_shadow_v1 WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
 IF s.status='finalized' THEN
 RETURN jsonb_build_object('ok',true,'score',s.score,'total',22,'duplicate',true,
 'calibrated_diagnostic',false,'can_credit_mastery',false); END IF;
 SELECT coalesce(sum(CASE WHEN s.responses ? q.n::text
 AND (q.item->'order'->>(s.responses->q.n::text->>'choice')::int)::int
 =ascii(q.item->>'key')-65 THEN 1 ELSE 0 END),0)::int,
 count(*) FILTER(WHERE s.responses ? q.n::text)::int,
 jsonb_agg(jsonb_build_object(
 'unit',(q.item->>'unit')::int,
 'correct',CASE WHEN s.responses ? q.n::text AND
 (q.item->'order'->>(s.responses->q.n::text->>'choice')::int)::int
 =ascii(q.item->>'key')-65 THEN true ELSE false END,
 'answered',s.responses ? q.n::text
 ) ORDER BY q.n)
 INTO points,answered,topics
 FROM jsonb_array_elements(s.items) WITH ORDINALITY q(item,n);
 UPDATE private.iclub_exam_chemistry_entry_shadow_v1
 SET status='finalized',score=points,finalized_at=clock_timestamp() WHERE id=p_id;
 RETURN jsonb_build_object('ok',true,'score',points,'total',22,
 'answered',answered,'topic_evidence',topics,
 'duplicate',false,'calibrated_diagnostic',false,'can_credit_mastery',false);
END $f$;

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_entry_shadow_start_v1(text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_entry_shadow_get_v1(uuid,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_entry_shadow_answer_v1(uuid,integer,integer)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_entry_shadow_finish_v1(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_entry_shadow_start_v1(text) TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_entry_shadow_get_v1(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_entry_shadow_answer_v1(uuid,integer,integer) TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_chemistry_entry_shadow_finish_v1(uuid) TO service_role;
DO $post$ BEGIN
 IF has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_start_v1(text)','EXECUTE')
 OR has_function_privilege('anon','private.iclub_exam_chemistry_entry_shadow_get_v1(uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_answer_v1(uuid,integer,integer)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_finish_v1(uuid)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_v1','SELECT')
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_entry_shadow_v1)<>0
 THEN RAISE EXCEPTION 'Entry QA shadow transport leaked or has user attempts'; END IF;
END $post$;