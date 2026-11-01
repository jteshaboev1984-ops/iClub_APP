-- Strictly disposable CI-only! Run after P2-73-equivalent isolated migrations.
-- NEVER submit this fixture to a production/database connector.
\set ON_ERROR_STOP on
DO $$
BEGIN
  IF current_database() <> 'postgres' OR
     current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'REFUSED: requires disposable e2e_isolated database';
  END IF;
  IF EXISTS (SELECT 1 FROM auth.users) OR EXISTS (SELECT 1 FROM public.users) THEN
    RAISE EXCEPTION 'REFUSED: disposable database already contains users';
  END IF;
END $$;

-- The P0-15 bootstrap auth.uid() reads legacy per-claim GUCs. PostgREST
-- actually sets request.jwt.claims (JSON). This fixture makes auth.uid()
-- compatible with BOTH Supabase-style JWT contexts *in disposable CI only*.
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE SET search_path='' AS $$
 SELECT COALESCE(
   NULLIF(current_setting('request.jwt.claim.sub',true),''),
   NULLIF(current_setting('request.jwt.claims',true),'')::jsonb ->> 'sub'
 )::uuid
$$;

-- Do not use synthetic identities from any real cohort or production export.
INSERT INTO auth.users(id,aud,role,email)
VALUES
 ('11111111-1111-4111-8111-111111111191','authenticated','authenticated','math-e2e-a@localhost.invalid'),
 ('22222222-2222-4222-8222-222222222292','authenticated','authenticated','math-e2e-b@localhost.invalid');

INSERT INTO public.users(id,first_name,last_name,language_code)
VALUES
 ('11111111-1111-4111-8111-111111111191','Test','Learner A','en'),
 ('22222222-2222-4222-8222-222222222292','Test','Learner B','ru');

UPDATE private.exam_prep_feature_config SET
 rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,
 mentor_enabled=false,kill_switch=false,qa_open_all_core=false,qa_open_all_weekly=false
WHERE id=1;

INSERT INTO private.exam_prep_feature_entitlements
 (user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from)
VALUES
 ('11111111-1111-4111-8111-111111111191','active',true,false,false,NULL,now()-interval '1 minute'),
 ('22222222-2222-4222-8222-222222222292','active',true,false,false,NULL,now()-interval '1 minute');

DO $$
BEGIN
 IF (SELECT count(*) FROM public.users) <> 2 THEN
  RAISE EXCEPTION 'isolated synthetic user count wrong';
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_feature_entitlements
      WHERE core_access AND entitlement_status='active') <> 2 THEN
  RAISE EXCEPTION 'isolated entitlements mismatch';
 END IF;
END $$;
