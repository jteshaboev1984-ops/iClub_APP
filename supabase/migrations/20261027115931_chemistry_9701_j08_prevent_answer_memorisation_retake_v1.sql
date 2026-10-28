-- J08 anti-memorisation: one entry assessment per user and source snapshot.
-- No grade, answer or existing P1 user record is modified.
CREATE UNIQUE INDEX chemistry_entry_no_same_form_retake_uq
ON private.iclub_exam_chemistry_entry_attempts_v1(user_id,source_manifest_md5);
CREATE OR REPLACE FUNCTION public.iclub_exam_chemistry_entry_start_v1(p_client_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 -- An entry check must NOT be retaken after the learner has seen its answers.
 -- The current source hash, not a new client nonce or release label, determines reuse.
 SELECT * INTO v FROM private.iclub_exam_chemistry_entry_attempts_v1
 WHERE user_id=v_user AND source_manifest_md5=(
 SELECT approved_manifest_md5 FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 ORDER BY started_at DESC LIMIT 1;
 IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v.id,
 'resumed',true,'status',v.status,'deadline_at',v.deadline_at,
 'same_source_reused',true); END IF;
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
END $function$;
REVOKE ALL ON FUNCTION public.iclub_exam_chemistry_entry_start_v1(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_chemistry_entry_start_v1(text) TO authenticated;
DO $verify$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 OR has_function_privilege('anon','public.iclub_exam_chemistry_entry_start_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Entry anti-retake created unexpected access or attempts'; END IF;
END $verify$;