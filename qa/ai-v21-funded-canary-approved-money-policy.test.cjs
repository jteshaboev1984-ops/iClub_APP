"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const fs=p=>readFileSync(p,"utf8");
const p=JSON.parse(fs("qa/ai-v21-funded-canary-approved-money-policy.json"));
const sql=fs("qa/sql_drafts/iclub_ai_v21_provider_spend_UNAPPLIED.sql");
test("approved owner cap is $1 LIFETIME, $0.50 UTC day, $0.05 user day, $0.01 request",()=>{
 assert.equal(p.currency,"USD");
 assert.deepEqual(p.money_caps_microusd,{
  absolute_lifetime:1000000,global_utc_day:500000,
  per_user_utc_day:50000,per_request:10000
 });
 assert.equal(p.max_parallel_provider_calls,2);
 assert.equal(p.model,"gpt-5.6-luna");
 assert.equal(p.max_output_tokens,220);
});
test("money approval NEVER automatically opens a real provider or students",()=>{
 assert.equal(p.status,"OWNER_APPROVED_BUDGET_LIVE_ISOLATED_LEDGER_AND_DORMANT_EDGE");
 assert.equal(p.provider_calls_enabled,false);
 assert.equal(p.allow_real_students,false);
 assert.equal(p.commercial_plan_activation,false);
 for(const x of [
  "enabled boolean NOT NULL DEFAULT false",
  "lifetime_cap_microusd bigint NOT NULL DEFAULT 0",
  "daily_cap_microusd bigint NOT NULL DEFAULT 0",
  "per_user_daily_cap_microusd bigint NOT NULL DEFAULT 0",
  "max_concurrent_requests smallint NOT NULL DEFAULT 0"
 ])assert.ok(sql.includes(x),x);
});
test("existing Tutor, Core and production runtime stay independent from funded candidate",()=>{
 const source=fs("qa/ai-v21-funded-provider-transport.cjs");
 assert.match(source,/Not linked from live Supabase or app/);
 assert.doesNotMatch(source,/exam_prep_ai_provider_leases|practice_ai_provider_leases/);
 assert.match(sql,/BLOCKED: provider monetary ledger only in local scratch/);
 assert.match(sql,/REVOKE ALL ON TABLE private\.iclub_ai_v21_provider_spend_control/);
});
