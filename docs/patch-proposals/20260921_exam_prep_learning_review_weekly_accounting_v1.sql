-- REVIEW PROPOSAL ONLY, not a migration. Apply after public review start,
-- recovery, goal eligibility and previous-week adherence proposals in isolated CI.
-- A saved repeated learning attempt alone NEVER proves a correction succeeded.
-- Only the existing server-created remediation_completed action can satisfy
-- a correction commitment. These read-only projections cannot credit mastery.
BEGIN;
DO $patch$
DECLARE v_oid oid; v_def text; v_old text; v_new text;
BEGIN
 IF to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL OR
    to_regprocedure('public.get_exam_prep_previous_week_adherence_safe_v1(text)') IS NULL THEN
  RAISE EXCEPTION 'review_weekly_accounting_prerequisite_missing'; END IF;
 v_oid:=to_regprocedure('public.get_exam_prep_weekly_progress_safe_v1(text)');
 IF v_oid IS NULL THEN RAISE EXCEPTION 'review_progress_projection_missing'; END IF;
 v_def:=pg_get_functiondef(v_oid);
 v_old:='coalesce(hist.remediation_done,false) as remediation_done,';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_progress_remediation_anchor_drift'; END IF;
 v_new:='(coalesce(hist.remediation_done,false) OR EXISTS('
  ||'SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rv '
  ||'JOIN private.exam_prep_session_authorizations ra ON ra.id=rv.authorization_id '
  ||'AND ra.user_id=v_uid AND ra.academic_credit IS FALSE '
  ||'AND ra.credit_context=''learning_review'' '
  ||'JOIN private.exam_prep_sessions rs ON rs.authorization_id=ra.id '
  ||'AND rs.user_id=v_uid AND rs.component_code=p_component_code AND rs.status=''finalized'' '
  ||'JOIN private.exam_prep_correction_actions ca ON ca.session_id=rs.id '
  ||'AND ca.correction_case_id=rv.correction_case_id AND ca.action_type=''remediation_completed'' '
  ||'WHERE g.item_type=''correction'' AND rv.user_id=v_uid AND rv.component_code=p_component_code '
  ||'AND rv.goal_id=g.id AND rv.correction_case_id=g.correction_case_id'
  ||')) as remediation_done,';
 EXECUTE replace(v_def,v_old,v_new);

 v_oid:=to_regprocedure('public.get_exam_prep_previous_week_adherence_safe_v1(text)');
 v_def:=pg_get_functiondef(v_oid);
 v_old:='AND a.plan_id=g.source_plan_id'||chr(10)
  ||'        AND a.plan_priority_order=g.priority_order AND a.academic_credit IS TRUE';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'review_adherence_proof_anchor_drift'; END IF;
 v_new:='AND ((a.plan_id=g.source_plan_id '
  ||'AND a.plan_priority_order=g.priority_order AND a.academic_credit IS TRUE) '
  ||'OR (g.item_type=''correction'' AND a.academic_credit IS FALSE '
  ||'AND a.credit_context=''learning_review'' AND EXISTS('
  ||'SELECT 1 FROM private.exam_prep_learning_review_starts_v1 rv '
  ||'WHERE rv.authorization_id=a.id AND rv.user_id=v_uid '
  ||'AND rv.component_code=p_component_code AND rv.goal_id=g.id '
  ||'AND rv.plan_id=g.source_plan_id AND rv.correction_case_id=g.correction_case_id)))';
 v_def:=replace(v_def,v_old,v_new);
 v_old:='''data_basis'',''frozen_goals_and_credited_sessions''';
 IF position(v_old in v_def)=0 THEN RAISE EXCEPTION 'review_adherence_basis_anchor_drift'; END IF;
 EXECUTE replace(v_def,v_old,
  '''data_basis'',''frozen_goals_and_verified_remediation''');
END;$patch$;
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.get_exam_prep_weekly_progress_safe_v1(text)','EXECUTE')
 OR has_function_privilege('anon','public.get_exam_prep_previous_week_adherence_safe_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_weekly_progress_safe_v1(text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_exam_prep_previous_week_adherence_safe_v1(text)','EXECUTE') THEN
  RAISE EXCEPTION 'review_weekly_projection_acl_changed'; END IF;
END;$verify$;
COMMIT;
