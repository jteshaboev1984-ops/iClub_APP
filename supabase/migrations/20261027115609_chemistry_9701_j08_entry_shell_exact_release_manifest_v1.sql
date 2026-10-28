-- J08 owner manifest preflight: fail closed before showing ENTRY screen.
-- A bare enabled=true is never sufficient to show a diagnostic with unapproved items.
CREATE OR REPLACE FUNCTION public.get_my_exam_prep_chemistry_entry_shell_v1(p_language text DEFAULT 'ru')
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE approved_n integer;units_n integer;source_hash text;owner_hash text;
BEGIN
 IF p_language IS NULL OR p_language NOT IN('ru','uz','en')
 OR NOT private.iclub_exam_chemistry_entry_student_authorized_v1()
 THEN RETURN '{}'::jsonb; END IF;
 SELECT count(*),count(DISTINCT d.syllabus_unit),
 md5(string_agg(d.id||'|'||d.item_md5,';' ORDER BY d.syllabus_unit))
 INTO approved_n,units_n,source_hash
 FROM private.iclub_exam_chemistry_entry_items_v1 d
 JOIN private.iclub_exam_chemistry_entry_release_items_v1 a
 ON a.item_id=d.id AND a.item_md5=d.item_md5
 JOIN private.iclub_exam_chemistry_entry_release_v1 c
 ON c.id=1 AND c.enabled=true AND c.release_version=a.release_version
 JOIN private.iclub_exam_chemistry_entry_study_links_v1 links
 ON links.private_entry_id=d.id
 WHERE links.AI_review_complete AND links.seven_review_gates
 AND links.syllabus_skill_link AND links.trilingual_theory_link
 AND links.trilingual_tutor_link AND links.distinct_from_exam_blueprint
 AND links.unreleased AND d.item_md5=md5(d.item_json::text);
 SELECT approved_manifest_md5 INTO owner_hash
 FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1;
 IF approved_n<>22 OR units_n<>22 OR source_hash IS DISTINCT FROM owner_hash
 THEN RETURN '{}'::jsonb; END IF;
 RETURN jsonb_build_object('enabled',true,'program_key','chemistry_9701',
 'assessment_code','ENTRY','duration_seconds',1800,'item_count',22,
 'language',p_language,'can_credit_mastery',false,
 'calibrated_diagnostic',false);
END $f$;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_chemistry_entry_shell_v1(text)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_chemistry_entry_shell_v1(text)
TO authenticated;
DO $qa$ BEGIN
 IF public.get_my_exam_prep_chemistry_entry_shell_v1('ru')<>'{}'::jsonb
 OR has_function_privilege('anon',
 'public.get_my_exam_prep_chemistry_entry_shell_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Diagnostic must fail closed'; END IF;
END $qa$;