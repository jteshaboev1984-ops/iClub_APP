-- Issue #450 D3: strictly disposable PostgreSQL17/JWT fixtures.
-- Apply after base auth seed, NEVER against Supabase production.
\set ON_ERROR_STOP on
DO $$
BEGIN
 IF current_database()<>'postgres' OR
    current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR
    (select count(*) from public.users)<>2 OR
    (select count(*) from auth.users)<>2 THEN
  RAISE EXCEPTION 'D3 REFUSED: isolated two-learner harness required';
 END IF;
 IF exists(select 1 from auth.users where id in
   ('33333333-3333-4333-8333-333333333393','44444444-4444-4444-8444-444444444494')) THEN
  RAISE EXCEPTION 'D3 fresh test users required';
 END IF;
END $$;
INSERT INTO auth.users(id,aud,role,email) VALUES
('33333333-3333-4333-8333-333333333393','authenticated','authenticated','d3-server@localhost.invalid'),
('44444444-4444-4444-8444-444444444494','authenticated','authenticated','d3-browser@localhost.invalid');
INSERT INTO public.users(id,first_name,last_name,language_code) VALUES
('33333333-3333-4333-8333-333333333393','D3','Server Only','en'),
('44444444-4444-4444-8444-444444444494','D3','Browser Only','ru');
INSERT INTO private.exam_prep_feature_entitlements
(user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from)
VALUES
('33333333-3333-4333-8333-333333333393','active',true,false,false,NULL,now()-interval '1 minute'),
('44444444-4444-4444-8444-444444444494','active',true,false,false,NULL,now()-interval '1 minute');
