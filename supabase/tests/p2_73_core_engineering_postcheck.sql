\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p273.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-73 postcheck REFUSED: isolated test database required';
  END IF;
END
$$;

DO $$
DECLARE
  v_state text;
  v_count bigint;
BEGIN
  SELECT rollout_state||'|'||core_enabled||'|'||ai_enabled||'|'||mentor_enabled||'|'||kill_switch
  INTO v_state
  FROM private.exam_prep_feature_config WHERE id=1;
  IF v_state IS DISTINCT FROM 'off|false|false|false|true' THEN
    RAISE EXCEPTION 'P2-73 fail-closed feature baseline drift: %',v_state;
  END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_identities;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 synthetic identity residue=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_validation_runs;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 synthetic run residue=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_evidence_events;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 evidence residue=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_integrity_events;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 integrity residue=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_mentor_queue_items;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 mentor queue residue=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_human_review_recommendations;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 human-review recommendation residue=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_beta_expansion_controls
  WHERE development_data_state='real_monitoring' OR real_review_epoch_started_at IS NOT NULL;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 isolated real-monitoring residue=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM auth.users
  WHERE email LIKE 'p015-%@invalid.example'
     OR email LIKE 'p106-%@invalid.example'
     OR email LIKE 'p238-%@invalid.example'
     OR email LIKE 'p243-%@invalid.example'
     OR email LIKE 'p258-%@invalid.example'
     OR email LIKE 'p260-%@invalid.example'
     OR email LIKE 'p263-%@invalid.example'
     OR email LIKE 'p264-%@invalid.example'
     OR email LIKE 'p265-%@invalid.example'
     OR email LIKE 'p266-%@invalid.example'
     OR email LIKE 'p267-%@invalid.example'
     OR email LIKE 'p268-%@invalid.example'
     OR email LIKE 'p269-%@invalid.example'
     OR email LIKE 'p270-%@invalid.example'
     OR email LIKE 'p271-%@invalid.example'
     OR email LIKE 'p272-%@invalid.example'
     OR email LIKE 'p273-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 synthetic auth user residue=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM public.practice_attempts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 practice_attempts legacy residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.practice_answers;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 practice_answers legacy residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.tour_attempts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 tour_attempts legacy residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.tour_answers;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 tour_answers legacy residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.ratings_cache;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 ratings_cache legacy residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.certificates;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-73 certificates legacy residue=%',v_count; END IF;

  IF (SELECT count(*) FROM private.exam_prep_synthetic_scenarios WHERE scenario_set_version='p2_67_canonical_v2_0')<>33 THEN
    RAISE EXCEPTION 'P2-73 canonical scenario definitions drifted';
  END IF;
END
$$;

SELECT 'P2-73 zero-residue postcheck: GREEN' AS result;
