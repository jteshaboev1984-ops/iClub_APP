// iClub AI v2.1 — QA ONLY. Verifies editorial metadata, NEVER academic content.
// Trust registry MUST be independently provisioned; browser/attachment is not trust.
"use strict";
const {createPublicKey,verify,createHash}=require("node:crypto");
const UUID=/^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i;
const SHA=/^[a-f0-9]{64}$/;
const CODE=/^[a-z0-9][a-z0-9._-]{0,99}$/;
const GATES=Object.freeze(["content_approved","rights_approved","source_version_verified",
 "correctness_passed","negative_tests_passed","exam_security_passed",
 "locale_verified","accessibility_passed"]);
const FIELDS=["protocol","ticketId","action","surface","subject","feature","topic",
 "locale","sourceId","sourceVersion","sourceHash","expectedRevision","qaEvidence",
 "reason","issuedAtMs","expiresAtMs"];
const obj=x=>x!==null&&typeof x==="object"&&!Array.isArray(x);
const exact=(x,fields)=>obj(x)&&Object.keys(x).length===fields.length&&
 fields.every(k=>Object.hasOwn(x,k));
const canonical=x=>Array.isArray(x)?"["+x.map(canonical).join(",")+"]":
 obj(x)?"{"+Object.keys(x).sort().map(k=>JSON.stringify(k)+":"+canonical(x[k])).join(",")+"}":
 JSON.stringify(x);
const signingBytes=m=>Buffer.from("iclub-ai-v21/editorial-evidence\n"+canonical(m),"utf8");
const sha=x=>createHash("sha256").update(x).digest("hex");
const deny=reason=>({ok:false,reason});
function validManifest(m,now){
 if(!exact(m,FIELDS)||m.protocol!=="iclub-ai-editorial-evidence-v21"
 ||!UUID.test(m.ticketId)||!["publish","revoke"].includes(m.action)
 ||!["lesson","practice"].includes(m.surface)||!CODE.test(m.subject)
 ||!CODE.test(m.feature)||!CODE.test(m.sourceId)||!CODE.test(m.sourceVersion)
 ||!SHA.test(m.sourceHash)||!["ru","uz","en"].includes(m.locale)
 ||!Number.isSafeInteger(m.expectedRevision)||m.expectedRevision<0
 ||!Number.isSafeInteger(m.issuedAtMs)||!Number.isSafeInteger(m.expiresAtMs)
 ||!Number.isSafeInteger(now)||m.issuedAtMs>now+60000
 ||m.expiresAtMs<=now||m.expiresAtMs<=m.issuedAtMs
 ||m.expiresAtMs-m.issuedAtMs>86400000)return false;
 if(m.surface==="lesson"&&!(m.feature==="topic_explanation"
  &&/^lesson_[1-9][0-9]{0,17}$/.test(m.topic)))return false;
 if(m.surface==="practice"&&!(m.feature==="answer_explanation"
  &&/^question_[1-9][0-9]{0,17}$/.test(m.topic)))return false;
 if(m.action==="publish"){
  if(!exact(m.qaEvidence,GATES)||GATES.some(g=>m.qaEvidence[g]!==true)
   ||m.reason!=="")return false;
 }else if(!exact(m.qaEvidence,[])||m.expectedRevision<1||
  typeof m.reason!=="string"||m.reason.trim().length<8||m.reason.length>500||
  /[\u0000-\u001f]/.test(m.reason))return false;
 return true;
}
function verifyEditorialEvidence({manifest,signatures,trustRegistry,nowMs}={}){
 if(!validManifest(manifest,nowMs))return deny("manifest_invalid");
 if(!obj(trustRegistry)||!CODE.test(trustRegistry.revision)||
  !Array.isArray(trustRegistry.reviewers)||trustRegistry.reviewers.length===0)
  return deny("trust_registry_missing");
 const roles=manifest.action==="publish"?["content","rights","technical"]:["safety"];
 if(!Array.isArray(signatures)||signatures.length!==roles.length)
  return deny("signatures_missing");
 const seenUsers=new Set(),seenKeys=new Set(),seenRoles=new Set(),reviewers={};
 const bytes=signingBytes(manifest);
 for(const x of signatures){
  if(!exact(x,["domain","reviewerId","keyId","signature"])||
    !roles.includes(x.domain)||seenRoles.has(x.domain)||
    !UUID.test(x.reviewerId)||seenUsers.has(x.reviewerId)||
    !CODE.test(x.keyId)||seenKeys.has(x.keyId)||
    typeof x.signature!=="string"||
    !/^[A-Za-z0-9_-]{86}$/.test(x.signature))
    return deny("identity_invalid");
  const matches=trustRegistry.reviewers.filter(r=>obj(r)&&r.enabled===true
   &&r.reviewerId===x.reviewerId&&r.keyId===x.keyId&&r.domain===x.domain
   &&Number.isSafeInteger(r.validFromMs)&&r.validFromMs<=manifest.issuedAtMs
   &&Number.isSafeInteger(r.validUntilMs)&&r.validUntilMs>nowMs);
  if(matches.length!==1)return deny("reviewer_untrusted");
  let valid=false;
  try{
   const key=createPublicKey(matches[0].publicKeyPem);
   valid=key.asymmetricKeyType==="ed25519"&&
    verify(null,bytes,key,Buffer.from(x.signature,"base64url"));
  }catch{}
  if(!valid)return deny("invalid_signature");
  seenRoles.add(x.domain);seenUsers.add(x.reviewerId);seenKeys.add(x.keyId);
  reviewers[x.domain]=x.reviewerId;
 }
 if(roles.some(r=>!seenRoles.has(r)))return deny("roles_missing");
 // For separately trusted staging ONLY. Never directly publishes.
 return {ok:true,attestation:{
  ticket_id:manifest.ticketId,action:manifest.action,
  surface_code:manifest.surface,subject_key:manifest.subject,
  feature_code:manifest.feature,topic_key:manifest.topic,locale:manifest.locale,
  source_id:manifest.sourceId,source_version:manifest.sourceVersion,
  source_hash:manifest.sourceHash,expected_revision:manifest.expectedRevision,
  qa_evidence:manifest.qaEvidence,reason:manifest.reason,reviewers,
  manifest_sha256:sha(bytes),trust_registry_revision:trustRegistry.revision,
  expires_at_ms:manifest.expiresAtMs
 }};
}
module.exports={verifyEditorialEvidence,signingBytes,GATES};
