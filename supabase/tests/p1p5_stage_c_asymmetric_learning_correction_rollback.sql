-- Issue #450 Stage C: two canonical asymmetric learners, real published
-- server-graded P1 vs P5 progression + independent failure/correction.
-- Uses already reviewed P2-69 TEMP helper function definitions on the SAME
-- psql connection, with real public RPC calls / persisted evidence events.
-- Test-only direct learning authorizations are synthetic bootstrap, NOT
-- proof of native weekly-plan routing (separately tested by real HTTP).
-- Entire test is atomic ROLLBACK; NEVER hosted Supabase.
\set ON_ERROR_STOP on
DO $guard$
BEGIN
 IF current_database()<>'postgres'
  OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
  OR (SELECT count(*) FROM auth.users)<>2
  OR (SELECT count(*) FROM public.users)<>2
  OR EXISTS (SELECT 1 FROM public.users WHERE id NOT IN (
    '11111111-1111-4111-8111-111111111191'::uuid,
    '22222222-2222-4222-8222-222222222292'::uuid
  ))
  OR EXISTS (SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
  OR EXISTS (SELECT 1 FROM public.practice_attempts)
  OR EXISTS (SELECT 1 FROM public.tour_attempts)
  OR EXISTS (SELECT 1 FROM public.certificates)
  OR NOT EXISTS (SELECT 1 FROM private.exam_prep_feature_config
    WHERE id=1 AND rollout_state='controlled_beta' AND core_enabled=true
      AND kill_switch=false AND qa_open_all_core=false
      AND qa_open_all_weekly=false AND ai_enabled=false AND mentor_enabled=false)
 THEN RAISE EXCEPTION 'STAGE C PROGRESSION REFUSED outside exact two-user isolated PG17 Core'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_synthetic_scenarios
     WHERE scenario_set_version='p2_67_canonical_v2_0'
       AND source_profile_id IN ('strong-p1','strong-p5')
       AND scenario_type='canonical_profile')<>2
 THEN RAISE EXCEPTION 'STAGE C: canonical strong-P1/P5 source models missing'; END IF;
END $guard$;

BEGIN;
CREATE TEMP TABLE stage_c_progression_result(
  profile text PRIMARY KEY,
  learner uuid NOT NULL,
  strong_component text NOT NULL,
  weak_component text NOT NULL,
  earned_l2 integer NOT NULL,
  weak_l2_before integer NOT NULL,
  weak_l2_after integer NOT NULL,
  new_correction_cases integer NOT NULL,
  weak_learning_sessions integer NOT NULL,
  retest_status text NOT NULL,
  too_early_rejected boolean NOT NULL,
  correction_events int NOT NULL,
  clock_only_credit_delta bigint NOT NULL
) ON COMMIT DROP;

-- Deliberate all-objective-wrong retest: answers are submitted and graded
-- by the real public RPC; this helper NEVER writes is_correct or mastery.
CREATE OR REPLACE FUNCTION pg_temp.stagec_submit_wrong_retest_v1(
 p_session_id uuid,p_prefix text
) RETURNS void LANGUAGE plpgsql AS $fail$
DECLARE v_item record;v_answer text;v_payload jsonb;v_n int:=0;
BEGIN
 FOR v_item IN
  SELECT si.item_order,si.item_kind,q.qtype,q.correct_answer
  FROM private.exam_prep_session_items si
  LEFT JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=p_session_id ORDER BY si.item_order
 LOOP
  IF v_item.item_kind='question' THEN
   IF v_item.correct_answer IS NULL THEN
    RAISE EXCEPTION 'Stage C failed retest had no authoritative answer key';
   END IF;
   v_answer:=CASE WHEN v_item.qtype='mcq'
    THEN CASE upper(trim(v_item.correct_answer)) WHEN 'A' THEN 'B' ELSE 'A' END
    ELSE CASE WHEN trim(v_item.correct_answer)='0' THEN '1' ELSE '0' END END;
   v_payload:=jsonb_build_object('answer',v_answer);
   v_n:=v_n+1;
  ELSE
   v_payload:=jsonb_build_object('artifact',jsonb_build_object(
    'working','not automatically graded','method','synthetic','conclusion','unverified'
   ));
  END IF;
  PERFORM public.submit_exam_prep_response_safe_v1(
   p_session_id,v_item.item_order,v_payload,
   p_prefix||'-wrong-'||v_item.item_order,1200,'en'
  );
 END LOOP;
 IF v_n=0 THEN RAISE EXCEPTION 'Stage C retest lacks objective questions'; END IF;
 PERFORM public.finalize_exam_prep_session_safe_v1(p_session_id,p_prefix||'-final');
END
$fail$;

DO $cases$
DECLARE
 v_run text:='SV-P1P5-STAGEC-ASYM-02';
 v_profile text;
 v_strong text;
 v_weak text;
 v_user uuid;
 v_program bigint;
 v_weak_before integer;
 v_strong_after integer;
 v_weak_after integer;
 v_weak_learning integer;
 v_skill text;
 v_ass bigint;
 v_session uuid;
 v_corrections int;
 v_stage_strong int;
 v_stage_weak int;
 v_manifest jsonb;
 v_clock_ready boolean:=false;
 v_case uuid;
 v_retest jsonb;
 v_authorization jsonb;
 v_retest_status text;
 v_early_denied boolean;
 v_event_count integer;
 v_before_evidence bigint;
 v_after_evidence bigint;
BEGIN
 PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',
    '5a52e40b1c8c732f4cd498595f1fce2d0ced4242',
    'p1p5-stagec-asymmetric',46302,'core','Stage C two asymmetric source profiles');
 FOR v_profile,v_strong,v_weak IN
   SELECT * FROM (VALUES
    ('strong-p1'::text,'P1'::text,'P5'::text),
    ('strong-p5'::text,'P5'::text,'P1'::text)
   ) AS v(profile,strong_component,weak_component)
 LOOP
  SELECT to_jsonb(s) INTO v_manifest
  FROM private.exam_prep_synthetic_scenarios s
  WHERE scenario_set_version='p2_67_canonical_v2_0'
    AND scenario_type='canonical_profile'
    AND source_profile_id=v_profile;
  IF v_manifest IS NULL
    OR v_manifest->'expected_invariants'->>'p1_p5_independent'<>'true'
  THEN RAISE EXCEPTION 'Stage C asymmetric source invariant invalid: %',v_profile; END IF;

  v_user:=private.create_exam_prep_synthetic_identity_v1(
   v_run,'learner','SVF-S463-'||upper(v_profile),
   'stage-c-isolated-learner-'||v_profile,
   'Stage C isolated asymmetric Core history','en'
  );
  IF NOT v_clock_ready THEN
    -- Synthetic academic evidence can be recorded only under an ACTIVE,
    -- owned governed validation run with the P2-68 bounded academic clock.
    PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
      v_run,'registered','running',null,null,
      jsonb_build_object('stage_c','asymmetric-learning-start')
    );
    PERFORM private.initialize_exam_prep_synthetic_clock_v1(
      v_run,'Stage C owned synthetic academic clock'
    );
    v_clock_ready:=true;
  END IF;
  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,
    mentor_care_entitled,cohort_key,valid_from
  ) VALUES (v_user,'active',true,false,false,NULL,now()-interval '1 minute');
  PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.save_exam_prep_exam_profile_v2('CI_STAGEC_ASYMMETRIC','A',12,6);

  SELECT program_version_id INTO v_program
  FROM private.exam_prep_exam_profiles WHERE user_id=v_user;
  IF v_program IS NULL THEN RAISE EXCEPTION 'Stage C no real exam profile'; END IF;
  PERFORM pg_temp.p269_run_stage0_component_v1(v_user,'P1');
  PERFORM pg_temp.p269_run_stage0_component_v1(v_user,'P5');
  PERFORM private.rebuild_exam_prep_state_v1(v_user,'P1');
  PERFORM private.rebuild_exam_prep_state_v1(v_user,'P5');

  SELECT count(*)::int INTO v_weak_before
  FROM private.exam_prep_skill_states
  WHERE user_id=v_user AND component_code=v_weak
    AND program_version_id=v_program
    AND engine_version='objective_state_v1' AND objective_level>=2;
  IF v_weak_before<>0 THEN
   RAISE EXCEPTION 'Stage C weak component pre-progress already mastery=%',v_weak_before;
  END IF;

  PERFORM pg_temp.p269_ensure_learning_first_n_v1(
   v_user,v_program,v_strong,CASE v_strong WHEN 'P1' THEN 7 ELSE 6 END
  );
  PERFORM private.rebuild_exam_prep_state_v1(v_user,v_strong);
  PERFORM private.rebuild_exam_prep_state_v1(v_user,v_weak);

  SELECT count(*)::int INTO v_strong_after
  FROM private.exam_prep_skill_states
  WHERE user_id=v_user AND component_code=v_strong
    AND program_version_id=v_program
    AND engine_version='objective_state_v1' AND objective_level>=2;
  SELECT count(*)::int INTO v_weak_after
  FROM private.exam_prep_skill_states
  WHERE user_id=v_user AND component_code=v_weak
    AND program_version_id=v_program
    AND engine_version='objective_state_v1' AND objective_level>=2;
  IF v_strong_after < (CASE v_strong WHEN 'P1' THEN 7 ELSE 6 END)
    OR v_weak_after IS DISTINCT FROM v_weak_before
  THEN
   RAISE EXCEPTION 'Stage C real asymmetric mastery leaked strong=% L2=% weak=% before=% after=%',
    v_strong,v_strong_after,v_weak,v_weak_before,v_weak_after;
  END IF;

  -- Additional genuine wrong learning answer in a NEW strong-component skill:
  -- failure must open correction and cannot improve the independent paper.
  SELECT skill_code INTO v_skill
  FROM private.exam_prep_syllabus_nodes
  WHERE program_version_id=v_program AND component_code=v_strong
  ORDER BY sequence_no,skill_code
  OFFSET CASE v_strong WHEN 'P1' THEN 7 ELSE 6 END LIMIT 1;
  SELECT a.id INTO v_ass
  FROM private.exam_prep_assessments a
  WHERE a.component_code=v_strong AND a.assessment_type='learning'
    AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
      WHERE ai.assessment_id=a.id AND ai.primary_skill_code=v_skill)
    AND NOT EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
      WHERE ai.assessment_id=a.id AND ai.primary_skill_code<>v_skill)
  ORDER BY a.id LIMIT 1;
  IF v_ass IS NULL THEN
   RAISE EXCEPTION 'Stage C no published fresh learning skill component=%',v_strong;
  END IF;
  v_session:=pg_temp.p269_start_direct_assessment_v1(
   v_user,v_ass,v_strong,'learning','s463-wrong-'||lower(v_strong)
  );
  PERFORM pg_temp.p269_complete_learning_one_wrong_v1(
   v_session,'s463-wrong-'||lower(v_strong)
  );
  SELECT count(*)::int INTO v_corrections
  FROM private.exam_prep_correction_cases
  WHERE user_id=v_user AND component_code=v_strong AND skill_code=v_skill
    AND status IN ('open','remediating','retest_due','reopened');
  IF v_corrections<1 THEN
    RAISE EXCEPTION 'Stage C wrong learning did not create active correction component=%',v_strong;
  END IF;

  PERFORM private.rebuild_exam_prep_state_v1(v_user,v_weak);
  SELECT count(*)::int INTO v_weak_after
  FROM private.exam_prep_skill_states
  WHERE user_id=v_user AND component_code=v_weak
    AND program_version_id=v_program
    AND engine_version='objective_state_v1' AND objective_level>=2;
  SELECT count(*)::int INTO v_weak_learning
  FROM private.exam_prep_sessions
  WHERE user_id=v_user AND component_code=v_weak AND session_type='learning';
  IF v_weak_after<>v_weak_before OR v_weak_learning<>0
  THEN RAISE EXCEPTION 'Stage C incorrect learning created cross-component credit';
  END IF;

  -- Canonical source adversarial events:
  -- ADV-02 (P5 failed retest reopens), ADV-03 (P1 delayed fresh passes).
  SELECT id INTO v_case FROM private.exam_prep_correction_cases
  WHERE user_id=v_user AND component_code=v_strong AND skill_code=v_skill
    AND status IN ('open','remediating','retest_due','reopened')
  ORDER BY opened_at DESC LIMIT 1;
  IF v_case IS NULL THEN RAISE EXCEPTION 'Stage C missing original correction case'; END IF;

  v_authorization:=public.authorize_exam_prep_correction_safe_v1(v_case);
  v_session:=(public.start_exam_prep_session_safe_v1(
   (v_authorization->>'authorization_id')::uuid,
   'stagec-remediation-start-'||lower(v_strong)
  )->>'session_id')::uuid;
  PERFORM pg_temp.p269_complete_session_correct_v1(
   v_session,'stagec-remediation-'||lower(v_strong)
  );

  v_early_denied:=false;
  BEGIN
   PERFORM public.authorize_exam_prep_retest_safe_v1(v_case);
  EXCEPTION WHEN OTHERS THEN
   IF SQLERRM='exam_prep_retest_too_early'
   THEN v_early_denied:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_early_denied THEN
   RAISE EXCEPTION 'Stage C retest authorized before min-delay component=%',v_strong;
  END IF;

  SELECT count(*) INTO v_before_evidence
  FROM private.exam_prep_evidence_events
  WHERE user_id=v_user AND component_code=v_strong;

  -- P2-68 is test-only, bounded, attributable and enforces time progression.
  -- One source profile may be retested after the other calendar has advanced;
  -- this does not grant an academic credit, only unlocks after-due eligibility.
  PERFORM pg_temp.p269_advance_days_v1(
   v_run,7,'Stage C immutable retest due calendar advancement');
  SELECT count(*) INTO v_after_evidence
  FROM private.exam_prep_evidence_events
  WHERE user_id=v_user AND component_code=v_strong;
  IF v_after_evidence<>v_before_evidence THEN
   RAISE EXCEPTION 'Stage C calendar alone created academic evidence';
  END IF;

  v_retest:=public.authorize_exam_prep_retest_safe_v1(v_case);
  v_session:=(public.start_exam_prep_session_safe_v1(
   (v_retest->>'authorization_id')::uuid,
   'stagec-due-retest-start-'||lower(v_strong)
  )->>'session_id')::uuid;

  IF v_strong='P5' THEN
   PERFORM pg_temp.stagec_submit_wrong_retest_v1(
    v_session,'stagec-retest-fail-p5');
   v_retest_status:='reopened';
  ELSE
   PERFORM pg_temp.p269_complete_session_correct_v1(
    v_session,'stagec-retest-pass-p1');
   v_retest_status:='resolved';
  END IF;

  IF (SELECT status FROM private.exam_prep_correction_cases
      WHERE id=v_case)<>v_retest_status THEN
   RAISE EXCEPTION 'Stage C real retest outcome mismatch profile=% expected=% actual=%',
     v_profile,v_retest_status,
     (SELECT status FROM private.exam_prep_correction_cases WHERE id=v_case);
  END IF;

  SELECT count(*)::int INTO v_event_count
  FROM private.exam_prep_correction_actions
  WHERE correction_case_id=v_case
    AND action_type=(CASE WHEN v_retest_status='reopened'
      THEN 'retest_failed' ELSE 'retest_passed' END)
    AND session_id=v_session;
  IF v_event_count<>1 THEN
   RAISE EXCEPTION 'Stage C expected genuine correction retest event exactly once';
  END IF;

  -- The failed P5 retest cannot award L2 on the deliberately new skill;
  -- no repair action on the strong paper can credit the weak paper.
  PERFORM private.rebuild_exam_prep_state_v1(v_user,v_strong);
  PERFORM private.rebuild_exam_prep_state_v1(v_user,v_weak);
  SELECT count(*)::int INTO v_weak_after
  FROM private.exam_prep_skill_states
  WHERE user_id=v_user AND component_code=v_weak
    AND program_version_id=v_program
    AND engine_version='objective_state_v1' AND objective_level>=2;
  IF v_weak_after<>v_weak_before THEN
   RAISE EXCEPTION 'Stage C retest affected opposite paper mastery';
  END IF;
  IF v_strong='P5' AND EXISTS (
   SELECT 1 FROM private.exam_prep_skill_states
   WHERE user_id=v_user AND component_code='P5'
     AND program_version_id=v_program
     AND skill_code=v_skill AND engine_version='objective_state_v1'
     AND objective_level>=2
  ) THEN
   RAISE EXCEPTION 'Stage C failed retest improperly created L2 on failed skill';
  END IF;

  INSERT INTO stage_c_progression_result VALUES(
   v_profile,v_user,v_strong,v_weak,v_strong_after,v_weak_before,
   v_weak_after,v_corrections,v_weak_learning,v_retest_status,
   v_early_denied,v_event_count,v_after_evidence-v_before_evidence);
 END LOOP;
 IF (SELECT count(*) FROM stage_c_progression_result)<>2
  OR EXISTS(SELECT 1 FROM stage_c_progression_result
    WHERE earned_l2 < (CASE strong_component WHEN 'P1' THEN 7 ELSE 6 END)
     OR weak_l2_after<>weak_l2_before OR new_correction_cases<1
     OR weak_learning_sessions<>0 OR NOT too_early_rejected
     OR correction_events<>1 OR clock_only_credit_delta<>0
     OR (strong_component='P1' AND retest_status<>'resolved')
     OR (strong_component='P5' AND retest_status<>'reopened'))
  OR (SELECT count(*) FROM private.exam_prep_beta_weekly_reviews)<>0
  OR (SELECT count(*) FROM public.practice_attempts)<>0
  OR (SELECT count(*) FROM public.tour_attempts)<>0
  OR (SELECT count(*) FROM public.certificates)<>0
 THEN RAISE EXCEPTION 'Stage C source-anchored progression final verification failed'; END IF;
END
$cases$;

SELECT 'STAGE C SOURCE-ANCHORED P1 P5 ASYMMETRIC LEARNING CORRECTION PASS' AS marker,
 profile,strong_component,weak_component,earned_l2,weak_l2_before,
 weak_l2_after,new_correction_cases,weak_learning_sessions,
 retest_status,too_early_rejected,correction_events,clock_only_credit_delta
FROM stage_c_progression_result ORDER BY profile;
SELECT 'STAGE C ACTUAL P1 DELAYED PASS P5 FAILED REOPENED RETEST PASS' AS marker,
 count(*) FILTER (WHERE strong_component='P1' AND retest_status='resolved') AS successful_p1,
 count(*) FILTER (WHERE strong_component='P5' AND retest_status='reopened') AS reopened_p5,
 count(*) FILTER (WHERE too_early_rejected) AS denied_early_retests,
 sum(clock_only_credit_delta) AS calendar_generated_evidence
FROM stage_c_progression_result;

ROLLBACK;

DO $after$
BEGIN
 IF (SELECT count(*) FROM public.users)<>2 OR (SELECT count(*) FROM auth.users)<>2
  OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_validation_runs
    WHERE run_id='SV-P1P5-STAGEC-ASYM-02')
  OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities
    WHERE run_id='SV-P1P5-STAGEC-ASYM-02')
  OR EXISTS (SELECT 1 FROM public.practice_attempts)
  OR EXISTS (SELECT 1 FROM public.tour_attempts)
  OR EXISTS (SELECT 1 FROM public.certificates)
  OR EXISTS (SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
 THEN RAISE EXCEPTION 'Stage C asymmetric rollback retained synthetic/legacy/beta rows'; END IF;
END $after$;
\echo 'STAGE C ASYMMETRIC LEARNING + CORRECTION ROLLBACK RESTORED TWO USERS PASS'
