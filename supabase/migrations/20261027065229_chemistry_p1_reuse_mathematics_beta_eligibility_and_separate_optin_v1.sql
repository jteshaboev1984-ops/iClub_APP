-- Chemistry J-03: reuse real Mathematics controlled-beta cohort for eligibility.
-- No account duplication. The 3 existing active Maths beta members remain unchanged.
-- Chemistry consent is separate; programme and entire Chemistry beta stay OFF.
DO $pre$
BEGIN
 IF to_regprocedure('private.iclub_exam_chemistry_p1_math_beta_eligible_v1(uuid)') IS NOT NULL
 OR to_regprocedure('public.grant_my_exam_prep_chemistry_consent_v1(text)') IS NOT NULL
 OR to_regprocedure('public.revoke_my_exam_prep_chemistry_consent_v1()') IS NOT NULL
 THEN RAISE EXCEPTION 'Math cohort Chemistry bridge is already installed'; END IF;
 IF (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_beta_members_v1)<>0
 OR (SELECT COUNT(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 OR (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'Never bridge cohorts after Chemistry has been enabled or enrolled'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_beta_cohorts
 WHERE cohort_key='math_as_p1_p5_beta_2026_09_01'
 AND program_key='math_as_p1_p5' AND cohort_status='canary')
 THEN RAISE EXCEPTION 'Existing Mathematics cohort changed; investigate before linking'; END IF;
END $pre$;

CREATE FUNCTION private.iclub_exam_chemistry_p1_math_beta_eligible_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 SELECT p_user_id IS NOT NULL AND EXISTS (
   SELECT 1 FROM private.exam_prep_beta_cohorts c
   JOIN private.exam_prep_beta_members m ON m.cohort_id=c.id
   JOIN private.exam_prep_beta_consents b
    ON b.cohort_id=c.id AND b.user_id=m.user_id
   WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
     AND c.program_key='math_as_p1_p5'
     AND c.cohort_status IN ('canary','active')
     AND m.user_id=p_user_id AND m.member_status='active'
     AND m.activated_at IS NOT NULL
     AND b.consent_scope='exam_prep_controlled_beta_v1'
     AND b.consent_status='granted' AND b.revoked_at IS NULL
 ) AND EXISTS (
   SELECT 1 FROM public.user_subjects us
   JOIN public.subjects s ON s.id=us.subject_id
   WHERE us.user_id=p_user_id AND s.subject_key='chemistry'
   AND s.is_active=true
 );
$f$;

CREATE OR REPLACE FUNCTION private.iclub_exam_chemistry_p1_student_authorized_v1()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 SELECT auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
 AND private.iclub_exam_chemistry_p1_math_beta_eligible_v1(auth.uid())
 AND EXISTS(
   SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_control_v1 b
   WHERE b.id=1 AND b.enabled=true AND b.owner_go_at IS NOT NULL
   AND b.approved_content_manifest IS NOT NULL
 )
 AND EXISTS(
   SELECT 1 FROM private.iclub_exam_chemistry_p1_beta_members_v1 m
   WHERE m.user_id=auth.uid() AND m.active=true
   AND m.consented_at IS NOT NULL AND m.owner_approved_at IS NOT NULL
   AND m.revoked_at IS NULL
 )
 AND EXISTS(
   SELECT 1 FROM private.iclub_exam_core_programs_v1 p
   JOIN private.iclub_exam_core_papers_v1 paper
   ON paper.program_key=p.program_key AND paper.version_key=p.version_key
   WHERE p.program_key='chemistry_9701'
   AND p.version_key='chemistry_2025_2027_v1'
   AND p.integration_mode='native' AND p.status='published'
   AND p.launch_enabled=true AND paper.paper_code='P1'
   AND paper.status='published' AND paper.level_code='AS'
   AND paper.assessment_kind='mcq'
   AND paper.mcq_count=40 AND paper.duration_seconds=4500
 );
$f$;

CREATE FUNCTION public.grant_my_exam_prep_chemistry_consent_v1(p_acknowledgement text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
BEGIN
 IF v_user IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
 OR coalesce(auth.jwt()->>'is_anonymous','false')='true'
 THEN RETURN jsonb_build_object('ok',false,'code','sign_in_required'); END IF;
 IF p_acknowledgement IS DISTINCT FROM 'I_CONSENT_TO_CHEMISTRY_P1_CONTROLLED_BETA_V1'
 THEN RETURN jsonb_build_object('ok',false,'code','consent_required'); END IF;
 IF NOT private.iclub_exam_chemistry_p1_math_beta_eligible_v1(v_user)
 THEN RETURN jsonb_build_object('ok',false,'code','not_eligible'); END IF;
 -- Existing Maths membership is reused. This single Chemistry row is a
 -- revocable, *pending* Chemistry-specific consent; never an automatic admission.
 INSERT INTO private.iclub_exam_chemistry_p1_beta_members_v1
 (user_id,consented_at,owner_approved_at,revoked_at,active)
 VALUES(v_user,clock_timestamp(),NULL,NULL,false)
 ON CONFLICT(user_id) DO UPDATE
 SET consented_at=clock_timestamp(),owner_approved_at=NULL,
 revoked_at=NULL,active=false;
 RETURN jsonb_build_object('ok',true,'chemistry_consent','recorded',
 'beta_access','pending_owner_release');
END $f$;

CREATE FUNCTION public.revoke_my_exam_prep_chemistry_consent_v1()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
BEGIN
 IF v_user IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
 THEN RETURN jsonb_build_object('ok',false,'code','sign_in_required'); END IF;
 -- Revocation is always available, even if the Maths cohort is later paused.
 UPDATE private.iclub_exam_chemistry_p1_beta_members_v1
 SET active=false,revoked_at=clock_timestamp()
 WHERE user_id=v_user AND consented_at IS NOT NULL AND revoked_at IS NULL;
 RETURN jsonb_build_object('ok',true,'chemistry_consent','revoked',
 'beta_access','off');
END $f$;

REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_math_beta_eligible_v1(uuid)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.iclub_exam_chemistry_p1_student_authorized_v1()
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.grant_my_exam_prep_chemistry_consent_v1(text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.revoke_my_exam_prep_chemistry_consent_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.grant_my_exam_prep_chemistry_consent_v1(text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_my_exam_prep_chemistry_consent_v1()
 TO authenticated;

DO $post$
DECLARE v_active integer;v_candidates integer;
BEGIN
 SELECT count(DISTINCT m.user_id),
 count(DISTINCT m.user_id) FILTER(WHERE EXISTS(
   SELECT 1 FROM public.user_subjects us
   JOIN public.subjects s ON s.id=us.subject_id
   WHERE us.user_id=m.user_id AND s.subject_key='chemistry'
   AND s.is_active=true))
 INTO v_active,v_candidates
 FROM private.exam_prep_beta_members m
 JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
 JOIN private.exam_prep_beta_consents b ON b.cohort_id=c.id AND b.user_id=m.user_id
 WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
 AND m.member_status='active' AND m.activated_at IS NOT NULL
 AND b.consent_status='granted' AND b.revoked_at IS NULL;
 IF v_active<>3 OR v_candidates<>2
 THEN RAISE EXCEPTION 'Mathematics beta cohort counts unexpectedly changed: % / %',v_active,v_candidates; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_p1_beta_members_v1)<>0
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_p1_live_attempts_v1)<>0
 THEN RAISE EXCEPTION 'User rows appeared during eligibility setup'; END IF;
 IF private.iclub_exam_chemistry_p1_student_authorized_v1()
 OR public.get_my_exam_prep_chemistry_shell_v1('ru')<>'{}'::jsonb
 THEN RAISE EXCEPTION 'Chemistry accidentally opened'; END IF;
 IF has_function_privilege('anon','public.grant_my_exam_prep_chemistry_consent_v1(text)','EXECUTE')
 OR has_function_privilege('anon','public.revoke_my_exam_prep_chemistry_consent_v1()','EXECUTE')
 OR has_function_privilege('authenticated',
 'private.iclub_exam_chemistry_p1_math_beta_eligible_v1(uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'Cohort rights exposed'; END IF;
END $post$;