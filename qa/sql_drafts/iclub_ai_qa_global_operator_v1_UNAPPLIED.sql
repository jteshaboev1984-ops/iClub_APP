-- Protected QA Global AI pilot: separate authorization from existing live
-- Mathematics Exam Prep, Practice AI and all learner data.
-- Default: no enabled users and no paid requests.
CREATE TABLE IF NOT EXISTS private.iclub_ai_qa_global_operator_v1 (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
 enabled boolean NOT NULL DEFAULT false,
 admitted_at timestamptz NOT NULL DEFAULT now(),
 note text NOT NULL DEFAULT 'approved operator QA only'
);
ALTER TABLE private.iclub_ai_qa_global_operator_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_qa_global_operator_v1
 FROM PUBLIC,anon,authenticated,service_role;
CREATE OR REPLACE FUNCTION public.authorize_iclub_ai_qa_global_operator_v1(
 p_user_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $func$
DECLARE money_enabled boolean;
BEGIN
 IF current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'service_role'
 OR p_user_id IS NULL THEN
  RETURN jsonb_build_object('allowed',false,'reason','operator_only');
 END IF;
 IF NOT EXISTS (SELECT 1 FROM private.iclub_ai_qa_global_operator_v1
   WHERE user_id=p_user_id AND enabled=true) THEN
  RETURN jsonb_build_object('allowed',false,'reason','operator_not_enrolled');
 END IF;
 SELECT enabled INTO money_enabled
 FROM private.iclub_ai_paid_canary_control_v1 WHERE singleton=1;
 RETURN jsonb_build_object('allowed',true,
   'money_enabled',coalesce(money_enabled,false),
   'route','public_app_help_qa_only');
END;
$func$;
REVOKE ALL ON FUNCTION public.authorize_iclub_ai_qa_global_operator_v1(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.authorize_iclub_ai_qa_global_operator_v1(uuid)
 TO service_role;
