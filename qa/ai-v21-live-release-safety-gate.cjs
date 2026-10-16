"use strict";
// Observational-only supplement to frozen P9 preflight. NEVER a release API.
// Compares verified public metadata against QA's 24+1 proposed RPC inventory.
const {readFileSync}=require("node:fs");
const {join}=require("node:path");
const {checkLiveIntegrationReadiness,expectedRpcNames}=
  require("./ai-layer-v21-p9-live-integration-preflight.cjs");
const observation=require("./ai-v21-live-release-metadata-observation-20261016.json");
const OLD=require("./ai-layer-v21-p9-live-metadata-readonly-snapshot.json");
const read=(p)=>readFileSync(join(__dirname,"..",p),"utf8");
const QA_RESOLVER="resolve_iclub_ai_v21_practice_attempt_service";
const bool=(x)=>x===true;
function assessGlobalAiRolloutEvidence({
 live=observation,
 prior=OLD,
 adapter=read("qa/edge_v21/supabase_services.ts"),
 resolver=read("qa/edge_v21/practice_resolver_service.ts"),
 signedJwtTest=read("qa/edge_v21/practice_resolver_real_pg_http_test.ts"),
 signedAuth=read("qa/ai-v21-local-signed-auth.cjs"),
 serverGuard=read("qa/edge_v21/qa_startup_guard.ts")
}={}){
 const reasons=[];
 const deny=(code)=>{if(!reasons.includes(code))reasons.push(code)};
 const priorResult=checkLiveIntegrationReadiness({
  metadata:prior,adapterSource:adapter
 });
 const expected=expectedRpcNames(adapter);
 const structurallyValid=!!live&&typeof live==="object"&&!Array.isArray(live)&&
  live.schema==="iclub_ai_v21_production_metadata_delta_v1"&&
  live.evidence==="READ_ONLY_LIVE_SUPABASE_PG_CATALOG_AND_EDGE_LIST"&&
  live.projectRef==="mmmduffgpvwjdpruzikw"&&
  live.observedOn==="2026-10-16"&&
  live.noStudentRowsRead===true&&
  live.noAuthTokensOrSecretsRead===true&&
  live.globalAiCandidateDeployed===false&&
  Array.isArray(live.globalAiCoreRpcContractsDeployed)&&
  live.globalAiCoreRpcContractsDeployed.length===0&&
  live.globalAiPracticeResolverDeployed===false&&
  live.localCryptographicJwtCheck==="SYNTHETIC_LOCAL_AUTH_ONLY"&&
  live.realHostedSignedJwtAuthVerified===false&&
  live.editorialRightsApproved===false&&
  live.productionReleaseAuthorized===false&&
  live.requireFreshPreflight===true;
 if(!structurallyValid)deny("LIVE_OBSERVATION_UNTRUSTED_OR_CHANGED");
 if(!Array.isArray(expected)||expected.length!==24||
    priorResult.status!=="NO_GO"||priorResult.releaseAllowed!==false)
  deny("P9_RELEASE_BLOCKER_DRIFT");
 else if(priorResult.missingRpcCount>0)deny("CORE_V21_RPC_MISSING");
 if(!resolver.includes(QA_RESOLVER)||
    !resolver.includes('["localhost","127.0.0.1"]')||
    !serverGuard.includes('c.flag!=="isolated-preview-only"'))
  deny("QA_LOCAL_ONLY_RESOLVER_GUARD_CHANGED");
 if(!Array.isArray(live?.existingAI)||
    live.existingAI.length!==2||
    !["exam-prep-ai","practice-ai"].every(slug=>
      live.existingAI.some(x=>x.slug===slug&&x.status==="ACTIVE"&&x.verifyJwt===true)))
  deny("EXISTING_AI_TUTOR_METADATA_DRIFT");
 if(!bool(live?.globalAiPracticeResolverDeployed))
  deny("V21_PRACTICE_RESOLVER_UNAPPLIED");
 if(!bool(live?.globalAiCandidateDeployed))
  deny("V21_GLOBAL_EDGE_UNDEPLOYED");
 // This is intentionally NOT a shortcut for actual GoTrue access tokens.
 if(!bool(live?.realHostedSignedJwtAuthVerified)||
    signedJwtTest.includes("ICLUB_QA_JWT_A")||
    signedAuth.includes("iclub-qa-local-scratch-only"))
  deny("REAL_SUPABASE_AUTH_JWT_NOT_VERIFIED");
 if(!bool(live?.editorialRightsApproved))
  deny("ACADEMIC_RIGHTS_NOT_RELEASED");
 // Release needs independent owner/legal/commercial decisions even if every
 // metadata boolean is forged to true. No predicate returns "GO".
 deny("REQUIRES_INDEPENDENT_OWNER_RELEASE_APPROVAL");
 return Object.freeze({
  status:"NO_GO",releaseAuthorized:false,realLearnerAccess:false,
  metadataOnly:true,localJwtDoesNotProveHostedAuth:true,
  coreRpcRequired:24,extraPracticeResolverRequired:1,
  totalProposedRpc:25,
  previousReadOnlyCheckStatus:priorResult.status,
  reasons:Object.freeze(reasons),
  next:"ISOLATED_QA_OR_AUTHORIZED_READ_ONLY_VERIFICATION",
  productionDataMutation:false,productionDeploy:false,
  previewRedeployNeeded:false
 });
}
module.exports={assessGlobalAiRolloutEvidence,QA_RESOLVER};
if(require.main===module){
 const r=assessGlobalAiRolloutEvidence();
 console.log(JSON.stringify({status:r.status,releaseAuthorized:r.releaseAuthorized,
  proposedRpc:r.totalProposedRpc,reasons:r.reasons},null,2));
}
