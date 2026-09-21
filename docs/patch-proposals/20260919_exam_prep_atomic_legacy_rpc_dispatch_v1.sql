-- REVIEW PROPOSAL ONLY. NOT A MIGRATION; DO NOT RUN ON PRODUCTION.
-- Test on disposable PG17 after three prerequisite SQL files AND the 11-RPC backup.
-- All eight original public entrypoints are retained for UNENROLLED learners.
-- Exactly one server-controlled cohort gate; JS flags are not authorization.
-- Enrollment starts empty. No legacy Practice/Tour or learner evidence writes.
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
REVOKE ALL ON TABLE private.exam_prep_weekly_flow_enrollment_v1 FROM PUBLIC,anon,authenticated,service_role;

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
REVOKE ALL ON FUNCTION private.exam_prep_weekly_flow_enrolled_v1(uuid) FROM PUBLIC,anon,authenticated,service_role;

-- Private originals must be created BEFORE altering any public entrypoint.
-- Copy every callable path, including v1 and direct correction/mixed/retest.
-- Rewrite only original internal-to-internal delegation, never Core math logic.
DO $copy$
DECLARE
 v_old text; v_new text; v_signature text; v_definition text;
 v_anchor text; v_call_old text; v_call_new text;
 v_names text[][] := ARRAY[
  ARRAY['generate_exam_prep_weekly_plan_safe_v1','exam_prep_legacy_generate_v1_internal_v1','text,text'],
  ARRAY['generate_exam_prep_weekly_plan_safe_v2','exam_prep_legacy_generate_v2_internal_v1','text'],
  ARRAY['generate_exam_prep_weekly_plan_safe_v3','exam_prep_legacy_generate_v3_internal_v1','text'],
  ARRAY['authorize_exam_prep_correction_safe_v1','exam_prep_legacy_correction_internal_v1','uuid'],
  ARRAY['authorize_exam_prep_mixed_safe_v1','exam_prep_legacy_mixed_internal_v1','text'],
  ARRAY['authorize_exam_prep_retest_safe_v1','exam_prep_legacy_retest_internal_v1','uuid'],
  ARRAY['authorize_exam_prep_plan_item_safe_v1','exam_prep_legacy_authorize_plan_internal_v1','uuid,integer'],
  ARRAY['start_exam_prep_session_safe_v1','exam_prep_legacy_start_session_internal_v1','uuid,text']
 ];
 v_i integer;
BEGIN
 FOR v_i IN 1..8 LOOP
  v_old:=v_names[v_i][1]; v_new:=v_names[v_i][2]; v_signature:=v_names[v_i][3];
  IF to_regprocedure('public.'||v_old||'('||v_signature||')') IS NULL THEN
   RAISE EXCEPTION 'RPC compatibility source missing: %',v_old;
  END IF;
  v_definition:=pg_get_functiondef(to_regprocedure('public.'||v_old||'('||v_signature||')'));
  v_anchor:='FUNCTION public.'||v_old||'(';
  IF (length(v_definition)-length(replace(v_definition,v_anchor,'')))<>length(v_anchor) THEN
   RAISE EXCEPTION 'RPC source header changed: %',v_old;
  END IF;
  v_definition:=replace(v_definition,v_anchor,'FUNCTION private.'||v_new||'(');
  IF v_i=3 THEN
   v_call_old:='public.generate_exam_prep_weekly_plan_safe_v2(p_component_code)';
   v_call_new:='private.exam_prep_legacy_generate_v2_internal_v1(p_component_code)';
   IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
    RAISE EXCEPTION 'Legacy v3 to v2 delegation drift';
   END IF;
   v_definition:=replace(v_definition,v_call_old,v_call_new);
  END IF;
  IF v_i=7 THEN
   v_call_old:='public.authorize_exam_prep_correction_safe_v1(';
   v_call_new:='private.exam_prep_legacy_correction_internal_v1(';
   IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
    RAISE EXCEPTION 'Core correction delegation drift';
   END IF;
   v_definition:=replace(v_definition,v_call_old,v_call_new);
   v_call_old:='public.authorize_exam_prep_retest_safe_v1(';
   v_call_new:='private.exam_prep_legacy_retest_internal_v1(';
   IF (length(v_definition)-length(replace(v_definition,v_call_old,'')))<>length(v_call_old) THEN
    RAISE EXCEPTION 'Core retest delegation drift';
   END IF;
   v_definition:=replace(v_definition,v_call_old,v_call_new);
  END IF;
  EXECUTE v_definition;
 END LOOP;
END;$copy$;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v1_internal_v1(text,text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v2_internal_v1(text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_generate_v3_internal_v1(text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_correction_internal_v1(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_mixed_internal_v1(text) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_retest_internal_v1(uuid) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer) FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION private.exam_prep_legacy_start_session_internal_v1(uuid,text) FROM PUBLIC,anon,authenticated,service_role;

-- Patch three DRAFT new functions to use inaccessible internal Core originals.
-- Fail on even one upstream body-anchor change, preventing silent recursion.
DO $guard$
DECLARE v_function text; v_def text; v_old text; v_new text; v_guard text;
BEGIN
 v_function:='public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)';
 v_def:=pg_get_functiondef(v_function::regprocedure);
 v_old:='v_generated:=public.generate_exam_prep_weekly_plan_safe_v3(p_component_code);';
 v_new:='v_generated:=private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Stable-plan generator anchor changed'; END IF;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='v_uid := private.exam_prep_require_core_access_v1();';
 v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Stable-plan owner gate anchor changed'; END IF;
 EXECUTE replace(v_def,v_old,v_guard);

 v_function:='public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)';
 v_def:=pg_get_functiondef(v_function::regprocedure);
 v_old:='v_authorized:=public.authorize_exam_prep_plan_item_safe_v1(p_plan_id,v_priority);';
 v_new:='v_authorized:=private.exam_prep_legacy_authorize_plan_internal_v1(p_plan_id,v_priority);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Goal authorization delegate changed'; END IF;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Goal authorization owner gate changed'; END IF;
 EXECUTE replace(v_def,v_old,v_guard);

 v_function:='public.start_exam_prep_plan_session_once_safe_v1(uuid,text)';
 v_def:=pg_get_functiondef(v_function::regprocedure);
 v_old:='v_started:=public.start_exam_prep_session_safe_v1(p_authorization_id,p_idempotency_key);';
 v_new:='v_started:=private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Once-only starter delegate changed'; END IF;
 v_def:=replace(v_def,v_old,v_new);
 v_old:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_guard:=v_old||E'\n  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN\n    RAISE EXCEPTION ''exam_prep_weekly_flow_not_enabled'' USING errcode=''42501'';\n  END IF;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN RAISE EXCEPTION 'Once-only starter owner gate changed'; END IF;
 EXECUTE replace(v_def,v_old,v_guard);
END;$guard$;

-- Legacy v1 has distinct recovery semantics. Do not silently discard mode or
-- replace an enrolled learner's plan; only the existing new recovery flow may do so.
CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v1(
 p_component_code text,p_recovery_mode text DEFAULT 'normal'::text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_legacy_plan_use_current_flow' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_generate_v1_internal_v1(p_component_code,p_recovery_mode);
END;$body$;

CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v2(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RETURN public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);
 END IF;
 RETURN private.exam_prep_legacy_generate_v2_internal_v1(p_component_code);
END;$body$;

CREATE OR REPLACE FUNCTION public.generate_exam_prep_weekly_plan_safe_v3(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RETURN public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);
 END IF;
 RETURN private.exam_prep_legacy_generate_v3_internal_v1(p_component_code);
END;$body$;

-- All direct old academic authorizers fail closed for ENROLLED learners.
-- The exact goal path calls private Core originals, including correction/retest.
CREATE OR REPLACE FUNCTION public.authorize_exam_prep_correction_safe_v1(p_correction_case_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_exact_goal_required' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_correction_internal_v1(p_correction_case_id);
END;$body$;

CREATE OR REPLACE FUNCTION public.authorize_exam_prep_mixed_safe_v1(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_exact_goal_required' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_mixed_internal_v1(p_component_code);
END;$body$;

CREATE OR REPLACE FUNCTION public.authorize_exam_prep_retest_safe_v1(p_correction_case_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_exact_goal_required' USING errcode='42501';
 END IF;
 RETURN private.exam_prep_legacy_retest_internal_v1(p_correction_case_id);
END;$body$;

CREATE OR REPLACE FUNCTION public.authorize_exam_prep_plan_item_safe_v1(p_plan_id uuid,p_priority_order integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  RETURN jsonb_build_object('status','goal_identity_required');
 END IF;
 RETURN private.exam_prep_legacy_authorize_plan_internal_v1(p_plan_id,p_priority_order);
END;$body$;

-- Guard BOTH plan-bound and unbound academic-credit authorizations. Preserve
-- existing ACTIVE sessions even across rollout; never replay a finalized ID.
-- Genuine separate Stage0 diagnostic, stage-gated timed/paper, and noncredit
-- progress revalidation remain available under their original Core contracts.
CREATE OR REPLACE FUNCTION public.start_exam_prep_session_safe_v1(
 p_authorization_id uuid,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $body$
DECLARE
 v_uid uuid;
 v_auth private.exam_prep_session_authorizations%rowtype;
 v_existing private.exam_prep_sessions%rowtype;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
  SELECT * INTO v_auth FROM private.exam_prep_session_authorizations
   WHERE id=p_authorization_id AND user_id=v_uid FOR UPDATE;
  IF v_auth.id IS NULL THEN RAISE EXCEPTION 'exam_prep_authorization_not_found' USING errcode='P0002'; END IF;
  IF v_auth.plan_id IS NOT NULL THEN
   RETURN public.start_exam_prep_plan_session_once_safe_v1(p_authorization_id,p_idempotency_key);
  END IF;
  IF v_auth.status='consumed' AND v_auth.consumed_session_id IS NOT NULL THEN
   SELECT * INTO v_existing FROM private.exam_prep_sessions
    WHERE id=v_auth.consumed_session_id AND user_id=v_uid AND authorization_id=v_auth.id;
   IF v_existing.id IS NOT NULL AND v_existing.status='active' THEN
    RETURN private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);
   END IF;
   IF v_existing.id IS NOT NULL AND v_existing.status='finalized' THEN
    RETURN jsonb_build_object('status','attempt_already_saved','resumed',true);
   END IF;
  END IF;
  IF v_auth.purpose IN ('learning','mixed','retest') AND coalesce(v_auth.academic_credit,true) THEN
   RAISE EXCEPTION 'exam_prep_exact_weekly_goal_required' USING errcode='42501';
  END IF;
  IF v_auth.purpose NOT IN ('diagnostic','timed','paper') AND
     NOT (v_auth.purpose='retest' AND v_auth.academic_credit IS FALSE
          AND v_auth.credit_context='progress_revalidation') THEN
   RAISE EXCEPTION 'exam_prep_unrecognized_nonplan_authorization' USING errcode='42501';
  END IF;
 END IF;
 RETURN private.exam_prep_legacy_start_session_internal_v1(p_authorization_id,p_idempotency_key);
END;$body$;

DO $verify$
DECLARE v_fn text;
BEGIN
 FOREACH v_fn IN ARRAY ARRAY[
  'private.exam_prep_legacy_generate_v1_internal_v1(text,text)',
  'private.exam_prep_legacy_generate_v2_internal_v1(text)',
  'private.exam_prep_legacy_generate_v3_internal_v1(text)',
  'private.exam_prep_legacy_correction_internal_v1(uuid)',
  'private.exam_prep_legacy_mixed_internal_v1(text)',
  'private.exam_prep_legacy_retest_internal_v1(uuid)',
  'private.exam_prep_legacy_authorize_plan_internal_v1(uuid,integer)',
  'private.exam_prep_legacy_start_session_internal_v1(uuid,text)',
  'private.exam_prep_weekly_flow_enrolled_v1(uuid)'
 ] LOOP
  IF has_function_privilege('authenticated',v_fn,'EXECUTE') OR
     has_function_privilege('anon',v_fn,'EXECUTE') OR
     has_function_privilege('service_role',v_fn,'EXECUTE') THEN
   RAISE EXCEPTION 'Private Core bypass executable: %',v_fn;
  END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_flow_enrollment_v1) THEN
  RAISE EXCEPTION 'Unapproved weekly-flow enrollment present';
 END IF;
END;$verify$;
COMMIT;
