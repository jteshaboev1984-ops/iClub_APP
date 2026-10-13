"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs");
const sql=fs.readFileSync("qa/sql_drafts/iclub_ai_v21_provider_spend_UNAPPLIED.sql","utf8");
const pg=fs.readFileSync("qa/sql_drafts/iclub_ai_v21_provider_spend_local_pg.psql","utf8");
test("Provider SQL is scratch-only, isolated from real Mathematics money accounting",()=>{
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/BLOCKED: provider monetary ledger only in local scratch/);
 assert.doesNotMatch(sql,/exam_prep_ai_provider_leases|practice_ai_provider_leases/i);
 assert.doesNotMatch(sql,/(UPDATE|DELETE)\s+public\.(lessons|users|practice_session_answers_v4)/i);
});
test("Budget is disabled at first and ONLY separate owner configuration can enable",()=>{
 assert.match(sql,/enabled boolean NOT NULL DEFAULT false/);
 assert.match(sql,/lifetime_cap_microusd bigint NOT NULL DEFAULT 0/);
 assert.match(sql,/per_request_ceiling_microusd bigint NOT NULL DEFAULT 0/);
 assert.match(sql,/release_approved/);
 assert.match(sql,/generation_enabled/);
 assert.doesNotMatch(sql,/UPDATE private\.iclub_ai_v21_provider_spend_control/i);
});
test("Unique request ID plus delivery and learner quota are mandatory, no second dispatch",()=>{
 for(const code of ["request_id uuid PRIMARY KEY","request_fingerprint",
 "session_fingerprint","q.status='reserved'","d.status='claimed'",
 "q.route_class='generated'","e.state<>'reserved'","state='dispatched'"])
 assert.ok(sql.includes(code),code);
});
test("Budget counts live reserved, dispatched and unknown at worst-case ceiling",()=>{
 assert.match(sql,/WHEN state='charged' THEN actual_microusd/);
 assert.match(sql,/WHEN state='no_charge' THEN 0 ELSE held_microusd/);
 assert.match(sql,/pg_advisory_xact_lock/);
 assert.match(sql,/FOR UPDATE/);
 assert.match(sql,/provider_budget_insufficient/);
});
test("Provider can be refunded only if definitely uncalled; ambiguous retains liability",()=>{
 assert.match(sql,/p_outcome='no_charge' AND e.state<>'reserved'/);
 assert.match(sql,/p_outcome IN \('charged','unknown'\) AND e.state<>'dispatched'/);
 assert.match(sql,/p_actual_microusd>e.held_microusd/);
 assert.match(sql,/unsafe_settlement/);
});
test("Money RPC is service-role-only, but service_role cannot update ceiling",()=>{
 for(const n of ["reserve_iclub_ai_v21_provider_spend_service",
  "dispatch_iclub_ai_v21_provider_spend_service",
  "finish_iclub_ai_v21_provider_spend_service"]){
  assert.ok(sql.includes("public."+n));
 }
 assert.match(sql,/REVOKE ALL ON TABLE private\.iclub_ai_v21_provider_spend_control/);
 assert.match(sql,/REVOKE ALL ON TABLE private\.iclub_ai_v21_provider_spend_leases/);
 assert.match(sql,/TO service_role/);
});
test("Native PostgreSQL validates real meter+claim, unknown cost and refund with rollback",()=>{
 assert.match(pg,/^BEGIN;/m);assert.match(pg,/^ROLLBACK;/m);
 for(const x of ["Provider spending roles insufficiently isolated",
  "Missing quota/claim admitted provider","Protected exam dispatched provider",
  "Two paid dispatches allowed","Dispatched provider money incorrectly released",
  "40 known + 80 unknown must count 120","Spending ceiling ignored",
  "Denied money left user charged"])assert.ok(pg.includes(x),x);
});
