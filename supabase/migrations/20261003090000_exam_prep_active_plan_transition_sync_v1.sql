-- Exam Prep active-plan transition sync v1
-- Production-safe repair for stale weekly-plan actions after learner state transitions.
-- Keeps plan_id/priority/frozen weekly goals/history intact; only the active pending action is reconciled.
-- No legacy Practice/Tour/rating/certificate/localStorage state is touched.

BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '60s';

CREATE TEMP TABLE _ep_transition_feature_before ON COMMIT DROP AS
SELECT id,program_key,rollout_state,core_enabled,ai_enabled,mentor_enabled,kill_switch,
       qa_open_all_core,qa_open_all_weekly,updated_at
FROM private.exam_prep_feature_config
WHERE id=1;

CREATE TEMP TABLE _ep_transition_legacy_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM public.users) AS users_count,
  (SELECT count(*) FROM public.practice_answers) AS practice_answers_count,
  (SELECT count(*) FROM public.tour_answers) AS tour_answers_count,
  (SELECT count(*) FROM public.certificates) AS certificates_count;

CREATE OR REPLACE FUNCTION private.exam_prep_reconcile_active_plan_transitions_v1(
  p_user_id uuid,
  p_component_code text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_plan private.exam_prep_weekly_plans%ROWTYPE;
  v_item private.exam_prep_weekly_plan_items%ROWTYPE;
  v_case private.exam_prep_correction_cases%ROWTYPE;
  v_retest private.exam_prep_retest_events%ROWTYPE;
  v_original_payload jsonb;
  v_original_action text;
  v_transitioned integer := 0;
  v_completed integer := 0;
  v_restored integer := 0;
BEGIN
  IF p_user_id IS NULL OR p_component_code NOT IN ('P1','P5') THEN
    RETURN jsonb_build_object('status','ignored','reason','invalid_scope');
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('exam-prep-plan-transition:'||p_user_id::text||':'||p_component_code,0)
  );

  SELECT p.* INTO v_plan
  FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=p_user_id
    AND p.component_code=p_component_code
    AND p.status='active'
  ORDER BY p.generated_at DESC,p.plan_version DESC,p.id DESC
  LIMIT 1
  FOR UPDATE;

  IF v_plan.id IS NULL THEN
    RETURN jsonb_build_object('status','no_active_plan','transitioned',0,'completed',0,'restored',0);
  END IF;

  FOR v_item IN
    SELECT i.*
    FROM private.exam_prep_weekly_plan_items i
    WHERE i.plan_id=v_plan.id
      AND i.status='pending'
    ORDER BY i.priority_order
    FOR UPDATE
  LOOP
    IF v_item.correction_case_id IS NOT NULL THEN
      SELECT c.* INTO v_case
      FROM private.exam_prep_correction_cases c
      WHERE c.id=v_item.correction_case_id
        AND c.user_id=p_user_id
        AND c.component_code=p_component_code;

      IF v_case.id IS NULL OR v_item.skill_code IS DISTINCT FROM v_case.skill_code THEN
        CONTINUE;
      END IF;

      IF v_case.status='resolved' THEN
        UPDATE private.exam_prep_weekly_plan_items
        SET status='completed'
        WHERE plan_id=v_plan.id
          AND priority_order=v_item.priority_order
          AND status='pending';
        IF FOUND THEN v_completed:=v_completed+1; END IF;
        CONTINUE;
      END IF;

      IF v_case.status='retest_due' THEN
        SELECT r.* INTO v_retest
        FROM private.exam_prep_retest_events r
        WHERE r.correction_case_id=v_case.id
          AND r.user_id=p_user_id
          AND r.component_code=p_component_code
          AND r.status IN ('scheduled','authorized')
        ORDER BY r.created_at DESC,r.id DESC
        LIMIT 1;

        IF v_retest.id IS NULL THEN
          CONTINUE;
        END IF;

        IF v_item.item_type='correction' THEN
          v_original_payload:=v_item.action_payload;
          v_original_action:=v_item.action_code;
          UPDATE private.exam_prep_weekly_plan_items
          SET item_type='retest',
              due_at=v_retest.due_not_before,
              action_code='COMPLETE_DELAYED_RETEST',
              action_payload=jsonb_build_object(
                'preserve_in_recovery',true,
                'transition_original_action_code',v_original_action,
                'transition_original_action_payload',v_original_payload
              )
          WHERE plan_id=v_plan.id
            AND priority_order=v_item.priority_order
            AND status='pending'
            AND correction_case_id=v_case.id;
          IF FOUND THEN v_transitioned:=v_transitioned+1; END IF;
        ELSIF v_item.item_type='retest' THEN
          UPDATE private.exam_prep_weekly_plan_items
          SET due_at=v_retest.due_not_before,
              action_code='COMPLETE_DELAYED_RETEST',
              action_payload=coalesce(v_item.action_payload,'{}'::jsonb)
                || jsonb_build_object('preserve_in_recovery',true)
          WHERE plan_id=v_plan.id
            AND priority_order=v_item.priority_order
            AND status='pending'
            AND correction_case_id=v_case.id
            AND (
              due_at IS DISTINCT FROM v_retest.due_not_before
              OR action_code IS DISTINCT FROM 'COMPLETE_DELAYED_RETEST'
              OR coalesce((action_payload->>'preserve_in_recovery')::boolean,false) IS DISTINCT FROM true
            );
          IF FOUND THEN v_transitioned:=v_transitioned+1; END IF;
        END IF;
        CONTINUE;
      END IF;

      IF v_case.status IN ('open','remediating','reopened') AND v_item.item_type='retest' THEN
        v_original_payload:=v_item.action_payload->'transition_original_action_payload';
        v_original_action:=nullif(v_item.action_payload->>'transition_original_action_code','');
        UPDATE private.exam_prep_weekly_plan_items
        SET item_type='correction',
            due_at=NULL,
            action_code=coalesce(v_original_action,'COMPLETE_CORRECTION_ANALOGUES'),
            action_payload=coalesce(
              v_original_payload,
              jsonb_build_object(
                'analogue_floor',3,
                'analogue_ceiling',6,
                'written_or_unprompted_required',true
              )
            )
        WHERE plan_id=v_plan.id
          AND priority_order=v_item.priority_order
          AND status='pending'
          AND correction_case_id=v_case.id;
        IF FOUND THEN v_restored:=v_restored+1; END IF;
      END IF;

      CONTINUE;
    END IF;

    IF (
      (v_item.item_type='learning' AND EXISTS(
        SELECT 1
        FROM private.exam_prep_session_authorizations a
        JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
        WHERE a.user_id=p_user_id
          AND a.plan_id=v_plan.id
          AND a.plan_priority_order=v_item.priority_order
          AND s.user_id=p_user_id
          AND s.component_code=p_component_code
          AND s.status='finalized'
          AND s.session_type='learning'
      ))
      OR
      (v_item.item_type='mixed_transfer' AND EXISTS(
        SELECT 1
        FROM private.exam_prep_session_authorizations a
        JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
        WHERE a.user_id=p_user_id
          AND a.plan_id=v_plan.id
          AND a.plan_priority_order=v_item.priority_order
          AND s.user_id=p_user_id
          AND s.component_code=p_component_code
          AND s.status='finalized'
          AND s.session_type='mixed'
      ))
      OR
      (v_item.item_type='retest' AND EXISTS(
        SELECT 1
        FROM private.exam_prep_session_authorizations a
        JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
        WHERE a.user_id=p_user_id
          AND a.plan_id=v_plan.id
          AND a.plan_priority_order=v_item.priority_order
          AND s.user_id=p_user_id
          AND s.component_code=p_component_code
          AND s.status='finalized'
          AND s.session_type='retest'
      ))
    ) THEN
      UPDATE private.exam_prep_weekly_plan_items
      SET status='completed'
      WHERE plan_id=v_plan.id
        AND priority_order=v_item.priority_order
        AND status='pending';
      IF FOUND THEN v_completed:=v_completed+1; END IF;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'status','reconciled',
    'plan_id',v_plan.id,
    'component_code',p_component_code,
    'transitioned',v_transitioned,
    'completed',v_completed,
    'restored',v_restored
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.exam_prep_reconcile_active_plan_transitions_v1(uuid,text)
FROM PUBLIC,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION private.exam_prep_sync_plan_after_session_finalize_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.status='finalized' AND OLD.status IS DISTINCT FROM NEW.status THEN
    PERFORM private.exam_prep_reconcile_active_plan_transitions_v1(NEW.user_id,NEW.component_code);
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.exam_prep_sync_plan_after_session_finalize_v1()
FROM PUBLIC,anon,authenticated,service_role;

DROP TRIGGER IF EXISTS exam_prep_z_plan_transition_sync_v1 ON private.exam_prep_sessions;
CREATE TRIGGER exam_prep_z_plan_transition_sync_v1
AFTER UPDATE OF status ON private.exam_prep_sessions
FOR EACH ROW
EXECUTE FUNCTION private.exam_prep_sync_plan_after_session_finalize_v1();

CREATE OR REPLACE FUNCTION private.exam_prep_sync_plan_after_correction_change_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM private.exam_prep_reconcile_active_plan_transitions_v1(NEW.user_id,NEW.component_code);
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.exam_prep_sync_plan_after_correction_change_v1()
FROM PUBLIC,anon,authenticated,service_role;

DROP TRIGGER IF EXISTS exam_prep_z_plan_transition_sync_v1 ON private.exam_prep_correction_cases;
CREATE TRIGGER exam_prep_z_plan_transition_sync_v1
AFTER INSERT OR UPDATE OF status,resolved_at ON private.exam_prep_correction_cases
FOR EACH ROW
EXECUTE FUNCTION private.exam_prep_sync_plan_after_correction_change_v1();

CREATE OR REPLACE FUNCTION private.exam_prep_sync_plan_after_retest_change_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM private.exam_prep_reconcile_active_plan_transitions_v1(NEW.user_id,NEW.component_code);
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.exam_prep_sync_plan_after_retest_change_v1()
FROM PUBLIC,anon,authenticated,service_role;

DROP TRIGGER IF EXISTS exam_prep_z_plan_transition_sync_v1 ON private.exam_prep_retest_events;
CREATE TRIGGER exam_prep_z_plan_transition_sync_v1
AFTER INSERT OR UPDATE OF status,due_not_before ON private.exam_prep_retest_events
FOR EACH ROW
EXECUTE FUNCTION private.exam_prep_sync_plan_after_retest_change_v1();

CREATE OR REPLACE FUNCTION private.exam_prep_active_plan_transition_audit_v1()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
WITH active_plans AS (
  SELECT p.*
  FROM private.exam_prep_weekly_plans p
  WHERE p.status='active'
),
duplicate_active AS (
  SELECT count(*)::integer AS n
  FROM (
    SELECT user_id,component_code,count(*)
    FROM active_plans
    GROUP BY user_id,component_code
    HAVING count(*)>1
  ) q
),
items AS (
  SELECT p.user_id,p.component_code,p.id AS plan_id,
         i.priority_order,i.item_type,i.skill_code,i.correction_case_id,
         i.due_at,i.action_code,i.action_payload,i.status
  FROM active_plans p
  JOIN private.exam_prep_weekly_plan_items i ON i.plan_id=p.id
),
cycle AS (
  SELECT i.*,
         c.status AS correction_status,
         c.skill_code AS case_skill_code,
         r.id AS retest_id,
         r.status AS retest_status,
         r.due_not_before
  FROM items i
  LEFT JOIN private.exam_prep_correction_cases c
    ON c.id=i.correction_case_id
   AND c.user_id=i.user_id
   AND c.component_code=i.component_code
  LEFT JOIN LATERAL (
    SELECT r.*
    FROM private.exam_prep_retest_events r
    WHERE r.correction_case_id=c.id
      AND r.user_id=i.user_id
      AND r.component_code=i.component_code
      AND r.status IN ('scheduled','authorized')
    ORDER BY r.created_at DESC,r.id DESC
    LIMIT 1
  ) r ON true
),
counts AS (
  SELECT
    (SELECT n FROM duplicate_active) AS duplicate_active_plan_groups,
    count(*) FILTER(
      WHERE status='pending' AND correction_case_id IS NOT NULL
        AND (correction_status IS NULL OR skill_code IS DISTINCT FROM case_skill_code)
    )::integer AS cycle_scope_mismatch,
    count(*) FILTER(
      WHERE status='pending' AND item_type='correction' AND correction_status='retest_due'
        AND retest_id IS NOT NULL
    )::integer AS correction_should_be_retest,
    count(*) FILTER(
      WHERE status='pending' AND item_type='retest'
        AND correction_status IN ('open','remediating','reopened')
    )::integer AS retest_should_be_correction,
    count(*) FILTER(
      WHERE status='pending' AND item_type IN ('correction','retest')
        AND correction_status='resolved'
    )::integer AS resolved_cycle_item_still_pending,
    count(*) FILTER(
      WHERE status='pending' AND item_type='retest' AND correction_status='retest_due'
        AND retest_id IS NULL
    )::integer AS retest_missing_active_event,
    count(*) FILTER(
      WHERE status='pending' AND item_type='retest' AND correction_status='retest_due'
        AND retest_id IS NOT NULL
        AND (
          due_at IS DISTINCT FROM due_not_before
          OR action_code IS DISTINCT FROM 'COMPLETE_DELAYED_RETEST'
        )
    )::integer AS retest_projection_mismatch,
    (
      SELECT count(*)::integer
      FROM items i
      WHERE i.status='pending'
        AND i.correction_case_id IS NULL
        AND (
          (i.item_type='learning' AND EXISTS(
            SELECT 1 FROM private.exam_prep_session_authorizations a
            JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
            WHERE a.user_id=i.user_id AND a.plan_id=i.plan_id
              AND a.plan_priority_order=i.priority_order
              AND s.user_id=i.user_id AND s.component_code=i.component_code
              AND s.status='finalized' AND s.session_type='learning'
          ))
          OR
          (i.item_type='mixed_transfer' AND EXISTS(
            SELECT 1 FROM private.exam_prep_session_authorizations a
            JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
            WHERE a.user_id=i.user_id AND a.plan_id=i.plan_id
              AND a.plan_priority_order=i.priority_order
              AND s.user_id=i.user_id AND s.component_code=i.component_code
              AND s.status='finalized' AND s.session_type='mixed'
          ))
          OR
          (i.item_type='retest' AND EXISTS(
            SELECT 1 FROM private.exam_prep_session_authorizations a
            JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
            WHERE a.user_id=i.user_id AND a.plan_id=i.plan_id
              AND a.plan_priority_order=i.priority_order
              AND s.user_id=i.user_id AND s.component_code=i.component_code
              AND s.status='finalized' AND s.session_type='retest'
          ))
        )
    ) AS finalized_generic_item_still_pending
  FROM cycle
)
SELECT jsonb_build_object(
  'contract_version','active_plan_transition_audit_v1',
  'duplicate_active_plan_groups',duplicate_active_plan_groups,
  'cycle_scope_mismatch',cycle_scope_mismatch,
  'correction_should_be_retest',correction_should_be_retest,
  'retest_should_be_correction',retest_should_be_correction,
  'resolved_cycle_item_still_pending',resolved_cycle_item_still_pending,
  'retest_missing_active_event',retest_missing_active_event,
  'retest_projection_mismatch',retest_projection_mismatch,
  'finalized_generic_item_still_pending',finalized_generic_item_still_pending,
  'hard_anomaly_count',
    duplicate_active_plan_groups
    + cycle_scope_mismatch
    + correction_should_be_retest
    + retest_should_be_correction
    + resolved_cycle_item_still_pending
    + retest_missing_active_event
    + retest_projection_mismatch
    + finalized_generic_item_still_pending
)
FROM counts;
$function$;

REVOKE ALL ON FUNCTION private.exam_prep_active_plan_transition_audit_v1()
FROM PUBLIC,anon,authenticated,service_role;

-- One-time production repair: reconcile only current active Exam Prep plans.
-- Frozen goals, completed/superseded plans, sessions, responses and evidence are untouched.
DO $backfill$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT DISTINCT user_id,component_code
    FROM private.exam_prep_weekly_plans
    WHERE status='active'
  LOOP
    PERFORM private.exam_prep_reconcile_active_plan_transitions_v1(r.user_id,r.component_code);
  END LOOP;
END;
$backfill$;

DO $postcheck$
DECLARE
  v_feature_before record;
  v_feature_after record;
  v_legacy_before record;
  v_audit jsonb;
BEGIN
  SELECT * INTO STRICT v_feature_before FROM _ep_transition_feature_before;
  SELECT id,program_key,rollout_state,core_enabled,ai_enabled,mentor_enabled,kill_switch,
         qa_open_all_core,qa_open_all_weekly,updated_at
  INTO STRICT v_feature_after
  FROM private.exam_prep_feature_config WHERE id=1;

  IF row(v_feature_before.id,v_feature_before.program_key,v_feature_before.rollout_state,
         v_feature_before.core_enabled,v_feature_before.ai_enabled,v_feature_before.mentor_enabled,
         v_feature_before.kill_switch,v_feature_before.qa_open_all_core,
         v_feature_before.qa_open_all_weekly,v_feature_before.updated_at)
     IS DISTINCT FROM
     row(v_feature_after.id,v_feature_after.program_key,v_feature_after.rollout_state,
         v_feature_after.core_enabled,v_feature_after.ai_enabled,v_feature_after.mentor_enabled,
         v_feature_after.kill_switch,v_feature_after.qa_open_all_core,
         v_feature_after.qa_open_all_weekly,v_feature_after.updated_at)
  THEN
    RAISE EXCEPTION 'exam_prep_transition_sync_feature_state_changed';
  END IF;

  SELECT * INTO STRICT v_legacy_before FROM _ep_transition_legacy_before;
  IF v_legacy_before.users_count IS DISTINCT FROM (SELECT count(*) FROM public.users)
     OR v_legacy_before.practice_answers_count IS DISTINCT FROM (SELECT count(*) FROM public.practice_answers)
     OR v_legacy_before.tour_answers_count IS DISTINCT FROM (SELECT count(*) FROM public.tour_answers)
     OR v_legacy_before.certificates_count IS DISTINCT FROM (SELECT count(*) FROM public.certificates)
  THEN
    RAISE EXCEPTION 'exam_prep_transition_sync_legacy_counts_changed';
  END IF;

  v_audit:=private.exam_prep_active_plan_transition_audit_v1();
  IF coalesce((v_audit->>'hard_anomaly_count')::integer,0)<>0 THEN
    RAISE EXCEPTION 'exam_prep_transition_sync_postcheck_failed %',v_audit;
  END IF;

  IF has_function_privilege('anon',
       'private.exam_prep_reconcile_active_plan_transitions_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('authenticated',
       'private.exam_prep_reconcile_active_plan_transitions_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('service_role',
       'private.exam_prep_reconcile_active_plan_transitions_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('anon',
       'private.exam_prep_active_plan_transition_audit_v1()','EXECUTE')
     OR has_function_privilege('authenticated',
       'private.exam_prep_active_plan_transition_audit_v1()','EXECUTE')
  THEN
    RAISE EXCEPTION 'exam_prep_transition_sync_private_acl_drift';
  END IF;
END;
$postcheck$;

COMMIT;
