-- AI #412 | Tutor transcript candidate ONLY. Not a live migration.
-- Requires a separate privacy/retention + content-scope owner GO.
-- Default OFF, explicit second consent, no browser storage, no provider/academic writes.
-- This file is intentionally under supabase/candidates/, NOT migrations/.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';

CREATE TABLE private.iclub_ai_tutor_history_v1_control (
  singleton smallint PRIMARY KEY CHECK (singleton=1),
  enabled boolean NOT NULL DEFAULT false,
  retention_hours smallint NOT NULL DEFAULT 24 CHECK(retention_hours BETWEEN 1 AND 168),
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.iclub_ai_tutor_history_v1_control(singleton,enabled,retention_hours)
VALUES (1,false,24);

-- A second, history-specific opt-in is required; existing model consent is NOT enough.
CREATE TABLE private.iclub_ai_tutor_history_v1_optins (
  user_id uuid PRIMARY KEY,
  agreed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE private.iclub_ai_tutor_history_v1_messages (
  user_id uuid NOT NULL,
  thread_key text NOT NULL CHECK (char_length(thread_key) BETWEEN 1 AND 80),
  request_id uuid NOT NULL,
  speaker text NOT NULL CHECK (speaker IN ('user','assistant')),
  locale text NOT NULL CHECK (locale IN ('ru','uz','en')),
  body_text text NOT NULL CHECK (char_length(body_text) BETWEEN 1 AND 2400),
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  PRIMARY KEY (user_id,request_id,speaker)
);
CREATE INDEX iclub_ai_tutor_history_v1_read_idx
  ON private.iclub_ai_tutor_history_v1_messages(user_id,thread_key,created_at DESC);
CREATE INDEX iclub_ai_tutor_history_v1_expiry_idx
  ON private.iclub_ai_tutor_history_v1_messages(expires_at);

-- No direct table access, even for the authenticated PostgREST role.
ALTER TABLE private.iclub_ai_tutor_history_v1_control ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_ai_tutor_history_v1_optins ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_ai_tutor_history_v1_messages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_ai_tutor_history_v1_control,
 private.iclub_ai_tutor_history_v1_optins,
 private.iclub_ai_tutor_history_v1_messages
 FROM PUBLIC,anon,authenticated,service_role;

-- This RPC is an opt-in/draft candidate, NOT a source of academic evidence.
-- Replies are client-captured snapshots; NEVER feed these records to model
-- prompts, scoring, evidence, recommendation, or protected-test routes.
CREATE FUNCTION public.iclub_ai_tutor_history_service_v1(
 p_action text,
 p_thread_key text DEFAULT NULL,
 p_request_id uuid DEFAULT NULL,
 p_speaker text DEFAULT NULL,
 p_text text DEFAULT NULL,
 p_locale text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE
 v_uid uuid := auth.uid();
 v_config private.iclub_ai_tutor_history_v1_control%rowtype;
 v_status jsonb;
 v_consent boolean := false;
 v_messages jsonb := '[]'::jsonb;
 v_inserted boolean := false;
 v_count integer := 0;
BEGIN
 IF v_uid IS NULL OR current_setting('request.jwt.claim.role',true) IS DISTINCT FROM 'authenticated' THEN
   RETURN jsonb_build_object('ok',false,'reason','auth_required');
 END IF;
 -- Delete/withdraw is available even after an operator disables the feature.
 IF p_action='opt_out' THEN
   DELETE FROM private.iclub_ai_tutor_history_v1_messages WHERE user_id=v_uid;
   DELETE FROM private.iclub_ai_tutor_history_v1_optins WHERE user_id=v_uid;
   RETURN jsonb_build_object('ok',true,'consented',false,'deleted',true);
 END IF;
 SELECT * INTO v_config FROM private.iclub_ai_tutor_history_v1_control
 WHERE singleton=1;
 IF NOT FOUND OR v_config.enabled IS NOT TRUE THEN
   RETURN jsonb_build_object('ok',false,'reason','not_released');
 END IF;
 v_status:=public.get_iclub_ai_v21_beta_status_service(v_uid);
 IF coalesce((v_status->>'eligible')::boolean,false) IS NOT TRUE THEN
   RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled');
 END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(v_uid) IS DISTINCT FROM false THEN
   RETURN jsonb_build_object('ok',false,'reason','active_assessment');
 END IF;
 SELECT EXISTS(SELECT 1 FROM private.iclub_ai_tutor_history_v1_optins
   WHERE user_id=v_uid) INTO v_consent;
 IF p_action='status' THEN
   RETURN jsonb_build_object('ok',true,'consented',v_consent,
     'retention_hours',v_config.retention_hours);
 END IF;
 IF p_action='opt_in' THEN
   -- Only call after separately displayed, affirmative history-storage consent.
   INSERT INTO private.iclub_ai_tutor_history_v1_optins(user_id)
     VALUES(v_uid) ON CONFLICT(user_id) DO NOTHING;
   RETURN jsonb_build_object('ok',true,'consented',true);
 END IF;
 IF NOT v_consent THEN
   RETURN jsonb_build_object('ok',false,'reason','history_consent_required');
 END IF;
 -- A bounded, navigation-only key; never restore protected Practice attempt,
 -- Exam Prep skill, QA/test, or Tour thread from this draft data store.
 IF p_thread_key IS NULL OR char_length(p_thread_key)>80
    OR p_thread_key !~ '^[a-z][a-z0-9_-]*$'
    OR p_thread_key ~ '^(practice_attempt_|qa_|exam_prep|tour_)' THEN
   RETURN jsonb_build_object('ok',false,'reason','unsupported_thread');
 END IF;
 IF p_action='read' THEN
   SELECT coalesce(jsonb_agg(
     jsonb_build_object(
       'request_id',t.request_id,'role',t.speaker,
       'locale',t.locale,'text',t.body_text,'created_at',t.created_at
     ) ORDER BY t.created_at,t.request_id,
       CASE WHEN t.speaker='user' THEN 0 ELSE 1 END
   ),'[]'::jsonb) INTO v_messages
   FROM (
     SELECT request_id,speaker,locale,body_text,created_at
     FROM private.iclub_ai_tutor_history_v1_messages
     WHERE user_id=v_uid AND thread_key=p_thread_key AND expires_at>now()
     ORDER BY created_at DESC,request_id DESC,speaker DESC
     LIMIT 40
   ) AS t;
   RETURN jsonb_build_object('ok',true,'messages',v_messages,
     'provider_called',false,'academic_state_changed',false);
 ELSIF p_action='append' THEN
   IF p_request_id IS NULL OR p_speaker NOT IN ('user','assistant')
      OR p_locale NOT IN ('ru','uz','en') OR p_text IS NULL
      OR char_length(btrim(p_text)) NOT BETWEEN 1 AND 2400 THEN
     RETURN jsonb_build_object('ok',false,'reason','invalid_message');
   END IF;
   -- Bound a learner's distinct public-help threads, not only each thread's rows.
   SELECT count(DISTINCT thread_key) INTO v_count
   FROM private.iclub_ai_tutor_history_v1_messages
   WHERE user_id=v_uid AND expires_at>now();
   IF v_count>=25 AND NOT EXISTS(
     SELECT 1 FROM private.iclub_ai_tutor_history_v1_messages
     WHERE user_id=v_uid AND thread_key=p_thread_key AND expires_at>now()
   ) THEN
     RETURN jsonb_build_object('ok',false,'reason','thread_limit');
   END IF;
   -- Same-user request UUID/role is an idempotency key, never an overwrite.
   INSERT INTO private.iclub_ai_tutor_history_v1_messages(
      user_id,thread_key,request_id,speaker,locale,body_text,expires_at
   ) VALUES(v_uid,p_thread_key,p_request_id,p_speaker,p_locale,btrim(p_text),
      now()+make_interval(hours=>v_config.retention_hours))
   ON CONFLICT(user_id,request_id,speaker) DO NOTHING;
   v_inserted:=FOUND;
   -- Bound total stored visible history per thread; no academic tables touched.
   DELETE FROM private.iclub_ai_tutor_history_v1_messages m
   WHERE m.user_id=v_uid AND m.thread_key=p_thread_key
     AND m.ctid IN (
       SELECT ctid FROM private.iclub_ai_tutor_history_v1_messages
       WHERE user_id=v_uid AND thread_key=p_thread_key
       ORDER BY created_at DESC,request_id DESC,speaker DESC
       OFFSET 40
     );
   RETURN jsonb_build_object('ok',true,'inserted',v_inserted,
     'provider_called',false,'academic_state_changed',false);
 END IF;
 RETURN jsonb_build_object('ok',false,'reason','invalid_action');
END;
$fn$;
REVOKE ALL ON FUNCTION public.iclub_ai_tutor_history_service_v1(
 text,text,uuid,text,text,text) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.iclub_ai_tutor_history_service_v1(
 text,text,uuid,text,text,text) TO authenticated;

-- Physical expired-text removal remains a separate scheduled ops decision.
-- This operator-only primitive deletes NOTHING until invoked by an approved job.
CREATE FUNCTION private.iclub_ai_tutor_history_purge_expired_v1()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $fn$
DECLARE v_rows bigint;
BEGIN
 DELETE FROM private.iclub_ai_tutor_history_v1_messages WHERE expires_at<=now();
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 RETURN v_rows;
END;
$fn$;
REVOKE ALL ON FUNCTION private.iclub_ai_tutor_history_purge_expired_v1()
 FROM PUBLIC,anon,authenticated,service_role;
COMMIT;
