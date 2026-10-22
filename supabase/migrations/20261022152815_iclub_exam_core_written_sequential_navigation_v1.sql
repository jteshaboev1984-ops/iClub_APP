-- Applied native sequential-navigation migration, reconstructed from verified Postgres definitions.

-- Generated in sync with Supabase migration 20261022152815; does not touch legacy learner data.

CREATE UNIQUE INDEX IF NOT EXISTS iclub_exam_core_written_one_active_plan_v1 ON private.iclub_exam_core_written_plans_v1(learner_user_id,program_key,version_key) WHERE status='active';

CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_advance_v1(p_item_id uuid, p_task_key text, p_task_version text, p_task_token uuid, p_idempotency_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_status text;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501';
  END IF;
  IF p_item_id IS NULL OR p_task_token IS NULL
    OR p_task_key IS NULL OR p_task_version IS NULL
    OR p_idempotency_key IS NULL
    OR length(btrim(p_idempotency_key)) < 8
    OR length(p_idempotency_key) > 120 THEN
    RAISE EXCEPTION 'written_request_invalid' USING ERRCODE='22023';
  END IF;

  SELECT i.status INTO v_status
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
    AND i.task_token=p_task_token
    AND i.mode='practice'
    AND i.opened_at IS NOT NULL
 AND (i.status='advanced' OR NOT EXISTS (
  SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 earlier
  WHERE earlier.plan_id=i.plan_id AND earlier.priority_order<i.priority_order
    AND earlier.status='pending'
 ))
    AND pl.status='active'
    AND pg.integration_mode='native'
    AND pg.status='published' AND pg.launch_enabled=true
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

  IF v_status='advanced' THEN
    RETURN jsonb_build_object(
      'status','advanced','plan_item_id',p_item_id::text,
      'task_key',p_task_key,'task_version',p_task_version,
      'replayed',true);
  END IF;

  IF EXISTS (
    SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 i2
    WHERE i2.learner_user_id=v_user
      AND i2.advance_nonce=p_idempotency_key AND i2.id<>p_item_id
  ) THEN
    RAISE EXCEPTION 'written_idempotency_conflict' USING ERRCODE='23505';
  END IF;

  UPDATE private.iclub_exam_core_written_plan_items_v1
  SET status='advanced',advanced_at=now(),advance_nonce=p_idempotency_key
  WHERE id=p_item_id AND status='pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'written_advance_conflict' USING ERRCODE='40001';
  END IF;

  RETURN jsonb_build_object(
    'status','advanced','plan_item_id',p_item_id::text,
    'task_key',p_task_key,'task_version',p_task_version,
    'replayed',false);
END;
$function$;

CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_criteria_v1(p_item_id uuid, p_task_key text, p_task_version text, p_task_token uuid, p_language text DEFAULT 'en'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid(); v_req jsonb;
BEGIN
 IF v_user IS NULL THEN
   RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501';
 END IF;
 IF p_language NOT IN ('ru','uz','en') OR p_item_id IS NULL
   OR p_task_token IS NULL OR p_task_key IS NULL OR p_task_version IS NULL THEN
   RAISE EXCEPTION 'written_request_invalid' USING ERRCODE='22023';
 END IF;
 SELECT t.answer_requirements->p_language INTO v_req
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
   AND i.opened_at IS NOT NULL
 AND (i.status='advanced' OR NOT EXISTS (
  SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 earlier
  WHERE earlier.plan_id=i.plan_id AND earlier.priority_order<i.priority_order
    AND earlier.status='pending'
 ))
   AND pl.status='active'
   AND pg.integration_mode='native' AND pg.status='published' AND pg.launch_enabled
   AND t.status='approved' AND t.release_enabled
   AND t.academic_review='approved' AND t.language_review='approved'
     AND t.source_review='approved'
   AND ac.status='active' AND ac.core_access
   AND (ac.valid_from IS NULL OR ac.valid_from<=now())
   AND (ac.valid_until IS NULL OR ac.valid_until>now());
 IF NOT FOUND THEN
   RAISE EXCEPTION 'written_criteria_unavailable' USING ERRCODE='42501';
 END IF;
 IF jsonb_typeof(v_req)<>'array' OR jsonb_array_length(v_req)=0
   OR EXISTS (SELECT 1 FROM jsonb_array_elements(v_req) x
      WHERE jsonb_typeof(x.value)<>'string'
        OR NULLIF(btrim(x.value #>> '{}'),'') IS NULL) THEN
   RAISE EXCEPTION 'written_criteria_unavailable' USING ERRCODE='22023';
 END IF;
 RETURN jsonb_build_object(
   'available',true,'task_key',p_task_key,'task_version',p_task_version,
   'title',CASE p_language
      WHEN 'ru' THEN 'Требования к ответу'
      WHEN 'uz' THEN 'Javobga qo‘yiladigan talablar'
      ELSE 'Answer requirements' END,
   'requirements',v_req);
END;
$function$;

CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_open_v1(p_item_id uuid, p_language text DEFAULT 'en'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid(); v_item record; v_question text;
BEGIN
 IF v_user IS NULL THEN
   RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501';
 END IF;
 IF p_language NOT IN ('ru','uz','en') OR p_item_id IS NULL THEN
   RAISE EXCEPTION 'written_request_invalid' USING ERRCODE='22023';
 END IF;
 SELECT i.id,i.task_token,i.task_key,i.task_version,i.status,i.program_key,
   i.version_key,i.plan_id,i.opened_at,t.paper_code,t.questions
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
   AND i.mode='practice'
 AND (i.status='advanced' OR NOT EXISTS (
  SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 earlier
  WHERE earlier.plan_id=i.plan_id AND earlier.priority_order<i.priority_order
    AND earlier.status='pending'
 ))
   AND pl.status='active'
   AND pg.integration_mode='native' AND pg.status='published' AND pg.launch_enabled
   AND t.status='approved' AND t.release_enabled
   AND t.academic_review='approved' AND t.language_review='approved'
     AND t.source_review='approved'
   AND ac.status='active' AND ac.core_access
   AND (ac.valid_from IS NULL OR ac.valid_from<=now())
   AND (ac.valid_until IS NULL OR ac.valid_until>now());
 IF NOT FOUND THEN
   RAISE EXCEPTION 'written_item_not_available' USING ERRCODE='42501';
 END IF;
 v_question:=NULLIF(btrim(v_item.questions->>p_language),'');
 IF v_question IS NULL THEN
   RAISE EXCEPTION 'written_content_unavailable' USING ERRCODE='22023';
 END IF;
 -- Idempotent opened timestamp, recorded solely as a navigation fact.
 UPDATE private.iclub_exam_core_written_plan_items_v1
 SET opened_at=COALESCE(opened_at,now())
 WHERE id=v_item.id AND opened_at IS NULL;
 RETURN jsonb_build_object(
   'task_kind','written_external','task_token',v_item.task_token::text,
   'task_key',v_item.task_key,'task_version',v_item.task_version,
   'plan_item_id',v_item.id::text,'program_key',v_item.program_key,
   'program_version',v_item.version_key,'paper_code',v_item.paper_code,
   'question',v_question,'runtime_enabled',true,'can_advance',true,
   'status',CASE WHEN v_item.status='advanced' THEN 'advanced' ELSE 'active' END
 );
END;
$function$;

CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_plan_next_v1(p_plan_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid(); v_program text; v_version text; v_item record;
BEGIN
 IF v_user IS NULL OR p_plan_id IS NULL THEN RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501'; END IF;
 SELECT pg.program_key,pg.version_key INTO v_program,v_version
 FROM private.iclub_exam_core_written_plans_v1 pl
 JOIN private.iclub_exam_core_programs_v1 pg ON pg.program_key=pl.program_key AND pg.version_key=pl.version_key
 JOIN private.iclub_exam_core_written_access_v1 ac ON ac.learner_user_id=pl.learner_user_id
  AND ac.program_key=pl.program_key AND ac.version_key=pl.version_key
 WHERE pl.id=p_plan_id AND pl.learner_user_id=v_user AND pl.status='active'
   AND pg.integration_mode='native' AND pg.status='published' AND pg.launch_enabled
   AND ac.core_access AND ac.status='active'
   AND (ac.valid_from IS NULL OR ac.valid_from<=now()) AND (ac.valid_until IS NULL OR ac.valid_until>now());
 IF NOT FOUND THEN RAISE EXCEPTION 'written_plan_unavailable' USING ERRCODE='42501'; END IF;
 SELECT i.id,i.priority_order,i.task_key,i.task_version,i.mode,t.status task_status,
  t.release_enabled,t.academic_review,t.language_review,t.source_review,t.paper_code
 INTO v_item
 FROM private.iclub_exam_core_written_plan_items_v1 i
 JOIN private.iclub_exam_core_written_tasks_v1 t ON t.program_key=i.program_key
  AND t.version_key=i.version_key AND t.task_key=i.task_key AND t.task_version=i.task_version
 WHERE i.plan_id=p_plan_id AND i.learner_user_id=v_user
  AND i.program_key=v_program AND i.version_key=v_version AND i.status='pending'
 ORDER BY i.priority_order LIMIT 1;
 IF NOT FOUND THEN RETURN jsonb_build_object('status','completed','plan_id',p_plan_id::text,
   'program_key',v_program,'program_version',v_version); END IF;
 IF v_item.mode<>'practice' OR v_item.task_status<>'approved'
  OR NOT v_item.release_enabled OR v_item.academic_review<>'approved'
  OR v_item.language_review<>'approved' OR v_item.source_review<>'approved' THEN
  RAISE EXCEPTION 'written_next_item_unavailable' USING ERRCODE='42501';
 END IF;
 RETURN jsonb_build_object('status','ready','plan_id',p_plan_id::text,
  'program_key',v_program,'program_version',v_version,
  'plan_item_id',v_item.id::text,'priority_order',v_item.priority_order,
  'task_key',v_item.task_key,'task_version',v_item.task_version,'paper_code',v_item.paper_code);
END;
$function$;

REVOKE ALL ON FUNCTION private.iclub_exam_core_written_plan_next_v1(uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION private.iclub_exam_core_written_plan_next_v1(uuid) TO service_role;
