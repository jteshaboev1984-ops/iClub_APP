-- P3-02 synthetic isolation / AI scale guard.
-- Isolated CI only. Proves engineering synthetic activity cannot satisfy real rollout evidence.
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_gate_before jsonb;
  v_gate_after jsonb;
  v_reviews_before bigint;
  v_reviews_after bigint;
  v_cfg_before jsonb;
  v_cfg_after jsonb;
  v_def text;
BEGIN
  IF to_regprocedure('private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)') IS NULL THEN
    RAISE EXCEPTION 'P3-02 requires P3-01 decision gate';
  END IF;
  IF to_regprocedure('private.exam_prep_beta_expansion_gate_v1(text)') IS NULL THEN
    RAISE EXCEPTION 'P3-02 requires expanded-beta evidence gate';
  END IF;
  IF to_regprocedure('private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text)') IS NULL THEN
    RAISE EXCEPTION 'P3-02 requires governed synthetic cleanup engine';
  END IF;

  v_def:=lower(pg_get_functiondef('private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)'::regprocedure));
  IF position('synthetic' in v_def)>0 THEN
    RAISE EXCEPTION 'P3-01 real rollout gate must not read synthetic state';
  END IF;

  v_def:=lower(pg_get_functiondef('private.exam_prep_beta_expansion_gate_v1(text)'::regprocedure));
  IF position('synthetic' in v_def)>0 THEN
    RAISE EXCEPTION 'expanded-beta real evidence gate must not read synthetic state';
  END IF;

  v_def:=lower(pg_get_functiondef('private.cleanup_exam_prep_synthetic_run_v1(text,integer,text,text)'::regprocedure));
  IF position('beta_weekly_reviews' in v_def)=0 THEN
    RAISE EXCEPTION 'synthetic cleanup must protect real beta weekly-review count';
  END IF;

  SELECT count(*) INTO v_reviews_before FROM private.exam_prep_beta_weekly_reviews;
  SELECT to_jsonb(f) INTO v_cfg_before FROM private.exam_prep_feature_config f WHERE id=1;
  v_gate_before:=private.exam_prep_p3_01_mass_core_rollout_gate_v1('p236-ci-cohort');

  PERFORM private.register_exam_prep_synthetic_validation_run_v1(
    'SV-P302-AI-ISOLATION',
    'p3-02-synthetic-ai-isolation-v1',
    repeat('3',40),
    'p3-02',
    30201,
    'ai_shadow',
    'p3-02-isolation-proof'
  );

  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    'SV-P302-AI-ISOLATION',
    'registered',
    'running',
    null,
    null,
    jsonb_build_object('p3_02','synthetic-start')
  );

  -- Engineering activity is intentionally synthetic-only and must never create
  -- real beta review rows or change the real rollout decision.
  SELECT count(*) INTO v_reviews_after FROM private.exam_prep_beta_weekly_reviews;
  SELECT to_jsonb(f) INTO v_cfg_after FROM private.exam_prep_feature_config f WHERE id=1;
  v_gate_after:=private.exam_prep_p3_01_mass_core_rollout_gate_v1('p236-ci-cohort');

  IF v_reviews_after<>v_reviews_before THEN
    RAISE EXCEPTION 'synthetic run changed real weekly-review count before=% after=%',v_reviews_before,v_reviews_after;
  END IF;
  IF v_cfg_after<>v_cfg_before THEN
    RAISE EXCEPTION 'synthetic run changed feature state before=% after=%',v_cfg_before,v_cfg_after;
  END IF;
  IF v_gate_after<>v_gate_before THEN
    RAISE EXCEPTION 'synthetic run changed real P3-01 decision before=% after=%',v_gate_before,v_gate_after;
  END IF;

  IF coalesce((v_gate_after->>'automatic_rollout_permitted')::boolean,true) THEN
    RAISE EXCEPTION 'P3-01 automatic rollout became permitted during synthetic validation';
  END IF;
END
$$;

ROLLBACK;

\echo 'P3-02 synthetic isolation / AI scale guard: GREEN'
