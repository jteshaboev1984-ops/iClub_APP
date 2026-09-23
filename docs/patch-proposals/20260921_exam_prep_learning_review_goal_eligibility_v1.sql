-- REVIEW-ONLY SQL proposal. Apply after private verdict, guarded start and recovery patches.
-- Old content-exhausted response remains for unenrolled users and for any
-- unverifiable, completed or fresh-retest-pending attempt; no academic writes.
BEGIN;
DO $patch$
DECLARE
 v_oid oid;
 v_def text;
 v_old text;
 v_new text;
BEGIN
 IF to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') IS NULL
 OR to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NULL THEN
  RAISE EXCEPTION 'review_goal_eligibility_prerequisite_missing';
 END IF;
 v_oid:=to_regprocedure('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)');
 IF v_oid IS NULL THEN RAISE EXCEPTION 'review_goal_eligibility_missing_rpc'; END IF;
 v_def:=pg_get_functiondef(v_oid);
 v_old:='    return jsonb_build_object(''status'',''waiting'',''reason'',''attempt_already_saved'');';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_goal_eligibility_consumed_anchor_drift'; END IF;
 v_new:='    IF v_item.item_type IN (''learning'',''correction'') AND v_auth.purpose=''learning'' '
 ||'AND private.exam_prep_weekly_flow_enrolled_v1(v_uid) '
 ||'AND (private.exam_prep_learning_review_verdict_v1(v_uid,v_program,p_component_code,v_item.skill_code,v_auth.assessment_id)->>''status'')=''repeat_learning'' THEN'
 ||chr(10)||'      RETURN jsonb_build_object(''status'',''review_ready'',''reason'',''same_pack_learning_review'', '
 ||'''component_code'',p_component_code,''goal_id'',v_goal.id,''plan_id'',v_plan.id, '
 ||'''priority_order'',v_item.priority_order,''skill_code'',v_item.skill_code,''item_type'',v_item.item_type, '
 ||'''fresh_assessment'',false);'
 ||chr(10)||'    END IF;'
 ||chr(10)||v_old;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='      return jsonb_build_object(''status'',''content_exhausted'','||chr(10)
  ||'        ''reason'',''previously_seen_learning_pack'');';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_goal_eligibility_exhausted_anchor_drift'; END IF;
 v_new:='      IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) '
 ||'AND (private.exam_prep_learning_review_verdict_v1(v_uid,v_program,p_component_code,v_item.skill_code,v_assessment)->>''status'')=''repeat_learning'' THEN'
 ||chr(10)||'        RETURN jsonb_build_object(''status'',''review_ready'',''reason'',''same_pack_learning_review'', '
 ||'''component_code'',p_component_code,''goal_id'',v_goal.id,''plan_id'',v_plan.id, '
 ||'''priority_order'',v_item.priority_order,''skill_code'',v_item.skill_code,''item_type'',v_item.item_type, '
 ||'''fresh_assessment'',false);'
 ||chr(10)||'      END IF;'
 ||chr(10)||v_old;
 EXECUTE replace(v_def,v_old,v_new);
END;$patch$;
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)','EXECUTE') THEN
  RAISE EXCEPTION 'review_goal_eligibility_acl_changed'; END IF;
END;$verify$;
COMMIT;
