-- Test fixture ONLY: the existing full-migrations runner predates the
-- separately published Extra Hard RPC API (present on live Supabase but not
-- reproduced by its *exam_prep*.sql replay). These two restricted stub
-- signatures allow source-contract installation on disposable PG17; they
-- NEVER serve task content or pretend to verify Extra Hard functional tests.
-- Never copy to supabase/migrations, production or source bank.
DO $guard$
BEGIN
 IF current_database()<>'postgres' OR
    current_setting('iclub.e2e_isolated',true)<>'true' OR
    to_regprocedure('public.start_my_exam_prep_extra_hard_safe_v1(text,text)') IS NOT NULL OR
    to_regprocedure('public.submit_my_exam_prep_extra_hard_safe_v1(uuid,text,text,text)') IS NOT NULL
 THEN RAISE EXCEPTION 'P0-16B fixture refused outside missing-function disposable PG17'; END IF;
END
$guard$;
CREATE FUNCTION public.start_my_exam_prep_extra_hard_safe_v1(
 p_task_key text, p_language text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 RAISE EXCEPTION 'p016b_disposable_extra_hard_functional_stub_no_content';
END
$f$;
CREATE FUNCTION public.submit_my_exam_prep_extra_hard_safe_v1(
 p_attempt_id uuid,p_response_text text,p_idempotency_key text,p_language text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_uid uuid;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 RAISE EXCEPTION 'p016b_disposable_extra_hard_functional_stub_no_content';
END
$f$;
REVOKE ALL ON FUNCTION public.start_my_exam_prep_extra_hard_safe_v1(text,text)
 FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.submit_my_exam_prep_extra_hard_safe_v1(uuid,text,text,text)
 FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.start_my_exam_prep_extra_hard_safe_v1(text,text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_my_exam_prep_extra_hard_safe_v1(uuid,text,text,text)
 TO authenticated;
