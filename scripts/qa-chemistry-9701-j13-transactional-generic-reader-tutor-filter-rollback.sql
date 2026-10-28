-- J13 admin-only positive functional test for Chemistry Theory/Tutor separation.
-- Simulated library visibility exists ONLY inside BEGIN/ROLLBACK, not to other sessions.
BEGIN;
SET LOCAL statement_timeout='20000ms';
SET LOCAL lock_timeout='3000ms';
DO $test$
DECLARE k text; payload jsonb; econ_before text;econ_after text;
BEGIN
 IF (SELECT visible_to_learners FROM private.iclub_subject_library WHERE subject_key='chemistry')
 OR (SELECT count(*) FROM private.iclub_subject_library_release_events WHERE subject_key='chemistry')<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 THEN RAISE EXCEPTION 'J13 reader rehearsal requires unreleased Chemistry'; END IF;
 SELECT md5(public.iclub_subject_library_content_service_v1('economics',t.skill_key,'en')::text)
 INTO econ_before FROM private.iclub_subject_library_theory t
 JOIN private.iclub_subject_library l
 ON l.subject_key=t.subject_key AND l.active_version=t.version_key
 WHERE t.subject_key='economics' AND l.visible_to_learners LIMIT 1;
 SELECT skill_key INTO k FROM private.iclub_subject_library_theory
 WHERE subject_key='chemistry' AND version_key='chemistry9701_20261022_stageb_draft'
 ORDER BY skill_key LIMIT 1;
 UPDATE private.iclub_subject_library SET
  active_version='chemistry9701_20261022_stageb_draft',
  visible_to_learners=true WHERE subject_key='chemistry';
 payload:=public.iclub_subject_library_content_service_v1('chemistry',k,'en');
 IF payload IS NULL OR NOT(payload ? 'theory') OR (payload ? 'tutor')
 THEN RAISE EXCEPTION 'Chemistry privileged Theory reader exposes Tutor or has no Theory'; END IF;
 SELECT md5(public.iclub_subject_library_content_service_v1('economics',t.skill_key,'en')::text)
 INTO econ_after FROM private.iclub_subject_library_theory t
 JOIN private.iclub_subject_library l ON l.subject_key=t.subject_key
 AND l.active_version=t.version_key WHERE t.subject_key='economics' AND l.visible_to_learners
 LIMIT 1;
 IF econ_before IS DISTINCT FROM econ_after
 THEN RAISE EXCEPTION 'Economics reader changed due to Chemistry-only guard'; END IF;
 RAISE NOTICE 'J13 PASS: Chemistry Theory WITHOUT Tutor; Economics response invariant; ROLLBACK';
END $test$;
ROLLBACK;
