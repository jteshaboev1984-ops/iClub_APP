-- DISPOSABLE PostgreSQL ONLY. Stage 0 -> genuine first plan -> explicit revision.
-- Evidence is synthetic STRUCTURAL test data, not actual marked learner work.
-- Do not run against production. Entire learner scenario rolls back.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
    OR to_regclass('weekly_goal_ci.fixture') IS NULL
    OR to_regclass('private.exam_prep_weekly_flow_enrollment_v1') IS NULL THEN
   RAISE EXCEPTION 'FIRST-WEEK FIXTURE REFUSED: isolated DB plus atomic proposal required';
 END IF;
END $$;
-- Install the DRAFT replan proposal in the disposable service ONLY, after the
-- preceding CI step installed the atomic dispatch. Never install on production.
\i docs/patch-proposals/20260920_exam_prep_explicit_weekly_replan_v1.sql
BEGIN;
DO $test$
DECLARE
 v_uid uuid:=gen_random_uuid(); v_program bigint; v_assessment bigint;
 v_cv bigint; v_version text; v_auth uuid; v_session uuid;
 v_plan jsonb; v_second jsonb; v_goals jsonb; v_plan_id uuid;
 v_replan jsonb; v_repeat jsonb; v_stale jsonb; v_blocked_replan jsonb;
 v_goals_before jsonb; v_goals_after jsonb; v_new_plan uuid;
 v_count int; v_areas int; v_reserved int; v_blocked boolean:=false; v_error text;
BEGIN
 SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
 INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
 VALUES(v_uid,'authenticated','authenticated','first-week-synthetic@invalid.example',now(),now(),false,false);
 INSERT INTO public.users(id,first_name,created_at,must_change_password)
 VALUES(v_uid,'FirstWeekSyntheticFixture',now(),false);
 INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
 VALUES(v_uid,'active',true);
 INSERT INTO private.exam_prep_exam_profiles(user_id,program_version_id,exam_series,
  target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
 VALUES(v_uid,v_program,'May/June 2027','A',12,6,1);
 INSERT INTO private.exam_prep_weekly_flow_enrollment_v1(user_id,enabled,approved_by,approved_at)
 VALUES(v_uid,true,'00000000-0000-4000-8000-000000000001',clock_timestamp());
 PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 BEGIN
   PERFORM public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
 EXCEPTION WHEN OTHERS THEN
   GET STACKED DIAGNOSTICS v_error=MESSAGE_TEXT;
   IF v_error<>'exam_prep_stage0_required_before_weekly_plan' THEN RAISE; END IF;
   v_blocked:=true;
 END;
 IF NOT v_blocked OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_plans WHERE user_id=v_uid) THEN
   RAISE EXCEPTION 'Stage 0 incomplete generated a phantom plan';
 END IF;
 RAISE NOTICE 'PASS first-week Stage 0 denied without phantom plan';

 -- Published diagnostic ASSESSMENTS contain lifecycle=reserve and withheld
 -- diagnostic QUESTIONS. Never reclassify them as learning questions.
 CREATE TEMP TABLE ep_first_diag ON COMMIT DROP AS
 WITH candidates AS (
   SELECT DISTINCT ON (ai.question_id) ai.question_id,ai.primary_skill_code,
     m.id AS content_meta_id,m.question_snapshot_md5,s.official_syllabus_section
   FROM private.exam_prep_assessments a
   JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
   JOIN private.exam_prep_question_content_meta m ON m.question_id=ai.question_id
     AND m.content_version_id=a.content_version_id
   JOIN private.exam_prep_syllabus_nodes s ON s.skill_code=ai.primary_skill_code
     AND s.component_code='P1' AND s.program_version_id=v_program
   WHERE a.status='published' AND a.assessment_type='diagnostic'
     AND a.component_code='P1' AND ai.question_id IS NOT NULL
     AND ai.reserve_role='diagnostic' AND m.reserve_role='diagnostic'
     AND m.lifecycle_state='reserve' AND m.exposure_state='withheld'
   ORDER BY ai.question_id,a.id
 ), ranked AS (
   SELECT *,row_number() OVER (PARTITION BY official_syllabus_section
     ORDER BY question_id) AS area_rank FROM candidates
 )
 SELECT row_number() OVER (ORDER BY area_rank,official_syllabus_section,question_id)::smallint AS ord,
   question_id,primary_skill_code,content_meta_id,question_snapshot_md5,official_syllabus_section
 FROM ranked ORDER BY area_rank,official_syllabus_section,question_id LIMIT 24;
 SELECT count(*),count(DISTINCT official_syllabus_section) INTO v_count,v_areas FROM ep_first_diag;
 IF v_count<>24 OR v_areas<8 THEN
   RAISE EXCEPTION 'Insufficient already published diagnostic assessment reserve: % questions, % areas',v_count,v_areas;
 END IF;
 SELECT count(*) INTO v_reserved FROM ep_first_diag d
 JOIN private.exam_prep_question_content_meta m ON m.id=d.content_meta_id
 WHERE m.reserve_role='diagnostic' AND m.lifecycle_state='reserve' AND m.exposure_state='withheld';
 IF v_reserved<>24 THEN RAISE EXCEPTION 'Reserved diagnostic metadata inconsistent before planning'; END IF;
 SELECT id,content_version_id,assessment_version INTO STRICT v_assessment,v_cv,v_version
 FROM private.exam_prep_assessments
 WHERE status='published' AND assessment_type='diagnostic' AND component_code='P1'
 ORDER BY id LIMIT 1;
 INSERT INTO private.exam_prep_session_authorizations
 (user_id,assessment_id,component_code,purpose,status,valid_until,reason)
 VALUES(v_uid,v_assessment,'P1','diagnostic','issued',now()+interval '1 hour',
 'Synthetic Stage 0 contract fixture') RETURNING id INTO v_auth;
 INSERT INTO private.exam_prep_sessions
 (authorization_id,user_id,program_version_id,content_version_id,assessment_id,
 assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
 VALUES(v_auth,v_uid,v_program,v_cv,v_assessment,v_version,'P1','diagnostic',
 'active','synthetic-first-diagnostic-001',24) RETURNING id INTO v_session;
 UPDATE private.exam_prep_session_authorizations
 SET status='consumed',consumed_at=now(),consumed_session_id=v_session WHERE id=v_auth;
 INSERT INTO private.exam_prep_session_items
 (session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
 is_holdout,content_meta_id,question_snapshot_md5,item_version)
 SELECT v_session,ord,'question',question_id,primary_skill_code,'diagnostic',false,
 content_meta_id,question_snapshot_md5,'ci_stage0_synthetic_v1' FROM ep_first_diag;
 INSERT INTO private.exam_prep_responses
 (session_id,item_order,user_id,client_idempotency_key,response_kind,
 user_answer,is_correct,evaluator_version,elapsed_ms)
 SELECT v_session,ord,v_uid,'ci-first-'||ord::text,'machine',
 'synthetic-ungraded',false,'ci_fixture_ungraded',1000 FROM ep_first_diag;
 INSERT INTO private.exam_prep_evidence_events
 (user_id,component_code,skill_code,session_id,response_id,evidence_type,
 verification_status,is_correct,evidence_payload,source_version)
 SELECT v_uid,'P1',i.primary_skill_code,v_session,r.id,'diagnostic',
 'app_verified',false,jsonb_build_object('synthetic_fixture',true),'ci_first_week_synthetic_v1'
 FROM private.exam_prep_responses r JOIN private.exam_prep_session_items i
 ON i.session_id=r.session_id AND i.item_order=r.item_order WHERE r.session_id=v_session;
 UPDATE private.exam_prep_sessions SET status='finalized',finalized_at=clock_timestamp(),
 finalize_idempotency_key='ci-first-diagnostic-final-001' WHERE id=v_session;

 -- Genuine placement rebuild and plan generator; no fake plan insert.
 v_plan:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
 IF v_plan->>'status'<>'created' OR v_plan->>'contract_version'<>'stable_weekly_plan_v1'
 OR v_plan->>'plan_id' IS NULL OR (v_plan->>'active_week_no')::int<>1
 OR jsonb_array_length(v_plan->'items')<1 THEN
   RAISE EXCEPTION 'Fresh first P1 plan failed or has no actions: %',v_plan;
 END IF;
 v_plan_id:=(v_plan->>'plan_id')::uuid;
 SELECT count(*) INTO v_count FROM ep_first_diag d
 JOIN private.exam_prep_question_content_meta m ON m.id=d.content_meta_id
 WHERE m.reserve_role='diagnostic' AND m.lifecycle_state='reserve' AND m.exposure_state='withheld';
 IF v_count<>v_reserved THEN RAISE EXCEPTION 'Planner altered diagnostic-reserved metadata'; END IF;
 v_second:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
 IF v_second->>'status'<>'existing' OR (v_second->>'plan_id')::uuid<>v_plan_id THEN
   RAISE EXCEPTION 'Same-week reopen changed first plan: %',v_second;
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_weekly_plans
     WHERE user_id=v_uid AND component_code='P1')<>1 OR EXISTS(
     SELECT 1 FROM private.exam_prep_weekly_plans WHERE user_id=v_uid AND component_code='P5')
   OR EXISTS(SELECT 1 FROM private.exam_prep_evidence_events
     WHERE user_id=v_uid AND component_code='P5') THEN
   RAISE EXCEPTION 'First P1 plan duplicated or contaminated P5';
 END IF;
 v_goals:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
 IF (v_goals->>'created')::int<1 THEN RAISE EXCEPTION 'First plan has no frozen goals: %',v_goals; END IF;
 SELECT jsonb_agg(jsonb_build_array(id,source_plan_id,priority_order,action_code) ORDER BY priority_order)
   INTO v_goals_before FROM private.exam_prep_weekly_goal_snapshots
   WHERE user_id=v_uid AND component_code='P1';

 -- Only an explicit confirmed request may replace this still-unattempted plan.
 v_blocked_replan:=public.request_exam_prep_explicit_weekly_replan_safe_v1(
   'P1',v_plan_id,'manual_review','ci-first-explicit-denied-01',false);
 IF v_blocked_replan->>'status'<>'confirmation_required' THEN
   RAISE EXCEPTION 'Unconfirmed plan was changed: %',v_blocked_replan;
 END IF;
 v_replan:=public.request_exam_prep_explicit_weekly_replan_safe_v1(
   'P1',v_plan_id,'manual_review','ci-first-explicit-approved-01',true);
 IF v_replan->>'status'<>'replanned' OR v_replan->>'goals_preserved'<>'true'
    OR (v_replan->>'previous_plan_id')::uuid<>v_plan_id THEN
   RAISE EXCEPTION 'Explicit revision failed: %',v_replan;
 END IF;
 v_new_plan:=(v_replan->>'plan_id')::uuid;
 IF v_new_plan=v_plan_id OR (SELECT count(*) FROM private.exam_prep_weekly_plans
      WHERE user_id=v_uid AND component_code='P1' AND status='active')<>1
    OR (SELECT status FROM private.exam_prep_weekly_plans WHERE id=v_plan_id)<>'superseded'
    OR (SELECT count(*) FROM private.exam_prep_explicit_weekly_replan_events_v1 WHERE user_id=v_uid)<>1 THEN
   RAISE EXCEPTION 'Revision did not atomically replace only the plan';
 END IF;
 SELECT jsonb_agg(jsonb_build_array(id,source_plan_id,priority_order,action_code) ORDER BY priority_order)
   INTO v_goals_after FROM private.exam_prep_weekly_goal_snapshots
   WHERE user_id=v_uid AND component_code='P1';
 IF v_goals_after IS DISTINCT FROM v_goals_before THEN
   RAISE EXCEPTION 'Replan rewrote frozen goal identities';
 END IF;
 v_repeat:=public.request_exam_prep_explicit_weekly_replan_safe_v1(
   'P1',v_plan_id,'manual_review','ci-first-explicit-approved-01',true);
 IF v_repeat->>'status'<>'already_applied' OR (v_repeat->>'plan_id')::uuid<>v_new_plan THEN
   RAISE EXCEPTION 'Replayed request duplicated the plan: %',v_repeat;
 END IF;
 v_stale:=public.request_exam_prep_explicit_weekly_replan_safe_v1(
   'P1',v_plan_id,'manual_review','ci-first-explicit-stale-02',true);
 IF v_stale->>'status'<>'stale' THEN RAISE EXCEPTION 'Old-tab revision not denied: %',v_stale; END IF;
 v_second:=public.ensure_exam_prep_stable_weekly_plan_safe_v1('P1');
 IF (v_second->>'plan_id')::uuid<>v_new_plan OR v_second->>'status'<>'existing' THEN
   RAISE EXCEPTION 'Revision not stable upon reopening';
 END IF;

 -- A real active plan session on the revised plan must win over replanning.
 SELECT id,content_version_id,assessment_version INTO STRICT v_assessment,v_cv,v_version
 FROM private.exam_prep_assessments WHERE status='published'
   AND assessment_type='learning' AND component_code='P1' ORDER BY id LIMIT 1;
 INSERT INTO private.exam_prep_session_authorizations
 (user_id,assessment_id,component_code,purpose,status,valid_until,reason,plan_id,plan_priority_order)
 VALUES(v_uid,v_assessment,'P1','learning','issued',now()+interval '1 hour',
   'CI active revised-plan session',v_new_plan,1) RETURNING id INTO v_auth;
 INSERT INTO private.exam_prep_sessions
 (authorization_id,user_id,program_version_id,content_version_id,assessment_id,
 assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
 VALUES(v_auth,v_uid,v_program,v_cv,v_assessment,v_version,'P1','learning',
 'active','ci-explicit-active-session-01',1) RETURNING id INTO v_session;
 UPDATE private.exam_prep_session_authorizations
 SET status='consumed',consumed_at=now(),consumed_session_id=v_session WHERE id=v_auth;
 v_blocked_replan:=public.request_exam_prep_explicit_weekly_replan_safe_v1(
   'P1',v_new_plan,'manual_review','ci-first-explicit-active-03',true);
 IF v_blocked_replan->>'status'<>'finish_current_session_first'
    OR (v_blocked_replan->'recovery'->>'session_id')::uuid<>v_session
    OR (SELECT count(*) FROM private.exam_prep_weekly_plans
        WHERE user_id=v_uid AND component_code='P1')<>2 THEN
   RAISE EXCEPTION 'Unfinished study session was not preserved: %',v_blocked_replan;
 END IF;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_plans WHERE user_id=v_uid AND component_code='P5')
   OR EXISTS(SELECT 1 FROM private.exam_prep_evidence_events WHERE user_id=v_uid AND component_code='P5') THEN
   RAISE EXCEPTION 'Explicit P1 revision contaminated P5';
 END IF;
 RAISE NOTICE 'PASS first-week genuine plan, explicit revision, frozen goals, replay, old-tab denial, unfinished session and P5 separation';
END;
$test$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='FirstWeekSyntheticFixture') OR
 EXISTS(SELECT 1 FROM auth.users WHERE email='first-week-synthetic@invalid.example') OR
 EXISTS(SELECT 1 FROM private.exam_prep_explicit_weekly_replan_events_v1 e
         JOIN public.users u ON u.id=e.user_id WHERE u.first_name='FirstWeekSyntheticFixture') THEN
   RAISE EXCEPTION 'First-week synthetic learner or revision survived ROLLBACK';
 END IF;
 RAISE NOTICE 'FIRST-WEEK SYNTHETIC ZERO RESIDUE';
END $$;