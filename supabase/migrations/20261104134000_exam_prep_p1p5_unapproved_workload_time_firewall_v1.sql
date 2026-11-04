-- Issue #450 / D10: do not offer numerical student study-time recommendations
-- from historical Cambridge teacher-contact hours and unreviewed 0.6/0.8 proxies.
-- Draft-only additive override after the existing P2-14/P2-18 functions.
-- No learner/profile/attempt/question/data writes. Core task plan stays available.
--
-- Academic 81-skill independent-study duration norms are not approved.
-- An actual, independently reviewed interval calculator needs a NEW
-- separately tested/versioned contract; this RPC cannot silently switch to
-- the older unreviewed heuristic merely because a status flag changes.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER SET search_path TO ''
AS $safe$
DECLARE
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%ROWTYPE;
  v_core jsonb;
BEGIN
  v_uid := private.exam_prep_require_core_access_v1();
  SELECT * INTO v_profile
    FROM private.exam_prep_exam_profiles
    WHERE user_id = v_uid;
  IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL THEN
    RAISE EXCEPTION 'exam_prep_profile_required';
  END IF;
  v_core := public.get_exam_prep_simple_learning_timeline_safe_v1();

  -- Do not call private.exam_prep_simple_guided_effort_internal_v1 here.
  -- The 2020 Cambridge Scheme of Work is historical guided teaching time,
  -- not approved independent study duration by skill or phase.
  RETURN v_core || jsonb_build_object(
    'contract_version','exam_prep_one_line_progress_timeline_v2_academic_review_pending',
    'P1',v_core->'P1' || jsonb_build_object(
      'estimated_remaining_study_hours',NULL::numeric,
      'estimated_remaining_study_hours_low',NULL::numeric,
      'estimated_remaining_study_hours_high',NULL::numeric,
      'estimated_component_weekly_hours',NULL::numeric
    ),
    'P5',v_core->'P5' || jsonb_build_object(
      'estimated_remaining_study_hours',NULL::numeric,
      'estimated_remaining_study_hours_low',NULL::numeric,
      'estimated_remaining_study_hours_high',NULL::numeric,
      'estimated_component_weekly_hours',NULL::numeric
    ),
    'estimated_remaining_math_hours',NULL::numeric,
    'estimated_joint_math_hours_per_week',NULL::numeric,
    'estimated_weekly_hours_difference_from_chosen',NULL::numeric,
    'existing_chosen_math_hours_per_week',v_profile.mathematics_hours_budget,
    'student_total_hours_per_week',v_profile.total_student_hours_available,
    'student_budget_profile_revision',v_profile.profile_revision,
    'academic_workload_status','awaiting_independent_81_skill_time_review',
    'numeric_recommendation_enabled',false,
    'recommendation_accept_enabled',false,
    'source_guided_hours_are_not_private_study_hours',true,
    'recommended_schedule_applied_automatically',false,
    'learning_evidence_mutated',false,
    'no_study_cap',true
  );
END;
$safe$;

REVOKE ALL ON FUNCTION public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
  FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
  TO authenticated,service_role;
COMMENT ON FUNCTION public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
  IS 'Academic review pending: owner-only objective P1/P5 progress and own exam dates; ALL unapproved personal workload and recommended hours NULL. No automatic changes.';

-- Both pre-existing keep_my... and accept_my... calls recompute the target
-- through this public RPC. NULL targets fail-closed and cannot write a
-- decision/profile revision; neither writer is dropped or silently renamed.
COMMIT;
