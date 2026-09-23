-- DISPOSABLE PostgreSQL 17 CI ONLY. Synthetic owner, real FKs, no production data.
-- Seed ONE active, saved-answer review while Core OFF and enrollment empty.
\set ON_ERROR_STOP on
DO $$BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
 OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
  RAISE EXCEPTION 'active_review_seed_requires_disposable_installed_review';
 END IF;
END$$;
BEGIN;
CREATE SCHEMA weekly_rollback_ci;
CREATE TABLE weekly_rollback_ci.fixture (
 user_id uuid PRIMARY KEY, session_id uuid NOT NULL, authorization_id uuid NOT NULL
);
DO $seed$
DECLARE
 v_uid uuid:=gen_random_uuid(); v_program bigint; v_ass record;
 v_plan uuid; v_goal uuid; v_case uuid; v_auth uuid; v_session uuid; v_response uuid;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE program_key='math_as_p1_p5' AND rollout_state='off'
  AND core_enabled IS FALSE AND kill_switch IS TRUE)
 OR EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE)
 OR EXISTS(SELECT 1 FROM private.exam_prep_learning_review_starts_v1) THEN
  RAISE EXCEPTION 'active_review_seed_requires_off_empty_baseline';
 END IF;
 SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0';
 SELECT a.id AS assessment_id,a.content_version_id,a.assessment_version,
        ai.question_id,ai.primary_skill_code,ai.reserve_role,m.id AS meta_id,
        m.question_snapshot_md5
 INTO STRICT v_ass
 FROM private.exam_prep_assessments a
 JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
 JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id AND ai.question_id IS NOT NULL
 JOIN private.exam_prep_question_content_meta m ON m.question_id=ai.question_id
 WHERE a.status='published' AND a.component_code='P1' AND a.assessment_type='learning'
 AND cv.program_version_id=v_program ORDER BY a.id,ai.item_order LIMIT 1;
 INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
 VALUES(v_uid,'authenticated','authenticated','rollback-active-fixture@example.invalid',now(),now(),false,false);
 INSERT INTO public.users(id,first_name,created_at,must_change_password)
 VALUES(v_uid,'RollbackActiveSynthetic',now(),false);
 INSERT INTO private.exam_prep_exam_profiles
 (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,active_week_no)
 VALUES(v_uid,v_program,'May/June 2027','A',12,6,1);
 INSERT INTO private.exam_prep_weekly_plans
 (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 VALUES(v_uid,v_program,'P1',1,1,'active','Synthetic rollback refusal only') RETURNING id INTO v_plan;
 INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status,engine_version,reason)
 VALUES(v_uid,'P1',v_ass.primary_skill_code,'open','objective_state_v1','{"synthetic_rollback":true}'::jsonb)
 RETURNING id INTO v_case;
 INSERT INTO private.exam_prep_weekly_plan_items
 (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
 VALUES(v_plan,1,'correction',v_ass.primary_skill_code,v_case,'COMPLETE_CORRECTION_ANALOGUES');
 INSERT INTO private.exam_prep_weekly_goal_snapshots
 (user_id,program_version_id,component_code,active_week_no,priority_order,source_plan_id,
 item_type,skill_code,correction_case_id,action_code,assessment_id)
 VALUES(v_uid,v_program,'P1',1,1,v_plan,'correction',v_ass.primary_skill_code,v_case,
 'COMPLETE_CORRECTION_ANALOGUES',v_ass.assessment_id) RETURNING id INTO v_goal;
 INSERT INTO private.exam_prep_session_authorizations
 (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
 correction_case_id,academic_credit,credit_context)
 VALUES(v_uid,v_ass.assessment_id,'P1','learning','issued',now()+interval '1 hour',
 'Synthetic no-credit review rollback',v_case,false,'learning_review') RETURNING id INTO v_auth;
 INSERT INTO private.exam_prep_sessions
 (authorization_id,user_id,program_version_id,content_version_id,assessment_id,
 assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
 VALUES(v_auth,v_uid,v_program,v_ass.content_version_id,v_ass.assessment_id,v_ass.assessment_version,
 'P1','learning','active','rollback-active-review-fixture-001',1)
 RETURNING id INTO v_session;
 INSERT INTO private.exam_prep_session_items
 (session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,is_holdout,
 content_meta_id,question_snapshot_md5,item_version)
 VALUES(v_session,1,'question',v_ass.question_id,v_ass.primary_skill_code,v_ass.reserve_role,
 false,v_ass.meta_id,v_ass.question_snapshot_md5,v_ass.assessment_version);
 UPDATE private.exam_prep_session_authorizations
 SET status='consumed',consumed_at=now(),consumed_session_id=v_session WHERE id=v_auth;
 INSERT INTO private.exam_prep_learning_review_starts_v1
 (authorization_id,user_id,program_version_id,component_code,plan_id,goal_id,priority_order,
 skill_code,correction_case_id,assessment_id)
 VALUES(v_auth,v_uid,v_program,'P1',v_plan,v_goal,1,v_ass.primary_skill_code,v_case,v_ass.assessment_id);
 INSERT INTO private.exam_prep_responses
 (session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
 is_correct,evaluator_version,elapsed_ms)
 VALUES(v_session,1,v_uid,'rollback-saved-answer-fixture-01','machine',
 'synthetic saved response',false,'synthetic-rollback',800) RETURNING id INTO v_response;
 INSERT INTO private.exam_prep_evidence_events
 (user_id,component_code,skill_code,session_id,response_id,evidence_type,
 verification_status,is_correct,evidence_payload,source_version)
 VALUES(v_uid,'P1',v_ass.primary_skill_code,v_session,v_response,'learning',
 'app_checked_noncredit',false,'{"synthetic":true}'::jsonb,'synthetic-rollback');
 INSERT INTO weekly_rollback_ci.fixture(user_id,session_id,authorization_id)
 VALUES(v_uid,v_session,v_auth);
 IF (SELECT count(*) FROM private.exam_prep_learning_review_starts_v1)=0 OR
  NOT EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE id=v_session AND status='active') OR
  NOT EXISTS(SELECT 1 FROM private.exam_prep_responses WHERE session_id=v_session) OR
  NOT EXISTS(SELECT 1 FROM private.exam_prep_evidence_events WHERE session_id=v_session) THEN
  RAISE EXCEPTION 'active_review_fixture_incomplete';
 END IF;
 RAISE NOTICE 'ACTIVE REVIEW SYNTHETIC FK-COMPLETE FIXTURE READY (no identifiers emitted)';
END;$seed$;
COMMIT;
