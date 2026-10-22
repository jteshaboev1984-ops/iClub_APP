-- Consolidate two concurrently added PRIVATE Stage 4 implementations.
-- Preserve the earlier, complete sequential-navigation functions and its
-- original unique active-plan index (migration 20261022152815).
-- Remove ONLY the three redundant PRIVATE objects introduced at 20261022152858.
-- No learner data or legacy structures are touched.
DO $guard$
BEGIN
 IF EXISTS (SELECT 1 FROM private.iclub_exam_core_written_plans_v1)
    OR EXISTS (SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1)
    OR EXISTS (SELECT 1 FROM private.iclub_exam_core_written_access_v1)
 THEN
   RAISE EXCEPTION 'Concurrent Stage4 consolidation requires empty written runtime';
 END IF;
 IF to_regclass('private.iclub_exam_core_written_one_active_plan_v1') IS NULL THEN
   RAISE EXCEPTION 'Preserved canonical active-plan index absent';
 END IF;
 IF NOT EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='private' AND p.proname='iclub_exam_core_written_plan_next_v1'
 ) THEN
  RAISE EXCEPTION 'Canonical ordered-navigation function absent';
 END IF;
END;
$guard$;
DROP FUNCTION IF EXISTS private.iclub_exam_core_written_next_item_v1(text,text,text);
DROP FUNCTION IF EXISTS private.iclub_exam_core_written_advance_v2(uuid,text,text,uuid,text);
DROP INDEX IF EXISTS private.iclub_exam_written_one_active_plan_v1;
