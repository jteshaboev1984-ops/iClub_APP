"use strict";
// P9: observational release preflight, never a capability/grant.
// Data source: date-stamped read-only pg_catalog/Edge metadata; NO learner rows.
// This module must NEVER return GO, deploy, connect or mutate production.
const {readFileSync}=require("node:fs");
const root=require("node:path").join(__dirname,"..");
const snapshot=require("./ai-layer-v21-p9-live-metadata-readonly-snapshot.json");
const commercial=require("./ai-layer-v21-p6-live-commercial-catalog-snapshot.json");
const read=p=>readFileSync(require("node:path").join(root,p),"utf8");
const sortedUnique=v=>Array.isArray(v)&&v.every(x=>typeof x==="string")&&
 new Set(v).size===v.length;
const validHash=h=>typeof h==="string"&&/^[a-f0-9]{32}$/.test(h);
const REQUIRED_TABLES=Object.freeze([
 "private.iclub_commercial_access_config",
 "private.iclub_subject_slot_selections",
 "public.practice_session_answers_v4",
 "public.practice_sessions_v4",
 "public.subjects","public.tour_attempts",
 "public.tour_session_runtime_v4","public.user_subjects"
]);
function expectedRpcNames(source,proof=read("qa/edge_v21/screen_proof_services.ts")){
 if(typeof source!=="string"||typeof proof!=="string")return null;
 const matches=[...source.matchAll(/\brpc\("([a-z][a-z0-9_]+)"/g)].map(x=>x[1]);
 const indirect=[...proof.matchAll(/\bconst\s+KIND\s*=\s*"(get_iclub_ai_v21_[a-z0-9_]+)"/g)].map(x=>x[1]);
 if(indirect.length!==1)return null;
 matches.push(...indirect);
 if(matches.length===0||matches.length>60)return null;
 return [...new Set(matches)].sort();
}
function checkLiveIntegrationReadiness({
 metadata=snapshot,
 adapterSource=read("qa/edge_v21/supabase_services.ts"),
 edgeSource=read("qa/edge_v21/index.ts"),
 productionHtml=read("index.html"),
 productionApp=read("app.js"),
 commercialBaseline=commercial
}={}){
 const issues=[];
 const add=(code,detail)=>issues.push(Object.freeze({code,detail}));
 const expected=expectedRpcNames(adapterSource);
 if(!metadata||typeof metadata!=="object"||Array.isArray(metadata)||
  metadata.schema!=="iclub_ai_v21_live_metadata_preflight_v1"||
  metadata.source!=="SUPABASE_PRODUCTION_READ_ONLY_PG_CATALOG_AND_EDGE_INVENTORY"||
  metadata.releaseAllowed!==false||
  metadata.freshRecheckRequired!==true||
  metadata.independentOwnerReleaseApprovalRequired!==true)
  return Object.freeze({status:"NO_GO",reason:"untrusted_metadata_snapshot",
   releaseAllowed:false,missingRpcCount:null,issues:[]});
 if(!expected||expected.length!==24||!sortedUnique(metadata.expectedRpcContracts)||
  JSON.stringify(expected)!==JSON.stringify(metadata.expectedRpcContracts))
  add("ADAPTER_RPC_INVENTORY_CHANGED","Re-audit exact adapter RPC list");
 const observed=metadata.observedV21RpcContracts;
 if(!sortedUnique(observed)||observed.some(s=>!expected?.includes(s)))
  add("LIVE_RPC_CATALOG_INVALID","Unrecognized or duplicate live RPC contracts");
 const missing=expected?expected.filter(s=>!observed?.includes(s)):[];
 if(missing.length>0)add("LIVE_RPC_MISSING",missing.length+" missing functions");
 if(!Array.isArray(metadata.previouslyVerifiedCommercial)||
  metadata.previouslyVerifiedCommercial.length!==2||
  commercialBaseline?.functions?.length!==2||
  commercialBaseline?.liveReleaseAllowed!==false)
  add("COMMERCIAL_METADATA_INCOMPLETE","Missing signed-off commercial baseline");
 else for(const item of commercialBaseline.functions){
  const row=metadata.previouslyVerifiedCommercial.find(x=>x.name===item.name);
  if(!row||row.identityArgs!==item.identityArgs||
   row.definitionMd5!==item.definitionMd5||!validHash(row.definitionMd5)||
   row.securityDefiner!==true||row.anonExecute!==false||
   row.authenticatedExecute!==false||row.serviceRoleExecute!==true)
   add("COMMERCIAL_ACCESS_DRIFT","Function definition/grants require renewed review: "+item.name);
 }
 const tables=metadata.observedTables;
 if(!Array.isArray(tables)||tables.length!==REQUIRED_TABLES.length||
  REQUIRED_TABLES.some(name=>!tables.some(t=>t.schema+"."+t.name===name&&
   t.rls===true&&Number.isInteger(t.policyCount)&&t.policyCount>=0))||
  new Set(tables?.map(t=>t.schema+"."+t.name)).size!==REQUIRED_TABLES.length)
  add("RLS_METADATA_INCOMPLETE","Eight table metadata entries required");
 else {
  for(const t of tables){
   if(["private.iclub_subject_slot_selections",
    "private.iclub_commercial_access_config",
    "public.practice_sessions_v4",
    "public.practice_session_answers_v4",
    "public.tour_session_runtime_v4"].includes(t.schema+"."+t.name)&&
    (t.anonSelect!==false||t.authenticatedSelect!==false))
    add("DIRECT_LEARNER_DATA_ACCESS_DRIFT","Direct table privilege changed");
  }
 }
 if(!Array.isArray(metadata.observedAIRelevantEdgeFunctions)||
  !["exam-prep-ai","practice-ai"].every(slug=>
   metadata.observedAIRelevantEdgeFunctions.some(x=>
    x.slug===slug&&x.status==="ACTIVE"&&x.verifyJwt===true)))
  add("EXISTING_TUTOR_EDGE_DRIFT","Existing production Edge needs independent review");
 if(metadata.observedV21EdgeDeployed!==true)
  add("V21_SERVER_EDGE_NOT_DEPLOYED","No approved Global AI v2.1 production Edge");
 if(metadata.contentSourceRightsReleased!==true)
  add("CONTENT_RIGHTS_UNPUBLISHED","Synthetic sources are not real editorial releases");
 if(metadata.fullIntegratedPreviewVerified!==true)
  add("PROTECTED_INTEGRATED_PREVIEW_MISSING","Static preview is not integrated Edge+DB");
 if(metadata.currentProductionAcademicRowsRead!==false)
  add("AUDIT_BOUNDARY_VIOLATION","Read-only catalog audit cannot include learner records");
 if(typeof edgeSource!=="string"||
  !edgeSource.includes('ICLUB_AI_V21_EXPLICIT_QA')||
  !edgeSource.includes('isolated-preview-only')||
  !edgeSource.includes('No provider is connected'))
  add("QA_EDGE_SCOPE_DRIFT","Isolated-only candidate changed; inspect before deploying");
 if(typeof productionHtml!=="string"||typeof productionApp!=="string"||
  ["ai-layer-v21-p6-study-route.cjs",
   "ai-layer-v21-p6-home-pg-http-gateway.cjs",
   "ai-layer-v21-p9-live-integration-preflight.cjs"].some(file=>
    productionHtml.includes(file)||productionApp.includes(file)))
  add("PRODUCTION_UI_GATE_DRIFT","Detached QA code appeared in current app");
 // Fundamental release gates are not represented by metadata booleans:
 // human/legal/financial acceptance must be evidenced independently.
 add("LIVE_PER_READ_AUTH_NOT_VERIFIED","Real end-screen RLS/owner auth untested");
 add("MATHEMATICS_CORE_AI_OFF_PARITY_PENDING","Need independent live-path parity");
 add("PROVIDER_PRICE_AND_BUDGET_UNAPPROVED","Test tariff weights are provisional");
 add("OWNER_BETA_SPEND_APPROVAL_MISSING","Explicit owner GO is separate from CI");
 return Object.freeze({
  status:"NO_GO",reviewOnly:true,releaseAllowed:false,
  metadataOnly:true,observedOn:metadata.observedOn,
  expectedRpcCount:expected?.length??null,
  observedRpcCount:observed?.length??null,
  missingRpcCount:missing.length,
  missingRpcNames:Object.freeze([...missing]),
  issues:Object.freeze(issues),
  nextAuthorizedAction:"ISOLATED_QA_AND_READ_ONLY_CATALOG_ONLY",
  noNewSupabaseBranch:true,existingExamPrepUntouched:true
 });
}
module.exports={checkLiveIntegrationReadiness,expectedRpcNames};
if(require.main===module){
 const out=checkLiveIntegrationReadiness();
 process.stdout.write(JSON.stringify({
  status:out.status,releaseAllowed:out.releaseAllowed,
  missingRpcCount:out.missingRpcCount,
  issues:out.issues.map(x=>x.code)
 },null,2)+"\n");
}
