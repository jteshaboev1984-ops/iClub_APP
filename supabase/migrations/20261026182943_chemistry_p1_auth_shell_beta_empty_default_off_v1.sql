-- Applied to Supabase as version 20261026182943, user beta empty by default.
-- Authenticated shell is intentionally empty until explicit owner GO/consent/subject/program release.
CREATE TABLE private.iclub_exam_chemistry_p1_beta_control_v1(
 id smallint PRIMARY KEY CHECK(id=1),
 enabled boolean NOT NULL DEFAULT false,
 owner_go_at timestamptz,
 approved_content_manifest text,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK((enabled=false AND owner_go_at IS NULL)
 OR (enabled=true AND owner_go_at IS NOT NULL
 AND length(approved_content_manifest)>=24))
);
INSERT INTO private.iclub_exam_chemistry_p1_beta_control_v1(id,enabled) VALUES(1,false);
CREATE TABLE private.iclub_exam_chemistry_p1_beta_members_v1(
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
 consented_at timestamptz,
 owner_approved_at timestamptz,
 revoked_at timestamptz,
 active boolean NOT NULL DEFAULT false,
 joined_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(active=false OR (consented_at IS NOT NULL
 AND owner_approved_at IS NOT NULL AND revoked_at IS NULL))
);
ALTER TABLE private.iclub_exam_chemistry_p1_beta_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_beta_members_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_beta_control_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_p1_beta_members_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_p1_beta_control_v1 FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON private.iclub_exam_chemistry_p1_beta_members_v1 FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON private.iclub_exam_chemistry_p1_beta_control_v1 TO service_role;
GRANT SELECT ON private.iclub_exam_chemistry_p1_beta_members_v1 TO service_role;

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_student_authorized_v1()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_control_v1 b
 WHERE b.id=1 AND b.enabled=true AND b.owner_go_at IS NOT NULL
 AND b.approved_content_manifest IS NOT NULL)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_members_v1 m
 WHERE m.user_id=auth.uid() AND m.active=true AND m.revoked_at IS NULL
 AND m.consented_at IS NOT NULL AND m.owner_approved_at IS NOT NULL)
 AND EXISTS(SELECT 1 FROM public.user_subjects us
 JOIN public.subjects s ON s.id=us.subject_id
 WHERE us.user_id=auth.uid() AND s.subject_key='chemistry'
 AND s.is_active=true)
 AND EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 p
 JOIN private.iclub_exam_core_papers_v1 paper
 ON paper.program_key=p.program_key AND paper.version_key=p.version_key
 WHERE p.program_key='chemistry_9701'
 AND p.version_key='chemistry_2025_2027_v1'
 AND p.integration_mode='native' AND p.status='published'
 AND p.launch_enabled=true AND paper.paper_code='P1' AND paper.status='published'
 AND paper.level_code='AS' AND paper.assessment_kind='mcq'
 AND paper.mcq_count=40 AND paper.duration_seconds=4500);
$function$;

CREATE OR REPLACE FUNCTION public.get_my_exam_prep_chemistry_shell_v1(p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_title text;
BEGIN
 IF p_language IS NULL OR p_language NOT IN ('ru','uz','en') OR
 NOT private.iclub_exam_chemistry_p1_student_authorized_v1()
 THEN RETURN '{}'::jsonb; END IF;
 v_title:=CASE p_language WHEN 'ru' THEN 'Подготовка к Cambridge AS Chemistry'
 WHEN 'uz' THEN 'Cambridge AS Chemistry imtihoniga tayyorgarlik'
 ELSE 'Cambridge AS Chemistry Exam Prep' END;
 RETURN jsonb_build_object(
 'contract_version','exam_prep_shared_host_v1',
 'enabled',true,'program_key','chemistry_9701',
 'version_key','chemistry_2025_2027_v1',
 'subject_key','chemistry','title',v_title,
 'papers',jsonb_build_array(jsonb_build_object(
 'code','P1','level','AS','assessment_kind','mcq',
 'mcq_count',40,'duration_seconds',4500,'total_marks',40)),
 'core_access',true,'ai_assist',false,'mentor_care',false);
END $function$;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_student_authorized_v1()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_chemistry_shell_v1(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_chemistry_shell_v1(text) TO authenticated;
DO $qa$ BEGIN
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE enabled=false)<>1
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_beta_members_v1)<>0
 THEN RAISE EXCEPTION 'Chemistry beta must remain OFF and empty'; END IF;
 IF public.get_my_exam_prep_chemistry_shell_v1('ru')<>'{}'::jsonb
 THEN RAISE EXCEPTION 'Premature Chemistry access'; END IF;
 IF has_function_privilege('anon','public.get_my_exam_prep_chemistry_shell_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Anon chemistry access leak'; END IF;
END $qa$;
