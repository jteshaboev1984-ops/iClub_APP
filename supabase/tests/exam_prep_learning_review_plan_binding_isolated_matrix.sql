-- Disposable PostgreSQL 17 only. An unverifiable historical replan MUST fail.
-- A verified same-identity plan reorder is tested separately by the 11-version
-- frozen-goal continuity fixture and is deliberately allowed.
-- Writes only artificial rows inside one ROLLBACK transaction.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
 OR to_regclass('weekly_goal_ci.fixture') IS NULL
 OR to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)') IS NULL THEN
  RAISE EXCEPTION 'review_binding_fixture_refused_outside_disposable_ci';
 END IF;
END $$;
BEGIN;
DO $test$
DECLARE
 v_user uuid; v_program bigint; v_old uuid; v_goal uuid; v_new uuid;
 v_auths bigint; v_sessions bigint; v_result jsonb;
BEGIN
 SELECT f.user_id,p.program_version_id,f.plan_id,f.goal_id
 INTO STRICT v_user,v_program,v_old,v_goal
 FROM weekly_goal_ci.fixture f JOIN private.exam_prep_exam_profiles p ON p.user_id=f.user_id;
 SELECT count(*) INTO v_auths FROM private.exam_prep_session_authorizations WHERE user_id=v_user;
 SELECT count(*) INTO v_sessions FROM private.exam_prep_sessions WHERE user_id=v_user;
 INSERT INTO private.exam_prep_correction_cases
   (user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(v_user,'P1','P1-QUA-01','open','objective_state_v1',
   '{"source":"disposable_plan_binding_negative"}'::jsonb);
 -- The snapshot belongs to v1, and v3 has an identical current item but the
 -- intervening plan v2 is MISSING. No legitimate lineage can be reconstructed.
 UPDATE private.exam_prep_weekly_plans SET status='superseded' WHERE id=v_old;
 INSERT INTO private.exam_prep_weekly_plans
  (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(v_user,v_program,'P1',1,3,'active','synthetic missing-v2 replacement')
 RETURNING id INTO v_new;
 INSERT INTO private.exam_prep_weekly_plan_items
  (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload,status)
 SELECT v_new,i.priority_order,i.item_type,i.skill_code,i.correction_case_id,
  i.action_code,i.action_payload,'pending'
 FROM private.exam_prep_weekly_plan_items i WHERE i.plan_id=v_old;
 IF (SELECT source_plan_id FROM private.exam_prep_weekly_goal_snapshots WHERE id=v_goal)<>v_old
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_weekly_plan_items
     WHERE plan_id=v_new AND priority_order=1 AND skill_code='P1-QUA-01')
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_plans
     WHERE user_id=v_user AND component_code='P1' AND plan_version=2) THEN
  RAISE EXCEPTION 'missing-plan-lineage test not reproduced'; END IF;
 PERFORM set_config('request.jwt.claim.sub',v_user::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 v_result:=public.start_exam_prep_learning_review_safe_v1(
  'P1',v_goal,v_new,'synthetic-wrong-source-plan-review-01');
 IF v_result->>'status'<>'stale' OR v_result?'session_id' THEN
  RAISE EXCEPTION 'missing intermediary plan was incorrectly accepted: %',v_result;
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=v_user)<>v_auths
 OR (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=v_user)<>v_sessions THEN
  RAISE EXCEPTION 'missing-plan negative call wrote auth or session'; END IF;
 RAISE NOTICE 'PASS unverified missing-version goal cannot launch a review';
END;
$test$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions
   WHERE client_idempotency_key='synthetic-wrong-source-plan-review-01') THEN
  RAISE EXCEPTION 'historical plan negative fixture leaked'; END IF;
 RAISE NOTICE 'PASS negative plan-lineage fixture rolled back completely';
END $$;
