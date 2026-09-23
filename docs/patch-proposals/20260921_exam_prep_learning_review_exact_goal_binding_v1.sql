-- DRAFT PROPOSAL ONLY. Apply after learning_review_start_v1 in DISPOSABLE CI.
-- No live SQL installation is authorized. Fail closed on unknown source drift.
-- A frozen goal must belong to the EXACT active plan and priority shown to
-- the learner. Matching only by skill/action can misattribute a legacy replan.
BEGIN;
DO $patch$
DECLARE
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
BEGIN
  v_oid:=to_regprocedure('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)');
  IF v_oid IS NULL OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
    RAISE EXCEPTION 'learning_review_binding_prerequisite_missing';
  END IF;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='WHERE id=p_goal_id AND user_id=v_uid AND program_version_id=v_program'
    ||chr(10)||' AND component_code=p_component_code AND active_week_no=v_week;';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
    RAISE EXCEPTION 'learning_review_goal_source_anchor_drift';
  END IF;
  v_new:='WHERE id=p_goal_id AND user_id=v_uid AND program_version_id=v_program'
    ||chr(10)||' AND component_code=p_component_code AND active_week_no=v_week'
    ||' AND source_plan_id=p_plan_id;';
  v_def:=replace(v_def,v_old,v_new);

  -- Both the COUNT and SELECT of the prospective item require its frozen
  -- priority; the independent duplicate-skill check stays broad on purpose.
  v_old:='WHERE i.plan_id=v_plan.id AND i.status=''pending'' AND i.item_type=v_goal.item_type';
  IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
    RAISE EXCEPTION 'learning_review_priority_anchors_drift';
  END IF;
  v_new:=v_old||chr(10)||' AND i.priority_order=v_goal.priority_order';
  v_def:=replace(v_def,v_old,v_new);
  EXECUTE v_def;
END;
$patch$;
DO $verify$
BEGIN
 IF has_function_privilege('anon','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 OR NOT EXISTS(SELECT 1 FROM pg_proc
   WHERE oid='public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure
   AND prosecdef AND provolatile='v') THEN
  RAISE EXCEPTION 'learning_review_binding_security_drift';
 END IF;
END;
$verify$;
COMMIT;
