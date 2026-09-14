-- P2-75 AI Academic-State Parity matrix.
-- Validation-only. Requires a disposable database and rolls all mutations back.
-- Identical learner evidence must produce identical deterministic academic state with AI OFF and AI ON.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p275.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-75 REFUSED: p275.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.p275_seed_learning_evidence_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component text,
  p_skill_filter text,
  p_is_correct boolean,
  p_tag text
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_assessment_id bigint;
  v_content_version_id bigint;
  v_assessment_version text;
  v_question_id bigint;
  v_skill_code text;
  v_reserve_role text;
  v_content_meta_id bigint;
  v_question_snapshot_md5 text;
  v_auth_id uuid;
  v_session_id uuid:=gen_random_uuid();
  v_response_id uuid;
  v_evidence_id uuid;
BEGIN
  SELECT
    a.id,
    a.content_version_id,
    a.assessment_version,
    ai.question_id,
    ai.primary_skill_code,
    ai.reserve_role,
    m.id,
    m.question_snapshot_md5
  INTO
    v_assessment_id,
    v_content_version_id,
    v_assessment_version,
    v_question_id,
    v_skill_code,
    v_reserve_role,
    v_content_meta_id,
    v_question_snapshot_md5
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_assessment_items ai
    ON ai.assessment_id=a.id
  JOIN private.exam_prep_question_content_meta m
    ON m.content_version_id=a.content_version_id
   AND m.question_id=ai.question_id
  WHERE a.component_code=p_component
    AND a.assessment_type='learning'
    AND a.status='published'
    AND ai.question_id IS NOT NULL
    AND coalesce(ai.is_holdout,false)=false
    AND (p_skill_filter IS NULL OR ai.primary_skill_code=p_skill_filter)
  ORDER BY a.id,ai.item_order
  LIMIT 1;

  IF v_assessment_id IS NULL THEN
    RAISE EXCEPTION 'P2-75 governed learning fixture missing component=% skill=%',p_component,p_skill_filter;
  END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    p_user_id,v_assessment_id,p_component,'learning','issued',clock_timestamp()+interval '1 hour',
    'P2-75 rollback-only academic-state parity fixture',true
  ) RETURNING id INTO v_auth_id;

  INSERT INTO private.exam_prep_sessions(
    id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
    assessment_version,component_code,session_type,status,client_idempotency_key,total_items
  ) VALUES(
    v_session_id,v_auth_id,p_user_id,p_program_version_id,v_content_version_id,v_assessment_id,
    v_assessment_version,p_component,'learning','active','p275-'||p_tag||'-session',1
  );

  INSERT INTO private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
    is_holdout,content_meta_id,question_snapshot_md5,item_version
  ) VALUES(
    v_session_id,1,'question',v_question_id,v_skill_code,v_reserve_role,
    false,v_content_meta_id,v_question_snapshot_md5,v_assessment_version||'|p275|'||p_tag
  );

  INSERT INTO private.exam_prep_responses(
    session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
    is_correct,evaluator_version,elapsed_ms
  ) VALUES(
    v_session_id,1,p_user_id,'p275-'||p_tag||'-response','machine',
    CASE WHEN p_is_correct THEN 'synthetic-correct' ELSE 'synthetic-wrong' END,
    p_is_correct,'p275_fixture_v1',1000
  ) RETURNING id INTO v_response_id;

  INSERT INTO private.exam_prep_evidence_events(
    user_id,component_code,skill_code,session_id,response_id,evidence_type,
    verification_status,is_correct,evidence_payload,source_version
  ) VALUES(
    p_user_id,p_component,v_skill_code,v_session_id,v_response_id,'learning',
    'app_verified',p_is_correct,
    jsonb_build_object('p2_75','parity-fixture','tag',p_tag,'component',p_component),
    v_assessment_version||'|p275'
  ) RETURNING id INTO v_evidence_id;

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='p275-'||p_tag||'-final'
  WHERE id=v_session_id;

  RETURN v_evidence_id;
END
$$;

CREATE OR REPLACE FUNCTION pg_temp.p275_academic_snapshot_v1(
  p_user_id uuid,
  p_program_version_id bigint
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
SELECT jsonb_build_object(
  'placement',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'component_code',p.component_code,
      'rule_version',p.rule_version,
      'placement_status',p.placement_status,
      'route',p.route,
      'profile_complete',p.profile_complete,
      'content_ready',p.content_ready,
      'screening_required_items',p.screening_required_items,
      'screening_required_areas',p.screening_required_areas,
      'screening_available_items',p.screening_available_items,
      'screening_available_areas',p.screening_available_areas,
      'screening_answered_items',p.screening_answered_items,
      'screening_answered_areas',p.screening_answered_areas,
      'screening_objective_items',p.screening_objective_items,
      'screening_correct_items',p.screening_correct_items,
      'screening_accuracy_pct',p.screening_accuracy_pct,
      'prerequisite_unknown_count',p.prerequisite_unknown_count,
      'prerequisite_blocker_count',p.prerequisite_blocker_count,
      'ambiguity',p.ambiguity,
      'advanced_skip_requires_human',p.advanced_skip_requires_human,
      'stage0_complete',p.stage0_complete,
      'route_reason',p.route_reason
    ) ORDER BY p.component_code)
    FROM private.exam_prep_component_placements p
    WHERE p.user_id=p_user_id AND p.program_version_id=p_program_version_id
  ),'[]'::jsonb),
  'mastery',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'component_code',s.component_code,
      'skill_code',s.skill_code,
      'engine_version',s.engine_version,
      'objective_level',s.objective_level,
      'coverage_confirmed',s.coverage_confirmed,
      'evidence_total',s.evidence_total,
      'objective_evidence_count',s.objective_evidence_count,
      'correct_objective_count',s.correct_objective_count,
      'objective_accuracy_pct',s.objective_accuracy_pct,
      'learning_count',s.learning_count,
      'diagnostic_count',s.diagnostic_count,
      'mixed_count',s.mixed_count,
      'timed_count',s.timed_count,
      'retest_count',s.retest_count,
      'written_count',s.written_count,
      'has_transfer_evidence',s.has_transfer_evidence,
      'has_successful_retest',s.has_successful_retest,
      'has_delayed_successful_retest',s.has_delayed_successful_retest,
      'has_written_evidence',s.has_written_evidence,
      'has_mentor_verified_evidence',s.has_mentor_verified_evidence,
      'unresolved_correction_count',s.unresolved_correction_count,
      'hold_reason',s.hold_reason
    ) ORDER BY s.component_code,s.skill_code)
    FROM private.exam_prep_skill_states s
    WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
      AND s.engine_version='objective_state_v1'
  ),'[]'::jsonb),
  'stages',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'component_code',st.component_code,
      'engine_version',st.engine_version,
      'denominator_count',st.denominator_count,
      'l0_count',st.l0_count,
      'l1_count',st.l1_count,
      'l2_count',st.l2_count,
      'l3_count',st.l3_count,
      'coverage_count',st.coverage_count,
      'coverage_pct',st.coverage_pct,
      'open_correction_count',st.open_correction_count,
      'retest_due_count',st.retest_due_count,
      'evidence_stage_candidate',st.evidence_stage_candidate,
      'operational_stage',st.operational_stage,
      'stage_gate_status',st.stage_gate_status,
      'stage_hold_reason',st.stage_hold_reason,
      'app_readiness_estimate',st.app_readiness_estimate,
      'app_readiness_reason',st.app_readiness_reason
    ) ORDER BY st.component_code)
    FROM private.exam_prep_stage_states st
    WHERE st.user_id=p_user_id AND st.program_version_id=p_program_version_id
      AND st.engine_version='objective_state_v1'
  ),'[]'::jsonb),
  'correction_retest',jsonb_build_object(
    'corrections',coalesce((
      SELECT jsonb_agg(jsonb_build_object(
        'component_code',c.component_code,
        'skill_code',c.skill_code,
        'status',c.status,
        'engine_version',c.engine_version
      ) ORDER BY c.component_code,c.skill_code,c.status)
      FROM private.exam_prep_correction_cases c
      WHERE c.user_id=p_user_id
    ),'[]'::jsonb),
    'retests',coalesce((
      SELECT jsonb_agg(jsonb_build_object(
        'component_code',r.component_code,
        'skill_code',r.skill_code,
        'status',r.status,
        'due_not_before',r.due_not_before
      ) ORDER BY r.component_code,r.skill_code,r.status,r.due_not_before)
      FROM private.exam_prep_retest_events r
      WHERE r.user_id=p_user_id
    ),'[]'::jsonb)
  ),
  'readiness',coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'component_code',st.component_code,
      'estimate',st.app_readiness_estimate,
      'reason',st.app_readiness_reason
    ) ORDER BY st.component_code)
    FROM private.exam_prep_stage_states st
    WHERE st.user_id=p_user_id AND st.program_version_id=p_program_version_id
      AND st.engine_version='objective_state_v1'
  ),'[]'::jsonb),
  'evidence_count',(SELECT count(*) FROM private.exam_prep_evidence_events e WHERE e.user_id=p_user_id),
  'evidence_hash',(SELECT md5(coalesce(jsonb_agg(to_jsonb(e) ORDER BY e.id)::text,'[]')) FROM private.exam_prep_evidence_events e WHERE e.user_id=p_user_id)
);
$$;

DO $$
DECLARE
  v_run text:='SV-P275CI-AI-PARITY';
  v_uid uuid;
  v_program bigint;
  v_clock jsonb;
  v_now timestamptz;
  v_p1_skill text;
  v_delay smallint;
  v_p1_evidence uuid;
  v_p5_evidence uuid;
  v_case uuid;
  v_retest uuid;
  v_core jsonb;
  v_ai jsonb;
  v_core_again jsonb;
  v_count bigint;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-75 canonical program missing'; END IF;

  SELECT c.skill_code,c.min_retest_delay_days
  INTO v_p1_skill,v_delay
  FROM private.exam_prep_skill_contracts c
  WHERE c.program_version_id=v_program
    AND c.component_code='P1'
    AND c.min_retest_delay_days>0
    AND EXISTS(
      SELECT 1
      FROM private.exam_prep_assessments a
      JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
      JOIN private.exam_prep_question_content_meta m
        ON m.content_version_id=a.content_version_id AND m.question_id=ai.question_id
      WHERE a.component_code='P1'
        AND a.assessment_type='learning'
        AND a.status='published'
        AND ai.primary_skill_code=c.skill_code
        AND ai.question_id IS NOT NULL
        AND coalesce(ai.is_holdout,false)=false
    )
  ORDER BY c.skill_code
  LIMIT 1;
  IF v_p1_skill IS NULL THEN RAISE EXCEPTION 'P2-75 P1 correction/retest fixture skill unavailable'; END IF;

  PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',repeat('5',40),'p2-75',27501,'ai_shadow',
    'P2-75 rollback-only AI academic-state parity validation'
  );
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P275-AI-PARITY','p2-75-ai-parity-proof',
    'Dedicated P2-75 synthetic learner. Never a real beta member.','en'
  );
  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,jsonb_build_object('p2_75','parity-start')
  );
  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(v_run,'p2-75-clock-init');
  v_now:=(v_clock->>'virtual_now')::timestamptz;

  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
  WHERE id=1;
  UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_optional_capability_status
  SET runtime_status='shadow',gate_version=null,updated_at=now()
  WHERE capability_code='ai_assist';

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_uid,'active',true,false,false,null,clock_timestamp()-interval '1 minute');

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.save_exam_prep_exam_profile_v2('CI_P275_PARITY','A',12,6);

  -- Use asymmetric raw evidence so the P1/P5 firewall is exercised while parity is measured.
  v_p1_evidence:=pg_temp.p275_seed_learning_evidence_v1(v_uid,v_program,'P1',v_p1_skill,false,'p1-wrong');
  v_p5_evidence:=pg_temp.p275_seed_learning_evidence_v1(v_uid,v_program,'P5',null,true,'p5-correct');

  INSERT INTO private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,opened_from_evidence_id,engine_version,reason
  ) VALUES(
    v_uid,'P1',v_p1_skill,'retest_due',v_p1_evidence,'objective_state_v1',
    jsonb_build_object('p2_75','parity-retest-eligibility')
  ) RETURNING id INTO v_case;

  INSERT INTO private.exam_prep_retest_events(
    correction_case_id,user_id,component_code,skill_code,status,due_not_before
  ) VALUES(
    v_case,v_uid,'P1',v_p1_skill,'scheduled',
    v_now + (v_delay::double precision * interval '1 day')
  ) RETURNING id INTO v_retest;

  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P5');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P5');

  v_core:=pg_temp.p275_academic_snapshot_v1(v_uid,v_program);

  IF jsonb_array_length(v_core->'placement')<>2 THEN
    RAISE EXCEPTION 'P2-75 placement snapshot is vacuous: %',v_core->'placement';
  END IF;
  IF jsonb_array_length(v_core->'stages')<>2 OR jsonb_array_length(v_core->'readiness')<>2 THEN
    RAISE EXCEPTION 'P2-75 stage/readiness snapshot is vacuous: %',v_core;
  END IF;
  IF jsonb_array_length(v_core->'mastery')<2 THEN
    RAISE EXCEPTION 'P2-75 mastery snapshot is vacuous: %',v_core->'mastery';
  END IF;
  IF jsonb_array_length(v_core#>'{correction_retest,corrections}')<1
     OR jsonb_array_length(v_core#>'{correction_retest,retests}')<1 THEN
    RAISE EXCEPTION 'P2-75 correction/retest eligibility snapshot is vacuous: %',v_core->'correction_retest';
  END IF;
  IF (v_core->>'evidence_count')::int<>2 THEN
    RAISE EXCEPTION 'P2-75 expected exactly two controlled raw evidence rows, got %',v_core->>'evidence_count';
  END IF;

  -- Static authority check: deterministic academic functions must not depend on AI capability/state.
  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('private','public')
    AND p.proname LIKE 'exam_prep%'
    AND p.proname ~ '(placement|state|retest|readiness|correction)'
    AND pg_get_functiondef(p.oid) ~* '(exam_prep_ai_|ai_assist|ai_enabled)';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P2-75 deterministic academic functions reference AI state count=%',v_count;
  END IF;

  -- Enable AI only inside this rollback-only transaction. Raw evidence is unchanged.
  UPDATE private.exam_prep_feature_entitlements
  SET ai_assist=true,updated_at=now()
  WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_config
  SET ai_enabled=true,updated_at=now()
  WHERE id=1;
  UPDATE private.exam_prep_ai_policy SET generation_enabled=true,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_optional_capability_status
  SET runtime_status='ready',gate_version='p2-75-isolated-parity',updated_at=now()
  WHERE capability_code='ai_assist';
END
$$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM private.exam_prep_synthetic_identities WHERE fixture_profile_key='SVF-P275-AI-PARITY'),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  v_component text;
  v_locale text;
  v_guard jsonb;
BEGIN
  FOREACH v_component IN ARRAY ARRAY['P1','P5']::text[] LOOP
    FOREACH v_locale IN ARRAY ARRAY['en','ru','uz']::text[] LOOP
      v_guard:=public.get_exam_prep_ai_guard_v1(v_component,'progress_summary',v_locale,20);
      IF coalesce((v_guard->>'allowed')::boolean,false) IS NOT TRUE
         OR v_guard->>'mode'<>'ready'
         OR v_guard->>'component_code'<>v_component
         OR v_guard->>'requested_locale'<>v_locale THEN
        RAISE EXCEPTION 'P2-75 Core+AI guard path failed component=% locale=% payload=%',v_component,v_locale,v_guard;
      END IF;
    END LOOP;
  END LOOP;
END
$$;
RESET ROLE;

DO $$
DECLARE
  v_uid uuid;
  v_program bigint;
  v_core jsonb;
  v_ai jsonb;
  v_core_again jsonb;
BEGIN
  SELECT user_id INTO v_uid
  FROM private.exam_prep_synthetic_identities
  WHERE fixture_profile_key='SVF-P275-AI-PARITY';
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';

  -- Recover the Core snapshot deterministically from unchanged raw evidence before comparing AI mode.
  UPDATE private.exam_prep_feature_entitlements SET ai_assist=false,updated_at=now() WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_config SET ai_enabled=false,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_optional_capability_status SET runtime_status='shadow',gate_version=null,updated_at=now() WHERE capability_code='ai_assist';
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P5');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P5');
  v_core:=pg_temp.p275_academic_snapshot_v1(v_uid,v_program);

  -- Re-enable AI and recompute the exact same deterministic state from the exact same evidence.
  UPDATE private.exam_prep_feature_entitlements SET ai_assist=true,updated_at=now() WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_config SET ai_enabled=true,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_ai_policy SET generation_enabled=true,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_optional_capability_status SET runtime_status='ready',gate_version='p2-75-isolated-parity',updated_at=now() WHERE capability_code='ai_assist';
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P5');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P5');
  v_ai:=pg_temp.p275_academic_snapshot_v1(v_uid,v_program);

  IF v_core->'placement' IS DISTINCT FROM v_ai->'placement' THEN
    RAISE EXCEPTION 'P2-75 placement parity diff Core=% AI=%',v_core->'placement',v_ai->'placement';
  END IF;
  IF v_core->'mastery' IS DISTINCT FROM v_ai->'mastery' THEN
    RAISE EXCEPTION 'P2-75 mastery/P1-P5 state parity diff Core=% AI=%',v_core->'mastery',v_ai->'mastery';
  END IF;
  IF v_core->'stages' IS DISTINCT FROM v_ai->'stages' THEN
    RAISE EXCEPTION 'P2-75 stage parity diff Core=% AI=%',v_core->'stages',v_ai->'stages';
  END IF;
  IF v_core->'correction_retest' IS DISTINCT FROM v_ai->'correction_retest' THEN
    RAISE EXCEPTION 'P2-75 correction/retest eligibility parity diff Core=% AI=%',v_core->'correction_retest',v_ai->'correction_retest';
  END IF;
  IF v_core->'readiness' IS DISTINCT FROM v_ai->'readiness' THEN
    RAISE EXCEPTION 'P2-75 readiness parity diff Core=% AI=%',v_core->'readiness',v_ai->'readiness';
  END IF;
  IF v_core->>'evidence_hash' IS DISTINCT FROM v_ai->>'evidence_hash'
     OR v_core->>'evidence_count' IS DISTINCT FROM v_ai->>'evidence_count' THEN
    RAISE EXCEPTION 'P2-75 AI mutated raw evidence Core=%/% AI=%/%',
      v_core->>'evidence_count',v_core->>'evidence_hash',v_ai->>'evidence_count',v_ai->>'evidence_hash';
  END IF;

  -- AI outage/downgrade must return to the same Core academic state without reset or recalculation drift.
  UPDATE private.exam_prep_feature_entitlements SET ai_assist=false,updated_at=now() WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_config SET ai_enabled=false,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
  UPDATE private.exam_prep_optional_capability_status SET runtime_status='shadow',gate_version=null,updated_at=now() WHERE capability_code='ai_assist';
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P5');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P5');
  v_core_again:=pg_temp.p275_academic_snapshot_v1(v_uid,v_program);

  IF v_core IS DISTINCT FROM v_core_again THEN
    RAISE EXCEPTION 'P2-75 AI disable/outage failed to return identical Core academic state Core=% CoreAgain=%',v_core,v_core_again;
  END IF;
END
$$;

SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claim.role','',true);
ROLLBACK;

DO $$
DECLARE
  v_count bigint;
BEGIN
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_identities WHERE fixture_profile_key='SVF-P275-AI-PARITY';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-75 rollback left synthetic identity residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P275CI-AI-PARITY';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-75 rollback left synthetic run residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'exam-prep-sv-p275-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-75 rollback left synthetic auth-user residue=%',v_count; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_feature_config
    WHERE id=1 AND (ai_enabled OR NOT core_enabled OR mentor_enabled OR kill_switch)
  ) THEN
    RAISE EXCEPTION 'P2-75 rollback did not restore Core-on AI-off feature boundary';
  END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_ai_policy WHERE id=1 AND generation_enabled) THEN
    RAISE EXCEPTION 'P2-75 rollback did not restore AI generation OFF';
  END IF;
END
$$;

\echo 'P2-75 AI academic-state parity matrix: GREEN'
