-- P2-12 / C23 Product Content-Complete label governance matrix.
-- Product metadata only. No learner evidence, mastery, stage, correction or legacy history may change.
\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p212_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
  (SELECT count(*) FROM private.exam_prep_skill_states) skill_states,
  (SELECT count(*) FROM private.exam_prep_stage_states) stage_states,
  (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases,
  (SELECT count(*) FROM private.exam_prep_timed_attempt_results) timed_results,
  (SELECT count(*) FROM private.exam_prep_weekly_plans) weekly_plans,
  (SELECT count(*) FROM public.practice_attempts) practice_attempts,
  (SELECT count(*) FROM public.practice_answers) practice_answers,
  (SELECT count(*) FROM public.tour_attempts) tour_attempts,
  (SELECT count(*) FROM public.tour_answers) tour_answers,
  (SELECT count(*) FROM public.certificates) certificates;

DO $$
DECLARE
  v_program bigint;
  v_constraint_valid boolean;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-12 active program missing'; END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM private.exam_prep_product_roadmap_milestones
    WHERE program_version_id=v_program
      AND milestone_key='product_content_complete'
      AND milestone_kind='product_content_complete'
      AND target_date=date '2027-02-15'
      AND product_label='Product Content-Complete'
  ) THEN
    RAISE EXCEPTION 'P2-12 canonical Product Content-Complete milestone missing/mislabeled';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_product_roadmap_milestones
    WHERE lower(product_label) like '%as ready%'
       OR lower(product_label) like '%exam ready%'
  ) THEN
    RAISE EXCEPTION 'P2-12 forbidden product readiness terminology exists';
  END IF;

  SELECT c.convalidated INTO v_constraint_valid
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='private'
    AND t.relname='exam_prep_product_roadmap_milestones'
    AND c.conname='exam_prep_product_roadmap_label_governance_v1';
  IF v_constraint_valid IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-12 product label governance constraint is missing or not validated';
  END IF;

  BEGIN
    UPDATE private.exam_prep_product_roadmap_milestones
    SET product_label='100% AS READY'
    WHERE program_version_id=v_program AND milestone_key='product_content_complete';
    RAISE EXCEPTION 'P2-12 guard accepted forbidden AS READY product label';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    UPDATE private.exam_prep_product_roadmap_milestones
    SET product_label='Learner Exam Ready'
    WHERE program_version_id=v_program AND milestone_key='product_content_complete';
    RAISE EXCEPTION 'P2-12 guard accepted forbidden learner Exam Ready product label';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  IF NOT EXISTS(
    SELECT 1
    FROM private.exam_prep_product_roadmap_milestones
    WHERE program_version_id=v_program
      AND milestone_key='product_content_complete'
      AND product_label='Product Content-Complete'
      AND can_force_learner_stage=false
      AND can_raise_learner_mastery=false
      AND can_label_learner_exam_ready=false
  ) THEN
    RAISE EXCEPTION 'P2-12 product/learner firewall drifted';
  END IF;
END
$$;

DO $$
DECLARE
  b record;
  a record;
BEGIN
  SELECT * INTO b FROM p212_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
    (SELECT count(*) FROM private.exam_prep_skill_states) skill_states,
    (SELECT count(*) FROM private.exam_prep_stage_states) stage_states,
    (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases,
    (SELECT count(*) FROM private.exam_prep_timed_attempt_results) timed_results,
    (SELECT count(*) FROM private.exam_prep_weekly_plans) weekly_plans,
    (SELECT count(*) FROM public.practice_attempts) practice_attempts,
    (SELECT count(*) FROM public.practice_answers) practice_answers,
    (SELECT count(*) FROM public.tour_attempts) tour_attempts,
    (SELECT count(*) FROM public.tour_answers) tour_answers,
    (SELECT count(*) FROM public.certificates) certificates
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-12 label guard mutated learner/legacy state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;
END
$$;

ROLLBACK;

\echo 'P2-12 Product Content-Complete label matrix: GREEN'
