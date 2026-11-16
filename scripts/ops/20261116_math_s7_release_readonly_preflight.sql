-- iClub Mathematics P1/P5 S7 -- SELECT-ONLY release snapshot, 2026-11-16.
-- May be run on EXISTING iClub Supabase by an authorized operator.
-- No DDL, DML, feature flag updates, session creation, auth impersonation,
-- learner row exports, hidden question keys or destructive rollback.
-- Report is a decision INPUT, never automatic permission to deploy or go mass.
WITH flags AS (
 SELECT rollout_state,core_enabled,kill_switch,qa_open_all_core,qa_open_all_weekly
 FROM private.exam_prep_feature_config WHERE id=1
), hybrid AS (
 SELECT paper_enabled,stage_gates_enabled
 FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton
), installed AS (
 SELECT version FROM supabase_migrations.schema_migrations WHERE version IN (
 '20261109110109',  -- D03 written self-scoring deny
 '20261109111900',  -- S2
 '20261109132000',  -- S3 reports
 '20261109132100',  -- S3 voluntary choices
 '20261109154000',  -- S4 no-marks Paper
 '20261109155000',  -- Stage3-6 optional operational reader
 '20261115100103',  -- existing Mathematics subject-selection guard
 '20261116164000'   -- proposed future Stage6 Final Calibration bridge (NOT released)
 )
), guards AS (
 SELECT
  position('iclub_math_subject_release_guard_v1' IN
    pg_get_functiondef('private.exam_prep_require_core_access_v1()'::regprocedure))>0
    AS private_math_selection_guard,
  position('iclub_math_subject_release_guard_v1' IN
    pg_get_functiondef('public.get_exam_prep_capabilities_v1()'::regprocedure))>0
    AS public_math_selection_guard
), owners AS (
 SELECT
   (SELECT count(*)::int FROM private.exam_prep_exam_profiles) AS profiles_total,
   (SELECT count(*)::int FROM private.exam_prep_exam_profiles p
    WHERE EXISTS (SELECT 1 FROM public.user_subjects us WHERE us.user_id=p.user_id
      AND us.subject_id=5)) AS profiles_math_selected,
   (SELECT count(*)::int FROM public.users) AS registered_users,
   (SELECT count(*)::int FROM public.user_subjects WHERE subject_id=5) AS selected_math_rows
)
SELECT
  (SELECT to_jsonb(flags) FROM flags) AS current_feature_flags,
  (SELECT to_jsonb(hybrid) FROM hybrid) AS current_hybrid_flags,
  (SELECT to_jsonb(guards) FROM guards) AS installed_core_auth_source,
  (SELECT to_jsonb(owners) FROM owners) AS only_aggregate_owner_counts,
  (SELECT jsonb_object_agg(version,true) FROM installed) AS applied_migration_receipts,
  (SELECT count(*)=7 FROM installed WHERE version <> '20261116164000')
    AS expected_seven_base_migrations_present,
  (SELECT count(*)=0 FROM installed WHERE version='20261116164000')
    AS stage6_new_bridge_not_deployed,
  (SELECT profiles_total=profiles_math_selected FROM owners) AS existing_profile_subject_continuity,
  -- A live mass transition must NOT occur solely because these fields appear.
  (SELECT qa_open_all_core=false AND qa_open_all_weekly=false FROM flags)
    AS technical_qa_overrides_closed,
  (SELECT rollout_state='mass' FROM flags) AS mass_already_enabled;
