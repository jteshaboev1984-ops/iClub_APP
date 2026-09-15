-- P2-80: Independent A-to-Z Release Audit
-- Isolated CI only. This matrix is read/rollback-only and must never authorize
-- expanded beta or mass rollout. Real-world evidence remains a separate gate.

begin;

DO $$
DECLARE
  v_cfg private.exam_prep_feature_config%rowtype;
  v_p1 int;
  v_p5 int;
  v_without_rls int;
  v_browser_grants int;
  v_private_exec int;
  v_synth jsonb;
  v_identity jsonb;
  v_scenarios jsonb;
  v_ai private.exam_prep_ai_policy%rowtype;
  v_runtime text;
  v_cards int;
  v_bad_cards int;
  v_bad_content int;
  v_bad_diag int;
  v_bad_written int;
  v_mixed int;
  v_mixed_fail_closed int;
  v_runway jsonb;
  v_active_synth int;
  v_active_mentor_entitlements int;
  v_active_mentor_assignments int;
  v_required_functions text[] := ARRAY[
    'private.exam_prep_synthetic_real_boundary_report_v1()',
    'private.exam_prep_synthetic_identity_isolation_report_v1()',
    'private.exam_prep_synthetic_scenario_set_report_v1(text)',
    'public.get_exam_prep_content_runway_v1(smallint)',
    'public.start_exam_prep_session_safe_v1(uuid,text)',
    'public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)',
    'public.finalize_exam_prep_session_safe_v1(uuid,text)',
    'public.record_my_exam_prep_interruption_v2(date,date,text)',
    'public.generate_exam_prep_weekly_plan_safe_v3(text)',
    'public.pause_exam_prep_mentor_assignment_safe_v1(bigint,text)',
    'public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text)'
  ];
  v_sig text;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.id IS NULL THEN RAISE EXCEPTION 'P2-80 feature config missing'; END IF;
  IF v_cfg.rollout_state<>'controlled_beta' OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P2-80 production-shaped boundary drift: rollout=% core=% ai=% mentor=% kill=%',
      v_cfg.rollout_state,v_cfg.core_enabled,v_cfg.ai_enabled,v_cfg.mentor_enabled,v_cfg.kill_switch;
  END IF;

  SELECT count(*) FILTER (WHERE component_code='P1'), count(*) FILTER (WHERE component_code='P5')
    INTO v_p1,v_p5
  FROM private.exam_prep_syllabus_nodes
  WHERE program_version_id=(SELECT id FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0');
  IF v_p1<>45 OR v_p5<>36 THEN RAISE EXCEPTION 'P2-80 canonical denominator drift P1=% P5=%',v_p1,v_p5; END IF;

  SELECT count(*) INTO v_without_rls
  FROM pg_tables
  WHERE schemaname='private' AND tablename LIKE 'exam_prep%' AND NOT rowsecurity;
  IF v_without_rls<>0 THEN RAISE EXCEPTION 'P2-80 private Exam Prep tables without RLS=%',v_without_rls; END IF;

  SELECT count(*) INTO v_browser_grants
  FROM information_schema.role_table_grants
  WHERE table_schema='private' AND table_name LIKE 'exam_prep%' AND grantee IN ('anon','authenticated');
  IF v_browser_grants<>0 THEN RAISE EXCEPTION 'P2-80 browser grants on private Exam Prep tables=%',v_browser_grants; END IF;

  SELECT count(*) INTO v_private_exec
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='private' AND p.proname LIKE 'exam_prep_%'
    AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE'));
  IF v_private_exec<>0 THEN RAISE EXCEPTION 'P2-80 browser EXECUTE on private Exam Prep functions=%',v_private_exec; END IF;

  v_synth:=private.exam_prep_synthetic_real_boundary_report_v1();
  IF coalesce((v_synth->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_synth->>'synthetic_environment_active_count')::int,0)<>0
     OR coalesce((v_synth->>'synthetic_marked_active_count')::int,0)<>0 THEN
    RAISE EXCEPTION 'P2-80 real/synthetic boundary failed: %',v_synth;
  END IF;

  v_identity:=private.exam_prep_synthetic_identity_isolation_report_v1();
  IF coalesce((v_identity->>'eligible')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-80 synthetic identity isolation failed: %',v_identity;
  END IF;

  v_scenarios:=private.exam_prep_synthetic_scenario_set_report_v1('p2_67_canonical_v2_0');
  IF coalesce((v_scenarios->>'eligible')::boolean,false) IS NOT TRUE
     OR coalesce((v_scenarios->>'total_scenarios')::int,0)<>33
     OR coalesce((v_scenarios->>'canonical_profiles')::int,0)<>15
     OR coalesce((v_scenarios->>'canonical_source_profiles')::int,0)<>15
     OR coalesce((v_scenarios->>'adversarial_variants')::int,0)<>18
     OR coalesce((v_scenarios->>'locale_violations')::int,-1)<>0
     OR coalesce((v_scenarios->>'structure_violations')::int,-1)<>0
     OR coalesce(jsonb_array_length(v_scenarios->'missing_required_tags'),-1)<>0 THEN
    RAISE EXCEPTION 'P2-80 canonical scenario set failed: %',v_scenarios;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM private.exam_prep_synthetic_scenario_sets s
    WHERE s.scenario_set_version='p2_67_canonical_v2_0'
      AND s.status='active'
      AND s.required_locales @> ARRAY['en','ru','uz']::text[]
      AND s.canonical_profile_count=15
      AND s.adversarial_variant_count=18
      AND s.total_scenario_count=33
  ) THEN
    RAISE EXCEPTION 'P2-80 scenario-set registry contract drift';
  END IF;

  IF NOT EXISTS (
      SELECT 1 FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0' AND capability_mode='core'
    ) OR NOT EXISTS (
      SELECT 1 FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0' AND capability_mode='ai_shadow'
    ) OR NOT EXISTS (
      SELECT 1 FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0' AND capability_mode='mentor_technical'
    ) OR NOT EXISTS (
      SELECT 1 FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0' AND component_focus IN ('P1','BOTH')
    ) OR NOT EXISTS (
      SELECT 1 FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0' AND component_focus IN ('P5','BOTH')
    ) OR EXISTS (
      SELECT 1 FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0'
        AND NOT (required_locales @> ARRAY['en','ru','uz']::text[])
    ) THEN
    RAISE EXCEPTION 'P2-80 scenario coverage/locale contract drift';
  END IF;

  SELECT * INTO v_ai FROM private.exam_prep_ai_policy WHERE id=1;
  IF v_ai.id IS NULL OR v_ai.generation_enabled THEN RAISE EXCEPTION 'P2-80 AI generation must remain OFF'; END IF;
  IF NOT (v_ai.allowed_locales @> ARRAY['en','ru','uz']::text[]) THEN RAISE EXCEPTION 'P2-80 AI locale policy drift'; END IF;
  SELECT runtime_status INTO v_runtime FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF v_runtime<>'shadow' THEN RAISE EXCEPTION 'P2-80 AI runtime must remain shadow, got %',v_runtime; END IF;

  SELECT count(*), count(*) FILTER (
      WHERE card_type NOT IN ('progress_context','weekly_plan_context')
         OR source_version<>'iclub_ai_context_v1_2026_09_07'
    )
    INTO v_cards,v_bad_cards
  FROM private.exam_prep_ai_source_cards
  WHERE approval_status='approved' AND is_runtime_allowed=true;
  IF v_cards<>12 OR v_bad_cards<>0 THEN RAISE EXCEPTION 'P2-80 approved AI source-card boundary drift cards=% bad=%',v_cards,v_bad_cards; END IF;

  SELECT count(*) FILTER (
    WHERE lifecycle_state IN ('approved','published','reserve')
      AND (copyright_status<>'pass' OR qa_scope_status<>'pass' OR qa_math_status<>'pass' OR qa_language_status<>'pass' OR qa_technical_status<>'pass')
  ), count(*) FILTER (
    WHERE reserve_role='diagnostic' AND lifecycle_state IN ('approved','published','reserve') AND diagnostic_rule_status<>'approved'
  ) INTO v_bad_content,v_bad_diag
  FROM private.exam_prep_question_content_meta;
  IF v_bad_content<>0 OR v_bad_diag<>0 THEN RAISE EXCEPTION 'P2-80 question governance failure content=% diagnostic=%',v_bad_content,v_bad_diag; END IF;

  SELECT count(*) INTO v_bad_written
  FROM private.exam_prep_written_tasks
  WHERE lifecycle_state IN ('approved','published')
    AND (copyright_status<>'pass' OR qa_math_status<>'pass' OR qa_language_status<>'pass' OR qa_technical_status<>'pass');
  IF v_bad_written<>0 THEN RAISE EXCEPTION 'P2-80 written governance failure=%',v_bad_written; END IF;

  SELECT count(*), count(*) FILTER (WHERE evidence_scope='objective_transfer_only' AND written_mastery_ready=false)
    INTO v_mixed,v_mixed_fail_closed
  FROM private.exam_prep_assessment_mixed_nodes;
  IF v_mixed<1 OR v_mixed_fail_closed<>v_mixed THEN
    RAISE EXCEPTION 'P2-80 mixed-node fail-closed boundary drift total=% fail_closed=%',v_mixed,v_mixed_fail_closed;
  END IF;

  v_runway:=public.get_exam_prep_content_runway_v1(1::smallint);
  IF coalesce((v_runway->>'target_4w_green')::boolean,false) IS NOT TRUE
     OR coalesce((v_runway->>'hard_floor_green')::boolean,false) IS NOT TRUE
     OR coalesce((v_runway#>>'{components,P1,target_4w_green}')::boolean,false) IS NOT TRUE
     OR coalesce((v_runway#>>'{components,P5,target_4w_green}')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-80 content runway not green: %',v_runway;
  END IF;

  SELECT count(*) INTO v_active_synth FROM private.exam_prep_synthetic_identities WHERE identity_status='active';
  SELECT count(*) INTO v_active_mentor_entitlements FROM private.exam_prep_feature_entitlements WHERE entitlement_status='active' AND mentor_care_entitled;
  SELECT count(*) INTO v_active_mentor_assignments FROM private.exam_prep_mentor_assignments WHERE assignment_status='active' AND valid_from<=now() AND (valid_until IS NULL OR valid_until>now());
  IF v_active_synth<>0 OR v_active_mentor_entitlements<>0 OR v_active_mentor_assignments<>0 THEN
    RAISE EXCEPTION 'P2-80 optional/synthetic baseline not clean synth=% entitlements=% assignments=%',v_active_synth,v_active_mentor_entitlements,v_active_mentor_assignments;
  END IF;

  FOREACH v_sig IN ARRAY v_required_functions LOOP
    IF to_regprocedure(v_sig) IS NULL THEN RAISE EXCEPTION 'P2-80 required function missing: %',v_sig; END IF;
  END LOOP;

  IF has_function_privilege('anon','public.pause_exam_prep_mentor_assignment_safe_v1(bigint,text)','EXECUTE')
     OR has_function_privilege('anon','public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-80 anon mentor operations exposed';
  END IF;

  RAISE NOTICE 'P2-80 independent release audit matrix GREEN P1=% P5=% cards=% mixed=% runway4w=true paid_ai_calls=0',v_p1,v_p5,v_cards,v_mixed;
END
$$;

rollback;
