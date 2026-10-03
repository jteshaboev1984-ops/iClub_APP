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
  v_new_plan uuid;
  v_next_version integer;
  v_transitioned integer := 0;
  v_completed integer := 0;
  v_restored integer := 0;
  v_needs_clone boolean := false;
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

  -- A completed academic action may close only its current pending slot.
  -- This does not rewrite frozen goals, sessions, responses or evidence.
  UPDATE private.exam_prep_weekly_plan_items i
  SET status='completed'
  WHERE i.plan_id=v_plan.id
    AND i.status='pending'
    AND (
      (
        i.correction_case_id IS NOT NULL
        AND EXISTS(
          SELECT 1
          FROM private.exam_prep_correction_cases c
          WHERE c.id=i.correction_case_id
            AND c.user_id=p_user_id
            AND c.component_code=p_component_code
            AND c.skill_code=i.skill_code
            AND c.status='resolved'
        )
      )
      OR
      (
        i.correction_case_id IS NULL
        AND (
          (i.item_type='learning' AND EXISTS(
            SELECT 1
            FROM private.exam_prep_session_authorizations a
            JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
            WHERE a.user_id=p_user_id
              AND a.plan_id=v_plan.id
              AND a.plan_priority_order=i.priority_order
              AND s.user_id=p_user_id
              AND s.component_code=p_component_code
              AND s.status='finalized'
              AND s.session_type='learning'
          ))
          OR
          (i.item_type='mixed_transfer' AND EXISTS(
            SELECT 1
            FROM private.exam_prep_session_authorizations a
            JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
            WHERE a.user_id=p_user_id
              AND a.plan_id=v_plan.id
              AND a.plan_priority_order=i.priority_order
              AND s.user_id=p_user_id
              AND s.component_code=p_component_code
              AND s.status='finalized'
              AND s.session_type='mixed'
          ))
          OR
          (i.item_type='retest' AND EXISTS(
            SELECT 1
            FROM private.exam_prep_session_authorizations a
            JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
            WHERE a.user_id=p_user_id
              AND a.plan_id=v_plan.id
              AND a.plan_priority_order=i.priority_order
              AND s.user_id=p_user_id
              AND s.component_code=p_component_code
              AND s.status='finalized'
              AND s.session_type='retest'
          ))
        )
      )
    );
  GET DIAGNOSTICS v_completed = ROW_COUNT;

  -- Existing retest rows may only need their due/action projection refreshed.
  -- This keeps the item's historical type unchanged.
  UPDATE private.exam_prep_weekly_plan_items i
  SET due_at=r.due_not_before,
      action_code='COMPLETE_DELAYED_RETEST',
      action_payload=coalesce(i.action_payload,'{}'::jsonb)
        || jsonb_build_object('preserve_in_recovery',true)
  FROM private.exam_prep_correction_cases c
  JOIN LATERAL (
    SELECT rr.*
    FROM private.exam_prep_retest_events rr
    WHERE rr.correction_case_id=c.id
      AND rr.user_id=p_user_id
      AND rr.component_code=p_component_code
      AND rr.status IN ('scheduled','authorized')
    ORDER BY rr.created_at DESC,rr.id DESC
    LIMIT 1
  ) r ON true
  WHERE i.plan_id=v_plan.id
    AND i.status='pending'
    AND i.item_type='retest'
    AND i.correction_case_id=c.id
    AND c.user_id=p_user_id
    AND c.component_code=p_component_code
    AND c.skill_code=i.skill_code
    AND c.status='retest_due'
    AND (
      i.due_at IS DISTINCT FROM r.due_not_before
      OR i.action_code IS DISTINCT FROM 'COMPLETE_DELAYED_RETEST'
      OR coalesce((i.action_payload->>'preserve_in_recovery')::boolean,false) IS DISTINCT FROM true
    );

  -- Item-type changes are never done in place. The old plan is immutable history:
  -- clone it, supersede it, and transform only the current actionable projection.
  SELECT EXISTS(
    SELECT 1
    FROM private.exam_prep_weekly_plan_items i
    JOIN private.exam_prep_correction_cases c
      ON c.id=i.correction_case_id
     AND c.user_id=p_user_id
     AND c.component_code=p_component_code
     AND c.skill_code=i.skill_code
    WHERE i.plan_id=v_plan.id
      AND i.status='pending'
      AND (
        (
          i.item_type='correction'
          AND c.status='retest_due'
          AND EXISTS(
            SELECT 1
            FROM private.exam_prep_retest_events r
            WHERE r.correction_case_id=c.id
              AND r.user_id=p_user_id
              AND r.component_code=p_component_code
              AND r.status IN ('scheduled','authorized')
          )
        )
        OR
        (
          i.item_type='retest'
          AND c.status IN ('open','remediating','reopened')
        )
      )
  ) INTO v_needs_clone;

  IF v_needs_clone THEN
    SELECT coalesce(max(p.plan_version),0)+1
      INTO v_next_version
    FROM private.exam_prep_weekly_plans p
    WHERE p.user_id=p_user_id
      AND p.component_code=p_component_code
      AND p.active_week_no=v_plan.active_week_no;

    UPDATE private.exam_prep_weekly_plans
    SET status='superseded'
    WHERE id=v_plan.id AND status='active';

    INSERT INTO private.exam_prep_weekly_plans(
      user_id,program_version_id,component_code,active_week_no,plan_version,status,
      recovery_mode,max_priorities,policy_note,recovery_case_id,allocation_policy,
      planning_horizon_days
    )
    VALUES(
      v_plan.user_id,v_plan.program_version_id,v_plan.component_code,v_plan.active_week_no,
      v_next_version,'active',v_plan.recovery_mode,v_plan.max_priorities,v_plan.policy_note,
      v_plan.recovery_case_id,v_plan.allocation_policy,v_plan.planning_horizon_days
    )
    RETURNING id INTO v_new_plan;

    INSERT INTO private.exam_prep_weekly_plan_items(
      plan_id,priority_order,item_type,skill_code,correction_case_id,due_at,
      action_code,action_payload,status,created_at
    )
    SELECT
      v_new_plan,
      i.priority_order,
      CASE
        WHEN i.status='pending' AND i.item_type='correction'
             AND c.status='retest_due' AND r.id IS NOT NULL THEN 'retest'
        WHEN i.status='pending' AND i.item_type='retest'
             AND c.status IN ('open','remediating','reopened') THEN 'correction'
        ELSE i.item_type
      END,
      i.skill_code,
      i.correction_case_id,
      CASE
        WHEN i.status='pending' AND i.item_type='correction'
             AND c.status='retest_due' AND r.id IS NOT NULL THEN r.due_not_before
        WHEN i.status='pending' AND i.item_type='retest'
             AND c.status IN ('open','remediating','reopened') THEN NULL
        ELSE i.due_at
      END,
      CASE
        WHEN i.status='pending' AND i.item_type='correction'
             AND c.status='retest_due' AND r.id IS NOT NULL THEN 'COMPLETE_DELAYED_RETEST'
        WHEN i.status='pending' AND i.item_type='retest'
             AND c.status IN ('open','remediating','reopened')
          THEN coalesce(nullif(i.action_payload->>'transition_original_action_code',''),
                        'COMPLETE_CORRECTION_ANALOGUES')
        ELSE i.action_code
      END,
      CASE
        WHEN i.status='pending' AND i.item_type='correction'
             AND c.status='retest_due' AND r.id IS NOT NULL
          THEN jsonb_build_object(
            'preserve_in_recovery',true,
            'transition_original_action_code',i.action_code,
            'transition_original_action_payload',i.action_payload
          )
        WHEN i.status='pending' AND i.item_type='retest'
             AND c.status IN ('open','remediating','reopened')
          THEN coalesce(
            i.action_payload->'transition_original_action_payload',
            jsonb_build_object(
              'analogue_floor',3,
              'analogue_ceiling',6,
              'written_or_unprompted_required',true
            )
          )
        ELSE i.action_payload
      END,
      i.status,
      i.created_at
    FROM private.exam_prep_weekly_plan_items i
    LEFT JOIN private.exam_prep_correction_cases c
      ON c.id=i.correction_case_id
     AND c.user_id=p_user_id
     AND c.component_code=p_component_code
     AND c.skill_code=i.skill_code
    LEFT JOIN LATERAL (
      SELECT rr.*
      FROM private.exam_prep_retest_events rr
      WHERE rr.correction_case_id=c.id
        AND rr.user_id=p_user_id
        AND rr.component_code=p_component_code
        AND rr.status IN ('scheduled','authorized')
      ORDER BY rr.created_at DESC,rr.id DESC
      LIMIT 1
    ) r ON true
    WHERE i.plan_id=v_plan.id
    ORDER BY i.priority_order;

    SELECT
      count(*) FILTER(
        WHERE old_i.status='pending' AND old_i.item_type='correction'
          AND new_i.item_type='retest'
      )::integer,
      count(*) FILTER(
        WHERE old_i.status='pending' AND old_i.item_type='retest'
          AND new_i.item_type='correction'
      )::integer
    INTO v_transitioned,v_restored
    FROM private.exam_prep_weekly_plan_items old_i
    JOIN private.exam_prep_weekly_plan_items new_i
      ON new_i.plan_id=v_new_plan
     AND new_i.priority_order=old_i.priority_order
    WHERE old_i.plan_id=v_plan.id;

    RETURN jsonb_build_object(
      'status','replanned',
      'previous_plan_id',v_plan.id,
      'plan_id',v_new_plan,
      'component_code',p_component_code,
      'transitioned',coalesce(v_transitioned,0),
      'completed',v_completed,
      'restored',coalesce(v_restored,0)
    );
  END IF;

  RETURN jsonb_build_object(
    'status','reconciled',
    'plan_id',v_plan.id,
    'component_code',p_component_code,
    'transitioned',0,
    'completed',v_completed,
    'restored',0
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
