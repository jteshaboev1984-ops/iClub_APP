-- D09-01: read-only per-component 7-day periods from finalized diagnostic.
-- DRAFT / NO_GO. Does not replace the legacy shared planner week clock or
-- recompute study evidence, stages, grades, corrections or session history.
-- This is a projection of existing completion evidence, not an immutable T0 ledger.
BEGIN;

CREATE OR REPLACE FUNCTION private.exam_prep_full_periods_from_t0_v1(
 p_diagnostic_t0 timestamptz,p_asof timestamptz
) RETURNS integer
LANGUAGE sql IMMUTABLE STRICT SET search_path TO ''
AS $period$
 SELECT CASE WHEN p_asof<p_diagnostic_t0 THEN NULL::integer
             ELSE floor(extract(epoch FROM (p_asof-p_diagnostic_t0))/604800)::integer
        END;
$period$;
REVOKE ALL ON FUNCTION private.exam_prep_full_periods_from_t0_v1(timestamptz,timestamptz)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_full_periods_from_t0_v1(timestamptz,timestamptz)
 TO service_role;

CREATE OR REPLACE FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $periods$
DECLARE
 v_uid uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_now timestamptz;
 v_component text;
 v_finished boolean;
 v_anchor timestamptz;
 v_periods integer;
 v_current_start timestamptz;
 v_next_end timestamptz;
 v_out jsonb:='{}'::jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 SELECT * INTO v_profile
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL THEN
  RAISE EXCEPTION 'exam_prep_profile_required' USING ERRCODE='42501';
 END IF;
 v_now:=private.exam_prep_effective_academic_now_v1(v_uid);

 FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
  v_finished:=false;
  v_anchor:=null;
  v_periods:=null;
  v_current_start:=null;
  v_next_end:=null;

  SELECT coalesce(p.stage0_complete,false) INTO v_finished
  FROM private.exam_prep_component_placements p
  WHERE p.user_id=v_uid AND p.program_version_id=v_profile.program_version_id
    AND p.component_code=v_component
  ORDER BY p.derived_at DESC LIMIT 1;
  v_finished:=coalesce(v_finished,false);
  IF v_finished THEN
   -- Same completed-diagnostic evidence used by the current personal horizon.
   -- Latest completion is intentionally labeled DERIVED: a repeated later
   -- diagnostic could move this anchor. Immutable original T0 remains OPEN.
   SELECT max(s.finalized_at) INTO v_anchor
   FROM private.exam_prep_sessions s
   WHERE s.user_id=v_uid AND s.program_version_id=v_profile.program_version_id
     AND s.component_code=v_component AND s.session_type='diagnostic'
     AND s.status='finalized' AND s.finalized_at IS NOT NULL;
  END IF;

  IF v_anchor IS NOT NULL AND v_anchor<=v_now THEN
   v_periods:=private.exam_prep_full_periods_from_t0_v1(v_anchor,v_now);
   v_current_start:=v_anchor+v_periods*interval '7 days';
   v_next_end:=v_current_start+interval '7 days';
  END IF;

  v_out:=v_out||jsonb_build_object(v_component,jsonb_build_object(
   'component_code',v_component,
   'status',CASE WHEN NOT v_finished THEN 'diagnostic_pending'
                 WHEN v_anchor IS NULL THEN 'diagnostic_completion_unknown'
                 WHEN v_anchor>v_now THEN 'diagnostic_in_future'
                 ELSE 'diagnostic_period_ready' END,
   'diagnostic_completed_at',v_anchor,
   'completed_7day_periods',v_periods,
   'current_period_no',CASE WHEN v_periods IS NULL THEN NULL ELSE v_periods+1 END,
   'current_period_started_at',v_current_start,
   'next_period_ends_at',v_next_end,
   'anchor_source','current_horizon_latest_finalized_diagnostic',
   'anchor_immutable',false,
   'calendar_promotes_stage',false
  ));
 END LOOP;

 RETURN jsonb_build_object(
  'contract_version','diagnostic_period_readonly_v1',
  'period_duration_days',7,
  'P1',v_out->'P1','P5',v_out->'P5',
  'account_planner_week_unchanged',true,
  'no_schedule_change',true,
  'study_minutes_recorded',false
 );
END;
$periods$;
REVOKE ALL ON FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1()
 TO authenticated,service_role;
COMMENT ON FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1() IS
 'Owner-only D09 P1/P5 diagnostic-derived 7-day period projection. Does not mutate the shared profile-based weekly planner. Immutable original T0 requires separate approval.';

COMMIT;
