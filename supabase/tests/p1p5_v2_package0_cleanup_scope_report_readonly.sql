-- Mathematics P1/P5 Issue #450 v2.0: consolidated ONE-ROW SELECT-only report.
-- Read-only dry-run. These are candidate counts, NOT authorization to DELETE.
-- All users, Practice v2 published, Tours, other subjects, AI and audits protected.
WITH candidate_counts AS (
 SELECT 'exam_prep_component_access_gates'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_component_access_gates
 UNION ALL
 SELECT 'exam_prep_component_placements'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_component_placements
 UNION ALL
 SELECT 'exam_prep_correction_actions'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_correction_actions
 UNION ALL
 SELECT 'exam_prep_correction_cases'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_correction_cases
 UNION ALL
 SELECT 'exam_prep_evidence_events'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_evidence_events
 UNION ALL
 SELECT 'exam_prep_exam_appointments'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_exam_appointments
 UNION ALL
 SELECT 'exam_prep_exam_map_revisions'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_exam_map_revisions
 UNION ALL
 SELECT 'exam_prep_exam_ops_confirmations'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_exam_ops_confirmations
 UNION ALL
 SELECT 'exam_prep_exam_profiles'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_exam_profiles
 UNION ALL
 SELECT 'exam_prep_human_review_recommendations'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_human_review_recommendations
 UNION ALL
 SELECT 'exam_prep_integrity_events'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_integrity_events
 UNION ALL
 SELECT 'exam_prep_learning_review_starts_v1'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_learning_review_starts_v1
 UNION ALL
 SELECT 'exam_prep_legacy_evidence_references'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_legacy_evidence_references
 UNION ALL
 SELECT 'exam_prep_prerequisite_states'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_prerequisite_states
 UNION ALL
 SELECT 'exam_prep_progress_revalidation_cases'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_progress_revalidation_cases
 UNION ALL
 SELECT 'exam_prep_progress_revalidation_items'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_progress_revalidation_items
 UNION ALL
 SELECT 'exam_prep_recovery_cases'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_recovery_cases
 UNION ALL
 SELECT 'exam_prep_responses'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_responses
 UNION ALL
 SELECT 'exam_prep_retest_events'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_retest_events
 UNION ALL
 SELECT 'exam_prep_session_authorizations'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_session_authorizations
 UNION ALL
 SELECT 'exam_prep_session_items'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_session_items
 UNION ALL
 SELECT 'exam_prep_sessions'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_sessions
 UNION ALL
 SELECT 'exam_prep_skill_states'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_skill_states
 UNION ALL
 SELECT 'exam_prep_stage_states'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_stage_states
 UNION ALL
 SELECT 'exam_prep_timed_attempt_results'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_timed_attempt_results
 UNION ALL
 SELECT 'exam_prep_timed_written_self_marks'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_timed_written_self_marks
 UNION ALL
 SELECT 'exam_prep_weekly_flow_enrollment_v1'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_weekly_flow_enrollment_v1
 UNION ALL
 SELECT 'exam_prep_weekly_goal_snapshots'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_weekly_goal_snapshots
 UNION ALL
 SELECT 'exam_prep_weekly_plan_items'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_weekly_plan_items
 UNION ALL
 SELECT 'exam_prep_weekly_plans'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_weekly_plans
 UNION ALL
 SELECT 'exam_prep_written_session_check_snapshots'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_written_session_check_snapshots
 UNION ALL
 SELECT 'exam_prep_written_step_advances_v1'::text AS table_name, count(*)::bigint AS n FROM private.exam_prep_written_step_advances_v1
), candidate_names AS (
 SELECT ('private.' || table_name)::regclass::oid AS oid FROM candidate_counts
), inbound AS (
 SELECT conrelid::regclass::text AS child,confrelid::regclass::text AS parent,
        pg_get_constraintdef(oid) AS definition
 FROM pg_constraint WHERE contype='f' AND confrelid IN (SELECT oid FROM candidate_names)
), reference_counts AS (
 SELECT count(*)::int AS all_inbound,
        count(*) FILTER(WHERE child NOT LIKE 'private.exam_prep_%')::int AS outside_private,
        count(*) FILTER(WHERE (child LIKE 'private.exam_prep_%' AND
          child NOT IN (SELECT 'private.'||table_name FROM candidate_counts)))::int AS retained_examprep_inbound
 FROM inbound
)
SELECT jsonb_build_object(
 'verdict','DRY_RUN_ONLY__NO_MUTATIONS',
 'candidate_table_count',(SELECT count(*) FROM candidate_counts),
 'candidate_row_count',(SELECT sum(n) FROM candidate_counts),
 'candidate_tables',(SELECT jsonb_agg(jsonb_build_object('name',table_name,'rows',n) ORDER BY table_name) FROM candidate_counts),
 'inbound_constraints',(SELECT row_to_json(r) FROM reference_counts r),
 'retained_to_candidate_edges',(SELECT coalesce(jsonb_agg(row_to_json(i) ORDER BY child,parent),'[]'::jsonb)
   FROM inbound i WHERE child NOT IN (SELECT 'private.'||table_name FROM candidate_counts)),
 'cycle_links',(SELECT jsonb_build_object(
  'authorization_to_session',(SELECT count(*) FROM private.exam_prep_session_authorizations WHERE consumed_session_id IS NOT NULL),
  'session_to_authorization',(SELECT count(*) FROM private.exam_prep_sessions WHERE authorization_id IS NOT NULL),
  'mentor_queue_refs',(SELECT count(*) FROM private.exam_prep_mentor_queue_items WHERE recommendation_id IS NOT NULL))),
 'excluded_active_data',jsonb_build_object(
  'users',(SELECT count(*) FROM public.users),
  'math_subjects',(SELECT count(*) FROM public.user_subjects WHERE subject_id=5),
  'math_tour_attempts',(SELECT count(*) FROM public.tour_attempts a JOIN public.tours t ON t.id=a.tour_id WHERE t.subject_id=5),
  'math_tour_answers',(SELECT count(*) FROM public.tour_answers a JOIN public.tour_attempts x ON x.id=a.attempt_id JOIN public.tours t ON t.id=x.tour_id WHERE t.subject_id=5),
  'math_certificates',(SELECT count(*) FROM public.certificates WHERE subject_id=5),
  'math_practice_sessions',(SELECT count(*) FROM public.practice_sessions_v4 WHERE subject_id=5),
  'math_practice_drills',(SELECT count(*) FROM public.practice_drill_sessions_v4 WHERE subject_id=5),
  'math_practice_attempts',(SELECT count(*) FROM public.practice_attempts WHERE subject_id=5),
  'practice_current_bank',(SELECT generation FROM public.practice_bank_generations WHERE subject_id=5 ORDER BY activated_at DESC LIMIT 1),
  'non_math_practice_attempts',(SELECT count(*) FROM public.practice_attempts WHERE subject_id<>5),
  'ai_grants',(SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE entitlement_status='active' AND ai_assist),
  'beta_consents',(SELECT count(*) FROM private.exam_prep_beta_consents),
  'audit_events',(SELECT count(*) FROM private.exam_prep_audit_events),
  'math_content_versions',(SELECT count(*) FROM private.exam_prep_content_versions),
  'written_content',(SELECT count(*) FROM private.exam_prep_written_tasks),
  'economics_core_shell_enabled',(SELECT launch_enabled FROM private.iclub_exam_core_programs_v1 WHERE program_key='economics_9708')
 )
) AS cleanup_scope_readonly_report;
