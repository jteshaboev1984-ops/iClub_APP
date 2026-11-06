-- Mathematics optional Extra Hard catalog: per-owner attempt state and official section.
-- No release/config/content/learner writes; compatible with 12/24/42 protected tasks.
BEGIN;
DO $guard$ DECLARE v text; BEGIN
 SELECT pg_get_functiondef('public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text)'::regprocedure) INTO v;
 IF position('private.exam_prep_require_core_access_v1()' in v)=0
 OR position('t.bank_version=v_control.bank_version' in v)=0
 OR has_function_privilege('anon','public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Extra Hard catalog source, owner or ACL changed'; END IF;
END $guard$;
CREATE OR REPLACE FUNCTION public.get_my_exam_prep_extra_hard_catalog_safe_v1(
 p_component_code text,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
 v_uid uuid;
 v_program bigint;
 v_control private.exam_prep_extra_hard_release_v1%ROWTYPE;
 v_items jsonb:='[]'::jsonb;
 v_done int:=0;
 v_started int:=0;
 v_lang text:=lower(coalesce(p_language,'en'));
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_component_code NOT IN ('P1','P5') OR v_lang NOT IN ('en','ru','uz')
 THEN RAISE EXCEPTION 'exam_prep_extra_hard_bad_component_or_language' USING ERRCODE='22023'; END IF;
 SELECT id INTO v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active' ORDER BY id DESC LIMIT 1;
 SELECT * INTO v_control FROM private.exam_prep_extra_hard_release_v1
 WHERE program_key='math_as_p1_p5';
 IF v_program IS NULL OR NOT coalesce(v_control.enabled,false)
     OR NOT coalesce(v_control.academic_approved,false) THEN
  RETURN jsonb_build_object('available',false,'component_code',p_component_code,
    'items','[]'::jsonb,'reason_code','content_preparing','noncredit',true);
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'task_key',t.task_key,'title',t.title_i18n->>v_lang,
  'primary_skill_code',t.primary_skill_code,'official_section',t.official_section,
  'attempt_status',coalesce(a.status,'not_started'),'noncredit',true
 ) ORDER BY t.official_section,t.task_key),'[]'::jsonb) INTO v_items
 FROM private.exam_prep_extra_hard_tasks_v1 t
 LEFT JOIN private.exam_prep_extra_hard_attempts_v1 a ON a.task_key=t.task_key AND a.user_id=v_uid
 WHERE t.program_version_id=v_program AND t.component_code=p_component_code
 AND t.bank_version=v_control.bank_version AND t.lifecycle_status='published'
 AND t.qa_math='approved' AND t.qa_languages='approved'
 AND t.qa_technical='approved' AND t.content_sha256 IS NOT NULL;
 SELECT count(*) filter(where e.obj->>'attempt_status'='submitted')::int,
  count(*) filter(where e.obj->>'attempt_status'='started')::int
 INTO v_done,v_started FROM jsonb_array_elements(v_items) e(obj);
 RETURN jsonb_build_object('available',jsonb_array_length(v_items)>0,
   'component_code',p_component_code,'items',v_items,'noncredit',true,
   'total_count',jsonb_array_length(v_items),'completed_count',v_done,'in_progress_count',v_started,
   'reason_code',CASE WHEN jsonb_array_length(v_items)>0 THEN 'ready' ELSE 'content_preparing' END);
END;
$$;


REVOKE ALL ON FUNCTION public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text) TO authenticated,service_role;
COMMIT;
