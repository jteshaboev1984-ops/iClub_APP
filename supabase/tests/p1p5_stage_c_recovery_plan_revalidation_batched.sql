-- Issue #450: one large Stage C recovery + stale plan + revision + noncredit
-- revalidation matrix. Uses genuine protected public Core RPCs and *earned*
-- P1/P5 skills. One transaction, no production database, no real users.
-- P2-69 pg_temp helper DEFINITIONS are loaded in the same psql connection.
\set ON_ERROR_STOP on

DO $guard$
BEGIN
 IF current_database()<>'postgres'
   OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
   OR (SELECT count(*) FROM auth.users)<>2
   OR (SELECT count(*) FROM public.users)<>2
   OR EXISTS(SELECT 1 FROM public.users WHERE id NOT IN (
    '11111111-1111-4111-8111-111111111191'::uuid,
    '22222222-2222-4222-8222-222222222292'::uuid
   ))
   OR EXISTS(SELECT 1 FROM public.practice_attempts)
   OR EXISTS(SELECT 1 FROM public.tour_attempts)
   OR EXISTS(SELECT 1 FROM public.certificates)
   OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
   OR NOT EXISTS (SELECT 1 FROM private.exam_prep_feature_config
    WHERE id=1 AND rollout_state='controlled_beta'
     AND core_enabled AND NOT kill_switch AND NOT ai_enabled
     AND NOT mentor_enabled AND NOT qa_open_all_core AND NOT qa_open_all_weekly)
 THEN RAISE EXCEPTION 'STAGE C BATCH REFUSED: not exactly guarded disposable 2-user PG17'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_synthetic_scenarios
     WHERE scenario_set_version='p2_67_canonical_v2_0'
       AND scenario_code IN (
         'CAN-12-ILLNESS-INTERRUPTION',
         'ADV-04-INTERRUPTED-RECOVERY-LONG',
         'ADV-07-TARGET-REVISION',
         'ADV-08-TIME-BUDGET-REVISION',
         'ADV-09-STALE-WEEKLY-PLAN',
         'ADV-10-STALE-PLAN-ACTION'
       ))<>6
 THEN RAISE EXCEPTION 'STAGE C BATCH SOURCE REGISTRY DRIFT'; END IF;
END
$guard$;

BEGIN;
CREATE TEMP TABLE stagec_recovery_checks(
  tz text NOT NULL,
  break_days integer NOT NULL,
  component text NOT NULL,
  recovery_mode text NOT NULL,
  stage_before int NOT NULL,
  stage_after int NOT NULL,
  l2_before int NOT NULL,
  l2_after int NOT NULL,
  evidence_before int NOT NULL,
  evidence_after int NOT NULL,
  PRIMARY KEY(tz,break_days,component)
) ON COMMIT DROP;

DO $main$
DECLARE
 v_run constant text:='SV-P1P5-CREC-20261102';
 v_user uuid;
 v_program bigint;
 v_component text;
 v_tz text;
 v_days int;
 v_mode text;
 v_policy jsonb;
 v_recovery jsonb;
 v_profile jsonb;
 v_plan1 uuid;
 v_plan2 uuid;
 v_started date;
 v_resumed date;
 v_before_stage int;
 v_after_stage int;
 v_before_l2 int;
 v_after_l2 int;
 v_before_evidence int;
 v_after_evidence int;
 v_stage_p1 int;
 v_stage_p5 int;
 v_l2_p1 int;
 v_l2_p5 int;
 v_evidence int;
 v_active_reval jsonb;
 v_reval_id uuid;
 v_reval_auth jsonb;
 v_reval_session uuid;
 v_reval_items int;
 v_stale_denied boolean:=false;
 v_foreign_denied boolean:=false;
 v_revision jsonb;
 v_before_sessions int;
 v_after_sessions int;
 v_progress_preserved boolean:=false;
BEGIN
 PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
  v_run,'p2_67_canonical_v2_0',
  '5a52e40b1c8c732f4cd498595f1fce2d0ced4242',
  'p1p5-stagec-batched',46501,'core',
  'Stage C recovery, timezone, stale plan, profile revision and noncredit');
 v_user:=private.create_exam_prep_synthetic_identity_v1(
  v_run,'learner','SVF-S465-RECOVERY-01','stage-c-guarded-evidence',
  'Single isolated genuine learner for batched recovery/progress','en');
 PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
  v_run,'registered','running',null,null,
  jsonb_build_object('stage_c','batched-recovery-start'));
 PERFORM private.initialize_exam_prep_synthetic_clock_v1(v_run,
  'Stage C controlled academic time baseline for real evidence');
 INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,
  mentor_care_entitled,cohort_key,valid_from)
 VALUES (v_user,'active',true,false,false,NULL,clock_timestamp()-interval '1 minute');
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM public.save_exam_prep_exam_profile_v2('CI_S465_RECOVERY','A',12,6);
 SELECT program_version_id INTO STRICT v_program
 FROM private.exam_prep_exam_profiles WHERE user_id=v_user;

 -- Authoritative Stage 0 and L2: no manually inserted grade/skill/evidence.
 PERFORM pg_temp.p269_run_stage0_component_v1(v_user,'P1');
 PERFORM pg_temp.p269_run_stage0_component_v1(v_user,'P5');
 PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_user,v_program,'P1',7);
 PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_user,v_program,'P5',6);
 PERFORM private.rebuild_exam_prep_state_v1(v_user,'P1');
 PERFORM private.rebuild_exam_prep_state_v1(v_user,'P5');

 SELECT operational_stage INTO STRICT v_stage_p1
 FROM private.exam_prep_stage_states
 WHERE user_id=v_user AND program_version_id=v_program
 AND component_code='P1' AND engine_version='objective_state_v1';
 SELECT operational_stage INTO STRICT v_stage_p5
 FROM private.exam_prep_stage_states
 WHERE user_id=v_user AND program_version_id=v_program
 AND component_code='P5' AND engine_version='objective_state_v1';
 SELECT count(*) INTO v_l2_p1 FROM private.exam_prep_skill_states
 WHERE user_id=v_user AND component_code='P1'
 AND program_version_id=v_program AND engine_version='objective_state_v1'
 AND objective_level>=2;
 SELECT count(*) INTO v_l2_p5 FROM private.exam_prep_skill_states
 WHERE user_id=v_user AND component_code='P5'
 AND program_version_id=v_program AND engine_version='objective_state_v1'
 AND objective_level>=2;
 IF v_l2_p1<7 OR v_l2_p5<6 THEN
  RAISE EXCEPTION 'Stage C batch must have genuine learned skills P1=% P5=%',v_l2_p1,v_l2_p5;
 END IF;

 -- 4 day bands * 2 timezones * 2 independent papers = 16 real
 -- interruption RPC writes + 16 independent server-owned readbacks.
 -- No clock manipulation of production users; only current_date of isolated
 -- SQL request is used. Time zone is local to this DB transaction.
 FOREACH v_tz IN ARRAY ARRAY['Pacific/Kiritimati','America/Los_Angeles'] LOOP
  PERFORM set_config('TimeZone',v_tz,true);
  FOREACH v_days IN ARRAY ARRAY[5,15,25,35] LOOP
   v_resumed:=current_date;
   v_started:=v_resumed-v_days;
   v_recovery:=public.record_my_exam_prep_interruption_v2(
    v_started,v_resumed,'absence');
   FOR v_component IN SELECT unnest(ARRAY['P1'::text,'P5'::text]) LOOP
    v_policy:=public.get_exam_prep_recovery_safe_v2(v_component);
    v_mode:=CASE v_days WHEN 5 THEN 'reserve_1w'
     WHEN 15 THEN 'recovery_2_3w' WHEN 25 THEN 'source_gap_review'
     WHEN 35 THEN 'rebaseline_over_1mo' END;
    IF v_policy->>'recovery_mode'<>v_mode
       OR coalesce((v_policy->>'missed_days')::int,-1)<>v_days
       OR v_policy->>'progress_retained'<>'true'
       OR v_policy->>'evidence_standards_unchanged'<>'true'
       OR v_policy->>'stage_changed_by_recovery'<>'false'
    THEN RAISE EXCEPTION 'Stage C recovery output drift tz=% days=% component=% output=%',
      v_tz,v_days,v_component,v_policy; END IF;
    SELECT operational_stage INTO STRICT v_before_stage
    FROM private.exam_prep_stage_states
    WHERE user_id=v_user AND program_version_id=v_program
     AND component_code=v_component AND engine_version='objective_state_v1';
    SELECT count(*) INTO v_before_l2
    FROM private.exam_prep_skill_states WHERE user_id=v_user
      AND program_version_id=v_program AND component_code=v_component
      AND engine_version='objective_state_v1' AND objective_level>=2;
    SELECT count(*) INTO v_before_evidence
    FROM private.exam_prep_evidence_events
    WHERE user_id=v_user AND component_code=v_component;
    PERFORM private.rebuild_exam_prep_state_v1(v_user,v_component);
    SELECT operational_stage INTO STRICT v_after_stage
    FROM private.exam_prep_stage_states WHERE user_id=v_user
      AND program_version_id=v_program AND component_code=v_component
      AND engine_version='objective_state_v1';
    SELECT count(*) INTO v_after_l2 FROM private.exam_prep_skill_states
    WHERE user_id=v_user AND program_version_id=v_program
      AND component_code=v_component AND engine_version='objective_state_v1'
      AND objective_level>=2;
    SELECT count(*) INTO v_after_evidence
    FROM private.exam_prep_evidence_events
    WHERE user_id=v_user AND component_code=v_component;
    IF v_after_stage<>v_before_stage OR v_after_l2<>v_before_l2
       OR v_after_evidence<>v_before_evidence THEN
      RAISE EXCEPTION 'Stage C recovery altered preserved grade/evidence tz=% days=% component=%',
       v_tz,v_days,v_component; END IF;
    INSERT INTO stagec_recovery_checks VALUES(v_tz,v_days,v_component,v_mode,
      v_before_stage,v_after_stage,v_before_l2,v_after_l2,
      v_before_evidence,v_after_evidence);
   END LOOP;
  END LOOP;
 END LOOP;

 PERFORM set_config('TimeZone','UTC',true);
 -- Last long interruption really offers noncredit revalidation for BOTH
 -- independently learned P1 and P5 components.
 v_active_reval:=public.get_exam_prep_recovery_safe_v2('P1');
 IF v_active_reval->'revalidation'->>'available'<>'true'
    OR v_active_reval->'revalidation'->>'academic_state_mutation_allowed'<>'false'
    OR v_active_reval->>'revalidation_recommended'<>'true'
 THEN RAISE EXCEPTION 'Stage C long break failed to offer read-only P1 revalidation %',
 v_active_reval; END IF;
 IF (public.get_exam_prep_recovery_safe_v2('P5')->'revalidation'->>'available')<>'true'
 THEN RAISE EXCEPTION 'Stage C long break missed P5 independently'; END IF;
 v_reval_id:=(v_active_reval->'revalidation'->>'case_id')::uuid;
 IF v_reval_id IS NULL THEN RAISE EXCEPTION 'Stage C no long-break revalidation case'; END IF;

 SELECT count(*) INTO v_before_evidence
 FROM private.exam_prep_evidence_events WHERE user_id=v_user;
 v_reval_auth:=public.authorize_exam_prep_revalidation_item_safe_v1(v_reval_id,1);
 IF v_reval_auth->>'academic_credit'<>'false' THEN
   RAISE EXCEPTION 'Stage C revalidation incorrectly created crediting authorization'; END IF;
 v_reval_session:=(public.start_exam_prep_session_safe_v1(
   (v_reval_auth->>'authorization_id')::uuid,
   'stagec-longbreak-noncredit-start')
   ->>'session_id')::uuid;
 IF v_reval_session IS NULL THEN RAISE EXCEPTION 'Stage C revalidation session absent'; END IF;
 PERFORM pg_temp.p269_complete_session_correct_v1(
  v_reval_session,'stagec-longbreak-noncredit');
 SELECT count(*) INTO v_after_evidence
 FROM private.exam_prep_evidence_events WHERE user_id=v_user;
 IF v_after_evidence<>v_before_evidence
  OR NOT EXISTS(
   SELECT 1 FROM private.exam_prep_sessions
   WHERE id=v_reval_session AND user_id=v_user AND status='finalized')
  OR NOT EXISTS(
   SELECT 1 FROM private.exam_prep_progress_revalidation_items
   WHERE case_id=v_reval_id AND item_order=1 AND status='completed'
   AND session_id=v_reval_session)
 THEN RAISE EXCEPTION 'Stage C revalidation was not finalized noncredit'; END IF;

 -- Current plan/old plan: regenerate the true weekly plan. Old plan token
 -- must fail closed, with no new authorization or session side effects.
 PERFORM public.generate_exam_prep_weekly_plan_safe_v3('P1');
 SELECT id INTO STRICT v_plan1 FROM private.exam_prep_weekly_plans
 WHERE user_id=v_user AND component_code='P1' AND status='active'
 ORDER BY created_at DESC,id DESC LIMIT 1;
 PERFORM public.generate_exam_prep_weekly_plan_safe_v3('P1');
 SELECT id INTO STRICT v_plan2 FROM private.exam_prep_weekly_plans
 WHERE user_id=v_user AND component_code='P1' AND status='active'
 ORDER BY created_at DESC,id DESC LIMIT 1;
 IF v_plan1=v_plan2 THEN RAISE EXCEPTION 'Stage C plan version did not rotate'; END IF;
 SELECT count(*) INTO v_before_sessions
 FROM private.exam_prep_session_authorizations WHERE user_id=v_user;
 BEGIN
  PERFORM public.authorize_exam_prep_plan_item_safe_v1(v_plan1,1);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM IN('exam_prep_active_plan_not_found','exam_prep_stale_weekly_plan')
  THEN v_stale_denied:=true; ELSE RAISE; END IF;
 END;
 SELECT count(*) INTO v_after_sessions
 FROM private.exam_prep_session_authorizations WHERE user_id=v_user;
 IF NOT v_stale_denied OR v_after_sessions<>v_before_sessions
  OR (SELECT status FROM private.exam_prep_weekly_plans WHERE id=v_plan1)<>'superseded'
 THEN RAISE EXCEPTION 'Stage C stale plan granted new credit/session'; END IF;

 -- Revision of exam series, target grade and time budget via protected public
 -- profile entry point. No direct SQL changes to academic evidence or mastery.
 SELECT count(*) INTO v_evidence
 FROM private.exam_prep_evidence_events WHERE user_id=v_user;
 v_revision:=public.save_exam_prep_exam_profile_v2('CI_S465_REVISED','B',14,7);
 IF v_revision->>'progress_retained'<>'true' THEN
  RAISE EXCEPTION 'Stage C profile revision did not affirm progress preservation %',
  v_revision; END IF;
 IF (SELECT count(*) FROM private.exam_prep_evidence_events
      WHERE user_id=v_user)<>v_evidence
 THEN RAISE EXCEPTION 'Stage C profile revision rewrote evidence'; END IF;
 PERFORM private.rebuild_exam_prep_state_v1(v_user,'P1');
 PERFORM private.rebuild_exam_prep_state_v1(v_user,'P5');
 IF (SELECT count(*) FROM private.exam_prep_skill_states
     WHERE user_id=v_user AND component_code='P1' AND objective_level>=2
       AND engine_version='objective_state_v1')<7
  OR (SELECT count(*) FROM private.exam_prep_skill_states
     WHERE user_id=v_user AND component_code='P5' AND objective_level>=2
       AND engine_version='objective_state_v1')<6
 THEN RAISE EXCEPTION 'Stage C revision erased previously genuine P1/P5 L2'; END IF;

 -- An unrelated test user must not read this learner's private data.
 PERFORM set_config('request.jwt.claim.sub',
   '22222222-2222-4222-8222-222222222292',true);
 BEGIN
  PERFORM public.authorize_exam_prep_revalidation_item_safe_v1(v_reval_id,1);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM IN ('exam_prep_core_unavailable','exam_prep_revalidation_case_not_available',
     'exam_prep_user_not_found') THEN v_foreign_denied:=true;
  ELSE RAISE; END IF;
 END;
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 IF NOT v_foreign_denied THEN
  RAISE EXCEPTION 'Stage C foreign user received protected revalidation'; END IF;

 IF (SELECT count(*) FROM stagec_recovery_checks)<>16
   OR (SELECT count(*) FROM private.exam_prep_beta_weekly_reviews)<>0
   OR EXISTS(SELECT 1 FROM public.practice_attempts)
   OR EXISTS(SELECT 1 FROM public.tour_attempts)
   OR EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'Stage C batch history/beta/16-way matrix incomplete'; END IF;
 RAISE NOTICE 'STAGE C BATCH ACTIVE SERVER RECOVERY 16 TZ-BAND-PAPER PASS, noncredit_revalidation=1, stale_plan_denied=%, foreign_denied=%, profile_revision_progress_retained=%',
   v_stale_denied,v_foreign_denied,v_revision->>'progress_retained';
END
$main$;

SELECT 'STAGE C BATCH 16 RECOVERY TZ DAYBAND P1P5 PRESERVATION PASS' AS result,
 count(*) AS real_component_recovery_checks,
 count(DISTINCT tz) AS server_request_timezones,
 count(DISTINCT break_days) AS official_and_amended_daybands,
 count(*) FILTER(WHERE stage_before=stage_after
     AND l2_before=l2_after AND evidence_before=evidence_after)
    AS unchanged_stage_mastery_and_evidence
FROM stagec_recovery_checks;

ROLLBACK;

DO $post$
BEGIN
 IF (SELECT count(*) FROM auth.users)<>2
   OR (SELECT count(*) FROM public.users)<>2
   OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_validation_runs
     WHERE run_id='SV-P1P5-CREC-20261102')
   OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities
     WHERE run_id='SV-P1P5-CREC-20261102')
   OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
   OR EXISTS(SELECT 1 FROM public.practice_attempts)
   OR EXISTS(SELECT 1 FROM public.tour_attempts)
   OR EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'Stage C batched recovery ROLLBACK leaked users/beta/legacy'; END IF;
END $post$;
\echo 'STAGE C BATCH ZERO SYNTHETIC RESIDUE RESTORED TWO ORIGINAL CI USERS PASS'
