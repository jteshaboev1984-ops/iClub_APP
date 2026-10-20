-- Production-only compatible additive rights enforcement for newly installed
-- academic resolver + source discovery. No legacy AI/grades/financial writes.
DO $guard$
BEGIN
 IF md5(pg_get_functiondef('public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)'::regprocedure))
   <> 'eba6645893247b79c1836f6935a2e200'
 OR md5(pg_get_functiondef('public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)'::regprocedure))
   <> '2a41a530ef486cb41826b245301b5f8c'
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND NOT enabled AND NOT provider_enabled)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_sources)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_deliveries)
 THEN RAISE EXCEPTION 'Academic entitlement contract changed or already active'; END IF;
END $guard$;
CREATE OR REPLACE FUNCTION public.deliver_iclub_ai_v21_academic_service(
 p_user_id uuid,p_request_id uuid,p_surface text,p_record_id bigint,
 p_question_id bigint,p_locale text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $academic$
DECLARE
 c private.iclub_ai_v21_beta_control%rowtype;
 m private.iclub_ai_v21_beta_members%rowtype;
 pol private.iclub_ai_v21_academic_policy%rowtype;
 source private.iclub_ai_v21_academic_sources%rowtype;
 old private.iclub_ai_v21_academic_deliveries%rowtype;
 usage private.iclub_ai_v21_beta_usage%rowtype;
 v_subject text;
 v_key text;
 v_now timestamptz:=clock_timestamp();
 v_tour bigint;
BEGIN
 IF p_user_id IS NULL OR p_request_id IS NULL
 OR p_surface NOT IN ('practice_error','lesson_topic','tour_archive')
 OR p_locale NOT IN ('ru','uz','en')
 OR p_record_id IS NULL OR p_record_id<=0
 OR (p_surface='practice_error' AND (p_question_id IS NULL OR p_question_id<=0))
 OR (p_surface<>'practice_error' AND p_question_id IS NOT NULL) THEN
  RETURN jsonb_build_object('ok',false,'reason','invalid_request');
 END IF;

 -- Serialize beta gate, publication, quota and delivery into one transaction.
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control WHERE singleton=1 FOR UPDATE;
 SELECT * INTO pol FROM private.iclub_ai_v21_academic_policy WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT coalesce(c.beta_enabled,false)
 OR NOT coalesce(c.prepared_enabled,false) OR coalesce(c.generation_enabled,true)
 OR NOT coalesce(pol.enabled,false) OR coalesce(pol.provider_enabled,true)
 THEN RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;
 SELECT * INTO m FROM private.iclub_ai_v21_beta_members WHERE user_id=p_user_id;
 IF NOT FOUND OR NOT m.enabled OR m.consent_version<>'global_ai_beta_v21'
 OR m.consent_at IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS(SELECT 1 FROM public.practice_sessions_v4 ps
           WHERE ps.user_id=p_user_id AND ps.status='in_progress')
 THEN RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 IF p_surface='practice_error' THEN
   -- The app provides LEGACY attempt ID from its real Practice review DOM.
   -- The source authority is the matching finalized V4 server session,
   -- including a verified incorrect AND actually answered question.
   SELECT subj.subject_key INTO v_subject
   FROM public.practice_attempts pa
   JOIN public.practice_sessions_v4 ps ON ps.legacy_attempt_id=pa.id
   JOIN public.practice_session_answers_v4 answer
     ON answer.session_id=ps.id AND answer.question_id=p_question_id
   JOIN public.subjects subj ON subj.id=ps.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   WHERE pa.id=p_record_id AND pa.user_id=p_user_id
     AND ps.user_id=p_user_id AND pa.subject_id=ps.subject_id
     AND ps.status='finalized' AND ps.finalized_at IS NOT NULL
     AND answer.answered_at IS NOT NULL AND answer.is_correct IS FALSE
     AND p_question_id=ANY(ps.question_ids) AND subj.is_active
   LIMIT 1;
   v_key:='question_'||p_question_id::text;
 ELSIF p_surface='lesson_topic' THEN
   SELECT subj.subject_key INTO v_subject
   FROM public.lessons lesson
   JOIN public.subjects subj ON subj.id=lesson.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   WHERE lesson.id=p_record_id AND subj.is_active LIMIT 1;
   v_key:='lesson_'||p_record_id::text;
 ELSIF p_surface='tour_archive' THEN
   SELECT subj.subject_key,tour.id INTO v_subject,v_tour
   FROM public.tour_attempts a
   JOIN public.tours tour ON tour.id=a.tour_id
   JOIN public.subjects subj ON subj.id=tour.subject_id
   JOIN public.user_subjects enrolled ON enrolled.subject_id=subj.id
     AND enrolled.user_id=p_user_id
   JOIN private.iclub_ai_v21_tour_archive_permissions access
     ON access.tour_id=tour.id
   WHERE a.id=p_record_id AND a.user_id=p_user_id
     AND a.status IN ('submitted','time_expired')
     AND subj.is_active AND access.approved AND NOT access.revoked
     AND access.approved_at IS NOT NULL AND access.available_at<=v_now
     AND tour.end_date < (v_now AT TIME ZONE 'Asia/Tashkent')::date
   LIMIT 1;
   v_key:='tour_'||v_tour::text||'_archive';
 END IF;
 -- Dynamic subscription contract: today lifecycle is OFF, but if enabled
 -- later then an active, time-valid recognized plan is REQUIRED as well as
 -- learner-owned subject selection. No paid model entitlement is inferred.
 IF EXISTS(SELECT 1 FROM private.iclub_commercial_access_config cfg
     WHERE cfg.id=1 AND cfg.lifecycle_enabled)
 AND NOT EXISTS(
   SELECT 1 FROM private.iclub_subscription_entitlements se
   JOIN private.iclub_plan_policies plan ON plan.plan_code=se.plan_code
     AND plan.is_active
   WHERE se.user_id=p_user_id AND se.entitlement_status='active'
    AND (se.valid_from IS NULL OR se.valid_from<=v_now)
    AND (se.valid_until IS NULL OR se.valid_until>v_now)
 ) THEN
  RETURN jsonb_build_object('ok',false,'reason','subject_rights_required');
 END IF;
 IF v_subject IS NULL OR v_key IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','context_not_authorized'); END IF;

 SELECT * INTO source FROM private.iclub_ai_v21_academic_sources s
 WHERE s.surface_code=p_surface AND s.subject_key=v_subject
 AND s.context_key=v_key AND s.locale=p_locale FOR SHARE;
 IF NOT FOUND OR NOT source.published OR source.revoked
 OR NOT source.content_reviewed OR NOT source.rights_reviewed
 OR NOT source.locale_reviewed OR NOT source.academic_qa_passed
 OR source.approved_at IS NULL
 OR encode(extensions.digest(convert_to(source.body_text,'UTF8'),'sha256'),'hex')
   <>source.content_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 SELECT * INTO old FROM private.iclub_ai_v21_academic_deliveries
  WHERE request_id=p_request_id;
 IF FOUND THEN
  IF old.user_id=p_user_id AND old.surface_code=p_surface
  AND old.subject_key=v_subject AND old.context_key=v_key
  AND old.locale=p_locale AND old.source_card_key=source.source_card_key
  AND old.content_hash=source.content_hash
  AND old.source_version=source.source_version
  AND old.publication_revision=source.publication_revision THEN
   RETURN jsonb_build_object('ok',true,'message',source.body_text,
    'mode','prepared','provider_called',false,
    'academic_state_changed',false,'replayed',true);
  END IF;
  RETURN jsonb_build_object('ok',false,'reason','request_conflict'); END IF;
 -- Prevent cross-route request-id reuse against existing Help quota claims.
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_deliveries
            WHERE request_id=p_request_id) THEN
  RETURN jsonb_build_object('ok',false,'reason','request_conflict'); END IF;

 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES(p_user_id,v_now,0) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO usage FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF usage.started_at<=v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
  SET started_at=v_now,committed_count=0,updated_at=v_now WHERE user_id=p_user_id;
  usage.committed_count:=0;
 END IF;
 IF usage.committed_count>=3 THEN
  RETURN jsonb_build_object('ok',false,'reason','usage_exhausted',
    'reset_at',usage.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_academic_deliveries(
 request_id,user_id,surface_code,subject_key,context_key,locale,
 source_card_key,source_version,content_hash,publication_revision
 ) VALUES(p_request_id,p_user_id,p_surface,v_subject,v_key,p_locale,
 source.source_card_key,source.source_version,source.content_hash,
 source.publication_revision);
 UPDATE private.iclub_ai_v21_beta_usage SET committed_count=committed_count+1,
 updated_at=v_now WHERE user_id=p_user_id;
 RETURN jsonb_build_object('ok',true,'message',source.body_text,
  'mode','prepared','provider_called',false,
  'academic_state_changed',false,'replayed',false);
END $academic$;
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_academic_capabilities_service(
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

 -- Dynamic subscription contract: today lifecycle is OFF, but if enabled
 -- later then an active, time-valid recognized plan is REQUIRED as well as
 -- learner-owned subject selection. No paid model entitlement is inferred.
 IF EXISTS(SELECT 1 FROM private.iclub_commercial_access_config cfg
     WHERE cfg.id=1 AND cfg.lifecycle_enabled)
 AND NOT EXISTS(
   SELECT 1 FROM private.iclub_subscription_entitlements se
   JOIN private.iclub_plan_policies plan ON plan.plan_code=se.plan_code
     AND plan.is_active
   WHERE se.user_id=p_user_id AND se.entitlement_status='active'
    AND (se.valid_from IS NULL OR se.valid_from<=v_now)
    AND (se.valid_until IS NULL OR se.valid_until>v_now)
 ) THEN
  RETURN jsonb_build_object('ok',true,'available',v_results);
 END IF;

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
REVOKE ALL ON FUNCTION public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.deliver_iclub_ai_v21_academic_service(uuid,uuid,text,bigint,bigint,text)
 TO service_role;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_academic_capabilities_service(uuid,text,bigint,text)
 TO service_role;
