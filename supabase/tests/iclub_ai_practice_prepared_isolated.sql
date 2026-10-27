\set ON_ERROR_STOP on
-- Disposable GitHub Actions PostgreSQL 17 only; synthetic rows.
DO $g$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: isolated database flag required'; END IF;
END $g$;
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS $$
 SELECT jsonb_build_object('role',current_setting('request.jwt.claim.role',true)) $$;
CREATE TABLE public.subjects(id bigint PRIMARY KEY,subject_key text,is_active boolean);
CREATE TABLE public.user_subjects(user_id uuid,subject_id bigint);
CREATE TABLE public.practice_attempts(
 id bigint PRIMARY KEY,user_id uuid,subject_id bigint,score integer,percent numeric,
 is_lab boolean,bank_generation integer);
CREATE TABLE public.practice_sessions_v4(
 id bigint PRIMARY KEY,user_id uuid,subject_id bigint,legacy_attempt_id bigint UNIQUE,
 bank_generation integer,status text,finalized_at timestamptz,
 pool_id bigint,question_ids bigint[]);
CREATE TABLE public.practice_session_answers_v4(
 session_id bigint,question_id bigint,answered_at timestamptz,is_correct boolean,
 PRIMARY KEY(session_id,question_id));
CREATE TABLE public.questions(id bigint PRIMARY KEY,subject_id bigint,is_active boolean,
 quality_status text);
CREATE TABLE private.iclub_ai_v21_academic_policy(singleton smallint PRIMARY KEY,
 enabled boolean,provider_enabled boolean);
CREATE TABLE private.iclub_ai_v21_beta_control(singleton smallint PRIMARY KEY,
 beta_enabled boolean,prepared_enabled boolean,generation_enabled boolean);
CREATE TABLE private.iclub_ai_v21_beta_members(user_id uuid,
 enabled boolean,consent_version text,consent_at timestamptz);
CREATE TABLE private.iclub_commercial_access_config(id smallint,lifecycle_enabled boolean);
CREATE TABLE private.iclub_subscription_entitlements(
 user_id uuid,entitlement_status text,plan_code text,valid_from timestamptz,valid_until timestamptz);
CREATE TABLE private.iclub_plan_policies(plan_code text,is_active boolean);
CREATE TABLE private.iclub_ai_v21_academic_sources(
 surface_code text,subject_key text,context_key text,locale text,
 source_card_key text,source_version text,body_text text,target_hash text,content_hash text);
CREATE TABLE private.isolated_protected_users(user_id uuid);
CREATE FUNCTION private.iclub_ai_has_active_protected_assessment_v1(p_user_id uuid)
 RETURNS boolean LANGUAGE sql STABLE AS $$
 SELECT EXISTS(SELECT 1 FROM private.isolated_protected_users WHERE user_id=p_user_id) $$;
CREATE FUNCTION public.iclub_practice_drill_question_protected_v4(p_question_id bigint)
 RETURNS boolean LANGUAGE sql STABLE AS $$ SELECT false $$;
-- Synthetic-only admission stub. Production source admission is not altered.
CREATE FUNCTION private.iclub_ai_v21_source_admitted_v1(
 src private.iclub_ai_v21_academic_sources)
 RETURNS boolean LANGUAGE sql STABLE AS $
 SELECT src.source_version='qa-approved-v1'
   AND src.source_card_key LIKE 'qa-approved-%'
   AND src.body_text LIKE 'Isolated approved synthetic %' $;
CREATE FUNCTION private.iclub_ai_v21_target_fingerprint_v1(p_surface text,p_id bigint)
 RETURNS text LANGUAGE sql STABLE AS $
 SELECT encode(extensions.digest(convert_to(p_surface||':'||p_id::text,'UTF8'),'sha256'),'hex') $;

-- Compile actual candidate; no placeholders in the candidate function body.
\ir ../candidates/iclub_ai_practice_context_v1_dormant.sql

DO $g$
DECLARE fn oid;
BEGIN
 fn:=to_regprocedure('public.get_iclub_ai_practice_context_v1_service(uuid,bigint,text,bigint,text)');
 IF fn IS NULL THEN RAISE EXCEPTION 'Function not compiled'; END IF;
 IF has_function_privilege('anon',fn,'EXECUTE')
 OR has_function_privilege('authenticated',fn,'EXECUTE')
 OR NOT has_function_privilege('service_role',fn,'EXECUTE')
 THEN RAISE EXCEPTION 'Unsafe function grants'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control WHERE enabled)
 THEN RAISE EXCEPTION 'Feature unexpectedly enabled'; END IF;
END $g$;

INSERT INTO public.subjects VALUES(5,'mathematics',true);
INSERT INTO public.user_subjects VALUES('00000000-0000-4000-8000-000000000011',5);
INSERT INTO private.iclub_ai_v21_academic_policy VALUES(1,true,false);
INSERT INTO private.iclub_ai_v21_beta_control VALUES(1,true,true,false);
INSERT INTO private.iclub_ai_v21_beta_members VALUES(
 '00000000-0000-4000-8000-000000000011',true,'global_ai_beta_v21',now());
INSERT INTO public.questions
 SELECT g,5,true,'published' FROM generate_series(1,10) AS g;
INSERT INTO public.practice_attempts VALUES
 (501,'00000000-0000-4000-8000-000000000011',5,7,70,false,NULL),
 (500,'00000000-0000-4000-8000-000000000011',5,8,80,false,NULL);
INSERT INTO public.practice_sessions_v4 VALUES
 (601,'00000000-0000-4000-8000-000000000011',5,501,2,'finalized',now(),11,
   ARRAY[1,2,3,4,5,6,7,8,9,10]::bigint[]),
 (600,'00000000-0000-4000-8000-000000000011',5,500,2,'finalized',
   now()-interval '1 day',11,ARRAY[1,2,3,4,5,6,7,8,9,10]::bigint[]);
INSERT INTO public.practice_session_answers_v4
 SELECT 601,g,now(),g NOT IN(2,6,9) FROM generate_series(1,10) AS g
 UNION ALL SELECT 600,g,now()-interval '1 day',g NOT IN(5,7)
 FROM generate_series(1,10) AS g;

-- Service authorization is simulated by a synthetic JWT claim, never production keys.
SELECT set_config('request.jwt.claim.role','service_role',false);
DO $g$
DECLARE r jsonb;
 uid uuid:='00000000-0000-4000-8000-000000000011';
BEGIN
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_result',null,'ru') INTO r;
 IF r->>'reason' IS DISTINCT FROM 'not_enabled' THEN
  RAISE EXCEPTION 'OFF gate failed %',r; END IF;
 UPDATE private.iclub_ai_practice_context_v1_control SET enabled=true WHERE singleton=1;
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_visibility',null,'ru') INTO r;
 IF r->>'ok' IS DISTINCT FROM 'true' OR r->'context'->>'intent' IS DISTINCT FROM 'practice_visibility'
 THEN RAISE EXCEPTION 'Visibility gate failed %',r; END IF;
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_result',null,'ru') INTO r;
 IF r->>'ok' IS DISTINCT FROM 'true' OR
   (r->'context'->>'correct')::int<>7 OR
   (r->'context'->>'total')::int<>10 OR
   (r->'context'->>'percentage')::numeric<>70 OR
   (r->'context'->'reviewable_error_ordinals')::text<>'[2, 6, 9]'
 THEN RAISE EXCEPTION 'Verified 7/10 failed %',r; END IF;
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,
   'practice_history_comparison',null,'ru') INTO r;
 IF r->'context'->'comparison'->>'previous_percentage' IS DISTINCT FROM '80.0'
 THEN RAISE EXCEPTION 'History comparison failed %',r; END IF;
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',2,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'source_not_ready'
 THEN RAISE EXCEPTION 'Missing source falsely admitted %',r; END IF;
 -- Two languages alone cannot unlock a question-specific explanation.
 INSERT INTO private.iclub_ai_v21_academic_sources(
  surface_code,subject_key,context_key,locale,source_card_key,
  source_version,body_text,target_hash,content_hash)
 SELECT 'practice_error','mathematics','question_2',lang,
  'qa-approved-'||lang,'qa-approved-v1','Isolated approved synthetic '||lang,
  private.iclub_ai_v21_target_fingerprint_v1('practice_error',2),
  encode(extensions.digest(convert_to('Isolated approved synthetic '||lang,'UTF8'),'sha256'),'hex')
 FROM (VALUES ('ru'::text),('en'::text)) q(lang);
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',2,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'source_not_ready'
 THEN RAISE EXCEPTION 'Two-language source incorrectly admitted %',r; END IF;
 INSERT INTO private.iclub_ai_v21_academic_sources(
  surface_code,subject_key,context_key,locale,source_card_key,
  source_version,body_text,target_hash,content_hash)
 SELECT 'practice_error','mathematics','question_2','uz',
  'qa-approved-uz','qa-approved-v1','Isolated approved synthetic uz',
  private.iclub_ai_v21_target_fingerprint_v1('practice_error',2),
  encode(extensions.digest(convert_to('Isolated approved synthetic uz','UTF8'),'sha256'),'hex');
 FOR r IN SELECT public.get_iclub_ai_practice_context_v1_service(
  uid,501,'practice_error',2,l) FROM (VALUES ('ru'),('en'),('uz')) q(l)
 LOOP
  IF r->>'source_status' IS DISTINCT FROM 'ready'
  THEN RAISE EXCEPTION 'Valid triple source was not admitted %',r; END IF;
 END LOOP;
 UPDATE private.iclub_ai_v21_academic_sources
 SET content_hash=repeat('f',64) WHERE context_key='question_2' AND locale='uz';
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',2,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'source_not_ready'
 THEN RAISE EXCEPTION 'Tampered translation hash incorrectly admitted %',r; END IF;
 UPDATE private.iclub_ai_v21_academic_sources SET
  content_hash=encode(extensions.digest(convert_to(body_text,'UTF8'),'sha256'),'hex'),
  source_version='qa-approved-v0'
  WHERE context_key='question_2' AND locale='uz';
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',2,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'source_not_ready'
 THEN RAISE EXCEPTION 'Mixed-version translation incorrectly admitted %',r; END IF;
 UPDATE private.iclub_ai_v21_academic_sources SET
  source_version='qa-approved-v1',target_hash=repeat('a',64)
  WHERE context_key='question_2' AND locale='uz';
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',2,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'source_not_ready'
 THEN RAISE EXCEPTION 'Stale question fingerprint incorrectly admitted %',r; END IF;
 UPDATE private.iclub_ai_v21_academic_sources SET
  target_hash=private.iclub_ai_v21_target_fingerprint_v1('practice_error',2)
  WHERE context_key='question_2' AND locale='uz';
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',2,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'ready'
 THEN RAISE EXCEPTION 'Correct source pack not restored %',r; END IF;
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',6,'ru') INTO r;
 IF r->>'source_status' IS DISTINCT FROM 'source_not_ready'
 THEN RAISE EXCEPTION 'Other wrong question borrowed source %',r; END IF;
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_error',1,'ru') INTO r;
 IF r->>'reason' IS DISTINCT FROM 'question_not_eligible'
 THEN RAISE EXCEPTION 'Correct answer falsely exposed %',r; END IF;
 SELECT public.get_iclub_ai_practice_context_v1_service(
 '00000000-0000-4000-8000-000000000022',501,'practice_result',null,'ru') INTO r;
 IF r->>'ok' IS DISTINCT FROM 'false'
 THEN RAISE EXCEPTION 'Other user admitted %',r; END IF;
 INSERT INTO private.isolated_protected_users VALUES(uid);
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_result',null,'ru') INTO r;
 IF r->>'reason' IS DISTINCT FROM 'active_assessment'
 THEN RAISE EXCEPTION 'Protected assessment not blocked %',r; END IF;
 DELETE FROM private.isolated_protected_users;
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 SELECT public.get_iclub_ai_practice_context_v1_service(uid,501,'practice_result',null,'ru') INTO r;
 IF r->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'JWT role bypass %',r; END IF;
 RAISE NOTICE 'PASS: compiled, off gate, 7/10, owner, trilingual source version/hash/target, protection and grants';
END $g$;
