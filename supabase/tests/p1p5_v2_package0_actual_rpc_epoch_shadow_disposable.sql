-- Issue #450 P0-16. ABSOLUTELY DISPOSABLE PG17 ONLY. NOT A MIGRATION.
-- Add a test-only epoch gate to six REAL current Exam Prep writer RPCs,
-- preserving their actual return logic. No real learner data or deployment.
-- This test proves only an explicitly enumerated subset, NOT 37+ RPC coverage.
\set ON_ERROR_STOP on
DO $guard$
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR current_setting('server_version_num')::integer<170000
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR NOT EXISTS(SELECT 1 FROM public.users
   WHERE id='11111111-1111-4111-8111-111111111191'::uuid)
 OR NOT EXISTS(SELECT 1 FROM public.users
   WHERE id='22222222-2222-4222-8222-222222222292'::uuid)
 OR to_regclass('private.p0_16_academic_epoch_gate') IS NOT NULL
 OR EXISTS(
   SELECT 1 FROM information_schema.columns WHERE table_schema='private'
   AND table_name='exam_prep_sessions' AND column_name='p0_16_issued_epoch')
 THEN RAISE EXCEPTION 'REFUSED P0-16 shadow epoch: only fresh disposable 2-user PG17'; END IF;
END $guard$;

CREATE TABLE private.p0_16_academic_epoch_gate(
 program_key text PRIMARY KEY,
 epoch integer NOT NULL CHECK(epoch BETWEEN 1 AND 2),
 paused boolean NOT NULL,
 min_signed_jwt_iat bigint NOT NULL DEFAULT 0
);
ALTER TABLE private.p0_16_academic_epoch_gate ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.p0_16_academic_epoch_gate FROM public,anon,authenticated;
INSERT INTO private.p0_16_academic_epoch_gate(program_key,epoch,paused,min_signed_jwt_iat)
VALUES ('math_as_p1_p5',1,false,0),('economics_as',1,false,0);

-- Existing synthetic prelaunch sessions are bound to epoch 1; the future
-- migration would use a reviewed non-test column name and migration process.
ALTER TABLE private.exam_prep_sessions
 ADD COLUMN p0_16_issued_epoch integer NOT NULL DEFAULT 1
 CHECK(p0_16_issued_epoch BETWEEN 1 AND 2);
ALTER TABLE private.exam_prep_session_authorizations
 ADD COLUMN p0_16_issued_epoch integer NOT NULL DEFAULT 1
 CHECK(p0_16_issued_epoch BETWEEN 1 AND 2);

CREATE OR REPLACE FUNCTION private.p0_16_require_current_epoch_v1(
 p_user_id uuid,p_session_id uuid DEFAULT NULL
) RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE
 v_claims jsonb;
 v_iat_text text;
 v_iat bigint;
 v_current_epoch integer;
 v_paused boolean;
 v_cutoff bigint;
 v_session_epoch integer;
BEGIN
 IF current_database()<>'postgres'
 OR to_regclass('private.p0_16_academic_epoch_gate') IS NULL
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 THEN RAISE EXCEPTION 'p0_16_disposable_only' USING ERRCODE='42501'; END IF;
 IF auth.uid() IS NULL OR auth.uid() IS DISTINCT FROM p_user_id
 OR p_user_id NOT IN (
   '11111111-1111-4111-8111-111111111191'::uuid,
   '22222222-2222-4222-8222-222222222292'::uuid)
 THEN RAISE EXCEPTION 'p0_16_signed_owner_required' USING ERRCODE='42501'; END IF;

 -- Reading server-controlled gate FOR SHARE serializes each real RPC write
 -- with the opposing release-maintenance row UPDATE.
 SELECT g.epoch,g.paused,g.min_signed_jwt_iat
 INTO v_current_epoch,v_paused,v_cutoff
 FROM private.p0_16_academic_epoch_gate g
 WHERE g.program_key='math_as_p1_p5'
 FOR SHARE;
 IF NOT FOUND OR v_paused THEN
   RAISE EXCEPTION 'p0_16_maintenance_paused' USING ERRCODE='PT409';
 END IF;
 v_claims:=NULLIF(current_setting('request.jwt.claims',true),'')::jsonb;
 v_iat_text:=v_claims->>'iat';
 IF v_iat_text IS NULL OR v_iat_text !~ '^[0-9]{10,12}$' THEN
   RAISE EXCEPTION 'p0_16_signed_iat_missing' USING ERRCODE='42501';
 END IF;
 v_iat:=v_iat_text::bigint;
 IF v_iat<v_cutoff THEN
   RAISE EXCEPTION 'p0_16_old_signed_jwt' USING ERRCODE='PT409';
 END IF;
 IF p_session_id IS NOT NULL THEN
   SELECT s.p0_16_issued_epoch INTO v_session_epoch
   FROM private.exam_prep_sessions s
   WHERE s.id=p_session_id AND s.user_id=p_user_id;
   IF NOT FOUND OR v_session_epoch IS DISTINCT FROM v_current_epoch THEN
     RAISE EXCEPTION 'p0_16_stale_session_epoch' USING ERRCODE='PT409';
   END IF;
 END IF;
END $fn$;
REVOKE ALL ON FUNCTION private.p0_16_require_current_epoch_v1(uuid,uuid)
 FROM public,anon,authenticated;

-- Future starts are stamped only by a server-controlled trigger. It does not
-- trust a browser-supplied epoch in a request body.
CREATE OR REPLACE FUNCTION private.p0_16_stamp_new_session_v1()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE v_epoch integer;
BEGIN
 PERFORM private.p0_16_require_current_epoch_v1(NEW.user_id,NULL::uuid);
 SELECT epoch INTO v_epoch FROM private.p0_16_academic_epoch_gate
 WHERE program_key='math_as_p1_p5' FOR SHARE;
 NEW.p0_16_issued_epoch:=v_epoch;
 RETURN NEW;
END $fn$;
REVOKE ALL ON FUNCTION private.p0_16_stamp_new_session_v1()
 FROM public,anon,authenticated;
CREATE TRIGGER p0_16_stamp_new_session_fixture
 BEFORE INSERT ON private.exam_prep_sessions
 FOR EACH ROW EXECUTE FUNCTION private.p0_16_stamp_new_session_v1();


-- Both server-issued authorization AND accepted session are epoch-owned.
-- A new valid JWT cannot revive an old prelaunch authorization.
CREATE OR REPLACE FUNCTION private.p0_16_require_issued_authorization_epoch_v1(
 p_user_id uuid,p_authorization_id uuid
) RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE v_current integer; v_issued integer;
BEGIN
 PERFORM private.p0_16_require_current_epoch_v1(p_user_id,NULL::uuid);
 SELECT g.epoch INTO v_current
 FROM private.p0_16_academic_epoch_gate g
 WHERE g.program_key='math_as_p1_p5' FOR SHARE;
 SELECT a.p0_16_issued_epoch INTO v_issued
 FROM private.exam_prep_session_authorizations a
 WHERE a.id=p_authorization_id AND a.user_id=p_user_id;
 IF NOT FOUND OR v_issued IS DISTINCT FROM v_current THEN
  RAISE EXCEPTION 'p0_16_stale_issued_authorization' USING ERRCODE='PT409';
 END IF;
END $fn$;
REVOKE ALL ON FUNCTION private.p0_16_require_issued_authorization_epoch_v1(uuid,uuid)
 FROM public,anon,authenticated;

CREATE OR REPLACE FUNCTION private.p0_16_stamp_new_authorization_v1()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE v_epoch integer;
BEGIN
 PERFORM private.p0_16_require_current_epoch_v1(NEW.user_id,NULL::uuid);
 SELECT epoch INTO v_epoch FROM private.p0_16_academic_epoch_gate
 WHERE program_key='math_as_p1_p5' FOR SHARE;
 NEW.p0_16_issued_epoch:=v_epoch;
 RETURN NEW;
END $fn$;
REVOKE ALL ON FUNCTION private.p0_16_stamp_new_authorization_v1()
 FROM public,anon,authenticated;
CREATE TRIGGER p0_16_stamp_new_authorization_fixture
 BEFORE INSERT ON private.exam_prep_session_authorizations
 FOR EACH ROW EXECUTE FUNCTION private.p0_16_stamp_new_authorization_v1();

-- Inject the guarded epoch check into the genuine, migrated source of SIX
-- named public writer functions and NO others. Unmatched source is a hard error.
-- The schema change is strictly inside the disposable CI process; never copy
-- the generated CREATE OR REPLACE statements into a production migration.
DO $install$
DECLARE
 v_signature text;
 v_source text;
 v_anchor text:='v_uid:=private.exam_prep_require_core_access_v1();';
 v_new text;
 v_oid oid;
 v_session_argument text;
 v_count integer:=0;
BEGIN
 FOR v_signature IN SELECT unnest(ARRAY[
  'public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)',
  'public.start_exam_prep_next_diagnostic_safe_v1(text,text)',
  'public.authorize_exam_prep_timed_safe_v1(bigint)',
  'public.start_exam_prep_session_safe_v1(uuid,text)',
  'public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)',
  'public.finalize_exam_prep_session_safe_v1(uuid,text)'
 ]) LOOP
   v_oid:=to_regprocedure(v_signature);
   IF v_oid IS NULL THEN
     RAISE EXCEPTION 'P0-16 refusing unknown actual RPC %',v_signature; END IF;
   v_source:=pg_get_functiondef(v_oid);
   IF (length(v_source)-length(replace(v_source,v_anchor,'')))<>length(v_anchor)
   OR v_source NOT ILIKE '%SECURITY DEFINER%'
   OR v_source NOT LIKE '%private.exam_prep_require_core_access_v1()%'
   THEN RAISE EXCEPTION 'P0-16 refusing RPC source drift %',v_signature; END IF;
   v_session_argument:=CASE WHEN v_signature LIKE '%submit_exam_prep_response%'
      OR v_signature LIKE '%finalize_exam_prep_session%' THEN 'p_session_id'
      ELSE 'NULL::uuid' END;
   v_new:=replace(v_source,v_anchor,
       v_anchor||E'\n  PERFORM private.p0_16_require_current_epoch_v1(v_uid,'||
       v_session_argument||');'||
       CASE WHEN v_signature LIKE 'public.start_exam_prep_session_safe_v1%'
         THEN E'\n  PERFORM private.p0_16_require_issued_authorization_epoch_v1(v_uid,p_authorization_id);'
         ELSE '' END);
   EXECUTE v_new;
   v_count:=v_count+1;
 END LOOP;
 IF v_count<>6 THEN RAISE EXCEPTION 'P0-16 incomplete RPC patch count %',v_count; END IF;
 RAISE NOTICE 'PASS P0-16 six genuine public writer entrypoints have disposable epoch fence';
END $install$;

DO $rights$
BEGIN
 IF has_table_privilege('authenticated','private.p0_16_academic_epoch_gate','UPDATE')
 OR has_table_privilege('anon','private.p0_16_academic_epoch_gate','UPDATE')
 OR has_function_privilege('authenticated',
    'private.p0_16_require_current_epoch_v1(uuid,uuid)','EXECUTE')
 OR has_function_privilege('authenticated',
    'private.p0_16_require_issued_authorization_epoch_v1(uuid,uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'P0-16 browser can bypass maintenance or write fence'; END IF;
END $rights$;
