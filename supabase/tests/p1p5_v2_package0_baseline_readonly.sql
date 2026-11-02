-- Mathematics Exam Prep P1/P5 / Issue #450 / workplan v2.0
-- PACKAGE 0: REPEATABLE READ-ONLY BASELINE. No writes, migration or user identifiers.
-- Do not turn this into a "cleanup" script; numbers can change between reads.
-- Note: execute as a read-only observer / SQL editor, never grant public access.

SELECT jsonb_build_object(
  'users_total', (SELECT count(*) FROM public.users),
  'math_enrollments', (SELECT count(DISTINCT user_id) FROM public.user_subjects WHERE subject_id=5),
  'exam_prep_sessions', (SELECT count(*) FROM private.exam_prep_sessions),
  'exam_prep_sessions_active', (SELECT count(*) FROM private.exam_prep_sessions WHERE status='active'),
  'exam_prep_exam_profiles', (SELECT count(*) FROM private.exam_prep_exam_profiles),
  'math_ai_active_grants', (SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE entitlement_status='active' AND ai_assist),
  'math_core_active_grants', (SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE entitlement_status='active' AND core_access),
  'timed_attempt_results', (SELECT count(*) FROM private.exam_prep_timed_attempt_results),
  'timed_written_self_marks', (SELECT count(*) FROM private.exam_prep_timed_written_self_marks),
  'approved_stage5_thresholds', (SELECT count(*) FROM private.exam_prep_stage5_thresholds WHERE status='approved'),
  'feature_config', (SELECT row_to_json(c) FROM
     (SELECT rollout_state, core_enabled, ai_enabled, mentor_enabled,
             kill_switch, qa_open_all_core, qa_open_all_weekly
        FROM private.exam_prep_feature_config WHERE program_key='math_as_p1_p5' LIMIT 1) c)
) AS baseline_readonly;

WITH tables AS (
 SELECT table_name,
        count(*) FILTER(WHERE column_name IN ('user_id','learner_user_id','owner_user_id')) > 0 AS direct_user,
        count(*) FILTER(WHERE column_name IN ('session_id','plan_id','correction_case_id','response_id')) > 0 AS indirect_link
   FROM information_schema.columns
  WHERE table_schema='private' AND table_name LIKE 'exam_prep_%'
  GROUP BY table_name
),
foreign_keys AS (
 SELECT tc.table_name, count(*) AS fk_count
   FROM information_schema.table_constraints tc
  WHERE tc.table_schema='private' AND tc.table_name LIKE 'exam_prep_%'
    AND tc.constraint_type='FOREIGN KEY'
  GROUP BY tc.table_name
)
SELECT count(*) AS exam_prep_tables,
       count(*) FILTER(WHERE t.direct_user) AS direct_user_tables,
       count(*) FILTER(WHERE t.indirect_link AND NOT t.direct_user) AS indirect_link_only_tables,
       sum(coalesce(fk.fk_count,0)) AS fk_constraints,
       jsonb_agg(t.table_name ORDER BY t.table_name) FILTER(WHERE t.direct_user) AS direct_user_table_names,
       jsonb_agg(t.table_name ORDER BY t.table_name)
           FILTER(WHERE t.indirect_link AND NOT t.direct_user) AS indirect_link_table_names
  FROM tables t LEFT JOIN foreign_keys fk ON fk.table_name=t.table_name;

-- Assess, don't modify, the existing cleanup entrypoints.
SELECT n.nspname AS schema_name, p.proname AS routine_name
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname IN ('public','private')
   AND (p.proname LIKE '%exam_prep%cleanup%'
        OR p.proname LIKE '%exam_prep%reset%'
        OR p.proname LIKE '%exam_prep%mass_core_rollout_gate%')
 ORDER BY n.nspname, p.proname;

-- Current issue-450 versioned read-only gate is an observation, NOT approval:
SELECT private.exam_prep_p3_01_mass_core_rollout_gate_v1(
  'math_as_p1_p5_beta_2026_09_01'
) AS old_governance_gate_observation;

-- A separate future allowlist-based dry-run will verify the precise delete scope.
-- NEVER execute DROP/DELETE/TRUNCATE or blindly clear localStorage here.
