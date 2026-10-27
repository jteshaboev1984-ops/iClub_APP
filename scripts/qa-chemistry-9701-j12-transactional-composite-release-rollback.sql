-- iClub Chemistry 9701 J12: reproducible ADMIN-only transaction rehearsal.
-- All approvals below are SYNTHETIC and ROLLBACK; do not execute with active Chemistry.
-- No learner IDs, unpublished questions, answer keys, or raw content here.
BEGIN;
SET LOCAL statement_timeout='70000ms';
SET LOCAL lock_timeout='3000ms';
DO $qa$
DECLARE s text;h text;r jsonb;
BEGIN
 IF (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR (SELECT armed FROM private.iclub_exam_chemistry_j12_release_control_v1 WHERE id=1)
 OR (SELECT count(*) FROM private.iclub_subject_library_release_events WHERE subject_key='chemistry')<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_attempts_v1)<>0
 THEN RAISE EXCEPTION 'J12 rehearsal refuses non-empty/live Chemistry'; END IF;
 SELECT package_sha256 INTO s FROM private.iclub_subject_library_releases WHERE subject_key='chemistry';
 SELECT source_snapshot_md5 INTO h FROM private.iclub_exam_chemistry_j12_release_gate_v1;
 r:=private.iclub_exam_chemistry_j12_admin_publish_v1(
 'chemistry9701_20261022_stageb_draft',s,h,'ICLUB_CHEMISTRY_9701_166_OWNER_GO');
 IF r->>'code'<>'owner_release_not_armed' THEN RAISE EXCEPTION 'Unapproved publish not blocked'; END IF;

 -- Hypothetical owner approval, not durable due to ROLLBACK.
 UPDATE private.iclub_exam_chemistry_j12_release_control_v1 SET
 armed=true,owner_go_at=clock_timestamp(),
 approved_version='chemistry9701_20261022_stageb_draft',
 approved_package_sha256=s,approved_source_md5=h,
 rights_review_at=clock_timestamp(),backup_restore_verified_at=clock_timestamp(),
 lab_delivery_verified_at=clock_timestamp(),tutor_access_isolated_at=clock_timestamp(),
 authenticated_device_qa_at=clock_timestamp() WHERE id=1;
 r:=private.iclub_exam_chemistry_j12_admin_publish_v1(
 'chemistry9701_20261022_stageb_draft',s,h,'ICLUB_CHEMISTRY_9701_166_OWNER_GO');
 IF r->>'published'<>'true' OR r->>'theory_skills'<>'154' OR r->>'lab_skills'<>'12'
 OR (SELECT count(*) FROM private.iclub_subject_library_cross_tour_v1
 WHERE subject_key='chemistry' AND state='validated')<>12
 THEN RAISE EXCEPTION 'Simulated 166 publish failed'; END IF;
 r:=private.iclub_exam_chemistry_j12_admin_publish_v1(
 'chemistry9701_20261022_stageb_draft',s,h,'ICLUB_CHEMISTRY_9701_166_OWNER_GO');
 IF r->>'code'<>'owner_release_not_armed' THEN RAISE EXCEPTION 'Replay allowed'; END IF;

 r:=private.iclub_exam_chemistry_j12_admin_hide_v1('J12 release-only rollback rehearsal');
 IF r->>'hidden'<>'true' OR (SELECT visible_to_learners FROM private.iclub_subject_library
 WHERE subject_key='chemistry') THEN RAISE EXCEPTION 'Hide failed'; END IF;

 -- Also exercise all-gate emergency shutoff using temporarily simulated state.
 UPDATE private.iclub_exam_core_programs_v1 SET status='published',launch_enabled=true
 WHERE program_key='chemistry_9701';
 UPDATE private.iclub_subject_library
 SET active_version='chemistry9701_20261022_stageb_draft',visible_to_learners=true
 WHERE subject_key='chemistry';
 UPDATE private.iclub_exam_chemistry_entry_release_v1 SET enabled=true,
 owner_go_at=clock_timestamp(),release_version='j12_rehearsal_entry',
 approved_manifest_md5=md5('synthetic entry approval') WHERE id=1;
 UPDATE private.iclub_exam_chemistry_recheck_control_v1 SET enabled=true,
 owner_go_at=clock_timestamp(),release_version='j12_rehearsal_recheck',
 approved_manifest_md5=md5('synthetic recheck approval') WHERE id=1;
 UPDATE private.iclub_exam_chemistry_p1_beta_control_v1 SET enabled=true,
 owner_go_at=clock_timestamp(),approved_content_manifest=repeat('f',32) WHERE id=1;
 r:=private.iclub_exam_chemistry_j12_admin_emergency_stop_v1('J12 simulated complete Chemistry emergency stop');
 IF r->>'stopped'<>'true'
 OR (SELECT launch_enabled FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701')
 OR (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR (SELECT enabled OR owner_go_at IS NOT NULL FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 OR (SELECT enabled OR owner_go_at IS NOT NULL FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1)
 OR (SELECT enabled OR owner_go_at IS NOT NULL FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1)
 THEN RAISE EXCEPTION 'Unified emergency stop failed'; END IF;
 IF (SELECT count(*) FROM private.iclub_subject_library_theory WHERE subject_key='chemistry')<>154
 OR (SELECT count(*) FROM private.iclub_subject_library_tutor WHERE subject_key='chemistry')<>462
 OR (SELECT count(*) FROM private.iclub_subject_library_cross_tour_v1 WHERE subject_key='chemistry')<>12
 OR (SELECT count(*) FROM private.exam_prep_sessions)<544
 OR (SELECT count(*) FROM public.practice_attempts)<502
 THEN RAISE EXCEPTION 'Rehearsal modified existing content/progress'; END IF;
 RAISE NOTICE 'PASS: 166-card publish -> reject duplicate -> hide -> complete emergency stop. ROLLBACK';
END $qa$;
ROLLBACK;