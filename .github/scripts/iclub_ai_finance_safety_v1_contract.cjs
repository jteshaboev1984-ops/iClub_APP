"use strict";
const fs=require("node:fs");
const assert=require("node:assert/strict");
const migration=fs.readFileSync("supabase/migrations/20261029180000_iclub_ai_finance_all_routes_unknown_holds_v1.sql","utf8");
assert.match(migration,/enabled boolean NOT NULL DEFAULT false/);
assert.equal((migration.match(/shared_provider_budget_exhausted/g)||[]).length,4,"all paid ledgers must participate");
assert.equal((migration.match(/actual_cost_usd=CASE WHEN v_status='completed'/g)||[]).length,2);
for(const r of ["exam_prep_ai_provider_leases","practice_ai_provider_leases","iclub_ai_v21_freeform_budget_ledger","iclub_ai_paid_canary_ledger_v1"]){
 assert.ok(migration.includes("FROM private."+r),"missing shared ledger "+r);
}
assert.doesNotMatch(migration,/\b(?:DELETE FROM|TRUNCATE)\s+public\./i);
for(const file of ["supabase/functions/exam-prep-ai/index.ts","supabase/functions/practice-ai/index.ts"]){
 const src=fs.readFileSync(file,"utf8");
 assert.match(src,/let providerDispatchAttempted = false/);
 assert.match(src,/providerDispatchAttempted = true;[\s\S]*?markProviderDispatched\(requestId\);[\s\S]*?callOpenAIProvider\(/);
 assert.match(src,/providerDispatchAttempted \? "unknown" : "released"/);
 assert.match(src,/if \(dispatchMark\?\.ok !== true\) throw/);
 assert.match(src,/status: "completed" \| "released" \| "unknown"/);
}
console.log("PASS 4 finance reserve guards, no public data writes, pre-call dispatch and unknown cost.");
