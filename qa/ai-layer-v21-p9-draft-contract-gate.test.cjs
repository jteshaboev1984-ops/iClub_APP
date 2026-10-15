"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {verifyDraftContracts}=require("./ai-layer-v21-p9-draft-contract-gate.cjs");
const manifest=require("./ai-layer-v21-p9-rpc-draft-manifest.json");
const policy=require("./ai-layer-v21-p9-policy-fingerprint-snapshot.json");
const file="qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql";
const source=()=>readFileSync(file,"utf8");
const clone=v=>JSON.parse(JSON.stringify(v));
const code=(r,k)=>r.errors.some(x=>x.code===k);
test("P9 all 23 SQL drafts match actual adapter signatures, service-only grants, scratch guard",()=>{
 const r=verifyDraftContracts();
 a.equal(r.matched,true,JSON.stringify(r.errors));
 a.equal(r.rpcContractCount,23);a.equal(r.localDraftCount,9);
 a.equal(r.status,"NO_GO");a.equal(r.releaseAllowed,false);
});
test("P9 parameter type drift blocks SQL",()=>{
 const s=source();const changed=s.replace(
  "p_user_id uuid,p_session_id bigint,p_question_id bigint",
  "p_user_id uuid,p_session_id text,p_question_id bigint");
 a.notEqual(s,changed);
 a.equal(code(verifyDraftContracts({overrides:{[file]:changed}}),"RPC_SIGNATURE_DRIFT"),true);
});
test("P9 revoke removal and public execute widening both block",()=>{
 const s=source();
 const missing=s.replace(/REVOKE ALL ON FUNCTION public\.mint_iclub_ai_v21_practice_context_service/i,"REVOKE NOTHING ON FUNCTION public.mint_iclub_ai_v21_practice_context_service");
 a.notEqual(s,missing);
 a.equal(code(verifyDraftContracts({overrides:{[file]:missing}}),"RPC_EXECUTION_GRANTS_DRIFT"),true);
 const wider=s.replace(/(GRANT EXECUTE ON FUNCTION public\.mint_iclub_ai_v21_practice_context_service\([^)]*\)\s+TO\s+)service_role/i,"$1authenticated");
 a.notEqual(s,wider);
 a.equal(code(verifyDraftContracts({overrides:{[file]:wider}}),"RPC_EXECUTION_GRANTS_DRIFT"),true);
});
test("P9 unsafe function owner context blocks",()=>{
 const s=source(),modified=s.replace("VOLATILE SECURITY DEFINER","VOLATILE SECURITY INVOKER");
 a.notEqual(s,modified);
 a.equal(code(verifyDraftContracts({overrides:{[file]:modified}}),"UNSAFE_DEFINER_CONTEXT"),true);
 const modifiedPath=s.replace("SET search_path='' AS $$","SET search_path=public AS $$");
 a.notEqual(s,modifiedPath);
 a.equal(code(verifyDraftContracts({overrides:{[file]:modifiedPath}}),"UNSAFE_DEFINER_CONTEXT"),true);
});
test("P9 missing scratch database guard blocks",()=>{
 const s=source(),changed=s.replace(
  "IF current_database() !~ '^iclub_ai_v21_scratch_[a-z0-9_]+$'",
  "IF current_database() IS NULL");
 a.notEqual(s,changed);
 a.equal(code(verifyDraftContracts({overrides:{[file]:changed}}),"SCRATCH_BOUNDARY_DRIFT"),true);
});
test("P9 order must respect dependency graph",()=>{
 const m=clone(manifest);
 m.stages[2].dependsOn=["qa/sql_drafts/iclub_ai_v21_encrypted_reply_UNAPPLIED.sql"];
 a.equal(code(verifyDraftContracts({drafts:m}),"DEPENDENCY_DRIFT"),true);
});
test("P9 fake new Edge contract, altered manifest or missing SQL blocks",()=>{
 const m=clone(manifest);m.contracts.pop();
 a.equal(code(verifyDraftContracts({drafts:m}),"RPC_INVENTORY_DRIFT"),true);
 const bad=clone(manifest);bad.releaseAllowed=true;
 a.equal(code(verifyDraftContracts({drafts:bad}),"UNTRUSTED_MANIFEST"),true);
 const s=source(),edited=s.replace(
  "CREATE OR REPLACE FUNCTION public.mint_iclub_ai_v21_practice_context_service",
  "CREATE OR REPLACE FUNCTION public.mint_iclub_ai_v21_fake_context_service");
 a.notEqual(s,edited);
 a.equal(code(verifyDraftContracts({overrides:{[file]:edited}}),"RPC_DRAFT_MISSING"),true);
});
test("P9 dated RLS policy metadata cannot grant release",()=>{
 const b=clone(policy);b.policies[0].expressionMd5="BROKEN";
 a.equal(code(verifyDraftContracts({policies:b}),"RLS_METADATA_DRIFT"),true);
 a.equal(verifyDraftContracts().releaseAllowed,false);
});
