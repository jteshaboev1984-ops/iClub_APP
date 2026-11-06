-- New private Extra Hard bank metadata, signed-HTTP synthetic fixture only.
-- Read-only and fail-closed; no protected original tasks/answers in this test.
\set ON_ERROR_STOP on
DO $proof$
DECLARE v private.exam_prep_extra_hard_release_v1%ROWTYPE;
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR current_setting('server_version_num')::int<170000
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 THEN RAISE EXCEPTION 'NEW EXTRA HARD refused: not disposable two-user PG17'; END IF;
 SELECT * INTO v FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5';
 IF v.bank_version<>'math-extra-hard-2026-11-original-v2' OR v.enabled IS DISTINCT FROM false
 OR v.academic_approved IS DISTINCT FROM false
 OR EXISTS (SELECT 1 FROM private.exam_prep_extra_hard_tasks_v1)
 OR EXISTS (SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1)
 OR has_table_privilege('authenticated','private.exam_prep_extra_hard_tasks_v1','SELECT')
 OR has_table_privilege('anon','private.exam_prep_extra_hard_tasks_v1','SELECT')
 THEN RAISE EXCEPTION 'NEW EXTRA HARD stale bank, exposed answers or synthetic residue'; END IF;
 RAISE NOTICE 'EXTRA HARD NEW BANK V2 PASS: metadata migrated, zero tasks/attempts, release OFF, no answer leak';
END $proof$;
