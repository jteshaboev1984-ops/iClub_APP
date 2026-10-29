-- ISOLATED PG-17 ONLY. Minimal production-shaped finance tables.
\set ON_ERROR_STOP on
CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO service_role;
CREATE TABLE private.exam_prep_ai_policy(
 id integer PRIMARY KEY, max_provider_request_cost_usd numeric NOT NULL,
 max_daily_requests int NOT NULL, max_concurrent_provider_calls int NOT NULL,
 max_daily_provider_cost_usd numeric NOT NULL,max_user_daily_provider_cost_usd numeric NOT NULL,
 provider_lease_ttl_seconds int NOT NULL
);
CREATE TABLE private.practice_ai_policy(LIKE private.exam_prep_ai_policy INCLUDING ALL);
INSERT INTO private.exam_prep_ai_policy VALUES(1,0.01,50,2,0.50,0.30,45);
INSERT INTO private.practice_ai_policy VALUES(1,0.01,50,2,0.50,0.30,45);
CREATE TABLE private.exam_prep_ai_provider_leases(
 request_id uuid PRIMARY KEY,user_id uuid NOT NULL,
 reserved_cost_usd numeric NOT NULL CHECK(reserved_cost_usd>0),
 actual_cost_usd numeric CHECK(actual_cost_usd>=0),
 status text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL,
 finished_at timestamptz,
 CONSTRAINT exam_prep_ai_provider_leases_status_check CHECK(status IN('active','completed','released','expired'))
);
CREATE TABLE private.practice_ai_provider_leases(
 LIKE private.exam_prep_ai_provider_leases INCLUDING ALL
);
ALTER TABLE private.practice_ai_provider_leases DROP CONSTRAINT exam_prep_ai_provider_leases_status_check;
ALTER TABLE private.practice_ai_provider_leases ADD CONSTRAINT practice_ai_provider_leases_status_check CHECK(status IN('active','completed','released','expired'));
CREATE TABLE private.iclub_ai_v21_freeform_budget_control(
 singleton int PRIMARY KEY,enabled boolean NOT NULL,owner_permitted boolean NOT NULL,include_free_beta boolean NOT NULL,
 maximum_per_request_microusd bigint NOT NULL,maximum_lifetime_microusd bigint NOT NULL,
 maximum_per_learner_microusd bigint NOT NULL,maximum_parallel int NOT NULL,model text NOT NULL
);
INSERT INTO private.iclub_ai_v21_freeform_budget_control VALUES(1,true,true,true,50000,5000000,750000,2,'gpt-5.4-mini');
CREATE TABLE private.iclub_ai_v21_beta_control(
 singleton int PRIMARY KEY,beta_enabled boolean NOT NULL,prepared_enabled boolean NOT NULL,generation_enabled boolean NOT NULL
);
INSERT INTO private.iclub_ai_v21_beta_control VALUES(1,true,true,false);
CREATE TABLE private.iclub_ai_v21_beta_members(
 user_id uuid PRIMARY KEY,enabled boolean NOT NULL,consent_at timestamptz,consent_version text NOT NULL
);
CREATE TABLE private.iclub_ai_v21_freeform_budget_ledger(
 request_id uuid PRIMARY KEY,user_id uuid NOT NULL,session_fingerprint text NOT NULL,request_fingerprint text NOT NULL,
 source_fingerprint text NOT NULL,source_version text NOT NULL,locale text NOT NULL,state text NOT NULL,
 held_microusd bigint NOT NULL,actual_microusd bigint,reserved_at timestamptz NOT NULL DEFAULT now(),
 dispatched_at timestamptz,finished_at timestamptz
);
CREATE TABLE private.iclub_ai_paid_canary_control_v1(
 singleton int PRIMARY KEY,enabled boolean NOT NULL,max_lifetime_microusd bigint NOT NULL,
 max_day_microusd bigint NOT NULL,max_actor_day_microusd bigint NOT NULL,
 per_call_hold_microusd bigint NOT NULL,max_inflight int NOT NULL
);
INSERT INTO private.iclub_ai_paid_canary_control_v1 VALUES(1,true,1000000,1000000,1000000,10000,2);
CREATE TABLE private.iclub_ai_paid_canary_ledger_v1(
 request_id uuid PRIMARY KEY,actor text NOT NULL DEFAULT 'pilot_operator',
 state text NOT NULL DEFAULT 'reserved',hold_microusd bigint NOT NULL DEFAULT 10000,
 actual_microusd bigint,reserved_at timestamptz NOT NULL DEFAULT now(),
 dispatched_at timestamptz,finished_at timestamptz
);
REVOKE ALL ON ALL TABLES IN SCHEMA private FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA private TO service_role;
