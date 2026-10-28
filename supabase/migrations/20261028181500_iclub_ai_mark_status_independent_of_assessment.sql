-- Current-screen-only AI Tutor icon: remove session/assessment state from
-- BETA STATUS only. Client owns icon visibility for active screen.
-- Server-owned Practice/Tour/Exam Prep request authorization is unchanged.
-- No user, quota, receipt, assessment or academic-data writes.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';
DO $pre$
BEGIN
 IF strpos(pg_get_functiondef('public.get_iclub_ai_v21_beta_status_service(uuid)'::regprocedure),
   'AND (NOT protected OR (')=0
 OR (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled
     AND NOT generation_enabled AND approved_release<>'none')
 THEN RAISE EXCEPTION 'Unexpected beta status revision or rollout controls'; END IF;
END $pre$;
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_beta_status_service(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 m private.iclub_ai_v21_beta_members%rowtype;
 c private.iclub_ai_v21_beta_control%rowtype;
 ready boolean:=false;
BEGIN
 IF p_user_id IS NULL THEN
  RETURN jsonb_build_object('ok',true,'candidate',false,'consented',false,
     'eligible',false,'preparedOnly',true); END IF;
 SELECT * INTO m FROM private.iclub_ai_v21_beta_members
 WHERE user_id=p_user_id;
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control WHERE singleton=1;
 SELECT EXISTS(
  SELECT 1 FROM private.iclub_ai_v21_beta_help_sources
  WHERE published AND NOT revoked AND rights_reviewed
  AND content_reviewed AND locale_reviewed AND approved_at IS NOT NULL
 ) INTO ready;
 RETURN jsonb_build_object('ok',true,
  'candidate',m.user_id IS NOT NULL,
  'consented',coalesce(m.consent_version='global_ai_beta_v21'
   AND m.consent_at IS NOT NULL,false),
  'eligible',coalesce(c.beta_enabled,false)
   AND coalesce(c.prepared_enabled,false)
   AND NOT coalesce(c.generation_enabled,true)
   AND coalesce(c.approved_release,'none')<>'none'
   AND coalesce(m.enabled,false)
   AND m.consent_version='global_ai_beta_v21'
   AND m.consent_at IS NOT NULL
   AND ready,
  'preparedOnly',true);
END $function$;
DO $post$
DECLARE allowed_count int; pending_count int;
BEGIN
 SELECT count(*) INTO allowed_count FROM private.iclub_ai_practice_beta_grants_v1 g
 JOIN private.iclub_ai_v21_beta_members m ON m.user_id=g.user_id
 WHERE g.enabled AND m.enabled AND m.consent_at IS NOT NULL
 AND (public.get_iclub_ai_v21_beta_status_service(g.user_id)->>'eligible')::boolean;
 SELECT count(*) INTO pending_count FROM private.iclub_ai_practice_beta_grants_v1 g
 JOIN private.iclub_ai_v21_beta_members m ON m.user_id=g.user_id
 WHERE g.enabled AND (NOT m.enabled OR m.consent_at IS NULL)
 AND (public.get_iclub_ai_v21_beta_status_service(g.user_id)->>'eligible')::boolean;
 IF allowed_count<>1 OR pending_count<>0 THEN
   RAISE EXCEPTION 'Expected exactly one currently consented beta user; got % and % unauthorized',
      allowed_count,pending_count; END IF;
 IF strpos(pg_get_functiondef('public.get_iclub_ai_v21_beta_status_service(uuid)'::regprocedure),
   'practice_sessions_v4')<>0
 OR strpos(pg_get_functiondef('public.get_iclub_ai_v21_beta_status_service(uuid)'::regprocedure),
   'iclub_ai_has_active_protected_assessment_v1')<>0
 OR has_function_privilege('authenticated',
    'public.get_iclub_ai_v21_beta_status_service(uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'Screen-only status or service-role privileges invalid'; END IF;
END $post$;
COMMIT;
