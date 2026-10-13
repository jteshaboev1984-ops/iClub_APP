"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs");
const sh=fs.readFileSync("qa/run-ai-layer-v21-budget-race.sh","utf8");
test("Budget race only permits an empty localhost scratch PostgreSQL",()=>{
 for(const s of ["iclub_ai_v21_scratch_","SCRATCH_OK","127.0.0.1","pg_tables",
  "unset DATABASE_URL SUPABASE_DB_URL SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY"])
  assert.ok(sh.includes(s),s);
});
test("Actual two processes compete for one global monetary cap",()=>{
 for(const s of ["synthetic_money_race","pg_sleep(0.6)","p1=$!","p2=$!",
  "1:80","one money hold, one refusal"])assert.ok(sh.includes(s),s);
 assert.doesNotMatch(sh,/api\.openai\.com/);
});
