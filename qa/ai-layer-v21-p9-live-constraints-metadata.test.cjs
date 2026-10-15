"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const snap=require("./ai-layer-v21-p9-auth-constraints-readonly.json");
const local=readFileSync("qa/sql_drafts/iclub_ai_v21_critical_constraints_LOCAL_ONLY.psql","utf8");
const flow=readFileSync("qa/sql_drafts/iclub_ai_v21_nine_drafts_integrated_local_pg.psql","utf8");
const owners=readFileSync("qa/sql_drafts/iclub_ai_v21_two_owner_proof_LOCAL_ONLY.psql","utf8");
test("§118 production constraints/indices/triggers/policy inventory grounded in catalog",()=>{
 a.equal(snap.metadataOnly,true);a.equal(snap.releaseAllowed,false);
 a.equal(snap.realUserRowsRead,false);
 a.equal(snap.constraints.length,48);
 a.equal(snap.indexes.length,43);
 a.equal(snap.triggers.length,4);
 a.equal(snap.policies.length,13);
 a.ok(snap.constraints.some(x=>x.name==="users_id_auth_users_fkey"&&
  x.definition.includes("REFERENCES auth.users(id)")));
 a.deepEqual(snap.triggers.map(x=>x.name).sort(),[
 "practice_stamp_bank_generation_v1","trg_auto_notify_welcome_after_registration",
 "trg_enforce_competitive_limit","trg_sync_telegram_link_from_users"].sort());
});
test("§118 limited test constraints and eight negative statements are never product DDL",()=>{
 a.ok(local.includes("scratch only")&&local.includes("FOREIGN KEY"));
 a.equal((local.match(/ADD CONSTRAINT qa_/g)||[]).length,23);
 a.ok(flow.includes("\\ir iclub_ai_v21_critical_constraints_LOCAL_ONLY.psql"));
 a.ok(flow.includes("\\ir iclub_ai_v21_real_schema_screen_proof_UNAPPLIED.sql"));
 for(const s of ["CONSTRAINT_NEGATIVE_GREEN","foreign_key_violation",
  "unique_violation","check_violation","TWO_OWNER_SCOPE_GREEN"])
  a.ok(owners.includes(s),s);
 a.doesNotMatch(local,/INSERT INTO auth.users|supabase.co|api.openai.com|CREATE TRIGGER/i);
});
test("§118 trusted user identity is derived from Supabase Auth, never from browser JSON",()=>{
 const adapter=readFileSync("qa/edge_v21/supabase_services.ts","utf8");
 const core=readFileSync("qa/edge_v21/context_core.ts","utf8");
 a.ok(adapter.includes('"/auth/v1/user"'));
 a.ok(adapter.includes("const key=config.serviceRoleKey"));
 a.ok(adapter.includes("UUID.test(str(d.id))"));
 a.ok(core.includes("userId:principal.userId"));
 a.ok(core.includes('const KEYS=new Set(["action","sessionId"'));
 a.ok(!core.includes('"userId","sessionId"'));
});
