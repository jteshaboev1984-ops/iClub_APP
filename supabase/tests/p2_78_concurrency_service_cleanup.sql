-- P2-78 governed completion/cleanup after the concurrent Node regression.
-- ISOLATED CI ONLY.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p278.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-78 REFUSED: p278.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_learners int;
  v_mentors int;
  v_assignments int;
  v_distinct_mentors int;
  v_queue int;
  v_leaked int;
  v_history int;
BEGIN
  SELECT count(*) FILTER(WHERE identity_kind='learner'),count(*) FILTER(WHERE identity_kind='mentor')
  INTO v_learners,v_mentors
  FROM private.exam_prep_synthetic_identities
  WHERE run_id='SV-P278-CONCURRENCY' AND identity_status='active';

  SELECT count(*),count(distinct a.mentor_user_id)
  INTO v_assignments,v_distinct_mentors
  FROM private.exam_prep_mentor_assignments a
  JOIN private.exam_prep_synthetic_identities l ON l.user_id=a.learner_user_id
  WHERE l.run_id='SV-P278-CONCURRENCY'
    AND a.assignment_status='active'
    AND a.valid_from<=now() AND (a.valid_until is null OR a.valid_until>now());

  SELECT count(*) INTO v_queue
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p278_scale';

  SELECT count(*) INTO v_leaked
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  JOIN private.exam_prep_synthetic_identities l ON l.user_id=q.learner_user_id
  WHERE r.source_object_type='p278_scale'
    AND (substring(l.fixture_profile_key from 'L([0-9]{4})$'))::int>10;

  SELECT count(*) INTO v_history
  FROM private.exam_prep_evidence_events e
  JOIN private.exam_prep_synthetic_identities s ON s.user_id=e.user_id
  WHERE s.run_id='SV-P278-CONCURRENCY';

  IF v_learners<>600 OR v_mentors<>10 OR v_assignments<>10 OR v_distinct_mentors<>10
     OR v_queue<>10 OR v_leaked<>0 OR v_history<>24 THEN
    RAISE EXCEPTION 'P2-78 final scale invariant failed learners=% mentors=% active_assignments=% distinct_mentors=% queue=% leaked=% history=%',
      v_learners,v_mentors,v_assignments,v_distinct_mentors,v_queue,v_leaked,v_history;
  END IF;
END
$$;

-- Restore the production-shaped controlled-beta boundary before run completion.
-- Optional layers stay OFF for real users; no provider was called during P2-78.
UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;
UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
UPDATE private.exam_prep_optional_capability_status
SET runtime_status='shadow',gate_version=null,updated_at=now()
WHERE capability_code='ai_assist';

-- Staff roles are a protected control in the reusable synthetic-run inventory.
-- Remove only run-owned synthetic grants before terminal audit; operational rows
-- remain run-owned and are removed by the governed P2-66 cleanup function.
DELETE FROM private.exam_prep_staff_roles sr
USING private.exam_prep_synthetic_identities s
WHERE sr.user_id=s.user_id AND s.run_id='SV-P278-CONCURRENCY';

DO $$
DECLARE v_inventory jsonb;
BEGIN
  v_inventory:=private.exam_prep_synthetic_run_inventory_v1('SV-P278-CONCURRENCY');
  IF coalesce((v_inventory->>'identity_count')::int,-1)<>610
     OR coalesce((v_inventory->>'protected_control_refs')::int,-1)<>0
     OR coalesce((v_inventory->>'mixed_real_synthetic_edges')::int,-1)<>0
     OR coalesce((v_inventory->>'clean_boundary')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-78 pre-cleanup run boundary not clean: %',v_inventory;
  END IF;
END
$$;

SELECT private.complete_exam_prep_synthetic_run_v1(
  'SV-P278-CONCURRENCY',610,
  jsonb_build_object(
    'p2_78','green',
    'learners',600,
    'mentor_scopes',10,
    'unassigned_queue_leakage',0,
    'academic_state_diff',0,
    'paid_ai_calls',0
  )
);

SELECT private.cleanup_exam_prep_synthetic_run_v1(
  'SV-P278-CONCURRENCY',610,
  'P2-78 governed cleanup after concurrency/service-transition GREEN',
  'I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
);

COMMIT;

DO $$
DECLARE
  v_count int;
  v_run record;
  v_cfg record;
  v_generation boolean;
  v_runtime text;
BEGIN
  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_identities WHERE run_id='SV-P278-CONCURRENCY';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-78 cleanup left synthetic identities=%',v_count; END IF;

  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'exam-prep-sv-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-78 cleanup left synthetic auth users=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_human_review_recommendations WHERE source_object_type='p278_scale';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-78 cleanup left recommendations=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p278_scale';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-78 cleanup left queue items=%',v_count; END IF;

  SELECT * INTO v_run FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P278-CONCURRENCY';
  IF v_run.run_status<>'completed' OR v_run.cleanup_status<>'clean' OR v_run.cleaned_at IS NULL THEN
    RAISE EXCEPTION 'P2-78 run ledger did not close cleanly: %',row_to_json(v_run);
  END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_audit_events
  WHERE event_type='synthetic_validation_run_cleaned'
    AND object_type='private.exam_prep_synthetic_validation_runs'
    AND object_id='SV-P278-CONCURRENCY';
  IF v_count<>1 THEN RAISE EXCEPTION 'P2-78 expected one cleanup summary event, got %',v_count; END IF;

  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  SELECT generation_enabled INTO v_generation FROM private.exam_prep_ai_policy WHERE id=1;
  SELECT runtime_status INTO v_runtime FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF v_cfg.rollout_state<>'controlled_beta' OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR v_cfg.kill_switch
     OR v_generation OR v_runtime<>'shadow' THEN
    RAISE EXCEPTION 'P2-78 did not restore production-shaped optional-layers-off baseline cfg=% generation=% runtime=%',
      row_to_json(v_cfg),v_generation,v_runtime;
  END IF;
END
$$;

\echo 'P2-78 cleanup GREEN: zero synthetic residue; production-shaped Core-only baseline restored'