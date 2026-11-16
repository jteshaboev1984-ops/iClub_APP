-- Mathematics #450 / owner 2026-11-16: P1/P5 Paper practice is ungraded.
-- Stage6 operational access is distinct from a Cambridge exam-readiness grade.
-- The 2026-11-09 hybrid objective progression already exists and is OFF
-- unless S4 stage_gates_enabled=true. Read-only RPC bridge ONLY:
-- NO config flip, no user/evidence DML, no self marks, no added AI/Mentor gate.
BEGIN;

DO $source_guard$
DECLARE v_def text;
BEGIN
  IF to_regprocedure('private.exam_prep_stage5_hybrid_operational_v1(uuid,bigint,text)') IS NULL
     OR to_regclass('private.exam_prep_hybrid_s4_config_v1') IS NULL
     OR to_regprocedure('public.get_exam_prep_final_calibration_safe_v1(text)') IS NULL
  THEN
    RAISE EXCEPTION 'Math S4 Stage6 bridge missing protected dependencies';
  END IF;
  SELECT pg_get_functiondef(
    'public.get_exam_prep_final_calibration_safe_v1(text)'::regprocedure) INTO v_def;
  IF position('exam_prep_stage5_readiness_status_v1' IN v_def)=0
     OR position('order by derived_at desc' IN lower(v_def))=0
     OR position('exam_prep_require_core_access_v1' IN v_def)=0
     OR position('exam_prep_exam_ops_status_v1' IN v_def)=0
  THEN
    RAISE EXCEPTION 'Math S4 Stage6 existing owner/calibration source changed';
  END IF;
END;
$source_guard$;

CREATE OR REPLACE FUNCTION public.get_exam_prep_final_calibration_safe_v1(
  p_component_code text
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $math_s4_stage6$
DECLARE
  v_uid uuid;
  v_program bigint;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_ready jsonb;
  v_operational jsonb;
  v_hybrid boolean:=false;
  v_available boolean:=false;
  v_stage smallint:=0;
  v_open_cases int:=0;
  v_latest_skill text;
  v_latest_case uuid;
  v_actions jsonb;
  v_readiness_note jsonb;
  v_ops jsonb;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF p_component_code NOT IN ('P1','P5') THEN
    RAISE EXCEPTION 'exam_prep_bad_component';
  END IF;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  v_program:=v_profile.program_version_id;
  IF v_program IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;

  SELECT coalesce(stage_gates_enabled,false) INTO v_hybrid
  FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton;
  v_hybrid:=coalesce(v_hybrid,false);

  -- Legacy reading must keep its prior behavior if the new gated contract is
  -- OFF, including all genuine historic digital scores and permissions.
  v_ready:=private.exam_prep_stage5_readiness_status_v1(
    v_uid,v_program,p_component_code);
  -- Preserve the pre-existing P2-06 owner-only exam logistics/checklist.
  v_ops:=private.exam_prep_exam_ops_status_v1(v_uid,v_program,p_component_code);
  SELECT coalesce(operational_stage,0) INTO v_stage
  FROM private.exam_prep_stage_states
  WHERE user_id=v_uid AND program_version_id=v_program
    AND component_code=p_component_code
  ORDER BY derived_at DESC LIMIT 1;
  v_stage:=coalesce(v_stage,0);

  IF v_hybrid THEN
    v_operational:=private.exam_prep_stage5_hybrid_operational_v1(
      v_uid,v_program,p_component_code);
    -- Stage6 is an operational option, not a scored Paper/grade:
    -- BOTH the independent objective reader and actual server stage row
    -- must agree. No client-supplied progress flag can grant access.
    v_available:=(v_stage>=6 AND
      coalesce((v_operational->>'ready')::boolean,false));
    v_readiness_note:=jsonb_build_object(
      'ready',false,
      'app_readiness_estimate','INSUFFICIENT_EVIDENCE',
      'reason_code','written_paper_ungraded',
      'full_paper_grade',null,
      'verified_written_method_marks',null,
      'not_official_cambridge_grade',true,
      'objective_operational_access_separate',true);
  ELSE
    v_available:=coalesce((v_ready->>'ready')::boolean,false);
    v_readiness_note:=v_ready-'threshold_version';
  END IF;

  SELECT count(*),
         (array_agg(skill_code ORDER BY updated_at DESC,id DESC))[1],
         (array_agg(id ORDER BY updated_at DESC,id DESC))[1]
    INTO v_open_cases,v_latest_skill,v_latest_case
  FROM private.exam_prep_correction_cases
  WHERE user_id=v_uid AND component_code=p_component_code
    AND status IN ('open','remediating','retest_due','reopened');

  v_actions:=jsonb_build_array(
    jsonb_build_object('action_code','short_targeted_work','priority',1,
      'purpose','Maintain exam form with short evidence-driven work; do not reopen the whole syllabus.'),
    jsonb_build_object('action_code','timing_and_logistics','priority',2,
      'purpose','Confirm component timing and exam logistics through the approved profile process.'),
    jsonb_build_object('action_code','taper','priority',3,
      'purpose','Reduce bulk workload and protect sleep/recovery; calibration volume does not create new mastery.')
  );
  IF v_open_cases>0 THEN
    v_actions:=jsonb_build_array(jsonb_build_object(
      'action_code','close_recurring_issue','priority',1,
      'purpose','Resolve the highest-priority remaining evidence-based correction before adding optional work.',
      'skill_code',v_latest_skill,'correction_case_id',v_latest_case
    )) || v_actions;
  END IF;

  RETURN jsonb_build_object(
    'available',v_available,
    'component_code',p_component_code,
    'operational_stage',v_stage,
    'stage6_operational_access',v_hybrid AND v_available,
    'hybrid_stage_gate_enabled',v_hybrid,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'readiness',v_readiness_note,
    'open_correction_cases',v_open_cases,
    'actions',v_actions,
    'exam_operations',v_ops,
    'new_mastery_allowed',false,
    'mentor_verified_readiness',CASE WHEN v_hybrid THEN false
      ELSE coalesce((private.exam_prep_mentor_verified_readiness_status_v1(
        v_uid,v_program,p_component_code)->>'mentor_verified')::boolean,false) END,
    'paper_marks_awarded',CASE WHEN v_hybrid THEN false ELSE null END,
    'paper_rehearsal_required',CASE WHEN v_hybrid THEN false ELSE null END,
    'mentor_required_for_core',false,
    'note',CASE WHEN v_hybrid THEN
      'Final Calibration is objective operational planning, not a Paper grade or Cambridge readiness prediction.'
      ELSE
      'Final Calibration is component-specific taper/logistics support. It is not a predicted Cambridge grade and does not create mastery from last-minute work.'
      END
  );
END;
$math_s4_stage6$;

REVOKE ALL ON FUNCTION public.get_exam_prep_final_calibration_safe_v1(text)
  FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_final_calibration_safe_v1(text)
  TO authenticated,service_role;

COMMIT;
