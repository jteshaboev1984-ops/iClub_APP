-- DRAFT / REVIEW ONLY: never run against production. Depends on the three
-- 18/19 September proposals AND atomic legacy dispatch, installed in that order.
-- One explicit learner-confirmed revision, one component, one expected plan.
-- A change to frozen goals is NOT automatically authorized: leave the original
-- plan intact and require a separately designed goal-amendment workflow.
BEGIN;
DO $preflight$
BEGIN
  IF to_regprocedure('private.exam_prep_legacy_generate_v3_internal_v1(text)') IS NULL
     OR to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL
     OR to_regprocedure('public.get_exam_prep_active_plan_session_safe_v1(text)') IS NULL
     OR to_regclass('private.exam_prep_weekly_goal_snapshots') IS NULL THEN
    RAISE EXCEPTION 'explicit_replan_prerequisites_missing';
  END IF;
END $preflight$;

CREATE TABLE private.exam_prep_explicit_weekly_replan_events_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id) ON DELETE RESTRICT,
  component_code text NOT NULL CHECK (component_code IN ('P1','P5')),
  active_week_no smallint NOT NULL CHECK (active_week_no BETWEEN 1 AND 36),
  original_plan_id uuid NOT NULL REFERENCES private.exam_prep_weekly_plans(id) ON DELETE RESTRICT,
  replacement_plan_id uuid NOT NULL REFERENCES private.exam_prep_weekly_plans(id) ON DELETE RESTRICT,
  reason_code text NOT NULL CHECK (reason_code='manual_review'),
  request_key text NOT NULL CHECK (char_length(request_key) BETWEEN 16 AND 160),
  frozen_goals_verified smallint NOT NULL CHECK (frozen_goals_verified BETWEEN 1 AND 3),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id,component_code,request_key),
  CHECK(original_plan_id<>replacement_plan_id)
);
ALTER TABLE private.exam_prep_explicit_weekly_replan_events_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_explicit_weekly_replan_events_v1 FROM PUBLIC,anon,authenticated,service_role;
DROP TRIGGER IF EXISTS exam_prep_explicit_replan_events_immutable_v1
  ON private.exam_prep_explicit_weekly_replan_events_v1;
CREATE TRIGGER exam_prep_explicit_replan_events_immutable_v1
  BEFORE UPDATE OR DELETE ON private.exam_prep_explicit_weekly_replan_events_v1
  FOR EACH ROW EXECUTE FUNCTION private.exam_prep_block_immutable_mutation_v1();

CREATE OR REPLACE FUNCTION public.request_exam_prep_explicit_weekly_replan_safe_v1(
  p_component_code text,p_expected_plan_id uuid,p_reason_code text,
  p_request_key text,p_confirmed boolean
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_plan private.exam_prep_weekly_plans%rowtype;
  v_new private.exam_prep_weekly_plans%rowtype;
  v_previous private.exam_prep_explicit_weekly_replan_events_v1%rowtype;
  v_resume jsonb;
  v_generated jsonb;
  v_original_fingerprint jsonb;
  v_goal_fingerprint jsonb;
  v_new_fingerprint jsonb;
  v_original_count integer;
  v_goals_count integer;
  v_new_count integer;
  v_reason text;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF p_component_code NOT IN ('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
  END IF;
  IF p_expected_plan_id IS NULL OR p_reason_code IS DISTINCT FROM 'manual_review'
     OR p_request_key IS NULL OR char_length(p_request_key) NOT BETWEEN 16 AND 160
     OR p_confirmed IS DISTINCT FROM true THEN
    RETURN jsonb_build_object('status','confirmation_required');
  END IF;
  SELECT program_version_id INTO v_program FROM private.exam_prep_exam_profiles
    WHERE user_id=v_uid;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  IF v_program IS NULL OR v_week IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;

  -- The same advisory lock serializes this request, regular plan opens, goal
  -- authorization, and starts. A second tab cannot quietly change its plan.
  PERFORM pg_advisory_xact_lock(hashtextextended(
    'ep-stable-plan:'||v_uid::text||':'||p_component_code,0));
  SELECT * INTO v_previous FROM private.exam_prep_explicit_weekly_replan_events_v1
    WHERE user_id=v_uid AND component_code=p_component_code AND request_key=p_request_key;
  IF v_previous.id IS NOT NULL THEN
    IF v_previous.original_plan_id IS DISTINCT FROM p_expected_plan_id
       OR v_previous.reason_code IS DISTINCT FROM p_reason_code THEN
      RETURN jsonb_build_object('status','request_key_conflict');
    END IF;
    IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_plans p
              WHERE p.id=v_previous.replacement_plan_id AND p.user_id=v_uid
                AND p.component_code=p_component_code AND p.status='active') THEN
      RETURN jsonb_build_object('status','already_applied',
        'plan_id',v_previous.replacement_plan_id,'previous_plan_id',v_previous.original_plan_id,
        'component_code',p_component_code,'goals_preserved',true);
    END IF;
    RETURN jsonb_build_object('status','stale','reason','plan_changed_since_request');
  END IF;

  SELECT * INTO v_plan FROM private.exam_prep_weekly_plans p
    WHERE p.id=p_expected_plan_id AND p.user_id=v_uid
      AND p.program_version_id=v_program AND p.component_code=p_component_code
      AND p.active_week_no=v_week AND p.status='active' FOR UPDATE;
  IF v_plan.id IS NULL THEN
    RETURN jsonb_build_object('status','stale','reason','expected_plan_not_current');
  END IF;
  v_resume:=public.get_exam_prep_active_plan_session_safe_v1(p_component_code);
  IF v_resume->>'status' IS DISTINCT FROM 'none' THEN
    RETURN jsonb_build_object('status','finish_current_session_first',
      'recovery',v_resume,'component_code',p_component_code);
  END IF;

  -- Once any goal has produced finalized academic work, keep this week's
  -- commitments unchanged. An edited profile does not undo completed evidence.
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_sessions s
    JOIN private.exam_prep_session_authorizations a ON a.id=s.authorization_id
      AND a.user_id=v_uid AND a.component_code=p_component_code AND a.plan_id IS NOT NULL
    JOIN private.exam_prep_weekly_plans p ON p.id=a.plan_id
      AND p.user_id=v_uid AND p.component_code=p_component_code
      AND p.program_version_id=v_program AND p.active_week_no=v_week
    WHERE s.user_id=v_uid AND s.component_code=p_component_code AND s.status='finalized'
  ) THEN
    RETURN jsonb_build_object('status','weekly_work_preserved','reason','completed_work_exists');
  END IF;

  SELECT count(*)::integer,coalesce(jsonb_agg(jsonb_build_array(
      g.priority_order,g.item_type,g.skill_code,g.correction_case_id,
      g.action_code,g.assessment_id) ORDER BY g.priority_order),'[]'::jsonb)
    INTO v_goals_count,v_goal_fingerprint
  FROM private.exam_prep_weekly_goal_snapshots g
  WHERE g.user_id=v_uid AND g.program_version_id=v_program
    AND g.component_code=p_component_code AND g.active_week_no=v_week;
  SELECT count(*)::integer,coalesce(jsonb_agg(jsonb_build_array(
      i.priority_order,i.item_type,i.skill_code,i.correction_case_id,
      i.action_code,CASE WHEN coalesce(i.action_payload->>'assessment_id','') ~ '^[0-9]+$'
                         THEN (i.action_payload->>'assessment_id')::bigint ELSE NULL END)
      ORDER BY i.priority_order),'[]'::jsonb)
    INTO v_original_count,v_original_fingerprint
  FROM private.exam_prep_weekly_plan_items i WHERE i.plan_id=v_plan.id;
  IF v_goals_count=0 OR v_goals_count<>v_original_count
     OR v_goal_fingerprint IS DISTINCT FROM v_original_fingerprint THEN
    RETURN jsonb_build_object('status','goal_review_required','reason','current_goals_not_aligned');
  END IF;

  -- The established planner remains the ONLY academic planner. The inner
  -- subtransaction rolls back ALL writes if priorities/identities change.
  BEGIN
    v_generated:=private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);
    SELECT * INTO v_new FROM private.exam_prep_weekly_plans p
      WHERE p.id=(v_generated->>'plan_id')::uuid AND p.user_id=v_uid
        AND p.program_version_id=v_program AND p.component_code=p_component_code
        AND p.active_week_no=v_week AND p.status='active' FOR UPDATE;
    IF v_new.id IS NULL OR v_new.id=v_plan.id OR EXISTS(
      SELECT 1 FROM private.exam_prep_weekly_plans p WHERE p.id=v_plan.id AND p.status<>'superseded'
    ) THEN RAISE EXCEPTION 'exam_prep_replan_goal_mismatch'; END IF;
    SELECT count(*)::integer,coalesce(jsonb_agg(jsonb_build_array(
      i.priority_order,i.item_type,i.skill_code,i.correction_case_id,
      i.action_code,CASE WHEN coalesce(i.action_payload->>'assessment_id','') ~ '^[0-9]+$'
                         THEN (i.action_payload->>'assessment_id')::bigint ELSE NULL END)
      ORDER BY i.priority_order),'[]'::jsonb)
      INTO v_new_count,v_new_fingerprint
    FROM private.exam_prep_weekly_plan_items i WHERE i.plan_id=v_new.id;
    IF v_new_count<>v_goals_count OR v_new_fingerprint IS DISTINCT FROM v_goal_fingerprint THEN
      RAISE EXCEPTION 'exam_prep_replan_goal_mismatch';
    END IF;
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_reason=MESSAGE_TEXT;
    IF v_reason<>'exam_prep_replan_goal_mismatch' THEN RAISE; END IF;
    RETURN jsonb_build_object('status','goal_review_required','reason','new_priorities_would_change');
  END;

  -- Issued authorizations from the superseded plan cannot start after this
  -- revision. Consumed/finalized history remains untouched.
  UPDATE private.exam_prep_session_authorizations SET status='revoked'
    WHERE user_id=v_uid AND component_code=p_component_code
      AND plan_id=v_plan.id AND status='issued';
  INSERT INTO private.exam_prep_explicit_weekly_replan_events_v1(
    user_id,program_version_id,component_code,active_week_no,original_plan_id,
    replacement_plan_id,reason_code,request_key,frozen_goals_verified
  ) VALUES(v_uid,v_program,p_component_code,v_week,v_plan.id,v_new.id,
           p_reason_code,p_request_key,v_goals_count);
  RETURN jsonb_build_object('status','replanned','plan_id',v_new.id,
    'previous_plan_id',v_plan.id,'component_code',p_component_code,
    'active_week_no',v_week,'goals_preserved',true);
END;
$fn$;
REVOKE ALL ON FUNCTION public.request_exam_prep_explicit_weekly_replan_safe_v1(text,uuid,text,text,boolean)
  FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.request_exam_prep_explicit_weekly_replan_safe_v1(text,uuid,text,text,boolean)
  TO authenticated;
COMMIT;
