-- Chemistry J-03: self-visible eligibility/consent state for existing Mathematics beta testers.
-- This is an offer, NOT an enabled Chemistry exam shell or an exam start endpoint.
DO $pre$ BEGIN
 IF to_regprocedure('public.get_my_exam_prep_chemistry_beta_status_v1()') IS NOT NULL
 THEN RAISE EXCEPTION 'Chemistry beta status RPC already exists'; END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) IS DISTINCT FROM false
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_p1_beta_members_v1)<>0
 THEN RAISE EXCEPTION 'Beta control unexpectedly open/has real opt-ins'; END IF;
END $pre$;
CREATE FUNCTION public.get_my_exam_prep_chemistry_beta_status_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();v_optin boolean:=false;v_revoked boolean:=false;
BEGIN
 IF v_user IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
 OR coalesce(auth.jwt()->>'is_anonymous','false')='true'
 THEN RETURN jsonb_build_object('eligible',false,'consented',false,'can_start',false); END IF;
 SELECT coalesce(consented_at IS NOT NULL AND revoked_at IS NULL,false),
 coalesce(revoked_at IS NOT NULL,false)
 INTO v_optin,v_revoked
 FROM private.iclub_exam_chemistry_p1_beta_members_v1 WHERE user_id=v_user;
 RETURN jsonb_build_object(
 'eligible',private.iclub_exam_chemistry_p1_math_beta_eligible_v1(v_user),
 'consented',coalesce(v_optin,false),
 'revoked',coalesce(v_revoked,false),
 'can_start',private.iclub_exam_chemistry_p1_student_authorized_v1(),
 'program_key','chemistry_9701','paper_code','P1');
END $f$;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_chemistry_beta_status_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_chemistry_beta_status_v1()
 TO authenticated;
DO $post$ BEGIN
 IF has_function_privilege('anon','public.get_my_exam_prep_chemistry_beta_status_v1()','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_my_exam_prep_chemistry_beta_status_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'Beta status privileges unsafe'; END IF;
 IF public.get_my_exam_prep_chemistry_beta_status_v1()->>'can_start' <> 'false'
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_p1_beta_members_v1)<>0
 THEN RAISE EXCEPTION 'Chemistry unexpectedly enabled or opted in'; END IF;
END $post$;