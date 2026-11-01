-- Stage A READ-ONLY live RPC contract inventory for Mathematics P1/P5.
-- 61 client-named functions extracted from actual main Exam Prep API, weekly adapter and progress adapter on 2026-11-01.
-- No writes / no PII / no learner table reads. Re-run after a client RPC change.
WITH required(name) AS (
  VALUES
    ('advance_exam_prep_written_step_safe_v1'),
    ('authorize_exam_prep_goal_once_safe_v1'),
    ('authorize_exam_prep_plan_item_safe_v1'),
    ('authorize_exam_prep_revalidation_item_safe_v1'),
    ('authorize_exam_prep_timed_safe_v1'),
    ('ensure_exam_prep_balanced_weekly_plan_safe_v1'),
    ('finalize_exam_prep_session_safe_v1'),
    ('finalize_exam_prep_session_written_v1'),
    ('finalize_exam_prep_timed_safe_v1'),
    ('generate_exam_prep_weekly_plan_safe_v3'),
    ('get_exam_prep_active_plan_session_safe_v1'),
    ('get_exam_prep_capabilities_v1'),
    ('get_exam_prep_correction_queue_safe_v1'),
    ('get_exam_prep_diagnostic_progress_safe_v1'),
    ('get_exam_prep_exam_map_status_safe_v1'),
    ('get_exam_prep_exam_ops_safe_v1'),
    ('get_exam_prep_exam_profile_v1'),
    ('get_exam_prep_final_calibration_safe_v1'),
    ('get_exam_prep_goal_action_state_safe_v1'),
    ('get_exam_prep_integrity_status_safe_v1'),
    ('get_exam_prep_legacy_reference_summary_safe_v1'),
    ('get_exam_prep_materials_library_safe_v1'),
    ('get_exam_prep_overview_safe_v1'),
    ('get_exam_prep_past_paper_companion_safe_v1'),
    ('get_exam_prep_placement_result_safe_v1'),
    ('get_exam_prep_placement_safe_v1'),
    ('get_exam_prep_previous_week_adherence_safe_v1'),
    ('get_exam_prep_readiness_safe_v1'),
    ('get_exam_prep_readiness_summary_safe_v1'),
    ('get_exam_prep_recent_results_safe_v1'),
    ('get_exam_prep_recent_results_written_v1'),
    ('get_exam_prep_recovery_safe_v2'),
    ('get_exam_prep_session_review_safe_v1'),
    ('get_exam_prep_session_review_written_v1'),
    ('get_exam_prep_session_safe_v1'),
    ('get_exam_prep_session_written_v1'),
    ('get_exam_prep_skill_detail_safe_v1'),
    ('get_exam_prep_stage0_workflow_safe_v1'),
    ('get_exam_prep_stage3_closure_safe_v1'),
    ('get_exam_prep_stage4_consolidation_safe_v1'),
    ('get_exam_prep_state_safe_v1'),
    ('get_exam_prep_syllabus_tracker_safe_v1'),
    ('get_exam_prep_timed_catalog_safe_v1'),
    ('get_exam_prep_timed_result_safe_v1'),
    ('get_exam_prep_timed_review_pack_safe_v1'),
    ('get_exam_prep_weekly_plan_safe_v2'),
    ('get_exam_prep_weekly_progress_safe_v1'),
    ('get_exam_prep_written_criteria_safe_v1'),
    ('get_exam_prep_written_step_status_safe_v1'),
    ('get_my_exam_prep_weekly_flow_status_v1'),
    ('record_exam_prep_integrity_event_safe_v1'),
    ('record_my_exam_prep_interruption_v2'),
    ('save_exam_prep_exam_profile_v2'),
    ('save_my_exam_prep_exam_appointment_v1'),
    ('set_my_exam_prep_exam_ops_confirmation_v1'),
    ('start_exam_prep_learning_review_safe_v1'),
    ('start_exam_prep_next_diagnostic_safe_v1'),
    ('start_exam_prep_plan_session_once_safe_v1'),
    ('start_exam_prep_session_safe_v1'),
    ('submit_exam_prep_response_safe_v1'),
    ('submit_exam_prep_timed_written_self_mark_safe_v1')
), observed AS (
 SELECT r.name, COUNT(p.oid) FILTER(WHERE n.nspname='public') AS public_implementations,
 COALESCE(bool_or(has_function_privilege('authenticated',p.oid,'EXECUTE')) FILTER(WHERE n.nspname='public'),false) AS authenticated_execute,
 COALESCE(bool_or(has_function_privilege('anon',p.oid,'EXECUTE')) FILTER(WHERE n.nspname='public'),false) AS anon_execute
 FROM required r
 LEFT JOIN pg_proc p ON p.proname=r.name
 LEFT JOIN pg_namespace n ON n.oid=p.pronamespace AND n.nspname='public'
 GROUP BY r.name
)
SELECT COUNT(*) AS expected_client_rpcs,
 COUNT(*) FILTER(WHERE public_implementations=1 AND authenticated_execute AND NOT anon_execute) AS passed_exact_public_auth_only,
 COUNT(*) FILTER(WHERE public_implementations<>1) AS missing_or_ambiguous,
 COUNT(*) FILTER(WHERE NOT authenticated_execute) AS authenticated_missing,
 COUNT(*) FILTER(WHERE anon_execute) AS anonymous_leak,
 COALESCE(array_agg(name ORDER BY name) FILTER(
  WHERE public_implementations<>1 OR NOT authenticated_execute OR anon_execute
 ),ARRAY[]::text[]) AS failed_function_names
FROM observed;
