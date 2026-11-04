-- iClub Mathematics P1/P5 - workplan v2.0 / Issue #450
-- PACKAGE 0: proposed learner-state scope inventory and independent safety checks.
-- READ ONLY / NO DATA RESET. Requires SQL editor access to private schema.
-- No SQL in this file changes data, privileges, tables, rows, or feature flags.
-- The 32-table list is a PROVISIONAL study scope, not an approved cleanup allowlist.
-- For final Math-only cleanup, compare program_version_id/ownership and any new FK
-- columns against the latest production schema; do not reset AI, beta consents,
-- protected app data, or governance/audit logs.

-- 1. Exact total row counts (not DELETE counts; no user identifiers exposed).
WITH counts AS (
SELECT 'exam_prep_component_access_gates'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_component_access_gates
UNION ALL
SELECT 'exam_prep_component_placements'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_component_placements
UNION ALL
SELECT 'exam_prep_correction_actions'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_correction_actions
UNION ALL
SELECT 'exam_prep_correction_cases'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_correction_cases
UNION ALL
SELECT 'exam_prep_evidence_events'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_evidence_events
UNION ALL
SELECT 'exam_prep_exam_appointments'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_exam_appointments
UNION ALL
SELECT 'exam_prep_exam_map_revisions'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_exam_map_revisions
UNION ALL
SELECT 'exam_prep_exam_ops_confirmations'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_exam_ops_confirmations
UNION ALL
SELECT 'exam_prep_exam_profiles'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_exam_profiles
UNION ALL
SELECT 'exam_prep_human_review_recommendations'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_human_review_recommendations
UNION ALL
SELECT 'exam_prep_integrity_events'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_integrity_events
UNION ALL
SELECT 'exam_prep_learning_review_starts_v1'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_learning_review_starts_v1
UNION ALL
SELECT 'exam_prep_legacy_evidence_references'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_legacy_evidence_references
UNION ALL
SELECT 'exam_prep_prerequisite_states'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_prerequisite_states
UNION ALL
SELECT 'exam_prep_progress_revalidation_cases'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_progress_revalidation_cases
UNION ALL
SELECT 'exam_prep_progress_revalidation_items'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_progress_revalidation_items
UNION ALL
SELECT 'exam_prep_recovery_cases'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_recovery_cases
UNION ALL
SELECT 'exam_prep_responses'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_responses
UNION ALL
SELECT 'exam_prep_retest_events'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_retest_events
UNION ALL
SELECT 'exam_prep_session_authorizations'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_session_authorizations
UNION ALL
SELECT 'exam_prep_session_items'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_session_items
UNION ALL
SELECT 'exam_prep_sessions'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_sessions
UNION ALL
SELECT 'exam_prep_skill_states'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_skill_states
UNION ALL
SELECT 'exam_prep_stage_states'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_stage_states
UNION ALL
SELECT 'exam_prep_timed_attempt_results'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_timed_attempt_results
UNION ALL
SELECT 'exam_prep_timed_written_self_marks'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_timed_written_self_marks
UNION ALL
SELECT 'exam_prep_weekly_flow_enrollment_v1'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_weekly_flow_enrollment_v1
UNION ALL
SELECT 'exam_prep_weekly_goal_snapshots'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_weekly_goal_snapshots
UNION ALL
SELECT 'exam_prep_weekly_plan_items'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_weekly_plan_items
UNION ALL
SELECT 'exam_prep_weekly_plans'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_weekly_plans
UNION ALL
SELECT 'exam_prep_written_session_check_snapshots'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_written_session_check_snapshots
UNION ALL
SELECT 'exam_prep_written_step_advances_v1'::text AS table_name, count(*)::bigint AS total_rows FROM private.exam_prep_written_step_advances_v1
)
SELECT table_name, total_rows
FROM counts
ORDER BY table_name;

-- 2. Schema drift and graph edges. If any new inbound FK points from a retained
-- table into a candidate learner-state table, reclassify or stop before cleanup.
WITH proposed_target(table_name) AS (
VALUES
  ('exam_prep_component_access_gates'),
  ('exam_prep_component_placements'),
  ('exam_prep_correction_actions'),
  ('exam_prep_correction_cases'),
  ('exam_prep_evidence_events'),
  ('exam_prep_exam_appointments'),
  ('exam_prep_exam_map_revisions'),
  ('exam_prep_exam_ops_confirmations'),
  ('exam_prep_exam_profiles'),
  ('exam_prep_human_review_recommendations'),
  ('exam_prep_integrity_events'),
  ('exam_prep_learning_review_starts_v1'),
  ('exam_prep_legacy_evidence_references'),
  ('exam_prep_prerequisite_states'),
  ('exam_prep_progress_revalidation_cases'),
  ('exam_prep_progress_revalidation_items'),
  ('exam_prep_recovery_cases'),
  ('exam_prep_responses'),
  ('exam_prep_retest_events'),
  ('exam_prep_session_authorizations'),
  ('exam_prep_session_items'),
  ('exam_prep_sessions'),
  ('exam_prep_skill_states'),
  ('exam_prep_stage_states'),
  ('exam_prep_timed_attempt_results'),
  ('exam_prep_timed_written_self_marks'),
  ('exam_prep_weekly_flow_enrollment_v1'),
  ('exam_prep_weekly_goal_snapshots'),
  ('exam_prep_weekly_plan_items'),
  ('exam_prep_weekly_plans'),
  ('exam_prep_written_session_check_snapshots'),
  ('exam_prep_written_step_advances_v1')
)
SELECT conrelid::regclass::text AS child_table,
       confrelid::regclass::text AS parent_table,
       conname AS fk_name,
       condeferrable AS fk_deferrable,
       pg_get_constraintdef(oid) AS fk_definition
FROM pg_constraint
WHERE contype='f'
  AND confrelid IN (
    SELECT ('private.' || table_name)::regclass::oid
    FROM proposed_target
  )
ORDER BY child_table,parent_table,fk_name;

-- 3. Known blockers: authorizations/sessions point to each other through
-- NOT DEFERRABLE RESTRICT FKs. Never delete in naive order. In particular,
-- authorization.consumed_session_id is nullable, sessions.authorization_id is not.
SELECT
  (SELECT count(*)
   FROM private.exam_prep_session_authorizations
   WHERE consumed_session_id IS NOT NULL) AS auth_consumed_session_links,
  (SELECT count(*)
   FROM private.exam_prep_sessions
   WHERE authorization_id IS NOT NULL) AS sessions_with_nonnull_auth,
  (SELECT count(*)
   FROM private.exam_prep_mentor_queue_items
   WHERE recommendation_id IS NOT NULL) AS retained_mentor_links_blocking_reset,
  (SELECT count(*)
   FROM private.exam_prep_audit_events
   WHERE actor_user_id IS NOT NULL OR target_user_id IS NOT NULL) AS retained_actor_or_target_audit_rows;

-- 4. Protected application data and non-Math Exam Prep state.
SELECT jsonb_build_object(
  'public_users', (SELECT count(*) FROM public.users),
  'math_enrollments', (SELECT count(*) FROM public.user_subjects WHERE subject_id=5),
  'math_tours', (SELECT count(*) FROM public.tours WHERE subject_id=5),
  'math_tour_attempts', (SELECT count(*) FROM public.tour_attempts a
    JOIN public.tours t ON t.id=a.tour_id WHERE t.subject_id=5),
  'math_tour_answers', (SELECT count(*) FROM public.tour_answers a
    JOIN public.tour_attempts x ON x.id=a.attempt_id
    JOIN public.tours t ON t.id=x.tour_id WHERE t.subject_id=5),
  'math_certificates', (SELECT count(*) FROM public.certificates WHERE subject_id=5),
  'math_practice_bank_generation', (SELECT generation FROM public.practice_bank_generations
    WHERE subject_id=5 ORDER BY activated_at DESC LIMIT 1),
  'math_practice_v4_sessions', (SELECT count(*) FROM public.practice_sessions_v4 WHERE subject_id=5),
  'math_practice_v4_drills', (SELECT count(*) FROM public.practice_drill_sessions_v4 WHERE subject_id=5),
  'math_practice_attempts', (SELECT count(*) FROM public.practice_attempts WHERE subject_id=5),
  'other_subjects_practice_attempts', (SELECT count(*) FROM public.practice_attempts WHERE subject_id<>5),
  'ai_beta_active_grants', (SELECT count(*) FROM private.exam_prep_feature_entitlements
    WHERE entitlement_status='active' AND ai_assist),
  'ai_beta_policy_records', (SELECT count(*) FROM private.exam_prep_ai_policy),
  'beta_consents', (SELECT count(*) FROM private.exam_prep_beta_consents),
  'beta_members', (SELECT count(*) FROM private.exam_prep_beta_members),
  'written_content_tasks', (SELECT count(*) FROM private.exam_prep_written_tasks),
  'assessments', (SELECT count(*) FROM private.exam_prep_assessments),
  'published_content_versions', (SELECT count(*) FROM private.exam_prep_content_versions
    WHERE status='published'),
  'exam_core_subject_status', (SELECT jsonb_agg(x) FROM
    (SELECT subject_key,status,launch_enabled FROM private.iclub_exam_core_programs_v1 ORDER BY subject_key)x)
) AS protected_invariants;

-- 5. Schema-only publication and scope warning (no cleanup code is authorized).
SELECT 'DRY_RUN_ONLY__NO_DELETE_EXECUTED'::text AS verdict,
       (SELECT count(*) FROM private.exam_prep_program_versions WHERE status='active') AS active_program_versions,
       (SELECT count(*) FROM private.exam_prep_feature_entitlements) AS preserved_entitlement_rows;
