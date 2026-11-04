-- Issue #450 / D09-02: immutable ORIGINAL diagnostic T0 capture for NEW
-- genuine Stage0 completion transitions. DRAFT/NO_GO, additive only.
-- Existing completed beta learners are NOT forcibly backfilled or re-anchored.
-- No rewrite of the canonical stable shared weekly plan generator.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_diagnostic_t0_snapshots_v1 (
 user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
 program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id) ON DELETE RESTRICT,
 component_code text NOT NULL CHECK(component_code IN ('P1','P5')),
 diagnostic_completed_at timestamptz NOT NULL,
 captured_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 capture_rule_version text NOT NULL,
 capture_source text NOT NULL DEFAULT 'first_verified_stage0_transition'
   CHECK(capture_source='first_verified_stage0_transition'),
 PRIMARY KEY(user_id,program_version_id,component_code)
);
ALTER TABLE private.exam_prep_diagnostic_t0_snapshots_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_diagnostic_t0_snapshots_v1
 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.exam_prep_diagnostic_t0_snapshots_v1 TO service_role;
-- The definer placement writer owns INSERT. No public or service API user
-- may later change an academic origin. Admin account deletion can still
-- cascade-clean these rows; an UPDATE, however, must never rewrite T0.
CREATE OR REPLACE FUNCTION private.reject_exam_prep_diagnostic_t0_update_v1()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $immutable$
BEGIN
 RAISE EXCEPTION 'exam_prep_diagnostic_t0_immutable' USING ERRCODE='42501';
END;
$immutable$;
REVOKE ALL ON FUNCTION private.reject_exam_prep_diagnostic_t0_update_v1()
 FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS exam_prep_diagnostic_t0_immutable_update_v1
 ON private.exam_prep_diagnostic_t0_snapshots_v1;
CREATE TRIGGER exam_prep_diagnostic_t0_immutable_update_v1
 BEFORE UPDATE ON private.exam_prep_diagnostic_t0_snapshots_v1
 FOR EACH ROW EXECUTE FUNCTION private.reject_exam_prep_diagnostic_t0_update_v1();

CREATE OR REPLACE FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $capture$
DECLARE
 v_completed timestamptz;
BEGIN
 IF NEW.stage0_complete IS DISTINCT FROM true
   OR NEW.component_code NOT IN ('P1','P5') THEN RETURN NEW; END IF;

 -- The academic placement has just completed for the first time. The LAST
 -- finalized diagnostic at THAT instant ends multi-step Stage0 if present.
 -- Never derive a new T0 from a later retest, paper, review or profile edit.
 SELECT max(s.finalized_at) INTO v_completed
 FROM private.exam_prep_sessions s
 WHERE s.user_id=NEW.user_id
   AND s.program_version_id=NEW.program_version_id
   AND s.component_code=NEW.component_code
   AND s.session_type='diagnostic'
   AND s.status='finalized'
   AND s.finalized_at IS NOT NULL;
 IF v_completed IS NULL THEN
   -- Some legacy/synthetic placements may be manually marked complete but
   -- lack finalized diagnostic evidence. Never forge a completion epoch.
   RETURN NEW;
 END IF;
 INSERT INTO private.exam_prep_diagnostic_t0_snapshots_v1(
  user_id,program_version_id,component_code,diagnostic_completed_at,capture_rule_version
 ) VALUES(
  NEW.user_id,NEW.program_version_id,NEW.component_code,v_completed,NEW.rule_version
 )
 ON CONFLICT(user_id,program_version_id,component_code) DO NOTHING;
 RETURN NEW;
END;
$capture$;
REVOKE ALL ON FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1()
 FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS exam_prep_diagnostic_t0_stage0_insert_v1
 ON private.exam_prep_component_placements;
CREATE TRIGGER exam_prep_diagnostic_t0_stage0_insert_v1
 AFTER INSERT ON private.exam_prep_component_placements
 FOR EACH ROW WHEN(NEW.stage0_complete IS TRUE)
 EXECUTE FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1();
DROP TRIGGER IF EXISTS exam_prep_diagnostic_t0_stage0_update_v1
 ON private.exam_prep_component_placements;
CREATE TRIGGER exam_prep_diagnostic_t0_stage0_update_v1
 AFTER UPDATE OF stage0_complete ON private.exam_prep_component_placements
 FOR EACH ROW WHEN(NEW.stage0_complete IS TRUE AND OLD.stage0_complete IS DISTINCT FROM TRUE)
 EXECUTE FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1();

-- Read-only D09 v1 projection now PREFERS the immutable first Stage0 T0
-- when recorded, while legacy students retain clearly labeled derived date.

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
 v_original private.exam_prep_diagnostic_t0_snapshots_v1%ROWTYPE;
 v_anchor_frozen boolean;
 v_anchor_source text;
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
  v_original:=null;
  v_anchor_frozen:=false;
  v_anchor_source:='current_horizon_latest_finalized_diagnostic';
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
   -- The first verified Stage0 transition is frozen server-side once.
   -- Historical completed beta profiles without a frozen row fall back to
   -- the old derived horizon, explicitly marked NOT immutable.
   SELECT * INTO v_original
   FROM private.exam_prep_diagnostic_t0_snapshots_v1 t
   WHERE t.user_id=v_uid AND t.program_version_id=v_profile.program_version_id
     AND t.component_code=v_component;
   IF v_original.user_id IS NOT NULL THEN
     v_anchor:=v_original.diagnostic_completed_at;
     v_anchor_frozen:=true;
     v_anchor_source:='first_verified_stage0_transition';
   ELSE
     SELECT max(s.finalized_at) INTO v_anchor
     FROM private.exam_prep_sessions s
     WHERE s.user_id=v_uid AND s.program_version_id=v_profile.program_version_id
       AND s.component_code=v_component AND s.session_type='diagnostic'
       AND s.status='finalized' AND s.finalized_at IS NOT NULL;
   END IF;
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
   'anchor_source',v_anchor_source,
   'anchor_immutable',v_anchor_frozen,
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
 'Owner-only D09 P1/P5 7-day projection: immutable first verified Stage0 transitions for new learners; legacy completions without a snapshot remain transparently derived. Does not mutate the shared weekly planner.';

COMMIT;
