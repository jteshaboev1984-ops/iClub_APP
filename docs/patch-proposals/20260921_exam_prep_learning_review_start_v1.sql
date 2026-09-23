-- REVIEW PROPOSAL ONLY; never install in production without independent owner approval.
-- Install after legacy RPC dispatch + private learning review verdict. Default no enrollments.
-- No question rows, prior sessions, goals, Practice or Tours are modified here.
BEGIN;
DO $prerequisite$
BEGIN
 IF to_regprocedure('private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)') IS NULL
 OR to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL
 OR to_regprocedure('private.exam_prep_legacy_start_session_internal_v1(uuid,text)') IS NULL THEN
  RAISE EXCEPTION 'learning_review_prerequisite_missing';
 END IF;
END;$prerequisite$;

CREATE TABLE private.exam_prep_learning_review_starts_v1 (
 authorization_id uuid PRIMARY KEY REFERENCES private.exam_prep_session_authorizations(id) ON DELETE RESTRICT,
 user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
 program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id) ON DELETE RESTRICT,
 component_code text NOT NULL CHECK(component_code IN ('P1','P5')),
 plan_id uuid NOT NULL REFERENCES private.exam_prep_weekly_plans(id) ON DELETE RESTRICT,
 goal_id uuid NOT NULL REFERENCES private.exam_prep_weekly_goal_snapshots(id) ON DELETE RESTRICT,
 priority_order smallint NOT NULL CHECK(priority_order BETWEEN 1 AND 3),
 skill_code text NOT NULL,
 correction_case_id uuid NOT NULL REFERENCES private.exam_prep_correction_cases(id) ON DELETE RESTRICT,
 assessment_id bigint NOT NULL REFERENCES private.exam_prep_assessments(id) ON DELETE RESTRICT,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX exam_prep_learning_review_owner_v1
 ON private.exam_prep_learning_review_starts_v1(user_id,component_code,plan_id,goal_id,created_at DESC);
ALTER TABLE private.exam_prep_learning_review_starts_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_learning_review_starts_v1 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER exam_prep_learning_review_starts_immutable_v1
 BEFORE UPDATE OR DELETE ON private.exam_prep_learning_review_starts_v1
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_block_immutable_mutation_v1();
CREATE TRIGGER exam_prep_learning_review_starts_audit_v1
 AFTER INSERT ON private.exam_prep_learning_review_starts_v1
 FOR EACH ROW EXECUTE FUNCTION private.exam_prep_audit_row_change_v1();

-- A single transaction and a shared owner/component lock bind the frozen goal,
-- original assessment, NONCREDIT authorization and new session. We deliberately
-- DO NOT bind a second authorization to the consumed original plan priority:
-- doing so would violate the existing unique index or rewrite historic evidence.
CREATE OR REPLACE FUNCTION public.start_exam_prep_learning_review_safe_v1(
 p_component_code text,p_goal_id uuid,p_plan_id uuid,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $body$
DECLARE
 v_uid uuid;
 v_program bigint;
 v_week smallint;
 v_plan private.exam_prep_weekly_plans%rowtype;
 v_goal private.exam_prep_weekly_goal_snapshots%rowtype;
 v_item private.exam_prep_weekly_plan_items%rowtype;
 v_case private.exam_prep_correction_cases%rowtype;
 v_ass bigint;
 v_matching integer;
 v_active private.exam_prep_sessions%rowtype;
 v_active_count integer;
 v_reused private.exam_prep_sessions%rowtype;
 v_verdict jsonb;
 v_auth uuid;
 v_started jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
 END IF;
 IF p_component_code NOT IN ('P1','P5') OR p_goal_id IS NULL OR p_plan_id IS NULL THEN
  RETURN jsonb_build_object('status','stale');
 END IF;
 IF p_idempotency_key IS NULL OR char_length(p_idempotency_key) NOT BETWEEN 8 AND 160 THEN
  RAISE EXCEPTION 'exam_prep_bad_idempotency_key';
 END IF;
 SELECT program_version_id INTO v_program FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 v_week:=private.exam_prep_effective_active_week_v1(v_uid);
 IF v_program IS NULL OR v_week IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||p_component_code,0));
 SELECT * INTO v_plan FROM private.exam_prep_weekly_plans
 WHERE id=p_plan_id AND user_id=v_uid AND program_version_id=v_program
 AND component_code=p_component_code AND active_week_no=v_week AND status='active' FOR UPDATE;
 SELECT * INTO v_goal FROM private.exam_prep_weekly_goal_snapshots
 WHERE id=p_goal_id AND user_id=v_uid AND program_version_id=v_program
 AND component_code=p_component_code AND active_week_no=v_week;
 IF v_plan.id IS NULL OR v_goal.id IS NULL OR v_goal.item_type NOT IN ('learning','correction')
 OR v_goal.skill_code IS NULL THEN RETURN jsonb_build_object('status','stale'); END IF;
 SELECT count(*)::integer INTO v_matching FROM private.exam_prep_weekly_plan_items i
 WHERE i.plan_id=v_plan.id AND i.status='pending' AND i.item_type=v_goal.item_type
 AND i.skill_code=v_goal.skill_code AND i.correction_case_id IS NOT DISTINCT FROM v_goal.correction_case_id
 AND i.action_code=v_goal.action_code;
 IF v_matching<>1 THEN RETURN jsonb_build_object('status','stale','reason','goal_binding_missing_or_ambiguous'); END IF;
 SELECT * INTO STRICT v_item FROM private.exam_prep_weekly_plan_items i
 WHERE i.plan_id=v_plan.id AND i.status='pending' AND i.item_type=v_goal.item_type
 AND i.skill_code=v_goal.skill_code AND i.correction_case_id IS NOT DISTINCT FROM v_goal.correction_case_id
 AND i.action_code=v_goal.action_code;
 IF (SELECT count(*) FROM private.exam_prep_weekly_plan_items i
     WHERE i.plan_id=v_plan.id AND i.status='pending' AND i.skill_code=v_item.skill_code
      AND i.item_type IN ('learning','correction'))<>1 THEN
  RETURN jsonb_build_object('status','stale','reason','duplicate_skill_binding');
 END IF;

 -- Any active attempt, including another review or an unfinished written answer,
 -- is resumed; never generate a second session during a two-device race.
 SELECT count(*)::integer,(array_agg(s.id ORDER BY s.started_at,s.id))[1]
 INTO v_active_count,v_active.id FROM private.exam_prep_sessions s
 WHERE s.user_id=v_uid AND s.program_version_id=v_program AND s.component_code=p_component_code
 AND s.status='active' AND s.session_type IN ('learning','mixed','retest');
 IF v_active_count>1 THEN RETURN jsonb_build_object('status','multiple_active'); END IF;
 IF v_active_count=1 THEN
  RETURN jsonb_build_object('status','resume_existing_session_first','session_id',v_active.id,
    'component_code',p_component_code);
 END IF;
 SELECT * INTO v_reused FROM private.exam_prep_sessions
 WHERE user_id=v_uid AND client_idempotency_key=p_idempotency_key;
 IF v_reused.id IS NOT NULL THEN RETURN jsonb_build_object('status','attempt_already_saved'); END IF;

 SELECT * INTO v_case FROM private.exam_prep_correction_cases c
 WHERE c.user_id=v_uid AND c.component_code=p_component_code AND c.skill_code=v_item.skill_code
 AND c.status IN ('open','remediating','reopened')
 AND (v_item.correction_case_id IS NULL OR c.id=v_item.correction_case_id)
 ORDER BY c.updated_at DESC LIMIT 1 FOR UPDATE;
 IF v_case.id IS NULL THEN RETURN jsonb_build_object('status','waiting','reason','no_open_correction'); END IF;
 SELECT a.id INTO v_ass FROM private.exam_prep_assessments a
 WHERE a.component_code=p_component_code AND a.assessment_type='learning' AND a.status='published'
 AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
            WHERE ai.assessment_id=a.id AND ai.primary_skill_code=v_item.skill_code)
 AND NOT EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
                WHERE ai.assessment_id=a.id AND ai.primary_skill_code<>v_item.skill_code)
 ORDER BY a.id LIMIT 1;
 IF v_ass IS NULL THEN RETURN jsonb_build_object('status','waiting','reason','content_unavailable'); END IF;
 v_verdict:=private.exam_prep_learning_review_verdict_v1(
    v_uid,v_program,p_component_code,v_item.skill_code,v_ass);
 IF v_verdict->>'status'<>'repeat_learning' THEN
  RETURN jsonb_build_object('status','waiting','reason',coalesce(v_verdict->>'status','unverifiable'));
 END IF;

 INSERT INTO private.exam_prep_session_authorizations(
  user_id,assessment_id,component_code,purpose,status,valid_until,reason,
  correction_case_id,academic_credit,credit_context
 ) VALUES(v_uid,v_ass,p_component_code,'learning','issued',
  private.exam_prep_effective_academic_now_v1(v_uid)+interval '1 hour',
  'Owner-approved same-pack noncredit learning review',v_case.id,false,'learning_review')
 RETURNING id INTO v_auth;
 INSERT INTO private.exam_prep_learning_review_starts_v1(
  authorization_id,user_id,program_version_id,component_code,plan_id,goal_id,
  priority_order,skill_code,correction_case_id,assessment_id
 ) VALUES(v_auth,v_uid,v_program,p_component_code,v_plan.id,v_goal.id,
          v_item.priority_order,v_item.skill_code,v_case.id,v_ass);
 v_started:=private.exam_prep_legacy_start_session_internal_v1(v_auth,p_idempotency_key);
 IF v_started->>'status'<>'active' OR v_started->>'session_id' IS NULL THEN
  RAISE EXCEPTION 'exam_prep_review_atomic_start_failed';
 END IF;
 UPDATE private.exam_prep_correction_cases
 SET status='remediating',updated_at=private.exam_prep_effective_academic_now_v1(v_uid)
 WHERE id=v_case.id;
 PERFORM private.exam_prep_log_correction_action_v1(v_case.id,'remediation_authorized',null,null,null,
   jsonb_build_object('authorization_id',v_auth,'assessment_id',v_ass,'noncredit_review',true));
 RETURN jsonb_build_object('status','started','session_id',v_started->>'session_id',
  'component_code',p_component_code,'goal_id',v_goal.id,'plan_id',v_plan.id,
  'repeat_learning',true,'academic_credit',false,'prior_progress_retained',true,
  'not_a_new_independent_check',true);
END;$body$;
REVOKE ALL ON FUNCTION public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)
 FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)
 TO authenticated;
COMMIT;
