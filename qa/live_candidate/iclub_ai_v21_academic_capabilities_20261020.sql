-- Read-only capabilities so the approved panel displays academic actions
-- ONLY for independently published, owner-confirmed real data.
-- This is optional UI discovery, NEVER an academic delivery authorization.
DO $preflight$
BEGIN
 IF to_regprocedure('public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)') IS NOT NULL
 OR to_regclass('private.iclub_ai_v21_academic_sources') IS NULL
 THEN RAISE EXCEPTION 'Capabilities version or academic catalog unexpected'; END IF;
END $preflight$;
CREATE FUNCTION public.get_iclub_ai_v21_academic_capabilities_service(
 p_user_id uuid,p_surface text,p_record_id bigint,p_locale text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $caps$
DECLARE
 v_subject text;
 v_tour bigint;
 v_results jsonb:='[]'::jsonb;
 v_now timestamptz:=clock_timestamp();
BEGIN
 IF p_user_id IS NULL OR p_record_id IS NULL OR p_record_id<=0
 OR p_surface NOT IN ('practice_error','lesson_topic','tour_archive')
 OR p_locale NOT IN ('ru','uz','en')
 OR NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_beta_control c
  JOIN private.iclub_ai_v21_academic_policy pol ON pol.singleton=c.singleton
  JOIN private.iclub_ai_v21_beta_members m ON m.user_id=p_user_id
  WHERE c.singleton=1 AND c.beta_enabled AND c.prepared_enabled
  AND NOT c.generation_enabled AND pol.enabled AND NOT pol.provider_enabled
  AND m.enabled AND m.consent_version='global_ai_beta_v21'
  AND m.consent_at IS NOT NULL)
 OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS(SELECT 1 FROM public.practice_sessions_v4 ps
    WHERE ps.user_id=p_user_id AND ps.status='in_progress')
 THEN RETURN jsonb_build_object('ok',true,'available',v_results); END IF;

 IF p_surface='practice_error' THEN
  SELECT subj.subject_key INTO v_subject
  FROM public.practice_attempts pa
  JOIN public.practice_sessions_v4 ps ON ps.legacy_attempt_id=pa.id
  JOIN public.subjects subj ON subj.id=ps.subject_id
  JOIN public.user_subjects e ON e.subject_id=subj.id AND e.user_id=p_user_id
  WHERE pa.id=p_record_id AND pa.user_id=p_user_id
   AND ps.user_id=p_user_id AND ps.status='finalized'
   AND ps.finalized_at IS NOT NULL AND pa.subject_id=ps.subject_id
   AND subj.is_active LIMIT 1;
  IF v_subject IS NOT NULL THEN
   SELECT coalesce(jsonb_agg(DISTINCT answer.question_id),'[]'::jsonb) INTO v_results
   FROM public.practice_sessions_v4 ps
   JOIN public.practice_session_answers_v4 answer ON answer.session_id=ps.id
   JOIN private.iclub_ai_v21_academic_sources src
    ON src.surface_code='practice_error' AND src.subject_key=v_subject
    AND src.context_key='question_'||answer.question_id::text
    AND src.locale=p_locale
   WHERE ps.legacy_attempt_id=p_record_id AND ps.user_id=p_user_id
    AND ps.status='finalized' AND ps.finalized_at IS NOT NULL
    AND answer.answered_at IS NOT NULL AND answer.is_correct IS FALSE
    AND answer.question_id=ANY(ps.question_ids)
    AND src.published AND NOT src.revoked AND src.content_reviewed
    AND src.rights_reviewed AND src.locale_reviewed AND src.academic_qa_passed
    AND src.approved_at IS NOT NULL
    AND src.content_hash=encode(extensions.digest(convert_to(src.body_text,'UTF8'),'sha256'),'hex');
  END IF;
 ELSIF p_surface='lesson_topic' THEN
   SELECT subj.subject_key INTO v_subject
   FROM public.lessons l
   JOIN public.subjects subj ON subj.id=l.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   WHERE l.id=p_record_id AND subj.is_active LIMIT 1;
   IF v_subject IS NOT NULL AND EXISTS(
    SELECT 1 FROM private.iclub_ai_v21_academic_sources src
    WHERE src.surface_code='lesson_topic' AND src.subject_key=v_subject
      AND src.context_key='lesson_'||p_record_id::text AND src.locale=p_locale
      AND src.published AND NOT src.revoked AND src.content_reviewed
      AND src.rights_reviewed AND src.locale_reviewed AND src.academic_qa_passed
      AND src.approved_at IS NOT NULL
      AND src.content_hash=encode(extensions.digest(convert_to(src.body_text,'UTF8'),'sha256'),'hex')
   ) THEN v_results:=jsonb_build_array(p_record_id); END IF;
 ELSIF p_surface='tour_archive' THEN
   SELECT subj.subject_key,t.id INTO v_subject,v_tour
   FROM public.tour_attempts a JOIN public.tours t ON t.id=a.tour_id
   JOIN public.subjects subj ON subj.id=t.subject_id
   JOIN public.user_subjects e ON e.subject_id=subj.id AND e.user_id=p_user_id
   JOIN private.iclub_ai_v21_tour_archive_permissions ar ON ar.tour_id=t.id
   WHERE a.id=p_record_id AND a.user_id=p_user_id
   AND a.status IN ('submitted','time_expired') AND subj.is_active
   AND ar.approved AND NOT ar.revoked AND ar.approved_at IS NOT NULL
   AND ar.available_at<=v_now
   AND t.end_date < (v_now AT TIME ZONE 'Asia/Tashkent')::date LIMIT 1;
   IF v_tour IS NOT NULL AND EXISTS(
    SELECT 1 FROM private.iclub_ai_v21_academic_sources src
    WHERE src.surface_code='tour_archive' AND src.subject_key=v_subject
      AND src.context_key='tour_'||v_tour::text||'_archive' AND src.locale=p_locale
      AND src.published AND NOT src.revoked AND src.content_reviewed
      AND src.rights_reviewed AND src.locale_reviewed AND src.academic_qa_passed
      AND src.approved_at IS NOT NULL
      AND src.content_hash=encode(extensions.digest(convert_to(src.body_text,'UTF8'),'sha256'),'hex')
   ) THEN v_results:=jsonb_build_array(p_record_id); END IF;
 END IF;
 RETURN jsonb_build_object('ok',true,'available',v_results);
END $caps$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)
 TO service_role;
