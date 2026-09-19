-- REVIEW PROPOSAL ONLY. NOT A MIGRATION; DO NOT RUN ON PRODUCTION.
-- Test on a disposable PostgreSQL clone after all three prerequisite SQL proposals.
-- Atomic compatibility dispatch protects users enrolled by the SERVER, not a JS flag.
-- Enrollment has zero rows on creation; no student is activated by this script.
-- Existing legacy RPC signatures/grants remain usable for everyone not enrolled.
-- Raw copies of exactly the deployed four functions are private and non-executable
-- by client roles. Never rely on user-settable custom GUCs as security authority.
-- NO legacy data updates, deletes, backfill, change of course/tour state or mastery.
-- Fresh first plans must pass actual Stage 0 evidence gates. Published diagnostic
-- assessments use reserve/withheld question metadata; NEVER relabel them as
-- learning content to satisfy a test. The isolated first-week fixture verifies
-- creation and rollback without crediting any real learner.
BEGIN;

CREATE TABLE private.exam_prep_weekly_flow_enrollment_v1 (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
  enabled boolean NOT NULL DEFAULT false,
  approved_by uuid,
  approved_at timestamptz,
  CONSTRAINT exam_prep_weekly_flow_enrollment_approval_check
    CHECK (enabled IS NOT TRUE OR (approved_by IS NOT NULL AND approved_at IS NOT NULL))
);
ALTER TABLE private.exam_prep_weekly_flow_enrollment_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_weekly_flow_enrollment_v1 FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.exam_prep_weekly_flow_enrolled_v1(p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $body$
  SELECT EXISTS (
    SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1 e
    JOIN private.exam_prep_feature_config f ON f.program_key='math_as_p1_p5'
    WHERE e.user_id=p_user_id AND e.enabled IS TRUE
      AND f.rollout_state='controlled_beta' AND f.core_enabled IS TRUE
      AND f.kill_switch IS FALSE
  );
$body$;
REVOKE ALL ON FUNCTION private.exam_prep_weekly_flow_enrolled_v1(uuid)
  FROM PUBLIC, anon, authenticated, service_role;

-- Copy exact CURRENT function definitions before replacing any public entry point.
-- Wrong signatures or changed source abort this entire transaction. The existing
-- Core academic implementation remains the only source of planning/marking.
DO $copy$
DECLARE
  v_old text;
  v_new text;
  v_signature text;
  v_definition text;
  v_anchor text;
  v_call_old text;
  v_call_new text;
  v_names text[][] := ARRAY[
    ARRAY['generate_exam_prep_weekly_plan_safe_v2','exam_prep_legacy_generate_v2_internal_v1','text'],
    ARRAY['generate_exam_prep_weekly_plan_safe_v3','exam_prep_legacy_generate_v3_internal_v1','text'],
    ARRAY['authorize_exam_prep_plan_item_safe_v1','exam_prep_legacy_authorize_plan_internal_v1','uuid,integer'],
    ARRAY['start_exam_prep_session_safe_v1','exam_prep_legacy_start_session_internal_v1','uuid,text']
  ];
  v_i integer;
BEGIN
  FOR v_i IN 1..4 LOOP
    v_old:=v_names[v_i][1];
    v_new:=v_names[v_i][2];
    v_signature:=v_names[v_i][3];
    IF to_regprocedure('public.'||v_old||'('||v_signature||')') IS NULL THEN
      RAISE EXCEPTION 'RPC compatibility source missing: %',v_old;
    END IF;
    v_definition:=pg_get_functiondef(to_regprocedure('public.'||v_old||'('||v_signature||')'));
    v_anchor:='FUNCTION public.'||v_old||'(';
    IF (length(v_definition)-length(replace(v_definition,v_anchor,'')))<>length(v_anchor) THEN
      RAISE EXCEPTION 'RPC source header changed; manually re-review: %',v_old;
    END IF;
    v_definition:=replace(v_definition,v_anchor,'FUNCTION private.'||v_new||'(');
    IF v_i=2 THEN
      v_call_old:='public.generate_exam_prep_weekly_plan_safe_v2(p_component_code)';
      v_call_new:='private.exam_prep_legacy_generate_v2_internal_v1(p_component_code)';
      IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
        RAISE EXCEPTION 'Legacy v3->v2 delegation changed; re-review before any release';
      END IF;
      v_definition:=replace(v_definition,v_call_old,v_call_new);
    END IF;
    EXECUTE v_definition;
  END LOOP;
END;
$copy$;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v2_internal_v1(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v3_internal_v1(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_start_session_internal_v1(uuid,text) FROM PUBLIC, anon, authenticated, service_role;

-- Patch only the three DRAFT new functions, preserving their existing SQL bodies.
-- The protected new RPCs must call inaccessible private originals, not public
-- compatibility wrappers; otherwise the dispatch would recurse forever.
DO $guard$
DECLARE
  v_function text;
  v_def text;
  v_old text;
  v_new text;
  v_guard text;
BEGIN
  v_function:='public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)';
  v_def:=pg_get_functiondef(v_function::regprocedure);
  v_old:='v_generated:=public.generate_exam_prep_weekly_plan_safe_v3(p_component_code);';
  v_new:='v_generated:=private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'Stable-plan generator anchor changed';
  END IF;
  v_def:=replace(v_def,v_old,v_new);
  v_old:='v_uid := private.exam_prep_require_core_access_v1();';
  v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'Stable-plan owner gate anchor changed';
  END IF;
  EXECUTE replace(v_def,v_old,v_guard);

  v_function:='public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)';
  v_def:=pg_get_functiondef(v_function::regprocedure);
  v_old:='v_authorized:=public.authorize_exam_prep_plan_item_safe_v1(p_plan_id,v_priority);';
  v_new:='v_authorized:=private.exam_prep_legacy_authorize_plan_internal_v1(p_plan_id,v_priority);';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'Goal authorization delegate changed';
  END IF;
  v_def:=replace(v_def,v_old,v_new);
  v_old:='v_uid:=private.exam_prep_require_core_access_v1();';
  v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'Goal authorization owner gate changed';
  END IF;
  EXECUTE replace(v_def,v_old,v_guard);

  v_function:='public.start_exam_prep_plan_session_once_safe_v1(uuid,text)';
  v_def:=pg_get_functiondef(v_function::regprocedure);
  v_old:='v_started:=public.start_exam_prep_session_safe_v1(p_authorization_id,p_idempotency_key);';
  v_new:='v_started:=private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'Once-only starter delegate changed';
  END IF;
  v_def:=replace(v_def,v_old,v_new);
  v_old:='v_uid:=private.exam_prep_require_core_access_v1();';
  v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'Once-only starter owner gate changed';
  END IF;
  EXECUTE replace(v_def,v_old,v_guard);
END;
$guard$;

-- Old direct plan generators must route through the exact SAME advisory lock
-- for enrolled learners. Legacy un-enrolled clients invoke byte-identical copies.
CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v2(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RETURN public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);
  END IF;
  RETURN private.exam_prep_legacy_generate_v2_internal_v1(p_component_code);
END;
$body$;

CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RETURN public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);
  END IF;
  RETURN private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);
END;
$body$;

-- A numeric priority is not an immutable goal identity. Do not infer one for an
-- enrolled learner. Old tabs fail CLOSED rather than issuing a mismatched attempt.
CREATE OR REPLACE FUNCTION public.authorize_exam_prep_plan_item_safe_v1(
  p_plan_id uuid, p_priority_order integer
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RETURN jsonb_build_object('status','goal_identity_required');
  END IF;
  RETURN private.exam_prep_legacy_authorize_plan_internal_v1(p_plan_id,p_priority_order);
END;
$body$;

-- Old tabs can safely resume their PREEXISTING plan authorization, but even
-- direct RPC replay may not expose a finalized session ID. Diagnostics, timed,
-- and recovery have no plan_id and keep the original Core starter untouched.
CREATE OR REPLACE FUNCTION public.start_exam_prep_session_safe_v1(
  p_authorization_id uuid, p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE
  v_uid uuid;
  v_plan_id uuid;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    SELECT plan_id INTO v_plan_id FROM private.exam_prep_session_authorizations
      WHERE id=p_authorization_id AND user_id=v_uid;
    IF v_plan_id IS NOT NULL THEN
      RETURN public.start_exam_prep_plan_session_once_safe_v1(p_authorization_id,p_idempotency_key);
    END IF;
  END IF;
  RETURN private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);
END;
$body$;

-- Existing public grants are preserved by CREATE OR REPLACE. Never grant the
-- private copies to authenticated, anon, service_role or PUBLIC.
DO $verify$
DECLARE v_fn text;
BEGIN
  FOREACH v_fn IN ARRAY ARRAY[
    'private.exam_prep_legacy_generate_v2_internal_v1(text)',
    'private.exam_prep_legacy_generate_v3_internal_v1(text)',
    'private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)',
    'private.exam_prep_legacy_start_session_internal_v1(uuid,text)',
    'private.exam_prep_weekly_flow_enrolled_v1(uuid)'
  ] LOOP
    IF has_function_privilege('authenticated',v_fn,'EXECUTE') OR
       has_function_privilege('anon',v_fn,'EXECUTE') OR
       has_function_privilege('service_role',v_fn,'EXECUTE') THEN
      RAISE EXCEPTION 'A private bypass became executable: %',v_fn;
    END IF;
  END LOOP;
  IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1) THEN
    RAISE EXCEPTION 'Unapproved weekly-flow enrollment present';
  END IF;
END;
$verify$;
COMMIT;