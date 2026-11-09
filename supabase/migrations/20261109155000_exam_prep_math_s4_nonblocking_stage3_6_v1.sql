-- Issue #450, architect explicitly approved 2026-11-09:
-- paper rehearsal #1/2/3 and non-observable written marks/timing are
-- RECOMMENDATIONS, never mandatory Stage3-6 academic gates.
-- DRAFT SOURCE ONLY. This installs new READERS and a FEATURE-GUARDED projection.
-- The config introduced in the prior S4 migration is OFF by default; applying
-- this code in isolation MUST NOT turn on stage promotion or hybrid learner UI.
-- Keep original old-reader semantics and genuine legacy Paper history intact.
BEGIN;

CREATE OR REPLACE FUNCTION private.exam_prep_stage3_hybrid_operational_v1(
 p_user_id uuid,p_program_version_id bigint,p_component_code text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4stage3$
DECLARE v_old jsonb; v_ready boolean; v_reason text;
BEGIN
 IF p_component_code NOT IN ('P1','P5') THEN
  RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
 -- Old source evaluates engine, registry, all-section coverage, all-skill L2,
 -- key-skill L3 BEFORE checking whether one full Paper exists.
 -- Only 'full_baseline_missing' is unblocked, not any academic guard.
 v_old:=private.exam_prep_stage3_exit_status_v1(
   p_user_id,p_program_version_id,p_component_code);
 v_reason:=coalesce(v_old->>'reason_code','unknown');
 v_ready:=coalesce((v_old->>'ready')::boolean,false)
    OR v_reason='full_baseline_missing';
 RETURN jsonb_build_object(
  'ready',v_ready,'reason_code',CASE WHEN v_ready THEN 'objective_stage3_complete'
      ELSE v_reason END,
  'source','existing_stage3_objective_coverage_l2_key_l3',
  'component_code',p_component_code,'program_version_id',p_program_version_id,
  'legacy_reader_reason',v_reason,
  'coverage_count',v_old->'coverage_count',
  'denominator_count',v_old->'denominator_count',
  'l2_or_higher_count',v_old->'l2_or_higher_count',
  'key_skill_count',v_old->'key_skill_count','key_l3_count',v_old->'key_l3_count',
  'paper_rehearsal_recommended',true,'paper_rehearsal_required',false,
  'paper_rehearsal_is_academic_evidence',false,
  'written_method_verified',false,'cambridge_marks_awarded',false);
END;
$s4stage3$;

CREATE OR REPLACE FUNCTION private.exam_prep_stage4_hybrid_operational_v1(
 p_user_id uuid,p_program_version_id bigint,p_component_code text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4stage4$
DECLARE v_stage3 jsonb; v_old jsonb; v_rule private.exam_prep_stage4_exit_rules%rowtype;
 v_ready boolean:=false;v_reason text:='rule_missing'; v_corrective boolean;
BEGIN
 IF p_component_code NOT IN ('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
 SELECT * INTO v_rule FROM private.exam_prep_stage4_exit_rules
 WHERE status='active' ORDER BY created_at DESC LIMIT 1;
 v_stage3:=private.exam_prep_stage3_hybrid_operational_v1(
  p_user_id,p_program_version_id,p_component_code);
 -- Reuse existing audited correction-plan policy and below-L3 governance
 -- from the legacy reader. It computes this independently of Paper marks.
 v_old:=private.exam_prep_stage4_exit_status_v1(
  p_user_id,p_program_version_id,p_component_code);
 v_corrective:=coalesce((v_old->>'corrective_plan_gate_ready')::boolean,false);
 IF v_rule.rule_version IS NULL THEN v_reason:='rule_missing';
 ELSIF NOT coalesce((v_stage3->>'ready')::boolean,false) THEN
  v_reason:='stage3_objective_incomplete';
 ELSIF NOT v_corrective THEN
  v_reason:='l3_or_governed_correction_plan_incomplete';
 ELSE v_ready:=true;v_reason:='objective_corrections_ready'; END IF;
 RETURN jsonb_build_object(
  'ready',v_ready,'reason_code',v_reason,'rule_version',v_rule.rule_version,
  'component_code',p_component_code,'program_version_id',p_program_version_id,
  'stage3_hybrid_ready',v_stage3->'ready',
  'legacy_reader_reason',v_old->'reason_code',
  'below_l3_count',v_old->'below_l3_count',
  'corrective_plan_gate_ready',v_corrective,
  'two_full_papers_recommended',true,'full_papers_required_for_access',false,
  'unattempted_written_marks_trend','unknown',
  'after_time_written_marks_trend','unknown',
  'timed_written_sections_required_for_access',false,
  'written_method_verified',false,'cambridge_marks_awarded',false);
END;
$s4stage4$;

CREATE OR REPLACE FUNCTION private.exam_prep_stage5_hybrid_operational_v1(
 p_user_id uuid,p_program_version_id bigint,p_component_code text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4stage5$
DECLARE v_stage4 jsonb; v_raw jsonb;
 v_rule private.exam_prep_stage5_readiness_rules%rowtype;
 v_total int:=0;v_below int:=0;v_open int:=0;
 v_ready boolean:=false;v_reason text:='rule_missing';
BEGIN
 IF p_component_code NOT IN ('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
 SELECT * INTO v_rule FROM private.exam_prep_stage5_readiness_rules
 WHERE status='active' ORDER BY created_at DESC LIMIT 1;
 v_stage4:=private.exam_prep_stage4_hybrid_operational_v1(
  p_user_id,p_program_version_id,p_component_code);
 -- Legacy raw reader independently computes ONLY confirmed objective L3
 -- skill states and unresolved correction cases; its full-Paper score fields
 -- and Stage4 legacy readiness are DELIBERATELY IGNORED for the hybrid gate.
 v_raw:=private.exam_prep_stage5_raw_readiness_v1(
  p_user_id,p_program_version_id,p_component_code);
 v_total:=coalesce((v_raw->>'canonical_skill_count')::int,0);
 v_below:=coalesce((v_raw->>'below_l3_count')::int,0);
 v_open:=coalesce((v_raw->>'unresolved_correction_case_count')::int,0);
 IF v_rule.rule_version IS NULL THEN v_reason:='rule_missing';
 ELSIF NOT coalesce((v_stage4->>'ready')::boolean,false) THEN
   v_reason:='stage4_objective_or_corrections_incomplete';
 ELSIF v_total=0 OR v_below<>0 THEN v_reason:='objective_skill_l3_stability_incomplete';
 ELSIF v_open<>0 THEN v_reason:='corrective_cycles_open';
 ELSE v_ready:=true;v_reason:='operational_final_calibration_available'; END IF;
 RETURN jsonb_build_object(
  'ready',v_ready,'reason_code',v_reason,'rule_version',v_rule.rule_version,
  'component_code',p_component_code,'program_version_id',p_program_version_id,
  'stage4_hybrid_ready',v_stage4->'ready',
  'canonical_skill_count',v_total,'below_l3_count',v_below,
  'unresolved_correction_case_count',v_open,
  'three_full_papers_recommended',true,'full_papers_required_for_access',false,
  'stage6_operational_access',v_ready,
  'app_readiness_estimate','INSUFFICIENT_EVIDENCE',
  'verified_written_method_marks',null,'full_paper_grade',null,
  'no_new_score_threshold',true,'mentor_required',false,'ai_required',false);
END;
$s4stage5$;

REVOKE ALL ON FUNCTION private.exam_prep_stage3_hybrid_operational_v1(uuid,bigint,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.exam_prep_stage4_hybrid_operational_v1(uuid,bigint,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.exam_prep_stage5_hybrid_operational_v1(uuid,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage3_hybrid_operational_v1(uuid,bigint,text)
 TO service_role;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage4_hybrid_operational_v1(uuid,bigint,text)
 TO service_role;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage5_hybrid_operational_v1(uuid,bigint,text)
 TO service_role;

-- Owner-only readout of the NEW non-scored operational stage recommendations;
-- not a grade, and does not mutate any record or trigger state.
CREATE OR REPLACE FUNCTION public.get_exam_prep_hybrid_s4_stage_status_safe_v1(
 p_component_code text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4stagepublic$
DECLARE v_uid uuid;v_program bigint;v_enabled boolean;
 v_3 jsonb;v_4 jsonb;v_5 jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_component_code NOT IN('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
 SELECT program_version_id INTO v_program FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF v_program IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
 SELECT stage_gates_enabled INTO v_enabled FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton;
 IF v_enabled IS DISTINCT FROM true THEN
   RETURN jsonb_build_object('enabled',false,'no_stage_change',true,'no_self_marks',true);
 END IF;
 v_3:=private.exam_prep_stage3_hybrid_operational_v1(v_uid,v_program,p_component_code);
 v_4:=private.exam_prep_stage4_hybrid_operational_v1(v_uid,v_program,p_component_code);
 v_5:=private.exam_prep_stage5_hybrid_operational_v1(v_uid,v_program,p_component_code);
 RETURN jsonb_build_object(
  'enabled',true,'component_code',p_component_code,
  'stage3_to_4',v_3,'stage4_to_5',v_4,'stage5_to_6',v_5,
  'full_papers_recommended_not_required',true,
  'stage_access_not_cambridge_readiness',true,
  'self_scoring',false,'human_marking_enabled',false,'ai_marking_enabled',false);
END;
$s4stagepublic$;
REVOKE ALL ON FUNCTION public.get_exam_prep_hybrid_s4_stage_status_safe_v1(text)
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_hybrid_s4_stage_status_safe_v1(text)
 TO authenticated,service_role;

-- Exact guarded patch of existing stage projector: toggles the NEW readers
-- ONLY when S4 stage_gates_enabled=true; default false preserves every legacy
-- stage result. Rewrites code, not any historical state/learner rows.
DO $s4patch$
DECLARE v_sig regprocedure;
 v_body text;v_old text;v_new text;v_n int; v_feature text;
BEGIN
 v_sig:=to_regprocedure('private.exam_prep_apply_stage0_gate_v1()');
 IF v_sig IS NULL THEN RAISE EXCEPTION 'S4 missing existing stage projector'; END IF;
 v_body:=pg_get_functiondef(v_sig);
 IF position('private.exam_prep_stage3_exit_status_v1(new.user_id' IN v_body)=0 OR
    position('private.exam_prep_stage4_exit_status_v1(new.user_id' IN v_body)=0 OR
    position('private.exam_prep_stage5_readiness_status_v1(new.user_id' IN v_body)=0 THEN
  RAISE EXCEPTION 'S4 projector changed, manual source inspection required';
 END IF;

 v_old:='v_stage3:=private.exam_prep_stage3_exit_status_v1(new.user_id,new.program_version_id,new.component_code);';
 v_new:='if coalesce((select stage_gates_enabled from private.exam_prep_hybrid_s4_config_v1 where singleton),false) then v_stage3:=private.exam_prep_stage3_hybrid_operational_v1(new.user_id,new.program_version_id,new.component_code); else v_stage3:=private.exam_prep_stage3_exit_status_v1(new.user_id,new.program_version_id,new.component_code); end if;';
 IF position(v_old IN v_body)=0 THEN RAISE EXCEPTION 'S4 stage3 source guard mismatch'; END IF;
 v_body:=replace(v_body,v_old,v_new);

 v_old:='v_stage4:=private.exam_prep_stage4_exit_status_v1(new.user_id,new.program_version_id,new.component_code);';
 v_new:='if coalesce((select stage_gates_enabled from private.exam_prep_hybrid_s4_config_v1 where singleton),false) then v_stage4:=private.exam_prep_stage4_hybrid_operational_v1(new.user_id,new.program_version_id,new.component_code); else v_stage4:=private.exam_prep_stage4_exit_status_v1(new.user_id,new.program_version_id,new.component_code); end if;';
 IF position(v_old IN v_body)=0 THEN RAISE EXCEPTION 'S4 stage4 source guard mismatch'; END IF;
 v_body:=replace(v_body,v_old,v_new);

 v_old:='v_stage5:=private.exam_prep_stage5_readiness_status_v1(new.user_id,new.program_version_id,new.component_code);';
 v_new:='if coalesce((select stage_gates_enabled from private.exam_prep_hybrid_s4_config_v1 where singleton),false) then v_stage5:=private.exam_prep_stage5_hybrid_operational_v1(new.user_id,new.program_version_id,new.component_code); else v_stage5:=private.exam_prep_stage5_readiness_status_v1(new.user_id,new.program_version_id,new.component_code); end if;';
 IF position(v_old IN v_body)=0 THEN RAISE EXCEPTION 'S4 stage5 source guard mismatch'; END IF;
 v_body:=replace(v_body,v_old,v_new);

 -- Preserve old user-facing stage-hold reasons WHEN the feature is OFF.
 -- Only switch those strings if owner later explicitly enables hybrid gates.
 v_old:='new.stage_hold_reason:=''Stage 3 Syllabus Closure active. Stage 4 requires complete component closure, governed key-skill evidence and the first comparable full-paper baseline.'';';
 v_new:='new.stage_hold_reason:=case when coalesce((select stage_gates_enabled from private.exam_prep_hybrid_s4_config_v1 where singleton),false) then ''Stage 3 Syllabus Closure active. Stage 4 requires verified L2 syllabus and key L3 skills; Paper practice is optional.'' else ''Stage 3 Syllabus Closure active. Stage 4 requires complete component closure, governed key-skill evidence and the first comparable full-paper baseline.'' end;';
 IF position(v_old IN v_body)=0 THEN RAISE EXCEPTION 'S4 stage3 reason source guard mismatch'; END IF;
 v_body:=replace(v_body,v_old,v_new);

 v_old:='new.stage_hold_reason:=''Stage 4 Timed Consolidation active. Stage 5 requires two compatible strict full papers, stable timing/unattempted evidence and resolved corrective work.'';';
 v_new:='new.stage_hold_reason:=case when coalesce((select stage_gates_enabled from private.exam_prep_hybrid_s4_config_v1 where singleton),false) then ''Stage 4 Timed Consolidation active. Stage 5 requires governed skills and correction evidence; Paper practice is optional.'' else ''Stage 4 Timed Consolidation active. Stage 5 requires two compatible strict full papers, stable timing/unattempted evidence and resolved corrective work.'' end;';
 IF position(v_old IN v_body)=0 THEN RAISE EXCEPTION 'S4 stage4 reason source guard mismatch'; END IF;
 v_body:=replace(v_body,v_old,v_new);

 v_old:='new.stage_hold_reason:=''Stage 5 Exam Readiness active. Stage 6 requires the component-specific App Readiness evidence gate; no date or weighted average can promote it.'';';
 v_new:='new.stage_hold_reason:=case when coalesce((select stage_gates_enabled from private.exam_prep_hybrid_s4_config_v1 where singleton),false) then ''Stage 5 active. Stage 6 operational access requires objectively verified L3 for all skills and closed corrections; exam method marks remain unknown.'' else ''Stage 5 Exam Readiness active. Stage 6 requires the component-specific App Readiness evidence gate; no date or weighted average can promote it.'' end;';
 IF position(v_old IN v_body)=0 THEN RAISE EXCEPTION 'S4 stage5 reason source guard mismatch'; END IF;
 v_body:=replace(v_body,v_old,v_new);

 EXECUTE v_body;
END;
$s4patch$;

COMMIT;
