-- iClub AI v2.1: proposed read-only resolution of legacy Practice result marker
-- into a canonical V4 session ID. QA/SCRATCH ONLY, UNAPPLIED TO PRODUCTION.
-- This function is NOT a new grant to AI. Follow with separately validated
-- mint_iclub_ai_v21_practice_context_service and source publication gates.
-- p_user_id must be derived by trusted Edge from JWT, NEVER the browser body.
CREATE OR REPLACE FUNCTION public.resolve_iclub_ai_v21_practice_attempt_service(
 p_user_id uuid,
 p_attempt_reference bigint,
 p_question_id bigint
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $fn$
DECLARE
 v_count integer;
 v_session bigint;
BEGIN
 IF p_user_id IS NULL OR p_attempt_reference IS NULL OR
    p_question_id IS NULL OR p_attempt_reference <= 0 OR p_question_id <= 0
 THEN RETURN '{"ok":false,"reason":"server_verification_required"}'::jsonb; END IF;

 -- No lookup, even read-only, while the feature is not explicitly enabled
 -- or a timed assessment is active. The context mint checks this AGAIN.
 IF NOT EXISTS(
   SELECT 1 FROM private.iclub_global_ai_runtime_config cfg
   WHERE cfg.id=1 AND cfg.kill_switch IS FALSE
     AND cfg.gateway_enabled IS TRUE
 ) OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 THEN RETURN '{"ok":false,"reason":"server_verification_required"}'::jsonb; END IF;

 -- The app's practiceAiAttemptId is legacy_attempt_id, NOT a V4 session id.
 -- One finalized owned V4 row, an included server-checked answer and current
 -- subject entitlement are required. Ambiguous mapping rejects both rows.
 SELECT count(DISTINCT s.id), min(s.id)
 INTO v_count,v_session
 FROM public.practice_sessions_v4 AS s
 JOIN public.practice_session_answers_v4 AS a
   ON a.session_id=s.id AND a.question_id=p_question_id
 JOIN public.subjects AS subject
   ON subject.id=s.subject_id AND subject.is_active IS TRUE
 JOIN public.user_subjects AS enrolled
   ON enrolled.subject_id=s.subject_id AND enrolled.user_id=p_user_id
 WHERE s.user_id=p_user_id
   AND s.legacy_attempt_id=p_attempt_reference
   AND s.status='finalized'
   AND s.finalized_at IS NOT NULL
   AND s.finalized_at <= clock_timestamp()
   AND p_question_id = ANY(s.question_ids)
   AND a.answered_at IS NOT NULL
   AND a.is_correct IS NOT NULL;

 IF v_count <> 1 OR v_session IS NULL
 THEN RETURN '{"ok":false,"reason":"server_verification_required"}'::jsonb; END IF;
 -- Never disclose answers, scoring, personal data, archive keys or readiness.
 RETURN jsonb_build_object(
  'ok',true,
  'kind','server_resolved_practice_v4',
  'attemptReference',p_attempt_reference,
  'questionId',p_question_id,
  'sessionId',v_session
 );
END;
$fn$;

REVOKE ALL ON FUNCTION public.resolve_iclub_ai_v21_practice_attempt_service(
 uuid,bigint,bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resolve_iclub_ai_v21_practice_attempt_service(
 uuid,bigint,bigint) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_iclub_ai_v21_practice_attempt_service(
 uuid,bigint,bigint) TO service_role;
