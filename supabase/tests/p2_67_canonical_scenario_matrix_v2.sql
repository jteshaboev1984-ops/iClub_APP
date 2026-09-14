\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p267.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-67 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_report jsonb;
  v_expected_profiles text[]:=array[
    'ai-unavailable','beginner','exam-mode-candidate','fast-inaccurate','half-syllabus',
    'illness-interruption','late-joiner','mcq-strong-input-weak','mentor-override',
    'offline-retry','prerequisite-gaps','slow-accurate','strong-p1','strong-p5','topic-strong-mixed-weak'
  ];
  v_actual_profiles text[];
  v_blocked boolean;
  v_run jsonb;
  v_before_users bigint;
  v_before_beta bigint;
  v_before_legacy jsonb;
BEGIN
  v_report:=private.exam_prep_synthetic_scenario_set_report_v1('p2_67_canonical_v2_0');
  IF coalesce((v_report->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_report->>'total_scenarios')::int,-1)<>33
     OR coalesce((v_report->>'canonical_profiles')::int,-1)<>15
     OR coalesce((v_report->>'adversarial_variants')::int,-1)<>18
     OR coalesce((v_report->>'canonical_source_profiles')::int,-1)<>15
     OR coalesce((v_report->>'locale_violations')::int,-1)<>0
     OR coalesce(jsonb_array_length(v_report->'missing_required_tags'),-1)<>0
     OR v_report->>'manifest_hash' IS DISTINCT FROM v_report->>'recomputed_manifest_hash' THEN
    RAISE EXCEPTION 'P2-67 scenario set report invalid: %',v_report;
  END IF;

  SELECT array_agg(source_profile_id order by source_profile_id)
  INTO v_actual_profiles
  FROM private.exam_prep_synthetic_scenarios
  WHERE scenario_set_version='p2_67_canonical_v2_0'
    AND scenario_type='canonical_profile';
  IF v_actual_profiles IS DISTINCT FROM v_expected_profiles THEN
    RAISE EXCEPTION 'P2-67 canonical profile IDs drifted expected=% actual=%',v_expected_profiles,v_actual_profiles;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_synthetic_scenarios
    WHERE scenario_set_version='p2_67_canonical_v2_0'
      AND learner_facing
      AND NOT(required_locales @> array['en','ru','uz'] AND required_locales <@ array['en','ru','uz'])
  ) THEN
    RAISE EXCEPTION 'P2-67 learner-facing locale scope is incomplete';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_synthetic_scenarios
    WHERE scenario_set_version='p2_67_canonical_v2_0'
      AND scenario_type='canonical_profile'
      AND (initial_state->'p1' IS NULL OR initial_state->'p5' IS NULL)
  ) THEN
    RAISE EXCEPTION 'P2-67 canonical profile missing separate P1/P5 initial state';
  END IF;

  IF EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='private'
      AND table_name IN ('exam_prep_synthetic_scenario_sets','exam_prep_synthetic_scenarios')
      AND column_name IN ('user_id','learner_user_id','mentor_user_id','email','phone','telegram_id')
  ) THEN
    RAISE EXCEPTION 'P2-67 scenario definitions contain person-linked columns';
  END IF;

  -- Definition rows are immutable once the manifest is activated.
  v_blocked:=false;
  BEGIN
    UPDATE private.exam_prep_synthetic_scenarios
    SET component_focus='NONE'
    WHERE scenario_set_version='p2_67_canonical_v2_0' AND deterministic_ordinal=1;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_scenario_definition_immutable' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-67 scenario definition was mutable'; END IF;

  v_blocked:=false;
  BEGIN
    DELETE FROM private.exam_prep_synthetic_scenario_sets
    WHERE scenario_set_version='p2_67_canonical_v2_0';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_scenario_definition_immutable' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-67 scenario set was deletable'; END IF;

  -- Browser roles cannot inspect scenario definitions or start engineering runs.
  IF has_table_privilege('anon','private.exam_prep_synthetic_scenario_sets','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_scenario_sets','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_scenarios','SELECT')
     OR has_function_privilege('authenticated','private.exam_prep_synthetic_scenario_set_report_v1(text)','EXECUTE')
     OR has_function_privilege('authenticated','private.register_exam_prep_canonical_synthetic_run_v2(text,text,text,text,bigint,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-67 scenario registry became browser-accessible';
  END IF;
  IF NOT has_table_privilege('service_role','private.exam_prep_synthetic_scenario_sets','SELECT')
     OR NOT has_table_privilege('service_role','private.exam_prep_synthetic_scenarios','SELECT')
     OR NOT has_function_privilege('service_role','private.exam_prep_synthetic_scenario_set_report_v1(text)','EXECUTE')
     OR NOT has_function_privilege('service_role','private.register_exam_prep_canonical_synthetic_run_v2(text,text,text,text,bigint,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-67 service-role scenario boundary missing';
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
      'SV-P267CI-BADSET','unknown-scenario-set',repeat('a',40),'p2-67',26701,'core','p2-67-bad-set-proof'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_scenario_set_not_found' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-67 governed registration accepted unknown scenario set'; END IF;

  SELECT count(*) INTO v_before_users FROM public.users;
  SELECT count(*) INTO v_before_beta FROM private.exam_prep_beta_members;
  SELECT jsonb_build_object(
    'practice_attempts',(SELECT count(*) FROM public.practice_attempts),
    'practice_answers',(SELECT count(*) FROM public.practice_answers),
    'tour_attempts',(SELECT count(*) FROM public.tour_attempts),
    'tour_answers',(SELECT count(*) FROM public.tour_answers),
    'certificates',(SELECT count(*) FROM public.certificates)
  ) INTO v_before_legacy;

  v_run:=private.register_exam_prep_canonical_synthetic_run_v2(
    'SV-P267CI-RUN-0001','p2_67_canonical_v2_0',repeat('f',40),'p2-67',26702,'core','p2-67-governed-run-proof'
  );
  IF v_run->>'scenario_set_version'<>'p2_67_canonical_v2_0'
     OR v_run->>'run_status'<>'registered'
     OR (v_run->>'deterministic_seed')::bigint<>26702 THEN
    RAISE EXCEPTION 'P2-67 governed run registration payload invalid: %',v_run;
  END IF;

  -- Registering a scenario set must not generate learner identities/evidence.
  IF (SELECT count(*) FROM public.users)<>v_before_users
     OR (SELECT count(*) FROM private.exam_prep_beta_members)<>v_before_beta
     OR (SELECT count(*) FROM private.exam_prep_synthetic_identities WHERE run_id='SV-P267CI-RUN-0001')<>0 THEN
    RAISE EXCEPTION 'P2-67 scenario registration generated learner/control state';
  END IF;
  IF v_before_legacy IS DISTINCT FROM jsonb_build_object(
    'practice_attempts',(SELECT count(*) FROM public.practice_attempts),
    'practice_answers',(SELECT count(*) FROM public.practice_answers),
    'tour_attempts',(SELECT count(*) FROM public.tour_attempts),
    'tour_answers',(SELECT count(*) FROM public.tour_answers),
    'certificates',(SELECT count(*) FROM public.certificates)
  ) THEN
    RAISE EXCEPTION 'P2-67 scenario registration mutated legacy state';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P267CI-RUN-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-67 rollback left test run rows=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_scenario_sets WHERE scenario_set_version='p2_67_canonical_v2_0';
  IF v_count<>1 THEN RAISE EXCEPTION 'P2-67 rollback removed canonical scenario set'; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_scenarios WHERE scenario_set_version='p2_67_canonical_v2_0';
  IF v_count<>33 THEN RAISE EXCEPTION 'P2-67 rollback changed canonical scenario rows=%',v_count; END IF;
END
$$;

\echo 'P2-67 canonical scenario matrix v2: GREEN'
