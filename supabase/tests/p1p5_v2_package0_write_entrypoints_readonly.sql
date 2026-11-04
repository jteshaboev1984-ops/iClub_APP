-- Issue #450 P0-12 read-only production database function inventory.
-- READ ONLY. NEVER an authorization to reset real users.
-- Inspect catalog metadata/privileges ONLY; no user content or credentials.
-- This audit identifies possible write surfaces; direct-regex matches are NOT
-- a proof of complete nested call coverage and must not be used as a blanket
-- permission patch to all RPCs.
WITH f AS (
 SELECT p.oid,p.proname,p.prosecdef,
        has_function_privilege('authenticated',p.oid,'EXECUTE') AS auth_can_execute,
        has_function_privilege('anon',p.oid,'EXECUTE') AS anon_can_execute,
        pg_get_functiondef(p.oid) AS definition
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname LIKE '%exam_prep%'
)
SELECT count(*) AS exam_prep_public_rpcs,
       count(*) FILTER(WHERE prosecdef) AS security_definer,
       count(*) FILTER(WHERE auth_can_execute) AS auth_callable,
       count(*) FILTER(WHERE anon_can_execute) AS anon_callable,
       count(*) FILTER(WHERE definition ~*
         '(insert[[:space:]]+into|update|delete[[:space:]]+from)[[:space:]]+(private\.)?exam_prep_') AS direct_private_dml_candidates,
       count(*) FILTER(WHERE auth_can_execute AND definition ~*
         '(insert[[:space:]]+into|update|delete[[:space:]]+from)[[:space:]]+(private\.)?exam_prep_') AS auth_direct_private_dml_candidates,
       count(*) FILTER(WHERE auth_can_execute
          AND definition ILIKE '%exam_prep_require_core_access_v1%') AS auth_calls_core_access,
       count(*) FILTER(WHERE auth_can_execute AND definition ~*
          'release_epoch|academic_epoch|progress_epoch|prelaunch_epoch') AS auth_contains_release_epoch_token
FROM f;

-- Low-privilege entrypoints that can change learner state: priority for the
-- post-beta epoch write fence and hosted old-device/queued-retry regression.
WITH f AS (
 SELECT p.oid,p.proname,pg_get_function_identity_arguments(p.oid) AS signature,
        has_function_privilege('authenticated',p.oid,'EXECUTE') AS auth_can_execute,
        pg_get_functiondef(p.oid) AS definition
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname LIKE '%exam_prep%'
)
SELECT proname,signature,
       definition ILIKE '%exam_prep_require_core_access_v1%' AS calls_core_access,
       definition ~* '(insert[[:space:]]+into|update|delete[[:space:]]+from)[[:space:]]+(private\.)?exam_prep_' AS direct_dml_candidate,
       definition ~* 'release_epoch|academic_epoch|progress_epoch|prelaunch_epoch' AS contains_release_epoch_token
FROM f
WHERE auth_can_execute AND
  (definition ~* '(insert[[:space:]]+into|update|delete[[:space:]]+from)[[:space:]]+(private\.)?exam_prep_'
   OR proname IN (
     'start_exam_prep_next_diagnostic_safe_v1',
     'authorize_exam_prep_timed_safe_v1',
     'submit_exam_prep_response_safe_v1',
     'finalize_exam_prep_session_safe_v1',
     'save_exam_prep_exam_profile_v2',
     'save_my_exam_prep_exam_appointment_v1',
     'ensure_exam_prep_balanced_weekly_plan_safe_v1'))
ORDER BY proname,signature;

-- A single feature/entitlement guard is NOT a release-epoch fence.
SELECT p.proname,
       pg_get_functiondef(p.oid) ILIKE '%exam_prep_feature_config%' AS checks_feature_config,
       pg_get_functiondef(p.oid) ILIKE '%exam_prep_feature_entitlements%' AS checks_entitlement,
       pg_get_functiondef(p.oid) ~* 'release_epoch|academic_epoch|progress_epoch|prelaunch_epoch' AS checks_epoch
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='private' AND p.proname='exam_prep_require_core_access_v1';

-- Check for public wrappers whose name is not exam_prep, not a false claim
-- that a 134-RPC name filter captures every caller or deferred write.
SELECT p.proname,
       pg_get_function_identity_arguments(p.oid) AS signature,
       has_function_privilege('authenticated',p.oid,'EXECUTE') AS auth_can_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname NOT LIKE '%exam_prep%'
  AND pg_get_functiondef(p.oid) ILIKE '%private.exam_prep_%'
ORDER BY p.proname,signature;
