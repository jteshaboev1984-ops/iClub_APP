-- Issue #450 Stage C: run 33 independent seeded, server-graded Stage-0
-- BASELINES mapped 1:1 to the immutable P2-67 canonical/adversarial manifest.
-- Explicitly NOT the full multi-year 33-scenario event-contract completion.
-- Real public Exam Prep RPCs and real published question keys drive outcomes.
-- Every synthetic actor and record is rolled back in this SAME psql transaction.
-- NEVER execute outside isolated GitHub PG17. No production queries/writes.
\set ON_ERROR_STOP on

DO $safety$
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
    WHERE id=1 AND rollout_state='controlled_beta' AND core_enabled
      AND NOT kill_switch AND NOT qa_open_all_core AND NOT qa_open_all_weekly
      AND NOT ai_enabled AND NOT mentor_enabled)
 THEN RAISE EXCEPTION 'STAGE C 33 REFUSED: not exact disposable Core-only CI database'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_synthetic_scenarios
      WHERE scenario_set_version='p2_67_canonical_v2_0')<>33
 THEN RAISE EXCEPTION 'STAGE C 33 REFUSED: canonical source set absent'; END IF;
END
$safety$;

BEGIN;
CREATE TEMP TABLE stage_c_33_baselines(
  ordinal integer PRIMARY KEY,
  scenario_code text NOT NULL UNIQUE,
  scenario_type text NOT NULL,
  source_profile_id text,
  pattern text NOT NULL,
  owner_id uuid NOT NULL UNIQUE,
  p1_session uuid NOT NULL,
  p5_session uuid NOT NULL,
  p1_items integer NOT NULL,
  p5_items integer NOT NULL,
  p1_wrong integer NOT NULL,
  p5_wrong integer NOT NULL
) ON COMMIT DROP;

DO $scenario$
DECLARE
 v_r record;
 v_id uuid;
 v_component text;
 v_session uuid;
 v_start jsonb;
 v_item record;
 v_correct boolean;
 v_answer text;
 v_payload jsonb;
 v_items int;
 v_wrong int;
 v_p1_session uuid;
 v_p5_session uuid;
 v_p1_items int;
 v_p5_items int;
 v_p1_wrong int;
 v_p5_wrong int;
 v_pattern text;
 v_before_p5 bigint;
 v_cross_denied boolean;
 v_frozen jsonb;
BEGIN
 FOR v_r IN
  SELECT deterministic_ordinal,scenario_code,scenario_type,source_profile_id,
         initial_state,expected_invariants,capability_mode
  FROM private.exam_prep_synthetic_scenarios
  WHERE scenario_set_version='p2_67_canonical_v2_0'
  ORDER BY deterministic_ordinal
 LOOP
  -- Authoritative scenario labels and original hypotheses are read-only.
  -- Their initial_state.stage/coverage are descriptive hypothetical baselines,
  -- NEVER inserted into server grade/stage/evidence tables.
  IF v_r.deterministic_ordinal NOT BETWEEN 1 AND 33
     OR v_r.initial_state->'p1' IS NULL OR v_r.initial_state->'p5' IS NULL
  THEN RAISE EXCEPTION 'Stage C malformed scenario ordinal=%',v_r.deterministic_ordinal; END IF;
  v_id:=md5('STAGE-C-P1P5-33-BASELINES-'||v_r.scenario_code)::uuid;
  INSERT INTO auth.users(id,aud,role,email)
  VALUES(v_id,'authenticated','authenticated',
         'ci-p1p5-s33-'||v_r.deterministic_ordinal::text||'@localhost.invalid');
  INSERT INTO public.users(id,first_name,last_name,language_code)
  VALUES(v_id,'CI 33','Isolated Learner','en');
  INSERT INTO private.exam_prep_feature_entitlements(
   user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_id,'active',true,false,false,NULL,now()-interval '1 minute');

  PERFORM set_config('request.jwt.claim.sub',v_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.save_exam_prep_exam_profile_v2(
   'CI_P1P5_SC33','A',12,6);
  IF NOT EXISTS (SELECT 1 FROM public.get_exam_prep_capabilities_v1()
                 WHERE core_access AND NOT ai_assist AND NOT mentor_care_entitled)
  THEN RAISE EXCEPTION 'Stage C synthetic profile lacks Core auth ordinal=%',v_r.deterministic_ordinal; END IF;

  v_pattern:=CASE
    WHEN v_r.source_profile_id IN ('beginner','fast-inaccurate','late-joiner') THEN 'mostly_wrong'
    WHEN v_r.source_profile_id='strong-p1' THEN 'strong_p1'
    WHEN v_r.source_profile_id='strong-p5' THEN 'strong_p5'
    WHEN v_r.source_profile_id='slow-accurate' THEN 'slow_correct'
    WHEN v_r.source_profile_id='mcq-strong-input-weak' THEN 'mcq_strong_input_weak'
    WHEN v_r.source_profile_id='exam-mode-candidate' THEN 'correct_both'
    WHEN v_r.source_profile_id='ai-unavailable' THEN 'correct_both_core_only'
    WHEN v_r.scenario_code='ADV-11-OFFLINE-DUPLICATE-RETRY' THEN 'duplicate_retry'
    ELSE CASE v_r.deterministic_ordinal % 3
       WHEN 0 THEN 'mostly_wrong'
       WHEN 1 THEN 'alternating'
       ELSE 'correct_both' END
  END;

  FOR v_component IN SELECT unnest(array['P1'::text,'P5'::text]) LOOP
   v_start:=public.start_exam_prep_next_diagnostic_safe_v1(
    v_component,'sc33-'||v_r.deterministic_ordinal||'-'||lower(v_component)||'-start');
   v_session:=(v_start->>'session_id')::uuid;
   IF v_session IS NULL THEN
    RAISE EXCEPTION 'Stage C no real authorized diagnostic scenario=% component=% payload=%',
      v_r.scenario_code,v_component,v_start;
   END IF;
   SELECT count(*) INTO v_items FROM private.exam_prep_session_items
   WHERE session_id=v_session;
   IF v_items<1 OR v_items>100 THEN
    RAISE EXCEPTION 'Stage C invalid genuine academic pack scenario=% component=%',
      v_r.scenario_code,v_component;
   END IF;
   v_wrong:=0;

   -- The frozen server pack, not a generated fake question, determines all
   -- session items. Answers are intentionally varied but real grading is
   -- performed by the original published server code.
   FOR v_item IN
    SELECT si.item_order,si.item_kind,q.qtype,q.correct_answer
    FROM private.exam_prep_session_items si
    LEFT JOIN public.questions q ON q.id=si.question_id
    WHERE si.session_id=v_session
    ORDER BY si.item_order
   LOOP
    IF v_item.item_kind='question' THEN
     IF v_item.correct_answer IS NULL THEN
      RAISE EXCEPTION 'Missing isolated grading key for question';
     END IF;
     v_correct:=CASE v_pattern
       WHEN 'strong_p1' THEN v_component='P1'
       WHEN 'strong_p5' THEN v_component='P5'
       WHEN 'mostly_wrong' THEN v_item.item_order % 5=0
       WHEN 'alternating' THEN v_item.item_order % 2=0
       WHEN 'mcq_strong_input_weak' THEN v_item.qtype='mcq'
       ELSE true
     END;
     v_answer:=v_item.correct_answer;
     IF NOT v_correct THEN
      v_wrong:=v_wrong+1;
      IF v_item.qtype='mcq' THEN
       v_answer:=CASE upper(trim(v_item.correct_answer))
         WHEN 'A' THEN 'B' ELSE 'A' END;
      ELSE
       v_answer:=CASE WHEN trim(v_item.correct_answer)='0' THEN '1' ELSE '0' END;
      END IF;
     END IF;
     v_payload:=jsonb_build_object('answer',v_answer);
    ELSE
     -- Synthetic written artifact does not award verified written marks.
     v_payload:=jsonb_build_object('artifact',jsonb_build_object(
       'working','Stage C rollback-only noncredit diagnostic',
       'method','synthetic','conclusion','unverified'));
    END IF;

    PERFORM public.submit_exam_prep_response_safe_v1(
     v_session,v_item.item_order,v_payload,
     's33-'||v_r.deterministic_ordinal||'-'||lower(v_component)||
       '-item-'||v_item.item_order,CASE WHEN v_pattern='slow_correct' THEN 24000 ELSE 1200 END,'en'
    );

    -- On the duplicated network retry scenario, an identical response must
    -- never generate a second durable academic response.
    IF v_pattern='duplicate_retry' AND v_item.item_order=1 THEN
     PERFORM public.submit_exam_prep_response_safe_v1(
      v_session,v_item.item_order,v_payload,
      's33-'||v_r.deterministic_ordinal||'-'||lower(v_component)||
       '-item-'||v_item.item_order,1200,'en');
     IF (SELECT count(*) FROM private.exam_prep_responses
         WHERE session_id=v_session AND item_order=1)<>1
     THEN RAISE EXCEPTION 'Duplicate retry counted twice'; END IF;
    END IF;
   END LOOP;
   PERFORM public.finalize_exam_prep_session_safe_v1(
    v_session,'s33-'||v_r.deterministic_ordinal||'-'||lower(v_component)||'-final');

   IF NOT EXISTS (SELECT 1 FROM private.exam_prep_sessions
      WHERE id=v_session AND user_id=v_id AND component_code=v_component
        AND status='finalized' AND session_type='diagnostic')
     OR (SELECT count(*) FROM private.exam_prep_responses
          WHERE session_id=v_session)<>v_items
   THEN RAISE EXCEPTION 'Stage C genuine server finalization mismatch scenario=% component=%',
     v_r.scenario_code,v_component; END IF;

   IF v_component='P1' THEN
    v_p1_session:=v_session;v_p1_items:=v_items;v_p1_wrong:=v_wrong;
    SELECT count(*) INTO v_before_p5 FROM private.exam_prep_sessions
       WHERE user_id=v_id AND component_code='P5';
    IF v_before_p5<>0 THEN
     RAISE EXCEPTION 'Stage C P1 evidence created P5 session scenario=%',v_r.scenario_code;
    END IF;
   ELSE
    v_p5_session:=v_session;v_p5_items:=v_items;v_p5_wrong:=v_wrong;
   END IF;
  END LOOP;

  -- Each actor has exactly two *real* finalized diagnostic sessions and no
  -- self-mark, beta evidence, historical Practice/Tour attempts or certificates.
  IF (SELECT count(*) FROM private.exam_prep_sessions
      WHERE user_id=v_id)<>2
     OR EXISTS (SELECT 1 FROM private.exam_prep_sessions
      WHERE user_id=v_id AND status<>'finalized')
     OR EXISTS (SELECT 1 FROM private.exam_prep_skill_states
      WHERE user_id=v_id AND objective_level>0)
  THEN
   RAISE EXCEPTION 'Stage C premature mastery/stage or session contamination scenario=%',
      v_r.scenario_code;
  END IF;

  -- Adversarial 16: foreign existing owner cannot read this scenario's
  -- private P1 session; exercise actual SECURITY DEFINER public RPC.
  IF v_r.scenario_code='ADV-16-CROSS-USER-ACCESS-ATTEMPT' THEN
   v_cross_denied:=false;
   PERFORM set_config('request.jwt.claim.sub',
     '22222222-2222-4222-8222-222222222292',true);
   BEGIN
    PERFORM public.get_exam_prep_session_safe_v1(v_p1_session,'en');
   EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_session_not_found' THEN
     v_cross_denied:=true;
    ELSE RAISE; END IF;
   END;
   PERFORM set_config('request.jwt.claim.sub',v_id::text,true);
   IF NOT v_cross_denied THEN
    RAISE EXCEPTION 'Stage C foreign user could read scenario session';
   END IF;
  END IF;

  INSERT INTO stage_c_33_baselines
   (ordinal,scenario_code,scenario_type,source_profile_id,pattern,owner_id,
    p1_session,p5_session,p1_items,p5_items,p1_wrong,p5_wrong)
  VALUES (v_r.deterministic_ordinal,v_r.scenario_code,v_r.scenario_type,
    v_r.source_profile_id,v_pattern,v_id,v_p1_session,v_p5_session,
    v_p1_items,v_p5_items,v_p1_wrong,v_p5_wrong);
 END LOOP;

 IF (SELECT count(*) FROM stage_c_33_baselines)<>33
  OR (SELECT count(*) FROM stage_c_33_baselines
      WHERE scenario_type='canonical_profile')<>15
  OR (SELECT count(*) FROM stage_c_33_baselines
      WHERE scenario_type='adversarial_variant')<>18
  OR (SELECT count(DISTINCT owner_id) FROM stage_c_33_baselines)<>33
  OR (SELECT count(*) FROM private.exam_prep_sessions
      WHERE user_id IN (SELECT owner_id FROM stage_c_33_baselines))<>66
  OR (SELECT count(*) FROM public.practice_attempts)<>0
  OR (SELECT count(*) FROM public.tour_attempts)<>0
  OR (SELECT count(*) FROM public.certificates)<>0
  OR (SELECT count(*) FROM private.exam_prep_beta_weekly_reviews)<>0
 THEN RAISE EXCEPTION 'Stage C 33 independent-model or legacy/beta isolation fail'; END IF;
END
$scenario$;

SELECT 'STAGE C 33 INDEPENDENT SERVER-GRADED STAGE0 BASELINES PASS' AS marker,
 count(*) AS source_manifest_scenarios,
 count(*) FILTER(WHERE scenario_type='canonical_profile') AS canonical_baselines,
 count(*) FILTER(WHERE scenario_type='adversarial_variant') AS adversarial_baselines,
 count(DISTINCT owner_id) AS distinct_isolated_learners,
 count(DISTINCT p1_session)+count(DISTINCT p5_session) AS finalized_paper_sessions,
 sum(p1_items)+sum(p5_items) AS committed_academic_answers,
 sum(p1_wrong)+sum(p5_wrong) AS deliberately_incorrect_input_choices,
 count(DISTINCT pattern) AS deterministic_answer_patterns,
 0::int AS full_event_contract_scenarios_completed,
 'stage0_baselines_only_not_full_15plus18' AS evidence_scope
FROM stage_c_33_baselines;

ROLLBACK;

DO $rollback_check$
BEGIN
 IF (SELECT count(*) FROM public.users)<>2
  OR (SELECT count(*) FROM auth.users)<>2
  OR EXISTS(SELECT 1 FROM public.users WHERE id NOT IN (
    '11111111-1111-4111-8111-111111111191'::uuid,
    '22222222-2222-4222-8222-222222222292'::uuid))
  OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
  OR EXISTS(SELECT 1 FROM public.practice_attempts)
  OR EXISTS(SELECT 1 FROM public.tour_attempts)
  OR EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'STAGE C 33 ROLLBACK FAILED TO RESTORE ORIGINAL TWO USERS'; END IF;
END
$rollback_check$;
\echo 'STAGE C 33 ROLLBACK RESTORED TWO ORIGINAL FAKE USERS: PASS'
