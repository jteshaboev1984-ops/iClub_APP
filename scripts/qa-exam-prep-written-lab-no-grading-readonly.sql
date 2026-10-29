-- Read-only production evidence for the approved iClub Exam Prep non-grading boundary.
-- No user identifiers are selected. No DDL, UPDATE, DELETE, INSERT or configuration changes.
-- Execute with Supabase SQL in a read-only transaction or inspect assertions directly.
BEGIN TRANSACTION READ ONLY;
DO $audit$
DECLARE v integer; v_p3 jsonb; v_p5 jsonb;
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
  WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027')<>22
 THEN RAISE EXCEPTION 'Economics 9708 reviewed written bank baseline changed'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_mark_scheme_v1 WHERE program_key='economics_9708')<>22
 THEN RAISE EXCEPTION 'Economics marking criteria bank changed'; END IF;
 IF (SELECT sum(max_marks) FROM private.iclub_exam_written_mark_scheme_v1 WHERE task_key LIKE 'P2.A.%')<>20
 OR (SELECT sum(max_marks) FROM private.iclub_exam_written_mark_scheme_v1 WHERE task_key LIKE 'P4.A.%')<>20
 THEN RAISE EXCEPTION 'Section A 20-mark question framing broken'; END IF;
 IF EXISTS (SELECT 1 FROM information_schema.columns
   WHERE table_schema='private'
     AND table_name='iclub_exam_core_written_plan_items_v1'
     AND column_name IN ('score','grade','marks_awarded','mastery','is_correct','essay_mark'))
 THEN RAISE EXCEPTION 'Written plan must only advance; grade field detected'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_j13_learning_control_v1
     WHERE paper3_enabled OR paper5_enabled)<>0
 THEN RAISE EXCEPTION 'Chemistry practical cards unexpectedly released'; END IF;
 IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname IN
    ('iclub_exam_chemistry_lab_catalog_v1','iclub_exam_chemistry_lab_lesson_v1')
    AND p.provolatile<>'s')
 THEN RAISE EXCEPTION 'Chemistry LAB lesson/catalog unexpectedly write-capable'; END IF;
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public' AND p.proname IN
     ('iclub_exam_chemistry_lab_catalog_v1','iclub_exam_chemistry_lab_lesson_v1')
     AND p.provolatile='s')<>2
 THEN RAISE EXCEPTION 'Chemistry LAB read contract absent'; END IF;
 IF has_table_privilege('authenticated','private.iclub_exam_written_mark_scheme_v1','SELECT')
 OR has_function_privilege('anon','public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Written marking scheme private boundary violated'; END IF;
END;$audit$;
SELECT
  (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
    WHERE program_key='economics_9708' AND task_version='economics_9708_written_editorial_candidate_v3_20261027') AS economics_original_written_practice_tasks,
  (SELECT count(*) FROM private.iclub_exam_written_mark_scheme_v1 WHERE program_key='economics_9708') AS private_exam_criteria,
  (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1
    WHERE program_key='economics_9708' AND status='advanced') AS written_steps_advanced_only,
  (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1 WHERE program_key='economics_9708') AS student_written_plans_preserved,
  (SELECT count(*) FROM private.iclub_exam_chemistry_j13_learning_control_v1
    WHERE paper3_enabled OR paper5_enabled) AS chemistry_lab_papers_released,
  'PASS: no app-issued written/lab grading; no data writes'::text AS non_grading_boundary;
ROLLBACK;