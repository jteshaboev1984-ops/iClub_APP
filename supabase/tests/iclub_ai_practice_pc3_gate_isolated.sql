\set ON_ERROR_STOP on
-- Requires earlier PC1/PC4 disposable SQL fixture in same PostgreSQL 17 job.
DO $v$ BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: isolated PostgreSQL only'; END IF;
END $v$;
ALTER TABLE private.iclub_ai_v21_beta_control
 ADD COLUMN approved_release text NOT NULL DEFAULT 'none';
CREATE TABLE private.iclub_ai_v21_freeform_budget_control(
 singleton smallint PRIMARY KEY,
 enabled boolean NOT NULL,owner_permitted boolean NOT NULL,
 include_free_beta boolean NOT NULL,model text NOT NULL,
 maximum_lifetime_microusd bigint NOT NULL,
 maximum_per_request_microusd bigint NOT NULL,
 maximum_per_learner_microusd bigint NOT NULL,
 maximum_parallel smallint NOT NULL,output_token_cap smallint NOT NULL,
 input_microusd_per_token numeric NOT NULL,
 output_microusd_per_token numeric NOT NULL
);
INSERT INTO private.iclub_ai_v21_freeform_budget_control
VALUES(1,true,true,true,'gpt-5.4-mini',5000000,50000,750000,2,384,0.75,4.5);
UPDATE private.iclub_ai_v21_beta_control
 SET approved_release='owner_beta' WHERE singleton=1;
\ir ../candidates/iclub_ai_practice_freeform_pc3_gate_dormant.sql
SET request.jwt.claim.role='service_role';
DO $test$
DECLARE r jsonb;
BEGIN
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'reason' IS DISTINCT FROM 'not_released'
 THEN RAISE EXCEPTION 'PC3 default OFF bypass %',r; END IF;
 UPDATE private.iclub_ai_practice_context_v1_control
  SET enabled=true WHERE singleton=1;
 UPDATE private.iclub_ai_practice_receipt_v1_control
  SET enabled=true WHERE singleton=1;
 UPDATE private.iclub_ai_practice_freeform_pc3_control
  SET enabled=true WHERE singleton=1;
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'released' IS DISTINCT FROM 'true' OR
   r->>'model' IS DISTINCT FROM 'gpt-5.4-mini' OR
   (r->>'output_token_cap')::integer<>384
 THEN RAISE EXCEPTION 'PC3 exact baseline unexpectedly denied %',r; END IF;
 -- Beta-only: no owner; revoked beta grant must close funded release.
 UPDATE private.iclub_ai_practice_context_v1_control SET owner_user_id=NULL WHERE singleton=1;
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'released' IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'Math beta only PC3 incorrectly closed %',r; END IF;
 UPDATE private.iclub_ai_practice_beta_grants_v1 SET enabled=false;
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'reason' IS DISTINCT FROM 'not_released' THEN
  RAISE EXCEPTION 'PC3 paid release bypassed revoked beta grant %',r; END IF;
 UPDATE private.iclub_ai_practice_beta_grants_v1 SET enabled=true;
 UPDATE private.iclub_ai_practice_context_v1_control
  SET owner_user_id='00000000-0000-4000-8000-000000000011' WHERE singleton=1;
 UPDATE private.iclub_ai_v21_freeform_budget_control
  SET output_token_cap=385 WHERE singleton=1;
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'reason' IS DISTINCT FROM 'not_released'
 THEN RAISE EXCEPTION 'Unapproved token cap allowed %',r; END IF;
 UPDATE private.iclub_ai_v21_freeform_budget_control
  SET output_token_cap=384 WHERE singleton=1;
 UPDATE private.iclub_ai_practice_receipt_v1_control
  SET enabled=false WHERE singleton=1;
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'reason' IS DISTINCT FROM 'not_released'
 THEN RAISE EXCEPTION 'PC4 disabled but generation enabled %',r; END IF;
 RAISE NOTICE 'PASS PC3: independent OFF, exact GPT-5.4-mini caps, PC4 prerequisite';
END $test$;
SET request.jwt.claim.role='authenticated';
DO $test$
DECLARE r jsonb;
BEGIN
 r:=public.iclub_ai_practice_freeform_pc3_gate_service();
 IF r->>'reason' IS DISTINCT FROM 'not_authorized'
 THEN RAISE EXCEPTION 'PC3 service-role check bypass %',r; END IF;
END $test$;
