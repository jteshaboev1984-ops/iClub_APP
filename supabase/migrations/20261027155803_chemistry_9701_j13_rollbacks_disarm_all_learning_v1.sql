DO $guard$ BEGIN
 IF to_regclass('private.iclub_exam_chemistry_j13_learning_control_v1') IS NULL
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 THEN RAISE EXCEPTION 'Cannot extend J13 emergency shutdown in live Chemistry'; END IF;
END $guard$;
CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_j12_admin_hide_v1(p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE c private.iclub_exam_chemistry_j12_release_control_v1%ROWTYPE;
 lib private.iclub_subject_library%ROWTYPE;
 n integer;
BEGIN
 IF current_user<>'postgres' THEN
 RAISE EXCEPTION 'J12 hide is exclusively an administrator operation' USING ERRCODE='42501'; END IF;
 IF p_reason IS NULL OR length(trim(p_reason))<10
 THEN RETURN jsonb_build_object('hidden',false,'code','reason_required'); END IF;
 SELECT * INTO c FROM private.iclub_exam_chemistry_j12_release_control_v1
 WHERE id=1 FOR UPDATE;
 SELECT * INTO lib FROM private.iclub_subject_library
 WHERE subject_key='chemistry' FOR UPDATE;
 IF c.published_at IS NULL OR c.published_version IS NULL
 THEN RETURN jsonb_build_object('hidden',false,'code','no_composite_release_to_hide'); END IF;
 IF lib.visible_to_learners IS DISTINCT FROM true OR
 lib.active_version IS DISTINCT FROM c.published_version THEN
 RETURN jsonb_build_object('hidden',false,'code','already_hidden_or_version_changed'); END IF;
 UPDATE private.iclub_subject_library
 SET visible_to_learners=false,
 active_version=c.previous_active_version,updated_at=clock_timestamp()
 WHERE subject_key='chemistry';
 GET DIAGNOSTICS n=ROW_COUNT;
 IF n<>1 THEN RAISE EXCEPTION 'Subject disappeared while hiding'; END IF;
 INSERT INTO private.iclub_subject_library_release_events
 (subject_key,from_version,to_version,action)
 VALUES('chemistry',c.published_version,c.previous_active_version,'hide');
 UPDATE private.iclub_exam_chemistry_j12_release_control_v1
 SET armed=false,hidden_at=clock_timestamp() WHERE id=1;
 UPDATE private.iclub_exam_chemistry_j13_learning_control_v1
 SET paper3_enabled=false,paper5_enabled=false,tutor_sources_enabled=false,
 paper3_owner_go_at=NULL,paper5_owner_go_at=NULL,tutor_owner_go_at=NULL,
 approved_source_md5=NULL WHERE id=1;
 RETURN jsonb_build_object('hidden',true,'subject','chemistry',
 'visible',false,'attempts_preserved',true,'reason_recorded',false,
 'validated_content_preserved',true);
END $function$
;
CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
 UPDATE private.iclub_exam_chemistry_entry_release_v1 SET enabled=false,owner_go_at=NULL WHERE id=1;
 UPDATE private.iclub_exam_chemistry_recheck_control_v1 SET enabled=false,owner_go_at=NULL WHERE id=1;
 UPDATE private.iclub_exam_chemistry_p1_beta_control_v1 SET enabled=false,owner_go_at=NULL WHERE id=1;

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

 UPDATE private.iclub_exam_chemistry_j13_learning_control_v1
 SET paper3_enabled=false,paper5_enabled=false,tutor_sources_enabled=false,
 paper3_owner_go_at=NULL,paper5_owner_go_at=NULL,tutor_owner_go_at=NULL,
 approved_source_md5=NULL WHERE id=1;
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
END $function$
;
DO $test$ BEGIN
 IF pg_get_functiondef('private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)'::regprocedure)
 NOT LIKE '%paper3_enabled=false,paper5_enabled=false,tutor_sources_enabled=false%'
 OR pg_get_functiondef('private.iclub_exam_chemistry_j12_admin_hide_v1(text)'::regprocedure)
 NOT LIKE '%approved_source_md5=NULL%'
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_chemistry_j12_admin_hide_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'J13 rollback extension failed'; END IF;
END $test$;
