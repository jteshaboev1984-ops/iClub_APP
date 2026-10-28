-- J10 independent recheck learner gate and exact 22-item owner-approved preflight.
-- A completed J07 ENTRY and a visible matching Chemistry Theory package are mandatory.
CREATE FUNCTION private.iclub_exam_chemistry_recheck_student_authorized_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 SELECT private.iclub_exam_chemistry_entry_student_authorized_v1()
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_recheck_control_v1 c
  WHERE c.id=1 AND c.enabled AND c.owner_go_at IS NOT NULL
  AND length(c.release_version)>=12 AND c.approved_manifest_md5 IS NOT NULL)
 AND EXISTS(SELECT 1 FROM private.iclub_subject_library l
  WHERE l.subject_key='chemistry' AND l.visible_to_learners
  AND l.active_version='chemistry9701_20261022_stageb_draft');
$f$;
CREATE FUNCTION private.iclub_exam_chemistry_recheck_manifest_ok_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 WITH authorized_rows AS(
 SELECT r.id,r.syllabus_unit,r.item_md5
 FROM private.iclub_exam_chemistry_recheck_items_v1 r
 JOIN private.iclub_exam_chemistry_recheck_release_items_v1 a
 ON a.item_id=r.id AND a.item_md5=r.item_md5
 JOIN private.iclub_exam_chemistry_recheck_control_v1 c
 ON c.id=1 AND c.enabled AND a.release_version=c.release_version
 JOIN private.iclub_exam_chemistry_recheck_preflight_v1 pf ON pf.id=r.id
 WHERE pf.seven_internal_AI_reviews AND pf.different_from_entry_stem
 AND pf.different_from_P1_stem AND pf.unreleased_no_mastery
 AND r.review_status='internal_ai_reviewed' AND r.reviewer_type='internal_ai'
 AND r.item_md5=md5(r.item_json::text)
 )
 SELECT (SELECT count(*)=22 AND count(DISTINCT syllabus_unit)=22 FROM authorized_rows)
 AND (SELECT md5(string_agg(id||'|'||item_md5,';' ORDER BY syllabus_unit)) FROM authorized_rows)
 = (SELECT approved_manifest_md5 FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1);
$f$;
CREATE FUNCTION public.get_my_exam_prep_chemistry_recheck_shell_v1(
 p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE latest uuid;
BEGIN
 IF p_language IS NULL OR p_language NOT IN('ru','uz','en')
 OR auth.uid() IS NULL
 OR NOT private.iclub_exam_chemistry_recheck_student_authorized_v1()
 OR NOT private.iclub_exam_chemistry_recheck_manifest_ok_v1()
 THEN RETURN '{}'::jsonb; END IF;
 SELECT s.id INTO latest FROM private.iclub_exam_chemistry_entry_attempts_v1 s
 WHERE s.user_id=auth.uid() AND s.status='finalized' AND s.finalized_at IS NOT NULL
 ORDER BY s.finalized_at DESC LIMIT 1;
 IF latest IS NULL THEN RETURN '{}'::jsonb; END IF;
 RETURN jsonb_build_object(
 'enabled',true,'program_key','chemistry_9701','assessment_code','RECHECK',
 'entry_session_id',latest,'item_count',22,'duration_seconds',1800,
 'can_credit_mastery',false,'calibrated_diagnostic',false,
 'learning_ack_kind','self_report','language',p_language);
END $f$;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_recheck_student_authorized_v1()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_recheck_manifest_ok_v1()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_chemistry_recheck_shell_v1(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_chemistry_recheck_shell_v1(text)
 TO authenticated;
DO $test$ BEGIN
 IF public.get_my_exam_prep_chemistry_recheck_shell_v1('ru')<>'{}'::jsonb
 OR has_function_privilege('anon','public.get_my_exam_prep_chemistry_recheck_shell_v1(text)','EXECUTE')
 OR (SELECT enabled FROM private.iclub_exam_chemistry_recheck_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'J10 shell unexpectedly open'; END IF;
END $test$;