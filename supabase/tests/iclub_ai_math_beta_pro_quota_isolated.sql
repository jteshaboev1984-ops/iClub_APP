\set ON_ERROR_STOP on
-- Isolated PostgreSQL 17 synthetic users only; production SQL identical.
DO $v$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'Refusing test on a hosted database'; END IF;
END $v$;
-- Simulate source-of-truth tariff schema from the real production catalog.
ALTER TABLE private.iclub_plan_policies ADD COLUMN policy_version text, ADD COLUMN ai_usage_policy_code text;
INSERT INTO private.iclub_plan_policies(plan_code,is_active,policy_version,ai_usage_policy_code)
 VALUES('pro',true,'global_ai_tariffs_v1','pro_v1');
CREATE TABLE private.iclub_ai_usage_policies(
 usage_policy_code text, policy_version text,
 is_active boolean,period_seconds integer,
 allowance_units integer,generation_weight integer,prepared_weight integer);
INSERT INTO private.iclub_ai_usage_policies
 VALUES('pro_v1','global_ai_tariffs_v1',true,18000,14,5,1);
CREATE TABLE private.iclub_ai_v21_beta_help_sources(
 help_key text,locale text,message text,source_version text,
 source_hash text,publication_revision bigint,
 content_reviewed boolean,rights_reviewed boolean,locale_reviewed boolean,
 published boolean,revoked boolean,approved_at timestamptz);
ALTER TABLE private.iclub_ai_v21_beta_deliveries
 ADD COLUMN user_id uuid, ADD COLUMN help_key text, ADD COLUMN locale text,
 ADD COLUMN source_version text,ADD COLUMN source_hash text,
 ADD COLUMN publication_revision bigint,ADD COLUMN delivered_at timestamptz DEFAULT now();
-- Previous canary revocation test intentionally disabled one synthetic grant.
UPDATE private.iclub_ai_practice_beta_grants_v1 SET enabled=true
 WHERE user_id='00000000-0000-4000-8000-000000000011';
UPDATE private.iclub_ai_practice_context_v1_control SET error_enabled=false WHERE singleton=1;
-- Preserve the real legacy DDL constraints in the disposable integration test.
-- They existed in production but were absent from the earlier synthetic fixture.
ALTER TABLE private.iclub_ai_v21_freeform_quota_holds
 ADD CONSTRAINT iclub_ai_v21_freeform_quota_holds_weight_check CHECK (weight = 3);
ALTER TABLE private.iclub_ai_v21_beta_usage
 ADD CONSTRAINT iclub_ai_v21_beta_usage_committed_count_check
 CHECK (committed_count >= 0 AND committed_count <= 3);
\ir ../migrations/20261028113000_iclub_math_beta_pro_ai_quota_v1.sql
\ir ../migrations/20261028120000_iclub_math_beta_pro_quota_constraints_fix.sql
SET request.jwt.claim.role='service_role';
INSERT INTO private.iclub_ai_v21_beta_help_sources
 VALUES('practice_rules','ru','Проверьте завершённую попытку и исправьте ошибки.',
 'qa-1',encode(extensions.digest(convert_to('Проверьте завершённую попытку и исправьте ошибки.','UTF8'),'sha256'),'hex'),
 1,true,true,true,true,false,now());
DO $bounds$
DECLARE rejected boolean;
BEGIN
 rejected:=false;
 BEGIN
  INSERT INTO private.iclub_ai_v21_freeform_quota_holds
  (request_id,user_id,request_fingerprint,period_started_at,weight,state)
  VALUES('c0000011-0000-4000-8000-000000000001',
         '00000000-0000-4000-8000-000000000011',repeat('f',64),now(),4,'reserved');
 EXCEPTION WHEN check_violation THEN rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'Invalid generated weight 4 was accepted'; END IF;
 rejected:=false;
 BEGIN
  UPDATE private.iclub_ai_v21_beta_usage SET committed_count=15
  WHERE user_id='00000000-0000-4000-8000-000000000011';
 EXCEPTION WHEN check_violation THEN rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'Invalid 15-unit counter was accepted'; END IF;
 RAISE NOTICE 'PASS strict DB constraints: reject 4-unit holds and 15-unit usage';
END $bounds$;
DO $test$
DECLARE
 u uuid:='00000000-0000-4000-8000-000000000011';
 outsider uuid:='00000000-0000-4000-8000-000000000044';
 a uuid:='c0000001-0000-4000-8000-000000000001';
 b uuid:='c0000001-0000-4000-8000-000000000002';
 third uuid:='c0000001-0000-4000-8000-000000000003';
 fourth uuid:='c0000001-0000-4000-8000-000000000004';
 r jsonb;
 n integer;
 i integer;
BEGIN
 IF NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(u)
 OR private.iclub_ai_math_beta_pro_quota_eligible_v1(outsider)
 OR private.iclub_ai_math_beta_pro_quota_eligible_v1('00000000-0000-4000-8000-000000000022')
 THEN RAISE EXCEPTION 'Eligible beta and pending-consent users not isolated'; END IF;
 -- Synthetic quota reset is allowed ONLY in this disposable CI database.
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=0,started_at=now() WHERE user_id=u;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(a,u,repeat('a',64));
 IF r->>'allowed' IS DISTINCT FROM 'true' OR (r->>'weight')::int<>5
 THEN RAISE EXCEPTION 'First Pro generation not 5 units: %',r; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(b,u,repeat('b',64));
 IF r->>'allowed' IS DISTINCT FROM 'true' OR (r->>'weight')::int<>5
 THEN RAISE EXCEPTION 'Second Pro generation denied: %',r; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(third,u,repeat('c',64));
 IF r->>'reason' IS DISTINCT FROM 'usage_exhausted' OR r->>'reset_at' IS NULL
 THEN RAISE EXCEPTION 'Third generation must exceed 14 units: %',r; END IF;
 -- Releasing a 5-unit Pro generation must refund 5, NOT the legacy 3.
 r:=public.finish_iclub_ai_v21_freeform_quota_v1(b,u,repeat('b',64),'released');
 IF r->>'ok' IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'Refund denied: %',r; END IF;
 SELECT committed_count INTO n FROM private.iclub_ai_v21_beta_usage WHERE user_id=u;
 IF n<>5 THEN RAISE EXCEPTION 'Pro generation refunded incorrect units: %',n; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(third,u,repeat('c',64));
 IF r->>'allowed' IS DISTINCT FROM 'true' OR (r->>'weight')::int<>5
 THEN RAISE EXCEPTION 'Pro quota was not available after refund: %',r; END IF;
 -- Prepared Help shares the same Pro total. 10+4*1=14.
 FOR i IN 1..4 LOOP
  r:=public.deliver_iclub_ai_v21_beta_prepared_service(
    u,('c0000002-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'practice_rules','ru');
  IF r->>'ok' IS DISTINCT FROM 'true'
  THEN RAISE EXCEPTION 'Prepared Pro unit % denied: %',i,r; END IF;
 END LOOP;
 r:=public.deliver_iclub_ai_v21_beta_prepared_service(
   u,'c0000002-0000-4000-8000-000000000005','practice_rules','ru');
 IF r->>'reason' IS DISTINCT FROM 'usage_exhausted'
 THEN RAISE EXCEPTION 'Pro prepared overflow not denied: %',r; END IF;
 SELECT committed_count INTO n FROM private.iclub_ai_v21_beta_usage WHERE user_id=u;
 IF n<>14 THEN RAISE EXCEPTION 'Shared Pro units must total 14, not %',n; END IF;
 -- A consented account outside this beta continues at 3 units/generation.
 INSERT INTO private.iclub_ai_v21_beta_members VALUES(outsider,true,'global_ai_beta_v21',now());
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(fourth,outsider,repeat('d',64));
 IF r->>'allowed' IS DISTINCT FROM 'true' OR (r->>'weight')::int<>3
 THEN RAISE EXCEPTION 'Ordinary beta changed from legacy 3: %',r; END IF;
 r:=public.reserve_iclub_ai_v21_freeform_quota_v1(
  'c0000001-0000-4000-8000-000000000005',outsider,repeat('e',64));
 IF r->>'reason' IS DISTINCT FROM 'usage_exhausted'
 THEN RAISE EXCEPTION 'Ordinary beta 3 unit cap was bypassed: %',r; END IF;
 UPDATE private.iclub_ai_practice_beta_grants_v1 SET enabled=false WHERE user_id=u;
 IF private.iclub_ai_math_beta_pro_quota_eligible_v1(u)
 THEN RAISE EXCEPTION 'Revoked beta grant retained Pro quota'; END IF;
 RAISE NOTICE 'PASS Pro exactly 14/5h, generated weight5, prepared weight1, full refund5, ordinary beta unchanged, revocable';
END $test$;
SET request.jwt.claim.role='authenticated';
DO $deny$ BEGIN
 IF has_function_privilege('authenticated','private.iclub_ai_math_beta_pro_quota_eligible_v1(uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'Protected quota helper is publicly executable'; END IF;
END $deny$;
