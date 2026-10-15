-- P9 immutable READ-ONLY metadata query; NO academic/student rows.
-- Supabase production allowed solely for schema/function metadata recheck.
-- Run manually after authorization; do NOT use this file for migration.
-- This file must never contain DDL, DML, or SELECT on learner records.

SELECT n.nspname AS schema,p.proname AS name,
 pg_get_function_identity_arguments(p.oid) AS identity_args,
 md5(pg_get_functiondef(p.oid)) AS definition_md5,
 p.prosecdef AS security_definer,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
 has_function_privilege('service_role',p.oid,'EXECUTE') AS service_execute
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname IN ('public','private')
 AND (p.proname LIKE '%iclub_ai%v21%'
  OR p.proname LIKE '%iclub_ai%_v2'
  OR p.proname IN ('get_iclub_subject_access_guard_service_v1',
                  'get_iclub_subscription_capabilities_service_v1'))
ORDER BY n.nspname,p.proname;

SELECT n.nspname AS schema,c.relname AS table_name,
 c.relrowsecurity AS rls_enabled,
 count(pol.oid)::integer AS policy_count,
 has_table_privilege('anon',c.oid,'SELECT') AS anon_select,
 has_table_privilege('authenticated',c.oid,'SELECT') AS authenticated_select
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
LEFT JOIN pg_catalog.pg_policy pol ON pol.polrelid=c.oid
WHERE n.nspname IN ('public','private')
 AND c.relname IN
 ('iclub_commercial_access_config','iclub_subject_slot_selections',
  'practice_sessions_v4','practice_session_answers_v4',
  'tour_attempts','tour_session_runtime_v4','subjects','user_subjects')
GROUP BY n.nspname,c.relname,c.relrowsecurity,c.oid
ORDER BY n.nspname,c.relname;

SELECT table_schema,table_name,column_name,data_type,is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public','private')
 AND table_name IN ('subjects','user_subjects','practice_sessions_v4',
  'practice_session_answers_v4','tour_attempts','tour_session_runtime_v4',
  'iclub_subject_slot_selections','iclub_commercial_access_config',
  'iclub_global_ai_runtime_config')
 AND column_name IN ('id','user_id','subject_id','subject_key',
 'status','mode','is_active','finalized_at','end_date','answered_at',
 'question_ids','study_selected','competitive_selected','subject_limits_mode',
 'grandfather_snapshot_completed_at','gateway_enabled','kill_switch',
 'expires_at','updated_at','is_correct','tour_id','attempt_id')
ORDER BY table_schema,table_name,ordinal_position;
