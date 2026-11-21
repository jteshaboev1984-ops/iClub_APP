\set ON_ERROR_STOP on
-- Isolated PostgreSQL 17 contract. Claim emulation here is NOT signed HTTP E2E.
DO $$ BEGIN
 IF current_setting('iclub.tutor_history_isolated',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: separate disposable PostgreSQL17 required'; END IF;
END $$;

CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA private;
GRANT USAGE ON SCHEMA auth TO authenticated,anon;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE
AS $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
CREATE TABLE private.qa_protected(user_id uuid PRIMARY KEY);
CREATE FUNCTION private.iclub_ai_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE AS $$
 SELECT EXISTS(SELECT 1 FROM private.qa_protected WHERE user_id=p_user_id)
$$;
CREATE TABLE private.iclub_ai_v21_beta_members(
 user_id uuid PRIMARY KEY,enabled boolean,consent_version text,consent_at timestamptz
);
CREATE FUNCTION public.get_iclub_ai_v21_beta_status_service(p_user_id uuid)
RETURNS jsonb LANGUAGE sql STABLE AS $$
 SELECT jsonb_build_object('eligible',EXISTS(
 SELECT 1 FROM private.iclub_ai_v21_beta_members
 WHERE user_id=p_user_id AND enabled AND consent_version='global_ai_beta_v21'
 AND consent_at IS NOT NULL))
$$;
-- Synthetic objective/academic state acts as unchanged sentinel.
CREATE TABLE private.qa_core_grade(user_id uuid PRIMARY KEY,score integer NOT NULL);
INSERT INTO private.qa_core_grade VALUES
 ('00000000-0000-4000-8000-000000000011',17);
INSERT INTO private.iclub_ai_v21_beta_members VALUES
 ('00000000-0000-4000-8000-000000000011',true,'global_ai_beta_v21',now()),
 ('00000000-0000-4000-8000-000000000022',true,'global_ai_beta_v21',now());
\ir ../candidates/iclub_ai_tutor_history_v1_owner_gated_dormant.sql

DO $verify$
BEGIN
 IF (SELECT enabled FROM private.iclub_ai_tutor_history_v1_control WHERE singleton=1)
 THEN RAISE EXCEPTION 'history turned ON by migration'; END IF;
 IF has_table_privilege('authenticated','private.iclub_ai_tutor_history_v1_messages','SELECT')
    OR has_table_privilege('authenticated','private.iclub_ai_tutor_history_v1_messages','INSERT')
    OR has_table_privilege('anon','private.iclub_ai_tutor_history_v1_messages','SELECT')
    OR has_table_privilege('service_role','private.iclub_ai_tutor_history_v1_messages','SELECT')
 THEN RAISE EXCEPTION 'transcript table privileges leaked'; END IF;
 IF has_function_privilege('anon',
      'public.iclub_ai_tutor_history_service_v1(text,text,uuid,text,text,text)','EXECUTE')
    OR has_function_privilege('service_role',
      'public.iclub_ai_tutor_history_service_v1(text,text,uuid,text,text,text)','EXECUTE')
    OR NOT has_function_privilege('authenticated',
      'public.iclub_ai_tutor_history_service_v1(text,text,uuid,text,text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'history RPC grants unsafe'; END IF;
 IF has_function_privilege('authenticated',
      'private.iclub_ai_tutor_history_purge_expired_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'purge RPC publicly executable'; END IF;
END;
$verify$;

-- AUTHENTICATED caller, fixed test claims. Real bearer validation is a later gate.
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.role','authenticated',false);
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000011',false);
DO $verify$
DECLARE v jsonb;
BEGIN
 v:=public.iclub_ai_tutor_history_service_v1('opt_in');
 IF v->>'reason'<>'not_released' THEN RAISE EXCEPTION 'default OFF bypass: %',v; END IF;
END;
$verify$;
RESET ROLE;
UPDATE private.iclub_ai_tutor_history_v1_control SET enabled=true WHERE singleton=1;
SET ROLE authenticated;
DO $verify$
DECLARE v jsonb;
BEGIN
 v:=public.iclub_ai_tutor_history_service_v1('read','mathematics');
 IF v->>'reason'<>'history_consent_required' THEN RAISE EXCEPTION 'read without opt-in: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','mathematics',
  '11111111-1111-4111-8111-111111111111','user','Practice nima uchun kerak?','uz');
 IF v->>'reason'<>'history_consent_required' THEN RAISE EXCEPTION 'write without opt-in: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('opt_in');
 IF (v->>'consented')::boolean IS DISTINCT FROM true THEN RAISE EXCEPTION 'opt in failed: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','mathematics',
  '11111111-1111-4111-8111-111111111111','user','Practice nima uchun kerak?','uz');
 IF (v->>'inserted')::boolean IS DISTINCT FROM true THEN RAISE EXCEPTION 'append failed: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','mathematics',
  '11111111-1111-4111-8111-111111111111','user','TAMPERED','uz');
 IF (v->>'inserted')::boolean IS DISTINCT FROM false THEN RAISE EXCEPTION 'replay overwrite: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','mathematics',
  '11111111-1111-4111-8111-111111111111','assistant',
  'Practice: mavzu tanlang va natijalarni ko‘ring.','uz');
 IF (v->>'inserted')::boolean IS DISTINCT FROM true THEN RAISE EXCEPTION 'paired reply failed: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('read','mathematics');
 IF jsonb_array_length(v->'messages')<>2
   OR v->'messages'->0->>'text'<>'Practice nima uchun kerak?'
   OR v->'messages'->1->>'role'<>'assistant'
   OR (v->>'provider_called')::boolean IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'transcript replay/ordering/provider invariant: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','practice_attempt_901',
  '22222222-2222-4222-8222-222222222222','user','secret answer','en');
 IF v->>'reason'<>'unsupported_thread' THEN RAISE EXCEPTION 'Practice protected thread stored: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','exam_prep_p1_skill_3',
  '22222222-2222-4222-8222-222222222222','user','hidden paper','en');
 IF v->>'reason'<>'unsupported_thread' THEN RAISE EXCEPTION 'Exam protected thread stored: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','mathematics',
  '33333333-3333-4333-8333-333333333333','user','', 'en');
 IF v->>'reason'<>'invalid_message' THEN RAISE EXCEPTION 'empty message allowed: %',v; END IF;
END;
$verify$;
RESET ROLE;
DO $verify$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_tutor_history_v1_messages)<>2
 OR (SELECT score FROM private.qa_core_grade LIMIT 1)<>17
 THEN RAISE EXCEPTION 'unexpected academic state mutation'; END IF;
END;
$verify$;

-- A different authenticated learner must never see or delete first owner's chat.
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000022',false);
DO $verify$
DECLARE v jsonb;
BEGIN
 v:=public.iclub_ai_tutor_history_service_v1('opt_in');
 IF (v->>'consented')::boolean IS DISTINCT FROM true THEN RAISE EXCEPTION 'second optin failed'; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('read','mathematics');
 IF jsonb_array_length(v->'messages')<>0 THEN RAISE EXCEPTION 'cross-user read leaked: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('opt_out');
 IF (v->>'deleted')::boolean IS DISTINCT FROM true THEN RAISE EXCEPTION 'own logout delete failed: %',v; END IF;
END;
$verify$;
RESET ROLE;
DO $verify$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_tutor_history_v1_messages)<>2
 THEN RAISE EXCEPTION 'another account deleted owner chat'; END IF;
END;
$verify$;

-- Protected assessment blocks otherwise eligible, consented owner's reads/writes.
INSERT INTO private.qa_protected VALUES ('00000000-0000-4000-8000-000000000011');
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000011',false);
DO $verify$
DECLARE v jsonb;
BEGIN
 v:=public.iclub_ai_tutor_history_service_v1('read','mathematics');
 IF v->>'reason'<>'active_assessment' THEN RAISE EXCEPTION 'protected replay: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('append','mathematics',
 '44444444-4444-4444-8444-444444444444','assistant','a hidden exam clue','en');
 IF v->>'reason'<>'active_assessment' THEN RAISE EXCEPTION 'protected append: %',v; END IF;
END;
$verify$;
RESET ROLE;
DELETE FROM private.qa_protected;

-- Expired rows are hidden immediately and physically removable only by operator.
UPDATE private.iclub_ai_tutor_history_v1_messages
  SET expires_at=now()-interval '1 minute'
  WHERE user_id='00000000-0000-4000-8000-000000000011';
SET ROLE authenticated;
DO $verify$
DECLARE v jsonb;
BEGIN
 v:=public.iclub_ai_tutor_history_service_v1('read','mathematics');
 IF jsonb_array_length(v->'messages')<>0 THEN RAISE EXCEPTION 'expired text served: %',v; END IF;
 -- Explicit opt-out works even if operator disabled new writes.
END;
$verify$;
RESET ROLE;
DO $verify$
BEGIN
 IF private.iclub_ai_tutor_history_purge_expired_v1()<>2
 THEN RAISE EXCEPTION 'expired text was not purged'; END IF;
END;
$verify$;
UPDATE private.iclub_ai_tutor_history_v1_control SET enabled=false WHERE singleton=1;
SET ROLE authenticated;
DO $verify$
DECLARE v jsonb;
BEGIN
 v:=public.iclub_ai_tutor_history_service_v1('opt_out');
 IF v->>'deleted'<>'true' THEN RAISE EXCEPTION 'opt-out disabled by operator kill: %',v; END IF;
 v:=public.iclub_ai_tutor_history_service_v1('read','mathematics');
 IF v->>'reason'<>'not_released' THEN RAISE EXCEPTION 'disabled read allowed: %',v; END IF;
END;
$verify$;
RESET ROLE;
SELECT 'PASS isolated history: default OFF; explicit opt-in; owner-only; protected denied; idempotent; bounded; expired; delete; no provider/academic state' AS result;
