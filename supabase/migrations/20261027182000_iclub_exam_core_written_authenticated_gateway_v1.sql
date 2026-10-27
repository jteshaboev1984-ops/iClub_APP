-- Universal Exam Prep written learner gateway, based on Written Learning Contract v1.3.
-- Public functions delegate exclusively to the already-reviewed private written core.
-- All current P2/P4 and practical content remains DRAFT and invisible.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='65s';

CREATE OR REPLACE FUNCTION public.iclub_exam_written_available_v1(
  p_program_key text, p_version_key text
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid(); v_plan uuid; v_item uuid;
BEGIN
 IF v_user IS NULL OR p_program_key IS NULL OR p_version_key IS NULL
    OR length(p_program_key)>128 OR length(p_version_key)>128
 THEN RETURN jsonb_build_object('ok',false,'available',false); END IF;

 SELECT pl.id,i.id INTO v_plan,v_item
 FROM private.iclub_exam_core_written_plans_v1 pl
 JOIN private.iclub_exam_core_programs_v1 pg
 ON pg.program_key=pl.program_key AND pg.version_key=pl.version_key
 JOIN private.iclub_exam_core_written_access_v1 ac
 ON ac.learner_user_id=pl.learner_user_id
 AND ac.program_key=pl.program_key AND ac.version_key=pl.version_key
 JOIN private.iclub_exam_core_written_plan_items_v1 i
 ON i.plan_id=pl.id AND i.learner_user_id=pl.learner_user_id
 AND i.program_key=pl.program_key AND i.version_key=pl.version_key
 JOIN private.iclub_exam_core_written_tasks_v1 t
 ON t.program_key=i.program_key AND t.version_key=i.version_key
 AND t.task_key=i.task_key AND t.task_version=i.task_version
 WHERE pl.learner_user_id=v_user AND pl.program_key=p_program_key
 AND pl.version_key=p_version_key AND pl.status='active'
 AND pg.integration_mode='native' AND pg.status='published' AND pg.launch_enabled
 AND ac.status='active' AND ac.core_access
 AND (ac.valid_from IS NULL OR ac.valid_from<=now())
 AND (ac.valid_until IS NULL OR ac.valid_until>now())
 AND i.status='pending' AND i.mode='practice'
 AND t.status='approved' AND t.release_enabled
 AND t.academic_review='approved' AND t.language_review='approved'
 AND t.source_review='approved'
 AND NOT EXISTS (
   SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 earlier
   WHERE earlier.plan_id=i.plan_id AND earlier.priority_order<i.priority_order
   AND earlier.status='pending'
 )
 ORDER BY pl.created_at DESC,i.priority_order
 LIMIT 1;

 IF NOT FOUND THEN RETURN jsonb_build_object('ok',true,'available',false); END IF;
 RETURN jsonb_build_object('ok',true,'available',true,'plan_id',v_plan::text);
END;
$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_written_next_v1(
 p_plan_id uuid
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
BEGIN
 IF auth.uid() IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 RETURN private.iclub_exam_core_written_plan_next_v1(p_plan_id);
END;$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_written_open_v1(
 p_item_id uuid,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
BEGIN
 IF auth.uid() IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 RETURN private.iclub_exam_core_written_open_v1(p_item_id,p_language);
END;$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_written_criteria_v1(
 p_item_id uuid,p_task_key text,p_task_version text,p_task_token uuid,
 p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
BEGIN
 IF auth.uid() IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 RETURN private.iclub_exam_core_written_criteria_v1(
   p_item_id,p_task_key,p_task_version,p_task_token,p_language);
END;$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_written_advance_v1(
 p_item_id uuid,p_task_key text,p_task_version text,p_task_token uuid,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
BEGIN
 IF auth.uid() IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 RETURN private.iclub_exam_core_written_advance_v1(
   p_item_id,p_task_key,p_task_version,p_task_token,p_idempotency_key);
END;$f$;

-- The private status operation only checks ownership; the public gateway adds
-- full active access + QA gates so revocation cannot become an information leak.
CREATE OR REPLACE FUNCTION public.iclub_exam_written_status_v1(
 p_item_id uuid,p_task_key text,p_task_version text,p_task_token uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
BEGIN
 IF v_user IS NULL OR p_item_id IS NULL OR p_task_key IS NULL
   OR p_task_version IS NULL OR p_task_token IS NULL
 THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 IF NOT EXISTS(
   SELECT 1
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
    AND pg.integration_mode='native' AND pg.status='published' AND pg.launch_enabled
    AND t.status='approved' AND t.release_enabled
    AND t.academic_review='approved' AND t.language_review='approved'
    AND t.source_review='approved'
    AND ac.status='active' AND ac.core_access
    AND (ac.valid_from IS NULL OR ac.valid_from<=now())
    AND (ac.valid_until IS NULL OR ac.valid_until>now())
 ) THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 RETURN private.iclub_exam_core_written_status_v1(
   p_item_id,p_task_key,p_task_version,p_task_token);
END;$f$;

REVOKE ALL ON FUNCTION public.iclub_exam_written_available_v1(text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_written_next_v1(uuid) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_written_open_v1(uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_written_advance_v1(uuid,text,text,uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_written_status_v1(uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_available_v1(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_next_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_open_v1(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_advance_v1(uuid,text,text,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_status_v1(uuid,text,text,uuid) TO authenticated;

DO $safety$
DECLARE n int;
BEGIN
 SELECT count(*) INTO n FROM private.iclub_exam_core_written_tasks_v1
  WHERE release_enabled AND status='approved';
 IF n<>0 OR (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1)<>0
   OR (SELECT count(*) FROM private.iclub_exam_core_written_access_v1)<>0
   OR (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1)<>0
   OR (SELECT count(*) FROM private.exam_prep_program_versions
      WHERE program_key='math_as_p1_p5' AND status='active')<>1
 THEN RAISE EXCEPTION 'Written beta baseline changed; manual review required'; END IF;
 IF has_function_privilege('anon','public.iclub_exam_written_available_v1(text,text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_written_advance_v1(uuid,text,text,uuid,text)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_core_written_tasks_v1','SELECT')
 THEN RAISE EXCEPTION 'Written student privileges unsafe'; END IF;
END $safety$;
COMMIT;