"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {checkLiveIntegrationReadiness,expectedRpcNames}=
 require("./ai-layer-v21-p9-live-integration-preflight.cjs");
const metadata=require("./ai-layer-v21-p9-live-metadata-readonly-snapshot.json");
const copy=()=>JSON.parse(JSON.stringify(metadata));
const has=(result,code)=>result.issues.some(x=>x.code===code);
test("P9 live read-only audit fails closed on ALL twenty-three missing contracts",()=>{
 const v=checkLiveIntegrationReadiness();
 a.equal(v.status,"NO_GO");a.equal(v.releaseAllowed,false);
 a.equal(v.expectedRpcCount,23);a.equal(v.observedRpcCount,0);
 a.equal(v.missingRpcCount,23);
 a.equal(new Set(v.missingRpcNames).size,23);
 a.equal(has(v,"LIVE_RPC_MISSING"),true);
 a.equal(has(v,"V21_SERVER_EDGE_NOT_DEPLOYED"),true);
 a.equal(has(v,"CONTENT_RIGHTS_UNPUBLISHED"),true);
 a.equal(has(v,"PROTECTED_INTEGRATED_PREVIEW_MISSING"),true);
 a.equal(has(v,"OWNER_BETA_SPEND_APPROVAL_MISSING"),true);
 a.equal(v.noNewSupabaseBranch,true);
});
test("P9 RPC inventory is exact static API source, not aspirational documentation",()=>{
 const source=readFileSync("qa/edge_v21/supabase_services.ts","utf8");
 const real=expectedRpcNames(source);
 a.deepEqual(real,metadata.expectedRpcContracts);
 a.equal(real.length,23);
 const injected=checkLiveIntegrationReadiness({adapterSource:
  source.replace('get_iclub_ai_v21_runtime_service"',
   'get_iclub_ai_v21_unknown_service"')});
 a.equal(injected.status,"NO_GO");
 a.equal(has(injected,"ADAPTER_RPC_INVENTORY_CHANGED"),true);
});
test("P9 fake all-present RPC inventory can NEVER turn into rollout approval",()=>{
 const fake=copy();
 fake.observedV21RpcContracts=[...fake.expectedRpcContracts];
 fake.observedV21EdgeDeployed=true;
 fake.contentSourceRightsReleased=true;
 fake.fullIntegratedPreviewVerified=true;
 const v=checkLiveIntegrationReadiness({metadata:fake});
 a.equal(v.missingRpcCount,0);
 a.equal(v.releaseAllowed,false);
 a.equal(v.status,"NO_GO");
 a.equal(has(v,"LIVE_PER_READ_AUTH_NOT_VERIFIED"),true);
 a.equal(has(v,"MATHEMATICS_CORE_AI_OFF_PARITY_PENDING"),true);
 a.equal(has(v,"PROVIDER_PRICE_AND_BUDGET_UNAPPROVED"),true);
 a.equal(has(v,"OWNER_BETA_SPEND_APPROVAL_MISSING"),true);
});
test("P9 commercial definition or grants drift force dedicated review",()=>{
 const broken=copy();broken.previouslyVerifiedCommercial[0].definitionMd5="0".repeat(32);
 const v=checkLiveIntegrationReadiness({metadata:broken});
 a.equal(has(v,"COMMERCIAL_ACCESS_DRIFT"),true);
 const grants=copy();grants.previouslyVerifiedCommercial[1].anonExecute=true;
 a.equal(has(checkLiveIntegrationReadiness({metadata:grants}),
  "COMMERCIAL_ACCESS_DRIFT"),true);
});
test("P9 RLS, direct read grants, protected Exam Prep and UI drift are not ignored",()=>{
 const tables=copy();
 tables.observedTables.find(x=>x.name==="practice_sessions_v4").authenticatedSelect=true;
 a.equal(has(checkLiveIntegrationReadiness({metadata:tables}),
  "DIRECT_LEARNER_DATA_ACCESS_DRIFT"),true);
 const dropped=copy();dropped.observedTables.pop();
 a.equal(has(checkLiveIntegrationReadiness({metadata:dropped}),
  "RLS_METADATA_INCOMPLETE"),true);
 const edge=copy();edge.observedAIRelevantEdgeFunctions=[];
 a.equal(has(checkLiveIntegrationReadiness({metadata:edge}),
  "EXISTING_TUTOR_EDGE_DRIFT"),true);
 const html=readFileSync("index.html","utf8")+
  '<script src="ai-layer-v21-p6-study-route.cjs"></script>';
 a.equal(has(checkLiveIntegrationReadiness({productionHtml:html}),
  "PRODUCTION_UI_GATE_DRIFT"),true);
});
test("P9 unknown, duplicate and missing live function inventories fail safely",()=>{
 const invalid=copy();invalid.observedV21RpcContracts=["unknown_rpc"];
 a.equal(has(checkLiveIntegrationReadiness({metadata:invalid}),
  "LIVE_RPC_CATALOG_INVALID"),true);
 const duplicate=copy();duplicate.observedV21RpcContracts=[
  metadata.expectedRpcContracts[0],metadata.expectedRpcContracts[0]];
 a.equal(has(checkLiveIntegrationReadiness({metadata:duplicate}),
  "LIVE_RPC_CATALOG_INVALID"),true);
 const spoof=copy();spoof.releaseAllowed=true;
 a.equal(checkLiveIntegrationReadiness({metadata:spoof}).reason,
  "untrusted_metadata_snapshot");
});
test("P9 audit SQL contains only pg_catalog and information_schema SELECT",()=>{
 const sql=readFileSync(
  "qa/sql_drafts/iclub_ai_v21_p9_catalog_READ_ONLY.sql","utf8");
 a.match(sql,/pg_catalog\.pg_proc/);
 a.match(sql,/pg_catalog\.pg_class/);
 a.match(sql,/information_schema\.columns/);
 a.doesNotMatch(sql,/\b(INSERT|UPDATE|DELETE|ALTER|CREATE|DROP|TRUNCATE|EXECUTE|CALL|COPY)\s/i);
 a.doesNotMatch(sql,/FROM\s+(?:public|private)\.(?:users|practice_sessions_v4|tour_attempts)\b/i);
});
