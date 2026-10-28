-- Paper-03 av3 amendment guard, checks against av2 while retaining original av1/av2 guards.
BEGIN;
CREATE OR REPLACE FUNCTION private.exam_prep_assert_stage5_paper03_versioned_release_v2(p_new_assessment bigint)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_new private.exam_prep_assessments%rowtype;
  v_old private.exam_prep_assessments%rowtype;
  v_c private.exam_prep_timed_assessment_contracts%rowtype;
  v_oldc private.exam_prep_timed_assessment_contracts%rowtype;
  v_stage4 private.exam_prep_stage4_release_controls%rowtype;
  v_stage5 private.exam_prep_stage5_release_controls%rowtype;
BEGIN
  SELECT * INTO v_new FROM private.exam_prep_assessments WHERE id=p_new_assessment;
  IF v_new.id IS NULL OR v_new.assessment_version NOT IN('av2','av3')
     OR v_new.assessment_type<>'paper'
     OR v_new.assessment_key NOT IN('p1_stage4_full_paper_03','p5_stage4_full_paper_03') THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_bad_target';
  END IF;
  SELECT * INTO v_old FROM private.exam_prep_assessments
   WHERE content_version_id=v_new.content_version_id
     AND assessment_key=v_new.assessment_key AND assessment_version=CASE WHEN v_new.assessment_version='av3' THEN 'av2' ELSE 'av1' END
     AND assessment_type='paper' AND status='published';
  IF v_old.id IS NULL OR v_new.component_code IS DISTINCT FROM v_old.component_code THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_original_missing';
  END IF;

  SELECT * INTO v_stage4 FROM private.exam_prep_stage4_release_controls
   WHERE status='active' ORDER BY created_at DESC LIMIT 1;
  SELECT * INTO v_stage5 FROM private.exam_prep_stage5_release_controls
   WHERE status='active' ORDER BY created_at DESC LIMIT 1;
  IF v_stage4.status IS DISTINCT FROM 'active'
     OR v_stage4.stage4_policy_status IS DISTINCT FROM 'approved'
     OR v_stage4.paper02_release_status IS DISTINCT FROM 'approved'
     OR v_stage5.status IS DISTINCT FROM 'active'
     OR v_stage5.stage5_policy_status IS DISTINCT FROM 'approved'
     OR v_stage5.paper03_release_status IS DISTINCT FROM 'approved' THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_policy_not_approved';
  END IF;

  SELECT * INTO v_c FROM private.exam_prep_timed_assessment_contracts
    WHERE assessment_id=v_new.id;
  SELECT * INTO v_oldc FROM private.exam_prep_timed_assessment_contracts
    WHERE assessment_id=v_old.id;
  IF v_c.assessment_id IS NULL OR v_oldc.status<>'published'
     OR v_c.attempt_kind<>'full_paper'
     OR v_c.attempt_kind IS DISTINCT FROM v_oldc.attempt_kind
     OR v_c.paper_profile_id IS DISTINCT FROM v_oldc.paper_profile_id
     OR v_c.timing_rule IS DISTINCT FROM v_oldc.timing_rule
     OR v_c.fixed_time_limit_sec IS DISTINCT FROM v_oldc.fixed_time_limit_sec
     OR v_c.marks_available IS DISTINCT FROM v_oldc.marks_available
     OR v_c.strict_timing IS DISTINCT FROM v_oldc.strict_timing
     OR v_c.comparison_scope IS DISTINCT FROM v_oldc.comparison_scope
     OR v_c.min_operational_stage IS NULL
     OR v_c.min_operational_stage < v_stage5.min_paper03_stage
     OR v_c.min_operational_stage < v_oldc.min_operational_stage
     OR v_c.comparability_key IS DISTINCT FROM regexp_replace(v_oldc.comparability_key,'-v[12] THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_contract_mismatch';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=v_new.id)
   <> (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=v_old.id)
  OR EXISTS (
    SELECT 1 FROM private.exam_prep_assessment_items oi
    LEFT JOIN private.exam_prep_assessment_items ni
      ON ni.assessment_id=v_new.id AND ni.item_order=oi.item_order
    WHERE oi.assessment_id=v_old.id AND (
      ni.assessment_id IS NULL
      OR ni.question_id IS DISTINCT FROM oi.question_id
      OR ni.primary_skill_code IS DISTINCT FROM oi.primary_skill_code
      OR ni.reserve_role IS DISTINCT FROM oi.reserve_role
      OR ni.is_holdout IS DISTINCT FROM oi.is_holdout
      OR (SELECT task_key FROM private.exam_prep_written_tasks WHERE id=ni.written_task_id)
         IS DISTINCT FROM
         (SELECT task_key FROM private.exam_prep_written_tasks WHERE id=oi.written_task_id)
    )
  ) THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_items_mismatch';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_timed_assessment_items WHERE assessment_id=v_new.id)
   <> (SELECT count(*) FROM private.exam_prep_timed_assessment_items WHERE assessment_id=v_old.id)
  OR EXISTS (
    SELECT 1 FROM private.exam_prep_timed_assessment_items oi
    LEFT JOIN private.exam_prep_timed_assessment_items ni
      ON ni.assessment_id=v_new.id AND ni.item_order=oi.item_order
    WHERE oi.assessment_id=v_old.id AND (
      ni.assessment_id IS NULL OR ni.max_marks IS DISTINCT FROM oi.max_marks
    )
  ) THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_marks_mismatch';
  END IF;
END;
$function$
,CASE WHEN v_new.assessment_version='av3' THEN '-v3' ELSE '-v2' END) THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_contract_mismatch';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=v_new.id)
   <> (SELECT count(*) FROM private.exam_prep_assessment_items WHERE assessment_id=v_old.id)
  OR EXISTS (
    SELECT 1 FROM private.exam_prep_assessment_items oi
    LEFT JOIN private.exam_prep_assessment_items ni
      ON ni.assessment_id=v_new.id AND ni.item_order=oi.item_order
    WHERE oi.assessment_id=v_old.id AND (
      ni.assessment_id IS NULL
      OR ni.question_id IS DISTINCT FROM oi.question_id
      OR ni.primary_skill_code IS DISTINCT FROM oi.primary_skill_code
      OR ni.reserve_role IS DISTINCT FROM oi.reserve_role
      OR ni.is_holdout IS DISTINCT FROM oi.is_holdout
      OR (SELECT task_key FROM private.exam_prep_written_tasks WHERE id=ni.written_task_id)
         IS DISTINCT FROM
         (SELECT task_key FROM private.exam_prep_written_tasks WHERE id=oi.written_task_id)
    )
  ) THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_items_mismatch';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_timed_assessment_items WHERE assessment_id=v_new.id)
   <> (SELECT count(*) FROM private.exam_prep_timed_assessment_items WHERE assessment_id=v_old.id)
  OR EXISTS (
    SELECT 1 FROM private.exam_prep_timed_assessment_items oi
    LEFT JOIN private.exam_prep_timed_assessment_items ni
      ON ni.assessment_id=v_new.id AND ni.item_order=oi.item_order
    WHERE oi.assessment_id=v_old.id AND (
      ni.assessment_id IS NULL OR ni.max_marks IS DISTINCT FROM oi.max_marks
    )
  ) THEN
    RAISE EXCEPTION 'exam_prep_paper03_amendment_marks_mismatch';
  END IF;
END;
$function$
;
CREATE OR REPLACE FUNCTION private.exam_prep_guard_stage5_paper03_assessment_release_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NEW.status='published'
     AND NEW.assessment_key IN('p1_stage4_full_paper_03','p5_stage4_full_paper_03') THEN
    IF NEW.assessment_version IN('av2','av3') THEN
      PERFORM private.exam_prep_assert_stage5_paper03_versioned_release_v2(NEW.id);
    ELSE
      PERFORM private.exam_prep_assert_stage5_paper03_release_governance_v1(NEW.component_code);
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;
CREATE OR REPLACE FUNCTION private.exam_prep_guard_stage5_paper03_contract_release_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_key text;
  v_component text;
  v_version text;
  v_required smallint;
  v_effective smallint;
BEGIN
  IF NEW.status<>'published' THEN RETURN NEW; END IF;
  SELECT assessment_key,component_code,assessment_version
    INTO v_key,v_component,v_version
  FROM private.exam_prep_assessments WHERE id=NEW.assessment_id;
  IF v_key NOT IN('p1_stage4_full_paper_03','p5_stage4_full_paper_03') THEN
    RETURN NEW;
  END IF;
  IF v_version IN('av2','av3') THEN
    PERFORM private.exam_prep_assert_stage5_paper03_versioned_release_v2(NEW.assessment_id);
  ELSE
    PERFORM private.exam_prep_assert_stage5_paper03_release_governance_v1(v_component);
  END IF;
  SELECT min_paper03_stage INTO v_required
  FROM private.exam_prep_stage5_release_controls WHERE status='active';
  v_effective:=private.exam_prep_timed_effective_min_stage_v1(
    NEW.attempt_kind,NEW.min_operational_stage::integer);
  IF NEW.min_operational_stage IS NULL OR v_effective<v_required THEN
    RAISE EXCEPTION 'exam_prep_stage5_paper03_min_stage_too_low required=% actual=%',
      v_required,coalesce(v_effective,0);
  END IF;
  RETURN NEW;
END;
$function$
;
COMMIT;
