"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {assessGlobalAiRolloutEvidence,QA_RESOLVER}=
 require("./ai-v21-live-release-safety-gate.cjs");
const metadata=require("./ai-v21-live-release-metadata-observation-20261016.json");
const authCatalog=require("./ai-v21-live-release-auth-catalog-readonly-20261016.json");
const p9=require("./ai-layer-v21-p9-live-metadata-readonly-snapshot.json");
const clone=(x)=>JSON.parse(JSON.stringify(x));
test("read-only production observations require twenty-four core RPCs plus one resolver, NO GO",()=>{
 const r=assessGlobalAiRolloutEvidence();
 assert.equal(r.status,"NO_GO");
 assert.equal(r.releaseAuthorized,false);
 assert.equal(r.coreRpcRequired,24);
 assert.equal(r.extraPracticeResolverRequired,1);
 assert.equal(r.totalProposedRpc,25);
 assert.equal(r.previewRedeployNeeded,false);
 assert.equal(r.productionDataMutation,false);
 assert.equal(r.localJwtDoesNotProveHostedAuth,true);
 for(const reason of ["CORE_V21_RPC_MISSING","V21_PRACTICE_RESOLVER_UNAPPLIED",
  "V21_GLOBAL_EDGE_UNDEPLOYED","REAL_SUPABASE_AUTH_JWT_NOT_VERIFIED",
  "ACADEMIC_RIGHTS_NOT_RELEASED","REQUIRES_INDEPENDENT_OWNER_RELEASE_APPROVAL"])
  assert.ok(r.reasons.includes(reason),reason);
 assert.equal(QA_RESOLVER,"resolve_iclub_ai_v21_practice_attempt_service");
});
test("missing metadata, changed owner project, altered source or forged approval cannot grant GO",()=>{
 for(const change of [
  x=>{x.projectRef="some-other-database";},
  x=>{x.realHostedSignedJwtAuthVerified=true;},
  x=>{x.productionReleaseAuthorized=true;},
  x=>{x.editorialRightsApproved=true;},
  x=>{x.noStudentRowsRead=false;},
  x=>{x.globalAiCandidateDeployed=true;},
  x=>{x.globalAiPracticeResolverDeployed=true;},
  x=>{x.requireFreshPreflight=false;}
 ]){
  const row=clone(metadata);change(row);
  const r=assessGlobalAiRolloutEvidence({live:row});
  assert.equal(r.status,"NO_GO");
  assert.equal(r.releaseAuthorized,false);
  assert.ok(r.reasons.includes("LIVE_OBSERVATION_UNTRUSTED_OR_CHANGED"));
 }
});
test("even spoofing all 24 RPCs, deployed Edge, rights and signed local JWT never authorizes learners",()=>{
 const live=clone(metadata),prior=clone(p9);
 prior.observedV21RpcContracts=[...prior.expectedRpcContracts];
 prior.observedV21EdgeDeployed=true;
 prior.contentSourceRightsReleased=true;
 prior.fullIntegratedPreviewVerified=true;
 live.globalAiCoreRpcContractsDeployed=[...prior.expectedRpcContracts];
 live.globalAiPracticeResolverDeployed=true;
 live.globalAiCandidateDeployed=true;
 live.realHostedSignedJwtAuthVerified=true;
 live.editorialRightsApproved=true;
 live.productionReleaseAuthorized=true;
 const out=assessGlobalAiRolloutEvidence({prior,live});
 assert.equal(out.releaseAuthorized,false);
 assert.equal(out.realLearnerAccess,false);
 assert.ok(out.reasons.includes("REQUIRES_INDEPENDENT_OWNER_RELEASE_APPROVAL"));
});
test("local signed JWT is NOT Supabase JWT and Auth user records were never inspected",()=>{
 assert.equal(metadata.noStudentRowsRead,true);
 assert.equal(metadata.noAuthTokensOrSecretsRead,true);
 assert.equal(metadata.localCryptographicJwtCheck,"SYNTHETIC_LOCAL_AUTH_ONLY");
 assert.equal(metadata.realHostedSignedJwtAuthVerified,false);
 const signed=readFileSync("qa/ai-v21-local-signed-auth.cjs","utf8");
 const resolver=readFileSync("qa/edge_v21/practice_resolver_service.ts","utf8");
 assert.match(signed,/iclub-qa-local-scratch-only/);
 assert.match(resolver,/\["localhost","127\.0\.0\.1"\]/);
 assert.match(resolver,/resolve_iclub_ai_v21_practice_attempt_service/);
});
test("already deployed Exam Prep and Practice AI remain independent of proposed Global AI",()=>{
 assert.deepEqual(metadata.existingAI.map(x=>x.slug).sort(),
  ["exam-prep-ai","practice-ai"]);
 assert.ok(metadata.existingAI.every(x=>x.verifyJwt===true&&x.status==="ACTIVE"));
 assert.equal(metadata.globalAiCandidateDeployed,false);
 const broken=clone(metadata);broken.existingAI[0].verifyJwt=false;
 const result=assessGlobalAiRolloutEvidence({live:broken});
 assert.ok(result.reasons.includes("EXISTING_AI_TUTOR_METADATA_DRIFT"));
 assert.equal(result.status,"NO_GO");
});

test("live Auth/Practice catalog proves only RLS metadata; GoTrue runtime remains unknown",()=>{
 const result=assessGlobalAiRolloutEvidence();
 assert.equal(result.authCatalogVerifiedAsMetadataOnly,true);
 assert.equal(result.releaseAuthorized,false);
 assert.equal(result.realLearnerAccess,false);
 assert.ok(result.reasons.includes("AUTH_HOSTED_RUNTIME_BEHAVIOR_NOT_TESTED"));
 assert.deepEqual(authCatalog.tables.filter(x=>x.schema==="auth").map(x=>x.name).sort(),
  ["audit_log_entries","identities","refresh_tokens","sessions","users"]);
 assert.equal(authCatalog.containsLearnerRows,false);
 assert.equal(authCatalog.containsAuthTokens,false);
});
test("grant drift, disabled RLS, weakened own policy or fake runtime approval fail closed",()=>{
 for(const mutation of [
  x=>{x.tables.find(t=>t.name==="users").authenticatedSelect=true;},
  x=>{x.tables.find(t=>t.name==="practice_session_answers_v4").anonSelect=true;},
  x=>{x.tables.find(t=>t.name==="practice_sessions_v4").rls=false;},
  x=>{x.selectedPolicies.find(t=>t.command==="SELECT").predicate="true";},
  x=>{x.selectedPolicies.find(t=>t.command==="ALL").predicate="true";},
  x=>{x.authServiceBehaviorVerified=true;},
  x=>{x.containsLearnerRows=true;},
  x=>{x.releaseAuthorized=true;}
 ]){
  const copy=clone(authCatalog);
  mutation(copy);
  const result=assessGlobalAiRolloutEvidence({catalog:copy});
  assert.equal(result.status,"NO_GO");
  assert.equal(result.releaseAuthorized,false);
  assert.ok(result.reasons.includes("LIVE_AUTH_RLS_METADATA_CHANGED"));
 }
});
