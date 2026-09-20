-- DRAFT PROPOSAL ONLY. Not a migration. NEVER execute on live Supabase without
-- separate authorization. Install only AFTER the stable-plan and atomic legacy
-- dispatch proposals; server enrollment defaults to zero learners.
-- Read-only factual previous-week commitment, NOT exam-grade/readiness prediction.
-- No writes to academic evidence, plans, history, users, or legacy tables.
BEGIN;
DO $guard$
BEGIN
  IF to_regprocedure('private.exam_prep_weekly_flow_enrolled_v1(uuid)') IS NULL
     OR to_regclass('private.exam_prep_weekly_goal_snapshots') IS NULL
     OR to_regprocedure('private.exam_prep_effective_active_week_v1(uuid)') IS NULL THEN
    RAISE EXCEPTION 'prior-week adherence: prerequisite migration/atomic enrollment missing';
  END IF;
END;
$guard$;

CREATE OR REPLACE FUNCTION public.get_exam_prep_previous_week_adherence_safe_v1(p_component_code text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $body$
DECLARE
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_week smallint;
  v_prior smallint;
  v_end timestamptz;
  v_plan_id uuid;
  v_plan_count int;
  v_goal_count int;
  v_due int;
  v_on_time int;
  v_eventually int;
  v_unmatched int;
  v_status text;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF p_component_code NOT IN ('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
  END IF;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL THEN
    RAISE EXCEPTION 'exam_prep_profile_required';
  END IF;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  IF v_week IS NULL OR v_week<=1 THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'status','not_due','can_alert',false);
  END IF;
  v_prior:=(v_week-1)::smallint;
  -- The authoritative weekly clock is the profile creation timestamp, NOT
  -- browser dates, target-exam dates or an arbitrary midnight in a time zone.
  v_end:=v_profile.created_at+(v_prior::integer * interval '7 days');
  IF clock_timestamp()<v_end THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'status','not_due','can_alert',false);
  END IF;

  SELECT count(*)::int,min(p.id) INTO v_plan_count,v_plan_id
  FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=v_uid AND p.program_version_id=v_profile.program_version_id
    AND p.component_code=p_component_code AND p.active_week_no=v_prior
    AND p.generated_at<v_end;
  -- Multiple versions are historically possible under legacy v3. Their frozen
  -- priorities may have been displaced: do NOT blame the learner or guess.
  IF v_plan_count<>1 THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'active_week_no',v_prior,
      'status',CASE WHEN v_plan_count=0 THEN 'no_verified_plan' ELSE 'ambiguous_plan' END,
      'can_alert',false);
  END IF;

  SELECT count(*)::int INTO v_goal_count
  FROM private.exam_prep_weekly_goal_snapshots g
  WHERE g.user_id=v_uid AND g.program_version_id=v_profile.program_version_id
    AND g.component_code=p_component_code AND g.active_week_no=v_prior;
  IF v_goal_count NOT BETWEEN 1 AND 3 OR EXISTS (
      SELECT 1 FROM private.exam_prep_weekly_goal_snapshots g
      LEFT JOIN private.exam_prep_weekly_plan_items i
        ON i.plan_id=g.source_plan_id AND i.priority_order=g.priority_order
      WHERE g.user_id=v_uid AND g.program_version_id=v_profile.program_version_id
        AND g.component_code=p_component_code AND g.active_week_no=v_prior
        AND (g.source_plan_id<>v_plan_id OR g.created_at>=v_end
          OR i.plan_id IS NULL OR i.item_type<>g.item_type
          OR i.skill_code IS DISTINCT FROM g.skill_code
          OR i.correction_case_id IS DISTINCT FROM g.correction_case_id
          OR i.action_code<>g.action_code
          OR g.item_type NOT IN ('learning','mixed_transfer','correction','retest')
          OR (g.item_type='mixed_transfer' AND
            i.action_payload->>'assessment_id' IS DISTINCT FROM g.assessment_id::text))
    ) THEN
    RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
      'component_code',p_component_code,'active_week_no',v_prior,
      'status','unverifiable_goals','can_alert',false);
  END IF;

  -- Link a completed commitment to exactly the frozen plan + priority and
  -- a genuinely finalized academically credited session. Corrections require
  -- the real remediation_completed action, not just another attempt.
  WITH qualified AS (
    SELECT g.id,g.item_type,
      (i.due_at IS NULL OR i.due_at<v_end) AS was_due,
      proof.completed_at
    FROM private.exam_prep_weekly_goal_snapshots g
    JOIN private.exam_prep_weekly_plan_items i
      ON i.plan_id=g.source_plan_id AND i.priority_order=g.priority_order
    LEFT JOIN LATERAL (
      SELECT min(CASE WHEN g.item_type='correction' THEN ca.created_at
                      ELSE s.finalized_at END) AS completed_at
      FROM private.exam_prep_session_authorizations a
      JOIN private.exam_prep_sessions s ON s.authorization_id=a.id
        AND s.user_id=v_uid AND s.component_code=p_component_code
        AND s.status='finalized' AND s.finalized_at IS NOT NULL
      LEFT JOIN private.exam_prep_correction_actions ca
        ON ca.session_id=s.id AND ca.user_id=v_uid
        AND ca.component_code=p_component_code
        AND ca.correction_case_id=g.correction_case_id
        AND ca.action_type='remediation_completed'
      WHERE a.user_id=v_uid AND a.component_code=p_component_code
        AND a.plan_id=g.source_plan_id
        AND a.plan_priority_order=g.priority_order AND a.academic_credit IS TRUE
        AND ((g.item_type='correction' AND s.session_type='learning' AND ca.id IS NOT NULL)
          OR (g.item_type='learning' AND s.session_type='learning')
          OR (g.item_type='mixed_transfer' AND s.session_type='mixed')
          OR (g.item_type='retest' AND s.session_type='retest'))
    ) proof ON true
    WHERE g.user_id=v_uid AND g.program_version_id=v_profile.program_version_id
      AND g.component_code=p_component_code AND g.active_week_no=v_prior
  )
  SELECT count(*) FILTER (WHERE was_due)::int,
         count(*) FILTER (WHERE was_due AND completed_at<v_end)::int,
         count(*) FILTER (WHERE was_due AND completed_at IS NOT NULL)::int,
         count(*) FILTER (WHERE NOT was_due)::int
  INTO v_due,v_on_time,v_eventually,v_unmatched FROM qualified;
  IF v_due=0 THEN v_status:='no_due_goals';
  ELSIF v_on_time=v_due THEN v_status:='completed_on_time';
  ELSIF v_eventually=v_due THEN v_status:='caught_up';
  ELSE v_status:='missed'; END IF;
  RETURN jsonb_build_object('contract_version','previous_week_adherence_v1',
    'component_code',p_component_code,'active_week_no',v_prior,
    'status',v_status,'can_alert',v_status='missed',
    'scheduled_goals',v_due,'completed_by_deadline',v_on_time,
    'completed_now',v_eventually,'deferred_goals',v_unmatched,
    'week_ended_at',v_end,'data_basis','frozen_goals_and_credited_sessions',
    'does_not_change_goals_or_grades',true);
END;
$body$;
REVOKE ALL ON FUNCTION public.get_exam_prep_previous_week_adherence_safe_v1(text)
  FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_previous_week_adherence_safe_v1(text)
  TO authenticated,service_role;
COMMIT;
