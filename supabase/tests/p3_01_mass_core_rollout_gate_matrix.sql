-- P3-01 Mass Core rollout gate matrix.
-- Decision tooling only. Never activates mass rollout.
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_gate jsonb;
  v_before jsonb;
  v_after jsonb;
BEGIN
  if to_regprocedure('private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)') is null then
    raise exception 'P3-01 gate function missing';
  end if;

  if has_function_privilege('anon','private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_p3_01_mass_core_rollout_gate_v1(text)','EXECUTE')
  then
    raise exception 'P3-01 decision function leaked to learner roles';
  end if;

  v_before:=jsonb_build_object(
    'feature_config',(select to_jsonb(f) from private.exam_prep_feature_config f where id=1),
    'users',(select count(*) from public.users),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates),
    'beta_members',(select count(*) from private.exam_prep_beta_members),
    'weekly_reviews',(select count(*) from private.exam_prep_beta_weekly_reviews)
  );

  v_gate:=private.exam_prep_p3_01_mass_core_rollout_gate_v1('__missing_p3_01_cohort__');

  if coalesce((v_gate->>'ready')::boolean,true)
     or v_gate->>'decision'<>'NO_GO'
     or v_gate->>'reason_code'<>'cohort_not_found'
     or coalesce((v_gate->>'automatic_rollout_permitted')::boolean,true)
     or coalesce((v_gate->>'learner_state_mutated')::boolean,true)
     or coalesce((v_gate->>'legacy_state_mutated')::boolean,true)
     or coalesce((v_gate->>'core_only_decision')::boolean,false) is not true
     or coalesce((v_gate->>'ai_scale_independent')::boolean,false) is not true
     or coalesce((v_gate->>'mentor_scale_independent')::boolean,false) is not true
  then
    raise exception 'P3-01 missing-cohort fail-closed payload mismatch: %',v_gate;
  end if;

  v_after:=jsonb_build_object(
    'feature_config',(select to_jsonb(f) from private.exam_prep_feature_config f where id=1),
    'users',(select count(*) from public.users),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates),
    'beta_members',(select count(*) from private.exam_prep_beta_members),
    'weekly_reviews',(select count(*) from private.exam_prep_beta_weekly_reviews)
  );

  if v_before<>v_after then
    raise exception 'P3-01 read-only gate mutated product state before=% after=%',v_before,v_after;
  end if;
END
$$;

ROLLBACK;

\echo 'P3-01 Mass Core rollout gate matrix: GREEN'
