-- J12 fail-safe all-Chemistry emergency stop. No DELETE/TRUNCATE or progress reset.
-- Revoke in-place future issue gates; preserve consent records, attempts, manifest history,
-- 154 Theory, 462 Tutor and 12 LAB source rows, untouched other subjects.
CREATE FUNCTION private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(
 p_reason text
) RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path=''
AS $func$
DECLARE previous_version text;was_visible boolean;prev_program_status text;
BEGIN
 IF current_user<>'postgres'
 THEN RAISE EXCEPTION 'Chemistry emergency stop requires the database administrator'
 USING ERRCODE='42501'; END IF;
 IF p_reason IS NULL OR length(trim(p_reason))<10
 THEN RETURN jsonb_build_object('stopped',false,'code','explicit_reason_required'); END IF;

 -- Serialize with J12 publisher (controller first, subject second).
 PERFORM 1 FROM private.iclub_exam_chemistry_j12_release_control_v1
 WHERE id=1 FOR UPDATE;
 SELECT active_version,visible_to_learners INTO previous_version,was_visible
 FROM private.iclub_subject_library
 WHERE subject_key='chemistry' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Chemistry library missing'; END IF;

 UPDATE private.iclub_exam_core_programs_v1
 SET status='draft',launch_enabled=false
 WHERE program_key='chemistry_9701';
 UPDATE private.iclub_exam_chemistry_entry_release_v1 SET enabled=false WHERE id=1;
 UPDATE private.iclub_exam_chemistry_recheck_control_v1 SET enabled=false WHERE id=1;
 UPDATE private.iclub_exam_chemistry_p1_beta_control_v1 SET enabled=false WHERE id=1;

 UPDATE private.iclub_subject_library
 SET visible_to_learners=false,active_version=NULL,updated_at=clock_timestamp()
 WHERE subject_key='chemistry';
 IF was_visible THEN
 INSERT INTO private.iclub_subject_library_release_events
 (subject_key,from_version,to_version,action)
 VALUES('chemistry',previous_version,NULL,'hide');
 END IF;
 UPDATE private.iclub_exam_chemistry_j12_release_control_v1
 SET armed=false, hidden_at=CASE WHEN published_at IS NULL THEN hidden_at
 ELSE clock_timestamp() END
 WHERE id=1;

 IF (SELECT launch_enabled FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701')
 OR (SELECT visible_to_learners FROM private.iclub_subject_library
 WHERE subject_key='chemistry')
 OR (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 OR (SELECT enabled FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1)
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1)
 THEN RAISE EXCEPTION 'Chemistry kill switches not all disabled, rolled back'; END IF;

 RETURN jsonb_build_object('stopped',true,'subject','chemistry',
 'entry_enabled',false,'recheck_enabled',false,'p1_enabled',false,
 'library_visible',false,'program_launch_enabled',false,
 'user_data_preserved',true);
END $func$;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)
 FROM PUBLIC,anon,authenticated,service_role;
DO $post$ DECLARE x jsonb;BEGIN
 IF has_function_privilege('anon','private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)','EXECUTE')
 OR has_function_privilege('service_role','private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Emergency stop exposed to browser roles'; END IF;
 SELECT private.iclub_exam_chemistry_j12_admin_emergency_stop_v1('') INTO x;
 IF x->>'code'<>'explicit_reason_required'
 THEN RAISE EXCEPTION 'Emergency stop does not demand reason'; END IF;
END $post$;