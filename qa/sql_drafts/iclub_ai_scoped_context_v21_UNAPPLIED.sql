-- iClub AI v2.1 — SERVER-OWNED SHORT-LIVED CONTEXT, QA SCRATCH ONLY.
-- NO CONTENT. NO PRODUCTION MIGRATION. NO ACADEMIC STATE WRITES.
-- Browser session/question IDs are lookup selectors, NEVER grants of authority.
-- The production-facing caller MUST verify the learner bearer through Auth;
-- ONLY service_role may mint, resolve or revoke this opaque context.
DO $scratch$
BEGIN
 IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'
 OR (inet_server_addr() IS NOT NULL
  AND inet_server_addr() NOT IN ('127.0.0.1'::inet,'::1'::inet)
  AND NOT (inet_server_addr() << '172.16.0.0/12'::cidr
   AND current_setting('application_name')='iclub_ai_v21_local_scratch')) THEN
  RAISE EXCEPTION 'BLOCKED: scoped context contract is scratch-only';
 END IF;
END $scratch$;

CREATE SCHEMA IF NOT EXISTS private;
-- One active screen per user for NEW AI only. Switching a screen invalidates
-- the previously minted handle in any tab without touching localStorage.
CREATE TABLE private.iclub_ai_v21_current_screen(
 user_id uuid PRIMARY KEY,
 current_handle uuid,
 revision bigint NOT NULL DEFAULT 0 CHECK(revision>=0),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE private.iclub_ai_v21_scoped_contexts(
 context_handle uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL,
 surface_code text NOT NULL CHECK(surface_code IN ('practice','lesson')),
 subject_key text NOT NULL,
 feature_code text NOT NULL CHECK((surface_code='practice' AND feature_code='answer_explanation') OR (surface_code='lesson' AND feature_code='topic_explanation')),
 topic_key text NOT NULL,
 practice_session_id bigint,
 practice_question_id bigint,
 lesson_id bigint,
 context_revision bigint NOT NULL CHECK(context_revision>0),
 expires_at timestamptz NOT NULL DEFAULT (now()+interval '90 seconds'),
 created_at timestamptz NOT NULL DEFAULT now(),
 revoked_at timestamptz,
 CHECK((surface_code='practice' AND practice_session_id IS NOT NULL
  AND practice_question_id IS NOT NULL AND lesson_id IS NULL
  AND topic_key='question_'||practice_question_id::text)
  OR (surface_code='lesson' AND lesson_id IS NOT NULL
   AND practice_session_id IS NULL AND practice_question_id IS NULL
   AND topic_key='lesson_'||lesson_id::text))
);
CREATE INDEX iclub_ai_v21_scoped_contexts_user_idx
 ON private.iclub_ai_v21_scoped_contexts(user_id,expires_at);
REVOKE ALL ON TABLE private.iclub_ai_v21_current_screen FROM public,anon,authenticated;
REVOKE ALL ON TABLE private.iclub_ai_v21_scoped_contexts FROM public,anon,authenticated;

-- No published-source check here, intentionally. The context refers to a
-- verified completed attempt; the separate source-publisher gate will return
-- "В разработке" when that exact question/locale lacks reviewed content.
CREATE OR REPLACE FUNCTION public.mint_iclub_ai_v21_practice_context_service(
 p_user_id uuid,p_session_id bigint,p_question_id bigint
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path='' AS $$
DECLARE
 v_subject text;
 v_id uuid;
 v_rev bigint;
 v_existing_handle uuid;
BEGIN
 IF p_user_id IS NULL OR p_session_id IS NULL OR p_question_id IS NULL
   OR p_session_id<=0 OR p_question_id<=0 THEN
  RETURN jsonb_build_object('allowed',false,'reason','invalid_request');
 END IF;
 -- Independent NEW AI emergency stop / owner activation.
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_global_ai_runtime_config cfg
  WHERE cfg.id=1 AND cfg.kill_switch=false
   AND cfg.ui_enabled=true AND cfg.gateway_enabled=true
 ) THEN
  RETURN jsonb_build_object('allowed',false,'reason','global_ai_disabled');
 END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id) THEN
  RETURN jsonb_build_object('allowed',false,'reason','active_assessment');
 END IF;
 -- Read-only, grounded in live Practice tables. Content readiness NOT guessed.
 SELECT subj.subject_key INTO v_subject
 FROM public.practice_sessions_v4 s
 JOIN public.subjects subj ON subj.id=s.subject_id
 WHERE s.id=p_session_id AND s.user_id=p_user_id
  AND s.status='finalized' AND s.finalized_at IS NOT NULL
  AND subj.is_active=true
  AND p_question_id=ANY(s.question_ids)
  AND EXISTS(
    SELECT 1 FROM public.practice_session_answers_v4 a
    WHERE a.session_id=s.id AND a.question_id=p_question_id
  )
  AND EXISTS(
    SELECT 1 FROM public.user_subjects us
    WHERE us.user_id=p_user_id AND us.subject_id=subj.id
  )
 LIMIT 1;
 IF v_subject IS NULL THEN
  RETURN jsonb_build_object('allowed',false,'reason','practice_context_not_authorized');
 END IF;
 -- For future Biology/Informatics, the exact same technical gate applies.
 -- No app-wide static subject ready list is allowed.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user_id::text,303));
 -- Same active finalized question opened twice is idempotent.
 SELECT c.context_handle INTO v_existing_handle
 FROM private.iclub_ai_v21_current_screen nav
 JOIN private.iclub_ai_v21_scoped_contexts c
   ON c.context_handle=nav.current_handle
 WHERE nav.user_id=p_user_id AND c.user_id=p_user_id
   AND c.context_revision=nav.revision
   AND c.practice_session_id=p_session_id
   AND c.practice_question_id=p_question_id
   AND c.revoked_at IS NULL AND c.expires_at>now();
 IF FOUND THEN
  RETURN jsonb_build_object('allowed',true,
   'context_handle',v_existing_handle,'expires_in_seconds',90,
   'duplicate',true);
 END IF;
 -- A browser cannot generate unlimited context rows by toggling screens.
 IF (SELECT count(*) FROM private.iclub_ai_v21_scoped_contexts
     WHERE user_id=p_user_id AND created_at>now()-interval '1 minute')>=30 THEN
  RETURN jsonb_build_object('allowed',false,'reason','context_rate_limited');
 END IF;
 v_id:=gen_random_uuid();
 INSERT INTO private.iclub_ai_v21_current_screen(
  user_id,current_handle,revision,updated_at
 ) VALUES (p_user_id,v_id,1,now())
 ON CONFLICT(user_id) DO UPDATE
 SET current_handle=excluded.current_handle,
     revision=private.iclub_ai_v21_current_screen.revision+1,
     updated_at=now()
 RETURNING revision INTO v_rev;
 INSERT INTO private.iclub_ai_v21_scoped_contexts(
  context_handle,user_id,surface_code,subject_key,
  feature_code,topic_key,practice_session_id,
  practice_question_id,context_revision
 ) VALUES (v_id,p_user_id,'practice',v_subject,
  'answer_explanation','question_'||p_question_id::text,
  p_session_id,p_question_id,v_rev);
 RETURN jsonb_build_object(
  'allowed',true,'context_handle',v_id,
  'expires_in_seconds',90
 );
END;
$$;
REVOKE ALL ON FUNCTION public.mint_iclub_ai_v21_practice_context_service(
 uuid,bigint,bigint) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mint_iclub_ai_v21_practice_context_service(
 uuid,bigint,bigint) TO service_role;

-- Verifies owner, revision, expiry, current live attempt/answer, subject and
-- active protected exam AT READ TIME, including after any asynchronous provider.
CREATE OR REPLACE FUNCTION public.get_iclub_ai_v21_scoped_context_service(
 p_user_id uuid,p_context_handle text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE
 v private.iclub_ai_v21_scoped_contexts%rowtype;
 v_current private.iclub_ai_v21_current_screen%rowtype;
BEGIN
 IF p_user_id IS NULL OR p_context_handle IS NULL
  OR p_context_handle !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
  RETURN jsonb_build_object('allowed',false,'reason','context_unavailable');
 END IF;
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_global_ai_runtime_config cfg
  WHERE cfg.id=1 AND cfg.kill_switch=false
   AND cfg.ui_enabled=true AND cfg.gateway_enabled=true
 ) OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id) THEN
  RETURN jsonb_build_object('allowed',false,'reason','context_unavailable');
 END IF;
 SELECT * INTO v FROM private.iclub_ai_v21_scoped_contexts
 WHERE context_handle=p_context_handle::uuid AND user_id=p_user_id
   AND revoked_at IS NULL AND expires_at>now();
 IF NOT FOUND THEN RETURN jsonb_build_object('allowed',false,'reason','context_unavailable');END IF;
 SELECT * INTO v_current FROM private.iclub_ai_v21_current_screen
 WHERE user_id=p_user_id AND current_handle=v.context_handle
   AND revision=v.context_revision;
 IF NOT FOUND THEN RETURN jsonb_build_object('allowed',false,'reason','context_unavailable');END IF;
 IF v.surface_code='practice' AND NOT EXISTS(
  SELECT 1
  FROM public.practice_sessions_v4 s
  JOIN public.subjects subj ON subj.id=s.subject_id
  WHERE s.id=v.practice_session_id AND s.user_id=p_user_id
   AND s.status='finalized' AND s.finalized_at IS NOT NULL
   AND subj.subject_key=v.subject_key AND subj.is_active=true
   AND v.practice_question_id=ANY(s.question_ids)
   AND EXISTS(
    SELECT 1 FROM public.practice_session_answers_v4 a
    WHERE a.session_id=s.id AND a.question_id=v.practice_question_id
   )
   AND EXISTS(
    SELECT 1 FROM public.user_subjects us
    WHERE us.user_id=p_user_id AND us.subject_id=subj.id
   )
 ) THEN
  RETURN jsonb_build_object('allowed',false,'reason','context_unavailable');
 END IF;
 IF v.surface_code='lesson' AND NOT EXISTS(
  SELECT 1 FROM public.lessons l
  JOIN public.subjects subj ON subj.id=l.subject_id
  WHERE l.id=v.lesson_id
   AND subj.subject_key=v.subject_key AND subj.is_active=true
   AND EXISTS(SELECT 1 FROM public.user_subjects us
    WHERE us.user_id=p_user_id AND us.subject_id=subj.id)
 ) THEN
  RETURN jsonb_build_object('allowed',false,'reason','context_unavailable');
 END IF;
 RETURN jsonb_build_object('allowed',true,'context',jsonb_build_object(
  'owner_id',v.user_id,'route_authority','unified_ai','active',true,
  'protected_assessment',false,
  'expires_at_ms',floor(extract(epoch from v.expires_at)*1000)::bigint,
  'context_revision','screen_'||v.context_revision::text,
  'surface',v.surface_code,'subject',v.subject_key,'feature',v.feature_code,
  'topic',v.topic_key
 ));
END;
$$;
REVOKE ALL ON FUNCTION public.get_iclub_ai_v21_scoped_context_service(
 uuid,text) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_iclub_ai_v21_scoped_context_service(
 uuid,text) TO service_role;

-- Lesson server context: no invented lesson title or AI content. The existing
-- public.lessons row is the server-verifiable selector. Independent editorial
-- release by lesson_XX and locale determines "В разработке" vs available.
CREATE OR REPLACE FUNCTION public.mint_iclub_ai_v21_lesson_context_service(
 p_user_id uuid,p_lesson_id bigint
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 SET search_path='' AS $iclub_lesson_mint_v21$
DECLARE
 v_subject text;
 v_id uuid;
 v_rev bigint;
 v_existing_handle uuid;
BEGIN
 IF p_user_id IS NULL OR p_lesson_id IS NULL OR p_lesson_id<=0 THEN
  RETURN jsonb_build_object('allowed',false,'reason','invalid_request');
 END IF;
 IF NOT EXISTS(
  SELECT 1 FROM private.iclub_global_ai_runtime_config cfg
  WHERE cfg.id=1 AND cfg.kill_switch=false
   AND cfg.ui_enabled=true AND cfg.gateway_enabled=true
 ) THEN
  RETURN jsonb_build_object('allowed',false,'reason','global_ai_disabled');
 END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id) THEN
  RETURN jsonb_build_object('allowed',false,'reason','active_assessment');
 END IF;
 SELECT subj.subject_key INTO v_subject
 FROM public.lessons l JOIN public.subjects subj ON subj.id=l.subject_id
 WHERE l.id=p_lesson_id AND subj.is_active=true
 AND EXISTS(SELECT 1 FROM public.user_subjects us
  WHERE us.user_id=p_user_id AND us.subject_id=subj.id)
 LIMIT 1;
 IF v_subject IS NULL THEN
  RETURN jsonb_build_object('allowed',false,'reason','lesson_context_not_authorized');
 END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user_id::text,303));
 SELECT c.context_handle INTO v_existing_handle
 FROM private.iclub_ai_v21_current_screen nav
 JOIN private.iclub_ai_v21_scoped_contexts c ON c.context_handle=nav.current_handle
 WHERE nav.user_id=p_user_id AND c.user_id=p_user_id
  AND c.context_revision=nav.revision
  AND c.lesson_id=p_lesson_id AND c.surface_code='lesson'
  AND c.revoked_at IS NULL AND c.expires_at>now();
 IF FOUND THEN
  RETURN jsonb_build_object('allowed',true,
   'context_handle',v_existing_handle,'expires_in_seconds',90,'duplicate',true);
 END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_scoped_contexts
     WHERE user_id=p_user_id AND created_at>now()-interval '1 minute')>=30 THEN
  RETURN jsonb_build_object('allowed',false,'reason','context_rate_limited');
 END IF;
 v_id:=gen_random_uuid();
 INSERT INTO private.iclub_ai_v21_current_screen(user_id,current_handle,revision,updated_at)
 VALUES(p_user_id,v_id,1,now())
 ON CONFLICT(user_id) DO UPDATE
 SET current_handle=excluded.current_handle,
 revision=private.iclub_ai_v21_current_screen.revision+1,updated_at=now()
 RETURNING revision INTO v_rev;
 INSERT INTO private.iclub_ai_v21_scoped_contexts(
  context_handle,user_id,surface_code,subject_key,feature_code,topic_key,
  lesson_id,context_revision
 ) VALUES(v_id,p_user_id,'lesson',v_subject,
  'topic_explanation','lesson_'||p_lesson_id::text,p_lesson_id,v_rev);
 RETURN jsonb_build_object('allowed',true,
  'context_handle',v_id,'expires_in_seconds',90);
END;
$iclub_lesson_mint_v21$;
REVOKE ALL ON FUNCTION public.mint_iclub_ai_v21_lesson_context_service(
 uuid,bigint) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mint_iclub_ai_v21_lesson_context_service(
 uuid,bigint) TO service_role;

-- End of screen: invalidate the current handle at once; an old handle
-- cannot become valid again even if a user returns to the same screen.
CREATE OR REPLACE FUNCTION public.revoke_iclub_ai_v21_scoped_context_service(
 p_user_id uuid,p_context_handle text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 IF p_user_id IS NULL OR p_context_handle IS NULL
 OR p_context_handle !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
  RETURN jsonb_build_object('ok',false);
 END IF;
 v_id:=p_context_handle::uuid;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user_id::text,303));
 UPDATE private.iclub_ai_v21_current_screen
  SET current_handle=NULL,revision=revision+1,updated_at=now()
  WHERE user_id=p_user_id AND current_handle=v_id;
 IF NOT FOUND THEN RETURN jsonb_build_object('ok',false);END IF;
 UPDATE private.iclub_ai_v21_scoped_contexts
  SET revoked_at=now() WHERE context_handle=v_id AND user_id=p_user_id;
 RETURN jsonb_build_object('ok',true);
END;
$$;
REVOKE ALL ON FUNCTION public.revoke_iclub_ai_v21_scoped_context_service(
 uuid,text) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_iclub_ai_v21_scoped_context_service(
 uuid,text) TO service_role;

-- The protected academic tables are SELECTed only; no writes to Practice,
-- Tours, Exam Prep, users, user_subjects or learner local progress.
-- No response text, answers, grades or school identifiers stored here.
-- Cleanup/retention of expired handles requires independent authorization.
