-- Architect 2026-11-06 replaced the lost 12 Extra Hard source drafts.
-- Twelve newly authored P1/P5 tasks (6+6) are stored ONLY in the owner's
-- PRIVATE BANK archive. Not included in Git history, browser assets, SQL, logs.
-- This additive schema transition changes EMPTY-bank version METADATA only.
-- NO task/question/answer payload; NO release; NO learner state deletion.
-- Applying to production requires a separate architect GO.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
DO $new_bank$
DECLARE
 v_cfg private.exam_prep_extra_hard_release_v1%ROWTYPE;
BEGIN
 SELECT * INTO v_cfg
 FROM private.exam_prep_extra_hard_release_v1
 WHERE program_key='math_as_p1_p5'
 FOR UPDATE;
 IF v_cfg.program_key IS NULL
  OR v_cfg.enabled IS DISTINCT FROM false
  OR v_cfg.academic_approved IS DISTINCT FROM false
  OR v_cfg.bank_version NOT IN ('secure-bank-v1-pending','math-extra-hard-2026-11-original-v2')
 THEN RAISE EXCEPTION 'new Extra Hard bank version requires original empty OFF state';
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_tasks_v1
    WHERE bank_version='secure-bank-v1-pending')
   OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1)
 THEN RAISE EXCEPTION 'new Extra Hard bank refuses to discard existing tasks or attempts';
 END IF;
 -- No legacy content is deleted and no public question is edited.
 UPDATE private.exam_prep_extra_hard_release_v1
 SET bank_version='math-extra-hard-2026-11-original-v2',updated_at=now()
 WHERE program_key='math_as_p1_p5';
 IF NOT EXISTS(
  SELECT 1 FROM private.exam_prep_extra_hard_release_v1
  WHERE program_key='math_as_p1_p5'
    AND bank_version='math-extra-hard-2026-11-original-v2' AND enabled=false
    AND academic_approved=false
 ) THEN RAISE EXCEPTION 'new Extra Hard bank version not installed OFF'; END IF;
END $new_bank$;
COMMIT;
