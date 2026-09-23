BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';

ALTER TABLE private.exam_prep_feature_config
  ADD COLUMN IF NOT EXISTS qa_open_all_core boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS qa_open_all_weekly boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN private.exam_prep_feature_config.qa_open_all_core
  IS 'Temporary operational QA override. When true, registered authenticated users may access Exam Prep Core without per-user entitlement. Keep false outside an explicitly approved QA window.';
COMMENT ON COLUMN private.exam_prep_feature_config.qa_open_all_weekly
  IS 'Temporary operational QA override. When true together with qa_open_all_core, registered authenticated users use the released weekly-flow path without per-user weekly enrollment. Keep false outside an explicitly approved QA window.';

CREATE OR REPLACE FUNCTION public.get_exam_prep_capabilities_v1()
RETURNS TABLE (
  program_key text,
  rollout_state text,
  core_access boolean,
  ai_assist boolean,
  mentor_care_entitled boolean,
  mentor_assignment_active boolean,
  mentor_authority boolean,
  kill_switch boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH caller AS (
    SELECT auth.uid() AS user_id
  ), cfg AS (
    SELECT
      c.program_key,
      c.rollout_state,
      c.core_enabled,
      c.ai_enabled,
      c.mentor_enabled,
      c.kill_switch,
      c.qa_open_all_core
    FROM private.exam_prep_feature_config c
    WHERE c.id = 1
  ), ent AS (
    SELECT e.user_id, e.core_access, e.ai_assist, e.mentor_care_entitled
    FROM private.exam_prep_feature_entitlements e, caller u
    WHERE e.user_id = u.user_id
      AND e.entitlement_status = 'active'
      AND (e.valid_from IS NULL OR e.valid_from <= now())
      AND (e.valid_until IS NULL OR e.valid_until > now())
  ), svc AS (
    SELECT s.learner_user_id, s.service_status
    FROM private.exam_prep_mentor_service_status s, caller u
    WHERE s.learner_user_id = u.user_id
  ), governed_assignment AS (
    SELECT
      u.user_id,
      (
        EXISTS(SELECT 1 FROM private.exam_prep_active_mentor_assignment_v1(u.user_id,'P1'))
        OR EXISTS(SELECT 1 FROM private.exam_prep_active_mentor_assignment_v1(u.user_id,'P5'))
      ) AS has_active_assignment
    FROM caller u
  ), effective AS (
    SELECT
      caller.user_id,
      cfg.program_key,
      cfg.rollout_state,
      cfg.core_enabled,
      cfg.ai_enabled,
      cfg.mentor_enabled,
      cfg.kill_switch,
      cfg.qa_open_all_core,
      COALESCE(ent.core_access,false) AS ent_core,
      COALESCE(ent.ai_assist,false) AS ent_ai,
      COALESCE(ent.mentor_care_entitled,false) AS ent_mentor,
      COALESCE(svc.service_status='assigned_active',false) AS service_assigned_active,
      COALESCE(governed_assignment.has_active_assignment,false) AS has_governed_assignment
    FROM caller
    LEFT JOIN cfg ON true
    LEFT JOIN ent ON ent.user_id=caller.user_id
    LEFT JOIN svc ON svc.learner_user_id=caller.user_id
    LEFT JOIN governed_assignment ON governed_assignment.user_id=caller.user_id
  )
  SELECT
    COALESCE(e.program_key,'math_as_p1_p5'::text),
    COALESCE(e.rollout_state,'off'::text),
    COALESCE(
      e.user_id IS NOT NULL
      AND EXISTS(SELECT 1 FROM public.users u WHERE u.id=e.user_id)
      AND NOT e.kill_switch
      AND e.core_enabled
      AND e.rollout_state<>'off'
      AND (e.ent_core OR e.qa_open_all_core),
      false
    ),
    COALESCE(
      e.user_id IS NOT NULL
      AND NOT e.kill_switch
      AND e.core_enabled
      AND e.ai_enabled
      AND e.rollout_state<>'off'
      AND e.ent_core
      AND e.ent_ai,
      false
    ),
    COALESCE(
      e.user_id IS NOT NULL
      AND NOT e.kill_switch
      AND e.core_enabled
      AND e.mentor_enabled
      AND e.rollout_state<>'off'
      AND e.ent_core
      AND e.ent_mentor,
      false
    ),
    COALESCE(
      e.user_id IS NOT NULL
      AND NOT e.kill_switch
      AND e.core_enabled
      AND e.mentor_enabled
      AND e.rollout_state<>'off'
      AND e.ent_core
      AND e.ent_mentor
      AND e.service_assigned_active
      AND e.has_governed_assignment,
      false
    ),
    COALESCE(
      e.user_id IS NOT NULL
      AND NOT e.kill_switch
      AND e.core_enabled
      AND e.mentor_enabled
      AND e.rollout_state<>'off'
      AND e.ent_core
      AND e.ent_mentor
      AND e.service_assigned_active
      AND e.has_governed_assignment,
      false
    ),
    COALESCE(e.kill_switch,true)
  FROM effective e;
$function$;

REVOKE ALL ON FUNCTION public.get_exam_prep_capabilities_v1() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_capabilities_v1() TO authenticated,service_role;

CREATE OR REPLACE FUNCTION private.exam_prep_require_core_access_v1()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid;
BEGIN
  v_uid := auth.uid();

  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'exam_prep_auth_required' USING errcode='28000';
  END IF;

  IF NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=v_uid) THEN
    RAISE EXCEPTION 'exam_prep_user_not_found' USING errcode='P0002';
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM private.exam_prep_feature_config c
    WHERE c.program_key='math_as_p1_p5'
      AND c.rollout_state<>'off'
      AND c.core_enabled
      AND NOT c.kill_switch
      AND (
        c.qa_open_all_core
        OR EXISTS(
          SELECT 1
          FROM private.exam_prep_feature_entitlements e
          WHERE e.user_id=v_uid
            AND e.entitlement_status='active'
            AND e.core_access
            AND (e.valid_from IS NULL OR e.valid_from<=now())
            AND (e.valid_until IS NULL OR e.valid_until>now())
        )
      )
  ) THEN
    RAISE EXCEPTION 'exam_prep_core_unavailable' USING errcode='42501';
  END IF;

  RETURN v_uid;
END;
$function$;

CREATE OR REPLACE FUNCTION private.exam_prep_weekly_flow_enrolled_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM private.exam_prep_feature_config f
    WHERE f.program_key='math_as_p1_p5'
      AND f.rollout_state='controlled_beta'
      AND f.core_enabled IS TRUE
      AND f.kill_switch IS FALSE
      AND p_user_id IS NOT NULL
      AND EXISTS(SELECT 1 FROM public.users u WHERE u.id=p_user_id)
      AND (
        (
          f.qa_open_all_core IS TRUE
          AND f.qa_open_all_weekly IS TRUE
        )
        OR EXISTS(
          SELECT 1
          FROM private.exam_prep_weekly_flow_enrollment_v1 e
          WHERE e.user_id=p_user_id
            AND e.enabled IS TRUE
        )
      )
  );
$function$;

DO $postcheck$
DECLARE
  v_bad integer;
BEGIN
  IF NOT EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='private'
      AND table_name='exam_prep_feature_config'
      AND column_name='qa_open_all_core'
  ) OR NOT EXISTS(
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='private'
      AND table_name='exam_prep_feature_config'
      AND column_name='qa_open_all_weekly'
  ) THEN
    RAISE EXCEPTION 'qa_open_all_columns_missing';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_feature_config
  WHERE id=1
    AND (qa_open_all_core IS TRUE OR qa_open_all_weekly IS TRUE);
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'qa_open_all_migration_must_install_closed';
  END IF;

  IF has_function_privilege('anon',
      'public.get_exam_prep_capabilities_v1()'::regprocedure,'EXECUTE') THEN
    RAISE EXCEPTION 'qa_open_all_capabilities_anon_execute_detected';
  END IF;

  IF NOT has_function_privilege('authenticated',
      'public.get_exam_prep_capabilities_v1()'::regprocedure,'EXECUTE') THEN
    RAISE EXCEPTION 'qa_open_all_capabilities_authenticated_execute_missing';
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname='get_exam_prep_capabilities_v1'
      AND p.prosecdef IS TRUE
      AND p.provolatile='s'
  ) THEN
    RAISE EXCEPTION 'qa_open_all_capability_security_contract_failed';
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='private'
      AND p.proname='exam_prep_require_core_access_v1'
      AND p.prosecdef IS TRUE
      AND p.provolatile='s'
  ) THEN
    RAISE EXCEPTION 'qa_open_all_core_guard_security_contract_failed';
  END IF;
END
$postcheck$;

COMMIT;
