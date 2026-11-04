-- P3-01: apply the learner's previously chosen Math weekly time to the next
-- existing P1/P5 weekly plan. This is an AVAILABLE-TIME allocation, NEVER a
-- claim that a question will take exactly this long or that mastery is earned.
-- This file is a DRAFT candidate: no production migration or release without GO.
-- The released stable generator, recovery/goal authorization and sessions stay intact.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_weekly_budget_snapshots_v1 (
  user_id uuid NOT NULL REFERENCES auth.users(id),
  program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id),
  active_week_no smallint NOT NULL CHECK(active_week_no >= 1),
  profile_revision integer NOT NULL CHECK(profile_revision >= 1),
  selected_math_hours numeric NOT NULL CHECK(selected_math_hours >= 0 AND selected_math_hours <= 168),
  available_math_minutes integer NOT NULL CHECK(available_math_minutes BETWEEN 0 AND 10080),
  p1_available_minutes integer NOT NULL CHECK(p1_available_minutes BETWEEN 0 AND 10080),
  p5_available_minutes integer NOT NULL CHECK(p5_available_minutes BETWEEN 0 AND 10080),
  p1_remaining_effort_weight numeric NOT NULL CHECK(p1_remaining_effort_weight >= 0),
  p5_remaining_effort_weight numeric NOT NULL CHECK(p5_remaining_effort_weight >= 0),
  captured_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id,program_version_id,active_week_no),
  CHECK(p1_available_minutes+p5_available_minutes=available_math_minutes)
);
ALTER TABLE private.exam_prep_weekly_budget_snapshots_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_weekly_budget_snapshots_v1
  FROM PUBLIC,anon,authenticated;
GRANT ALL ON private.exam_prep_weekly_budget_snapshots_v1 TO service_role;

-- The only plan creator remains ensure_exam_prep_balanced_weekly_plan_safe_v1.
-- This RPC runs AFTER that authorized action, binds to its exact active plan,
-- and freezes the shared available-time allocation for the first opening of
-- this effective week. New profile choices are consumed at the next week.
CREATE OR REPLACE FUNCTION public.ensure_my_exam_prep_weekly_budget_safe_v1(
 p_component_code text,
 p_plan_id uuid
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $weekly_budget$
DECLARE
 v_uid uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_week smallint;
 v_plan private.exam_prep_weekly_plans%ROWTYPE;
 v_snap private.exam_prep_weekly_budget_snapshots_v1%ROWTYPE;
 v_p1 jsonb;
 v_p5 jsonb;
 v_h1 numeric;
 v_h5 numeric;
 v_minutes integer;
 v_p1_minutes integer;
 v_items integer;
 v_component_minutes integer;
 v_priorities jsonb;
 v_keep boolean;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_component_code NOT IN ('P1','P5') OR p_plan_id IS NULL THEN
   RAISE EXCEPTION 'exam_prep_weekly_budget_bad_plan_identity' USING ERRCODE='22023';
 END IF;
 v_week:=private.exam_prep_effective_active_week_v1(v_uid);
 IF v_week IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;

 -- Serializes only a user's two-component budget; NEVER requests a new plan.
 PERFORM pg_advisory_xact_lock(
   hashtextextended('ep-shared-weekly-budget:'||v_uid::text||':'||v_week::text,0)
 );
 SELECT * INTO v_profile FROM private.exam_prep_exam_profiles
 WHERE user_id=v_uid FOR SHARE;
 IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL
    OR v_profile.mathematics_hours_budget IS NULL
    OR v_profile.total_student_hours_available IS NULL
    OR v_profile.mathematics_hours_budget>v_profile.total_student_hours_available
 THEN RAISE EXCEPTION 'exam_prep_weekly_budget_profile_required' USING ERRCODE='42501'; END IF;
 SELECT * INTO v_plan FROM private.exam_prep_weekly_plans
 WHERE id=p_plan_id AND user_id=v_uid
   AND program_version_id=v_profile.program_version_id
   AND component_code=p_component_code
   AND active_week_no=v_week AND status='active'
 FOR SHARE;
 IF v_plan.id IS NULL THEN
   RAISE EXCEPTION 'exam_prep_weekly_budget_plan_not_current_or_not_owned'
     USING ERRCODE='42501';
 END IF;
 SELECT * INTO v_snap
 FROM private.exam_prep_weekly_budget_snapshots_v1
 WHERE user_id=v_uid AND program_version_id=v_profile.program_version_id
  AND active_week_no=v_week;
 IF v_snap.user_id IS NULL THEN
   v_p1:=private.exam_prep_simple_guided_effort_internal_v1(
     v_uid,v_profile.program_version_id,'P1');
   v_p5:=private.exam_prep_simple_guided_effort_internal_v1(
     v_uid,v_profile.program_version_id,'P5');
   IF (v_p1->>'skill_count')::int<>45 OR (v_p5->>'skill_count')::int<>36
      OR (v_p1->>'source_coverage_count')::int<>45
      OR (v_p5->>'source_coverage_count')::int<>36 THEN
     RAISE EXCEPTION 'exam_prep_weekly_budget_academic_source_incomplete';
   END IF;
   v_h1:=(v_p1->>'estimated_remaining_hours')::numeric;
   v_h5:=(v_p5->>'estimated_remaining_hours')::numeric;
   IF v_h1 IS NULL OR v_h5 IS NULL OR v_h1<0 OR v_h5<0
      OR v_h1+v_h5<=0 THEN
     RAISE EXCEPTION 'exam_prep_weekly_budget_estimate_unavailable';
   END IF;
   v_minutes:=floor(v_profile.mathematics_hours_budget*60)::integer;
   v_p1_minutes:=floor(v_minutes*v_h1/(v_h1+v_h5))::integer;
   INSERT INTO private.exam_prep_weekly_budget_snapshots_v1(
     user_id,program_version_id,active_week_no,profile_revision,
     selected_math_hours,available_math_minutes,
     p1_available_minutes,p5_available_minutes,
     p1_remaining_effort_weight,p5_remaining_effort_weight
   ) VALUES (
     v_uid,v_profile.program_version_id,v_week,v_profile.profile_revision,
     v_profile.mathematics_hours_budget,v_minutes,
     v_p1_minutes,v_minutes-v_p1_minutes,v_h1,v_h5
   ) ON CONFLICT(user_id,program_version_id,active_week_no) DO NOTHING;
   SELECT * INTO v_snap FROM private.exam_prep_weekly_budget_snapshots_v1
   WHERE user_id=v_uid AND program_version_id=v_profile.program_version_id
     AND active_week_no=v_week;
 END IF;
 IF v_snap.user_id IS NULL THEN
   RAISE EXCEPTION 'exam_prep_weekly_budget_snapshot_missing';
 END IF;

 v_component_minutes:=CASE WHEN p_component_code='P1'
   THEN v_snap.p1_available_minutes ELSE v_snap.p5_available_minutes END;
 SELECT count(*)::integer INTO v_items
 FROM private.exam_prep_weekly_plan_items
 WHERE plan_id=v_plan.id;
 IF v_items>3 THEN
   RAISE EXCEPTION 'exam_prep_weekly_budget_plan_priority_count_invalid';
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
    'priority_order',i.priority_order,
    'item_type',i.item_type,
    'status',i.status,
    'available_study_minutes',
      CASE WHEN v_items=0 THEN 0
        ELSE (v_component_minutes/v_items)
          + CASE WHEN row_number.rank_no<=mod(v_component_minutes,v_items) THEN 1 ELSE 0 END
        END
 ) ORDER BY i.priority_order),'[]'::jsonb)
 INTO v_priorities
 FROM private.exam_prep_weekly_plan_items i
 JOIN (
    SELECT priority_order,row_number() OVER (ORDER BY priority_order)::integer rank_no
    FROM private.exam_prep_weekly_plan_items WHERE plan_id=v_plan.id
 ) row_number ON row_number.priority_order=i.priority_order
 WHERE i.plan_id=v_plan.id;

 SELECT EXISTS (
   SELECT 1 FROM private.exam_prep_weekly_time_decisions_v1 d
   WHERE d.user_id=v_uid AND d.program_version_id=v_snap.program_version_id
     AND d.decision_kind='keep'
     AND d.profile_revision=v_snap.profile_revision
     AND d.chosen_math_hours=v_snap.selected_math_hours
     AND d.created_at<=v_snap.captured_at
 ) INTO v_keep;
 RETURN jsonb_build_object(
   'contract_version','exam_prep_shared_weekly_available_time_v1',
   'plan_id',v_plan.id,
   'component_code',p_component_code,
   'active_week_no',v_week,
   'budget_status','captured_for_week',
   'available_math_minutes',v_snap.available_math_minutes,
   'p1_reserved_minutes',v_snap.p1_available_minutes,
   'p5_reserved_minutes',v_snap.p5_available_minutes,
   'component_available_minutes',v_component_minutes,
   'priority_slots',v_priorities,
   'priority_count',v_items,
   'keep_choice_recorded_before_snapshot',v_keep,
   'profile_revision_at_capture',v_snap.profile_revision,
   'profile_changed_after_capture',v_snap.profile_revision<>v_profile.profile_revision,
   'time_split_basis','iclub_objective_evidence_and_source_guided_effort_weights',
   'remaining_effort_is_approximate_not_cambridge_private_hours',true,
   'priority_minutes_are_available_time_not_task_duration',true,
   'current_week_snapshot_not_rewritten',true,
   'next_week_uses_latest_confirmed_hours',true,
   'learning_access_capped',false,
   'written_marks_awarded',false,
   'academic_results_mutated',false
 );
END;
$weekly_budget$;
REVOKE ALL ON FUNCTION public.ensure_my_exam_prep_weekly_budget_safe_v1(text,uuid)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.ensure_my_exam_prep_weekly_budget_safe_v1(text,uuid)
 TO authenticated,service_role;
COMMENT ON FUNCTION public.ensure_my_exam_prep_weekly_budget_safe_v1(text,uuid) IS
'After the single existing weekly plan is created, freeze owner-only P1/P5 shared time availability for that week from the chosen Math hours and current evidence. Never a duration claim, grade, task gate or second planner.';
COMMIT;
