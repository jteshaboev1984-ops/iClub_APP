-- DRAFT ONLY. Apply in disposable PG17 AFTER exact_goal_binding AND
-- learning_review_goal_eligibility, BEFORE review postinstall attestation.
-- No live installation, academic writes, snapshot edits or automatic enrollment.
-- Frozen goal order is an immutable commitment, not the latest plan priority.
BEGIN;
DO $pristine$
BEGIN
 IF to_regprocedure('private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)') IS NOT NULL
 OR to_regclass('private.exam_prep_learning_review_starts_v1') IS NULL THEN
  RAISE EXCEPTION 'frozen_goal_continuity_requires_pristine_review_install';
 END IF;
END;$pristine$;

CREATE FUNCTION private.exam_prep_frozen_goal_current_priority_v1(
 p_uid uuid,p_program bigint,p_component text,p_week smallint,
 p_goal uuid,p_current_plan uuid
) RETURNS smallint LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $body$
DECLARE
 g private.exam_prep_weekly_goal_snapshots%rowtype;
 src private.exam_prep_weekly_plans%rowtype;
 dst private.exam_prep_weekly_plans%rowtype;
 v_version integer;
 v_plan uuid;
 v_count integer;
 v_priority smallint;
 v_result smallint;
BEGIN
 IF p_uid IS NULL OR p_program IS NULL OR p_component NOT IN ('P1','P5')
    OR p_week IS NULL OR p_goal IS NULL OR p_current_plan IS NULL THEN RETURN NULL; END IF;
 SELECT * INTO g FROM private.exam_prep_weekly_goal_snapshots
 WHERE id=p_goal AND user_id=p_uid AND program_version_id=p_program
 AND component_code=p_component AND active_week_no=p_week;
 IF g.id IS NULL OR g.item_type NOT IN ('learning','correction')
 OR g.skill_code IS NULL OR (g.item_type='correction' AND g.correction_case_id IS NULL)
 THEN RETURN NULL; END IF;
 SELECT * INTO src FROM private.exam_prep_weekly_plans
 WHERE id=g.source_plan_id AND user_id=p_uid AND program_version_id=p_program
 AND component_code=p_component AND active_week_no=p_week
 AND status IN ('active','superseded');
 SELECT * INTO dst FROM private.exam_prep_weekly_plans
 WHERE id=p_current_plan AND user_id=p_uid AND program_version_id=p_program
 AND component_code=p_component AND active_week_no=p_week AND status='active';
 IF src.id IS NULL OR dst.id IS NULL OR src.plan_version IS NULL
 OR dst.plan_version IS NULL OR src.plan_version<1
 OR dst.plan_version<src.plan_version OR dst.plan_version-src.plan_version>100
 OR dst.generated_at<src.generated_at THEN RETURN NULL; END IF;
 -- Two frozen goals with indistinguishable content/correction identity are not
 -- safely routable. Refuse even if today's plan happens to have one candidate.
 IF EXISTS(SELECT 1 FROM private.exam_prep_weekly_goal_snapshots other
 WHERE other.user_id=p_uid AND other.program_version_id=p_program
 AND other.component_code=p_component AND other.active_week_no=p_week
 AND other.id<>g.id AND other.item_type=g.item_type
 AND other.skill_code IS NOT DISTINCT FROM g.skill_code
 AND other.correction_case_id IS NOT DISTINCT FROM g.correction_case_id
 AND other.action_code=g.action_code
 AND other.assessment_id IS NOT DISTINCT FROM g.assessment_id)
 THEN RETURN NULL; END IF;
 -- Every intermediate plan version MUST be present exactly once and carry one
 -- identical item identity. A gap, duplicate or changed case/action fails shut.
 -- Its priority may vary: the first must match the frozen ordinal, the last
 -- returns the ACTIVE item ordinal. Historical plan/item rows are never edited.
 FOR v_version IN src.plan_version..dst.plan_version LOOP
  SELECT count(*)::integer INTO v_count FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=p_uid AND p.program_version_id=p_program
   AND p.component_code=p_component AND p.active_week_no=p_week
   AND p.plan_version=v_version AND p.generated_at BETWEEN src.generated_at AND dst.generated_at;
  IF v_count<>1 THEN RETURN NULL; END IF;
  SELECT p.id INTO v_plan FROM private.exam_prep_weekly_plans p
  WHERE p.user_id=p_uid AND p.program_version_id=p_program
   AND p.component_code=p_component AND p.active_week_no=p_week
   AND p.plan_version=v_version;
  SELECT count(*)::integer,min(i.priority_order)
  INTO v_count,v_priority FROM private.exam_prep_weekly_plan_items i
  WHERE i.plan_id=v_plan AND i.item_type=g.item_type
   AND i.skill_code IS NOT DISTINCT FROM g.skill_code
   AND i.correction_case_id IS NOT DISTINCT FROM g.correction_case_id
   AND i.action_code=g.action_code
   AND (g.assessment_id IS NULL OR i.action_payload->>'assessment_id'=g.assessment_id::text)
   AND (v_version<>dst.plan_version OR i.status='pending');
  IF v_count<>1 OR (v_version=src.plan_version AND v_priority<>g.priority_order)
   OR (v_version=dst.plan_version AND v_plan<>dst.id)
  THEN RETURN NULL; END IF;
  IF v_version=dst.plan_version THEN v_result:=v_priority; END IF;
 END LOOP;
 RETURN v_result;
END;$body$;
REVOKE ALL ON FUNCTION private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)
 FROM PUBLIC,anon,authenticated,service_role;

-- The preceding exact-binding patch intentionally rejected ALL superseded
-- source plans; replace that unconditional denial ONLY with the provenance
-- proof above. Require exact existing anchors to avoid editing a drifted RPC.
DO $review_patch$
DECLARE v_def text; v_old text; v_new text;
BEGIN
 v_def:=pg_get_functiondef('public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)'::regprocedure);
 v_old:=' AND source_plan_id=p_plan_id;';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'continuity_review_source_anchor_drift'; END IF;
 v_def:=replace(v_def,v_old,';');
 v_old:=chr(10)||' AND i.priority_order=v_goal.priority_order';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>2*length(v_old) THEN
  RAISE EXCEPTION 'continuity_review_frozen_order_anchors_drift'; END IF;
 v_def:=replace(v_def,v_old,'');
 v_old:=chr(10)||' IF (SELECT count(*) FROM private.exam_prep_weekly_plan_items i';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'continuity_review_verified_item_anchor_drift'; END IF;
 v_new:=chr(10)
 ||' IF private.exam_prep_frozen_goal_current_priority_v1(v_uid,v_program,p_component_code,v_week,p_goal_id,p_plan_id)'
 ||' IS DISTINCT FROM v_item.priority_order THEN'
 ||chr(10)||'  RETURN jsonb_build_object(''status'',''stale'',''reason'',''goal_lineage_unverified'');'
 ||chr(10)||' END IF;'
 ||v_old;
 EXECUTE replace(v_def,v_old,v_new);
END;$review_patch$;

-- The read-only goal endpoint must agree with the atomic starter; never show
-- review_ready for an unproven historical goal, even if skill/action match.
DO $eligibility_patch$
DECLARE v_def text; v_old text; v_new text;
BEGIN
 v_def:=pg_get_functiondef('public.get_exam_prep_goal_action_state_safe_v1(text,uuid,uuid)'::regprocedure);
 v_old:='v_now:=private.exam_prep_effective_academic_now_v1(v_uid);';
 IF (length(v_def)-length(replace(v_def,v_old,'')))<>length(v_old) THEN
  RAISE EXCEPTION 'continuity_goal_read_model_anchor_drift'; END IF;
 v_new:='IF v_item.item_type IN (''learning'',''correction'') AND'
 ||chr(10)||'     private.exam_prep_frozen_goal_current_priority_v1(v_uid,v_program,p_component_code,v_week,p_goal_id,p_plan_id)'
 ||' IS DISTINCT FROM v_item.priority_order THEN'
 ||chr(10)||'    RETURN jsonb_build_object(''status'',''stale'',''reason'',''goal_lineage_unverified'');'
 ||chr(10)||'  END IF;'
 ||chr(10)||'  '||v_old;
 EXECUTE replace(v_def,v_old,v_new);
END;$eligibility_patch$;
DO $acl_gate$
BEGIN
 IF has_function_privilege('anon','private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)','EXECUTE')
 OR has_function_privilege('authenticated','private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)','EXECUTE')
 OR has_function_privilege('service_role','private.exam_prep_frozen_goal_current_priority_v1(uuid,bigint,text,smallint,uuid,uuid)','EXECUTE')
 OR has_function_privilege('anon','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.start_exam_prep_learning_review_safe_v1(text,uuid,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'continuity_acl_drift'; END IF;
END;$acl_gate$;
COMMIT;
