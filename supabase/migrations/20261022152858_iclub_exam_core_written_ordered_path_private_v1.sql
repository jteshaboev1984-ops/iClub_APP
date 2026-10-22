-- iClub Exam Prep Economics — closed Stage 4. Additive PRIVATE-only.
-- No changes to Mathematics, Practice, Tours, user history, or public API.
CREATE UNIQUE INDEX IF NOT EXISTS iclub_exam_written_one_active_plan_v1
  ON private.iclub_exam_core_written_plans_v1(learner_user_id,program_key,version_key)
  WHERE status='active';

CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_next_item_v1(
  p_program_key text,p_version_key text,p_language text DEFAULT 'en'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE v_user uuid:=auth.uid(); v_item record;
BEGIN
 IF v_user IS NULL THEN
  RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501';
 END IF;
 IF NULLIF(btrim(p_program_key),'') IS NULL
   OR NULLIF(btrim(p_version_key),'') IS NULL
   OR p_language NOT IN ('en','ru','uz') THEN
  RAISE EXCEPTION 'written_request_invalid' USING ERRCODE='22023';
 END IF;
 IF NOT EXISTS (
  SELECT 1
  FROM private.iclub_exam_core_written_plans_v1 pl
  JOIN private.iclub_exam_core_programs_v1 pg
    ON pg.program_key=pl.program_key AND pg.version_key=pl.version_key
  JOIN private.iclub_exam_core_written_access_v1 ac
    ON ac.learner_user_id=pl.learner_user_id
      AND ac.program_key=pl.program_key AND ac.version_key=pl.version_key
  WHERE pl.learner_user_id=v_user
    AND pl.program_key=p_program_key AND pl.version_key=p_version_key
    AND pl.status='active'
    AND pg.integration_mode='native'
    AND pg.status='published' AND pg.launch_enabled=true
    AND ac.status='active' AND ac.core_access=true
    AND (ac.valid_from IS NULL OR ac.valid_from<=now())
    AND (ac.valid_until IS NULL OR ac.valid_until>now())
 ) THEN
  RAISE EXCEPTION 'written_plan_not_available' USING ERRCODE='42501';
 END IF;
 SELECT i.id,i.priority_order,i.program_key,i.version_key,i.mode,
        t.status AS task_status,t.release_enabled,
        t.academic_review,t.language_review,t.source_review,
        t.questions->>p_language AS localized_question
 INTO v_item
 FROM private.iclub_exam_core_written_plans_v1 pl
 JOIN private.iclub_exam_core_written_plan_items_v1 i
   ON i.plan_id=pl.id AND i.learner_user_id=pl.learner_user_id
     AND i.program_key=pl.program_key AND i.version_key=pl.version_key
 JOIN private.iclub_exam_core_written_tasks_v1 t
   ON t.program_key=i.program_key AND t.version_key=i.version_key
     AND t.task_key=i.task_key AND t.task_version=i.task_version
 WHERE pl.learner_user_id=v_user
   AND pl.program_key=p_program_key AND pl.version_key=p_version_key
   AND pl.status='active' AND i.status='pending'
 ORDER BY i.priority_order
 LIMIT 1;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('available',false,'reason','no_pending_step');
 END IF;
 IF v_item.mode<>'practice'
  OR v_item.task_status<>'approved' OR NOT v_item.release_enabled
  OR v_item.academic_review<>'approved'
  OR v_item.language_review<>'approved'
  OR v_item.source_review<>'approved'
  OR NULLIF(btrim(v_item.localized_question),'') IS NULL THEN
  RETURN jsonb_build_object('available',false,'reason','step_not_released');
 END IF;
 RETURN jsonb_build_object(
  'available',true,'plan_item_id',v_item.id::text,
  'priority_order',v_item.priority_order,'program_key',v_item.program_key,
  'program_version',v_item.version_key);
END;
$fn$;

-- V1 remains unchanged and inaccessible; new learner transport MUST use V2.
CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_advance_v2(
 p_item_id uuid,p_task_key text,p_task_version text,
 p_task_token uuid,p_idempotency_key text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE v_user uuid:=auth.uid(); v_item record;
BEGIN
 IF v_user IS NULL THEN
  RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501';
 END IF;
 IF p_item_id IS NULL OR p_task_token IS NULL
  OR NULLIF(btrim(p_task_key),'') IS NULL
  OR NULLIF(btrim(p_task_version),'') IS NULL
  OR NULLIF(btrim(p_idempotency_key),'') IS NULL
  OR length(btrim(p_idempotency_key))<8 OR length(p_idempotency_key)>120 THEN
  RAISE EXCEPTION 'written_request_invalid' USING ERRCODE='22023';
 END IF;
 SELECT i.plan_id,i.priority_order,i.status,i.opened_at
 INTO v_item
 FROM private.iclub_exam_core_written_plan_items_v1 i
 JOIN private.iclub_exam_core_written_plans_v1 pl
   ON pl.id=i.plan_id AND pl.learner_user_id=i.learner_user_id
     AND pl.program_key=i.program_key AND pl.version_key=i.version_key
 JOIN private.iclub_exam_core_programs_v1 pg
   ON pg.program_key=i.program_key AND pg.version_key=i.version_key
 JOIN private.iclub_exam_core_written_tasks_v1 t
   ON t.program_key=i.program_key AND t.version_key=i.version_key
     AND t.task_key=i.task_key AND t.task_version=i.task_version
 JOIN private.iclub_exam_core_written_access_v1 ac
   ON ac.learner_user_id=i.learner_user_id
     AND ac.program_key=i.program_key AND ac.version_key=i.version_key
 WHERE i.id=p_item_id AND i.learner_user_id=v_user
   AND i.task_key=p_task_key AND i.task_version=p_task_version
   AND i.task_token=p_task_token AND i.mode='practice'
   AND pl.status='active'
   AND pg.integration_mode='native' AND pg.status='published'
     AND pg.launch_enabled=true
   AND t.status='approved' AND t.release_enabled=true
   AND t.academic_review='approved' AND t.language_review='approved'
     AND t.source_review='approved'
   AND ac.status='active' AND ac.core_access=true
   AND (ac.valid_from IS NULL OR ac.valid_from<=now())
   AND (ac.valid_until IS NULL OR ac.valid_until>now())
 FOR UPDATE OF i;
 IF NOT FOUND THEN
  RAISE EXCEPTION 'written_item_not_available' USING ERRCODE='42501';
 END IF;
 IF v_item.status='advanced' THEN
  RETURN jsonb_build_object('status','advanced','plan_item_id',p_item_id::text,
    'task_key',p_task_key,'task_version',p_task_version,'replayed',true);
 END IF;
 IF v_item.opened_at IS NULL THEN
  RAISE EXCEPTION 'written_must_open_first' USING ERRCODE='22023';
 END IF;
 IF EXISTS (
  SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 earlier
  WHERE earlier.plan_id=v_item.plan_id
    AND earlier.priority_order<v_item.priority_order
    AND earlier.status<>'advanced'
 ) THEN
  RAISE EXCEPTION 'written_previous_step_pending' USING ERRCODE='22023';
 END IF;
 IF EXISTS (
  SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 other
  WHERE other.learner_user_id=v_user
    AND other.advance_nonce=p_idempotency_key AND other.id<>p_item_id
 ) THEN
  RAISE EXCEPTION 'written_idempotency_conflict' USING ERRCODE='23505';
 END IF;
 UPDATE private.iclub_exam_core_written_plan_items_v1
  SET status='advanced',advanced_at=now(),advance_nonce=p_idempotency_key
  WHERE id=p_item_id AND status='pending';
 IF NOT FOUND THEN
  RAISE EXCEPTION 'written_advance_conflict' USING ERRCODE='40001';
 END IF;
 RETURN jsonb_build_object('status','advanced','plan_item_id',p_item_id::text,
  'task_key',p_task_key,'task_version',p_task_version,'replayed',false);
END;
$fn$;

REVOKE ALL ON FUNCTION private.iclub_exam_core_written_next_item_v1(text,text,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_core_written_advance_v2(uuid,text,text,uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_core_written_next_item_v1(text,text,text)
 TO service_role;
GRANT EXECUTE ON FUNCTION private.iclub_exam_core_written_advance_v2(uuid,text,text,uuid,text)
 TO service_role;
