-- Dispose ONLY the single synthetic Extra Hard task/attempt in local PG.
\set ON_ERROR_STOP on
DO $$
BEGIN
 IF current_database()<>'postgres' OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
  OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'REFUSED: cleanup only on isolated PG with two synthetic users'; END IF;
END $$;
DELETE FROM private.exam_prep_extra_hard_attempts_v1 WHERE task_key='CI-EXTRA-HARD-TEST-01';
DELETE FROM private.exam_prep_extra_hard_tasks_v1 WHERE task_key='CI-EXTRA-HARD-TEST-01';
UPDATE private.exam_prep_extra_hard_release_v1
 SET academic_approved=false,enabled=false,updated_at=now()
 WHERE program_key='math_as_p1_p5';
