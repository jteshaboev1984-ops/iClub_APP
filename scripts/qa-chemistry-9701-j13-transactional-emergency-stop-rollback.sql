-- J13 postgres-only transactional safety rehearsal; all artificial approvals ROLLBACK.
-- Never run in learner-active Chemistry; precondition below fails closed.
BEGIN;
SET LOCAL statement_timeout='35000ms';
SET LOCAL lock_timeout='3000ms';
DO $test$
DECLARE v_digest text;v_result jsonb;
BEGIN
 IF (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR (SELECT launch_enabled FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701')
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_j13_a_level_permissions_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_j13_tutor_permissions_v1)<>0
 THEN RAISE EXCEPTION 'J13 rehearsal must run only on closed and empty Chemistry beta'; END IF;
 SELECT source_snapshot_md5 INTO v_digest
 FROM private.iclub_exam_chemistry_j12_release_gate_v1;
 UPDATE private.iclub_exam_chemistry_j13_learning_control_v1
 SET paper3_enabled=true,paper5_enabled=true,tutor_sources_enabled=true,
  paper3_owner_go_at=clock_timestamp(),paper5_owner_go_at=clock_timestamp(),
  tutor_owner_go_at=clock_timestamp(),approved_source_md5=v_digest
 WHERE id=1;
 IF NOT (SELECT paper3_enabled AND paper5_enabled AND tutor_sources_enabled
 FROM private.iclub_exam_chemistry_j13_learning_control_v1 WHERE id=1)
 THEN RAISE EXCEPTION 'Unable to synthesize gated state'; END IF;
 v_result:=private.iclub_exam_chemistry_j12_admin_emergency_stop_v1(
  'J13 transaction-only learner-access rollback regression');
 IF v_result->>'stopped'<>'true'
 OR (SELECT paper3_enabled OR paper5_enabled OR tutor_sources_enabled
  OR paper3_owner_go_at IS NOT NULL OR paper5_owner_go_at IS NOT NULL
  OR tutor_owner_go_at IS NOT NULL OR approved_source_md5 IS NOT NULL
  FROM private.iclub_exam_chemistry_j13_learning_control_v1 WHERE id=1)
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR (SELECT launch_enabled FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701')
 THEN RAISE EXCEPTION 'J13 unified emergency stop failed'; END IF;
 RAISE NOTICE 'J13 PASS: synthetic P3+P5+Tutor access disarmed by existing Chemistry emergency stop; ROLLBACK';
END $test$;
ROLLBACK;
