-- Issue #450 P4-04: operational Final Calibration is NOT a Cambridge grade.
-- DRAFT only. Adds a separate deterministic Core Stage5->Stage6 operational
-- evidence gate, without relaxing scored-paper App Readiness or Mentor Care.
BEGIN;

CREATE OR REPLACE FUNCTION private.exam_prep_stage5_operational_completion_v1(
  p_user_id uuid,p_program_version_id bigint,p_component_code text
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO ''
AS $fn$
DECLARE
  v_rule private.exam_prep_stage5_readiness_rules%rowtype;
  v_stage4 jsonb;
  v_raw jsonb;
  v_family_count int:=0;
  v_denom int:=0;
  v_below int:=0;
  v_open int:=0;
  v_can_access boolean:=false;
  v_reason text:='rule_missing';
BEGIN
  IF p_component_code NOT IN ('P1','P5') THEN
    RAISE EXCEPTION 'exam_prep_bad_component';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM private.exam_prep_program_versions p
    WHERE p.id=p_program_version_id AND p.status='active'
  ) THEN
    RAISE EXCEPTION 'exam_prep_stage5_operational_program_inactive';
  END IF;
  SELECT * INTO v_rule FROM private.exam_prep_stage5_readiness_rules
  WHERE status='active' ORDER BY created_at DESC LIMIT 1;
  IF v_rule.rule_version IS NULL THEN
    RETURN jsonb_build_object(
      'operational_calibration_access',false,'reason_code','rule_missing',
      'component_code',p_component_code,'exam_readiness_claim',false);
  END IF;
  -- Stage4 includes objective/coverage, two compatible strict papers,
  -- governed timed-section majority, trend and corrective plan conditions.
  v_stage4:=private.exam_prep_stage4_exit_status_v1(
    p_user_id,p_program_version_id,p_component_code);
  v_raw:=private.exam_prep_stage4_raw_evidence_v1(
    p_user_id,p_program_version_id,p_component_code);
  v_family_count:=coalesce((v_raw->>'max_compatible_family_attempt_count')::int,0);
  v_denom:=coalesce((v_raw->>'canonical_skill_count')::int,0);
  v_below:=coalesce((v_raw->>'below_l3_count')::int,0);
  SELECT count(*)::int INTO v_open
  FROM private.exam_prep_correction_cases c
  WHERE c.user_id=p_user_id AND c.component_code=p_component_code
    AND c.status IN ('open','remediating','retest_due','reopened');

  IF NOT coalesce((v_stage4->>'ready')::boolean,false) THEN
    v_reason:='stage4_exit_incomplete';
  ELSIF v_family_count<v_rule.min_comparable_full_attempts THEN
    v_reason:='three_execution_papers_incomplete';
  ELSIF v_denom=0 OR (v_rule.require_all_skills_l3 AND v_below<>0) THEN
    v_reason:='objective_skill_stability_incomplete';
  ELSIF v_rule.require_all_corrections_closed AND v_open<>0 THEN
    v_reason:='corrective_cycles_open';
  ELSE
    v_reason:='operational_final_calibration_available';
    v_can_access:=true;
  END IF;
  RETURN jsonb_build_object(
    'component_code',p_component_code,
    'operational_calibration_access',v_can_access,
    'reason_code',v_reason,
    'compatible_execution_papers',v_family_count,
    'required_execution_papers',v_rule.min_comparable_full_attempts,
    'canonical_skill_count',v_denom,
    'below_l3_count',v_below,
    'open_correction_count',v_open,
    'stage4_execution_gate_ready',coalesce((v_stage4->>'ready')::boolean,false),
    'exam_readiness_claim',false,
    'written_marks_awarded_by_core',false,
    'mentor_required',false
  );
END;
$fn$;

REVOKE ALL ON FUNCTION private.exam_prep_stage5_operational_completion_v1(uuid,bigint,text)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage5_operational_completion_v1(uuid,bigint,text)
TO service_role;

-- Surgical rewrite of the EXISTING Stage0–6 projection trigger: only the
-- Stage5->6 gate changes from scored App Readiness to independent Core
-- operational proof. Stage3->4/Stage4->5 and grade-readiness remain untouched.
DO $patch$
DECLARE
  v_def text;
  v_oid oid:='private.exam_prep_apply_stage0_gate_v1()'::regprocedure;
  v_old text:='v_stage5:=private.exam_prep_stage5_readiness_status_v1(new.user_id,new.program_version_id,new.component_code);';
  v_new text:='v_stage5:=private.exam_prep_stage5_operational_completion_v1(new.user_id,new.program_version_id,new.component_code);';
  v_old_cond text:='if coalesce((v_stage5->>''ready'')::boolean,false) then v_target:=6; end if;';
  v_new_cond text:='if coalesce((v_stage5->>''operational_calibration_access'')::boolean,false) then v_target:=6; end if;';
BEGIN
  v_def:=pg_get_functiondef(v_oid);
  IF position(v_old IN v_def)=0
    OR position(v_old_cond IN v_def)=0
    OR position('private.exam_prep_stage4_exit_status_v1(new.user_id' IN v_def)=0
    OR position('SECURITY DEFINER' IN upper(v_def))=0
    OR position('search_path TO ''''' IN v_def)=0
  THEN RAISE EXCEPTION 'P4-04 existing stage projection source drift'; END IF;
  v_def:=replace(replace(v_def,v_old,v_new),v_old_cond,v_new_cond);
  EXECUTE v_def;
  IF position(v_new IN pg_get_functiondef(v_oid))=0 OR
     position(v_new_cond IN pg_get_functiondef(v_oid))=0 OR
     position('private.exam_prep_stage5_readiness_status_v1(new.user_id' IN pg_get_functiondef(v_oid))>0
  THEN RAISE EXCEPTION 'P4-04 stage6 operational projection proof failed'; END IF;
END
$patch$;

-- Intentionally NOT changed: score_comparable, Stage5 scored readiness
-- and app_readiness_estimate trigger. No threshold insert, no Mentor grant.
COMMIT;
