\set ON_ERROR_STOP on
-- Disposable test of the actual activation transaction, never production accounts.
DO $guard$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'Isolated PostgreSQL is mandatory'; END IF;
END $guard$;
CREATE TABLE private.exam_prep_feature_config(
 id smallint PRIMARY KEY,rollout_state text,core_enabled boolean,
 ai_enabled boolean,kill_switch boolean);
CREATE TABLE private.exam_prep_optional_capability_status(
 capability_code text PRIMARY KEY,runtime_status text);
INSERT INTO private.exam_prep_feature_config
 VALUES(1,'controlled_beta',true,true,false);
INSERT INTO private.exam_prep_optional_capability_status
 VALUES('ai_assist','ready');
INSERT INTO private.exam_prep_beta_members VALUES
 ('00000000-0000-4000-8000-000000000022',71,'active','ai_assist'),
 ('00000000-0000-4000-8000-000000000033',71,'active','ai_assist');
INSERT INTO private.exam_prep_beta_consents VALUES
 ('00000000-0000-4000-8000-000000000022',71,'exam_prep_controlled_beta_v1','granted',NULL),
 ('00000000-0000-4000-8000-000000000033',71,'exam_prep_controlled_beta_v1','granted',NULL);
INSERT INTO private.exam_prep_feature_entitlements VALUES
 ('00000000-0000-4000-8000-000000000022','active',true,true,NULL,NULL),
 ('00000000-0000-4000-8000-000000000033','active',true,true,NULL,NULL);
INSERT INTO private.iclub_ai_v21_beta_members VALUES
 ('00000000-0000-4000-8000-000000000022',false,NULL,NULL),
 ('00000000-0000-4000-8000-000000000033',false,NULL,NULL);
\ir ../candidates/iclub_ai_practice_math_beta_activation_v1.sql
SET request.jwt.claim.role='service_role';
DO $verify$
DECLARE r jsonb;
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 OR EXISTS (SELECT 1 FROM private.iclub_ai_practice_context_v1_control
    WHERE NOT enabled OR owner_user_id IS NOT NULL OR error_enabled)
 OR EXISTS (SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control WHERE NOT enabled)
 OR EXISTS (SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control WHERE NOT enabled)
 THEN RAISE EXCEPTION 'Activation incomplete or academic-error exposure'; END IF;
 r:=public.get_iclub_ai_practice_context_v1_service(
   '00000000-0000-4000-8000-000000000011',501,'practice_result',NULL,'ru');
 IF r->>'ok' IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'Already-consented beta owner denied %',r; END IF;
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'released' IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'Funded route not released for approved grant %',r; END IF;
 r:=public.get_iclub_ai_practice_context_v1_service(
   '00000000-0000-4000-8000-000000000022',501,'practice_result',NULL,'ru');
 IF r->>'reason' IS DISTINCT FROM 'not_enabled'
 THEN RAISE EXCEPTION 'Unconsented beta got AI context %',r; END IF;
 UPDATE private.iclub_ai_practice_beta_grants_v1
  SET enabled=false WHERE user_id='00000000-0000-4000-8000-000000000011';
 r:=public.get_iclub_ai_practice_context_v1_service(
   '00000000-0000-4000-8000-000000000011',501,'practice_result',NULL,'ru');
 IF r->>'reason' IS DISTINCT FROM 'not_enabled'
 THEN RAISE EXCEPTION 'Revoked beta individual still authorized %',r; END IF;
 RAISE NOTICE 'PASS exact 3 enrollment, canary gate, 2 Global AI consent pending, private revocation and academic-error OFF';
END $verify$;
