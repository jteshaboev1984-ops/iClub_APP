-- iClub AI v2.1 / P7+1: ACTUAL SCHEMA evidence; LOCAL SCRATCH ONLY.
-- READ-ONLY RPC body, no AI release, academic mutations, billing or provider.
-- Never apply to production: explicit database/name/IP guard, no migrations.
DO $guard$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
    OR (inet_server_addr() IS NOT NULL
      AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
      AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
        AND current_setting('application_name')='iclub_ai_v21_local_scratch'))
 THEN RAISE EXCEPTION 'BLOCKED: iClub AI real-schema proof is scratch-only'; END IF;
END $guard$;

-- A single RPC implements the verified existing-record subset of the
-- screen-proof interface. Home, General Help, subject overview and Lessons
-- remain DENY until separately approved content and factual source mapping.
-- This service does NOT mint contexts or assert a current browser screen.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_screen_evidence_service(
 p_user_id uuid, p_kind text, p_view text DEFAULT NULL,
 p_subject text DEFAULT NULL, p_lesson_id bigint DEFAULT NULL,
 p_session_id bigint DEFAULT NULL, p_question_id bigint DEFAULT NULL,
 p_attempt_id bigint DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $proof_v21$
DECLARE
 v_evidence jsonb;
 v_current_date date := (now() AT TIME ZONE 'Asia/Tashkent')::date;
BEGIN
 IF p_user_id IS NULL OR p_kind IS NULL OR
    p_kind NOT IN ('current_screen','profile_aggregate','practice_session_v4','practice_answer_v4',
                   'tour_attempt','tour_runtime','tour_archive_access')
    OR (p_kind LIKE 'practice_%' AND (p_session_id IS NULL OR p_session_id<=0))
    OR (p_kind='practice_answer_v4' AND (p_question_id IS NULL OR p_question_id<=0))
    OR (p_kind LIKE 'tour_%' AND (p_attempt_id IS NULL OR p_attempt_id<=0))
 THEN RETURN jsonb_build_object('allowed',false); END IF;

 -- The ordinary app's existing v1 global AI kill switch remains authoritative;
 -- successful local tests do NOT turn on the global v2 AI release.
 IF NOT EXISTS (
  SELECT 1 FROM private.iclub_global_ai_runtime_config x
  WHERE x.id=1 AND x.kill_switch=false AND x.gateway_enabled=true
 ) OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 THEN RETURN jsonb_build_object('allowed',false); END IF;

 -- The screen is server-minted ONLY through the existing short-lived
 -- practice/lesson context service. Mere browser view strings never count.
 -- Missing scoped context schema means NO screen authority (standalone proof QA).
 IF p_kind='current_screen' THEN
  IF to_regclass('private.iclub_ai_v21_current_screen') IS NULL
    OR to_regclass('private.iclub_ai_v21_scoped_contexts') IS NULL
  THEN RETURN jsonb_build_object('allowed',false); END IF;
  SELECT jsonb_build_object(
   'user_id',nav.user_id,'evidence_kind','current_screen',
   'active',true,'context_handle',c.context_handle,
   'context_revision','screen_'||nav.revision::text,
   'revision',nav.revision,'current_view',CASE
     WHEN c.surface_code IN ('home','profile','global') THEN c.app_view_code
     ELSE 'courses' END)
  INTO v_evidence
  FROM private.iclub_ai_v21_current_screen nav
  JOIN private.iclub_ai_v21_scoped_contexts c
   ON c.context_handle=nav.current_handle
    AND c.user_id=nav.user_id AND c.context_revision=nav.revision
  WHERE nav.user_id=p_user_id AND nav.current_handle IS NOT NULL
   AND c.surface_code IN ('practice','lesson','tour_archive','home','profile','global')
   AND c.revoked_at IS NULL AND c.expires_at>now()
   AND public.get_iclub_ai_v21_scoped_context_service(
        p_user_id,c.context_handle::text)->>'allowed'='true';
  IF v_evidence IS NULL THEN RETURN jsonb_build_object('allowed',false); END IF;
  RETURN jsonb_build_object('allowed',true,'evidence',v_evidence);
 END IF;

 -- Profile proof is a minimal verified ACTIVITY snapshot, not an
 -- academic mastery/readiness metric, trend or AI lesson recommendation.
 -- Its values are calculated ONLY from actual owner-enrolled DB rows.
 IF p_kind='profile_aggregate' THEN
  IF to_regclass('private.iclub_ai_v21_scoped_contexts') IS NULL THEN
   RETURN jsonb_build_object('allowed',false);END IF;
  SELECT jsonb_build_object(
   'user_id',nav.user_id,'evidence_kind','profile_aggregate',
   'verified',true,'aggregate_revision',nav.revision,
   'metrics',jsonb_build_array(
    jsonb_build_object('metric','competitive_subjects','count',COALESCE(cs.n,0)),
    jsonb_build_object('metric','pinned_study_subjects','count',COALESCE(ss.n,0)),
    jsonb_build_object('metric','finalized_tours','count',COALESCE(ts.n,0))))
  INTO v_evidence
  FROM private.iclub_ai_v21_current_screen nav
  JOIN private.iclub_ai_v21_scoped_contexts c
    ON c.context_handle=nav.current_handle AND c.user_id=nav.user_id
     AND c.context_revision=nav.revision
  JOIN public.users person ON person.id=nav.user_id
  CROSS JOIN LATERAL (
   SELECT count(*)::integer AS n
   FROM public.user_subjects us
   JOIN public.subjects subj ON subj.id=us.subject_id AND subj.is_active=true
   WHERE us.user_id=nav.user_id AND us.mode='competitive'
  ) cs
  CROSS JOIN LATERAL (
   SELECT count(*)::integer AS n
   FROM public.user_subjects us
   JOIN public.subjects subj ON subj.id=us.subject_id AND subj.is_active=true
   WHERE us.user_id=nav.user_id AND us.mode='study' AND us.is_pinned=true
  ) ss
  CROSS JOIN LATERAL (
   SELECT count(DISTINCT ta.tour_id)::integer AS n
   FROM public.tour_attempts ta
   JOIN public.tour_session_runtime_v4 rt ON rt.attempt_id=ta.id
    AND rt.user_id=ta.user_id AND rt.tour_id=ta.tour_id
    AND rt.finalized_at IS NOT NULL
   WHERE ta.user_id=nav.user_id AND ta.status IN ('submitted','time_expired')
  ) ts
  WHERE nav.user_id=p_user_id AND c.surface_code='profile'
   AND c.app_view_code='profile' AND c.subject_key='general'
   AND c.topic_key='progress' AND c.revoked_at IS NULL
   AND c.expires_at>now()
   AND public.get_iclub_ai_v21_scoped_context_service(
     p_user_id,c.context_handle::text)->>'allowed'='true';
  IF v_evidence IS NULL THEN RETURN jsonb_build_object('allowed',false);END IF;
  RETURN jsonb_build_object('allowed',true,'evidence',v_evidence);
 END IF;

 IF p_kind='practice_session_v4' THEN
  SELECT jsonb_build_object(
    'user_id',s.user_id,'evidence_kind',p_kind,
    'id',s.id,'session_id',s.id,'subject_key',subj.subject_key,
    'status',s.status,'finalized_at',s.finalized_at,'question_ids',s.question_ids)
  INTO v_evidence
  FROM public.practice_sessions_v4 s
  JOIN public.subjects subj ON subj.id=s.subject_id AND subj.is_active=true
  JOIN public.user_subjects us ON us.user_id=p_user_id AND us.subject_id=s.subject_id
  WHERE s.id=p_session_id AND s.user_id=p_user_id
    AND s.status='finalized' AND s.finalized_at IS NOT NULL;
 ELSIF p_kind='practice_answer_v4' THEN
  SELECT jsonb_build_object(
    'user_id',s.user_id,'evidence_kind',p_kind,
    'session_id',s.id,'question_id',a.question_id,
    'server_checked',true,'is_final',true,
    'topic_key','question_'||a.question_id::text,
    'revision',floor(extract(epoch FROM a.answered_at)*1000)::bigint)
  INTO v_evidence
  FROM public.practice_sessions_v4 s
  JOIN public.subjects subj ON subj.id=s.subject_id AND subj.is_active=true
  JOIN public.user_subjects us ON us.user_id=p_user_id AND us.subject_id=s.subject_id
  JOIN public.practice_session_answers_v4 a
    ON a.session_id=s.id AND a.question_id=p_question_id
  WHERE s.id=p_session_id AND s.user_id=p_user_id
    AND s.status='finalized' AND s.finalized_at IS NOT NULL
    AND p_question_id=ANY(s.question_ids)
    AND a.answered_at IS NOT NULL AND a.is_correct IS NOT NULL;
 ELSIF p_kind LIKE 'tour_%' THEN
  -- Tour archive really opens strictly AFTER end_date in Asia/Tashkent;
  -- this matches get_tour_review_full_safe_v4 and is NOT an invented flag.
  SELECT jsonb_build_object(
    'user_id',ta.user_id,'evidence_kind',p_kind,
    'id',ta.id,'attempt_id',ta.id,'tour_id',ta.tour_id,
    'subject_key',subj.subject_key,'status',ta.status,
    'finalized_at',runtime.finalized_at,
    'owner_verified',true,
    'unlocked',(t.end_date IS NOT NULL AND v_current_date>t.end_date),
    'unlock_revision',greatest(1,v_current_date-t.end_date),
    'topic_key','tour_'||ta.tour_id::text||'_archive')
  INTO v_evidence
  FROM public.tour_attempts ta
  JOIN public.tours t ON t.id=ta.tour_id
  JOIN public.subjects subj ON subj.id=t.subject_id AND subj.is_active=true
  JOIN public.user_subjects us ON us.user_id=p_user_id AND us.subject_id=t.subject_id
  JOIN public.tour_session_runtime_v4 runtime
    ON runtime.attempt_id=ta.id AND runtime.user_id=ta.user_id
       AND runtime.tour_id=ta.tour_id AND runtime.finalized_at IS NOT NULL
  WHERE ta.id=p_attempt_id AND ta.user_id=p_user_id
    AND ta.status IN ('submitted','time_expired');
  IF p_kind='tour_archive_access' AND
     COALESCE((v_evidence->>'unlocked')::boolean,false) IS NOT TRUE THEN
   RETURN jsonb_build_object('allowed',false);
  END IF;
 END IF;
 IF v_evidence IS NULL THEN RETURN jsonb_build_object('allowed',false); END IF;
 -- Normalized metadata only, NEVER raw answers, marks or explanations.
 RETURN jsonb_build_object('allowed',true,'evidence',v_evidence);
END $proof_v21$;

REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_screen_evidence_service(
 uuid,text,text,text,bigint,bigint,bigint,bigint) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_screen_evidence_service(
 uuid,text,text,text,bigint,bigint,bigint,bigint) TO service_role;
